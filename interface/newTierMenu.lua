local gui = require("__gui-modules__.gui")
local calculator = require("__tier-generator__.calculation.calculator")
local table_size = {
	width = 5,
	item_height = 2,
	fluid_height = 1
}


---@class WindowState.TierMenu.tab
---@field has_changed boolean Wether the chosen elements have changed
---@field result {[integer]:tierResult[]}? the results of this tab's last calculation
---@field calculated simpleItem[] the list of items last calculated

---@class WindowState.TierMenu : WindowState.ElemSelectorTable
---@field highlight simpleItem? The item clicked to highlight everything
---@field highlighted LuaGuiElement[]? List of elements currently highlighted
---@field selected_tab 1|2|3 the tab that is currently selected
---@field calculated_tab 0|1|2|3 the tab that was last calculated
---@field [1] WindowState.TierMenu.tab
---@field [2] WindowState.TierMenu.tab
---@field [3] WindowState.TierMenu.tab
---@field base_changed boolean
---@field base_state simpleItem[]
---@field ignored_changed boolean
---@field ignored_state simpleItem[]

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
					name = number.."_item_selection", elem_type = "item",
					height = table_size.item_height, width = table_size.width,
					on_elem_changed = "elems-changed",
				} --[[@as ElemSelectorTableParams]],
				{
					type = "label",
					caption = {"tiergen.fluids"}
				},
				{
					type = "module", module_type = "elem_selector_table",
					frame_style = "tiergen_elem_selector_table_frame",
					name = number.."_fluid_selection", elem_type = "fluid",
					height = table_size.fluid_height, width = table_size.width,
					on_elem_changed = "elems-changed",
				} --[[@as ElemSelectorTableParams]],
			}
		} --[[@as GuiElemModuleDef]],
	}
end
---Creates the row of a single tier
---@param table LuaGuiElement
---@param tier integer
---@param items simpleItem[]
---@param namespace namespace
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
---Generates the tier table for the given array
---@param self WindowState.TierMenu
---@param tierArray table<integer, simpleItem[]>
local function update_tier_table(self, tierArray)
	local elems = self.elems
	local error = elems["error-message"]
	local table = elems["tier-table"]
	if not error.valid or not table.valid then
		return lib.log("Table or Error are invalid references")
	end

	table.clear()

	if #tierArray == 0 then
		error.visible = true
		table.visible = false
		return
	else
		error.visible = false
		table.visible = true
	end

	local namespace = self.namespace
	for tier, items in pairs(tierArray) do
		make_new_tier_row(table, tier, items, namespace)
	end
end

local function base_tab()
	return {has_changed = true, calculated = {}}
end

gui.new{
	window_def = {
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
							confirm_handler = "calculate",
	---@diagnostic disable-next-line: missing-fields
							style_mods = {top_margin = 8},
							children = {{
								type = "tabbed-pane", style = "tiergen_tabbed_pane",
	---@diagnostic disable-next-line: missing-fields
								elem_mods = {selected_tab_index = 1},
								handler = {
									[defines.events.on_gui_selected_tab_changed] = "tab-changed"
								},
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
							confirm_handler = "define-base", confirm_enabled_default = false,
							children = {
								{
									type = "label",
									caption = {"tiergen.items"}
								},
								{
									type = "module", module_type = "elem_selector_table",
									frame_style = "tiergen_elem_selector_table_frame",
									name = "base_item_selection", elem_type = "item",
									height = table_size.item_height, width = table_size.width,
									on_elem_changed = "elems-changed",
								} --[[@as ElemSelectorTableParams]],
								{
									type = "label",
									caption = {"tiergen.fluids"}
								},
								{
									type = "module", module_type = "elem_selector_table",
									frame_style = "tiergen_elem_selector_table_frame",
									name = "base_fluid_selection", elem_type = "fluid",
									height = table_size.fluid_height, width = table_size.width,
									on_elem_changed = "elems-changed",
								} --[[@as ElemSelectorTableParams]],
							}
						} --[[@as SelectionAreaParams]],
						{ -- Ignored recipes
							type = "module", module_type = "tiergen_selection_area",
							caption = {"tiergen.ignored-selection"},
							confirm_name = "define-ignored", confirm_locale = {"tiergen.define-ignored"},
							confirm_handler = "define-ignored", confirm_enabled_default = false,
	---@diagnostic disable-next-line: missing-fields
							style_mods = {bottom_margin = 4},
							children = {
								{
									type = "module", module_type = "elem_selector_table",
									frame_style = "tiergen_elem_selector_table_frame",
									name = "ignored_recipe_selection", elem_type = "recipe",
									height = table_size.fluid_height, width = table_size.width,
									on_elem_changed = "elems-changed",
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
	handlers = {
		---@param event EventData.on_gui_selected_tab_changed
		["tab-changed"] = function (self, elem, event)
			local selected_tab = elem.selected_tab_index --[[@as integer]]
			self.selected_tab = selected_tab
			local calculate = self.elems["calculate"]

			if self.selected_tab ~= self.calculated_tab then
				calculate.enabled = true
			else
				calculate.enabled = self[selected_tab].has_changed
			end
		end,
		["elems-changed"] = function (self, elem, event)
			local name = elem.name
			if name:match("base") then
				-- Base items
				self.base_changed = true
				self.elems["define-base"].enabled = true

			elseif name:match("ignored") then
				-- Ignored items
				self.ignored_changed = true
				self.elems["define-ignored"].enabled = true

			else
				-- Tab
				local tab = self[self.selected_tab]
				tab.has_changed = true
				self.elems["calculate"].enabled = true
			end
		end,

		["calculate"] = function (self, elem, event)
			lib.log("CALCULATED")
		end,
		["define-base"] = function (self, elem, event)
			lib.log("BASED")
		end,
		["define-ignored"] = function (self, elem, event)
			lib.log("IGNORED")
		end
	} --[[@as table<any, fun(self:WindowState.TierMenu,elem:LuaGuiElement,event:GuiEventData)>]],
	state_setup = function (state)
		---@cast state WindowState.TierMenu
		state.selected_tab = state.selected_tab or 1
		state.calculated_tab = state.calculated_tab or 0

		state[1] = state[1] or base_tab()
		state[2] = state[2] or base_tab()
		state[3] = state[3] or base_tab()

		state.base_changed = false
		state.base_state = {}
		state.ignored_changed = false
		state.ignored_state = {}
	end
} --[[@as newWindowParams]]

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

--- Invalidates the tiers
local function invalidateTiers()
	calculator.uncalculate()

	---@type WindowState.TierMenu[]
	local namespace = global["tiergen-menu"]
	for _, state in pairs(namespace) do
		state.calculated_tab = 0
		state[1] = base_tab()
		state[2] = base_tab()
		state[3] = base_tab()

		state.highlight = nil
		state.highlighted = nil

		update_tier_table(state, {})
	end
end
lib.register_func("invalidate_tiers", invalidateTiers)

local function test()
	local self = global["tiergen-menu"][1] --[[@as WindowState.TierMenu]]
	local tierArray = calculator.getArray{lib.item("space-science-pack")}
	update_tier_table(self, tierArray)
end
lib.register_func("testing", test)

---@type event_handler
return {
	on_init = function ()
		lib.tick_later("invalidate_tiers") -- Is this actually necessary?
		lib.seconds_later(2, "testing")
	end,
	on_configuration_changed = function ()
		lib.tick_later("invalidate_tiers")
	end,
	events = {
		[defines.events.on_gui_click] = on_gui_click
	}
}