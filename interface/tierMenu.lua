local calculator = require("__tier-generator__.calculation.calculator")
local table_size = {
	width = 5,
	item_height = 2,
	fluid_height = 1
}

---Adds a title_bar to the given frame, and returns the
---horizontal flow for elements to be put into
---@param frame LuaGuiElement
---@param caption LocalisedString
local function create_titlebar(frame, caption)
	local base_flow = frame.add{
		type = "flow",
		name = "base",
		direction = "vertical",
	}
	local title_flow = base_flow.add{
		type = "flow",
		direction = "horizontal"
	}
	title_flow.drag_target = frame
	title_flow.style.horizontal_spacing = 8
	title_flow.add{
		type = "label",
		style = "frame_title",
		caption = caption,
		ignored_by_interaction = true
	}
	local drag = title_flow.add{
		type = "empty-widget",
		style = "draggable_space_header",
		ignored_by_interaction = true
	}
	drag.style.height = 24
	drag.style.right_margin = 4
	drag.style.horizontally_stretchable = true
	title_flow.add{
		type = "sprite-button",
		name = "close_button",
		style = "close_button",
		sprite = "utility/close_white",
		hovered_sprite = "utility/close_black",
		clicked_sprite = "utility/close_black",
	}
	return base_flow.add{
		type = "flow",
		name = "flow",
		direction = "horizontal",
		style = "inset_frame_container_horizontal_flow"
	}
end

---Adds a row of empty buttons to a selector table
---Just like the logistic requests table
---@param table LuaGuiElement
---@param type ElemType
local function add_elem_selector_row(table, type)
	local width = table.column_count
	for i = 1, width, 1 do
		table.add{
			type = "choose-elem-button",
			elem_type = type,
			-- style = "slot_button",
		}
	end
end
---Creates a scrollable table of a given width and height
---@param base LuaGuiElement
---@param type ElemType
---@param width integer
---@param height integer
---@return LuaGuiElement
local function make_elem_selector_table(base, type, width, height)
	local scroll_frame = base.add{
		type = "frame",
		style = "deep_frame_in_shallow_frame"
	}
	local scroll = scroll_frame.add{
		type = "scroll-pane",
		style = "naked_scroll_pane"
	}
	local frame = scroll.add{
		type = "frame",
		style = "slot_button_deep_frame"
	}
	local table = frame.add{
		type = "table",
		name = "tiergen-item-selection-table",
		style = "filter_slot_table",
		column_count = width
	}
	table.style.width = 40*width
	table.style.minimal_height = 40*height
	scroll.style.height = 40*height
	scroll_frame.style.left_margin = 12
	add_elem_selector_row(table, type)
	return table
end
---Creates a table with selectable elements
---@param base_flow LuaGuiElement
---@param caption LocalisedString
---@param button_name string
---@param middle_stuff fun(vert_flow:LuaGuiElement)
---@return LuaGuiElement area_frame the created frame
local function make_selection_area(base_flow, name, caption, button_name, middle_stuff)
	local base_frame = base_flow.add{
		type = "frame",
		name = name,
		style = "bordered_frame_with_extra_side_margins"
	}
	local vert_flow = base_frame.add{
		type = "flow",
		direction = "vertical"
	}
	local label = vert_flow.add{
		type = "label",
		caption = caption,
		style = "caption_label"
	}

	-- Other stuff
	middle_stuff(vert_flow)

	local confirm_flow = vert_flow.add{
		type = "flow",
		direction = "horizontal"
	}
	confirm_flow.add{
		type = "empty-widget",
	}.style.horizontally_stretchable = true
	local confirm = confirm_flow.add{
		type = "button",
		name = button_name,
		caption = {"tiergen."..button_name},
		style = "confirm_button_without_tooltip"
	}
	confirm.style.minimal_width = 0
	confirm.style.right_margin = 4
	confirm.style.top_margin = 4
	confirm.enabled = true
	global.player[confirm.player_index][button_name] = confirm
	return base_frame
