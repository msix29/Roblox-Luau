local thread = require("bee.thread")

local taskPad = thread.channel("taskpad")
local waiter  = thread.channel("waiter")

---@class pub_brave
local brave = {}
brave.type = "brave"
brave.ability = {}
brave.queue = {}

--- Register to become a warrior
---@param id number
function brave.register(id)
    brave.id = id

    if #brave.queue > 0 then
        for _, info in ipairs(brave.queue) do
            waiter:push(brave.id, info.name, info.params)
        end
    end

    brave.queue = nil
    brave.start()
end

--- Registration ability
---@param name string
---@param callback function
function brave.on(name, callback)
    brave.ability[name] = callback
end

--- Report
---@param name string
---@param params any
function brave.push(name, params)
    if brave.id then
        waiter:push(brave.id, name, params)

    else
        brave.queue[#brave.queue+1] = {
            name   = name,
            params = params,
        }
    end
end

--- Start looking for a job
function brave.start()
    brave.push("mem", collectgarbage "count")

    while true do
        local name, id, params = taskPad:bpop()
        local ability = brave.ability[name]

        if not ability then
            waiter:push(brave.id, id)
            log.error("Brave can not handle this work: "..name)

            goto CONTINUE
        end

        local ok, res = xpcall(ability, log.error, params)
        waiter:push(brave.id, id, ok and res or nil)
        brave.push("mem", collectgarbage "count")

        ::CONTINUE::
    end
end

return brave
