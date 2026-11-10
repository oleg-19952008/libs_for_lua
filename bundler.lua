#!/usr/bin/env lua
-- ============================================================
-- bundler.lua — сборщик одного Lua-файла из проекта.
-- Совместим с Lua 5.1.4 (работает и на 5.2–5.4).
--
-- Идея:
--   * Сканируем главный файл на require("...")/require '...'/require "..."
--   * Каждый найденный модуль ищем через package.path
--     (плюс fallback: каталог главного файла + ?.lua)
--   * Рекурсивно собираем транзитивные зависимости
--   * Генерируем один .lua, где каждый модуль завёрнут в
--     function(require) ... end, а require — локальный параметр.
--     Это изолирует модули друг от друга и сохраняет return M.
--   * Выход сохраняется в бинарном режиме, без BOM.
--
-- Ограничения (ожидаемые для любого простого бандлера):
--   * Только литеральные require. require(var), require("a".."b")
--     и require внутри loadstring() НЕ бандлятся — уйдут в
--     настоящий require в рантайме (если модуль есть на диске).
--   * dofile()/loadfile() не бандлятся.
--   * Модули с module("x", package.seeall) в 5.1 — работают,
--     т.к. module() вызывается в теле и пишет в package.loaded
--     сам; наш return всё равно возьмёт таблицу.
-- ============================================================

local SEP = package.config:sub(1, 1) -- "\\" на Windows, "/" на POSIX

-- ────────────────────────────────────────────────────────────
-- Утилиты
-- ────────────────────────────────────────────────────────────

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c
end

local function writeFile(path, data)
    local f, err = io.open(path, "wb")
    if not f then
        io.stderr:write("error: cannot write " .. path .. ": " .. tostring(err) .. "\n")
        return false
    end
    f:write(data)
    f:close()
    return true
end

local function stripBom(src)
    if #src >= 3
       and src:byte(1) == 0xEF
       and src:byte(2) == 0xBB
       and src:byte(3) == 0xBF then
        return src:sub(4)
    end
    return src
end

local function stripShebang(src)
    if src:sub(1, 2) == "#!" then
        local nl = src:find("\n", 1, true)
        if nl then return src:sub(nl + 1) end
        return ""
    end
    return src
end

local function normalizeSource(src)
    return stripShebang(stripBom(src))
end

-- ────────────────────────────────────────────────────────────
-- Сканер require'ов: пропускает комментарии и строки,
-- возвращает массив имён модулей (без дубликатов).
-- ────────────────────────────────────────────────────────────

