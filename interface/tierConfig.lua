local autoConfigure = require("__tier-generator__.compatibility.defaultConfigs")
---@class configFuncs
local configTable = {}

local function MentionConfig()
	local mod = global.config.mod
	if mod then
		message = {"tiergen.mod-config", mod}
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
	---@class config
	---@field base_items simpleItem[]
	---@field ignored_recipes data.RecipeID[]
	---@field [0] defaultPlayer
	---@field [uint] playerConfig
	---@field mod string?
	local config = {}
	global.config = config
	local defaultConfigs, mod = autoConfigure()
	config.mod = mod
	config.base_items = defaultConfigs.base_items
	config.ignored_recipes = defaultConfigs.ignored_recipes
	---@class playerConfig
	---@field all_sciences simpleItem[]
	---@field ultimate_science simpleItem[]
	---@class defaultPlayer : playerConfig
	local defaultPlayer = {
		all_sciences = defaultConfigs.all_sciences,
		ultimate_science = {defaultConfigs.ultimate_science},
		custom = {},
	}
	config[0] = defaultPlayer

	for player_index in pairs(game.players) do
		config[player_index] = defaultPlayer
	end

	lib.seconds_later(2, "config-alert")
end
---Sets the player's config to the defaultConfigs
---@param player_index uint
function configTable.add_player(player_index)
	global.config[player_index] = global.config[0]
end

return configTable