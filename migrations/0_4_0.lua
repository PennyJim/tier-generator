---@diagnostic disable: inject-field, no-unknown
-- Clean destroy old tiergen-menus
for _, player in pairs(game.players) do
	local menu = player.gui.screen["tiergen-menu"]
	if menu then
		menu.destroy()
	end
end

-- Clear the old global values
global.player = nil
global.menu = nil