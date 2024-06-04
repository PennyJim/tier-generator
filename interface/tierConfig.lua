local autoConfigure = require("__tier-generator__.compatibility.defaultConfigs")
---@class configFuncs
local configTable = {}

local function MentionConfig()
	local mod = global.config.mod
	if mod then
		message = {"tiergen.mod-config", global.config.name or mod}
	else
		message = {"tiergen.vanilla-config"}
	end

	if remote.interfaces["better-chat"] then
		remote.call("better-chat", "send", message, nil, "global")
	else
		game.print(message)
	end
end
lib.register_func("config-alert", MentionConfig)

function configTable.init()
	---@class config : defaultConfigs
	---@field all_sciences simpleItem[]
	---@field ultimate_science simpleItem
	---@field base_items simpleItem[]
	---@field ignored_recipes data.RecipeID[]
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

	lib.seconds_later(2, "config-alert")
end

return configTable