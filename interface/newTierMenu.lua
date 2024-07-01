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
			{ -- Options
				type = "frame", style = "inside_shallow_frame",
				direction = "vertical",
				children = {
					{ -- Requested items
						type = "module", module_type = "tiergen_selection_area",
						caption = {"tiergen.item-selection"},
						confirm_name = "calculate", confirm_locale = {"tiergen.calculate"},
---@diagnostic disable-next-line: missing-fields
						style_mods = {top_margin = 8},
						children = {
							-- TODO: stuff
						}
					} --[[@as SelectionAreaParams]],
					{ -- Base items
						type = "module", module_type = "tiergen_selection_area",
						caption = {"tiergen.base-selection"},
						confirm_name = "define-base", confirm_locale = {"tiergen.define-base"},
						children = {
							-- TODO: stuff
						}
					},
					{ -- Ignored recipes
						type = "module", module_type = "tiergen_selection_area",
						caption = {"tiergen.ignored-selection"},
						confirm_name = "define-ignored", confirm_locale = {"tiergen.define-ignored"},
---@diagnostic disable-next-line: missing-fields
						style_mods = {bottom_margin = 8},
						children = {
							-- TODO: stuff
						}
					}
				}
			},
			{ -- Tier Graph
				type = "frame", style = "inside_shallow_frame",
				-- TODO: menu
			}
		}
	} --[[@as WindowFrameButtonsDef]]
} --[[@as GuiWindowDef]],
{}
)


-- {
-- 	type = "module", module_type = "elem_selector_table",
-- 	frame_style = "tiergen_elem_selector_table_frame",
-- 	name = "test",
-- 	height = 2, width = 5,
-- 	elem_type = "item"
-- }