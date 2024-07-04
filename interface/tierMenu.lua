local gui = require("__gui-modules__.gui")
local calculator = require("__tier-generator__.calculation.calculator")
local table_size = {
	width = 5,
	item_height = 2,
	fluid_height = 1
}

---@class tierMenu : event_handler
local tierMenu = {events={}--[[@as event_handler.events]]}

---@class WindowState.TierMenu.tab
---@field has_changed boolean Whether the chosen elements have changed since last calculated
---@field has_changed_from_default boolean Whether the chosen elements have been changed from the default
---@field result {[integer]:tierResult[]}? the results of this tab's last calculation
---@field calculated simpleItem[] the list of items last calculated

---@class WindowState.TierMenu : WindowState.ElemSelectorTable
---@field highlight simpleItem? The item clicked to highlight everything
---@field highlighted LuaGuiElement[]? List of elements currently highlighted
---@field selected_tab integer the tab that is currently selected
---@field calculated_tab integer the tab that was last calculated
---@field [1] WindowState.TierMenu.tab
---@field [2] WindowState.TierMenu.tab
---@field [3] WindowState.TierMenu.tab
---@field base_changed boolean
---@field base_state simpleItem[]
---@field ignored_changed boolean
---@field ignored_state simpleItem[]


--#region Local Functions

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
local function make_new_tier_row(table, tier, tierdigits, items, namespace)
	gui.add(namespace, table, {
		type = "label", style = "tiergen_tierlabel_"..tierdigits,
		caption = {"tiergen.tier-label", tier-1},
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

	local tier_digits = #tierArray
	if tier_digits == 0 then
		error.visible = true
		table.parent.visible = false
		return
	else
		error.visible = false
		table.parent.visible = true
	end

	tier_digits = #tostring(tier_digits)
	local background = table.parent.children[2]
	background.style = "tiergen_tierlist_"..tier_digits.."_background"

	local namespace = self.namespace
	for tier, items in pairs(tierArray) do
		make_new_tier_row(table, tier, tier_digits, items, namespace)
	end
end

---Shorthand for making the base tab struct
---@return WindowState.TierMenu.tab
local function base_tab()
	return {
		has_changed = true,
		calculated = {},
		has_changed_from_default = false
	}	--[[@as WindowState.TierMenu.tab]]
end

---Highlights the items in the player's global highlight array
---@param self WindowState.TierMenu
local function highlightItems(self)
	local highlightedList = self.highlighted or {}
	self.highlighted = highlightedList
	local highlightItem = self.highlight
	if not highlightItem then return end

	local table = self.elems["tier-table"]
	if table and table.valid and not table.parent.visible then
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

--- Invalidates the tiers
local function invalidateTiers()
	if global.reprocess then
		global.reprocess = nil
		calculator.unprocess()
	else
		calculator.uncalculate()
	end

	---@type WindowState.TierMenu[]
	local namespace = global["tiergen-menu"]
	for _, state in pairs(namespace) do
		if _ == 0 then goto continue end
		state.calculated_tab = 0
		state[1] = base_tab()
		state[2] = base_tab()
		state[3] = base_tab()

		state.highlight = nil
		state.highlighted = nil

		update_tier_table(state, {})
    ::continue::
	end
end
lib.register_func("invalidate_tiers", invalidateTiers)
--#endregion

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
---@diagnostic disable-next-line: missing-fields
					style_mods = {height = 16*44 },
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
							},{
---@diagnostic disable-next-line: missing-fields
								type = "empty-widget", style_mods = {height = 0, width = 5}
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
								{
---@diagnostic disable-next-line: missing-fields
									type = "empty-widget", style_mods = {height = 0, width = 5}
								}
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
---@diagnostic disable-next-line: missing-fields
					style_mods = {height = 16*44 },
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
---@diagnostic disable-next-line: missing-fields
							elem_mods = {visible = false},
							-- style_mods = {left_padding = 8},
							children = {{
								type = "table", direction = "vertical",
								name = "tier-table", column_count = 2,
								draw_horizontal_lines = true,
	---@diagnostic disable-next-line: missing-fields
								style_mods = {left_padding = 8},
							},{
								type = "frame", style = "tiergen_tierlist_background",
							}}
						}
					}
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
				tab.has_changed_from_default = true
				self.elems["calculate"].enabled = true
			end
		end,

		["calculate"] = function (self, elem, event)
			elem.enabled = false
			local selected_index = self.selected_tab
			local calculated_index = self.calculated_tab
			self.calculated_tab = selected_index
			local tab = self[selected_index]

			if not tab.has_changed then
				update_tier_table(self, tab.result)
				return
			end

			---@type simpleItem[]
			local new_calculated = {}
			for _, type in pairs{"item","fluid"} do
				local table = self.selector_table[selected_index.."_"..type.."_selection"] or {}
				for _, value in ipairs(table) do
					---@cast value string
					new_calculated[#new_calculated+1] = lib.item(value, type)
				end
			end
			tab.has_changed = false

			local calculated_tab = self[calculated_index]
			if calculated_tab then
				local old_calculated = calculated_tab.calculated
				if #old_calculated == #new_calculated then
					local isDifferent = false
					local index = 1
					while not isDifferent and index <= #new_calculated do
						isDifferent = new_calculated[index] ~= old_calculated[index]
						index = index + 1
					end
					if not isDifferent then
						tab.calculated = new_calculated
						tab.result = calculated_tab.result
						return -- Tier table is already set
					end
				end
			end
			tab.calculated = new_calculated

			if #new_calculated == 0 then
				tab.result = {}
				update_tier_table(self, {})
				return
			end

			local results = calculator.getArray(new_calculated)
			tab.result = results
			update_tier_table(self, results)
		end,
		["define-base"] = function (self, elem, event)
			lib.log("BASED") -- TODO: implement base setting
		end,
		["define-ignored"] = function (self, elem, event)
			lib.log("IGNORED") -- TODO: implement ignored setting
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

		local config = global.config
		if config then
			local player_index = state.player.index
			tierMenu.set_items(player_index, {
				config.all_sciences,
				{config.ultimate_science},
				{}
			})
			tierMenu.set_base(player_index, config.base_items)
			tierMenu.set_ignored(player_index, config.ignored_recipes)
		end
	end
} --[[@as newWindowParams]]

