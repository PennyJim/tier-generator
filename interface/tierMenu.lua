local calculator = require("__tier-generator__.calculation.calculator")
local table_size = {
	width = 5,
	item_height = 2,
	fluid_height = 1
}

local menu = {}

---Initializes the menu for new players
---@param player LuaPlayer
function menu.add_player(player)
	return nil
	-- if not global.menu then return menu.init() end
	-- if not global.config then return end
	-- global.player[player.index].menu = create_frame(player)
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

return menu