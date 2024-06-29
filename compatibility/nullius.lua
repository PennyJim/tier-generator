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
		all_sciences = {
			-- Regular sciences
			lib.item("nullius-geology-pack"),
			lib.item("nullius-climatology-pack"),
			lib.item("nullius-mechanical-pack"),
			lib.item("nullius-electrical-pack"),
			lib.item("nullius-chemical-pack"),
			lib.item("nullius-physics-pack"),
			lib.item("nullius-astronomy-pack"),
	
			-- Biology Sciences
			lib.item("nullius-biochemistry-pack"),
			lib.item("nullius-microbiology-pack"),
			lib.item("nullius-botany-pack"),
			lib.item("nullius-dendrology-pack"),
			lib.item("nullius-nematology-pack"),
			lib.item("nullius-ichthyology-pack"),
			lib.item("nullius-zoology-pack"),
		},
		base_items = {
			-- Given items
			lib.item("nullius-chemical-plant-1"),
			lib.item("nullius-distillery-1"),
			lib.item("nullius-hydro-plant-1"),
			lib.item("nullius-foundry-1"),
			lib.item("nullius-air-filter-1"),
			lib.item("nullius-seawater-intake-1"),
			lib.item("nullius-medium-assembler-1"),
			lib.item("nullius-small-furnace-2"), -- 2??
			lib.item("nullius-broken-electrolyzer"),
	
			--For checkpoint sciences
			lib.item("nullius-checkpoint"),
			lib.item("nullius-requirement-build"),
			lib.item("nullius-requirement-consume"),
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