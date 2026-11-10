-- docgen.lua
-- Lua & C# API documentation generator.
-- Usage: lua docgen.lua <input_dir> [output_file]

local inputDir   = arg[1] or "."
local outputFile = arg[2] or "API.md"

local isWindows = package.config:sub(1, 1) == "\\"

--------------------------------------------------------------------------------
-- Utils
--------------------------------------------------------------------------------

local function listSourceFiles(dir)
    dir = dir:gsub("[/\\]+$", "")
    local files = {}
    local cmd
    if isWindows then
        cmd = 'dir /b /s "' .. dir .. '\\*.lua" 2>nul & dir /b /s "' .. dir .. '\\*.cs" 2>nul'
    else
        cmd = 'find "' .. dir .. '" -type f \\( -name "*.lua" -o -name "*.cs" \\) 2>/dev/null'
    end
    local p = io.popen(cmd)
    if not p then return files end
    local seen = {}
    for line in p:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not seen[line] then
            seen[line] = true
            files[#files + 1] = line
        end
    end
    p:close()
    return files
end

local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c
end

local function splitLines(s)
    local t = {}
    for line in (s .. "\n"):gmatch("([^\r\n]*)[\r\n]") do
        t[#t + 1] = line
    end
    return t
end

local function ensureDir(path)
    local dir = path:match("^(.*)[/\\][^/\\]+$")
    if not dir or dir == "" then return end
    if isWindows then
        os.execute('if not exist "' .. dir .. '" mkdir "' .. dir .. '" >nul 2>nul')
    else
        os.execute('mkdir -p "' .. dir .. '"')
    end
end

--------------------------------------------------------------------------------
-- Shared helpers
--------------------------------------------------------------------------------

local function splitTopLevel(s, sep)
    local parts = {}
    local depth = 0
    local start = 1
    local i, n = 1, #s
    while i <= n do
        local c = s:sub(i, i)
        if c == "(" or c == "{" or c == "[" then
            depth = depth + 1
        elseif c == ")" or c == "}" or c == "]" then
            depth = depth - 1
        elseif c == sep and depth == 0 then
            parts[#parts + 1] = s:sub(start, i - 1)
            start = i + 1
        elseif c == '"' or c == "'" then
            local q = c
            i = i + 1
            while i <= n do
                local cc = s:sub(i, i)
                if cc == "\\" then i = i + 1
                elseif cc == q then break end
                i = i + 1
            end
        end
        i = i + 1
    end
    parts[#parts + 1] = s:sub(start)
    return parts
end

local function splitCsTopLevel(s, sep)
    -- Like splitTopLevel, but also tracks <> (C# generics).
    local parts = {}
    local depth, angle = 0, 0
    local start = 1
    local i, n = 1, #s
    while i <= n do
        local c = s:sub(i, i)
        if c == "(" or c == "{" or c == "[" then
            depth = depth + 1
        elseif c == ")" or c == "}" or c == "]" then
            depth = depth - 1
        elseif c == "<" then
            angle = angle + 1
        elseif c == ">" then
            if angle > 0 then angle = angle - 1 end
        elseif c == sep and depth == 0 and angle == 0 then
            parts[#parts + 1] = s:sub(start, i - 1)
            start = i + 1
        elseif c == '"' or c == "'" then
            local q = c
            i = i + 1
            while i <= n do
                local cc = s:sub(i, i)
                if cc == "\\" then i = i + 1
                elseif cc == q then break end
                i = i + 1
            end
        end
        i = i + 1
    end
    parts[#parts + 1] = s:sub(start)
    return parts
end

--------------------------------------------------------------------------------
-- Lua: code cleaning
--------------------------------------------------------------------------------

local function stripCode(lines)
    local cleaned = {}
    local state = nil
    local eqs = ""
    for i, line in ipairs(lines) do
        local out = {}
        local j, n = 1, #line
        while j <= n do
            if state then
                local closeMark = "]" .. eqs .. "]"
                local pos = line:find(closeMark, j, true)
                if pos then
                    j = pos + #closeMark
                    state, eqs = nil, ""
                else
                    j = n + 1
                end
            else
                local c1 = line:sub(j, j)
                local c2 = line:sub(j + 1, j + 1)
                if c1 == "-" and c2 == "-" then
                    local sub = line:sub(j)
                    local e = sub:match("^%-%-%[(=*)%[")
                    if e then
                        state, eqs = "comment", e
                        j = j + 4 + #e
                    else
                        break
                    end
                elseif c1 == "[" then
                    local sub = line:sub(j)
                    local e = sub:match("^%[(=*)%[")
                    if e then
                        state, eqs = "string", e
                        j = j + 2 + #e
                    else
                        out[#out + 1] = c1
                        j = j + 1
                    end
                elseif c1 == '"' or c1 == "'" then
                    local q = c1
                    j = j + 1
                    while j <= n do
                        local cc = line:sub(j, j)
                        if cc == "\\" then j = j + 2
                        elseif cc == q then j = j + 1; break
                        else j = j + 1 end
                    end
                    out[#out + 1] = " "
                else
                    out[#out + 1] = c1
                    j = j + 1
                end
            end
        end
        cleaned[i] = table.concat(out)
    end
    return cleaned
end

local function stripLineComment(s)
    local i, n = 1, #s
    while i <= n do
        local c = s:sub(i, i)
        if c == '"' or c == "'" then
            local q = c
            i = i + 1
            while i <= n do
                local cc = s:sub(i, i)
                if cc == "\\" then i = i + 2
                elseif cc == q then i = i + 1; break
                else i = i + 1 end
            end
        elseif c == "-" and s:sub(i + 1, i + 1) == "-" then
            return s:sub(1, i - 1)
        else
            i = i + 1
        end
    end
    return s
end

--------------------------------------------------------------------------------
-- Lua: block stacks
--------------------------------------------------------------------------------

local function buildBlockStacks(cleaned)
    local stacks = {}
    local stack = {}
    for i, line in ipairs(cleaned) do
        local snap = {}
        for j = 1, #stack do snap[j] = stack[j] end
        stacks[i] = snap

        for token in line:gmatch("[%a_][%w_]*") do
            if token == "function" then
                stack[#stack + 1] = "function"
            elseif token == "if" then
                stack[#stack + 1] = "if"
            elseif token == "for" or token == "while" then
                stack[#stack + 1] = "pending_loop"
            elseif token == "do" then
                if stack[#stack] == "pending_loop" then
                    stack[#stack] = "loop"
                else
                    stack[#stack + 1] = "do"
                end
            elseif token == "repeat" then
                stack[#stack + 1] = "repeat"
            elseif token == "end" then
                if #stack > 0 then stack[#stack] = nil end
            elseif token == "until" then
                if #stack > 0 then stack[#stack] = nil end
            end
        end
    end
    return stacks
end

--------------------------------------------------------------------------------
-- Lua: expression type inference
--------------------------------------------------------------------------------

local function stripOuterParens(s)
    s = s:match("^%s*(.-)%s*$")
    while true do
        if s:sub(1, 1) ~= "(" or s:sub(-1) ~= ")" then break end
        local depth = 0
        local closedAtEnd = false
        local i, n = 1, #s
        while i <= n do
            local c = s:sub(i, i)
            if c == "(" then
                depth = depth + 1
            elseif c == ")" then
                depth = depth - 1
                if depth == 0 then
                    if i == n then closedAtEnd = true end
                    break
                end
            elseif c == '"' or c == "'" then
                local q = c
                i = i + 1
                while i <= n do
                    local cc = s:sub(i, i)
                    if cc == "\\" then i = i + 1
                    elseif cc == q then break end
                    i = i + 1
                end
            end
            i = i + 1
        end
        if not closedAtEnd then break end
        s = s:sub(2, -2):match("^%s*(.-)%s*$")
    end
    return s
end

local function findTopLevelOps(expr)
    local ops = {}
    local depth = 0
    local i, n = 1, #expr
    while i <= n do
        local c = expr:sub(i, i)
        if c == "(" or c == "{" or c == "[" then
            depth = depth + 1
            i = i + 1
        elseif c == ")" or c == "}" or c == "]" then
            depth = depth - 1
            i = i + 1
        elseif c == '"' or c == "'" then
            local q = c
            i = i + 1
            while i <= n do
                local cc = expr:sub(i, i)
                if cc == "\\" then i = i + 2
                elseif cc == q then i = i + 1; break
                else i = i + 1 end
            end
        elseif c:match("[%a_]") then
            local s2, e2 = expr:find("[%a_][%w_]*", i)
            local word = expr:sub(s2, e2)
            if depth == 0 then
                if (word == "and" or word == "or" or word == "not")
                   and not ops[word] then
                    ops[word] = s2
                end
            end
            i = e2 + 1
        elseif depth == 0 then
            local two = expr:sub(i, i + 1)
            if two == ".." or two == "==" or two == "~="
               or two == "<=" or two == ">=" then
                if not ops[two] then ops[two] = i end
                i = i + 2
            else
                if c == "+" or c == "-" or c == "*" or c == "/"
                   or c == "%" or c == "^" or c == "<" or c == ">" then
                    if not ops[c] then ops[c] = i end
                end
                i = i + 1
            end
        else
            i = i + 1
        end
    end
    return ops
end

local function splitAtLastTop(expr, kw)
    local depth = 0
    local i, n = 1, #expr
    local lastS, lastE
    while i <= n do
        local c = expr:sub(i, i)
        if c == "(" or c == "{" or c == "[" then
            depth = depth + 1
            i = i + 1
        elseif c == ")" or c == "}" or c == "]" then
            depth = depth - 1
            i = i + 1
        elseif c == '"' or c == "'" then
            local q = c
            i = i + 1
            while i <= n do
                local cc = expr:sub(i, i)
                if cc == "\\" then i = i + 2
                elseif cc == q then i = i + 1; break
                else i = i + 1 end
            end
        elseif c:match("[%a_]") then
            local s2, e2 = expr:find("[%a_][%w_]*", i)
            local word = expr:sub(s2, e2)
            if depth == 0 and word == kw then lastS, lastE = s2, e2 end
            i = e2 + 1
        else
            i = i + 1
        end
    end
    if lastS then
        return expr:sub(1, lastS - 1), expr:sub(lastE + 1)
    end
    return nil
end

local inferType
inferType = function(expr)
    expr = expr:match("^%s*(.-)%s*$")
    if expr == "" then return "nil" end
    expr = stripOuterParens(expr)
    if expr == "" then return "nil" end

    if expr == "nil" then return "nil" end
    if expr == "true" or expr == "false" then return "boolean" end

    if expr:match("^0[xX]%x+$") or expr:match("^%-?%d+$")
       or expr:match("^%-?%d*%.%d+$") or expr:match("^%-?%d+%.%d*$")
       or expr:match("^%-?%d+[eE][%+%-]?%d+$") then
        return "number"
    end

    if expr:match('^".*"$') or expr:match("^'.*'$")
       or expr:match("^%[=*%[") then
        return "string"
    end
    if expr:match("^{") then return "table" end
    if expr:match("^function[%s%(]") then return "function" end

    if expr:sub(1, 1) == "#" then return "number" end
    if expr:match("^not[%s%(]") then return "boolean" end

    local ops = findTopLevelOps(expr)

    if ops[".."] then return "string" end
    if ops["=="] or ops["~="] or ops["<"] or ops[">"]
       or ops["<="] or ops[">="] then
        return "boolean"
    end

    if ops["or"] then
        local l, r = splitAtLastTop(expr, "or")
        if l and r then
            local andL, andR = splitAtLastTop(l, "and")
            local a, b
            if andL and andR then
                a = andR
                b = r
            else
                a = l
                b = r
            end
            local ta = inferType(a)
            local tb = inferType(b)
            if ta == tb then return ta end
            if ta == "nil" then return tb end
            if tb == "nil" then return ta end
            return "any"
        end
    end

    if ops["and"] then
        local _, r = splitAtLastTop(expr, "and")
        if r then
            local tr = inferType(r)
            if tr == "boolean" then return "boolean" end
            return "any"
        end
    end

    if ops["+"] or ops["-"] or ops["*"] or ops["/"]
       or ops["%"] or ops["^"] then
        return "number"
    end

    return "any"
end

--------------------------------------------------------------------------------
-- Lua: comment parsing
--------------------------------------------------------------------------------

local function collectComments(lines, endIdx)
    local buf = {}
    local i = endIdx
    while i >= 1 do
        local trimmed = lines[i]:match("^%s*(.-)%s*$")
        if trimmed:match("^%-%-") then
            buf[#buf + 1] = trimmed
            i = i - 1
        else
            break
        end
    end
    local out = {}
    for j = #buf, 1, -1 do out[#out + 1] = buf[j] end
    return out
end

local function parseModuleComment(commentLines)
    local out = {}
    for _, line in ipairs(commentLines) do
        local body = line:match("^%-%-%-?(.*)$")
        if body then
            body = body:gsub("^ ", "")
            out[#out + 1] = body
        else
            out[#out + 1] = ""
        end
    end
    return table.concat(out, "\n")
end

local function parseDocComment(commentLines)
    local desc, params, returns = {}, {}, {}
    for _, line in ipairs(commentLines) do
        local body = line:match("^%-%-%-?(.*)$")
        if body then
            body = body:match("^%s*(.-)%s*$")
            local pname, ptype, pdesc = body:match(
                "^@param%s+([%w_%.]+)%s+([%w_%[%]%{%},|]+)%s*(.*)$")
            if pname then
                params[#params + 1] = {
                    name = pname, type = ptype, desc = pdesc or "",
                }
            else
                local rlist = body:match("^@return%s+(.+)$")
                if rlist then
                    for part in rlist:gmatch("[^,]+") do
                        part = part:match("^%s*(.-)%s*$")
                        local rtype, rdesc = part:match(
                            "^([%w_%[%]%{%},|]+)%s*(.*)$")
                        if rtype then
                            returns[#returns + 1] = {
                                type = rtype, desc = rdesc or "",
                            }
                        end
                    end
                elseif body ~= "" then
                    desc[#desc + 1] = body
                end
            end
        end
    end
    return table.concat(desc, " "), params, returns
end

--------------------------------------------------------------------------------
-- Lua: function detection
--------------------------------------------------------------------------------

local FUNC_PATTERNS = {
    "^%s*local%s+function%s+([%w_%.%:]+)%s*%((.-)%)",
    "^%s*function%s+([%w_%.%:]+)%s*%((.-)%)",
    "^%s*local%s+([%w_]+)%s*=%s*function%s*%((.-)%)",
    "^%s*([%w_%.%:]+)%s*=%s*function%s*%((.-)%)",
}

local function detectFunc(line)
    for _, pat in ipairs(FUNC_PATTERNS) do
        local name, argsStr = line:match(pat)
        if name then return name, argsStr or "" end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Lua: file parsing
--------------------------------------------------------------------------------

local function parseLuaFile(path)
    local content = readFile(path)
    if not content then return nil end
    local lines = splitLines(content)
    local cleaned = stripCode(lines)
    local stacks = buildBlockStacks(cleaned)

    local result = { path = path, lang = "lua", moduleDesc = "", functions = {} }

    local topBuf, started = {}, false
    for i = 1, #lines do
        local trimmed = lines[i]:match("^%s*(.-)%s*$")
        if trimmed:match("^%-%-") then
            topBuf[#topBuf + 1] = trimmed
            started = true
        elseif trimmed == "" and started then
            topBuf[#topBuf + 1] = trimmed
        else
            break
        end
    end
    if #topBuf > 0 then
        result.moduleDesc = parseModuleComment(topBuf) or ""
    end

    for i = 1, #lines do
        local name, argsStr = detectFunc(cleaned[i])
        if name then
            local baseDepth = #stacks[i]
            local endLine = #lines
            for k = i, #lines do
                if k + 1 > #lines then
                    endLine = k
                    break
                end
                if #stacks[k + 1] <= baseDepth then
                    endLine = k
                    break
                end
            end

            local comments = collectComments(lines, i - 1)
            local desc, params, returns = parseDocComment(comments)

            if #params == 0 and argsStr ~= "" then
                for raw in argsStr:gmatch("[^,]+") do
                    local pname = raw:match("^%s*([%w_%.]+)")
                    if pname then
                        params[#params + 1] =
                            { name = pname, type = "any", desc = "" }
                    end
                end
            end

            if #returns == 0 then
                local seen = {}
                for k = i, endLine do
                    local stk = stacks[k]
                    local inNestedFn = false
                    for j = baseDepth + 2, #stk do
                        if stk[j] == "function" then
                            inNestedFn = true
                            break
                        end
                    end

                    if not inNestedFn then
                        local cl = cleaned[k]
                        if cl:match("^%s*return%s+")
                           or cl:match("^%s*return%s*$") then
                            local orig = stripLineComment(lines[k])
                            local origExpr = orig:match("^%s*return%s*(.-)%s*$") or ""
                            origExpr = origExpr:gsub("%send%s*$", "")
                            origExpr = origExpr:gsub(";%s*$", "")
                            origExpr = origExpr:match("^%s*(.-)%s*$")

                            local cleanStripped = cl:match("^%s*(.-)%s*$")
                            local cleanExpr =
                                cleanStripped:match("^return%s*(.*)$") or ""
                            cleanExpr = cleanExpr:gsub("%send%s*$", "")
                            cleanExpr = cleanExpr:gsub(";%s*$", "")
                            cleanExpr = cleanExpr:match("^%s*(.-)%s*$")

                            if origExpr ~= "" then
                                local origParts = splitTopLevel(origExpr, ",")
                                local cleanParts = splitTopLevel(cleanExpr, ",")
                                for idx, e in ipairs(cleanParts) do
                                    e = e:match("^%s*(.-)%s*$")
                                    local eOrig = origParts[idx] or e
                                    eOrig = eOrig:match("^%s*(.-)%s*$")
                                    if e ~= "" then
                                        local t = inferType(e)
                                        local key = t .. "|" .. e
                                        if not seen[key] then
                                            seen[key] = true
                                            returns[#returns + 1] = {
                                                type = t,
                                                desc = eOrig,
                                                auto = true,
                                            }
                                        end
                                    end
                                end
                            else
                                local key = "nil|"
                                if not seen[key] then
                                    seen[key] = true
                                    returns[#returns + 1] = {
                                        type = "nil",
                                        desc = "",
                                        auto = true,
                                    }
                                end
                            end
                        end
                    end
                end
            end

            result.functions[#result.functions + 1] = {
                name    = name,
                desc    = desc,
                params  = params,
                returns = returns,
                line    = i,
            }
        end
    end

    return result
end
--------------------------------------------------------------------------------
-- C#: helpers and parsing
--------------------------------------------------------------------------------

local CS_MODIFIERS = {
    "public", "private", "protected", "internal",
    "static", "virtual", "override", "abstract",
    "async", "sealed", "extern", "new", "unsafe",
    "readonly", "partial", "const", "volatile",
    "ref", "out", "in", "scoped",
}

local CS_TYPE_KWS = { "class", "struct", "interface", "enum", "record" }
local CS_ACCESS   = { "public", "private", "protected", "internal" }

local function hasWord(s, w)
    return s:find("%f[%w_]" .. w .. "%f[^%w_]") ~= nil
end

local function stripCsStringsAndComments(line)
    local out = {}
    local i, n = 1, #line
    while i <= n do
        local c = line:sub(i, i)
        if c == '"' or c == "'" then
            local q = c
            i = i + 1
            while i <= n do
                local cc = line:sub(i, i)
                if cc == "\\" then i = i + 2
                elseif cc == q then i = i + 1; break
                else i = i + 1 end
            end
            out[#out + 1] = " "
        elseif c == "/" and line:sub(i + 1, i + 1) == "/" then
            break
        else
            out[#out + 1] = c
            i = i + 1
        end
    end
    return table.concat(out)
end

local function detectCsType(line)
    local s = line:match("^%s*(.-)%s*$")
    for _, kw in ipairs(CS_TYPE_KWS) do
        local kwPos = s:find("%f[%w_]" .. kw .. "%f[^%w_]")
        if kwPos then
            local prefix = s:sub(1, kwPos - 1)
            if not prefix:find("[%(%)%.%=]") then
                local rest = s:sub(kwPos + #kw)
                local name = rest:match("^%s+([%a_][%w_]*)")
                if name == "class" or name == "struct" then
                    local realName = rest:match("^%s+%a+%s+([%a_][%w_]*)")
                    if realName then return name, realName end
                elseif name then
                    return kw, name
                end
            end
        end
    end
    return nil
end
 local CS_STMT_KWS = {
    "if", "else", "for", "foreach", "while", "do", "switch", "case",
    "default", "try", "catch", "finally", "throw", "using", "lock",
    "return", "yield", "break", "continue", "goto", "new", "checked",
    "unchecked", "sizeof", "typeof", "nameof", "ref", "out", "in",
    "is", "as", "when", "where", "select", "from", "let", "orderby",
    "join", "on", "equals", "by", "ascending", "descending", "group",
    "into", "var", "null", "true", "false", "this", "base",
    "await", "async",
}

local CS_STMT_KW_SET = {}
for _, kw in ipairs(CS_STMT_KWS) do CS_STMT_KW_SET[kw] = true end

local function detectCsMethod(line)
    local s = line:match("^%s*(.-)%s*$")

    local hasAccess = false
    for _, mod in ipairs(CS_ACCESS) do
        if hasWord(s, mod) then hasAccess = true; break end
    end

    local parenStart = s:find("%(")
    if not parenStart then return nil end

    local depth = 0
    local parenEnd = nil
    local j = parenStart
    while j <= #s do
        local c = s:sub(j, j)
        if c == "(" then
            depth = depth + 1
        elseif c == ")" then
            depth = depth - 1
            if depth == 0 then parenEnd = j; break end
        elseif c == '"' or c == "'" then
            local q = c
            j = j + 1
            while j <= #s do
                local cc = s:sub(j, j)
                if cc == "\\" then j = j + 1
                elseif cc == q then break end
                j = j + 1
            end
        end
        j = j + 1
    end
    if not parenEnd then return nil end

    local rest = s:sub(parenEnd + 1):match("^%s*(.-)%s*$")
    if rest ~= ""
       and not rest:match("^[{=>;]")
       and not rest:match("^where%f[^%w_]") then
        return nil
    end

    local before = s:sub(1, parenStart - 1)
    local name = before:match("([%a_][%w_]*)%s*$")
    if not name then return nil end

    local prefix = before:match("^(.-)%s+[%a_][%w_]*%s*$") or ""
    local rest2 = prefix:gsub("%[.-%]", " ")
    for _, mod in ipairs(CS_MODIFIERS) do
        rest2 = rest2:gsub("%f[%w_]" .. mod .. "%f[^%w_]", " ")
    end
    rest2 = rest2:match("^%s*(.-)%s*$")

    if rest2:find("[%(%)=]") then return nil end

    local argsStr = s:sub(parenStart + 1, parenEnd - 1)

    if hasAccess then
        -- Same permissive path as before.
        if rest2 == "" then
            return name, argsStr, "void", true
        end
        return name, argsStr, rest2, false
    end

    -- ---- no access modifier: strict heuristics ----
    if CS_STMT_KW_SET[name] then return nil end
    if rest2:find("[{}]") then return nil end
    if rest2:find("%.") then return nil end

    if rest2 == "" then
        -- Possible ctor without access: must be followed by `{` and start uppercase.
        if rest:match("^{") and name:match("^[A-Z]") then
            return name, argsStr, "void", true
        end
        return nil
    end

    return name, argsStr, rest2, false
end
local function joinDeclarationHead(stripped, startIdx, maxLines)
    maxLines = maxLines or 30
    local buf = {}
    local paren = 0
    local bracket = 0
    for j = startIdx, math.min(#stripped, startIdx + maxLines - 1) do
        local s = stripped[j]
        local trimmed = s:match("^%s*(.-)%s*$")
        if j > startIdx and paren == 0 and bracket == 0 then
            local isNew = false
            for _, mod in ipairs(CS_ACCESS) do
                if trimmed:match("^" .. mod .. "%f[^%w_]") then isNew = true; break end
            end
            if not isNew then
                for _, kw in ipairs(CS_TYPE_KWS) do
                    if trimmed:match("^" .. kw .. "%f[^%w_]") then isNew = true; break end
                end
            end
            if isNew then return nil end
        end
        buf[#buf + 1] = s
        local i, n = 1, #s
        while i <= n do
            local c = s:sub(i, i)
            if c == "(" then paren = paren + 1
            elseif c == ")" then paren = paren - 1
            elseif c == "[" then bracket = bracket + 1
            elseif c == "]" then bracket = bracket - 1
            elseif c == "{" and paren == 0 and bracket == 0 then
                return table.concat(buf, " "), j
            elseif c == ";" and paren == 0 and bracket == 0 then
                return table.concat(buf, " "), j
            end
            i = i + 1
        end
    end
    return nil
end

local function collectXmlComments(lines, endIdx)
    local buf = {}
    local i = endIdx
    while i >= 1 do
        local trimmed = lines[i]:match("^%s*(.-)%s*$")
        if trimmed:match("^///") then
            buf[#buf + 1] = trimmed
            i = i - 1
        else
            break
        end
    end
    local out = {}
    for j = #buf, 1, -1 do out[#out + 1] = buf[j] end
    return out
end

local function parseXmlDoc(commentLines)
    local summary, params, returns = {}, {}, {}

    local state = "other"
    local currentParam = nil
    local currentParamBuf = {}
    local currentReturnsBuf = {}

    local function flushParam()
        if currentParam then
            params[#params + 1] = {
                name = currentParam,
                type = "any",
                desc = table.concat(currentParamBuf, " "):match("^%s*(.-)%s*$"),
            }
            currentParam, currentParamBuf = nil, {}
        end
    end
    local function flushReturns()
        if #currentReturnsBuf > 0 then
            returns[#returns + 1] = {
                type = "any",
                desc = table.concat(currentReturnsBuf, " "):match("^%s*(.-)%s*$"),
            }
            currentReturnsBuf = {}
        end
    end

    for _, line in ipairs(commentLines) do
        local body = line:match("^///%s?(.*)$") or ""
        body = body:match("^%s*(.-)%s*$")

        local s1 = body:match("<summary>(.-)</summary>")
        local s2name, s2body = body:match('<param%s+name="([^"]+)"%s*>(.-)</param>')
        local s3 = body:match("<returns>(.-)</returns>")

        if s1 then
            flushParam(); flushReturns()
            summary[#summary + 1] = s1; state = "summary"
        elseif s2name then
            flushParam(); flushReturns()
            params[#params + 1] = { name = s2name, type = "any", desc = s2body }
            state = "other"
        elseif s3 then
            flushParam(); flushReturns()
            returns[#returns + 1] = { type = "any", desc = s3 }
            state = "other"
        elseif body:match("^<summary>%s*$") then
            flushParam(); flushReturns(); state = "summary"
        elseif body:match("^</summary>%s*$") then
            state = "other"
        elseif body:match('^<param%s+name="[^"]+"%s*>%s*$') then
            flushParam(); flushReturns()
            currentParam = body:match('^<param%s+name="([^"]+)"')
            state = "param"
        elseif body:match("^</param>%s*$") then
            flushParam(); state = "other"
        elseif body:match("^<returns>%s*$") then
            flushParam(); flushReturns(); state = "returns"
        elseif body:match("^</returns>%s*$") then
            flushReturns(); state = "other"
        elseif body:match("^<[%w]") then
            state = "other"
        elseif body == "" then
            -- blank
        else
            if state == "summary" then
                summary[#summary + 1] = body
            elseif state == "param" then
                currentParamBuf[#currentParamBuf + 1] = body
            elseif state == "returns" then
                currentReturnsBuf[#currentReturnsBuf + 1] = body
            end
        end
    end

    flushParam(); flushReturns()
    return table.concat(summary, " "):match("^%s*(.-)%s*$"), params, returns
end

local function parseCsParams(argsStr)
    local params = {}
    if not argsStr or argsStr == "" then return params end
    for _, part in ipairs(splitCsTopLevel(argsStr, ",")) do
        part = part:match("^%s*(.-)%s*$")
        if part ~= "" then
            part = part:gsub("%s*=[^=].*$", "")
            local ptype, pname = part:match("^(.+)%s+([%a_][%w_]*)$")
            if ptype and pname then
                for _, mod in ipairs({ "this", "params", "ref", "out", "in", "scoped" }) do
                    ptype = ptype:gsub("^%s*" .. mod .. "%f[^%w_]%s*", "")
                end
                ptype = ptype:match("^%s*(.-)%s*$")
                params[#params + 1] = { name = pname, type = ptype, desc = "" }
            end
        end
    end
    return params
end

local function parseCsModuleComment(commentLines)
    local out = {}
    for _, line in ipairs(commentLines) do
        local body = line:match("^///%s?(.*)$") or line:match("^//%s?(.*)$")
        if body then out[#out + 1] = body end
    end
    return table.concat(out, "\n")
end

local function parseCsFile(path)
    local content = readFile(path)
    if not content then return nil end
    local lines = splitLines(content)

    local stripped = {}
    for i = 1, #lines do
        stripped[i] = stripCsStringsAndComments(lines[i])
    end

    local result = {
        path = path, lang = "csharp",
        moduleDesc = "", classes = {}, functions = {},
    }

    local topBuf, started = {}, false
    for i = 1, #lines do
        local trimmed = lines[i]:match("^%s*(.-)%s*$")
        if trimmed:match("^///") or trimmed:match("^//") then
            topBuf[#topBuf + 1] = trimmed; started = true
        elseif trimmed == "" and started then
            topBuf[#topBuf + 1] = trimmed
        else
            break
        end
    end
    if #topBuf > 0 then
        result.moduleDesc = parseCsModuleComment(topBuf) or ""
    end

    local depth = 0
    local levelOwner = {}
    local pendingClass = nil

    local i = 1
    while i <= #lines do
        local s = stripped[i]:match("^%s*(.-)%s*$")

        if s == "" then
            i = i + 1
        else
            local kind, typeName = detectCsType(s)
            local mname, argsStr, rtype, isCtor
            if not kind then
                mname, argsStr, rtype, isCtor = detectCsMethod(s)
            end

            local endIdx = i

            if not kind and not mname then
                local maybeStart = false
                for _, mod in ipairs(CS_ACCESS) do
                    if hasWord(s, mod) then maybeStart = true; break end
                end
                if not maybeStart then
                    for _, kw in ipairs(CS_TYPE_KWS) do
                        if hasWord(s, kw) then maybeStart = true; break end
                    end
                end

                if maybeStart then
                    local joined, j = joinDeclarationHead(stripped, i)
                    if joined then
                        local jk, jtn = detectCsType(joined)
                        if jk then
                            kind, typeName = jk, jtn
                            endIdx = j
                        else
                            local jm, ja, jr, jc = detectCsMethod(joined)
                            if jm then
                                mname, argsStr, rtype, isCtor = jm, ja, jr, jc
                                endIdx = j
                            end
                        end
                    end
                end
            end

            if kind and typeName then
                local xml = collectXmlComments(lines, i - 1)
                local desc = parseXmlDoc(xml)
                local cls = {
                    kind = kind, name = typeName, desc = desc,
                    line = i, methods = {}, depth = depth,
                }
                result.classes[#result.classes + 1] = cls
                pendingClass = cls
            elseif mname then
                local xml = collectXmlComments(lines, i - 1)
                local mdesc, docParams, docReturns = parseXmlDoc(xml)

                local csParams = parseCsParams(argsStr or "")
                for _, p in ipairs(csParams) do
                    for _, dp in ipairs(docParams) do
                        if dp.name == p.name then
                            p.desc = dp.desc; break
                        end
                    end
                end
                for _, dp in ipairs(docParams) do
                    local found = false
                    for _, p in ipairs(csParams) do
                        if p.name == dp.name then found = true; break end
                    end
                    if not found then csParams[#csParams + 1] = dp end
                end

                local method = {
                    name = mname, returnType = rtype, isCtor = isCtor,
                    desc = mdesc, params = csParams,
                    returns = docReturns, line = i,
                }
                local owner = levelOwner[depth]
                if owner then
                    owner.methods[#owner.methods + 1] = method
                else
                    result.functions[#result.functions + 1] = method
                end
            end

            for k = i, endIdx do
                for c in stripped[k]:gmatch("[{};]") do
                    if c == "{" then
                        depth = depth + 1
                        if pendingClass then
                            levelOwner[depth] = pendingClass
                            pendingClass = nil
                        else
                            levelOwner[depth] = levelOwner[depth - 1]
                        end
                    elseif c == "}" then
                        levelOwner[depth] = nil
                        depth = depth - 1
                    elseif c == ";" and depth == 0 and pendingClass then
                        pendingClass = nil
                    end
                end
            end

            i = endIdx + 1
        end
    end

    return result
end

--------------------------------------------------------------------------------
-- Dispatcher
--------------------------------------------------------------------------------

local function parseFile(path)
    local ext = path:match("%.([%w]+)$")
    if ext == "lua" then
        return parseLuaFile(path)
    elseif ext == "cs" then
        return parseCsFile(path)
    end
    return nil
end

--------------------------------------------------------------------------------
-- Markdown generation
--------------------------------------------------------------------------------

local function renderParamTable(w, params)
    w("**Parameters:**")
    w("")
    w("| Name | Type | Description |")
    w("|------|------|-------------|")
    for _, p in ipairs(params) do
        w(string.format("| `%s` | `%s` | %s |",
            p.name or "", p.type or "any", p.desc or ""))
    end
    w("")
end

local function renderLuaFunction(w, fn)
    w("### `" .. fn.name .. "`")
    w("")
    if fn.desc and fn.desc ~= "" then w(fn.desc); w("") end
    if #fn.params > 0 then renderParamTable(w, fn.params) end
    if #fn.returns > 0 then
        w("**Returns:**")
        w("")
        for _, r in ipairs(fn.returns) do
            if r.auto then
                if r.desc and r.desc ~= "" then
                    w("- `" .. (r.type or "any") ..
                        "` ← `return " .. r.desc .. "`")
                else
                    w("- `" .. (r.type or "any") .. "`")
                end
            else
                w("- `" .. (r.type or "any") .. "`" ..
                    (r.desc ~= "" and (" — " .. r.desc) or ""))
            end
        end
        w("")
    end
end

local function renderCsMethod(w, m)
    w("#### `" .. m.name .. "`")
    w("")
    if m.desc and m.desc ~= "" then w(m.desc); w("") end
    if #m.params > 0 then renderParamTable(w, m.params) end
    local hasType = m.returnType and m.returnType ~= "void"
    local hasDesc = #m.returns > 0
    if hasType or hasDesc then
        w("**Returns:**")
        w("")
        local rtype = hasType and m.returnType or "any"
        local rdesc = hasDesc and m.returns[1].desc or ""
        w("- `" .. rtype .. "`" .. (rdesc ~= "" and (" — " .. rdesc) or ""))
        w("")
    end
end

local function generate(docs, outputPath)
    ensureDir(outputPath)

    local luaDocs, csDocs = {}, {}
    for _, d in ipairs(docs) do
        if d.lang == "csharp" then csDocs[#csDocs + 1] = d
        else luaDocs[#luaDocs + 1] = d end
    end
    table.sort(luaDocs, function(a, b) return a.path < b.path end)
    table.sort(csDocs,  function(a, b) return a.path < b.path end)

    local out = {}
    local function w(s) out[#out + 1] = s or "" end

    w("# API Documentation")
    w("")
    w("Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
    w("")
    w("Total files: " .. #docs ..
        " (Lua: " .. #luaDocs .. ", C#: " .. #csDocs .. ")")
    w("")

    w("## Contents")
    w("")
    if #luaDocs > 0 then
        w("### Lua")
        w("")
        for _, doc in ipairs(luaDocs) do
            w("- [" .. doc.path .. "](#" ..
                doc.path:gsub("[^%w]", "-"):lower() .. ")")
        end
        w("")
    end
    if #csDocs > 0 then
        w("### C#")
        w("")
        for _, doc in ipairs(csDocs) do
            w("- [" .. doc.path .. "](#" ..
                doc.path:gsub("[^%w]", "-"):lower() .. ")")
        end
        w("")
    end

    for _, doc in ipairs(luaDocs) do
        w("---")
        w("")
        w("## File: `" .. doc.path .. "` (Lua)")
        w("")
        if doc.moduleDesc and doc.moduleDesc ~= "" then
            w(doc.moduleDesc); w("")
        end
        if #doc.functions == 0 then
            w("_No functions found._"); w("")
        else
            for _, fn in ipairs(doc.functions) do
                renderLuaFunction(w, fn)
            end
        end
    end

    for _, doc in ipairs(csDocs) do
        w("---")
        w("")
        w("## File: `" .. doc.path .. "` (C#)")
        w("")
        if doc.moduleDesc and doc.moduleDesc ~= "" then
            w(doc.moduleDesc); w("")
        end
        if #doc.classes == 0 and #doc.functions == 0 then
            w("_No classes or methods found._"); w("")
        end
        for _, cls in ipairs(doc.classes) do
            local kindLabel = cls.kind:sub(1,1):upper() .. cls.kind:sub(2)
            w("### " .. kindLabel .. " `" .. cls.name .. "`")
            w("")
            if cls.desc and cls.desc ~= "" then w(cls.desc); w("") end
            for _, m in ipairs(cls.methods) do
                renderCsMethod(w, m)
            end
        end
        for _, fn in ipairs(doc.functions) do
            w("### `" .. fn.name .. "`")
            w("")
            if fn.desc and fn.desc ~= "" then w(fn.desc); w("") end
            if #fn.params > 0 then renderParamTable(w, fn.params) end
        end
    end

    local f = io.open(outputPath, "w")
    if not f then
        print("Error: cannot write " .. outputPath)
        return false
    end
    f:write(table.concat(out, "\n"))
    f:close()
    return true
end

--------------------------------------------------------------------------------
-- main
--------------------------------------------------------------------------------

local function main()
    print("Scanning: " .. inputDir)
    local files = listSourceFiles(inputDir)
    if #files == 0 then
        print("No .lua or .cs files found.")
        return
    end
    local docs = {}
    for _, path in ipairs(files) do
        print("  parsing: " .. path)
        local d = parseFile(path)
        if d then docs[#docs + 1] = d end
    end
    if generate(docs, outputFile) then
        print("Done -> " .. outputFile)
    end
end

main()