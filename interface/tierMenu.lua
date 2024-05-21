lib = require("__tier-generator__.library")

---comment
---@param frame LuaGuiElement
---@param caption LocalisedString
local function create_titlebar(frame, caption)
	local base_flow = frame.add{
		type = "flow",
		direction = "vertical",
	}
	local title_flow = base_flow.add{
		type = "flow",
		direction = "horizontal"
	}
	title_flow.drag_target = frame
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
		type = "frame",
		style = "inside_shallow_frame"
	}
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
	local base_frame = create_titlebar(base, {"tiergen.menu"})
	local scroll = base_frame.add{
		type = "scroll-pane",
		style = "naked_scroll_pane"
	}
	scroll.style.maximal_height = 16*44
	local table = scroll.add{
		type = "table",
		column_count = 2,
		draw_horizontal_lines = true,
		direction="vertical",
	}
	table.style.left_padding = 8
	for tier, items in ipairs(global.tier_array) do
		local tier_label = table.add{
			type = "label",
			caption = {"tiergen.tier-label", tier-1}
		}
		tier_label.style.right_padding = 4
		local tier_list_frame = table.add{
			type = "frame",
			style = "slot_button_deep_frame"
		}
		tier_list_frame.style.horizontally_stretchable = true
		local tier_list = tier_list_frame.add{
			type = "table",
			column_count = 12,
			style = "filter_slot_table"
		}
		tier_list.style.width = 40*12

		for _, item in ipairs(items) do
			local itemPrototype = lib.getItemOrFluid(item.name, item.type)
			tier_list.add{
				type = "sprite-button",
				sprite = item.type.."/"..item.name,
				style = "recipe_slot_button",
				tooltip = itemPrototype.localised_name
			}
		end
	end
	return base_frame
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
---Destroyes the menu for the player to recreate it
---@param player LuaPlayer
local function reset_frame(player)
	---@type LuaGuiElement
	local frame = player.gui.screen["tiergen-menu"]
	if frame then
		frame.destroy()
	end
	create_frame(player)
	local is_open = player.is_shortcut_toggled("tiergen-menu")
	set_visibility(player, is_open)
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
		reset_frame(player)
	end
end


script.on_event(defines.events.on_gui_click, function (EventData)
	if EventData.element.name == "close_button" then
		local player = game.get_player(EventData.player_index)
		if not player then
			return log("wtf")
		end
		player.set_shortcut_toggled("tiergen-menu", false)
		set_visibility(player, false)
	end
end)


return {
	init = init,
	join_player = new_player,
	set_visibility = set_visibility,
	regenerate_menus = regenerate_menus,
}