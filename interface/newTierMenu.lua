local gui = require("__gui-modules__.gui")
gui.new({
	namespace = "tiergen-menu",
	root = "screen",
	version = 1,
	custominput = "tiergen-menu",
	shortcut = "tiergen-menu",
	definition = {
		type = "module", module_type = "window_frame",
		name = "tiergen-menu", title = {"tiergen.menu"},
		has_close_button = true, has_pin_button = true,
		children = {
			{
				type = "module", module_type = "elem_selector_table",
				frame_style = "tiergen_elem_selector_table_frame",
				name = "test",
				height = 2, width = 5,
				elem_type = "item"
			}
		}
	} --[[@as GuiElemModuleDef]]
} --[[@as GuiWindowDef]],
{}
)