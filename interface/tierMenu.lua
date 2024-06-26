local calculator = require("__tier-generator__.calculation.calculator")
local table_size = {
	width = 5,
	item_height = 2,
	fluid_height = 1
}

local menu = {}
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