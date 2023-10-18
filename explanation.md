# Explanation file

This file will explain what you need to know in order to be able to edit this extension effectively. Most of the functions have explanations on what they do so this file will only explain meaning of things.

* Uri: A way to encode file paths, ex. "C:\my_project\file.txt" on a Windows system will be represented as "file:///C:/my_project/file.txt". [How to edit](#how-to-work-with-uris)
* Logging/printing: Normal `print()` doesn't work here so you will need to use the global `log()`. [How to log](#how-to-log)

## How to work with URIs

You can work with URIs using the `file-uri` file, commonly referred to as furi.

```lua
local furi = require("file-uri")

local path = "C:\\my_project\\file.txt" -- \\ Will correspond to one \ at the end.
local uri = furi.encode(path) -- file:///C:/my_project/file.txt
furi.decode(uri) -- C:\my_project\file.txt (same as path variable above)
```

## How to Log

Unlike normal Lua code, you can't just use the normal `print()`, you use the global `log` made in this extension. Here's what you need to know about using it.

```lua
log.info(value) -- Prints standard Lua output, tables are output as their hexadecimal memory address
log.tableInfo(value) -- Used to print table values, doesn't output their hexadecimal memory address like log.info()
log.warn(value) -- Same as info() but shows [warn] instead of [info] at the start of the line
log.error(value) -- Same as info() but shows [error] instead of [info] at the start of the line
```

To read the output of your logs, open `.vscode\extensions\msix29.roblox-luau-language-server-0.0.2\server\log` and look for the file named as the path to the project where the language server was ran. If you want to find a specific log, you can Ctrl + F and look for the line in which u called the `log.method()` in or using the name of the file that called the `log.method()` in.
