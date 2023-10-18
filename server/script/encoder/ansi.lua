local platform = require("bee.platform")
local unicode = platform.OS == "Windows" and require("bee.unicode") or nil

local ansi = {}

--- Turn text into utf8
---@param text string
function ansi.toutf8(text)
    if not unicode then return text end

    return unicode.a2u(text)
end

--- Turn utf8 to text
---@param text string
function ansi.fromutf8(text)
    if not unicode then return text end

    return unicode.u2a(text)
end

return ansi
