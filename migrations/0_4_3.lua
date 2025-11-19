---@diagnostic disable: no-unknown
local states = storage["tiergen-menu"]
if states then
	storage["tiergen-menu"] = nil
	storage.gui_states = storage.gui_states or {}
	storage.gui_states["tiergen-menu"] = storage.gui_states["tiergen-menu"] or states
end