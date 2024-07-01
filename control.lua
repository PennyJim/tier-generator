lib = require("__tier-generator__.library")
config = require("__tier-generator__.interface.tierConfig")
local calculator = require("__tier-generator__.calculation.calculator")
local tierMenu = require("__tier-generator__.interface.tierMenu")
local globals = require("__tier-generator__.global")


---Recalculates the tiers
local function recalcTiers()
	calculator.uncalculate()
	tierMenu.regenerate_menus()
end
lib.register_func("recalc", recalcTiers)
lib.register_func("tierMenu", tierMenu.init)

script.on_init(function ()
	globals.on_init()
	config.init()
	lib.tick_later("recalc")
	lib.tick_later("tierMenu")
end)

script.on_event(defines.events.on_player_created, function (EventData)
	local player = game.get_player(EventData.player_index)
	if not player then
		return log("No player pressed created??")
	end

	if not global.config then
		player.set_shortcut_available("tiergen-menu", false)
	end
	globals.events[defines.events.on_player_created](EventData)
	-- tierMenu.add_player(player)
end)
script.on_event(defines.events.on_player_removed, function (EventData)
	globals.events[defines.events.on_player_removed](EventData)
end)

script.on_configuration_changed(function (ChangedData)
	globals.on_configuration_changed(ChangedData)
	if not global.config then
		config.init()
	end

	if ChangedData.mod_startup_settings_changed
	or next(ChangedData.mod_changes)
	or ChangedData.migration_applied then
		lib.tick_later("recalc")
	end
end)

script.on_event(defines.events.on_lua_shortcut, function (EventData)
	if EventData.prototype_name == "tiergen-menu" then
		local player = game.get_player(EventData.player_index)
		if not player then
			return log("No player pressed that shortcut??")
		end

		tierMenu.open_close(player)
	end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function (EventData)
	local setting = EventData.setting
	if EventData.setting_type == "runtime-global" then
		lib.clearSettingCache(setting)
	end

	-- Need to reprocess data if autoplace rules are changed
	if setting == "tiergen-consider-autoplace-setting" then
		calculator.unprocess()
	end

	if not global.willRecalc
	and lib.isOurSetting(setting)
	and setting ~= "tiergen-debug-log" then
		-- Do it a tick later so we don't recalculate multiple times a tick
		lib.tick_later("recalc")
	end
end)

script.on_load(function ()
	lib.register_load()
end)