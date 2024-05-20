---Creates the menu for the player
---@param player LuaPlayer
---@return LuaGuiElement
local function create_frame(player)
	local screen = player.gui.screen
	local base_frame = screen.add{
		type = "frame",
		name = "tiergen-menu",
		caption = {"tiergen.menu"},
		visible = false,
	}
	base_frame.auto_center = true
	return base_frame
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
		reset_frame(player)
	end
end


return {
	init = init,
	join_player = new_player,
	set_visibility = set_visibility,
	regenerate_menus = regenerate_menus,
}