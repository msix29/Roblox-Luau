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

--TODO: Use recleun answer here
local parser = lpeglabel.P {
    'Main',
    ['Sp']          = lpeglabel.S(' \t')^0,
    ['Slash']       = lpeglabel.P('/')^1,
    ['Main']        = lpeglabel.Ct(lpeglabel.V'Sp' * lpeglabel.P'{' * lpeglabel.V'Pattern' * (',' * expect(lpeglabel.V'Pattern', 'Miss exp after ","'))^0 * lpeglabel.P'}')
                    + lpeglabel.Ct(lpeglabel.V'Pattern')
                    + lpeglabel.T'Main Failed'
                    ,
    ['Pattern']     = lpeglabel.Ct(lpeglabel.V'Sp' * prop('neg', lpeglabel.P'!') * expect(lpeglabel.V'Unit', 'Miss exp after "!"'))
                    + lpeglabel.Ct(lpeglabel.V'Unit')
                    ,
    ['NeedRoot']    = prop('root', (lpeglabel.P'.' * lpeglabel.V'Slash' + lpeglabel.V'Slash')),
    ['Unit']        = lpeglabel.V'Sp' * lpeglabel.V'NeedRoot'^-1 * expect(lpeglabel.V'Exp', 'Miss exp') * lpeglabel.V'Sp',
    ['Exp']         = lpeglabel.V'Sp' * (lpeglabel.V'FSymbol' + object('/', lpeglabel.V'Slash') + lpeglabel.V'Word')^0 * lpeglabel.V'Sp',
    ['Word']        = object('word', lpeglabel.Ct((lpeglabel.V'CSymbol' + lpeglabel.V'Char' - lpeglabel.V'FSymbol')^1)),
    ['CSymbol']     = object('*',    lpeglabel.P'*')
                    + object('?',    lpeglabel.P'?')
                    + object('[]',   lpeglabel.V'Range')
                    ,
    ['SimpleChar']  = lpeglabel.P(1) - lpeglabel.S',{}[]*?/',
    ['EscChar']     = lpeglabel.P'\\' / '' * lpeglabel.P(1),
    ['Char']        = object('char', lpeglabel.Cs((lpeglabel.V'EscChar' + lpeglabel.V'SimpleChar')^1)),
    ['FSymbol']     = object('**', lpeglabel.P'**'),
    ['RangeWord']   = 1 - lpeglabel.P']',
    ['Range']       = lpeglabel.P'[' * lpeglabel.Ct(lpeglabel.V'RangeUnit'^0) * lpeglabel.P']'^-1,
    ['RangeUnit']   = lpeglabel.Ct(lpeglabel.C(lpeglabel.V'RangeWord') * lpeglabel.P'-' * lpeglabel.C(lpeglabel.V'RangeWord'))
                    + lpeglabel.V'RangeWord',
}

local metatable = {}
metatable.__index = metatable
metatable.__name = "glob"

--- Adds a pattern to the pattern matching object and compiles it for pattern matching.
---@param pattern string
function metatable:addPattern(pattern)
    if type(pattern) ~= "string" then
        return
    end

    self.pattern[#self.pattern + 1] = pattern
    if self.options.ignoreCase then
        pattern = pattern:lower()
    end

    local states, error = parser:match(pattern)

    if not states then
        self.errors[#self.errors + 1] = {
            pattern = pattern,
            message = error
        }

        return
    end

    for _, state in ipairs(states) do
        if state.neg then
            self.refused[#self.refused + 1] = matcher(state)

        else
            self.passed[#self.passed + 1] = matcher(state)
        end
    end
end

--- Sets an option for the pattern matching object.
---@param option string
---@param value any
function metatable:setOption(option, value)
    self.options[option] = value == nil and true or value
end

--- Allows the pattern matching object to be called as a function for matching a given path.
---@param path string
---@return boolean
function metatable:__call(path)
    if self.options.ignoreCase then
        path = path:lower()
    end

    path = path:gsub("^[/\\]+", "")

    for _, refused in ipairs(self.refused) do
        if refused(path) then
            return false
        end
    end

    for _, passed in ipairs(self.passed) do
        if passed(path) then
            return true
        end
    end

    return false
end

--- Creates and returns a pattern matching object based on the provided patterns and options.
---@param pattern string
---@param options table
---@return table
return function(pattern, options)
    local self = setmetatable({
        pattern = {},
        options = {},
        passed = {},
        refused = {},
        errors = {}
    }, metatable)

    if type(pattern) == "table" then
        for _, pattern in ipairs(pattern) do
            self:addPattern(pattern)
        end

    else
        self:addPattern(pattern)
    end

    if type(options) == "table" then
        for option, value in pairs(options) do
            self:setOption(option, value)
        end
    end

    return self
end
