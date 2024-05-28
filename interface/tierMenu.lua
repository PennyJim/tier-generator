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
		style = "frame_action_button",
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
---Creates the tab for item selection
---@param tab_base LuaGuiElement
---@param index integer
---@param autopopulate simpleItem[]
---@return LuaGuiElement
local function create_item_selection_tab(tab_base, index, autopopulate)
	local tab = tab_base.add{
		type = "tab",
		name = "tab"..index,
		caption = {"tiergen.tab"..index}
	}
	tab.style.minimal_width = 40
	local vert_flow = tab_base.add{
		type = "flow",
		direction = "vertical"
	}
	tab_base.add_tab(tab, vert_flow)
	local item_scroll = vert_flow.add{
		type = "frame",
		style = "slot_button_deep_frame"
	}.add{
		type = "scroll-pane",
		name = "scroll",
		style = "naked_scroll_pane"
	}
	local item_table = item_scroll.add{
		type = "table",
		style = "filter_slot_table",
		column_count = 5
	}
	item_table.style.width = 40*5
	item_table.style.minimal_height = 40*3
	item_scroll.style.height = 40*3
	local fluid_scroll = vert_flow.add{
		type = "frame",
		style = "slot_button_deep_frame"
	}.add{
		type = "scroll-pane",
		name = "scroll",
		style = "naked_scroll_pane"
	}
	local fluid_table = fluid_scroll.add{
		type = "table",
		style = "filter_slot_table",
		column_count = 5
	}
	fluid_table.style.width = 40*5
	fluid_table.style.minimal_height = 40*2
	fluid_scroll.style.height = 40*2
	for _, item in ipairs(autopopulate) do
		local table = item.type == "item" and item_table or fluid_table
		table.add{
			type = "choose-elem-button",
			elem_type = item.type,
			[item.type] = item.name
		}
	end
	item_table.add{
		type = "choose-elem-button",
		elem_type = "item",
		-- style = "slot_button",
	}
	fluid_table.add{
		type = "choose-elem-button",
		elem_type = "fluid",
		-- style = "slot_button",
	}
	return tab
end
---Creates the pane for item selection
---@param base_flow LuaGuiElement
local function create_item_selection(base_flow)
	local vert_flow = base_flow.add{
		type = "frame",
		name = "tiergen-items",
		style = "bordered_frame_with_extra_side_margins"
	}.add{
		type = "flow",
		direction = "vertical"
	}
	local label = vert_flow.add{
		type = "label",
		caption = "Testing Testing 1 2 3"
	}
	local tabs = vert_flow.add{
		type = "tabbed-pane",
	}
	local playerConfig = global.config[tabs.player_index]
	create_item_selection_tab(tabs, 1, playerConfig.ultimate_science)
	create_item_selection_tab(tabs, 2, playerConfig.all_sciences)
	create_item_selection_tab(tabs, 3, playerConfig.custom)

	local confirm = vert_flow.add{
		type = "button"
	}
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
		style = "inside_shallow_frame_with_padding"
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
	local menu = player.gui.screen["tiergen-menu"]
	---@type LuaGuiElement
	local scroll = menu["base"]["flow"]["scroll_frame"]["scroll"]
	---@type LuaGuiElement
	local table = scroll["table"]
	if table then
		table.destroy()
	end
	if #global.default_tiers == 0 then
		--- FIXME: Doesn't center???
		local flow = scroll.add{
			type = "flow",
			name = "table",
		}
		flow.style.padding = {100,40}
		flow.add{
			type = "label",
			caption = {"tiergen.no-tiers"}
		}
		return
	end
	table = scroll.add{
		type = "table",
		name = "table",
		column_count = 2,
		draw_horizontal_lines = true,
		direction="vertical",
	}
	table.style.left_padding = 8
	for tier, items in ipairs(global.default_tiers) do
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
	local scroll = base_flow.add{
		type = "frame",
		name = "scroll_frame",
		style = "inside_shallow_frame"
	}.add{
		type = "scroll-pane",
		name = "scroll",
		style = "naked_scroll_pane"
	}
	scroll.style.maximal_height = 16*44
	scroll.style.left_padding = 8
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
	local menu = player.gui.screen["tiergen-menu"]
	if not menu then
		menu = create_frame(player)
	end

	menu.visible = is_toggled
end

---Initializes the menu for all players
local function init()
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
	create_frame(player)
end
---Goes through each player and calls `reset_frame`
local function regenerate_menus()
	for _, player in pairs(game.players) do
		global.player_highlight[player.index] = nil
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
---@param menu LuaGuiElement
---@param inputItem simpleItem[]
---@param callback fun(elem:LuaGuiElement,item:tierResult)
local function traverseArray(menu, inputItem, callback)
	---@type LuaGuiElement
	local table = menu["base"]["flow"]["scroll_frame"]["scroll"]["table"]
	if table.type ~= "table" then
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
---@param player LuaPlayer
local function highlightItems(player)
	local highlightedList = global.player_highlighted[player.index] or {}
	global.player_highlighted[player.index] = highlightedList
	local highlightItem = global.player_highlight[player.index]
	traverseArray(
		player.gui.screen["tiergen-menu"],
		highlightItem,
	function (elem, item)
		elem.toggled = true
		highlightedList[#highlightedList+1] = elem
	end)
end
---Highlights the items in the player's global highlight array
---@param player LuaPlayer
local function unhighlightItems(player)
	local highlightedList = global.player_highlighted[player.index]
	if not highlightedList then return end
	for _, highlightedElem in ipairs(highlightedList) do
		---@cast highlightedElem LuaGuiElement
		if not highlightedElem.valid then break end

		highlightedElem.toggled = false
	end
	global.player_highlight[player.index] = nil
	global.player_highlighted[player.index] = nil
end

script.on_event(defines.events.on_gui_click, function (EventData)
	local player = game.get_player(EventData.player_index)
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
		local highlightItem = {name=item,type=type}
		local oldHighlight = global.player_highlight[EventData.player_index]
		if oldHighlight then
			if oldHighlight.name ~= item
			or oldHighlight.type ~= type then
				unhighlightItems(player)
				global.player_highlight[EventData.player_index] = highlightItem
				highlightItems(player)
			end
		else
			global.player_highlight[EventData.player_index] = highlightItem
			highlightItems(player)
		end
	else
		unhighlightItems(player)
	end
end)

return {
	init = init,
	add_player = new_player,
	set_visibility = set_visibility,
	regenerate_menus = regenerate_menus,
	migration = migrator,
}