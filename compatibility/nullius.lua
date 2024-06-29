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

return function ()
	return {
		-- ultimate_science = lib.item("nullius-astronomy-pack"),
		ultimate_science = lib.item("nullius-zoology-pack"),
		all_sciences = lib.items{
			-- Regular sciences
			"nullius-geology-pack",
			"nullius-climatology-pack",
			"nullius-mechanical-pack",
			"nullius-electrical-pack",
			"nullius-chemical-pack",
			"nullius-physics-pack",
			"nullius-astronomy-pack",
	
			-- Biology Sciences
			"nullius-biochemistry-pack",
			"nullius-microbiology-pack",
			"nullius-botany-pack",
			"nullius-dendrology-pack",
			"nullius-nematology-pack",
			"nullius-ichthyology-pack",
			"nullius-zoology-pack",
		},
		base_items = lib.items{
			-- Given items
			"nullius-chemical-plant-1",
			"nullius-distillery-1",
			"nullius-hydro-plant-1",
			"nullius-foundry-1",
			"nullius-air-filter-1",
			"nullius-seawater-intake-1",
			"nullius-medium-assembler-1",
			"nullius-small-furnace-2", -- 2??
			"nullius-broken-electrolyzer",
	
			--For checkpoint sciences
			"nullius-checkpoint",
			"nullius-requirement-build",
			"nullius-requirement-consume",
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
	}
end