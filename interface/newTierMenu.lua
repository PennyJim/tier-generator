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

---@class WindowState.TierMenu : WindowState
---@field highlight simpleItem?
---@field highlighted LuaGuiElement[]?

---Highlights the items in the player's global highlight array
---@param self WindowState.TierMenu
local function highlightItems(self)
	local highlightedList = self.highlighted or {}
	self.highlighted = highlightedList
	local highlightItem = self.highlight
	if not highlightItem then return end

	local table = self.elems["tier-table"]
	if table and table.valid and not table.visible then
		return -- No tiers error message
	end

	for item in calculator.get{highlightItem} do
		local button_name = item.type.."/"..item.name
		local button = self.elems[button_name]

		-- ---@type LuaGuiElement
		-- local item_table = table.children[(item.tier+1)*2]["tierlist-items"]
		-- local button = item_table[item.type.."/"..item.name] --[[@as LuaGuiElement]]

		if not button or not button.valid then
			-- Can't highlight an invalid element,
			-- so remove the invalid reference.
			-- If it didn't exist, this does nothing
			self.elems[button_name] = nil
		else
			button.toggled = true
			highlightedList[#highlightedList+1] = button
		end
	end
end
---Highlights the items in the player's global highlight array
---@param self WindowState.TierMenu
local function unhighlightItems(self)
	local highlightedList = self.highlighted
	if not highlightedList then return end
	for _, highlightedElem in ipairs(highlightedList) do
		---@cast highlightedElem LuaGuiElement
		if highlightedElem.valid then
			highlightedElem.toggled = false
		end
	end
	self.highlight = nil
	self.highlighted = nil
end

---@param EventData EventData.on_gui_click
local function on_gui_click(EventData)
	local element = EventData.element
	local WindowStates = global["tiergen-menu"] --[[@as WindowState[] ]]
	if not WindowStates then return end -- Don't do anything if the namespace isn't setup
	local self = WindowStates[EventData.player_index] --[[@as WindowState.TierMenu]]
	if not self then return end -- Don't do anything if the player isn't setup

	local parent = element.parent
	if not parent or not parent.name then return end

	if parent.name:match("^tierlist%-items") then
		local type_item = element.name
		local type = type_item:match("^[^/]+")
		local item = type_item:match("/.+"):sub(2)
		---@type simpleItem
		local highlightItem = {name=item,type=type}
		local oldHighlight = self.highlight
		if oldHighlight then
			if oldHighlight.name ~= item
			or oldHighlight.type ~= type then
				unhighlightItems(self)
				self.highlight = highlightItem
				highlightItems(self)
			end
		else
			self.highlight = highlightItem
			highlightItems(self)
		end
	else
		unhighlightItems(self)
	end
end

---@type event_handler
return {
	on_init = function ()
		lib.seconds_later(2, "testing")
	end,
	events = {
		[defines.events.on_gui_click] = on_gui_click
	}
}