end
---Creates a table for item selection
---@param vert_flow LuaGuiElement
---@param autopopulate simpleItem[]
---@return integer item_count The number of items in this table
---@return integer fluid_count the number of fluids in this table
local function create_item_selection_block(vert_flow, autopopulate, elems)
	vert_flow.add{
		type = "label",
		caption = {"tiergen.items"}
	}
	local item_table = make_elem_selector_table(vert_flow, "item", table_size.width, table_size.item_height)
	local item_index = 1
	vert_flow.add{
		type = "label",
		caption = {"tiergen.fluids"}
	}
	local fluid_table = make_elem_selector_table(vert_flow, "fluid", table_size.width, table_size.fluid_height)
	local fluid_index = 1
	for _, item in ipairs(autopopulate) do
		local table, index
		if item.type == "item" then
			table = item_table
			index = item_index
			item_index = item_index + 1
		else
			table = fluid_table
			index = fluid_index
			fluid_index = fluid_index + 1
		end

		if index >= #table.children - table.column_count then
			add_elem_selector_row(table, item.type)
		end
		elems[item.type][index] = item.name
		table.children[index].elem_value = item.name
	end
	return item_index - 1, fluid_index - 1
end
---Creates the tab for item selection
---@param tab_base LuaGuiElement
---@param tab_num integer
---@param autopopulate simpleItem[]
---@return LuaGuiElement
local function create_item_selection_tab(tab_base, tab_num, autopopulate)
	local tab = tab_base.add{
		type = "tab",
		name = "tab"..tab_num,
		caption = {"tiergen.tab", tab_num}
	}
	tab.style.minimal_width = 40
	local vert_flow = tab_base.add{
		type = "flow",
		direction = "vertical"
	}
	vert_flow.style.minimal_width = table_size.width*40 + 24
	tab_base.add_tab(tab, vert_flow)
	local player_tab = global.player[tab.player_index][tab_num]
	local items, fluids = create_item_selection_block(vert_flow, autopopulate, player_tab.elems)
	player_tab.elems.count.item = items
	player_tab.elems.last.item = items
	player_tab.elems.count.fluid = fluids
	player_tab.elems.last.fluid = fluids
	return tab
end
---Creates the pane for item selection
---@param base_flow LuaGuiElement
local function create_item_selection(base_flow)
	local area = make_selection_area(
		base_flow, "tiergen-items", {"tiergen.item-selection"}, "calculate",
		function (vert_flow)
			-- local tab_flow = vert_flow.add{
			-- 	type = "flow",
			-- 	style = "tiergen_wide_horizontal_flow",
			-- 	direction = "horizontal"
			-- }
			-- tab_flow.add{
			-- 	type = "sprite",
			-- 	sprite = "bottom_left_inside_corner"
			-- }.style.top_margin = 35
			local tabs = vert_flow.add{
				type = "tabbed-pane",
				name = "tiergen-item-selection",
				style = "tiergen_tabbed_pane"
			}
			-- tab_flow.add{
			-- 	type = "sprite",
			-- 	sprite = "bottom_right_inside_corner"
			-- }.style.top_margin = 35
			local config = global.config
			create_item_selection_tab(tabs, 1, config.all_sciences)
			create_item_selection_tab(tabs, 2, {config.ultimate_science})
			create_item_selection_tab(tabs, 3, {})
			global.player[tabs.player_index].selected_tab = 1
			tabs.selected_tab_index = 1
		end
	)
	area.style.top_margin = 8
end
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
			for index, recipeID in pairs(global.config.ignored_recipes) do
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

	area_children[2].ignored_by_interaction = true
	for _,table_elem in pairs(area_children[2].children[1].children[1].children[1].children) do
		table_elem.enabled = false
	end
	area_children[3].ignored_by_interaction = true
	area_children[3].children[2].enabled = false
end
---Creates the options interface
---@param base_flow LuaGuiElement
local function create_options(base_flow)
	local vert_flow = base_flow.add{
		type = "frame",
		style = "inside_shallow_frame"
	}.add{
		type = "flow",
		direction = "vertical"
	}
	vert_flow.style.vertically_stretchable = true
	create_item_selection(vert_flow)
	create_base_selection(vert_flow)
	create_ignored_selection(vert_flow)
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
		tier_list.style.width = 40*10

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
	if not global.menu then return end
	---@type LuaGuiElement
	local menu = player.gui.screen["tiergen-menu"]
	if not menu then
		menu = create_frame(player)
	end

	menu.visible = is_toggled
end

---Initializes the menu for new players
---@param player LuaPlayer
local function new_player(player)
	if not global.menu then return end
	global.player[player.index].menu = create_frame(player)
