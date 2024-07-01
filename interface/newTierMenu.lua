local gui = require("__gui-modules__.gui")
gui.new({
	namespace = "tiergen-menu",
	root = "screen",
	version = 1,
	custominput = "tiergen-menu",
	shortcut = "tiergen-menu",
	definition = {
		type = "module", module_type = "window_frame",
		name = "testing", title = "Testing",
		has_close_button = true, has_pin_button = true,
		children = {
			
		}
	} --[[@as GuiElemModuleDef]]
} --[[@as GuiWindowDef]],
{}
)