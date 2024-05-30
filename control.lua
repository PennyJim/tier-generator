lib = require("__tier-generator__.library")
config = require("__tier-generator__.interface.tierConfig")
local calculator = require("__tier-generator__.calculation.calculator")
local tierMenu = require("__tier-generator__.interface.tierMenu")

---@class PlayerGlobal.tab
---@field elems {["item"|"fluid"]:{[int]:string}}
---@field result {[integer]:tierResult[]}?
---@field has_changed boolean

---@class PlayerGlobal
---@field highlight simpleItem?
---@field highlighted LuaGuiElement[]?
---@field calculate LuaGuiElement
---@field calculated_tab integer
---@field selected_tab integer
---@field calculated simpleItem[]
---@field elem_has_changed boolean
---@field error LuaGuiElement
---@field table LuaGuiElement
---@field [1] PlayerGlobal.tab
---@field [2] PlayerGlobal.tab
---@field [3] PlayerGlobal.tab


---Initializes the player's global variables
---@param player_index integer
local function setupPlayerGlobal(player_index)
	---@type PlayerGlobal
	local player = global.player[player_index] or {}
	global.player[player_index] = player
	player.calculated_tab = player.calculated_tab or 1
	for tab = 1, 3, 1 do
		player[tab] = player[tab] or {}
		player[tab].elems = player[tab].elems or {}
		player[tab].elems["item"] = player[tab].elems["item"] or {}
		player[tab].elems["fluid"] = player[tab].elems["fluid"] or {}
	end
end
---Initializes the global variables
local function setupGlobal()
	---@type simpleItem[]
	global.default_tiers = global.default_tiers or {}
	---@type string[]
	global.tick_later = global.tick_later or {}
	---@type PlayerGlobal[]
	global.player = global.player or {}
	for player_index in pairs(game.players) do
		---@cast player_index integer
		setupPlayerGlobal(player_index)
	end
end

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
	global.updateBase = true
	---@type string[]
	setupGlobal()
	config.init()
	lib.tick_later("recalc")
	lib.tick_later("tierMenu")
end)

script.on_event(defines.events.on_player_created, function (EventData)
	local player = game.get_player(EventData.player_index)
	if not player then
		return log("No player pressed created??")
	end

	setupPlayerGlobal(EventData.player_index)
	config.add_player(EventData.player_index)
	tierMenu.add_player(player)
end)
script.on_event(defines.events.on_player_removed, function (EventData)
	global.player[EventData.player_index] = nil
end)

script.on_configuration_changed(function (ChangedData)
	setupGlobal()
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

		tierMenu.open_close(player)
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