local function se_core_fragements(fragments)
	---@type table<data.ItemID,CompleteFakeRecipe>
	local recipes = {}
	for _, fragment in pairs(fragments) do
		recipes["se-core-fragment-"..fragment] = {
			id = "injected-se-core-fragment-"..fragment,
			category = "crafting",
			ingredients = {
				{type="item",name="se-core-miner",amount=1}
			},
			enabled = true,
			object_name = "LuaRecipePrototype"
		}
	end
	return recipes
end
return function ()
	return {
		name = {"tiergen-config.se"},
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
		},
		consider_autoplace_setting = false
	}
end