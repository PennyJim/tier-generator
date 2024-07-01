local menu = require("__tier-generator__.interface.tierMenu")
---@type event_handler
local config_handlers = {}

---@class defaultConfig
---@field name LocalisedString?
---@field ultimate_science simpleItem
---@field all_sciences simpleItem[]
---@field base_items (simpleItem|tierResult)[]
---@field ignored_recipes table<data.RecipeID,true> --An array of lua patterns
---@field ignored_patterns string[]?
---@field consider_technology boolean?
---@field consider_autoplace_setting boolean?
---@field injected_recipes table<data.ItemID,CompleteFakeRecipe>?

---@class config : defaultConfig
---@field mod string?
---@field ignored_patterns nil

---@type defaultConfig?
local interface_configs
---@type string?
local interface_mod
---@type table<string,fun():defaultConfig>
local builtin_configs = {}
-- Overhauls
builtin_configs["Ultracube"]								= require("__tier-generator__.compatibility.Ultracube")
builtin_configs["pyhardmode"]								= require("__tier-generator__.compatibility.py").hard
builtin_configs["pyalternativeenergy"]			= require("__tier-generator__.compatibility.py").ae
builtin_configs["pypostprocessing"]					= require("__tier-generator__.compatibility.py").base
builtin_configs["nullius"]									= require("__tier-generator__.compatibility.nullius")
builtin_configs["SimpleSeablock"]						= require("__tier-generator__.compatibility.simple-seablock")

-- Small(er) mods
builtin_configs["space-exploration"]				= require("__tier-generator__.compatibility.space-exploration")
builtin_configs["MoreSciencePacks-for1_1"]	= require("__tier-generator__.compatibility.msp")
builtin_configs["SciencePackGalore"] 				= require("__tier-generator__.compatibility.spg")
builtin_configs["SciencePackGaloreForked"]	= builtin_configs["SciencePackGalore"]

---@type fun():defaultConfig
local vanilla_config = require("__tier-generator__.compatibility.base")

-- Process the patterns into ignored_recipes
---@param ignored_patterns string[] the list of patterns
---@param ignored_recipes table<string,true> the list of ignored recipes
local function expand_patterns(ignored_patterns, ignored_recipes)
	for _, pattern in pairs(ignored_patterns) do
		for key in pairs(game.recipe_prototypes) do
			if ignored_recipes[key] then
			elseif key:match(pattern) then
				ignored_recipes[key] = true
			end
		end
	end
end

---Picks a config table
---@return defaultConfig config
---@return string? mod
local function choose_config()
	if interface_configs then
		return interface_configs, interface_mod or "external"
	end

	for mod, default in pairs(builtin_configs) do
		if game.active_mods[mod] then
			return default(), mod
		end
	end

	return vanilla_config()
end

local function actually_init()
	local config, mod = choose_config()
	expand_patterns(config.ignored_patterns or {}, config.ignored_recipes)
	---@cast config config
	config.ignored_patterns = nil
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
		message = {"tiergen.mod-config", config.name or mod}
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

function config_handlers.on_init()
	lib.seconds_later(1, "config-setup")
end

function config_handlers.on_configuration_changed(ChangedData)
	if not global.config then
		config_handlers.on_init()
	end
end

return config_handlers