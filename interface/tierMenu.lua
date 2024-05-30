local calculator = require("__tier-generator__.calculation.calculator")
local migrator = require("__tier-generator__.interface.tierMenuMigrations")

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
	local width = 5
	vert_flow.style.minimal_width = width*40 + 24
	tab_base.add_tab(tab, vert_flow)
	vert_flow.add{
		type = "label",
		caption = {"tiergen.items"}
	}
	local item_table = make_elem_selector_table(vert_flow, "item", width, 2)
	local item_index = 1
	vert_flow.add{
		type = "label",
		caption = {"tiergen.fluids"}
	}
	local fluid_table = make_elem_selector_table(vert_flow, "fluid", width, 1)
	local fluid_index = 1
	local elems = global.player[tab.player_index][tab_num].elems
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
	return tab
end
---Creates the pane for item selection
---@param base_flow LuaGuiElement
local function create_item_selection(base_flow)
	local base_frame = base_flow.add{
		type = "frame",
		name = "tiergen-items",
		style = "bordered_frame_with_extra_side_margins"
	}
	base_frame.style.top_margin = 8
	base_frame.style.bottom_padding = 4
	local vert_flow = base_frame.add{
		type = "flow",
		direction = "vertical"
	}
	local label = vert_flow.add{
		type = "label",
		caption = {"tiergen.item-selection"}
	}
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
	local playerConfig = global.config[tabs.player_index] or global.config[0]
	create_item_selection_tab(tabs, 1, playerConfig.all_sciences)
	create_item_selection_tab(tabs, 2, playerConfig.ultimate_science)
	create_item_selection_tab(tabs, 3, playerConfig.custom)
	global.player[tabs.player_index].selected_tab = 1
	tabs.selected_tab_index = 1

	local confirm_flow = vert_flow.add{
		type = "flow",
		direction = "horizontal"
	}
	confirm_flow.add{
		type = "empty-widget",
	}.style.horizontally_stretchable = true
	local confirm = confirm_flow.add{
		type = "button",
		caption = {"tiergen.calculate"},
		style = "confirm_button_without_tooltip"
	}
	confirm.style.minimal_width = 0
	confirm.style.right_margin = 4
	confirm.style.top_margin = 4
	confirm.enabled = false
	global.player[confirm.player_index].calculate = confirm
end
---Creates the pane for item selection
---@param base_flow LuaGuiElement
local function create_base_selection(base_flow)
end
---Creates the pane for item selection
---@param base_flow LuaGuiElement
local function create_ignored_selection(base_flow)
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
end
---Updates the tier list for the player
---@param player LuaPlayer
local function update_list(player)
	local player_table = global.player[player.index]
	local error = player_table.error
	local table = player_table.table
	if table then
		table.clear()
	end

	local tiers = player_table[player_table.selected_tab].result
	if not tiers then
		tiers = global.default_tiers
		player_table[player_table.selected_tab].result = tiers
	end
	if #tiers == 0 then
		error.visible = true
		return
	else
		error.visible = false
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
	}
	error_flow.add{
		type = "empty-widget"
	}.style.vertically_stretchable = true
	local scroll = horz_flow.add{
		type = "scroll-pane",
		name = "scroll",
		style = "naked_scroll_pane"
	}
	scroll.style.maximal_height = 16*44
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
	update_list(player)
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

---Initializes the menu for all players
local function init()
	global.menu = true
	for _, player in pairs(game.players) do
		local oldMenu = player.gui.screen["tiergen-menu"]
		if oldMenu then
			--- Destroy remnants of last mod installation
			oldMenu.destroy()
		end
		create_frame(player)
	end
end
---Initializes the menu for new players
---@param player LuaPlayer
local function new_player(player)
	if not global.menu then return end
	create_frame(player)
end
---Goes through each player and calls `reset_frame`
local function regenerate_menus()
	if not global.menu then return end
	for index, player in pairs(game.players) do
		global.player[index].highlight = nil
		global.player[index].highlighted = nil
		---@type LuaGuiElement
		local frame = player.gui.screen["tiergen-menu"]
		if frame then
			update_list(player)
		else
			create_frame(player)
		end
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

script.on_event("tiergen-menu", function (EventData)
	local player = game.get_player(EventData.player_index)
	if not player then
		return log("No player pressed that keybind??")
	end

	open_close(player)
end)
script.on_event(defines.events.on_gui_closed, function (EventData)
	if EventData.element and EventData.element.name == "tiergen-menu" then
		local player = game.get_player(EventData.player_index)
		if not player then
			return log("Who's menu just closed!?")
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
	local rootElement = lib.getRootElement(EventData.element)
	if rootElement.name == "tiergen-menu" then
	end
	if EventData.element.name == "close_button" then
		player.set_shortcut_toggled("tiergen-menu", false)
		set_visibility(player, false)
	end

	if EventData.element.parent.name == "tierlist-items" then
		local type_item = EventData.element.name
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
end)
script.on_event(defines.events.on_gui_elem_changed, function (EventData)
	if EventData.element.parent.name ~= "tiergen-item-selection-table" then
		return
	end

	local player_table = global.player[EventData.player_index]
	local player_tab = player_table[player_table.selected_tab]
	player_tab.has_changed = true
	player_table.calculate.enabled = true

	local elem = EventData.element
	local index = elem.get_index_in_parent()
	local items = player_tab.elems[elem.elem_type --[[@as "item"|"fluid"]]]
	items[index] = elem.elem_value --[[@as string]]
end)
script.on_event(defines.events.on_gui_selected_tab_changed, function (EventData)
	if EventData.element.name ~= "tiergen-item-selection" then
		return
	end

	local player_table = global.player[EventData.player_index]
	local new_tab = EventData.element.selected_tab_index
	---@cast new_tab integer
	player_table.selected_tab = new_tab
	if player_table.calculated_tab ~= new_tab then
		player_table.calculate.enabled = true
		return
	end

	local player_tab = player_table[new_tab]
	player_table.calculate.enabled = player_tab.has_changed
end)

return {
	init = init,
	add_player = new_player,
	regenerate_menus = regenerate_menus,
	migration = migrator,
	open_close = open_close
}