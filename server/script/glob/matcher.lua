local lpeglabel = require("lpeglabel")

local Slash = lpeglabel.S("/\\") ^ 1
local Symbol = lpeglabel.S(",{}[]*?/\\")
local Char = 1 - Symbol
local Path = Char ^ 1 * Slash
local NoWord = #(lpeglabel.P(-1) + Symbol)

--- Creates an LPEG pattern that matches any input and prints the captured values or arguments.
---@eturn table
local function whatHappened()
    return lpeglabel.Cmt(lpeglabel.P(1) ^ 1, function (...)
        print(...)
    end)
end

local metatable = {}
metatable.__index = metatable
metatable.__name = "matcher"

function metatable:exp(state, index)
    local exp = state[index]
    if not exp then return end

    --TODO: Turn this into a table and replace this monstrosity
    if exp.type == "word" then
        return self:word(exp, state, index + 1)
    elseif exp.type == "char" then
        return self:char(exp, state, index + 1)
    elseif exp.type == "**" then
        return self:anyPath(exp, state, index + 1)
    elseif exp.type == "*" then
        return self:anyChar(exp, state, index + 1)
    elseif exp.type == "?" then
        return self:oneChar(exp, state, index + 1)
    elseif exp.type == "[]" then
        return self:range(exp, state, index + 1)
    elseif exp.type == "/" then
        return self:slash(exp, state, index + 1)
    end
end

--- Constructs a composite expression by combining the current expression with a state expression.
---@param exp table
---@param state table
---@param index number
---@return number
function metatable:word(exp, state, index)
    local current = self:exp(exp.value, 1)
    local after = self:exp(state, index)

    if after then
        return current * Slash * after
    else
        return current
    end
end

--- Constructs a composite expression by combining the current character expression with a state expression.
---@param exp table
---@param state table
---@param index number
---@return number
function metatable:char(exp, state, index)
    local current = lpeglabel.P(exp.value)
    local after = self:exp(state, index)

    if after then
        return current * after * NoWord
    else
        return current * NoWord
    end
end

--- Constructs an expression that represents any valid path or a sequence of paths.
---@param _ any
---@param state table
---@param index number
---@return number
function metatable:anyPath(_, state, index)
    local after = self:exp(state, index)

    if after then
        return lpeglabel.P {
            "Main",
            Main = after + Path * lpeglabel.V("Main")
        }

    else
        return Path ^ 0
    end
end

--- Constructs a parsing expression for matching characters with optional state-based matching.
---@param _ any
---@param state table
---@param index number
---@return number
function metatable:anyChar(_, state, index)
    local after = self:exp(state, index)

    if after then
        return lpeglabel.P {
            "Main",
            Main = after + Char * lpeglabel.V("Main")
        }

    else
        return Char ^ 0
    end
end

--- Constructs a parsing expression for matching a single character with optional state-based matching.
---@param _ any
---@param state table
---@param index number
---@return number
function metatable:oneChar(_, state, index)
    local after = self:exp(state, index)
    if after then
        return Char * after
    else
        return Char
    end
end

--- Constructs a parsing expression for matching characters within specified ranges with optional state-based matching.
---@param exp table
---@param state table
---@param index number
---@return number
function metatable:range(exp, state, index)
    local after = self:exp(state, index)
    local ranges = {}
    local selects = {}
    for _, range in ipairs(exp.value) do
        if #range == 1 then
            selects[#selects+1] = range[1]
        elseif #range == 2 then
            ranges[#ranges+1] = range[1] .. range[2]
        end
    end
    local current = lpeglabel.S(table.concat(selects)) + lpeglabel.R(table.unpack(ranges))
    if after then
        return current * after
    else
        return current
    end
end

--- Constructs a parsing expression for matching slashes with optional state-based matching and sets a flag to indicate the need for a directory.
---@param _ any
---@param state table
---@param index number
---@return number
function metatable:slash(_, state, index)
    local after = self:exp(state, index)
    if after then
        return after
    else
        self.needDirectory = true
        return nil
    end
end

--- Constructs a parsing expression for matching a pattern based on whether it's the root or not.
---@param state table
---@return number
function metatable:pattern(state)
    if state.root then
        return lpeglabel.C(self:exp(state, 1))
    else
        return lpeglabel.C(self:anyPath(nil, state, 1))
    end
end

--- Checks whether a directory is needed based on a flag set during parsing.
---@return boolean
function metatable:isNeedDirectory()
    return self.needDirectory == true
end

--- Checks whether a pattern is negative based on state information.
---@return boolean
function metatable:isNegative()
    return self.state.neg == true
end

--- Allows the object to be called as a function, matching a given path against the defined pattern.
---@param path string
---@return any
function metatable:__call(path)
    return self.matcher:match(path)
end

return function (state, options)
    local self = setmetatable({
        options = options,
        state = state,
    }, metatable)
    self.matcher = self:pattern(state)
    return self
end
