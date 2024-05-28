-- Should only ever need to be run once.
-- No active code should be done outside a function
---@class defaultConfigs
---@field ultimate_science simpleItem
---@field all_sciences simpleItem[]
---@field base_items simpleItem[]
---@field ignored_recipes data.RecipeID[]
---@class defaultSettingsMap
---@field [string] defaultConfigs

---@type defaultSettingsMap
local singleMods = {
	["Ultracube"] = {
		ultimate_science = lib.item("cube-complete-annihilation-card"),
		all_sciences = {
			lib.item("cube-basic-contemplation-unit"),
			lib.item("cube-fundamental-comprehension-card"),
			lib.item("cube-abstract-interrogation-card"),
			lib.item("cube-deep-introspection-card"),
			lib.item("cube-synthetic-premonition-card"),
			lib.item("cube-complete-annihilation-card")
		},
		base_items = {
			lib.item("cube-ultradense-utility-cube"), -- It is the *core* of the mod
			lib.item("cube-fabricator"), -- You are given one
			lib.item("cube-synthesizer"), -- You are given one
			lib.item("cube-construct-forbidden-ziggurat-dummy") -- Because of a scripted technology
		},
		ignored_recipes = {}
	}
}
---@type defaultConfigs
local vanillaDefaults = {
	ultimate_science = lib.item{"space-science-pack"},
	all_sciences = {
		lib.item("automation-science-pack"),
		lib.item("logistic-science-pack"),
		lib.item("military-science-pack"),
		lib.item("chemical-science-pack"),
		lib.item("production-science-pack"),
		lib.item("utility-science-pack"),
		lib.item("space-science-typo"),
	}, -- TODO
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

-- ---Turns a array into a comma separated string
-- ---@param array string[]
-- ---@return string
-- local function turnArrayIntoString(array)
-- 	local full_string = ""
-- 	for _, string in ipairs(array) do
-- 		full_string = full_string..", "..string
-- 	end
-- 	return full_string:sub(3)
-- end

return DetermineMod