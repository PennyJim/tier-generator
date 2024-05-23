local calculator = require("__tier-generator__.calculation.calculator")
local tierMenu = require("__tier-generator__.interface.tierMenu")

local function recalcTiers()
	global.tier_array = calculator.calculate()
	tierMenu.regenerate_menus()
	script.on_nth_tick(1, nil)
	global.willRecalc = nil
end

script.on_init(function ()
	recalcTiers()
end)

script.on_event(defines.events.on_player_created, function (EventData)
	local player = game.get_player(EventData.player_index)
	if not player then
		return log("No player pressed created??")
	end

	tierMenu.join_player(player)
end)

script.on_configuration_changed(function (ChangedData)
	if ChangedData.mod_startup_settings_changed
	or ChangedData.mod_changes
	or ChangedData.migration_applied then
		recalcTiers()
	end
end)

script.on_event(defines.events.on_lua_shortcut, function (EventData)
	if EventData.prototype_name == "tiergen-menu" then
		local player = game.get_player(EventData.player_index)
		if not player then
			return log("No player pressed that shortcut??")
		end

		local isOpened = not player.is_shortcut_toggled("tiergen-menu")
		player.set_shortcut_toggled("tiergen-menu", isOpened)
		tierMenu.set_visibility(player, isOpened)
	end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function (EventData)
	local setting = EventData.setting
	if EventData.setting_type == "runtime-global" then
		lib.clearSettingCache(setting)
	end
	if setting == "tiergen-ignored-recipes" then
		calculator.clearCache()
	end
	if not global.willRecalc
	and lib.isOurSetting(setting)
	and setting ~= "tiergen-debug-log" then
		script.on_nth_tick(1, recalcTiers)
		global.willRecalc = true
	end
end)

script.on_load(function ()
	if global.willRecalc then
		script.on_nth_tick(1, recalcTiers)
	end
end)