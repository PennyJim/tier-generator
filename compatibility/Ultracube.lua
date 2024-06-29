return function ()
	return {
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
end