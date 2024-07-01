local calculator = require("__tier-generator__.calculation.calculator")
local table_size = {
	width = 5,
	item_height = 2,
	fluid_height = 1
}

local menu = {}
---Creates the pane for item selection
---@param base_flow LuaGuiElement
local function create_base_selection(base_flow)
	local area = make_selection_area(
		base_flow, "tiergen-base", {"tiergen.base-selection"}, "define-base",
		function (vert_flow)
			local base_items = global.config.base_items
			local elems = global.player[vert_flow.player_index].base_elems
			create_item_selection_block(vert_flow, base_items, elems)
		end
	)
	-- Not implemented yet
	area.enabled = false
	local area_children = area.children[1].children
	local label = area_children[1]
	label.enabled = false
	label.tooltip = {"tiergen.not-implemented"}
	label.caption = {"", label.caption, " [img=info]"}
	for index = 2, 6, 1 do
		area_children[index].enabled = false
		area_children[index].ignored_by_interaction = true
	end
	for _,table_elem in pairs(area_children[3].children[1].children[1].children[1].children) do
		table_elem.enabled = false
	end
	for _,table_elem in pairs(area_children[5].children[1].children[1].children[1].children) do
		table_elem.enabled = false
	end
	area_children[6].children[2].enabled = false
end
---Creates the pane for item selection
---@param base_flow LuaGuiElement
local function create_ignored_selection(base_flow)
	local area = make_selection_area(
		base_flow, "tiergen-ignored", {"tiergen.ignored-selection"}, "define-ignored",
		function (vert_flow)
			local table = make_elem_selector_table(vert_flow, "recipe", table_size.width, table_size.fluid_height)

			local elems = global.player[table.player_index].ignored_elems
			local count = #global.config.ignored_recipes
			elems.count.recipe = count
			elems.last.recipe = count
			local index = 0
			for recipeID in pairs(global.config.ignored_recipes) do
				index = index + 1
				if index >= #table.children - table.column_count then
					add_elem_selector_row(table, "recipe")
				end

				elems.recipe[index] = recipeID
				table.children[index].elem_value = recipeID
			end
		end
	)
	area.style.bottom_padding = 4
	-- Not implemented yet
	area.enabled = false
	local area_children = area.children[1].children
	local label = area_children[1]
	label.enabled = false
	label.tooltip = {"tiergen.not-implemented"}
	label.caption = {"", label.caption, " [img=info]"}

	-- area_children[2].ignored_by_interaction = true
	for _,table_elem in pairs(area_children[2].children[1].children[1].children[1].children) do
		table_elem.enabled = false
		table_elem.ignored_by_interaction = true
	end
	area_children[3].ignored_by_interaction = true
	area_children[3].children[2].enabled = false
end
---Updates the tier list for the player
---@param player_table PlayerGlobal
local function update_list(player_table)
	local error = player_table.error
	local table = player_table.table
	if table then
		table.clear()
	end

	local calculated_tab = player_table[player_table.calculated_tab]
	local tiers = calculated_tab and calculated_tab.result or {}

	if #tiers == 0 then
		error.visible = true
		table.visible = false
		return
	else
		error.visible = false
		table.visible = true
	end

	for tier, items in ipairs(tiers) do
		local tier_label = table.add{
			type = "label",
			name = "tier-"..tier.."-label",
			caption = {"tiergen.tier-label", tier-1}
		}
		tier_label.style.right_padding = 4
		local tier_list_frame = table.add{
			type = "frame",
			name = "tier-"..tier.."-items",
			style = "slot_button_deep_frame"
		}
		tier_list_frame.style.horizontally_stretchable = true
		local tier_list = tier_list_frame.add{
			type = "table",
			name = "tierlist-items",
			column_count = 12,
			style = "filter_slot_table"
		}
		-- Do minimal because if something messes up,
		-- I'd rather it grow than hide something
		tier_list.style.minimal_width = 40*12

		for _, item in ipairs(items) do
			local itemPrototype = lib.getItemOrFluid(item.name, item.type)
			local sprite = item.type.."/"..item.name
			tier_list.add{
				type = "sprite-button",
				name = sprite,
				sprite = sprite,
				style = "slot_button",
				tooltip = itemPrototype.localised_name
			}
		end
	end
