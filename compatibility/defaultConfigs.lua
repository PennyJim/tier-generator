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
	},
	["MoreSciencePacks-for1_1"] = {
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
		ignored_recipes = {}
	}
}
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
	ignored_recipes = {}
}

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