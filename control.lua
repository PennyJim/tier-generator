local handler = require("event_handler")
lib = require("__tier-generator__.library")
local calculator = require("__tier-generator__.calculation.calculator")
-- local tierMenu = require("__tier-generator__.interface.tierMenu")

handler.add_lib(require("__tier-generator__.global"))
handler.add_lib(require("__tier-generator__.interface.newTierMenu"))
handler.add_lib(require("__gui-modules__.gui"))
handler.add_lib(require("__tier-generator__.interface.tierConfig"))

-- require("__tier-generator__.calculation.ErrorFinder")

---@type event_handler
local main_handler = {events={}}

---Recalculates the tiers
local function recalcTiers()
	calculator.uncalculate()
	-- tierMenu.regenerate_menus()
end
lib.register_func("recalc", recalcTiers)
-- lib.register_func("tierMenu", tierMenu.init)

main_handler.on_init = function ()
	lib.tick_later("recalc")
	lib.tick_later("tierMenu")
end

main_handler.events[defines.events.on_player_created] = function (EventData)
	local player = game.get_player(EventData.player_index)
	if not player then
		return log("No player pressed created??")
	end

	if not global.config then
		player.set_shortcut_available("tiergen-menu", false)
	end
	-- tierMenu.add_player(player)
end

main_handler.on_configuration_changed = function (ChangedData)
	if ChangedData.mod_startup_settings_changed
	or next(ChangedData.mod_changes)
	or ChangedData.migration_applied then
		lib.tick_later("recalc")
	end
end

main_handler.events[defines.events.on_runtime_mod_setting_changed] = function (EventData)
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
end

main_handler.on_load = function ()
	lib.register_load()
end