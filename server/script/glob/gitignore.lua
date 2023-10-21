local lpeglabel = require("lpeglabel")
local matcher = require("glob.matcher")

--- Constructs a parsing expression for matching a property with a given name and pattern.
---@param name string
---@param pattern number
---@return number
local function prop(name, pattern)
    return lpeglabel.Cg(lpeglabel.Cc(true), name) * pattern
end

--- Constructs a parsing expression for matching an object with a specified type and pattern.
---@param type string
---@param pattern number
---@return number
local function object(type, pattern)
    return lpeglabel.Ct(lpeglabel.Cg(lpeglabel.Cc(type), "type") * lpeglabel.Cg(pattern, "value"))
end

--- Constructs a parsing expression for matching an expression and provides an error message if it doesn"t match.
---@param p number
---@param error string
---@return number
local function expect(p, error)
    return p + lpeglabel.T(error)
end

local parser = lpeglabel.P {
    "Main",
    ["Sp"] = lpeglabel.S(" \t") ^ 0,
    ["Slash"] = lpeglabel.S("/") ^ 1,
    ["Main"] = lpeglabel.Ct(
                lpeglabel.V("Sp")
                * lpeglabel.P("{")
                * lpeglabel.V("Pattern")
                * ("," * expect(lpeglabel.V("Pattern"), "Miss exp after \",\"")) ^ 0
                * lpeglabel.P("}")
            ) + lpeglabel.Ct(lpeglabel.V("Pattern"))+ lpeglabel.T("Main Failed"),
    ["Pattern"] = lpeglabel.Ct(
                lpeglabel.V("Sp")
                * prop("neg", lpeglabel.P("!"))
                * expect(lpeglabel.V("Unit"), "Miss exp after \"!\"")
            ) + lpeglabel.Ct(lpeglabel.V("Unit")),
    ["NeedRoot"] = prop(
                "root",
                (
                    lpeglabel.P(".")
                    * lpeglabel.V("Slash")
                    + lpeglabel.V("Slash")
                )
            ),
    ["Unit"] = (
        lpeglabel.V("Sp")
        * lpeglabel.V("NeedRoot") ^ -1
        * expect(lpeglabel.V("Exp"), "Miss exp") * lpeglabel.V("Sp")
    ),
    ["Exp"] = (
        lpeglabel.V("Sp")
        * (
            lpeglabel.V("FSymbol")
            + object("/", lpeglabel.V("Slash")) + lpeglabel.V("Word")
        )
        ^ 0
        * lpeglabel.V("Sp")
    ),
    ["Word"] = object(
        "word",
        lpeglabel.Ct(
            (
                lpeglabel.V("CSymbol")
                + lpeglabel.V("Char")
                - lpeglabel.V("FSymbol")
            ) ^ 1
        )
    ),
    ["CSymbol"] = (
        object("*", lpeglabel.P("*"))
        + object("?", lpeglabel.P("?"))
        + object("[]", lpeglabel.V("Range"))
    ),
    ["SimpleChar"] = lpeglabel.P(1) - lpeglabel.S(",{}[]*?/"),
    ["EscChar"] = lpeglabel.P("\\") / "" * lpeglabel.P(1),
    ["Char"] = object(
        "char",
        lpeglabel.Cs(
            (
                lpeglabel.V("EscChar")
                + lpeglabel.V("SimpleChar")
            )
            ^ 1
        )
    ),
    ["FSymbol"] = object("**", lpeglabel.P("**")),
    ["Range"] = (
        lpeglabel.P("[")
        * lpeglabel.Ct(lpeglabel.V("RangeUnit")^ 0)
        * lpeglabel.P("]")^ -1
    ),
    ["RangeUnit"] = lpeglabel.Ct(
        -lpeglabel.P("]")
        * lpeglabel.C(lpeglabel.P(1))
        * (
            lpeglabel.P("-")
            * -lpeglabel.P("]")
            * lpeglabel.C(lpeglabel.P(1))
        ) ^ -1
    ),
}

---@class gitignore
---@field pattern string[]
---@field options table
---@field errors table[]
---@field matcher table
---@field interface function[]
local metatable = {}
metatable.__index = metatable
metatable.__name = "gitignore"

