---Migrates from one version of tiegen to another
---@param migration ModChangeData
return function (migration)
	local old = migration.old_version
	if			old == "0.2.0" then goto v0_2_0
	elseif 	old == "0.2.1" then goto v0_2_1
	elseif 	old == "0.2.2" then goto v0_2_2
	elseif 	old == "0.2.3" then goto v0_2_3
	elseif 	old == "0.2.4" then goto v0_2_4
	elseif 	old == "0.2.5" then goto v0_2_5
	else return end

	::v0_2_0::
	::v0_2_1::
	::v0_2_2::
	::v0_2_3::
	::v0_2_4::
	for _, player in pairs(game.players) do
		local menu = player.gui.screen["tiergen-menu"]
		if menu then
			menu.destroy()
		end
	end

	global.player_highlight = {}
	global.player_highlighted = {}
	global.default_tiers = global.tier_array
	global.tier_array = nil
	::v0_2_5::
end