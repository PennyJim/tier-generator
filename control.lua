local calculator = require("__tier-generator__.calculation.calculator")
local tierMenu = require("__tier-generator__.interface.tierMenu")

local function recalcTiers()
	if global.updateBase then
		calculator.updateBase()
		global.updateBase = nil
	end
	global.tier_array = calculator.calculate()
	tierMenu.regenerate_menus()
	script.on_nth_tick(1, nil)
	global.willRecalc = nil
end

script.on_init(function ()
	global.player_highlight = {}
	global.updateBase = true
	tierMenu.init()
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
	local tiergen_migration = ChangedData.mod_changes["tier-generator"]
	if tiergen_migration then
		tierMenu.migration(tiergen_migration)
	end
	local mods_have_changed = false
	for _ in pairs(ChangedData.mod_changes) do
		mods_have_changed = true
		break
	end
	if ChangedData.mod_startup_settings_changed
	or mods_have_changed
	or ChangedData.migration_applied then
		global.player_highlight = {}
		global.updateBase = true
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
		calculator.reprocess()
	elseif setting == "tiergen-base-items" then
		global.updateBase = true
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