# API Documentation

Generated: 2026-11-10 22:18:06

Total files: 6 (Lua: 6, C#: 0)

## Contents

### Lua

- [base64.lua](#base64lua)
- [bundler.lua](#bundlerlua)
- [color.lua](#colorlua)
- [docgen.lua](#docgenlua)
- [paths.lua](#pathslua)
- [random.lua](#randomlua)

---

## File: `base64.lua` (Lua)

base64.lua

Компактный Base64-кодек для Lua 5.1+ без внешних зависимостей.
Поддерживает стандартный (RFC 4648) и URL-safe (RFC 4648 §5) алфавиты.

Пример использования:
local b64 = require('base64')
local s   = b64.encode('hello')       --> 'aGVsbG8='
local u   = b64.encode_url('hello')   --> 'aGVsbG8'
local d   = b64.decode(u)             --> 'hello'

@module base64

### `base64.encode`

Кодирует строку в Base64. При `url_safe = true` применяются замены: '+' -> '-', '/' -> '_', и удаляется padding '='. @raise                            Если data не строка.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `data` | `string` | Исходные байты. |
| `url_safe` | `boolean` | ? Если true — URL-safe вариант без padding. |

**Returns:**

- `string` - Base64-строка.

### `base64.encode_url`

Кодирует строку в URL-safe Base64 (без padding). Эквивалент `base64.encode(data, true)`.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `data` | `string` |  |

**Returns:**

- `string`

### `base64.decode`

Декодирует Base64-строку. Принимает как стандартный, так и URL-safe алфавит одновременно: символы '-' и '_' трактуются как '+' и '/' соответственно. Пробельные символы игнорируются, padding '=' опционален. В случае ошибки не бросает исключение, а возвращает nil и текст ошибки: * 'invalid base64 length'    — длина после удаления padding даёт #data % 4 == 1 * 'invalid base64 character' — встречен символ вне алфавита @raise                    Если data не строка.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `data` | `string` |  |

**Returns:**

- `string` - ? decoded   Расшифрованные байты
- `либо` - nil.
- `string` - ? err       Описание ошибки
- `либо` - nil.

### `base64.decode_url`

Алиас `base64.decode` для симметрии с `encode_url`. URL-safe алфавит уже поддерживается в `decode`, так что это просто обёртка.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `data` | `string` |  |

**Returns:**

- `string` - ?
- `string` - ?

---

## File: `bundler.lua` (Lua)

### `readFile`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `writeFile`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |
| `data` | `any` |  |

### `stripBom`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `src` | `any` |  |

### `stripShebang`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `src` | `any` |  |

### `normalizeSource`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `src` | `any` |  |

### `collectRequires`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `src` | `any` |  |

### `add`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `name` | `any` |  |

### `longBracketOpen`

На позиции pos открывается длинная скобка [[, [=[, [==[ ?

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `pos` | `any` |  |

### `skipLong`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `pos` | `any` |  |
| `lvl` | `any` |  |

### `skipShort`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `pos` | `any` |  |
| `q` | `any` |  |

### `findModuleFile`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `name` | `any` |  |
| `searchPaths` | `any` |  |

### `bundle`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `mainFile` | `any` |  |
| `outputFile` | `any` |  |
| `extraPaths` | `any` |  |

### `w`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `main`

---

## File: `color.lua` (Lua)

ansi.lua
Расширенная ANSI-библиотека. Совместима с Lua 5.1, 5.2, 5.3, 5.4, LuaJIT.
Лицензия: MIT

### `_bor`

Арифметический fallback (для маленьких DWORD-значений Windows).

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `a` | `any` |  |
| `b` | `any` |  |

### `try_enable_windows_vt`

### `is_tty`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `handle` | `any` |  |

### `env_nonempty`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `name` | `any` |  |

### `detect_support`

### `M.set_enabled`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `v` | `any` |  |

### `M.enable`

### `M.disable`

### `M.is_enabled`

### `clamp`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `n` | `any` |  |
| `lo` | `any` |  |
| `hi` | `any` |  |

### `M.clamp_byte`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `n` | `any` |  |

### `M.fg256`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `n` | `any` |  |

### `M.bg256`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `n` | `any` |  |

### `M.fgRGB`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `r` | `any` |  |
| `g` | `any` |  |
| `b` | `any` |  |

### `M.bgRGB`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `r` | `any` |  |
| `g` | `any` |  |
| `b` | `any` |  |

### `M.hex_to_rgb`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `hex` | `any` |  |

### `M.fgHex`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `hex` | `any` |  |

### `M.bgHex`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `hex` | `any` |  |

### `M.RESET`

### `decode_utf8`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |
| `i` | `any` |  |

### `cp_width`

Упрощённый wcwidth. Достаточно для CLI-вывода; покрывает контрольные, комбинирующие, широкие CJK и основные emoji.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `cp` | `any` |  |

### `tokenize`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `parse_spec`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `spec` | `any` |  |

### `M.color`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `text` | `any` |  |
| `...` | `any` |  |

### `M.write_color`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `text` | `any` |  |
| `...` | `any` |  |

### `M.writeln_color`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `text` | `any` |  |
| `...` | `any` |  |

### `Builder.__tostring`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `self` | `any` |  |

### `new_builder`

### `resolve_fg`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `name` | `any` |  |

### `resolve_bg`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `name` | `any` |  |

### `Builder:_add`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `code` | `any` |  |

### `Builder:fg`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `x` | `any` |  |

### `Builder:bg`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `x` | `any` |  |

### `Builder:fg256`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `n` | `any` |  |

### `Builder:bg256`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `n` | `any` |  |

### `Builder:fgRGB`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `r` | `any` |  |
| `g` | `any` |  |
| `b` | `any` |  |

### `Builder:bgRGB`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `r` | `any` |  |
| `g` | `any` |  |
| `b` | `any` |  |

### `Builder:fgHex`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `h` | `any` |  |

### `Builder:bgHex`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `h` | `any` |  |

### `Builder:sgr`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `...` | `any` |  |

### `Builder:reset_tail`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `tail` | `any` |  |

### `Builder:text`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `Builder:_render`

### `Builder:render`

### `Builder:write`

### `Builder:print`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `...` | `any` |  |

### `M.strip`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `M.len`

Количество codepoint'ов (не колонок терминала!).

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `M.width`

Ширина в колонках терминала (учитывает East Asian Wide / emoji).

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `M.pad_right`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |
| `width` | `any` |  |
| `ch` | `any` |  |

### `M.pad_left`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |
| `width` | `any` |  |
| `ch` | `any` |  |

### `M.pad_center`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |
| `width` | `any` |  |
| `ch` | `any` |  |

### `M.truncate`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |
| `width` | `any` |  |
| `ellipsis` | `any` |  |

### `term_width`

### `M.center`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |
| `width` | `any` |  |

### `M.demo`

### `line`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `t` | `any` |  |

---

## File: `docgen.lua` (Lua)

docgen.lua
Lua & C# API documentation generator.
Usage: lua docgen.lua <input_dir> [output_file]

### `listSourceFiles`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `dir` | `any` |  |

### `readFile`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `splitLines`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `ensureDir`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `splitTopLevel`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |
| `sep` | `any` |  |

### `splitCsTopLevel`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |
| `sep` | `any` |  |

### `stripCode`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `lines` | `any` |  |

### `stripLineComment`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `buildBlockStacks`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `cleaned` | `any` |  |

### `stripOuterParens`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `findTopLevelOps`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `expr` | `any` |  |

### `splitAtLastTop`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `expr` | `any` |  |
| `kw` | `any` |  |

### `inferType`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `expr` | `any` |  |

### `collectComments`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `lines` | `any` |  |
| `endIdx` | `any` |  |

### `parseModuleComment`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `commentLines` | `any` |  |

### `parseDocComment`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `commentLines` | `any` |  |

### `detectFunc`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `line` | `any` |  |

### `parseLuaFile`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `hasWord`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |
| `w` | `any` |  |

### `stripCsStringsAndComments`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `line` | `any` |  |

### `detectCsType`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `line` | `any` |  |

### `detectCsMethod`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `line` | `any` |  |

### `joinDeclarationHead`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `stripped` | `any` |  |
| `startIdx` | `any` |  |
| `maxLines` | `any` |  |

### `collectXmlComments`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `lines` | `any` |  |
| `endIdx` | `any` |  |

### `parseXmlDoc`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `commentLines` | `any` |  |

### `flushParam`

### `flushReturns`

### `parseCsParams`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `argsStr` | `any` |  |

### `parseCsModuleComment`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `commentLines` | `any` |  |

### `parseCsFile`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `parseFile`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `renderParamTable`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `w` | `any` |  |
| `params` | `any` |  |

### `renderLuaFunction`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `w` | `any` |  |
| `fn` | `any` |  |

### `renderCsMethod`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `w` | `any` |  |
| `m` | `any` |  |

### `generate`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `docs` | `any` |  |
| `outputPath` | `any` |  |

### `w`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `main`

---

## File: `paths.lua` (Lua)

============================================================
paths.lua — Windows-only, Lua 5.1.4+, pure Lua
============================================================

Универсальный модуль для работы с путями и ФС на Windows:
разбор путей, листинг каталогов, проверка существования,
CWD процесса и каталог скрипта.

Публичный API:

Разбор путей (чистые функции, без доступа к ФС):
M.normalizePath(path)     -> нормализованный путь (assert на мусор)
M.isAbsolutePath(path)    -> boolean (см. оговорку про "\foo")
M.getFileName(path)       -> имя файла или "" для корня
M.getExtension(path)      -> ".ext" в нижнем регистре или ""
M.getDirName(path)        -> каталог (без имени файла)

Склейка:
M.joinPath(dir, name)     -> нормализованный путь (nil-толерантен)
M.pathCombine(a, b)       -> алиас joinPath (обратная совместимость)

Среда:
M.getCwd()                -> CWD процесса (кэш; для корня диска "C:\")
M.resetCwdCache()         -> сброс кэша CWD после chdir из хоста
M.getScriptDir()          -> каталог, из которого запущен скрипт

ФС:
M.fileExists(path)        -> boolean (только регулярные файлы)
M.dirExists(path)         -> boolean (только папки)
M.listFiles(dir)          -> массив имён файлов, без рекурсии
M.listFilesRecursive(dir) -> массив ПОЛНЫХ путей, рекурсивно
M.listDirs(dir)           -> массив имён подпапок, без рекурсии

КОДИРОВКИ:
Входные пути ожидаются в UTF-8. Конвертация из ANSI/CP1251 —
на вызывающем. os.getenv("TEMP") для кириллических юзеров
возвращает ACP-байты — для temp-каталога это ок (fopen/cmd
интерпретируют как ACP), но НЕ смешивайте arg[1] (ACP) с
путями, которые вы передаёте в M.listFiles.
ИСКЛЮЧЕНИЕ — arg[0] в M.getScriptDir: он приходит в ACP,
а runBat/makeAbs ждут UTF-8 (см. комментарий к функции).

Почему не `io.popen('dir /b "path"')`:
* OEM-кодировка вывода → кракозябры. `cmd /u` даёт UTF-16LE,
декодируем в UTF-8 сами.
* %VAR% в пути раскрывается cmd'ом даже в кавычках. Путь
уходит в файл, читается через `set /p P=<...`.
* Спецсимволы & | < > ^ " — в .bat внутри "..." литералы;
%P% подставляется однократно (`/v:off` — ! не тронут).
* Построчный dir /b терял ведущие пробелы. Сейчас разделитель
— \r\n в UTF-16LE (в именах Windows запрещён), пробелы целы.
* pipe читается в режиме "rb": в UTF-16LE любой ASCII-символ
содержит байт 0x00, текстовый режим fread на Windows обрезает
поток на первом нуле — вывод терялся целиком сразу после BOM
("\xFF\xFE"), и dirExists всегда возвращал false.
* UTF-8 BOM ("EF BB BF") в выводе cmd /u невозможен: весь raw
— UTF-16LE, его BOM (FF FE) снимается в runBat. Поэтому в
listEntries фильтруется только мусор с управляющим первым
байтом (< 0x20); по первому байту 0xEF строки НЕ отбрасываются
— это валидное начало UTF-8 для U+F000–U+FFFF (ＦＵＬＬＷＩＤＴＨ
"Ａ", CJK-совместимость "豈", PUA), иначе имена таких файлов
молча исчезали бы из листинга.
* Литералы "%VAR%" в целевом пути: путь уходит в temp-файл,
set /p читает его побайтово (без раскрытия), а внутри .bat
путь попадает в команды ТОЛЬКО через подстановку %P%.
Командный процессор раскрывает переменные однократно при
парсинге строки и НЕ делает второго прохода по значению
переменной — литерал "%TEMP%" внутри %P% остаётся литералом.
Кавычки вокруг "%P%" защищают & | < > ^, флаг /v:off — ! от
delayed expansion. Относительные пути резолвятся лексически
относительно CWD процесса до записи в temp-файл.

Temp-файлы и коллизии:
Имя = "_lf_" + 16 hex (два вызова локального LCG по 32-бита,
каждый форматируется как две 16-битные половины: %04x%04x).
%08x в MSVC/Lua 5.1 может приводить 32-битный C-int к UB на
значениях ≥ 2^31 (на x86 часто 80000000; на x64 поведение
зависит от инструкций) — такой формат не используется.
Seed = os.time + os.clock() (мкс) + %RANDOM%³ (если io.popen
доступен; иначе только os.time + os.clock). Финальный
`% 2^32` режет seed до 32 бит, поэтому уникальных имён на
процесс не более 2^32, а межпроцессная коллизия — ~2^-32
(при совпадении seed'ов два процесса дадут одинаковую
последовательность имён). %RANDOM%³ добавляет до ~45 бит
энтропии, но большая часть теряется на `% 2^32`.
После записи содержимое сверяется чтением — от подмены во
время записи. Микро-TOCTOU между verify и popen остаётся:
для привилегированных сценариев на общем TEMP — закрывать
нативным CreateFile с SECURITY_ATTRIBUTES.

Ограничения:
* Windows-only; io.popen; chcp 65001 надёжен на Win10/11.
* Каждый вызов listXxx / dirExists / fileExists — spawn cmd
и два temp-файла; на порядок медленнее прямого dir /b.
Для тысяч вызовов — кэшируйте у себя.
* fileExists: `if exist` возвращает true для устройств
NUL, CON, PRN, AUX, COM1.. и т.п. — это ограничение
`if exist`, без нативных вызовов не обходится. Для
«настоящих» файлов работает корректно (включая нечитаемые
и занятые эксклюзивно — проверка идёт в обход fopen).
* Нет таймаута на io.popen: висящий UNC-шаринг подвесит
вызов (в 5.1 без C-модуля нерешаемо).
* p:read("*a") держит вывод целиком (пик ~2–3×). Огромные
деревья — обход через listDirs.
* Путь > 1023 символов обрезается `set /p`.
* Метаданных (size/mtime) нет — только имена и пути.
* Контракт listXxx: {} и для несуществующей, и для пустой
папки. Нужно различать — вызывающий проверяет dirExists
перед listFiles (или после, если {} — ожидаемый случай).
* Относительные пути разрешаются относительно CWD процесса
(тот же базовый каталог, что у io.open/fopen). CWD кэши-
руется на процесс; если хост меняет рабочий каталог через
lfs.chdir/FFI — вызовите M.resetCwdCache(), иначе модуль
будет резолвить относительные пути по устаревшему CWD.
os.execute("cd ...") на родителя не влияет и сброса не требует.
* Пути вида "D:" (диск без слэша, отличный от текущего) cmd
разрешает по запомненным текущим директориям дисков —
используйте явный "D:\".
* dirExists через pushd на UNC временно мапит диск — побочный
эффект + задержка; без нативных вызовов неизбежно.
* В GUI-хосте каждый io.popen может мигать консольным окном
(CREATE_NO_WINDOW недоступен без FFI/C-модуля).

Идеал при разрешённых C-модулях: lfs.dir + lfs.attributes,
либо LuaJIT FFI + FindFirstFileW.
============================================================

### `normalizePath`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `isAbsolutePath`

isAbsolutePath отвечает на вопрос «путь начинается с якоря?», НО не на вопрос «путь полностью определён без CWD?». "\foo" и "/foo" — это корень ТЕКУЩЕГО диска: чтобы получить полный путь, нужен CWD (см. makeAbs). makeAbs обрабатывает их в отдельной ветке; isAbsolutePath("\\foo") == true — это осознанно: для чистого разбора строк без ФС такое соглашение удобно, но вызывающий должен помнить, что резолв всё равно требует CWD.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `getFileName`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `getExtension`

Расширение — от последней точки до конца, при условиях: * точка не в позиции 1 (иначе ".bashrc" — dotfile, ext = ""); * за точкой что-то есть (иначе "a." — trailing dot, ext = ""). Примеры: "file.tar.gz"     -> ".gz" ".config.json"    -> ".json" ".bashrc"         -> "" "a."              -> "" "a.b.c"           -> ".c"

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `getDirName`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `lcgNext`

### `lcgSeed`

### `utf16leToUtf8`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `isSafeDir`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `d` | `any` |  |

### `tempCandidates`

### `writeAndVerify`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |
| `content` | `any` |  |

### `removeWithRetry`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `makeTempPair`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `pathContent` | `any` |  |
| `batBody` | `any` |  |

### `processCwd`

### `resetCwdCache`

### `makeAbs`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `getScriptDir`

### `runBat`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `target` | `any` |  |
| `batBody` | `any` |  |

### `fileExists`

Проверка «это файл» через `if exist`. В отличие от io.open: * путь уходит в cmd через /u (UTF-16LE) — кириллица работает; * нечитаемые / эксклюзивно занятые файлы находятся (проверка на уровне namespace, а не через fopen); * `if exist "%P%\"` истинно только для каталогов — так мы отсекаем директории (io.open на директорию в Windows тоже даёт NULL, но не по всем причинам); * устройства NUL/CON/PRN/AUX/COM1.. `if exist` считает существующими — это ограничение, см. шапку. Цена — spawn cmd и два temp-файла на вызов.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `dirExists`

Существование директории: pushd успешен → это папка. Никакого парсинга локализованного текста dir. Проверка первого символа (не find) — детерминированно.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |

### `listEntries`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `path` | `any` |  |
| `mode` | `any` |  |

### `listFiles`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `dir` | `any` |  |

### `listFilesRecursive`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `dir` | `any` |  |

### `listDirs`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `dir` | `any` |  |

### `joinPath`

============================================================ 10. Склейка путей ============================================================ Единая функция для обоих старых имён (joinPath/pathCombine). Контракт: * nil / "" на любом аргументе — толерантно (совместимо с path_utils.pathCombine); не-строки — error. * Первый аргумент нормализуется (слэши, /, хвостовой \). * Второй аргумент нормализуется по слэшам. * Если b абсолютный (C:\x, \\server\share, \foo) — он выигрывает и возвращается как нормализованный. Это соглашение .NET Path.Combine и Python os.path.join; снимает сюрприз «C:\foo\C:\x». * Изменение контракта относительно старого listFiles.joinPath: joinPath(dir, "") теперь возвращает normalizePath(dir) (раньше — dir .. "\"), joinPath(dir, nil) больше не падает (раньше — assert). Сделано ради совместимости с pathCombine. Тесты должны учитывать (см. M._test).

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `a` | `any` |  |
| `b` | `any` |  |

### `renameFile`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `oldPath` | `any` |  |
| `newName` | `any` |  |

### `lcgReset`

Сброс LCG к детерминированному состоянию (state = 0, seeded = false). После вызова первый lcgNext() вернёт 1013904223 — удобно для юнит-тестов makeTempPair.

---

## File: `random.lua` (Lua)

random.lua
Генератор случайных байт для утилиты переименования.
Lua 5.1.4, Windows. Без C-модулей, io.popen, os.execute.

Использование как модуля:
local random = dofile("random.lua")   -- или require после настройки путей
random.initRandom()                   -- один раз при старте
local bytes = random.getRandomBytes(16)

### `hash_string`

Хеш строки с модульной арифметикой. Смешивает несколько источников энтропии. В Lua 5.1 нет побитовых операций — используем арифметическую свёртку.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `s` | `any` |  |

### `M.getRandomBytes`

Возвращает строку из n случайных байт (0x00–0xFF). Это единственное место, где вызывается math.random. Для замены источника на криптостойкий достаточно переписать тело функции.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `n` | `any` |  |

### `M.initRandom`

Инициализирует seed генератора. Вызывать один раз при старте скрипта до первого getRandomBytes. Опциональный custom_seed позволяет воспроизводимость.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `custom_seed` | `any` |  |

### `run_self_test`

Самотест. Запускается только при прямом вызове файла (lua random.lua), но не при require/dofile как модуля.

### `check`

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `name` | `any` |  |
| `ok` | `any` |  |
| `detail` | `any` |  |

