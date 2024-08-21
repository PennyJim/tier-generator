---@type event_handler
local handlers = {events={}}
---@type TierGlobal
global = {tick_later = {}, seconds = {}, debug_table = {}, config = {}}

---Initializes the global variables
local function setup()
	---@type string[]
	global.tick_later = global.tick_later or {}
end
function handlers.on_configuration_changed(EventData)
	if EventData.mod_changes[script.mod_name] then
		setup()
	end
end
function handlers.on_init()
	setup()
end

return handlers