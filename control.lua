lib = require("__tier-generator__.library")
config = require("__tier-generator__.interface.tierConfig")
local calculator = require("__tier-generator__.calculation.calculator")
local tierMenu = require("__tier-generator__.interface.tierMenu")

---Recalculates the tiers
local function recalcTiers()
	if global.updateBase then
		calculator.updateBase()
		global.updateBase = nil
	end
	global.default_tiers = calculator.getArray(global.config[0].all_sciences)
	tierMenu.regenerate_menus()
end
lib.register_func("recalc", recalcTiers)
lib.register_func("tierMenu", tierMenu.init)

script.on_init(function ()
	global.player_highlight = {}
	global.player_highlighted = {}
	global.default_tiers = {}
	global.tick_later = {}
	global.updateBase = true
	config.init()
	lib.tick_later("recalc")
	lib.tick_later("tierMenu")
end)

script.on_event(defines.events.on_player_created, function (EventData)
	local player = game.get_player(EventData.player_index)
	if not player then
		return log("No player pressed created??")
	end

	config.add_player(EventData.player_index)
	tierMenu.add_player(player)
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
		lib.tick_later("recalc")
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
		lib.tick_later("recalc")
	end
end)

script.on_load(function ()
	lib.register_load()
end)