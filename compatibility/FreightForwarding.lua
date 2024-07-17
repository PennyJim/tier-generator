local vanilla = require("__tier-generator__.compatibility.base")()

return function ()
	return {
		ultimate_science = vanilla.ultimate_science,
		all_sciences = vanilla.all_sciences,
		base_items = lib.items{
			-- Was for testing the compatibility with msp
			-- TODO: actually make multi-mod configurations
			-- "more-science-pack-8",
			-- "more-science-pack-9",
			-- "more-science-pack-10",
		},
		ignored_recipes = {},
		injected_recipes = {
			["space-science-pack"] = {
				id = "injected-space-science",
				enabled = true,
				category = "crafting",
				ingredients = lib.items{
					"ff-rocket-silo-hole-dummy",
					"rocket-part",
					"satellite",
				},
				object_name = "LuaRecipePrototype"
			},
			-- HACK: The problem is resolving the machine for the "rocket-building" category
			-- Should add the ability to give an item for a category instead of this.
			-- If I implement it right, I can also get rid of the above injected recipe
			["rocket-part"] = {
				id = "replicated-rocket-part",
				enabled = true,
				category = "crafting",
				ingredients = lib.items{
					"rocket-control-unit",
					"ff-rocket-frame",
					"rocket-fuel",
				},
				object_name = "LuaRecipePrototype"
			},
			-- That previous ability would also simplify this
			["ff-dredger-dummy"] = {
				id = "ff-dredger",
				enabled = true,
				category = "crafting",
				ingredients = lib.items{
					"ff-dredging-platform"
				},
				object_name = "LuaRecipePrototype"
			},
		}
	} --[[@as defaultConfig]]
end