end
---Initializes the menu for all players
local function init()
	global.menu = true
	for _, player in pairs(game.players) do
		local oldMenu = player.gui.screen["tiergen-menu"]
		if oldMenu then
			--- Destroy remnants of last mod installation
			oldMenu.destroy()
		end
		new_player(player)
	end
end
---Goes through each player and calls `reset_frame`
local function regenerate_menus()
	if not global.menu then return end
	for index, player in pairs(game.players) do
		local player_table = global.player[index]
		if not player_table.menu and not player_table.menu.valid then
			new_player(player)
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
local function open_close(player)
	if not global.menu then return end
	local isOpened = not player.is_shortcut_toggled("tiergen-menu")
	if isOpened then
		open(player)
	else
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


script.on_event("tiergen-menu", function (EventData)
	local player = game.get_player(EventData.player_index)
	local player_table = global.player[EventData.player_index]
	if not player then
		return log("No player pressed that keybind??")
	end

	if not player_table.menu or not player_table.menu.valid then
		new_player(player)
		lib.log("Generating new menu for "..player.name.." as their reference was invalid")
	end

	open_close(player)
end)
script.on_event(defines.events.on_gui_closed, function (EventData)
	if EventData.element and EventData.element.name == "tiergen-menu" then
		local player = game.get_player(EventData.player_index)
		local player_table = global.player[EventData.player_index]
		if not player then
			return log("Who's menu just closed!?")
		end

		if not player_table.menu or not player_table.menu.valid then
			new_player(player)
			return lib.log("Generating new menu for "..player.name.." as their reference was invalid")
		end

		close(player)
	end
end)
script.on_event(defines.events.on_gui_click, function (EventData)
	local player = game.get_player(EventData.player_index)
	local player_table = global.player[EventData.player_index]
	if not player then
		return log("wtf")
	end

	if not player_table.menu or not player_table.menu.valid then
		new_player(player)
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
script.on_event(defines.events.on_gui_elem_changed, function (EventData)
	if EventData.element.parent.name ~= "tiergen-item-selection-table" then
		return
	end

	local player_table = global.player[EventData.player_index]
	if not player_table.menu or not player_table.menu.valid then
		local player = game.get_player(EventData.player_index)
		if not player then return end
		new_player(player)
		return lib.log("Generating new menu for "..player.name.." as their reference was invalid")
	end

	local player_tab = player_table[player_table.selected_tab]
	local elem = EventData.element
	local index = elem.get_index_in_parent()
	local type = elem.elem_type --[[@as "item"|"fluid"]]
	local items = player_tab.elems
	local new_value, old_value = elem.elem_value, items[type][index]

	if new_value == old_value then return end

	if new_value == nil
	and old_value ~= nil then
		items.count[type] = items.count[type] - 1
	elseif new_value ~= nil
	and old_value == nil then
		items.count[type] = items.count[type] + 1
	end

	local elem_table = elem.parent --[[@as LuaGuiElement]]
	if index > items.last[type] then
		-- Don't have to worry about setting nil as the last value
		-- Because then old_value (a later index) would have had to be a value
		items.last[type] = index
		-- Add a row if needed
		if index >= #elem_table.children - elem_table.column_count then
			add_elem_selector_row(elem_table, type)
		end
	elseif index == items.last[type] then
		-- Decrement the last_index to the last item with a value
		for new_last = index, 0, -1 do
			if items[new_last] or new_last == 0 then
				items.last[type] = new_last
			end
		end
		-- Remove as many rows as needed
		local last_index = items.last[type]
		local columns = elem_table.column_count
		local desired_rows = math.ceil(last_index/columns)+1
		for remove_index = #elem_table.children, desired_rows*columns+1, -1 do
			elem_table.children[remove_index].destroy()
		end
	end

	items.has_changed = true
	player_tab.calculated = nil
	items[type][index] = elem.elem_value --[[@as string]]
	player_table.calculate.enabled = true
end)
script.on_event(defines.events.on_gui_selected_tab_changed, function (EventData)
	if EventData.element.name ~= "tiergen-item-selection" then
		return
	end

	local player_table = global.player[EventData.player_index]
	if not player_table.menu or not player_table.menu.valid then
		local player = game.get_player(EventData.player_index)
		if not player then return end
		new_player(player)
		return lib.log("Generating new menu for "..player.name.." as their reference was invalid")
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

return {
	init = init,
	add_player = new_player,
	regenerate_menus = regenerate_menus,
	open_close = open_close
}