if not DEVELOP then return end

local fs = require("bee.filesystem")

local luaDebugs = {}
local vscodePaths = {".vscode", ".vscode-insiders", ".vscode-server-insiders"}

for i, vscodePath in ipairs(vscodePaths) do
    local extensionPath = fs.path(os.getenv("USERPROFILE") or os.getenv("HOME")) / vscodePath / 'extensions'
    log.debug('Searching extensions at: ', extensionPath:string())

    if not fs.exists(extensionPath) then goto MAIN_CONTINUE end

    for path in fs.pairs(extensionPath) do
        if not fs.is_directory(path) then goto SECONDARY_CONTINUE end

        local name = path:filename():string()
        if name:find('actboy168.lua-debug-', 1, true) then
            luaDebugs[#luaDebugs+1] = path:string()
        end

        ::SECONDARY_CONTINUE::
    end

    ::MAIN_CONTINUE::
end

if #luaDebugs == 0 then return log.debug("Cant find \"actboy168.lua-debug\"") end

local function getVersion(filename)
    local a, b, c = filename:match("(%d+)%.(%d+)%.(%d+)$")
    if not a then return 0 end

    return a * 1000000 + b * 1000 + c
end

-- Higher versions come first
table.sort(luaDebugs, function(a, b)
    return getVersion(a) > getVersion(b)
end)

local debugPath = luaDebugs[1]
local cpath = "/runtime/win64/lua54/?.dll;/runtime/win64/lua54/?.so"
local path  = "/script/?.lua"

local function tryDebugger()
    local entry = assert(package.searchpath('debugger', debugPath .. path))
    local root = debugPath
    local address = ("127.0.0.1:%d"):format(DEBUGPORT)
    local debug = loadfile(entry)(root)
    debug:start {
        address = address,
        latest = true,
    }

    log.debug('Debugger started, port: ', DEBUGPORT)
    log.debug('Debugger args:', address, root, path, cpath)

    if DEBUGWAIT then debug:event('wait') end

    return debug
end

xpcall(tryDebugger, log.debug)
