-- Should only ever need to be run once.
-- No active code should be done outside a function
---@class defaultConfigs
---@field ultimate_science simpleItem
---@field all_sciences simpleItem[]
---@field base_items (simpleItem|tierResult)[]
---@field ignored_recipes data.RecipeID[]
---@field consider_technology boolean?
---@class defaultSettingsMap
---@field [string] defaultConfigs

---@type defaultSettingsMap
local singleMods = {}
singleMods["Ultracube"] = {
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
	ignored_recipes = {},
}
singleMods["MoreSciencePacks-for1_1"] = {
	ultimate_science = lib.item("space-science-pack"),
	all_sciences = {
		lib.item("automation-science-pack"),
		lib.item("logistic-science-pack"),
		lib.item("military-science-pack"),
		lib.item("chemical-science-pack"),
		lib.item("production-science-pack"),
		lib.item("utility-science-pack"),
		lib.item("space-science-pack"),
		lib.item("more-science-pack-1"),
		lib.item("more-science-pack-2"),
		lib.item("more-science-pack-3"),
		lib.item("more-science-pack-4"),
		lib.item("more-science-pack-5"),
		lib.item("more-science-pack-6"),
		lib.item("more-science-pack-7"),
		lib.item("more-science-pack-8"),
		lib.item("more-science-pack-9"),
		lib.item("more-science-pack-10"),
		lib.item("more-science-pack-11"),
		lib.item("more-science-pack-12"),
		lib.item("more-science-pack-13"),
		lib.item("more-science-pack-14"),
		lib.item("more-science-pack-15"),
		lib.item("more-science-pack-16"),
		lib.item("more-science-pack-17"),
		lib.item("more-science-pack-18"),
		lib.item("more-science-pack-19"),
		lib.item("more-science-pack-20"),
		lib.item("more-science-pack-21"),
		lib.item("more-science-pack-22"),
		lib.item("more-science-pack-23"),
		lib.item("more-science-pack-24"),
		lib.item("more-science-pack-25"),
		lib.item("more-science-pack-26"),
		lib.item("more-science-pack-27"),
		lib.item("more-science-pack-28"),
		lib.item("more-science-pack-29"),
		lib.item("more-science-pack-30"),
	},
	base_items = {},
	ignored_recipes = {},
}
singleMods["SciencePackGalore"] = {
	ultimate_science = lib.item("space-science-pack"),
	all_sciences = {
		lib.item("automation-science-pack"),
		lib.item("logistic-science-pack"),
		lib.item("military-science-pack"),
		lib.item("chemical-science-pack"),
		lib.item("production-science-pack"),
		lib.item("utility-science-pack"),
		lib.item("space-science-pack"),
		lib.item("sem:spg_science-pack-1"),
		lib.item("sem:spg_science-pack-2"),
		lib.item("sem:spg_science-pack-3"),
		lib.item("sem:spg_science-pack-4"),
		lib.item("sem:spg_science-pack-5"),
		lib.item("sem:spg_science-pack-6"),
		lib.item("sem:spg_science-pack-7"),
		lib.item("sem:spg_science-pack-8"),
		lib.item("sem:spg_science-pack-9"),
		lib.item("sem:spg_science-pack-10"),
		lib.item("sem:spg_science-pack-11"),
		lib.item("sem:spg_science-pack-12"),
		lib.item("sem:spg_science-pack-13"),
		lib.item("sem:spg_science-pack-14"),
		lib.item("sem:spg_science-pack-15"),
		lib.item("sem:spg_science-pack-16"),
		lib.item("sem:spg_science-pack-17"),
		lib.item("sem:spg_science-pack-18"),
		lib.item("sem:spg_science-pack-19"),
		lib.item("sem:spg_science-pack-20"),
		lib.item("sem:spg_science-pack-21"),
		lib.item("sem:spg_science-pack-22"),
		lib.item("sem:spg_science-pack-23"),
		lib.item("sem:spg_science-pack-24"),
		lib.item("sem:spg_science-pack-25"),
		lib.item("sem:spg_science-pack-26"),
		lib.item("sem:spg_science-pack-27"),
		lib.item("sem:spg_science-pack-28"),
		lib.item("sem:spg_science-pack-29"),
		lib.item("sem:spg_science-pack-30"),
		lib.item("sem:spg_science-pack-31"),
		lib.item("sem:spg_science-pack-32"),
		lib.item("sem:spg_science-pack-33"),
		lib.item("sem:spg_science-pack-34"),
		lib.item("sem:spg_science-pack-35"),
		lib.item("sem:spg_science-pack-36"),
	},
	base_items = {},
	ignored_recipes = {},
}
singleMods["SciencePackGaloreForked"] = singleMods["SciencePackGalore"]
---@type defaultConfigs
local vanillaDefaults = {
	ultimate_science = lib.item("space-science-pack"),
	all_sciences = {
		lib.item("automation-science-pack"),
		lib.item("logistic-science-pack"),
		lib.item("military-science-pack"),
		lib.item("chemical-science-pack"),
		lib.item("production-science-pack"),
		lib.item("utility-science-pack"),
		lib.item("space-science-pack"),
	},
	base_items = {},
	ignored_recipes = {},
}

---Returns the chosen defaultConfigs and the mod associated with them
---If it has no compatibility available, then the second parameter returns nil
---@return defaultConfigs
---@return string?
local function DetermineMod()
	for mod, defaults in pairs(singleMods) do
		if game.active_mods[mod] then
			return defaults, mod
		end
	end

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