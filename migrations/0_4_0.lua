---@diagnostic disable: inject-field, no-unknown
-- Clean destroy old tiergen-menus
if global.menu then
	for _, player in pairs(game.players) do
		local menu = player.gui.screen["tiergen-menu"]
		if menu then
			menu.destroy()
		end
	end

	global.player = nil
	global.menu = nil
end