--- Adds a pattern to the pattern matching object and compiles it for pattern matching.
---@param pattern string
function metatable:addPattern(pat)
    if type(pat) ~= "string" then return end

    self.pattern[#self.pattern+1] = pat
    if self.options.ignoreCase then pat = pat:lower() end

    local states, err = parser:match(pat)
    if not states then
        self.errors[#self.errors+1] = {
            pattern = pat,
            message = err
        }

        return
    end

    for _, state in ipairs(states) do
        self.matcher[#self.matcher+1] = matcher(state)
    end
end

--- Sets an option for the pattern matching object.
---@param option string
---@param value any
function metatable:setOption(option, value)
    self.options[option] = value == nil and true or value
end

--- Sets an interface using the given key
---@param key string | ""type"" | ""list""
---@param func function | "function (path) end"
function metatable:setInterface(key, func)
    if type(func) ~= "function" then return end

    self.interface[key] = func
end

--- Calls an interface with the given name and pass the provided parameters
---@param name string
---@param ... any
function metatable:callInterface(name, ...)
    return self.interface[name](...)
end

--- Checks if an interface with the name "name" exists
---@param name string
function metatable:hasInterface(name)
    return self.interface[name] ~= nil
end

--- Checks if the specified path and matcher combination should be considered a directory or not.
---@param catch string
---@param path string
---@param matcher table
---@return boolean
function metatable:checkDirectory(catch, path, matcher)
    if not self:hasInterface "type" then return true end
    if not matcher:isNeedDirectory() then return true end
    if #catch < #path then return true end
    --? if path is "a/b/c" and catch is "a/b" then the catch must be a directory

    return self:callInterface("type", path) == "directory"
end

--- Performs a simple path matching operation using a list of matchers.
---@param path string
---@return boolean|nil
function metatable:simpleMatch(path)
    path = self:getRelativePath(path)

    for i = #self.matcher, 1, -1 do
        local matcher = self.matcher[i]
        local catch = matcher(path)

        if catch and self:checkDirectory(catch, path, matcher) then
            return not matcher:isNegative()
        end
    end

    return nil
end

--- Continuously checks for matches while constructing paths from left to right.
---@param path string
---@return boolean|nil
function metatable:finishMatch(path)
    local paths = {}
    for filename in path:gmatch "[^/\\]+" do
        paths[#paths+1] = filename
    end

    for i = 1, #paths do
        local newPath = table.concat(paths, "/", 1, i)
        local passed = self:simpleMatch(newPath)

        if passed == true or passed == false then
            return passed
        end
    end

    return false
end

--- Adjusts the provided path to be relative to a specified root path.
---@param path string
---@return string
function metatable:getRelativePath(path)
    local root = self.options.root or ""

    if self.options.ignoreCase then
        path = path:lower()
        root = root:lower()
    end

    path = path:gsub("^[/\\]+", ""):gsub("[/\\]+", "/")
    root = root:gsub("^[/\\]+", ""):gsub("[/\\]+", "/")

    if path:sub(1, #root) == root then
        path = path:sub(#root + 1)
        path = path:gsub("^[/\\]+", "")
    end

    return path
end

--- Scans a path for files and directories that match the defined patterns.
---@param path string
---@param callback function
---@return table
function metatable:scan(path, callback)
    if type(callback) ~= "function" then callback = nil end

    local files = {}
    local list = {}

    local function check(current)
        local fileType = self:callInterface("type", current)

        if fileType == "file" then
            if callback then callback(current) end

            files[#files + 1] = current

        elseif fileType == "directory" then
            local result = self:callInterface("list", current)

            if type(result) == "table" then
                for _, path in ipairs(result) do
                    local filename = path:match("([^/\\]+)[/\\]*$")

                    if filename and filename ~= "." and filename ~= ".." then
                        list[#list+1] = path
                    end
                end
            end
        end
    end

    if not self:simpleMatch(path) then check(path) end

    while #list > 0 do
        local current = list[#list]
        if not current then break end

        list[#list] = nil
        if not self:simpleMatch(current) then check(current) end
    end

    return files
end

--- Invokes the module as a function, checking a path against the defined patterns.
---@param path string
---@return boolean|nil
function metatable:__call(path)
    return self:finishMatch(self:getRelativePath(path))
end

--- Creates a new glob matcher object.
---@param pattern string|table
---@param options table
---@param interface table
---@return table
return function(pattern, options, interface)
    local self = setmetatable({
        pattern = {},
        options = {},
        matcher = {},
        errors = {},
        interface = {},
    }, metatable)

    if type(options) == "table" then
        for op, val in pairs(options) do
            self:setOption(op, val)
        end
    end

    if type(pattern) == "table" then
        for _, pat in ipairs(pattern) do
            self:addPattern(pat)
        end
        
    else
        self:addPattern(pattern)
    end

    if type(interface) == "table" then
        for key, func in pairs(interface) do
            self:setInterface(key, func)
        end
    end

    return self
end
