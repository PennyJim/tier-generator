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
		all_sciences = lib.items{
			-- Basic research
			"automation-science-pack",
			"logistic-science-pack",
			"military-science-pack",
			"chemical-science-pack",
			"se-rocket-science-pack",
			"space-science-pack",
			"utility-science-pack",
			"production-science-pack",

			-- advanced research
			"se-astronomic-science-pack-1",
			"se-astronomic-science-pack-2",
			"se-astronomic-science-pack-3",
			"se-astronomic-science-pack-4",

			"se-biological-science-pack-1",
			"se-biological-science-pack-2",
			"se-biological-science-pack-3",
			"se-biological-science-pack-4",

			"se-energy-science-pack-1",
			"se-energy-science-pack-2",
			"se-energy-science-pack-3",
			"se-energy-science-pack-4",

			"se-material-science-pack-1",
			"se-material-science-pack-2",
			"se-material-science-pack-3",
			"se-material-science-pack-4",

			"se-deep-space-science-pack-1",
			"se-deep-space-science-pack-2",
			"se-deep-space-science-pack-3",
			"se-deep-space-science-pack-4",
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