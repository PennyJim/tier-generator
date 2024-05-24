---Migrates from one version of tiegen to another
---@param migration ModChangeData
return function (migration)
	local old = migration.old_version
	if old == "0.2.0" then goto v0_2_0 end

	::v0_2_0::
	for _, player in pairs(game.players) do
		local menu = player.gui.screen["tiergen-menu"]
		if menu then
			menu.destroy()
		end
	end
end