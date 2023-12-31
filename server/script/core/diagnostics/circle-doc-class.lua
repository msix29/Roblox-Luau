local files = require("files")
local guide = require("core.guide")
local lang = require("language")
local define = require("proto.define")
local vm = require("vm")

return function(uri, callback)
    local state = files.getAst(uri)
    if not state then return end
    if not state.ast.docs then return end

    for _, doc in ipairs(state.ast.docs) do
        if doc.type ~= "doc.class" then goto MAIN_CONTINUE end
        if not doc.extends then goto MAIN_CONTINUE end

        local myName = guide.getKeyName(doc)
        local list = {doc}
        local mark = {}

        for i = 1, 999 do
            local current = list[i]
            if not current then goto MAIN_CONTINUE end
            if not current.extends then goto SECONDARY_CONTINUE end

            for _, extend in ipairs(current.extends) do
                local newName = extend[1]
                if newName == myName then
                    callback {
                        start = doc.start,
                        finish = doc.finish,
                        message = lang.script("DIAG_CIRCLE_DOC_CLASS", myName)
                    }

                    goto MAIN_CONTINUE
                end

                if not mark[newName] then
                    mark[newName] = true
                    local docs = vm.getDocTypes(newName)

                    for _, otherDoc in ipairs(docs) do
                        if otherDoc.type == "doc.class.name" then
                            list[#list+1] = otherDoc.parent
                        end
                    end
                end
            end

            ::SECONDARY_CONTINUE::
        end

        ::MAIN_CONTINUE::
    end
end
