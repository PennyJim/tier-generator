local vanilla = require("__tier-generator__.compatibility.base")()

return function ()
	return {
		ultimate_science = vanilla.ultimate_science,
		all_sciences = vanilla.all_sciences,
		base_items = lib.items{
			"seablock-electrolyzer",
			"offshore-pump"
		},
		ignored_recipes = {
			-- ["tiergen-hand-mining"] = true -- Crashes the UI
			-- Since it's basically a category, rather than a recipe, it might
			-- have unintended consequences, so I don't like it even if it worked
		}
	} --[[@as config]]
end