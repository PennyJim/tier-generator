local autoConfigure = require("__tier-generator__.compatibility.defaultConfigs")
local menu = require("__tier-generator__.interface.tierMenu")
---@class configFuncs
local configTable = {}

local function actually_init()
	---@class config : defaultConfigs
	---@field all_sciences simpleItem[]
	---@field ultimate_science simpleItem
	---@field base_items simpleItem[]
	---@field ignored_recipes table<data.RecipeID,true>
	---@field mod string?
	local config, mod = autoConfigure()
	---@cast config config
	config.mod = mod
	global.config = config

	if config.consider_technology ~= nil
	and config.consider_technology ~= lib.getSetting("tiergen-consider-technology") then
		settings.global["tiergen-consider-technology"] = {value=config.consider_technology}
		lib.clearSettingCache("tiergen-consider-technology")
	end

	if config.consider_autoplace_setting ~= nil
	and config.consider_autoplace_setting ~= lib.getSetting("tiergen-consider-autoplace-setting") then
		settings.global["tiergen-consider-autoplace-setting"] = {value=config.consider_autoplace_setting}
		lib.clearSettingCache("tiergen-consider-autoplace-setting")
	end

	local message
	if mod then
		message = {"tiergen.mod-config", global.config.name or mod}
	else
		message = {"tiergen.vanilla-config"}
	end

	for _, player in pairs(game.players) do
		menu.add_player(player)
		player.set_shortcut_available("tiergen-menu", true)
	end

	lib.global_print(message)
end
lib.register_func("config-setup", actually_init)

function configTable.init()
	lib.seconds_later(1, "config-setup")
end

return configTable