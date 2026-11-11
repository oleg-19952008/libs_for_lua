# libs_for_lua

[English](#english) | [Русский](#русский)

---

## English

A collection of standalone Lua libraries. Each file is a single module with no external dependencies: copy the file you need into your project and `require` it.

> **How this was made:** the code was written by AI under human direction. The human wrote the specs, tested the results, filed bug reports and made the AI fix them, over and over. Treat it as a hand-tested, AI-written codebase: read the code before relying on it in anything critical.

### Contents

- [Modules overview](#modules-overview)
- [Installation](#installation)
- [base64.lua](#base64lua)
- [color.lua](#colorlua)
- [paths.lua](#pathslua-windows-only)
- [random.lua](#randomlua)
- [bundler.lua](#bundlerlua-command-line-tool)
- [docgen.lua](#docgenlua-command-line-tool)
- [Reporting bugs](#reporting-bugs)
- [License and terms of use](#license-and-terms-of-use)

### Modules overview

| File | What it does | Lua version | Platform |
| ---- | ------------ | ----------- | -------- |
| [`base64.lua`](base64.lua) | Base64 encode/decode, standard and URL-safe (RFC 4648) | 5.1+ | any |
| [`color.lua`](color.lua) | ANSI colors and styles, UTF-8 aware string width, padding, truncation | 5.1, 5.2, 5.3, 5.4, LuaJIT | any |
| [`paths.lua`](paths.lua) | Path parsing and joining, file/dir checks, directory listing, CWD, script directory | 5.1.4+ | **Windows only** |
| [`random.lua`](random.lua) | Random byte generator (`math.random` based) | 5.1.4+ | any |
| [`bundler.lua`](bundler.lua) | **Command-line tool:** bundles a script and its `require`d modules into one file | 5.1.4+ (also 5.2-5.4) | any |
| [`docgen.lua`](docgen.lua) | **Command-line tool:** API documentation generator for Lua and C# | 5.1+ | any |

### Installation

There is nothing to install. Copy the `.lua` file you need next to your script (or into a folder on `package.path`) and load it:

```lua
local b64 = require('base64')
```

`bundler.lua` and `docgen.lua` are not libraries: they are scripts you run with `lua`.

---

### base64.lua

Compact Base64 codec for Lua 5.1+ with no dependencies. Supports the standard (RFC 4648) and URL-safe (RFC 4648 §5) alphabets.

```lua
local b64 = require('base64')

b64.encode('hello')       --> 'aGVsbG8='
b64.encode_url('hello')   --> 'aGVsbG8'     (URL-safe, no padding)

b64.decode('aGVsbG8=')    --> 'hello'
b64.decode('aGVsbG8')     --> 'hello'       (padding is optional)
b64.decode('!!!')         --> nil, 'invalid base64 character'
b64.decode('a')           --> nil, 'invalid base64 length'
```

| Function | Description |
| -------- | ----------- |
| `b64.encode(data, url_safe)` | Encodes a string to Base64. With `url_safe = true`: `+` → `-`, `/` → `_`, and all `=` padding is removed. Raises an error if `data` is not a string. |
| `b64.encode_url(data)` | URL-safe Base64 without padding. Same as `b64.encode(data, true)`. |
| `b64.decode(data)` | Decodes standard and URL-safe Base64 at the same time (`-` and `_` are treated as `+` and `/`). Whitespace is ignored, `=` padding is optional. Returns the decoded bytes, or `nil, err` instead of throwing: `'invalid base64 length'` (length without padding gives `#data % 4 == 1`) or `'invalid base64 character'`. Raises an error only if `data` is not a string. |
| `b64.decode_url(data)` | Alias of `b64.decode`, for symmetry with `encode_url`. |

---

### color.lua

Extended ANSI library for Lua 5.1, 5.2, 5.3, 5.4 and LuaJIT. Colors (16, 256, true-color, HEX), text styles, a fluent builder, and UTF-8 aware string helpers (width in terminal columns, padding, truncation). Respects `NO_COLOR` and `FORCE_COLOR`.

```lua
local color = require('color')

print(color.color('Hello!', 'bold', 'red'))
print(color.color('Error', 'fg:bright_red', 'bg:black', 'underline'))
print(color.color('palette', 'fg256:208'))
print(color.color('true color', 'fgRGB:255;100;0'))
print(color.color('hot pink', 'fgHex:#ff69b4'))

-- Builder
print(color.builder():bold():fg('bright_yellow'):bg('navy'):text('  Attention!  '):render())

-- UTF-8 aware helpers (ANSI codes are ignored)
color.len('日本語')       --> 3   (codepoints)
color.width('日本語')     --> 6   (terminal columns)
color.truncate('Привет, мир!', 8)   --> 'Привет,…'
```

> The comments inside `color.lua` call the module `ansi` (its old name). Use `require('color')`.

#### Color support detection

Colors are enabled automatically when the output looks like it supports them:

- `NO_COLOR` set to a non-empty value: colors **off**. `FORCE_COLOR` set (and not `0`): colors **on**. `TERM=dumb`: off.
- Unix: `io.stdout:isatty()` if available, otherwise a heuristic from `TERM` / `COLORTERM`.
- Windows: on when `WT_SESSION`, `ANSICON`, `ConEmuANSI=ON` or `TERM_PROGRAM` is present. Old `cmd.exe` gets no colors. Switching on Windows VT mode is done through the LuaJIT FFI, so without LuaJIT it is not enabled.
- When colors are off, every function returns the plain text without ANSI codes.

#### Enable / disable

| Function | Description |
| -------- | ----------- |
| `color.set_enabled(v)` | Force colors on or off (also available as the field `color.enabled`). |
| `color.enable()` / `color.disable()` | Shortcuts. |
| `color.is_enabled()` | Whether colors are currently on. |

#### Coloring text

| Function | Description |
| -------- | ----------- |
| `color.color(text, ...)` | Returns `text` wrapped in the styles given by the extra arguments (see specs below). Invalid specs are silently ignored. |
| `color.write_color(text, ...)` | Same, writes to stdout. |
| `color.writeln_color(text, ...)` | Same, plus a newline. |
| `color.RESET()` | Returns the reset sequence `ESC[0m` (an empty string when colors are off). |

**Style specs** (arguments after `text`):

| Spec | Example | Meaning |
| ---- | ------- | ------- |
| Foreground name | `'red'`, `'bright_red'`, `'fg:red'` | Entry of `color.fg` |
| Background name | `'bg:red'` | Entry of `color.bg` |
| Palette name | `'orange'`, `'bg:navy'` | Entry of `color.palette` (256-color) |
| Style | `'bold'`, `'underline'` | Entry of `color.style` |
| 256 colors | `'fg256:208'`, `'bg256:17'` | |
| RGB | `'fgRGB:255;100;0'`, `'bgRGB:0;0;0'` | |
| HEX | `'#ff69b4'`, `'fgHex:#ff69b4'`, `'bgHex:#222222'` | `#RGB` and `#RRGGBB`; a bare `'#...'` is foreground |
| Raw SGR | `'1;31'` or the number `31` | Inserted as is |

Available tables: `color.fg` (`black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, `default`, `bright_*`, `gray`/`grey`, `light_*`), `color.bg`, `color.style` (`bold`, `dim`, `italic`, `underline`, `blink`, `reverse`, `hidden`, `strikethrough`, `reset_*`, ...), `color.palette` (`orange`, `pink`, `purple`, `teal`, `lime`, `gold`, `indigo`, `crimson`, `salmon`, `sky`, `mint`, `coral`, `violet`, `olive`, `maroon`, `navy`, `forest`, `brown`).

#### SGR code generators

These return the **code part** (e.g. `"38;2;255;128;0"`), not a full escape sequence. Pass them as a spec to `color.color` or to `builder:sgr()`.

| Function | Returns |
| -------- | ------- |
| `color.fg256(n)` / `color.bg256(n)` | `"38;5;n"` / `"48;5;n"` (`n` clamped to 0..255) |
| `color.fgRGB(r, g, b)` / `color.bgRGB(r, g, b)` | `"38;2;r;g;b"` / `"48;2;r;g;b"` |
| `color.fgHex(hex)` / `color.bgHex(hex)` | Same from `'#ff8800'` or `'#f80'`; `nil` for an invalid string |
| `color.hex_to_rgb(hex)` | `r, g, b`, or `nil` for an invalid string |
| `color.clamp_byte(n)` | `n` clamped to an integer in 0..255 (`0` for a non-number) |

#### Builder

`color.builder()` creates a chainable object. Every method returns the builder.

```lua
local msg = 'result: ' .. tostring(color.builder():fg('lime'):text('OK'))
```

| Method | Description |
| ------ | ----------- |
| `:bold()` `:dim()` `:italic()` `:underline()` `:blink()` `:reverse()` `:hidden()` `:strikethrough()` ... | One method for every entry of `color.style` |
| `:fg(x)` / `:bg(x)` | Name, number or `'#hex'` |
| `:fg256(n)` `:bg256(n)` `:fgRGB(r,g,b)` `:bgRGB(r,g,b)` `:fgHex(h)` `:bgHex(h)` | Explicit color forms |
| `:sgr(...)` | Any raw SGR codes |
| `:text(s)` | Appends text |
| `:reset_tail(tail)` | Replaces the closing reset (default `ESC[0m`) |
| `:render()` | Returns the string (`tostring(builder)` does the same) |
| `:write()` / `:print(...)` | Output via `io.write` / `print` |

#### String helpers

All of them ignore ANSI sequences and understand UTF-8.

| Function | Description |
| -------- | ----------- |
| `color.strip(s)` | Removes ANSI sequences. |
| `color.len(s)` | Number of codepoints (not columns!). |
| `color.width(s)` | Width in terminal columns (East Asian wide characters and emoji count as 2). Use this for alignment. |
| `color.pad_right(s, width [, ch])` / `color.pad_left(...)` / `color.pad_center(...)` | Pads to a column width, default fill is a space. |
| `color.truncate(s, width [, ellipsis])` | Truncates to a column width, keeps ANSI codes, default ellipsis `…`. |
| `color.center(s [, width])` | Centers; `width` defaults to the terminal width. |
| `color.term_width()` | Terminal width in columns: `$COLUMNS`, then `mode con` (Windows) or `tput cols` / `stty size`, fallback `80`. |
| `color.demo()` | Prints a demo of all features. |

License of this file (in its header): MIT.

---

### paths.lua (Windows only)

Path and file-system module for Windows. Pure Lua, Lua 5.1.4+. Path parsing, joining, listing directories, existence checks, process CWD and script directory.

```lua
local paths = require('paths')

paths.joinPath('C:\\dir', 'file.txt')   --> 'C:\\dir\\file.txt'
paths.getExtension('archive.tar.gz')    --> '.gz'
paths.getFileName('C:\\dir\\a.txt')     --> 'a.txt'
paths.getDirName('C:\\dir\\a.txt')      --> 'C:\\dir'
paths.fileExists('C:\\test.txt')        --> true / false
paths.dirExists('C:\\dir')              --> true / false
paths.listFiles('C:\\dir')              --> { 'a.txt', 'b.txt' }
paths.listFilesRecursive('C:\\dir')     --> { 'C:\\dir\\a.txt', 'C:\\dir\\sub\\c.txt' }
```

**Path parsing** (pure functions, no file-system access)

| Function | Description |
| -------- | ----------- |
| `paths.normalizePath(path)` | `/` → `\`, repeated slashes collapsed, trailing slash removed, `C:` → `C:\`. Asserts on a non-string or empty string. |
| `paths.isAbsolutePath(path)` | `true` if the path starts with `C:\`, `C:/`, `\\` (UNC) or a slash. Note: `\foo` and `/foo` return `true` (root of the *current* drive), but resolving them still needs the CWD. |
| `paths.getFileName(path)` | File name, or `""` for roots (`C:\`, `\`, `\\server\share`). `nil` for a non-string. |
| `paths.getExtension(path)` | Lowercase extension with a dot, or `""`. The dot must not be the first character and something must follow it: `file.tar.gz` → `.gz`, `.config.json` → `.json`, `.bashrc` → `""`, `a.` → `""`, `a.b.c` → `.c`. |
| `paths.getDirName(path)` | Directory part: `C:\dir\a.txt` → `C:\dir`, `a.txt` → `.`, `C:\a` → `C:\`. `nil` for a non-string or empty string. |

**Joining**

| Function | Description |
| -------- | ----------- |
| `paths.joinPath(a, b)` | Joins and normalizes. `nil` or `""` arguments are tolerated, other non-strings raise an error. If `b` is absolute (`C:\x`, `\\server\share`, `\foo`), it wins and is returned normalized (same convention as .NET `Path.Combine` and Python `os.path.join`). `joinPath(dir, "")` returns `normalizePath(dir)`. |
| `paths.pathCombine(a, b)` | Alias of `joinPath` (backward compatibility). |

**Environment**

| Function | Description |
| -------- | ----------- |
| `paths.getCwd()` | CWD of the process (cached; for a drive root it is `C:\`). |
| `paths.resetCwdCache()` | Clears the CWD cache. Call it if the host changes the directory (`lfs.chdir`, FFI). `os.execute("cd ...")` does not affect the parent process, so no reset is needed. |
| `paths.getScriptDir()` | Directory the script was started from (based on `arg[0]`). |

**File system**

| Function | Description |
| -------- | ----------- |
| `paths.fileExists(path)` | `true` only for regular files. Works with Cyrillic paths and with unreadable or exclusively locked files. Devices such as `NUL`, `CON`, `PRN`, `AUX`, `COM1` also count as existing (limitation of `if exist`). |
| `paths.dirExists(path)` | `true` only for directories (checked with `pushd`, no parsing of localized text). |
| `paths.listFiles(dir)` | Array of file names, no recursion. |
| `paths.listFilesRecursive(dir)` | Array of **full paths**, recursive. |
| `paths.listDirs(dir)` | Array of sub-directory names, no recursion. |
| `paths.renameFile(oldPath, newName)` | Renames a file inside its folder. `newName` is a bare name and must match `name.ext` (letters, digits, `_`, `-`, one dot, an alphanumeric extension), otherwise returns `nil, "unsafe new name"`. Returns `true`, or `nil, err` if the rename failed (file in use, target exists, no access). |

`listFiles`, `listFilesRecursive` and `listDirs` return `{}` both for an empty and for a non-existent directory. If you need to tell them apart, call `dirExists`.

`paths._test` holds internal functions for unit tests. Do not use it in production code.

**Encodings.** Input paths must be UTF-8. Converting from ANSI/CP1251 is up to the caller. `os.getenv("TEMP")` returns ACP bytes for users with Cyrillic names: fine for a temp directory, but do not mix `arg[1]` (ACP) with paths passed to `listFiles`. Exception: `arg[0]` in `getScriptDir` also arrives in ACP; if the start directory contains non-ASCII characters and `arg[0]` includes a path, the result can contain ACP bytes. Starting the script from its own directory (`arg[0]` without slashes) works cleanly.

**How it works.** `io.popen('dir /b ...')` is not used: its output is in the OEM code page, `%VAR%` in paths gets expanded by `cmd`, and leading spaces get lost. Instead the module writes the path to a temp file, runs a small `.bat` that reads it with `set /p`, and decodes the `cmd /u` output (UTF-16LE) to UTF-8 itself. The file is verified after writing. Temp-file names are `_lf_` + 16 hex digits from a local LCG (your `math.random` seed is not touched).

**Limitations**
- Windows only; needs `io.popen`. `chcp 65001` is reliable on Win10/11.
- Every `listXxx` / `dirExists` / `fileExists` call spawns `cmd` and uses two temp files: an order of magnitude slower than a native `dir /b`. For thousands of calls, cache the results.
- No timeout on `io.popen`: a hanging UNC share will hang the call.
- The whole output is read into memory (peak about 2-3×). For huge trees walk with `listDirs`.
- Paths longer than 1023 characters are truncated by `set /p`.
- No metadata (size, mtime), only names and paths.
- Relative paths resolve against the process CWD (same as `io.open`). A bare `"D:"` is resolved by `cmd` through its remembered per-drive directory: use `"D:\"`.
- `dirExists` on a UNC path temporarily maps a drive (side effect and delay).
- In GUI hosts every `io.popen` may flash a console window.
- Cross-process temp-name collision chance is about 2^-32, and a tiny TOCTOU window remains between verifying the file and starting `cmd`. For privileged scenarios on a shared TEMP use native `CreateFile`.
- With C modules allowed, the better solution is `lfs.dir` + `lfs.attributes` or LuaJIT FFI + `FindFirstFileW`.

---

### random.lua

Random byte generator, originally written for a file-renaming utility. Pure Lua, uses only standard functions (`math.random`, `os.time`, `os.clock`, `collectgarbage`): no C modules, no `io.popen`, no `os.execute`.

```lua
local random = dofile('random.lua')      -- or require, if the path is set up

random.initRandom()                      -- once at startup
local bytes = random.getRandomBytes(16)  -- a string of 16 random bytes
```

| Function | Description |
| -------- | ----------- |
| `random.initRandom([custom_seed])` | Seeds `math.randomseed`. Call it once at startup, before the first `getRandomBytes`. Without an argument the seed is a hash of several sources (time, `os.clock` noise, a table address, memory use). A numeric `custom_seed` (any number, including negative) makes the sequence reproducible. Then 15 warm-up values are discarded. |
| `random.getRandomBytes(n)` | Returns a string of `n` random bytes (`0x00`-`0xFF`). A fractional `n` is rounded down. Returns `""` for `nil`, a non-number, `n <= 0`, NaN, infinity, or `n > random.MAX_BYTES`. This is the only function that calls `math.random`: to use a cryptographically secure source, rewrite just this function. |
| `random.MAX_BYTES` | Maximum bytes per call: `65536`. |

Note that `initRandom` calls the global `math.randomseed`, so it affects other code that uses `math.random`.

Self-test: run `lua random.lua` directly. It checks edge cases, string length, byte range, uniqueness and distribution, and prints `[OK]` / `[FAIL]` lines. It does not run when the file is loaded through `require` or `dofile`.

> **Not cryptographically secure.** It is built on `math.random`.

---

### bundler.lua (command-line tool)

Bundles a main Lua script and everything it `require`s into **one** `.lua` file. This is a command-line script, not a library: it runs `main()` as soon as it is loaded.

```
lua bundler.lua <main.lua> [output.lua]
```

- If `output.lua` is omitted, the result goes next to the input as `<main>.bundle.lua`.
- Extra module search templates can be passed through the `BUNDLE_SEARCH_PATH` environment variable, for example `BUNDLE_SEARCH_PATH=libs\?.lua;vendor\?.lua`.
- Exit codes: `0` success, `1` error (cannot read or write a file, or the generated code has a syntax error), `2` no arguments (usage is printed).

Example:

```
lua bundler.lua main.lua app.lua
--> bundled 3 module(s) -> app.lua (12345 bytes)
```

**How it works**
- The scanner finds `require("x")`, `require 'x'` and `require "x"` in the main file and, recursively, in every module it finds. It skips comments and strings (including long brackets `[[ ]]`, `[=[ ]=]`).
- Modules are searched in this order: `package.path`, then `BUNDLE_SEARCH_PATH`, then `<main file directory>/?.lua`. Dots in module names become directory separators.
- Standard library names (`string`, `table`, `math`, `io`, `os`, `coroutine`, `debug`, `package`, `_G`) are not bundled.
- Each module is wrapped in `function(require) ... end` and loaded through a built-in `require` with a cache and circular-dependency detection, so modules stay isolated and their `return` values are kept. Loaded modules are also stored in `package.loaded`.
- A UTF-8 BOM and a `#!` shebang line are removed from every source file. The generated file is syntax-checked before it is written and saved in binary mode, without a BOM.
- A module that is not found produces a warning, and the call is left to the real `require` at runtime (it works if the module exists on disk then).

**Limitations**
- Only literal `require` calls are bundled. `require(variable)`, `require("a" .. "b")` and `require` inside `loadstring()` are not (they go to the real `require` at runtime).
- `dofile()` and `loadfile()` are not bundled.
- Only `.lua` source modules found through the search templates are bundled; compiled C modules (`.dll`, `.so`) are not.
- `module("x", package.seeall)` modules (Lua 5.1) work.

---

### docgen.lua (command-line tool)

API documentation generator for Lua and C# sources. It scans a directory **recursively** for `*.lua` and `*.cs` files and writes one Markdown reference. This is a command-line script, not a library.

```
lua docgen.lua [input_dir] [output_file]
```

- `input_dir` defaults to `.` (current directory), `output_file` defaults to `API.md`.
- The scan uses `io.popen` (`dir /b /s` on Windows, `find` elsewhere).
- Be careful with the output name: an existing file is overwritten. Do not point it at `README.md`.

**What it reads**
- **Lua:** a comment block (`--` or `---`) directly above a function becomes its description. Supported tags: `@param name type description` and `@return type description` (several return values separated by commas). The first comment block at the top of a file becomes the module description. Functions without tags still appear; parameter types are then inferred or shown as `any`.
- **C#:** XML documentation comments (`///` with `<summary>`, `<param name="...">`, `<returns>`) for classes and methods.

The result has a table of contents and, for every file and function, a description, a parameter table and the return values.

---

### Reporting bugs

Found a bug? Open an [issue](../../issues) with the Lua version, the OS, a minimal code sample, and what you expected vs. what happened. That is exactly how most of the bugs here were fixed.

### License and terms of use

**MIT License.** In plain words:

- It is free for everyone.
- You can use it in commercial projects.
- You can copy, modify, merge, publish, distribute and sell it, with or without changes.
- You must keep the copyright notice and the license text with the code (copies or substantial portions).
- The software is provided "as is", with no warranty of any kind. **The author is not liable** for any damage, loss or other consequences of using it.
- Parts of the code were written by AI. Test it for your use case yourself.

Full text:

```
MIT License

Copyright (c) 2026 oleg-19952008

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Русский

Коллекция самостоятельных Lua-библиотек. Каждый файл это отдельный модуль без внешних зависимостей: скопируйте нужный файл в свой проект и подключите через `require`.

> **Как это сделано:** код написан ИИ под руководством человека. Человек писал ТЗ, тестировал результат, составлял баг-репорты и заставлял ИИ исправлять баги снова и снова. Считайте это вручную протестированной кодовой базой, написанной ИИ: перед использованием в чём-то критичном читайте код.

### Содержание

- [Обзор модулей](#обзор-модулей)
- [Установка](#установка)
- [base64.lua](#base64lua-1)
- [color.lua](#colorlua-1)
- [paths.lua](#pathslua-только-windows)
- [random.lua](#randomlua-1)
- [bundler.lua](#bundlerlua-утилита-командной-строки)
- [docgen.lua](#docgenlua-утилита-командной-строки)
- [Сообщить об ошибке](#сообщить-об-ошибке)
- [Лицензия и условия использования](#лицензия-и-условия-использования)

### Обзор модулей

| Файл | Что делает | Версия Lua | Платформа |
| ---- | ---------- | ---------- | --------- |
| [`base64.lua`](base64.lua) | Кодирование и декодирование Base64, стандартный и URL-safe алфавиты (RFC 4648) | 5.1+ | любая |
| [`color.lua`](color.lua) | ANSI-цвета и стили, ширина строк с учётом UTF-8, выравнивание, обрезка | 5.1, 5.2, 5.3, 5.4, LuaJIT | любая |
| [`paths.lua`](paths.lua) | Разбор и склейка путей, проверка файлов и папок, листинг каталогов, CWD, каталог скрипта | 5.1.4+ | **только Windows** |
| [`random.lua`](random.lua) | Генератор случайных байт (на основе `math.random`) | 5.1.4+ | любая |
| [`bundler.lua`](bundler.lua) | **Утилита командной строки:** собирает скрипт и подключаемые им через `require` модули в один файл | 5.1.4+ (также 5.2-5.4) | любая |
| [`docgen.lua`](docgen.lua) | **Утилита командной строки:** генератор API-документации для Lua и C# | 5.1+ | любая |

### Установка

Ставить ничего не нужно. Скопируйте нужный `.lua`-файл рядом со скриптом (или в папку из `package.path`) и подключите:

```lua
local b64 = require('base64')
```

`bundler.lua` и `docgen.lua` не библиотеки: это скрипты, которые запускаются командой `lua`.

---

### base64.lua

Компактный Base64-кодек для Lua 5.1+ без зависимостей. Поддерживает стандартный (RFC 4648) и URL-safe (RFC 4648 §5) алфавиты.

```lua
local b64 = require('base64')

b64.encode('hello')       --> 'aGVsbG8='
b64.encode_url('hello')   --> 'aGVsbG8'     (URL-safe, без padding)

b64.decode('aGVsbG8=')    --> 'hello'
b64.decode('aGVsbG8')     --> 'hello'       (padding необязателен)
b64.decode('!!!')         --> nil, 'invalid base64 character'
b64.decode('a')           --> nil, 'invalid base64 length'
```

| Функция | Описание |
| ------- | -------- |
| `b64.encode(data, url_safe)` | Кодирует строку в Base64. При `url_safe = true`: `+` → `-`, `/` → `_`, и удаляется весь padding `=`. Бросает ошибку, если `data` не строка. |
| `b64.encode_url(data)` | URL-safe Base64 без padding. Эквивалент `b64.encode(data, true)`. |
| `b64.decode(data)` | Декодирует стандартный и URL-safe Base64 одновременно (`-` и `_` трактуются как `+` и `/`). Пробельные символы игнорируются, padding `=` необязателен. Возвращает расшифрованные байты, либо `nil, err` вместо исключения: `'invalid base64 length'` (длина без padding даёт `#data % 4 == 1`) или `'invalid base64 character'`. Ошибку бросает только если `data` не строка. |
| `b64.decode_url(data)` | Алиас `b64.decode` для симметрии с `encode_url`. |

---

### color.lua

Расширенная ANSI-библиотека для Lua 5.1, 5.2, 5.3, 5.4 и LuaJIT. Цвета (16, 256, true-color, HEX), стили текста, цепочечный builder и функции для строк с учётом UTF-8 (ширина в колонках терминала, выравнивание, обрезка). Уважает `NO_COLOR` и `FORCE_COLOR`.

```lua
local color = require('color')

print(color.color('Привет!', 'bold', 'red'))
print(color.color('Ошибка', 'fg:bright_red', 'bg:black', 'underline'))
print(color.color('палитра', 'fg256:208'))
print(color.color('true color', 'fgRGB:255;100;0'))
print(color.color('hot pink', 'fgHex:#ff69b4'))

-- Builder
print(color.builder():bold():fg('bright_yellow'):bg('navy'):text('  Внимание!  '):render())

-- Функции для строк понимают UTF-8 и игнорируют ANSI-коды
color.len('日本語')       --> 3   (кодпоинты)
color.width('日本語')     --> 6   (колонки терминала)
color.truncate('Привет, мир!', 8)   --> 'Привет,…'
```

> В комментариях внутри `color.lua` модуль называется `ansi` (старое имя). Подключайте через `require('color')`.

#### Определение поддержки цвета

Цвета включаются автоматически, если вывод, судя по всему, их поддерживает:

- `NO_COLOR` с непустым значением: цвета **выключены**. `FORCE_COLOR` задан (и не `0`): цвета **включены**. `TERM=dumb`: выключены.
- Unix: `io.stdout:isatty()`, если доступен, иначе эвристика по `TERM` / `COLORTERM`.
- Windows: включены, если есть `WT_SESSION`, `ANSICON`, `ConEmuANSI=ON` или `TERM_PROGRAM`. Старый `cmd.exe` цветов не получает. VT-режим Windows включается через FFI LuaJIT, поэтому без LuaJIT он не включается.
- При выключенных цветах все функции возвращают обычный текст без ANSI-кодов.

#### Включение и выключение

| Функция | Описание |
| ------- | -------- |
| `color.set_enabled(v)` | Принудительно включить или выключить цвета (также доступно поле `color.enabled`). |
| `color.enable()` / `color.disable()` | Сокращения. |
| `color.is_enabled()` | Включены ли цвета сейчас. |

#### Окрашивание текста

| Функция | Описание |
| ------- | -------- |
| `color.color(text, ...)` | Возвращает `text`, обёрнутый стилями из дополнительных аргументов (см. спецификации ниже). Неверные спецификации молча игнорируются. |
| `color.write_color(text, ...)` | То же, пишет в stdout. |
| `color.writeln_color(text, ...)` | То же, с переводом строки. |
| `color.RESET()` | Возвращает последовательность сброса `ESC[0m` (пустую строку при выключенных цветах). |

**Спецификации стилей** (аргументы после `text`):

| Спецификация | Пример | Значение |
| ------------ | ------ | -------- |
| Имя цвета текста | `'red'`, `'bright_red'`, `'fg:red'` | Запись из `color.fg` |
| Имя цвета фона | `'bg:red'` | Запись из `color.bg` |
| Имя из палитры | `'orange'`, `'bg:navy'` | Запись из `color.palette` (256 цветов) |
| Стиль | `'bold'`, `'underline'` | Запись из `color.style` |
| 256 цветов | `'fg256:208'`, `'bg256:17'` | |
| RGB | `'fgRGB:255;100;0'`, `'bgRGB:0;0;0'` | |
| HEX | `'#ff69b4'`, `'fgHex:#ff69b4'`, `'bgHex:#222222'` | `#RGB` и `#RRGGBB`; просто `'#...'` это цвет текста |
| Готовый SGR | `'1;31'` или число `31` | Вставляется как есть |

Доступные таблицы: `color.fg` (`black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, `default`, `bright_*`, `gray`/`grey`, `light_*`), `color.bg`, `color.style` (`bold`, `dim`, `italic`, `underline`, `blink`, `reverse`, `hidden`, `strikethrough`, `reset_*` и др.), `color.palette` (`orange`, `pink`, `purple`, `teal`, `lime`, `gold`, `indigo`, `crimson`, `salmon`, `sky`, `mint`, `coral`, `violet`, `olive`, `maroon`, `navy`, `forest`, `brown`).

#### Генераторы SGR-кодов

Возвращают **часть кода** (например, `"38;2;255;128;0"`), а не полную escape-последовательность. Передавайте их как спецификацию в `color.color` или в `builder:sgr()`.

| Функция | Возвращает |
| ------- | ---------- |
| `color.fg256(n)` / `color.bg256(n)` | `"38;5;n"` / `"48;5;n"` (`n` ограничивается 0..255) |
| `color.fgRGB(r, g, b)` / `color.bgRGB(r, g, b)` | `"38;2;r;g;b"` / `"48;2;r;g;b"` |
| `color.fgHex(hex)` / `color.bgHex(hex)` | То же из `'#ff8800'` или `'#f80'`; `nil` для неверной строки |
| `color.hex_to_rgb(hex)` | `r, g, b` или `nil` для неверной строки |
| `color.clamp_byte(n)` | `n`, ограниченное целым числом 0..255 (`0` для не-числа) |

#### Builder

`color.builder()` создаёт объект для цепочечных вызовов. Каждый метод возвращает сам builder.

```lua
local msg = 'результат: ' .. tostring(color.builder():fg('lime'):text('OK'))
```

| Метод | Описание |
| ----- | -------- |
| `:bold()` `:dim()` `:italic()` `:underline()` `:blink()` `:reverse()` `:hidden()` `:strikethrough()` ... | По методу на каждую запись `color.style` |
| `:fg(x)` / `:bg(x)` | Имя, число или `'#hex'` |
| `:fg256(n)` `:bg256(n)` `:fgRGB(r,g,b)` `:bgRGB(r,g,b)` `:fgHex(h)` `:bgHex(h)` | Явные формы цвета |
| `:sgr(...)` | Произвольные SGR-коды |
| `:text(s)` | Добавляет текст |
| `:reset_tail(tail)` | Заменяет завершающий сброс (по умолчанию `ESC[0m`) |
| `:render()` | Возвращает строку (`tostring(builder)` делает то же) |
| `:write()` / `:print(...)` | Вывод через `io.write` / `print` |

#### Функции для строк

Все игнорируют ANSI-последовательности и понимают UTF-8.

| Функция | Описание |
| ------- | -------- |
| `color.strip(s)` | Удаляет ANSI-последовательности. |
| `color.len(s)` | Число кодпоинтов (не колонок!). |
| `color.width(s)` | Ширина в колонках терминала (широкие символы East Asian и emoji считаются за 2). Для выравнивания используйте её. |
| `color.pad_right(s, width [, ch])` / `color.pad_left(...)` / `color.pad_center(...)` | Дополняет до ширины в колонках, по умолчанию пробелом. |
| `color.truncate(s, width [, ellipsis])` | Обрезает до ширины в колонках, сохраняя ANSI-коды, многоточие по умолчанию `…`. |
| `color.center(s [, width])` | Центрирует; `width` по умолчанию равна ширине терминала. |
| `color.term_width()` | Ширина терминала в колонках: `$COLUMNS`, затем `mode con` (Windows) или `tput cols` / `stty size`, запасной вариант `80`. |
| `color.demo()` | Выводит демонстрацию всех возможностей. |

Лицензия этого файла (в его шапке): MIT.

---

### paths.lua (только Windows)

Модуль для работы с путями и файловой системой на Windows. Чистый Lua, Lua 5.1.4+. Разбор и склейка путей, листинг каталогов, проверка существования, CWD процесса и каталог скрипта.

```lua
local paths = require('paths')

paths.joinPath('C:\\dir', 'file.txt')   --> 'C:\\dir\\file.txt'
paths.getExtension('archive.tar.gz')    --> '.gz'
paths.getFileName('C:\\dir\\a.txt')     --> 'a.txt'
paths.getDirName('C:\\dir\\a.txt')      --> 'C:\\dir'
paths.fileExists('C:\\test.txt')        --> true / false
paths.dirExists('C:\\dir')              --> true / false
paths.listFiles('C:\\dir')              --> { 'a.txt', 'b.txt' }
paths.listFilesRecursive('C:\\dir')     --> { 'C:\\dir\\a.txt', 'C:\\dir\\sub\\c.txt' }
```

**Разбор путей** (чистые функции, без доступа к ФС)

| Функция | Описание |
| ------- | -------- |
| `paths.normalizePath(path)` | `/` → `\`, повторные слэши схлопываются, хвостовой слэш убирается, `C:` → `C:\`. Assert на не-строку и пустую строку. |
| `paths.isAbsolutePath(path)` | `true`, если путь начинается с `C:\`, `C:/`, `\\` (UNC) или слэша. Оговорка: `\foo` и `/foo` дают `true` (корень ТЕКУЩЕГО диска), но для полного пути всё равно нужен CWD. |
| `paths.getFileName(path)` | Имя файла или `""` для корней (`C:\`, `\`, `\\server\share`). `nil` для не-строки. |
| `paths.getExtension(path)` | Расширение в нижнем регистре с точкой или `""`. Точка не должна быть первым символом, и после неё что-то должно быть: `file.tar.gz` → `.gz`, `.config.json` → `.json`, `.bashrc` → `""`, `a.` → `""`, `a.b.c` → `.c`. |
| `paths.getDirName(path)` | Каталог: `C:\dir\a.txt` → `C:\dir`, `a.txt` → `.`, `C:\a` → `C:\`. `nil` для не-строки и пустой строки. |

**Склейка**

| Функция | Описание |
| ------- | -------- |
| `paths.joinPath(a, b)` | Склеивает и нормализует. `nil` и `""` допустимы, остальные не-строки вызывают ошибку. Если `b` абсолютный (`C:\x`, `\\server\share`, `\foo`), он побеждает и возвращается нормализованным (как в .NET `Path.Combine` и Python `os.path.join`). `joinPath(dir, "")` возвращает `normalizePath(dir)`. |
| `paths.pathCombine(a, b)` | Алиас `joinPath` (обратная совместимость). |

**Среда**

| Функция | Описание |
| ------- | -------- |
| `paths.getCwd()` | CWD процесса (кэшируется; для корня диска это `C:\`). |
| `paths.resetCwdCache()` | Сбрасывает кэш CWD. Вызывайте, если хост меняет каталог (`lfs.chdir`, FFI). `os.execute("cd ...")` на родителя не влияет, сброс не нужен. |
| `paths.getScriptDir()` | Каталог, из которого запущен скрипт (по `arg[0]`). |

**Файловая система**

| Функция | Описание |
| ------- | -------- |
| `paths.fileExists(path)` | `true` только для обычных файлов. Работает с кириллицей и с нечитаемыми или эксклюзивно занятыми файлами. Устройства `NUL`, `CON`, `PRN`, `AUX`, `COM1` тоже считаются существующими (ограничение `if exist`). |
| `paths.dirExists(path)` | `true` только для папок (проверка через `pushd`, без парсинга локализованного текста). |
| `paths.listFiles(dir)` | Массив имён файлов, без рекурсии. |
| `paths.listFilesRecursive(dir)` | Массив **полных путей**, рекурсивно. |
| `paths.listDirs(dir)` | Массив имён подпапок, без рекурсии. |
| `paths.renameFile(oldPath, newName)` | Переименовывает файл в его же папке. `newName` это просто имя вида `name.ext` (буквы, цифры, `_`, `-`, одна точка, буквенно-цифровое расширение), иначе вернёт `nil, "unsafe new name"`. Возвращает `true`, либо `nil, err`, если переименовать не удалось (файл занят, цель существует, нет доступа). |

`listFiles`, `listFilesRecursive` и `listDirs` возвращают `{}` и для пустой, и для несуществующей папки. Если нужно их различать, вызывайте `dirExists`.

В `paths._test` лежат внутренние функции для юнит-тестов. В боевом коде их использовать не стоит.

**Кодировки.** Пути должны быть в UTF-8. Конвертация из ANSI/CP1251 лежит на вызывающем. `os.getenv("TEMP")` для пользователей с кириллицей возвращает байты ACP: для временного каталога это нормально, но не смешивайте `arg[1]` (ACP) с путями, которые передаёте в `listFiles`. Исключение: `arg[0]` в `getScriptDir` тоже приходит в ACP; если каталог запуска содержит не-ASCII символы и в `arg[0]` есть путь, результат может содержать байты ACP. Запуск из каталога самого скрипта (`arg[0]` без слэшей) работает чисто.

**Как это работает.** `io.popen('dir /b ...')` не используется: вывод идёт в OEM-кодировке, `%VAR%` в путях раскрывается `cmd`, а ведущие пробелы теряются. Вместо этого модуль пишет путь во временный файл, запускает небольшой `.bat`, который читает его через `set /p`, и сам декодирует вывод `cmd /u` (UTF-16LE) в UTF-8. Файл сверяется после записи. Имена временных файлов: `_lf_` + 16 hex-цифр из локального LCG (ваш seed для `math.random` не затрагивается).

**Ограничения**
- Только Windows, нужен `io.popen`. `chcp 65001` надёжен на Win10/11.
- Каждый вызов `listXxx` / `dirExists` / `fileExists` запускает `cmd` и создаёт два временных файла: на порядок медленнее прямого `dir /b`. Для тысяч вызовов кэшируйте результаты.
- У `io.popen` нет таймаута: зависший UNC-шаринг подвесит вызов.
- Весь вывод читается в память (пик ~2-3×). Для огромных деревьев обходите через `listDirs`.
- Путь длиннее 1023 символов обрезается `set /p`.
- Метаданных (размер, дата изменения) нет, только имена и пути.
- Относительные пути разрешаются относительно CWD процесса (как у `io.open`). Голый `"D:"` `cmd` разрешает по запомненному каталогу диска: используйте `"D:\"`.
- `dirExists` на UNC-пути временно мапит диск (побочный эффект и задержка).
- В GUI-хосте каждый `io.popen` может мигать консольным окном.
- Шанс коллизии имён временных файлов между процессами около 2^-32, и остаётся крошечное окно TOCTOU между проверкой файла и запуском `cmd`. Для привилегированных сценариев на общем TEMP используйте нативный `CreateFile`.
- Если C-модули разрешены, лучше `lfs.dir` + `lfs.attributes` или LuaJIT FFI + `FindFirstFileW`.

---

### random.lua

Генератор случайных байт, изначально написан для утилиты переименования файлов. Чистый Lua, используются только стандартные функции (`math.random`, `os.time`, `os.clock`, `collectgarbage`): без C-модулей, `io.popen` и `os.execute`.

```lua
local random = dofile('random.lua')      -- или require, если путь настроен

random.initRandom()                      -- один раз при старте
local bytes = random.getRandomBytes(16)  -- строка из 16 случайных байт
```

| Функция | Описание |
| ------- | -------- |
| `random.initRandom([custom_seed])` | Инициализирует `math.randomseed`. Вызывайте один раз при старте, до первого `getRandomBytes`. Без аргумента seed это хеш нескольких источников (время, шум `os.clock`, адрес таблицы, потребление памяти). Числовой `custom_seed` (любое число, в том числе отрицательное) даёт воспроизводимую последовательность. Затем отбрасываются 15 «прогревочных» значений. |
| `random.getRandomBytes(n)` | Возвращает строку из `n` случайных байт (`0x00`-`0xFF`). Дробное `n` округляется вниз. Возвращает `""` для `nil`, не-числа, `n <= 0`, NaN, бесконечности и `n > random.MAX_BYTES`. Это единственная функция, которая вызывает `math.random`: для криптостойкого источника достаточно переписать только её. |
| `random.MAX_BYTES` | Максимум байт за один вызов: `65536`. |

Учтите, что `initRandom` вызывает глобальный `math.randomseed`, поэтому влияет на другой код, использующий `math.random`.

Самотест: запустите `lua random.lua` напрямую. Он проверяет граничные случаи, длину строк, диапазон байт, уникальность и распределение и печатает строки `[OK]` / `[FAIL]`. При загрузке через `require` или `dofile` он не запускается.

> **Не криптостойкий.** Построен на `math.random`.

---

### bundler.lua (утилита командной строки)

Собирает главный Lua-скрипт и всё, что он подключает через `require`, в **один** `.lua`-файл. Это скрипт командной строки, а не библиотека: он запускает `main()` сразу при загрузке.

```
lua bundler.lua <main.lua> [output.lua]
```

- Если `output.lua` не указан, результат кладётся рядом со входным файлом как `<main>.bundle.lua`.
- Дополнительные шаблоны поиска модулей передаются через переменную окружения `BUNDLE_SEARCH_PATH`, например `BUNDLE_SEARCH_PATH=libs\?.lua;vendor\?.lua`.
- Коды выхода: `0` успех, `1` ошибка (не удалось прочитать или записать файл, либо в сгенерированном коде синтаксическая ошибка), `2` нет аргументов (печатается подсказка).

Пример:

```
lua bundler.lua main.lua app.lua
--> bundled 3 module(s) -> app.lua (12345 bytes)
```

**Как это работает**
- Сканер находит `require("x")`, `require 'x'` и `require "x"` в главном файле и, рекурсивно, в каждом найденном модуле. Комментарии и строки (включая длинные скобки `[[ ]]`, `[=[ ]=]`) пропускаются.
- Модули ищутся в таком порядке: `package.path`, затем `BUNDLE_SEARCH_PATH`, затем `<каталог главного файла>/?.lua`. Точки в именах модулей превращаются в разделители каталогов.
- Имена стандартной библиотеки (`string`, `table`, `math`, `io`, `os`, `coroutine`, `debug`, `package`, `_G`) не бандлятся.
- Каждый модуль оборачивается в `function(require) ... end` и загружается через встроенный `require` с кэшем и обнаружением циклических зависимостей: модули изолированы, их `return` сохраняется. Загруженные модули также записываются в `package.loaded`.
- Из каждого исходника удаляются UTF-8 BOM и строка `#!`. Сгенерированный файл проверяется на синтаксис перед записью и сохраняется в бинарном режиме, без BOM.
- Если модуль не найден, выводится предупреждение, а вызов остаётся настоящему `require` во время выполнения (сработает, если модуль тогда есть на диске).

**Ограничения**
- Бандлятся только литеральные `require`. `require(переменная)`, `require("a" .. "b")` и `require` внутри `loadstring()` не бандлятся (они уйдут в настоящий `require` в рантайме).
- `dofile()` и `loadfile()` не бандлятся.
- Бандлятся только исходники `.lua`, найденные по шаблонам поиска; скомпилированные C-модули (`.dll`, `.so`) не бандлятся.
- Модули `module("x", package.seeall)` (Lua 5.1) работают.

---

### docgen.lua (утилита командной строки)

Генератор API-документации для Lua и C#. **Рекурсивно** сканирует каталог на файлы `*.lua` и `*.cs` и пишет один Markdown-справочник. Это скрипт командной строки, а не библиотека.

```
lua docgen.lua [input_dir] [output_file]
```

- `input_dir` по умолчанию `.` (текущий каталог), `output_file` по умолчанию `API.md`.
- Сканирование использует `io.popen` (`dir /b /s` на Windows, `find` на остальных системах).
- Осторожнее с именем выходного файла: существующий файл перезаписывается. Не указывайте `README.md`.

**Что он читает**
- **Lua:** блок комментариев (`--` или `---`) прямо над функцией становится её описанием. Поддерживаются теги `@param имя тип описание` и `@return тип описание` (несколько возвращаемых значений через запятую). Первый блок комментариев в начале файла становится описанием модуля. Функции без тегов тоже попадают в документацию; типы параметров тогда выводятся автоматически или показываются как `any`.
- **C#:** XML-комментарии (`///` с `<summary>`, `<param name="...">`, `<returns>`) для классов и методов.

В результате получается оглавление и для каждого файла и функции: описание, таблица параметров и возвращаемые значения.

---

### Сообщить об ошибке

Нашли баг? Создайте [issue](../../issues): укажите версию Lua, ОС, минимальный пример кода и что ожидали получить и что получили. Именно так здесь исправлялась большая часть багов.

### Лицензия и условия использования

**Лицензия MIT.** Простыми словами:

- Бесплатно для всех.
- Можно использовать в коммерческих проектах.
- Можно копировать, изменять, объединять, публиковать, распространять и продавать, с изменениями или без.
- Нужно сохранять уведомление об авторстве и текст лицензии вместе с кодом (копиями или его существенными частями).
- Программа предоставляется «как есть», без каких-либо гарантий. **Автор не несёт ответственности** за любой ущерб, убытки и другие последствия её использования.
- Часть кода написана ИИ. Проверяйте его под свою задачу самостоятельно.

Юридически значим оригинальный английский текст лицензии, он приведён выше в разделе English → License and terms of use, а также в файле [LICENSE](LICENSE).
