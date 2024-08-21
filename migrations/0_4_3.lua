---@diagnostic disable: no-unknown
local states = global["tiergen-menu"]
if states then
	global["tiergen-menu"] = nil
	global.gui_states = global.gui_states or {}
	global.gui_states["tiergen-menu"] = global.gui_states["tiergen-menu"] or states
end