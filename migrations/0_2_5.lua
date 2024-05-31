-- Clean destroy old tiergen-menus
for _, player in pairs(game.players) do
	local menu = player.gui.screen["tiergen-menu"]
	if menu then
		menu.destroy()
	end
end

-- Clear the unecessary array
global.tier_array = nil

-- Migrate the highlight and highlighted table into the new global player structure
global.player = global.player or {}
if global.player_highlight then
	for player_index, highlight in pairs(global.player_highlight) do
		global.player[player_index].highlight = highlight
	end
end
global.player_highlight = nil
if global.player_highlighted then
	for player_index, highlighted in pairs(global.player_highlighted) do
		global.player[player_index].highlighted = highlighted
	end
end
global.player_highlighted = nil