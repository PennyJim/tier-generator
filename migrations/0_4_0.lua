---@diagnostic disable: inject-field, no-unknown
-- Clean destroy old tiergen-menus
if storage.menu then
	for _, player in pairs(game.players) do
		local menu = player.gui.screen["tiergen-menu"]
		if menu then
			menu.destroy()
		end
	end

	storage.player = nil
	storage.menu = nil
end