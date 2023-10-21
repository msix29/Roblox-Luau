local error = error
local strchar = string.char
local strbyte = string.byte
local strmatch = string.match
local utf8char = utf8.char
local tableConcat = table.concat

local _utf8byte = utf8.codes("")

--- be encoding to char
---@param code number
local function be_tochar(code)
    return strchar((code >> 8) & 0xFF, code & 0xFF)
end

--- be encoding to byte
---@param code number
local function be_tobyte(s, i)
    local h, l = strbyte(s, i, i+1)

    return (h << 8) | l
end

--- le encoding to char
---@param code number
local function le_tochar(code)
    return strchar(code & 0xFF, (code >> 8) & 0xFF)
end

--- le encoding to byte
---@param code number
local function le_tobyte(s, i)
    local l, h = strbyte(s, i, i+1)
    return (h << 8) | l
end

--- Converts a Unicode code point to a UTF-16 encoded character string.
---@param tochar function
---@param code number
---@return string
local function utf16char(tochar, code)
    if code < 0x10000 then
        return tochar(code)

    else
        code = code - 0x10000
        return tochar(0xD800 + (code >> 10))..tochar(0xDC00 + (code & 0x3FF))
    end
end

--- Advances the position in a UTF-16 encoded string and retrieves the next Unicode code point.
---@param s string
---@param n number
---@param tobyte function
---@return number, number|nil
local function utf16next(s, n, tobyte)
    if n > #s then return end

    local code1 = tobyte(s, n)
    if code1 < 0xD800 or code1 >= 0xE000 then
        return n + 2, code1

    elseif code1 >= 0xD800 and code1 < 0xDC00 then
        n = n + 2
        if n > #s then return n end --! invaild

        local code2 = tobyte(s, n)
        if code2 < 0xDC00 or code2 >= 0xE000 then return n end --! invaild

        local code = 0x10000 + ((code1 - 0xD800) << 10) + ((code2 - 0xDC00) & 0x3FF)

        return n + 2, code

    else
        return n + 2 --! invaild
    end
end

--- Creates an iterator function for iterating over Unicode code points in a UTF-16 encoded string.
---@param s string
---@param tobyte function
---@return function, string, number
local function utf16codes(s, tobyte)
    return function(_, n)
        return utf16next(s, n, tobyte)
    end, s, 1
end

--- Retrieves the Unicode code point at a specified position in a UTF-8 encoded string.
---@param s string
---@param n number
---@return number
local function utf8byte(s, n)
    local _, code = _utf8byte(s, n - 1)

    return code
end

--[[
    U+0000..  U+007F 00..7F
    U+0080..  U+07FF C2..DF 80..BF
    U+0800..  U+0FFF E0     A0..BF 80..BF
    U+1000..  U+CFFF E1..EC 80..BF 80..BF
    U+D000..  U+D7FF ED     80..9F 80..BF
    U+E000..  U+FFFF EE..EF 80..BF 80..BF
    U+10000.. U+3FFFF F0     90..BF 80..BF 80..BF
    U+40000.. U+FFFFF F1..F3 80..BF 80..BF 80..BF
    U+100000..U+10FFFF F4     80..8F 80..BF 80..BF
]]
--- Advances the position in a UTF-8 encoded string and retrieves the next Unicode code point.
---@param s string
---@param n number
---@return number, number|nil
local function utf8next(s, n)
    if n > #s then return end

    --TODO: Turn this into a table and replace this monstrosity
    if strmatch(s, "^[\0-\x7F]", n) then
        return n + 1, utf8byte(s, n)
    elseif strmatch(s, "^[\xC2-\xDF][\x80-\xBF]", n) then
        return n + 2, utf8byte(s, n)
    elseif strmatch(s, "^[\xE0][\xA0-\xBF][\x80-\xBF]", n) then
        return n + 3, utf8byte(s, n)
    elseif strmatch(s, "^[\xE1-\xEC][\x80-\xBF][\x80-\xBF]", n) then
        return n + 3, utf8byte(s, n)
    elseif strmatch(s, "^[\xED][\x80-\x9F][\x80-\xBF]", n) then
        return n + 3, utf8byte(s, n)
    elseif strmatch(s, "^[\xEE-\xEF][\x80-\xBF][\x80-\xBF]", n) then
        return n + 3, utf8byte(s, n)
    elseif strmatch(s, "^[\xF0][\x90-\xBF][\x80-\xBF][\x80-\xBF]", n) then
        return n + 4, utf8byte(s, n)
    elseif strmatch(s, "^[\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF]", n) then
        return n + 4, utf8byte(s, n)
    elseif strmatch(s, "^[\xF4][\x80-\x8F][\x80-\xBF][\x80-\xBF]", n) then
        return n + 4, utf8byte(s, n)
    else
        return n + 1 --! invaild
    end
end

--- Creates an iterator function for iterating over Unicode code points in a UTF-8 encoded string.
---@param s string
---@return function, string, number
local function utf8codes(s)
    return utf8next, s, 1
end

--- Creates an encoding conversion utility for converting between UTF-8 and UTF-16 encodings.
---@param encodingType string
---@param replace string|nil
---@return table
return function(encodingType, replace)
    local tobyte, tochar
    if encodingType == "be" then
        tobyte = be_tobyte
        tochar = be_tochar
    else
        tobyte = le_tobyte
        tochar = le_tochar
    end

    local utf8replace = replace and utf8char(replace)
    local utf16replace = replace and utf16char(tochar, replace)

    local function toutf8(s)
        local t = {}

        for _, code in utf16codes(s, tobyte) do
            if code == nil then
                if replace then
                    t[#t + 1] = utf8replace
                else
                    error("invalid UTF-16 code")
                end

            else
                t[#t + 1] = utf8char(code)
            end
        end

        return tableConcat(t)
    end
    local function fromutf8(s)
        local t = {}

        for _, code in utf8codes(s) do
            if code == nil then
                if replace then
                    t[#t + 1] = utf16replace
                else
                    error("invalid UTF-8 code")
                end

            else
                t[#t + 1] = utf16char(tochar, code)
            end
        end

        return tableConcat(t)
    end

    return {
        toutf8 = toutf8,
        fromutf8 = fromutf8,
    }
end
