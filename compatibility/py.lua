local config_set = {}

local vanilla = require("__tier-generator__.compatibility.base")()
local ignored_patterns = "%-turd$" --Ignore all T.U.R.D. recipes

function config_set.hard()
	return {
		name = {"tiergen-config.pyhardmode"},
		ultimate_science = vanilla.ultimate_science,
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