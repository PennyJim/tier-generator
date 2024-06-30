local config_set = {}

local vanilla = require("__tier-generator__.compatibility.base")()
local ignored_patterns = {"%-turd$"} --Ignore all T.U.R.D. recipes

function config_set.hard()
	---@type defaultConfig
	return {
		name = {"tiergen-config.pyhardmode"},
		ultimate_science = vanilla.ultimate_science,
		all_sciences = lib.items{
			"automation-science-pack",
			"py-science-pack-1",
			"logistic-science-pack",
			"military-science-pack",
			"py-science-pack-2",
			"chemical-science-pack",
			"py-science-pack-3",
			"production-science-pack",
			"py-science-pack-4",
			"utility-science-pack",
			"space-science-pack",
		},
		base_items = lib.items{"burner-mining-drill", "offshore-pump"},
		ignored_recipes = {
			["bioport-hidden-recipe"] = true, -- Ignore this one, just use the injected recipe
		},
		ignored_patterns = ignored_patterns,
		injected_recipes = {
			["guano"] = {
				id = "injected-guano",
				enabled = true,
				category = "crafting",
				ingredients = {
					{type="item",name="bioport",amount=1},
					{type="item",name="workers-food",amount=1},
					{type="item",name="gobachov",amount=1}
				},
				object_name = "LuaRecipePrototype"
			}
		}
	}
end

function config_set.ae()
	local ae = config_set.hard()
	ae.base_items = {}
	return ae
end

function config_set.base()
	---@type defaultConfig
	return {
		name = {"tiergen-config.py"},
		ultimate_science = vanilla.ultimate_science,
		all_sciences = vanilla.all_sciences,
		base_items = {},
		ignored_recipes = {},
		ignored_patterns = ignored_patterns
	}
end

return config_set