--#region Direct Handlers

tierMenu.events[defines.events.on_gui_click] = function(EventData)
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
tierMenu.events[defines.events.on_runtime_mod_setting_changed] = function (EventData)
	local setting = EventData.setting

	if setting == "tiergen-consider-autoplace-setting" then
		global.reprocess = true
	end

	if lib.isOurSetting(setting)
	and setting ~= "tiergen-debug-log" then
		lib.tick_later("invalidate_tiers")
	end
end

function tierMenu.on_init()
	lib.tick_later("invalidate_tiers") -- Is this actually necessary?
end

function tierMenu.on_configuration_changed()
	lib.tick_later("invalidate_tiers")
end
--#endregion
--#region Public Functions

---Sets the items in the 
---@param player_index integer
---@param tabs {[1]:simpleItem[],[2]:simpleItem[],[3]:simpleItem[]}
function tierMenu.set_items(player_index, tabs)
	local state = global["tiergen-menu"][player_index] --[[@as WindowState.TierMenu]]
	local elems = state.elems
	local values = state.selector_table

	local update_rows = state.selector_update_rows.call
	if not update_rows then
		error("elem_selector_table's function didn't get restored on save/load")
	end

	for i = 1, 3, 1 do
		-- Don't change it to the default if they've altered it
		if state[i].has_changed_from_default then goto continue end

		local items = i.."_item_selection"
		local item_table = elems[items]
		local item_values = values[items] or {count=0}
		values[items] = item_values

		local fluids = i.."_fluid_selection"
		local fluid_table = elems[fluids]
		local fluid_values = values[fluids] or {count=0}
		values[fluids] = fluid_values

		for index, item in pairs(tabs[i]) do
			local elem_table, elem_values
			if item.type == "item" then
				elem_table = item_table
				elem_values = item_values
			else
				elem_table = fluid_table
				elem_values = fluid_values
			end

			elem_table.children[index].elem_value = item.name
			update_rows(elem_table, elem_values.count, item.type, state)
			elem_values[index] = item.name
			elem_values.count = elem_values.count + 1
		end

		item_values.last = item_values.count
		fluid_values.last = item_values.count
    ::continue::
	end
end
---@param player_index integer
---@param base simpleItem[]
function tierMenu.set_base(player_index, base)
	local state = global["tiergen-menu"][player_index] --[[@as WindowState.TierMenu]]

	local item_table = state.elems["base_item_selection"]
	local item_values = state.selector_table["base_item_selection"] or {count=0}
	state.selector_table["base_item_selection"] = item_values

	local fluid_table = state.elems["base_fluid_selection"]
	local fluid_values = state.selector_table["base_fluid_selection"] or {count=0}
	state.selector_table["base_fluid_selection"] = fluid_values

	local update_rows = state.selector_update_rows.call
	if not update_rows then
		error("elem_selector_table's function didn't get restored on save/load")
	end

	for index, item in pairs(base) do
		local elem_table, elem_values
		if item.type == "item" then
			elem_table = item_table
			elem_values = item_values
		else
			elem_table = fluid_table
			elem_values = fluid_values
		end

		elem_table.children[index].elem_value = item.name
		update_rows(elem_table, elem_values.count, item.type, state)
		elem_values[index] = item.name
		elem_values.count = elem_values.count + 1
	end

	item_values.last = item_values.count
	fluid_values.last = item_values.count
end
---@param player_index integer
---@param ignored table<data.RecipeID,true>
function tierMenu.set_ignored(player_index, ignored)
	local state = global["tiergen-menu"][player_index] --[[@as WindowState.TierMenu]]
	local recipe_table = state.elems["ignored_recipe_selection"]
	local recipe_values = state.selector_table["ignored_recipe_selection"] or {count=0}
	state.selector_table["ignored_recipe_selection"] = recipe_values

	local update_rows = state.selector_update_rows.call
	if not update_rows then
		error("elem_selector_table's function didn't get restored on save/load")
	end

	local index = 0
	for recipe in pairs(ignored) do
		index = index + 1
		recipe_table.children[index].elem_value = recipe
		update_rows(recipe_table, index, "recipe", state)
		recipe_values[index] = recipe
	end

	recipe_values.last = index
	recipe_values.count = index
end
--#endregion

---@type event_handler
return tierMenu