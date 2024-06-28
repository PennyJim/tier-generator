-- Should only ever need to be run once.
-- No active code should be done outside a function

---@class defaultConfigs
---@field name LocalisedString?
---@field ultimate_science simpleItem
---@field all_sciences simpleItem[]
---@field base_items (simpleItem|tierResult)[]
---@field ignored_recipes table<data.RecipeID,true> --An array of lua patterns
---@field ignored_patterns string[]?
---@field consider_technology boolean?
---@field injected_recipes table<data.ItemID,CompleteFakeRecipe>?

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

---@class defaultSettingsMap
---@field [string] defaultConfigs
local singleMods = {}

---Generates the core fragment recipes
---@param fragments string[]
---@return table<data.ItemID,CompleteFakeRecipe>
local function se_core_fragements(fragments)
	---@type table<data.ItemID,CompleteFakeRecipe>
	local recipes = {}
	for _, fragment in pairs(fragments) do
		recipes["se-core-fragment-"..fragment] = {
			id = "injected-se-core-fragment-"..fragment,
			category = "crafting",
			ingredients = {
				{name="se-core-miner", type="item", amount = 1}
			},
			enabled = true,
			object_name = "LuaRecipePrototype"
		}
	end
	return recipes
end

singleMods["space-exploration"] = {
	ultimate_science = lib.item("se-deep-space-science-pack-4"),
	all_sciences = {
		-- Basic research
		lib.item("automation-science-pack"),
		lib.item("logistic-science-pack"),
		lib.item("military-science-pack"),
		lib.item("chemical-science-pack"),
		lib.item("se-rocket-science-pack"),
		lib.item("space-science-pack"),
		lib.item("utility-science-pack"),
		lib.item("production-science-pack"),
		-- advanced research
		lib.item("se-astronomic-science-pack-1"),
		lib.item("se-astronomic-science-pack-2"),
		lib.item("se-astronomic-science-pack-3"),
		lib.item("se-astronomic-science-pack-4"),

		lib.item("se-biological-science-pack-1"),
		lib.item("se-biological-science-pack-2"),
		lib.item("se-biological-science-pack-3"),
		lib.item("se-biological-science-pack-4"),

		lib.item("se-energy-science-pack-1"),
		lib.item("se-energy-science-pack-2"),
		lib.item("se-energy-science-pack-3"),
		lib.item("se-energy-science-pack-4"),

		lib.item("se-material-science-pack-1"),
		lib.item("se-material-science-pack-2"),
		lib.item("se-material-science-pack-3"),
		lib.item("se-material-science-pack-4"),

		lib.item("se-deep-space-science-pack-1"),
		lib.item("se-deep-space-science-pack-2"),
		lib.item("se-deep-space-science-pack-3"),
		lib.item("se-deep-space-science-pack-4"),
	},
	base_items = {},
	ignored_recipes = {},
	injected_recipes = se_core_fragements{
		"omni",
		"coal",
		"crude-oil",
		"stone",
		"iron-ore",
		"copper-ore",
		"uranium-ore",
		"se-vulcanite",
		"se-cryonite",
		"se-beryllium-ore",
		"se-holmium-ore",
		"se-iridium-ore",
		"se-vitamelange",
	}
}
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
singleMods["pyhardmode"] = {
	name = {"tiergen-configs.pyhardmode"},
	ultimate_science = vanillaDefaults.ultimate_science,
	all_sciences = {
		lib.item("automation-science-pack"),
		lib.item("py-science-pack-1"),
		lib.item("logistic-science-pack"),
		lib.item("military-science-pack"),
		lib.item("py-science-pack-2"),
		lib.item("chemical-science-pack"),
		lib.item("py-science-pack-3"),
		lib.item("production-science-pack"),
		lib.item("py-science-pack-4"),
		lib.item("utility-science-pack"),
		lib.item("space-science-pack"),
	},
	base_items = {lib.item("burner-mining-drill"), lib.item("offshore-pump")},
	ignored_recipes = {
		["bioport-hidden-recipe"] = true, -- Ignore this one, just use the injected recipe
	},
	ignored_patterns = {
		"%-turd$", --Ignore all T.U.R.D. recipes
	},
	injected_recipes = {
		["guano"] = {
			id = "injected-guano",
			enabled = true,
			category = "biofluid", -- FIXME: currently gets the logistic tanks instead of the biopyanoport
			ingredients = {
				{type="item",name="workers-food",amount=1},
				{type="item",name="gobachov",amount=1}
			},
			object_name = "LuaRecipePrototype"
		}
	}
}
singleMods["pyalternativeenergy"] = {
	name = {"tiergen-configs.py-ae"},
	ultimate_science = singleMods["pyhardmode"].ultimate_science,
	all_sciences = singleMods["pyhardmode"].all_sciences,
	base_items = {},
	ignored_recipes = singleMods["pyhardmode"].ignored_recipes,
	ignored_patterns = singleMods["pyhardmode"].ignored_patterns,
	injected_recipes = singleMods["pyhardmode"].injected_recipes
}
singleMods["pypostprocessing"] = {
	name = {"tiergen-configs.py"},
	ultimate_science = vanillaDefaults.ultimate_science,
	all_sciences = vanillaDefaults.all_sciences,
	base_items = {},
	ignored_recipes = {},
	ignored_patterns = singleMods["pyalternativeenergy"].ignored_patterns
}
singleMods["MoreSciencePacks-for1_1"] = {
	name = {"tiergen-configs.msp"},
	ultimate_science = vanillaDefaults.ultimate_science,
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
	name = {"tiergen-configs.science-pack-galore"},
	ultimate_science = vanillaDefaults.ultimate_science,
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
singleMods["SimpleSeablock"] = {
	ultimate_science = vanillaDefaults.ultimate_science,
	all_sciences = vanillaDefaults.all_sciences,
	base_items = {
		lib.item("seablock-electrolyzer"),
		lib.item("offshore-pump"),
	},
	ignored_recipes = {
		-- ["tiergen-hand-mining"] = true -- Crashes the UI
		-- Since it's basically a category, rather than a recipe, it might
		-- have unintended consequences, so I don't like it even if it worked
	}
}
---Shorthand for the nullius asteroid mining 'recipes'
---@param resource string
---@return CompleteFakeRecipe
local function nullius_guide_resources(resource)
	---@type CompleteFakeRecipe
	return {
		id = "injected-nullius-asteroid-mining-"..resource,
		enabled = true,
		category = "crafting",
		ingredients = {
			{type="item",name="nullius-guide-drone-"..resource.."-1",amount=1},
			{type="item",name="nullius-guide-remote-"..resource,amount=1},
		},
		object_name = "LuaRecipePrototype"
	}
end
singleMods["nullius"] = {
	-- ultimate_science = lib.item("nullius-astronomy-pack"),
	ultimate_science = lib.item("nullius-zoology-pack"), -- Has a higher tier...
	all_sciences = {
		-- Regular sciences
		lib.item("nullius-geology-pack"),
		lib.item("nullius-climatology-pack"),
		lib.item("nullius-mechanical-pack"),
		lib.item("nullius-electrical-pack"),
		lib.item("nullius-chemical-pack"),
		lib.item("nullius-physics-pack"),
		lib.item("nullius-astronomy-pack"),

		-- Biology Sciences
		lib.item("nullius-biochemistry-pack"),
		lib.item("nullius-microbiology-pack"),
		lib.item("nullius-botany-pack"),
		lib.item("nullius-dendrology-pack"),
		lib.item("nullius-nematology-pack"),
		lib.item("nullius-ichthyology-pack"),
		lib.item("nullius-zoology-pack"),
	},
	base_items = {
		-- Given items
		lib.item("nullius-chemical-plant-1"),
		lib.item("nullius-distillery-1"),
		lib.item("nullius-hydro-plant-1"),
		lib.item("nullius-foundry-1"),
		lib.item("nullius-air-filter-1"),
		lib.item("nullius-seawater-intake-1"),
		lib.item("nullius-medium-assembler-1"),
		lib.item("nullius-small-furnace-2"), -- 2??
		lib.item("nullius-broken-electrolyzer"),

		--For checkpoint sciences
		lib.item("nullius-checkpoint"),
		lib.item("nullius-requirement-build"),
		lib.item("nullius-requirement-consume"),
	},
	ignored_recipes = {},
	injected_recipes = {
		["iron-ore"] = nullius_guide_resources("iron"),
		["nullius-bauxite"] = nullius_guide_resources("bauxite"),
		["copper-ore"] = nullius_guide_resources("copper"),
		["nullius-sandstone"] = nullius_guide_resources("sandstone"),
		["nullius-limestone"] = nullius_guide_resources("limestone"),
		["uranium-ore"] = nullius_guide_resources("uranium"),
	},
	-- consider_technology = false,
}

---Returns the chosen defaultConfigs and the mod associated with them
---If it has no compatibility available, then the second parameter returns nil
---@return defaultConfigs
---@return string?
local function DetermineMod()
	for mod, defaults in pairs(singleMods) do
		---@cast defaults defaultConfigs
		if game.active_mods[mod] then
			local ignored_recipes = defaults.ignored_recipes
			local ignored_patterns = defaults.ignored_patterns or {}
			-- Process the patterns into ignored_recipes
			for _, pattern in pairs(ignored_patterns) do
				for key in pairs(game.recipe_prototypes) do
					if ignored_recipes[key] then
					elseif key:match(pattern) then
						ignored_recipes[key] = true
					end
				end
			end
			defaults.ignored_patterns = nil
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