local function collectRequires(src)
    local names = {}
    local seen  = {}
    local n     = #src
    local i     = 1

    local function add(name)
        if name and name ~= "" and not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end

    -- На позиции pos открывается длинная скобка [[, [=[, [==[ ?
    local function longBracketOpen(pos)
        if src:sub(pos, pos) ~= "[" then return nil end
        local j = pos + 1
        local lvl = 0
        while src:sub(j, j) == "=" do
            lvl = lvl + 1
            j = j + 1
        end
        if src:sub(j, j) == "[" then
            return lvl, j + 1
        end
        return nil
    end

    local function skipLong(pos, lvl)
        local close = "]" .. string.rep("=", lvl) .. "]"
        local _, e = src:find(close, pos, true)
        if e then return e + 1 end
        return n + 1
    end

    local function skipShort(pos, q)
        pos = pos + 1
        while pos <= n do
            local c = src:sub(pos, pos)
            if c == "\\" then
                pos = pos + 2
            elseif c == q then
                return pos + 1
            elseif c == "\n" then
                return pos
            else
                pos = pos + 1
            end
        end
        return pos
    end

    while i <= n do
        local c = src:sub(i, i)

        if c == "-" and src:sub(i + 1, i + 1) == "-" then
            local lvl, cs = longBracketOpen(i + 2)
            if lvl then
                i = skipLong(cs, lvl)
            else
                local nl = src:find("\n", i, true)
                i = nl and (nl + 1) or (n + 1)
            end
        elseif c == "[" then
            local lvl, cs = longBracketOpen(i)
            if lvl then
                i = skipLong(cs, lvl)
            else
                i = i + 1
            end
        elseif c == '"' or c == "'" then
            i = skipShort(i, c)
        elseif c:match("[%a_]") then
            local ws = i
            while i <= n and src:sub(i, i):match("[%w_]") do
                i = i + 1
            end
            if src:sub(ws, i - 1) == "require" then
                local j = i
                while j <= n and src:sub(j, j):match("%s") do j = j + 1 end
                if src:sub(j, j) == "(" then
                    j = j + 1
                    while j <= n and src:sub(j, j):match("%s") do j = j + 1 end
                end
                local q = src:sub(j, j)
                if q == '"' or q == "'" then
                    local k = j + 1
                    local buf = {}
                    while k <= n do
                        local ck = src:sub(k, k)
                        if ck == "\\" then
                            buf[#buf + 1] = src:sub(k + 1, k + 1)
                            k = k + 2
                        elseif ck == q then
                            break
                        else
                            buf[#buf + 1] = ck
                            k = k + 1
                        end
                    end
                    if k <= n then
                        add(table.concat(buf))
                        i = k + 1
                    end
                end
            end
        else
            i = i + 1
        end
    end

    return names
end

-- ────────────────────────────────────────────────────────────
-- Поиск файла модуля по package.path + доп. шаблонам
-- ────────────────────────────────────────────────────────────

local function findModuleFile(name, searchPaths)
    local modPath = name:gsub("%.", SEP)
    for _, tpl in ipairs(searchPaths) do
        local candidate = tpl:gsub("%?", modPath)
        local c = readFile(candidate)
        if c then
            return candidate, c
        end
    end
    return nil
end

-- ────────────────────────────────────────────────────────────
-- Сборка
-- ────────────────────────────────────────────────────────────

local STDLIB = {
    _G = true,
    string = true, table = true, math = true, io = true,
    os = true, coroutine = true, debug = true, package = true,
}

local function bundle(mainFile, outputFile, extraPaths)
    local mainRaw = readFile(mainFile)
    if not mainRaw then
        io.stderr:write("error: cannot read " .. mainFile .. "\n")
        return false
    end
    local mainSrc = normalizeSource(mainRaw)

    -- Поисковый путь: package.path → extraPaths → каталог main/?.lua
    local searchPaths = {}
    for tpl in (package.path or ""):gmatch("[^;]+") do
        searchPaths[#searchPaths + 1] = tpl
    end
    if extraPaths then
        for tpl in extraPaths:gmatch("[^;]+") do
            searchPaths[#searchPaths + 1] = tpl
        end
    end
    local mainDir = mainFile:match("^(.*)[/\\][^/\\]*$") or "."
    searchPaths[#searchPaths + 1] = mainDir .. SEP .. "?.lua"

    -- BFS-сбор модулей
    local modules = {}
    local order   = {}
    local visited = {}
    local queue   = { { name = false, src = mainSrc, path = mainFile } }
    local idx     = 1

    while idx <= #queue do
        local item = queue[idx]
        idx = idx + 1

        for _, dep in ipairs(collectRequires(item.src)) do
            if not STDLIB[dep] and not visited[dep] then
                visited[dep] = true
                local path, content = findModuleFile(dep, searchPaths)
                if path then
                    queue[#queue + 1] = {
                        name = dep,
                        src  = normalizeSource(content),
                        path = path,
                    }
                else
                    io.stderr:write(string.format(
                        "warning: module '%s' (required by %s) not found; "
                        .. "will delegate to runtime require\n",
                        dep, item.path))
                end
            end
        end

        if item.name then
            modules[item.name] = item
            order[#order + 1] = item.name
        end
    end

    -- Генерация
    local out = {}
    local function w(s) out[#out + 1] = s end

    w("--!bundled\n")
    w("-- Generated by bundler.lua. Do not edit.\n")
    w("-- Main: " .. mainFile .. "\n")
    w("-- Date: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    w("-- Modules: " .. tostring(#order) .. "\n")
    w("\n")
    w("local __real_require = require\n")
    w("local __modules = {}\n")
    w("local __cache   = {}\n")
    w("local __loading = {}\n")
    w("\n")
    w("local function __require(name)\n")
    w("    local c = __cache[name]\n")
    w("    if c ~= nil then return c end\n")
    w("    if __loading[name] then\n")
    w("        error(\"bundled require: circular dependency on '\" .. tostring(name) .. \"'\", 2)\n")
    w("    end\n")
    w("    local loader = __modules[name]\n")
    w("    if not loader then\n")
    w("        if __real_require then return __real_require(name) end\n")
    w("        error(\"bundled require: module '\" .. tostring(name) .. \"' not found\", 2)\n")
    w("    end\n")
    w("    __loading[name] = true\n")
    w("    local result = loader(__require)\n")
    w("    __loading[name] = nil\n")
    w("    if result == nil then result = true end\n")
    w("    __cache[name] = result\n")
    w("    package.loaded[name] = result\n")
    w("    return result\n")
    w("end\n")
    w("\n")

    for _, name in ipairs(order) do
        local m = modules[name]
        w("-- ============================================================\n")
        w("-- module: " .. name .. "  (" .. m.path .. ")\n")
        w("-- ============================================================\n")
        w("__modules[" .. string.format("%q", name) .. "] = function(require)\n")
        w(m.src)
        if m.src:sub(-1) ~= "\n" then w("\n") end
        w("end\n\n")
    end

    w("-- ============================================================\n")
    w("-- main\n")
    w("-- ============================================================\n")
    w("(function(require)\n")
    w(mainSrc)
    if mainSrc:sub(-1) ~= "\n" then w("\n") end
    w("end)(__require)\n")

    local code = table.concat(out)

    -- Синтаксическая валидация результата (без исполнения)
    local loader, err
    if loadstring then
        loader, err = loadstring(code, "@" .. outputFile)
    else
        loader, err = load(code, "@" .. outputFile)
    end
    if not loader then
        io.stderr:write("error: generated code has syntax error:\n  "
            .. tostring(err) .. "\n")
        return false
    end

    if not writeFile(outputFile, code) then
        return false
    end

    io.write(string.format(
        "bundled %d module(s) -> %s (%d bytes)\n",
        #order, outputFile, #code))
    return true
end

-- ────────────────────────────────────────────────────────────
-- CLI
-- ────────────────────────────────────────────────────────────

local function main()
    local args = arg or {}
    local mainFile = args[1]
    if not mainFile then
        io.stderr:write("usage: lua bundler.lua <main.lua> [output.lua]\n")
        io.stderr:write("       BUNDLE_SEARCH_PATH=dir1\\?.lua;dir2\\?.lua\n")
        os.exit(2)
    end
    local outputFile = args[2]
    if not outputFile then
        outputFile = mainFile:gsub("%.lua$", "") .. ".bundle.lua"
    end
    local extra = os.getenv("BUNDLE_SEARCH_PATH")
    if not bundle(mainFile, outputFile, extra) then
        os.exit(1)
    end
end

main()