local calculator = require("__tier-generator__.calculation.calculator")
local tierMenu = require("__tier-generator__.interface.tierMenu")

script.on_init(function ()
	global.tier_array = calculator()
	tierMenu.init()
end)

script.on_event(defines.events.on_player_created, function (EventData)
	local player = game.get_player(EventData.player_index)
	if not player then
		return log("No player pressed that shortcut??")
	end

	tierMenu.join_player(player)
end)

script.on_configuration_changed(function (ChangedData)
	if ChangedData.mod_startup_settings_changed  or
			ChangedData.mod_changes or
			ChangedData.migration_applied then
		global.tier_array = calculator()
		tierMenu.regenerate_menus()
	end
end)

script.on_event(defines.events.on_lua_shortcut, function (EventData)
	if EventData.prototype_name == "tiergen-menu" then
		log(EventData)
		local player = game.get_player(EventData.player_index)
		if not player then
			return log("No player pressed that shortcut??")
		end

		local isOpened = not player.is_shortcut_toggled("tiergen-menu")
		player.set_shortcut_toggled("tiergen-menu", isOpened)
		tierMenu.set_visibility(player, isOpened)
	end
end)