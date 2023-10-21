local util = require 'utility'
local furi = require 'file-uri'
local files = require 'files'
local guide = require 'core.guide'

local knitUtils = {}

--@param serviceOrControllerName string
--@param isDocumentLink boolean
--@param method string
--@param results {}
--@param source string
--@param uri string
function knitUtils.resolveKnitRequires(serviceOrControllerName, isDocumentLink, method, results, source, uri)
    local serviceUri

    for _, fileUri in ipairs(files.getAllUris()) do
		--? Package managers like Wally add too many files and the user doesn't access them at
		--? all, (s)he only accesses the main require for them so it's better to skip them.
		--? Knit controllers and services won't be there at all.
        if fileUri:find("_Index") then goto CONTINUE end

		local filePath = furi.decode(fileUri)
		local fileSource = util.loadFile(filePath)
        local pattern = ".-Name%s-=%s-\"%s-"..serviceOrControllerName
		local match
        if method then
            match = fileSource:match(method..pattern)
        else
            match = fileSource:match("CreateController"..pattern) or fileSource:match("CreateService"..pattern)
        end
		--? This is to match creating service or controllers

		if match ~= nil then
			serviceUri = fileUri

			if fileUri:find("init%.lua") then
				--? if this is a init.lua file under a folder, this would be where the real methods are located
				--? so stop here and make sure nothing overwrites it.

				log.info("DOCUMENT LINK STOP FULL STOP")

				break
			end
		end

        ::CONTINUE::
    end

	if not isDocumentLink then return serviceUri end

    if serviceUri then
        results[#results+1] = {
            range = files.range(uri, source.start, source.finish),
            tooltip = "Go To Script",
            target = serviceUri
        }
    end

    local status = guide.status()
    guide.searchRefs(status, source.parent.parent, "def")
    local statusResults = status.results

    for _, result in ipairs(statusResults) do
        if result.type == "local" then
            results[#results+1] = {
                range = files.range(uri, result.start, result.finish),
                tooltip = "Go To Script",
                target = serviceUri
            }
        end
    end
end

function knitUtils.isKnitFile(uri, method, serviceOrControllerName)
    serviceOrControllerName = serviceOrControllerName or ""

    local filePath = furi.decode(uri)
    local fileSource = util.loadFile(filePath)
    local pattern = ".-Name%s-=%s-\"%s-"..serviceOrControllerName
    local match
    if method then
        match = fileSource:match(method..pattern)
    else
        match = fileSource:match("CreateController"..pattern) or fileSource:match("CreateService"..pattern)
    end
    --? This is to match creating service or controllers

    return match ~= nil
end

return knitUtils