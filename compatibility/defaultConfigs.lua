-- Should only ever need to be run once.
-- No active code should be done outside a function
---@class defaultSettings
---@field ultimate_science data.ItemID
---@field all_sciences data.ItemID[]
---@field base_items data.ItemID[]
---@field ignored_recipes data.RecipeID[]
---@class settingTable
---@field [string] defaultSettings

---@type settingTable
local singleMods = {
	["Ultracube"] = {
		ultimate_science = "cube-complete-annihilation-card",
		all_sciences = {
			"cube-basic-contemplation-unit",
			"cube-fundamental-comprehension-card",
			"cube-abstract-interrogation-card",
			"cube-deep-introspection-card",
			"cube-synthetic-premonition-card",
			"cube-complete-annihilation-card"
		},
		base_items = {
			"cube-ultradense-utility-cube", -- It is the *core* of the mod
			"cube-fabricator", -- You are given one
			"cube-synthesizer", -- You are given one
			"cube-construct-forbidden-ziggurat-dummy" -- BECAUSE A TECHNOLOGY REQUIRES THIS DUMMY ITEM
		},
		ignored_recipes = {}
	}
}
---@type defaultSettings
local vanillaDefaults = {
	ultimate_science = "space-science-pack",
	all_sciences = {}, -- TODO
	base_items = {},
	ignored_recipes = {}
}

local function DetermineMod()
	for mod, defaults in pairs(singleMods) do
		if game.active_mods[mod] then
			game.print("Tier Calculator is using the "..mod.." configuration")
			return defaults
		end
	end

	-- Unknown mod(s)
	game.print("Tier Calculator is using the default configuration")
	return vanillaDefaults
end

---Turns a array into a comma separated string
---@param array string[]
---@return string
local function turnArrayIntoString(array)
	local full_string = ""
	for _, string in ipairs(array) do
		full_string = full_string..", "..string
	end
	return full_string:sub(3)
end

return function ()
	local defaults = DetermineMod()

	-- TODO: turn settings into configs
	local ultimate = defaults.ultimate_science
	local sciences = turnArrayIntoString(defaults.all_sciences)
	local base_items = turnArrayIntoString(defaults.base_items)
	local ignored_recipes = turnArrayIntoString(defaults.ignored_recipes)

	-- FIXME: A testing hack. DO NOT USE THESE IN PROD
	-- lib.setSetting("tiergen-item-calculation", ultimate)
	-- lib.setSetting("tiergen-base-items", base_items)
	-- lib.setSetting("tiergen-ignored-recipes", ignored_recipes)
end