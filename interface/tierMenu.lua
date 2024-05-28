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
	local testing = vert_flow.add{
		type = "label",
		caption = "Testing Testing 1 2 3"
	}
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
	if #global.tier_array == 0 then
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
	for tier, items in ipairs(global.tier_array) do
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
		tier_list.style.width = 40*12

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
	-- create_options(base_flow)
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
---@param array tierArray
---@param callback fun(elem:LuaGuiElement,item:tierArrayItem)
local function traverseArray(menu, array, callback)
	array = array or {{}}
	---@type LuaGuiElement
	local table = menu["base"]["flow"]["scroll_frame"]["scroll"]["table"]
	if table.type ~= "table" then
		return -- No tiers error message
	end
	for tier, items in ipairs(array) do
		---@type LuaGuiElement
		local item_table = table.children[tier*2]["tierlist-items"]

		for _, item in ipairs(items) do
			local name = item.type.."/"..item.name
			local button = item_table[name]
			callback(button, item)
		end
	end
end

---Highlights the items in the player's global highlight array
---@param player LuaPlayer
local function highlightItems(player)
	local highlightArray = global.player_highlight[player.index]
	traverseArray(
		player.gui.screen["tiergen-menu"],
		highlightArray,
	function (elem, item)
		elem.toggled = true
		-- /TODO: Do something special if elem.isDirect is true
		-- if item.isDirect then
		-- 	-- Set a special style
		-- 	-- elem.enabled = false -- to prove it's the right elements
		-- end
	end)
end
---Highlights the items in the player's global highlight array
---@param player LuaPlayer
local function unhighlightItems(player)
	local highlightArray = global.player_highlight[player.index]
	if not highlightArray then return end
	traverseArray(
		player.gui.screen["tiergen-menu"],
		highlightArray,
	function (elem, item)
		elem.toggled = false
		-- if item.isDirect then
		-- 	-- Reset the style
		-- 	-- elem.enabled = true
		-- end
	end)
	global.player_highlight[player.index] = nil
end

script.on_event(defines.events.on_gui_click, function (EventData)
	local player = game.get_player(EventData.player_index)
	if not player then
		return log("wtf")
	end
	local rootElement = lib.getRootElement(EventData.element)
	if rootElement.name == "tiergen-menu" then
		unhighlightItems(player)
	end
	if EventData.element.name == "close_button" then
		player.set_shortcut_toggled("tiergen-menu", false)
		set_visibility(player, false)
	elseif EventData.element.parent.name == "tierlist-items" then
		local type_item = EventData.element.name
		local type = type_item:match("^[^/]+")
		local item = type_item:match("/.+"):sub(2)
		local highlightArray = calculator.get({item}, type)
		global.player_highlight[EventData.player_index] = highlightArray
		highlightItems(player)
	end
end)

return {
	init = init,
	join_player = new_player,
	set_visibility = set_visibility,
	regenerate_menus = regenerate_menus,
	migration = migrator,
}