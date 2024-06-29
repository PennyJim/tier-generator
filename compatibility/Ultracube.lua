return function ()
	return {
		ultimate_science = lib.item("cube-complete-annihilation-card"),
		all_sciences = lib.items{
			"cube-basic-contemplation-unit",
			"cube-fundamental-comprehension-card",
			"cube-abstract-interrogation-card",
			"cube-deep-introspection-card",
			"cube-synthetic-premonition-card",
			"cube-complete-annihilation-card",
		},
		base_items = lib.items{
			"cube-ultradense-utility-cube", -- It is the *core* of the mod
			"cube-fabricator", -- You are given one
			"cube-synthesizer", -- You are given one
			"cube-construct-forbidden-ziggurat-dummy", -- Because of a scripted technology
		},
		ignored_recipes = {},
	}
end