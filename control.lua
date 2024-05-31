lib = require("__tier-generator__.library")
config = require("__tier-generator__.interface.tierConfig")
local calculator = require("__tier-generator__.calculation.calculator")
local tierMenu = require("__tier-generator__.interface.tierMenu")

---@class PlayerGlobal.elems.recipe
---@field has_changed boolean whether or not the elems have changed since last confirmed
---@field recipe {[int]:string} the table of recipe values
---@field count {["recipe"]:integer} how many items have a value
---@field last {["recipe"]:integer} the index of the last item with a value

---@class PlayerGlobal.elems.items
---@field has_changed boolean whether or not the elems have changed since last confirmed
---@field ["item"|"fluid"] {[int]:string} the table of values
---@field count {["item"|"fluid"]:integer} how many items have a value
---@field last {["item"|"fluid"]:integer} the index of the last item with a value

---@class PlayerGlobal.tab
---@field elems PlayerGlobal.elems.items the values of this element
---@field result {[integer]:tierResult[]}? the results of this tab's last calculation
---@field calculated simpleItem[]? the list of items last calculated, given has_changed is false

---@class PlayerGlobal
---@field menu LuaGuiElement the menu element everything is attatched to
---@field highlight simpleItem? the item to be highlighted/currently highlighted
---@field highlighted LuaGuiElement[]? the elements that have been highlighted
---@field calculate LuaGuiElement the confirm button for calculation
---@field calculated_tab integer the tab that was last calculated
---@field selected_tab integer the tab that is currently selected
---@field calculated simpleItem[] the list of items last calculated
---@field error LuaGuiElement the element displayed in case of an error
---@field table LuaGuiElement the displayed table of calculated tiers
---@field [1] PlayerGlobal.tab
---@field [2] PlayerGlobal.tab
---@field [3] PlayerGlobal.tab
---@field base_elems PlayerGlobal.elems.items the choose-elem values of the base elements
---@field ignored_elems PlayerGlobal.elems.recipe the chooose-elem values of the ignored elements


---Initializes the player's global variables
---@param player_index integer
local function setupPlayerGlobal(player_index)
	---@type PlayerGlobal
	local player = global.player[player_index] or {}
	global.player[player_index] = player
	player.calculated = player.calculated or {}
	player.calculated_tab = player.calculated_tab or 0
	for tab = 1, 3, 1 do
		player[tab] = player[tab] or {}
		player[tab].elems = player[tab].elems or {}
		if player[tab].elems.has_changed == nil then
			player[tab].elems.has_changed = true
		end
		player[tab].elems["item"] = player[tab].elems["item"] or {}
		player[tab].elems["fluid"] = player[tab].elems["fluid"] or {}
		player[tab].elems.last = player[tab].elems.last or {}
		player[tab].elems.count = player[tab].elems.count or {}
		player[tab].elems.last["item"] = player[tab].elems.last["item"] or 0
		player[tab].elems.count["item"] = player[tab].elems.count["item"] or 0
		player[tab].elems.last["fluid"] = player[tab].elems.last["fluid"] or 0
		player[tab].elems.count["fluid"] = player[tab].elems.count["fluid"] or 0
	end
	player.base_elems = player.base_elems or {}
	player.base_elems["item"] = player.base_elems["item"] or {}
	player.base_elems["fluid"] = player.base_elems["fluid"] or {}
	player.base_elems.count = player.base_elems.count or {}
	player.base_elems.last = player.base_elems.last or {}
	player.base_elems.count["item"] = player.base_elems.count["item"] or 0
	player.base_elems.count["fluid"] = player.base_elems.count["fluid"] or 0
	player.base_elems.last["item"] = player.base_elems.last["item"] or 0
	player.base_elems.last["fluid"] = player.base_elems.last["fluid"] or 0

	player.ignored_elems = player.ignored_elems or {}
	player.ignored_elems.count = player.ignored_elems.count or {}
	player.ignored_elems.last = player.ignored_elems.last or {}
	player.ignored_elems.recipe = player.ignored_elems.recipe or {}
	player.ignored_elems.count.recipe = player.ignored_elems.count.recipe or 0
	player.ignored_elems.last.recipe = player.ignored_elems.last.recipe or 0
end
---Initializes the global variables
local function setupGlobal()
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
	calculator.uncalculate()
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
	tierMenu.add_player(player)
end)
script.on_event(defines.events.on_player_removed, function (EventData)
	global.player[EventData.player_index] = nil
end)

script.on_configuration_changed(function (ChangedData)
	setupGlobal()
	if not global.config then
		config.init()
	end

	local mods_have_changed = false
	for _ in pairs(ChangedData.mod_changes) do
		mods_have_changed = true
		break
	end
	if ChangedData.mod_startup_settings_changed
	or mods_have_changed
	or ChangedData.migration_applied then
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
	-- Currently doesn't do anything because it's not a setting
	-- Keeping it to remind myself that `unprocess` is the right function to use
	-- if setting == "tiergen-ignored-recipes" then
	-- 	calculator.unprocess()
	-- end
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