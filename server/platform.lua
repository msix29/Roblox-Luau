local fs = require 'bee.filesystem'

local script = ...

local function getExecutablePath()
    local n = 0

    while arg[n - 1] do
        n = n - 1
    end

    return arg[n]
end

local exePath = getExecutablePath()
local exeDir = exePath:match("(.+)[/\\][%w_.-]+$")
local dll = package.cpath:match("[/\\]%?%.([a-z]+)")
package.cpath = ("%s/?.%s"):format(exeDir, dll)
-- local ok, err = package.loadlib(exeDir..'/bee.'..dll, 'luaopen_bee_platform')
-- if not ok then
--     error(([[It doesn't seem to support your OS, please build it in your OS, see https://github.com/sumneko/vscode-lua/wiki/Build
-- errorMsg: %s
-- exePath:  %s
-- exeDir:   %s
-- dll:      %s
-- cpath:    %s
-- ]]):format(
--     err,
--     exePath,
--     exeDir,
--     dll,
--     package.cpath
-- ))
-- end

local currentPath = debug.getinfo(1, 'S').source:sub(2)
local rootPath = fs.path(currentPath):remove_filename():string()

if dll == 'dll' then
    rootPath = rootPath:gsub('/', '\\')
    package.path  = rootPath..script..'\\?.lua'
        ..';'..rootPath..script..'\\?\\init.lua'
else
    rootPath = rootPath:gsub('\\', '/')
    package.path  = rootPath..script..'/?.lua'
        ..';'..rootPath..script..'/?/init.lua'
end

package.searchers[2] = function(name)
    local filename, err = package.searchpath(name, package.path)
    if not filename then return err end

    local file = io.open(filename)
    local buffer = file:read '*a'
    file:close()

    local relative = filename:sub(#rootPath + 1)
    local init, _err = load(buffer, '@' .. relative)
    if not init then return _err end

    return init, filename
end
