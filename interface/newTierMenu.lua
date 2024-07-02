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

local function make_new_tier_row(table, tier, items, namespace)
	gui.add(namespace, table, {
		type = "label",
		caption = {"tiergen.tier-label", tier-1},
---@diagnostic disable-next-line: missing-fields
		style_mods = {right_padding = 4},
	}, true)

	---@type GuiElemModuleDef[]
	local item_elements = {}
	for i, item in ipairs(items) do
		local itemPrototype = lib.getItemOrFluid(item.name, item.type)
		local sprite = item.type.."/"..item.name
		item_elements[i] = {
			type = "sprite-button", style = "slot_button",
			name = sprite, sprite = sprite,
			tooltip = itemPrototype.localised_name
		}
	end

	gui.add(namespace, table, {
		type = "frame",
		name = "tier-"..tier.."-items",
		style = "slot_button_deep_frame",
---@diagnostic disable-next-line: missing-fields
		style_mods = {horizontally_stretchable = true},
		children ={{
			type = "table", style = "filter_slot_table",
			name = "tierlist-items-"..tier, column_count = 12,
---@diagnostic disable-next-line: missing-fields
			style_mods = {minimal_width = 40*12},
			children = item_elements
		}}
	}, true)
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
					} --[[@as SelectionAreaParams]],
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
					} --[[@as SelectionAreaParams]],
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
---@diagnostic disable-next-line: missing-fields
							style_mods = {left_padding = 8},
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
local calculator = require("__tier-generator__.calculation.calculator")
local function test()
	local elems = global["tiergen-menu"]--[[@as WindowState[] ]][1].elems
	local error = elems["error-message"]
	local table = elems["tier-table"]
	local items_by_tier = calculator.getArray{lib.item("space-science-pack")}
	for tier, items in pairs(items_by_tier) do
		make_new_tier_row(table, tier, items, "tiergen-menu")
	end
	error.visible = false
	table.visible = true
end
lib.register_func("testing", test)


---@type event_handler
return {
	on_init = function ()
		lib.seconds_later(2, "testing")
	end
}