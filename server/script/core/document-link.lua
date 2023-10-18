local util = require 'utility'
local fileUriModule = require 'file-uri'
local knitUtils = require 'knit-utils'
local files = require 'files'
local guide = require 'core.guide'
local vm = require 'vm'

return function (uri)
    local ast = files.getAst(uri)
    if not ast then
        return
    end
    local results = {}

    -- every source that calls something in the file
    -- change to not make sure it is in the visible ranges
    -- this is where types/auto complete can transfer from different files (or not?)

    guide.eachSourceType(ast.ast, "call", function(source)
        log.info("CALL LINK")

        if source.node.special == "require" then
            if source.args and source.args[1] then
                local defs = vm.getDefs(source.args[1])
                for _, def in ipairs(defs) do
                    if def.uri then
                        results[#results+1] = {
                            range = files.range(uri, source.args[1].start, source.args[1].finish),
                            tooltip = "Go To Script",
                            target = def.uri
                        }
                    end
                end
            end
        ---- KNIT EXTENSION
        -- lets you click and navigate to the knit file its referencing
        -- doesnt work with some file names
        -- puts links on the "local service/controller and the definition aka declaration and definition"
        -- gotta do automatically making service/controller delcarations and definitions
        -- and auto completion across different knit files (proto.on completion)
        elseif source.node.field and source.node.field[1] == "GetService" then
            -- assuming this is knit (only thing that has GetService and uses a dot)
            local serviceName = source.args[1][1]
            knitUtils.resolveKnitRequires(serviceName, true, "CreateService", results, source, uri)
        elseif source.node.field and source.node.field[1] == "GetController" then
            -- assuming this is knit (only thing that has GetController and uses a dot)
            local controllerName = source.args[1][1]
            knitUtils.resolveKnitRequires(controllerName, true, "CreateController", results, source, uri)
        end
    end)
    if #results == 0 then
        return nil
    end
    return results
end