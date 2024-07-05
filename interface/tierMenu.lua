local gui = require("__gui-modules__.gui")
local calculator = require("__tier-generator__.calculation.calculator")
local table_size = {
	width = 5,
	item_height = 2,
	fluid_height = 1
}
---@enum ElementNames
local names = {
	namespace = "tiergen-menu",
	tier_items_table = "tierlist-items",
	---@deprecated
	---USE `gen_item_selection` INSTEAD
	item_selection = "tab_item_selection",
	---@deprecated
	---USE `gen_fluid_selection` INSTEAD
	fluid_selection = "tab_fluid_selection",
	---@deprecated
	---USE `gen_sprite` INSTEAD
	sprite = "type/name",
	-- tier_items = function(tier) return "tier-"..tier.."-items" end, -- Kept just in case the table *does* need a name
	calculate = "calculate",
	base = "define_base",
	base_items = "base_item_selection",
	base_fluids = "base_fluid_selection",
	ignored = "define_ignored",
	ignored_recipes = "ignored_recipes_selection",
	error_message = "error_message",
	tier_table = "tier_table",
}
---@param tab_num integer
---@return string
local function gen_item_selection(tab_num)
	return tab_num.."_item_selection" --[[@as string]]
end
---@param tab_num integer
---@return string
local function gen_fluid_selection(tab_num)
	return tab_num.."_fluid_selection" --[[@as string]]
end
---@param type string
---@param name string
---@return string
local function gen_sprite(type,name)
	return type.."/"..name --[[@as string]]
end

---@class Global
---@field tiergen-menu WindowGlobal
---@field reprocess boolean?

---@class tierMenu : event_handler
local tierMenu = {events={}--[[@as event_handler.events]]}

---@class WindowState.TierMenu.tab
---@field has_changed boolean Whether the chosen elements have changed since last calculated
---@field has_changed_from_default boolean Whether the chosen elements have been changed from the default
---@field result {[integer]:tierResult[]}? the results of this tab's last calculation
---@field calculated simpleItem[] the list of items last calculated

---@class WindowState.TierMenu : WindowState.ElemSelectorTable
---@field elems table<ElementNames,LuaGuiElement>
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
					name = gen_item_selection(number), elem_type = "item",
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
					name = gen_fluid_selection(number), elem_type = "fluid",
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
		local sprite = gen_sprite(item.type, item.name)
		item_elements[i] = {
			type = "sprite-button", style = "slot_button",
			name = sprite, sprite = sprite,
			tooltip = itemPrototype.localised_name
		}
	end

	gui.add(namespace, table, {
		type = "frame",
		style = "slot_button_deep_frame",
---@diagnostic disable-next-line: missing-fields
		style_mods = {horizontally_stretchable = true},
		children ={{
			type = "table", style = "filter_slot_table",
			name = names.tier_items_table, column_count = 12,
---@diagnostic disable-next-line: missing-fields
			style_mods = {minimal_width = 40*12},
			children = item_elements
		}}
	}, true)
end
---Generates the tier table for the given array
---@param state WindowState.TierMenu
---@param tierArray table<integer, simpleItem[]>
local function update_tier_table(state, tierArray)
	local elems = state.elems
	local error = elems[names.error_message]
	local table = elems[names.tier_table]
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

	local namespace = state.namespace
	for tier, items in pairs(tierArray) do
		make_new_tier_row(table, tier, tier_digits, items, namespace)
	end
end

---Shorthand for making the base tab struct
---@param is_default boolean
---@return WindowState.TierMenu.tab
local function base_tab(is_default)
	return {
		has_changed = true,
		calculated = {},
		has_changed_from_default = not is_default
	}	--[[@as WindowState.TierMenu.tab]]
end