end
---Creates the structure for the list
---@param base_flow LuaGuiElement
local function create_list(base_flow)
	local horz_flow = base_flow.add{
		type = "frame",
		name = "scroll_frame",
		style = "inside_shallow_frame"
	}.add{
		type = "flow",
		name = "error_flow",
		direction = "horizontal"
	}
	local error_flow = horz_flow.add{
		type = "flow",
		direction = "vertical"
	}
	error_flow.visible = false
	error_flow.add{
		type = "empty-widget"
	}.style.vertically_stretchable = true
	error_flow.add{
		type = "label",
		caption = {"tiergen.no-tiers"}
	}.style.padding = 40
	error_flow.add{
		type = "empty-widget"
	}.style.vertically_stretchable = true
	local scroll = horz_flow.add{
		type = "scroll-pane",
		name = "scroll",
		style = "naked_scroll_pane"
	}
	base_flow.style.height = 16*44
	scroll.style.left_padding = 8
	local table = scroll.add{
		type = "table",
		name = "table",
		column_count = 2,
		draw_horizontal_lines = true,
		direction="vertical",
	}
	table.style.left_padding = 8
	local player_table = global.player[error_flow.player_index]
	player_table.error = error_flow
	player_table.table = table
end
---Creates the menu for the player
---@param player LuaPlayer
---@return LuaGuiElement
local function create_frame(player)
	local screen = player.gui.screen
	local base = screen.add{
		type = "frame",
		name = "tiergen-menu",
		visible = false
	}
	base.auto_center = true
	local base_flow = create_titlebar(base, {"tiergen.menu"})
	create_options(base_flow)
	create_list(base_flow)
	local player_table = global.player[player.index]
	update_list(player_table)
	return base
end
---Changes the state of the tiergen menu for the player
---@param player LuaPlayer
---@param is_toggled boolean
local function set_visibility(player, is_toggled)
	if not global.menu then return menu.init() end
	if not global.config then return end
	---@type LuaGuiElement
	local player_menu = global.player[player.index].menu
	if not player_menu or not player_menu.valid then
		menu.add_player(player)
		player_menu = global.player[player.index].menu
	end

	player_menu.visible = is_toggled
end

---Initializes the menu for new players
---@param player LuaPlayer
function menu.add_player(player)
	return nil
	-- if not global.menu then return menu.init() end
	-- if not global.config then return end
	-- global.player[player.index].menu = create_frame(player)
end
---Initializes the menu for all players
function menu.init()
	global.menu = true
	local init_player = not not global.config
	for _, player in pairs(game.players) do
		local oldMenu = player.gui.screen["tiergen-menu"]
		if oldMenu then
			--- Destroy remnants of last mod installation
			oldMenu.destroy()
		end
		if init_player then
			menu.add_player(player)
		end
	end
end
---Goes through each player and calls `reset_frame`
function menu.regenerate_menus()
	if not global.menu then return menu.init() end
	if not global.config then return end
	for index, player in pairs(game.players) do
		local player_table = global.player[index]
		if not player_table.menu or not player_table.menu.valid then
			menu.add_player(player)
			goto continue
		end

		local recalc_tab = player_table.calculated_tab
		for tab = 1, 3, 1 do
			if tab ~= recalc_tab then
				player_table[tab].elems.has_changed = true
				player_table[tab].calculated = nil
				player_table[tab].result = nil
			end
		end

		player_table.highlight = nil
		player_table.highlighted = nil
		if not player_table.base_elems.has_changed then
			-- TODO: update player_table.base_elems
		end
		if not player_table.ignored_elems.has_changed then
			-- TODO: update player_table.base_items
		end

		if recalc_tab ~= 0 then
			player_table[recalc_tab].result = calculator.getArray(player_table.calculated)
		end
		update_list(player_table)
	    ::continue::
	end
end

---Calls the callback on each item's element in the given array
---@param player_table PlayerGlobal
---@param inputItem simpleItem
---@param callback fun(elem:LuaGuiElement,item:tierResult)
local function traverseArray(player_table, inputItem, callback)
	---@type LuaGuiElement
	local table = player_table.table
	if table.valid and not table.visible then
		return -- No tiers error message
	end
	for item in calculator.get{inputItem} do
		---@type LuaGuiElement
		local item_table = table.children[(item.tier+1)*2]["tierlist-items"]
		local button = item_table[item.type.."/"..item.name]
		callback(button, item)
	end
end

