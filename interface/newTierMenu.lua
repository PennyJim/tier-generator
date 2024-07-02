local gui = require("__gui-modules__.gui")
local table_size = {
	width = 5,
	item_height = 2,
	fluid_height = 1
}
---Crates the tab for item selection
---@param number integer
---@return GuiElemModuleDef
local function make_item_selection_pane(number)
	return {
		tab = {
			type = "tab",
			caption = {"tiergen.tab", number},
---@diagnostic disable-next-line: missing-fields
			style_mods = {minimal_width = 40},
		} --[[@as GuiElemModuleDef]],
		content = {
			type = "flow", direction = "vertical",
---@diagnostic disable-next-line: missing-fields
			style_mods = {minimal_width = table_size.width*40 +24},
			children = {
				{
					type = "label",
					caption = {"tiergen.items"}
				},
				{
					type = "module", module_type = "elem_selector_table",
					frame_style = "tiergen_elem_selector_table_frame",
					name = number.."_item_selection",
					height = table_size.item_height, width = table_size.width,
					elem_type = "item"
				} --[[@as ElemSelectorTableParams]],
				{
					type = "label",
					caption = {"tiergen.fluids"}
				},
				{
					type = "module", module_type = "elem_selector_table",
					frame_style = "tiergen_elem_selector_table_frame",
					name = number.."_fluid_selection",
					height = table_size.fluid_height, width = table_size.width,
					elem_type = "fluid"
				} --[[@as ElemSelectorTableParams]],
			}
		} --[[@as GuiElemModuleDef]],
	}
end

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
						children = {{
							type = "tabbed-pane", style = "tiergen_tabbed_pane",
---@diagnostic disable-next-line: missing-fields
							elem_mods = {selected_tab_index = 1},
							children = {
								make_item_selection_pane(1),
								make_item_selection_pane(2),
								make_item_selection_pane(3),
							}
						}}
					} --[[@as SelectionAreaParams]],
					{ -- Base items
						type = "module", module_type = "tiergen_selection_area",
						caption = {"tiergen.base-selection"},
						confirm_name = "define-base", confirm_locale = {"tiergen.define-base"},
						children = {
							{
								type = "label",
								caption = {"tiergen.items"}
							},
							{
								type = "module", module_type = "elem_selector_table",
								frame_style = "tiergen_elem_selector_table_frame",
								name = "base_item_selection",
								height = table_size.item_height, width = table_size.width,
								elem_type = "item"
							} --[[@as ElemSelectorTableParams]],
							{
								type = "label",
								caption = {"tiergen.fluids"}
							},
							{
								type = "module", module_type = "elem_selector_table",
								frame_style = "tiergen_elem_selector_table_frame",
								name = "base_fluid_selection",
								height = table_size.fluid_height, width = table_size.width,
								elem_type = "fluid"
							} --[[@as ElemSelectorTableParams]],
						}
					},
					{ -- Ignored recipes
						type = "module", module_type = "tiergen_selection_area",
						caption = {"tiergen.ignored-selection"},
						confirm_name = "define-ignored", confirm_locale = {"tiergen.define-ignored"},
---@diagnostic disable-next-line: missing-fields
						style_mods = {bottom_margin = 4},
						children = {
							{
								type = "module", module_type = "elem_selector_table",
								frame_style = "tiergen_elem_selector_table_frame",
								name = "ignored_recipe_selection",
								height = table_size.fluid_height, width = table_size.width,
								elem_type = "recipe"
							} --[[@as ElemSelectorTableParams]],
						}
					}
				}
			},
			{ -- Tier pane
				type = "frame", style = "inside_shallow_frame",
				children = {
					{ -- Error message
						type = "flow", name = "error-message",
						direction = "vertical",
						children = {
							{type = "empty-widget", style = "flib_vertical_pusher"},
							{
								type = "label",
								caption = {"tiergen.no-tiers"},
---@diagnostic disable-next-line: missing-fields
								style_mods = {padding = 40},
							},
							{type = "empty-widget", style = "flib_vertical_pusher"},
						}
					},
					{ -- Tier graph
						type = "scroll-pane", style = "naked_scroll_pane",
						-- style_mods = {left_padding = 8},
						children = {{
							type = "table", direction = "vertical",
							name = "tier-table", column_count = 2,
							draw_horizontal_lines = true,
							-- style_mods = {left_padding = 8},
---@diagnostic disable-next-line: missing-fields
							elem_mods = {visible = false}
						}}
					}
				}
				-- TODO: menu
			}
		}
	} --[[@as WindowFrameButtonsDef]]
} --[[@as GuiWindowDef]],
{}
)