---Highlights the items in the player's global highlight array
---@param state WindowState.TierMenu
local function highlightItems(state)
	local highlightedList = state.highlighted or {}
	state.highlighted = highlightedList
	local highlightItem = state.highlight
	if not highlightItem then return end

	local table = state.elems[names.tier_table]
	if table and table.valid and not table.parent.visible then
		return -- No tiers error message
	end

	for item in calculator.get{highlightItem} do
		local button_name = gen_sprite(item.type, item.name)
		local button = state.elems[button_name]

		-- ---@type LuaGuiElement
		-- local item_table = table.children[(item.tier+1)*2]["tierlist-items"]
		-- local button = item_table[item.type.."/"..item.name] --[[@as LuaGuiElement]]

		if not button or not button.valid then
			-- Can't highlight an invalid element,
			-- so remove the invalid reference.
			-- If it didn't exist, this does nothing
			state.elems[button_name] = nil
		else
			button.toggled = true
			highlightedList[#highlightedList+1] = button
		end
	end
end
---Highlights the items in the player's global highlight array
---@param state WindowState.TierMenu
local function unhighlightItems(state)
	local highlightedList = state.highlighted
	if not highlightedList then return end
	for _, highlightedElem in ipairs(highlightedList) do
		---@cast highlightedElem LuaGuiElement
		if highlightedElem.valid then
			highlightedElem.toggled = false
		end
	end
	state.highlight = nil
	state.highlighted = nil
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
	local namespace = global[names.namespace]
	for _, state in pairs(namespace) do
		if _ == 0 then goto continue end
		state.calculated_tab = 0
		state[1] = base_tab(not state[1].has_changed_from_default)
		state[2] = base_tab(not state[2].has_changed_from_default)
		state[3] = base_tab(not state[3].has_changed_from_default)

		state.highlight = nil
		state.highlighted = nil

		state.elems[names.calculate].enabled = true

		update_tier_table(state, {})
    ::continue::
	end
end
lib.register_func("invalidate_tiers", invalidateTiers)
--#endregion

gui.new{
	window_def = {
		namespace = names.namespace,
		root = "screen",
		version = 1,
		custominput = names.namespace,
		shortcut = names.namespace,
		definition = {
			type = "module", module_type = "window_frame",
			name = names.namespace, title = {"tiergen.menu"},
			has_close_button = true, has_pin_button = true,
			children = {
				{ -- Options
					type = "frame", style = "inside_shallow_frame",
					direction = "vertical",
---@diagnostic disable-next-line: missing-fields
					children = {
						{ -- Requested items
							type = "module", module_type = "tiergen_selection_area",
							caption = {"tiergen.item-selection"},
							confirm_name = names.calculate, confirm_locale = {"tiergen.calculate"},
							confirm_handler = names.calculate,
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
							confirm_name = names.base, confirm_locale = {"tiergen.define-base"},
							confirm_handler = names.base, confirm_enabled_default = false,
							children = {
								{
									type = "label",
									caption = {"tiergen.items"}
								},
								{
									type = "module", module_type = "elem_selector_table",
									frame_style = "tiergen_elem_selector_table_frame",
									name = names.base_items, elem_type = "item",
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
									name = names.base_fluids, elem_type = "fluid",
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
							confirm_name = names.ignored, confirm_locale = {"tiergen.define-ignored"},
							confirm_handler = names.ignored, confirm_enabled_default = false,
	---@diagnostic disable-next-line: missing-fields
							style_mods = {bottom_margin = 4},
							children = {
								{
									type = "module", module_type = "elem_selector_table",
									frame_style = "tiergen_elem_selector_table_frame",
									name = names.ignored_recipes, elem_type = "recipe",
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
							type = "flow", name = names.error_message,
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
								name = names.tier_table, column_count = 2,
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
		["tab-changed"] = function (state, elem)
			local selected_tab = elem.selected_tab_index --[[@as integer]]
			state.selected_tab = selected_tab
			local calculate = state.elems[names.calculate]

			if state.selected_tab ~= state.calculated_tab then
				calculate.enabled = true
			else
				calculate.enabled = state[selected_tab].has_changed
			end
		end,
		["elems-changed"] = function (state, elem)
			local name = elem.name
			if name:match("base") then
				-- Base items
				state.base_changed = true
				state.elems[names.base].enabled = true

			elseif name:match("ignored") then
				-- Ignored items
				state.ignored_changed = true
				state.elems[names.ignored].enabled = true

			else
				-- Tab
				local tab = state[state.selected_tab]
				tab.has_changed = true
				tab.has_changed_from_default = true
				state.elems[names.calculate].enabled = true
			end
		end,

		[names.calculate] = function (state, elem)
			elem.enabled = false
			local selected_index = state.selected_tab
			local calculated_index = state.calculated_tab
			state.calculated_tab = selected_index
			local tab = state[selected_index]

			if not tab.has_changed then
				update_tier_table(state, tab.result)
				return
			end

			---@type simpleItem[]
			local new_calculated = {}
			for _, type in pairs{"item","fluid"} do
				local table = state.selector_table[selected_index.."_"..type.."_selection"] or {}
				for index, value in pairs(table) do
					if lib.type(index) == "number" then 
						---@cast value string
						new_calculated[#new_calculated+1] = lib.item(value, type)
					end
				end
			end
			tab.has_changed = false

			local calculated_tab = state[calculated_index]
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
				update_tier_table(state, {})
				return
			end

			local results = calculator.getArray(new_calculated)
			tab.result = results
			update_tier_table(state, results)
		end,
		[names.base] = function (state, elem)
			elem.enabled = false

			---@type (simpleItem|tierResult)[]
			local new_base,old_base = {},global.config.base_items
			local index, is_different = 0, false
			for _, type in pairs{"item","fluid"} do
				local table = state.selector_table["base_"..type.."_selection"] or {}
				for item_index, value in pairs(table) do
					if lib.type(item_index) ~= "number" then goto continue end
					---@cast value string
					index = index + 1
					local new_item = lib.item(value, type, item_index)
					new_base[index] = new_item
					if not is_different and new_item ~= old_base[index] then
						is_different = true
					end
			    ::continue::
				end
			end

			--Mark as different if the old one had more
			if not is_different then
				is_different = #old_base ~= index
			end

			if not is_different then
				return -- Don't do anything if it wasn't changed
			end

			invalidateTiers()
			tierMenu.update_base(new_base)
			global.config.base_items = new_base
		end,
		[names.ignored] = function (state, elem)
			elem.enabled = false

			---@type table<string,integer>
			local new_ignored,old_ignored = {},global.config.ignored_recipes
			local new_count,old_count = 0,0
			local is_different = false
			local table = state.selector_table["ignored_recipe_selection"] or {}
			for index, recipe in pairs(table) do
				if lib.type(index) ~= "number" then goto continue end
				---@cast recipe string
				new_count = new_count + 1
				new_ignored[recipe] = index
				if not is_different and not old_ignored[recipe] then
					is_different = true
				end
			  ::continue::
			end

			--Count the old table because you can't do # on table<string,true>
			for _ in pairs(old_ignored) do
				old_count = old_count + 1
			end

			--Mark as different if the old one had a different amount
			if not is_different then
				is_different = old_count ~= new_count
			end

			if not is_different then
				return -- Don't do anything if it wasn't changed
			end

			global.reprocess = true
			invalidateTiers()
			tierMenu.update_ignored(new_ignored)
			global.config.ignored_recipes = new_ignored
		end
	} --[[@as table<any, fun(state:WindowState.TierMenu,elem:LuaGuiElement,event:GuiEventData)>]],
	state_setup = function (state)
		---@cast state WindowState.TierMenu
		state.selected_tab = state.selected_tab or 1
		state.calculated_tab = state.calculated_tab or 0

		state[1] = state[1] or base_tab(true)
		state[2] = state[2] or base_tab(true)
		state[3] = state[3] or base_tab(true)

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
			tierMenu.update_base(config.base_items)
			tierMenu.update_ignored(config.ignored_recipes)
		end
	end
} --[[@as newWindowParams]]

--#region Direct Handlers

tierMenu.events[defines.events.on_gui_click] = function(EventData)
	local element = EventData.element
	local WindowStates = global[names.namespace] --[[@as WindowState[] ]]
	if not WindowStates then return end -- Don't do anything if the namespace isn't setup
	local state = WindowStates[EventData.player_index] --[[@as WindowState.TierMenu]]
	if not state then return end -- Don't do anything if the player isn't setup

	local parent = element.parent
	if not parent or not parent.name then return end

	if parent.name:match("^tierlist%-items") then
		local type_item = element.name
		local type = type_item:match("^[^/]+")
		local item = type_item:match("/.+")--[[@as string]]:sub(2)
		---@type simpleItem
		local highlightItem = {name=item,type=type}
		local oldHighlight = state.highlight
		if oldHighlight then
			if oldHighlight.name ~= item
			or oldHighlight.type ~= type then
				unhighlightItems(state)
				state.highlight = highlightItem
				highlightItems(state)
			end
		else
			state.highlight = highlightItem
			highlightItems(state)
		end
	else
		unhighlightItems(state)
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

---@param player_index integer
---@param tabs {[1]:simpleItem[],[2]:simpleItem[],[3]:simpleItem[]}
function tierMenu.set_items(player_index, tabs)
	local state = global[names.namespace][player_index] --[[@as WindowState.TierMenu]]
	local elems = state.elems
	local values = state.selector_table

	local update_rows = state.selector_update_rows.call
	if not update_rows then
		error("elem_selector_table's function didn't get restored on save/load")
	end

	for i = 1, 3, 1 do
		-- Don't change it to the default if they've altered it
		if state[i].has_changed_from_default then goto continue end

		local items = gen_item_selection(i)
		local item_table = elems[items]
		---@type ElemList
		local item_values = {count=0,last=0}
		values[items] = item_values

		local fluids = gen_fluid_selection(i)
		local fluid_table = elems[fluids]
		---@type ElemList
		local fluid_values = {count=0,last=0}
		values[fluids] = fluid_values

		---@type table<integer,true>, table<integer,true>
		local visited_items,visited_fluids = {},{}
		for _, item in pairs(tabs[i]) do
			---@type LuaGuiElement, ElemList, table<integer,true>
			local elem_table, elem_values, visited
			if item.type == "item" then
				elem_table = item_table
				elem_values = item_values
				visited = visited_items
			else
				elem_table = fluid_table
				elem_values = fluid_values
				visited = visited_fluids
			end

			local index = item.count or elem_values.last + 1
			visited[index] = true

			elem_values.last = math.max(index, elem_values.last)
			update_rows(elem_table, elem_values.last, item.type, state)

			elem_table.children[index].elem_value = item.name
			elem_values[index] = item.name
			elem_values.count = elem_values.count + 1
		end

		-- Clear unvisited elems
		for index, elem in pairs(item_table.children) do
			if not visited_items[index] then
				elem.elem_value = nil
			end
		end
		update_rows(item_table, item_values.last, "item", state)
		for index, elem in pairs(fluid_table.children) do
			if not visited_fluids[index] then
				elem.elem_value = nil
			end
		end
		update_rows(fluid_table, fluid_values.last, "fluid", state)
    ::continue::
	end
end
---@param base simpleItem[]
function tierMenu.update_base(base)
	for player_index in pairs(game.players) do
		local state = global[names.namespace][player_index] --[[@as WindowState.TierMenu]]

		local item_table = state.elems[names.base_items]
		---@type ElemList
		local item_values = {count=0,last=0}
		state.selector_table[names.base_items] = item_values

		local fluid_table = state.elems[names.base_fluids]
		---@type ElemList
		local fluid_values = {count=0,last=0}
		state.selector_table[names.base_fluids] = fluid_values

		local update_rows = state.selector_update_rows.call
		if not update_rows then
			error("elem_selector_table's function didn't get restored on save/load")
		end

		---@type table<integer,true>,table<integer,true>
		local visited_items,visited_fluids = {},{}
		for _, item in pairs(base) do
			---@type LuaGuiElement, ElemList, table<integer,true>
			local elem_table, elem_values, visited
			if item.type == "item" then
				elem_table = item_table
				elem_values = item_values
				visited = visited_items
			else
				elem_table = fluid_table
				elem_values = fluid_values
				visited = visited_fluids
			end

			local index = item.count or elem_values.last + 1
			visited[index] = true

			elem_values.last = math.max(elem_values.last, index)
			update_rows(elem_table, elem_values.last, item.type, state)

			elem_table.children[index].elem_value = item.name
			elem_values[index] = item.name
			elem_values.count = elem_values.count + 1
		end

		-- Clear unvisited elems
		for index, elem in pairs(item_table.children) do
			if not visited_items[index] then
				elem.elem_value = nil
			end
		end
		update_rows(item_table, item_values.last, "item", state)
		for index, elem in pairs(fluid_table.children) do
			if not visited_fluids[index] then
				elem.elem_value = nil
			end
		end
		update_rows(fluid_table, fluid_values.last, "fluid", state)
	end
end
---@param ignored table<data.RecipeID,integer|true>
function tierMenu.update_ignored(ignored)
	for player_index in pairs(game.players) do
		local state = global[names.namespace][player_index] --[[@as WindowState.TierMenu]]
		local recipe_table = state.elems[names.ignored_recipes]
		---@type ElemList
		local recipe_values = {count=0,last=0}
		state.selector_table[names.ignored_recipes] = recipe_values

		local update_rows = state.selector_update_rows.call
		if not update_rows then
			error("elem_selector_table's function didn't get restored on save/load")
		end

		---@type table<integer,true>
		local visited = {}
		for recipe, index in pairs(ignored) do
			if type(index) == "boolean" then
				index = recipe_values.last + 1
				recipe_values.last = index
			elseif index > recipe_values.last then
				recipe_values.last = index
			end
			visited[index] = true
			update_rows(recipe_table, recipe_values.last, "recipe", state)

			recipe_table.children[index].elem_value = recipe
			recipe_values[index] = recipe
			recipe_values.count = recipe_values.count + 1
		end

		--- Clear unvisited elems
		for index, elem in pairs(recipe_table.children) do
			if not visited[index] then
				elem.elem_value = nil
			end
		end
		update_rows(recipe_table, recipe_values.last, "recipe", state)
	end
end
--#endregion

---@type event_handler
return tierMenu