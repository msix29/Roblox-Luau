local guide    = require 'core.guide'
local vm       = require 'vm'

local buildName

local function asLocal(source)
    return guide.getKeyName(source)
end

local function asField(source, oop)
    local class
    if source.node.type ~= 'getglobal' then
        class = vm.getClass(source.node, 0)
    end
    local node = class or guide.getKeyName(source.node) or '?'
    local method = guide.getKeyName(source)
    if oop then
        return ('%s:%s'):format(node, method)
    else
        return ('%s.%s'):format(node, method)
    end
end

local function asTableField(source)
    if not source.field then
        return
    end
    return guide.getKeyName(source.field)
end

local function asGlobal(source)
    return guide.getKeyName(source)
end

local function asDocFunction(source)
    local doc = guide.getParentType(source, 'doc.type')
            or  guide.getParentType(source, 'doc.overload')
    if not doc or not doc.bindSources then
        return ''
    end
    for _, src in ipairs(doc.bindSources) do
        local name = buildName(src)
        if name ~= '' then
            return name
        end
    end
    return ''
end

local function asDocField(source)
    return source.field[1]
end

function buildName(source, oop)
    -- log.info(source.type, oop)
    if oop == nil then
        oop =  source.type == 'setmethod'
            or source.type == 'getmethod'
            or nil
    end
    if source.type == 'local' then
        return asLocal(source) or '', oop
    end
    if source.type == 'getlocal'
    or source.type == 'setlocal' then
        return asLocal(source.node) or '', oop
    end
    if source.type == 'setglobal'
    or source.type == 'getglobal' then
        return asGlobal(source) or '', oop
    end
    if source.type == 'setmethod'
    or source.type == 'getmethod' then
        return asField(source, oop) or '', oop
    end
    if source.type == 'setfield'
    or source.type == 'getfield' then
        return asField(source, oop) or '', oop
    end
    if source.type == 'tablefield' then
        return asTableField(source) or '', oop
    end
    if source.type == 'doc.type.function' then
        return asDocFunction(source), oop
    end
    if source.type == 'doc.field' then
        return asDocField(source), oop
    end
    if source.type == "type.field" then
        return source.key[1], oop
    end
    if source.type == "type.library" then
        return source.name, oop
    end
    local parent = source.parent
    if parent then
        return buildName(parent, oop)
    end
    return '', oop
end

return buildName