---Highlights the items in the player's global highlight array
---@param player_table PlayerGlobal
local function highlightItems(player_table)
	local highlightedList = player_table.highlighted or {}
	player_table.highlighted = highlightedList
	local highlightItem = player_table.highlight
	if not highlightItem then return end
	traverseArray(
		player_table,
		highlightItem,
	function (elem, item)
		elem.toggled = true
		highlightedList[#highlightedList+1] = elem
	end)
end
---Highlights the items in the player's global highlight array
---@param player_table PlayerGlobal
local function unhighlightItems(player_table)
	local highlightedList = player_table.highlighted
	if not highlightedList then return end
	for _, highlightedElem in ipairs(highlightedList) do
		---@cast highlightedElem LuaGuiElement
		if highlightedElem.valid then
			highlightedElem.toggled = false
		end
	end
	player_table.highlight = nil
	player_table.highlighted = nil
end


local function open(player)
	player.set_shortcut_toggled("tiergen-menu", true)
	set_visibility(player, true)
	player.opened = player.gui.screen["tiergen-menu"]
end
local function close(player)
	player.set_shortcut_toggled("tiergen-menu", false)
	set_visibility(player, false)
	if player.opened and player.opened.name == "tiergen-menu" then
		player.opened = nil
	end
end
---Toggles the menu open or close depending on the state of the shortcut
---@param player LuaPlayer
function menu.open_close(player)
	if not global.menu then return menu.init() end
	if not global.config then return end
	local isOpened = not player.is_shortcut_toggled("tiergen-menu")
	if isOpened then
		open(player)
	else
		-- Set the shortcut to off just in case the menu was invalidated
		player.set_shortcut_toggled("tiergen-menu", false)
		player.opened = nil
	end
end


local function handle_click_highlight(player_table, element)
	if element.parent.name == "tierlist-items" then
		local type_item = element.name
		local type = type_item:match("^[^/]+")
		local item = type_item:match("/.+"):sub(2)
		---@type simpleItem
		local highlightItem = {name=item,type=type}
		local oldHighlight = player_table.highlight
		if oldHighlight then
			if oldHighlight.name ~= item
			or oldHighlight.type ~= type then
				unhighlightItems(player_table)
				player_table.highlight = highlightItem
				highlightItems(player_table)
			end
		else
			player_table.highlight = highlightItem
			highlightItems(player_table)
		end
	else
		unhighlightItems(player_table)
	end
end

---Handles whether or not the calculate button actually updates the menu
---@param player_table PlayerGlobal
---@param element LuaGuiElement
local function handle_click_confirm(player_table, element)
	if element.name ~= "calculate" then return end
	local tab_index = player_table.selected_tab
	local player_tab = player_table[tab_index]

	if tab_index ~= player_table.calculated_tab
	and not player_table[tab_index].elems.has_changed then
		player_table.calculated_tab = tab_index
		player_table.calculated = player_tab.calculated
		player_table.calculate.enabled = false
		return update_list(player_table)
	end

	---@type simpleItem[]
	local new_calculated = {}
	for _, type in ipairs({"fluid","item"}) do
		for _, value in pairs(player_tab.elems[type]) do
			new_calculated[#new_calculated+1] = lib.item(value, type)
		end
	end

	local old_calculated = player_table.calculated
	local results
	if #new_calculated == #old_calculated then
		local isDifferent = false
		local index = 1
		while not isDifferent and index <= #new_calculated do
			isDifferent = new_calculated[index] ~= old_calculated[index]
			index = index + 1
		end
		if not isDifferent then
			if player_table.calculated_tab ~= 0 then
				results = player_table[player_table.calculated_tab].result
			else
				results = {}
			end
			goto skip_calculation
		end
	end

	results = calculator.getArray(new_calculated)
	::skip_calculation::
	player_tab.result = results
	player_table.calculated = new_calculated
	player_tab.calculated = new_calculated
	player_table.calculated_tab = tab_index
	player_tab.elems.has_changed = false
	player_table.calculate.enabled = false
	return update_list(player_table)
end
local function handle_click_define_base(player_table, element)
	
end
local function handle_click_define_ignored(player_table, element)
	
end


script.on_event(defines.events.on_gui_click, function (EventData)
	local player = game.get_player(EventData.player_index)
	local player_table = global.player[EventData.player_index]
	if not player then
		return log("wtf")
	end

	if not player_table.menu or not player_table.menu.valid then
		menu.add_player(player)
		return lib.log("Generating new menu for "..player.name.." as their reference was invalid")
	end

	local rootElement = lib.getRootElement(EventData.element)
	if rootElement.name ~= "tiergen-menu" then return	end

	if EventData.element.name == "close_button" then
		player.set_shortcut_toggled("tiergen-menu", false)
		set_visibility(player, false)
	end

	handle_click_highlight(player_table, EventData.element)
	handle_click_confirm(player_table, EventData.element)
	handle_click_define_base(player_table, EventData.element)
	handle_click_define_ignored(player_table, EventData.element)
end)
script.on_event(defines.events.on_gui_selected_tab_changed, function (EventData)
	if EventData.element.name ~= "tiergen-item-selection" then
		return
	end

	local player_table = global.player[EventData.player_index]
	if not player_table.menu or not player_table.menu.valid then
		local player = game.get_player(EventData.player_index)
		if not player then return end
		lib.log("Generating new menu for "..player.name.." as their reference was invalid")
		menu.add_player(player)
		return
	end

	local new_tab = EventData.element.selected_tab_index
	---@cast new_tab integer
	player_table.selected_tab = new_tab
	if player_table.calculated_tab ~= new_tab then
		player_table.calculate.enabled = true
		return
	end

	local player_tab = player_table[new_tab]
	player_table.calculate.enabled = player_tab.elems.has_changed
end)

return menu