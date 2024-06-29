return function ()
	return {
		ultimate_science = lib.item("space-science-pack"),
		all_sciences = lib.items{
			"automation-science-pack",
			"logistic-science-pack",
			"military-science-pack",
			"chemical-science-pack",
			"production-science-pack",
			"utility-science-pack",
			"space-science-pack",
		},
		base_items = lib.items{"space-science-pack"},
		ignored_recipes = {},
	}
end