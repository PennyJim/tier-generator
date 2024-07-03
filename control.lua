local handler = require("event_handler")
lib = require("__tier-generator__.library")
local calculator = require("__tier-generator__.calculation.calculator")
-- local tierMenu = require("__tier-generator__.interface.tierMenu")

---@type event_handler
local main_handler = {events={}}

handler.add_lib(require("__tier-generator__.global"))
handler.add_lib(main_handler)
handler.add_lib(require("__tier-generator__.interface.newTierMenu"))
handler.add_lib(require("__gui-modules__.gui"))
handler.add_lib(require("__tier-generator__.interface.tierConfig"))

-- require("__tier-generator__.calculation.ErrorFinder")


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