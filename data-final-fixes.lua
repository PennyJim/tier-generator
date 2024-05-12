local tierArray = {};
TierMaps = {
	["recipe-category"] = {},
	["technology"] = {},
	["recipe"] = {},
	["fluid"] = {},
};
for subtype in pairs(defines.prototypes["item"]) do
	TierMaps[subtype] = {}
end
calculating = table.deepcopy(TierMaps)

--#region Helper functions

---Appends to an array within a table
---@param table table
---@param key any
---@param newValue any
local function appendToArrayInTable(table, key, newValue)
	local array = table[key] or {}
	array[#array+1] = newValue;
	table[key] = array;
end

---Always return plural results
---Absolutely no gurantees it works for everything
---@param table data.RecipePrototype|data.MinableProperties|any
---@return data.ProductPrototype[]
local function alwaysPluralResults(table)
	---@type data.ProductPrototype[]
	local results = table.results
	if not results then
		results = {{
			type = "item",
			name = table.result,
		}}
	end
	if results[1].name or results[1][1] then
		return results
	else
---@diagnostic disable-next-line: return-type-mismatch
		return false
	end
end
---Always return RecipeData
---@param table data.RecipePrototype
---@return data.RecipeData
local function alwaysRecipeData(table)
	---@type data.RecipeData
---@diagnostic disable-next-line: assign-type-mismatch
	local oldRecipeData = table.normal or table.expensive
	local recipeData = {
		ingredients = table.ingredients or oldRecipeData.ingredients,
		results = alwaysPluralResults(table) or alwaysPluralResults(oldRecipeData),
		enabled = (table and table.enabled) or (oldRecipeData and oldRecipeData.enabled)
	}
	-- has to check if it's nil specifically, as it'll just always be true otherwise
	if recipeData.enabled == nil then
		recipeData.enabled = true;
	end

	return recipeData
end
---Always returns TechnologyData
---@param table data.TechnologyPrototype
---@return data.TechnologyData
local function alwaysTechnologyData(table)
	---@type data.TechnologyData
---@diagnostic disable-next-line: assign-type-mismatch
	local oldTechnologyData = table.normal or table.expensive or {}
	local technologyData = {
		unit = table.unit or oldTechnologyData.unit,
		prerequisites = table.prerequisites or oldTechnologyData.prerequisites or {}
	}
	return technologyData
end
--#endregion

--#region Process functions & loops
--#region Recipe Processing

---@type table<data.ItemID,data.RecipeID[]>
local ItemRecipeLookup = {}
---@type table<data.FluidID,data.RecipeID[]>
local FluidRecipeLookup = {}
---Parses `data.raw.recipe` items
---@param recipeID data.RecipeID
---@param recipePrototype data.RecipePrototype
local function processRecipe(recipeID, recipePrototype)
	---@type data.RecipePrototype|data.RecipeData
	local recipeData = alwaysRecipeData(recipePrototype);

	if not recipeData.results then
		print("\t"..recipeID.." didn't result in anything?")
		print(serpent.line(recipeData))
		return
	end

	-- Ignore unbarreling recipes
	if recipePrototype.subgroup == "empty-barrel" then
		print("\t"..recipeID.." is unbarreling. Ignoring...")
		return
	end

	for _, rawResult in pairs(recipeData.results) do
		-- Get resultID
		local result = rawResult[1] or rawResult.name;
		if result == nil then
			print("\tCouldn't find ingredientID:")
			print(serpent.line(rawResult))
			goto continue
		end

		if rawResult.type == "fluid" then
			appendToArrayInTable(FluidRecipeLookup, result, recipeID)
		else
			appendToArrayInTable(ItemRecipeLookup, result, recipeID)
		end
	::continue::
	end
end
print("Processing recipes")
for recipeID, rawRecipe in pairs(data.raw["recipe"]) do
	processRecipe(recipeID, rawRecipe);
end
--#endregion
--#region Technology Proesssing

---@type table<data.RecipeID,data.TechnologyID[]>
local RecipeTechnologyLookup = {}
---Parses `data.raw.technology` items
---@param technologyID data.TechnologyID
---@param technologyPrototype data.TechnologyPrototype
local function processTechnology(technologyID, technologyPrototype)
	---@type data.TechnologyPrototype|data.TechnologyData
	local technologyData = technologyPrototype

	if technologyData.effects == nil then
---@diagnostic disable-next-line: cast-local-type
		technologyData = technologyData.normal or technologyData.expensive
		if not technologyData then
			print("\t"..technologyID.." didn't unlock anything")
			-- print(serpent.line(technologyPrototype))
			return;
		end
	end

	for _, modifier in pairs(technologyData.effects) do
		if modifier.type == "unlock-recipe" then
			appendToArrayInTable(RecipeTechnologyLookup, modifier.recipe, technologyID)
		end
		-- Theoretically, it can give an item. Should we make that
		-- item inherit the tier of the technology that gives it?
	end
end
print("Processing technology")
for technologyID, technologyData in pairs(data.raw["technology"]) do
	processTechnology(technologyID, technologyData)
end
--#endregion
--#region Category Processing

---@alias data.CraftingMachineID string
---@type table<data.RecipeCategoryID, data.ItemID[]>
local CategoryItemLookup = {}
---Parses `data.raw.assembling` and `data.raw.furnace` items
---@param EntityID data.EntityID
---@param machinePrototype data.CraftingMachinePrototype
local function processCraftingMachine(EntityID, machinePrototype)
	local machineItem
	if machinePrototype.placeable_by then
		machineItem = machinePrototype.placeable_by.item
	elseif machinePrototype.minable then
		local items = alwaysPluralResults(machinePrototype.minable)

		for _, item in pairs(items) do
			if data.raw["item"][item.name].place_result == EntityID then
				machineItem = item.name
			end
		end

		if not machineItem then
			print("\t"..EntityID.."'s mined items aren't placable. Ignoring...")
		end
	else
		print("\t"..EntityID.." Isn't placable _or_ mineable. Ignoring...")
		return
	end

	for _, category in pairs(machinePrototype.crafting_categories) do
		appendToArrayInTable(CategoryItemLookup, category, machineItem)
	end
end
print("Processing crafting categories")
appendToArrayInTable(CategoryItemLookup, "crafting", "hand")
for EntityID, machinePrototype in pairs(data.raw["assembling-machine"]) do
	processCraftingMachine(EntityID, machinePrototype)
end
for EntityID, furnacePrototype in pairs(data.raw["furnace"]) do
	processCraftingMachine(EntityID, furnacePrototype)
end
--#endregion
--#region Item Type Processing

---@type table<data.ItemID, data.ItemSubGroupID>
local ItemTypeLookup = {}
---Parses all item-subtypes
---@param SubgroupID data.ItemSubGroupID
local function processItemSubtype(SubgroupID)
	for ItemID, itemPrototype in pairs(data.raw[SubgroupID]) do
		if ItemTypeLookup[ItemID] then
			error(ItemID.." already assigned a type??")
		end

---@diagnostic disable-next-line: assign-type-mismatch
		ItemTypeLookup[ItemID] = itemPrototype.type
	end
end
print("Processing items")
for subtype in pairs(defines.prototypes["item"]) do
	processItemSubtype(subtype)
end
--#endregion
print("Finished Pre-Processing")
--#endregion

--@type table<string,fun(string,data.PrototypeBase)>
local tierSwitch = setmetatable({}, {
	__call = function(self, prototypeID, value)
		return self["base"](prototypeID, value)
	end
})
---Determine the tier of the given prototype
---@param prototypeID string
---@param value data.PrototypeBase
---@return integer
tierSwitch["base"] = function(prototypeID, value)
	local tier = TierMaps[value.type][prototypeID]
	if tier ~= nil then return tier end
	if calculating[value.type][prototypeID] then return -math.huge end

	calculating[value.type][prototypeID] = true
	tier = tierSwitch[value.type](prototypeID, value);
	calculating[value.type][prototypeID] = nil
	if tier >= 0 then -- Discard negative values
		TierMaps[value.type][prototypeID] = tier
	end
	return tier
end

---Determine the tier of the given recipe category
---@param CategoryID data.RecipeCategoryID
---@param category data.RecipeCategory
---@return integer
tierSwitch["recipe-category"] = function (CategoryID, category)
	local machines = CategoryItemLookup[CategoryID]
	local categoryTier = math.huge;
	for _, item in pairs(machines) do
		-- If it's craftable by hand, it's a base recipe.
		-- TODO: figure out how to *properly* check this
		-- I'm currently just adding "hand" to the "crafting" category
		if item == "hand" then return 0 end
		local itemTier = tierSwitch(item, data.raw["item"][item])
		-- Don't consider the machine if it takes something being calculated.
		-- It must mean that it uses something a tier too high, Right..?
		if itemTier >= 0 then
			categoryTier = math.min(categoryTier, itemTier)
		end
	end
	return categoryTier - 1 -- subtract one to reduce the amount of tiers
end

---Return the highest tier from the ingredients
---@param ingredients data.IngredientPrototype[]
---@return integer
local function getIngredientsTier(ingredients)
	local ingredientsTier = 0;
	for _, ingredient in pairs(ingredients) do
		local nextName = ingredient.name or ingredient[1]
		local nextType = ingredient.type or ItemTypeLookup[nextName]
		local nextValue = data.raw[nextType][nextName]
		local nextTier = tierSwitch(nextName, nextValue)
		-- Skip if machine takes an item being calculated
		if nextTier < 0 then return nextTier end
		ingredientsTier = math.max(ingredientsTier, nextTier)
	end
	return ingredientsTier
end

---Determine the tier of the given technology
---@param technologyID data.TechnologyID
---@param technology data.TechnologyPrototype
---@return integer
tierSwitch["technology"] = function (technologyID, technology)
	local techData = alwaysTechnologyData(technology)
	local ingredientsTier = getIngredientsTier(techData.unit.ingredients)

	local prereqTier = 0;
	for _, prerequisite in pairs(techData.prerequisites) do
		local preValue = data.raw["technology"][prerequisite]
		local preTier = tierSwitch(prerequisite, preValue)
		-- Skip if technology takes an item being calculated
		if preTier < 0 then preTier = 0 end
		prereqTier = math.max(prereqTier, preTier)
	end

	if ingredientsTier == 0 and prereqTier == 0 then
		error("I don't think a technology should every be t0")
	end
	return math.max(ingredientsTier, prereqTier)
end

---Determine the tier of the given recipe
---@param recipeID data.RecipeID
---@param recipe data.RecipePrototype
---@return integer
tierSwitch["recipe"] = function (recipeID, recipe)
	local recipeData = alwaysRecipeData(recipe)
	if not recipeData.ingredients then
		print("\t"..recipeID.." didn't require anything? Means it's a t0?")
		error(serpent.line(recipeData.ingredients))
	end

	-- Get recipe ingredients tier
	local ingredientsTier = getIngredientsTier(recipeData.ingredients)
	-- Exit early if child-tier isn't currently calculable
	if ingredientsTier < 0 then return ingredientsTier end

	-- Get category tier
	local category = data.raw["recipe-category"][recipe.category or "crafting"]
	local machineTier = tierSwitch(category.name, category)
	-- Exit early if child-tier isn't currently calculable
	if machineTier < 0 then return machineTier end

	-- Get technology tier if it isn't enabled to start with
	local technologyTier = 0
	if not recipeData.enabled then
		technologyTier = math.huge
		local technologies = RecipeTechnologyLookup[recipeID]
		for _, technology in pairs(technologies) do
			local nextValue = data.raw["technology"][technology]
			local nextTier = tierSwitch(technology, nextValue)
			-- Assume currently calculating technology to be of higher tier
			if nextTier >= 0 then
				technologyTier = math.min(technologyTier, nextTier)
			end
		end
	end

	return math.max(ingredientsTier, machineTier, technologyTier)
end

---Determine the tier of the given item or fluid
---@param ItemID data.ItemID|data.FluidID
---@param value data.ItemPrototype|data.FluidPrototype
---@return integer
tierSwitch["fluid"] = function (ItemID, value)
	local recipes
	if value.type == "fluid" then
		recipes = FluidRecipeLookup[ItemID]
	else
		recipes = ItemRecipeLookup[ItemID]
	end

	-- No recipes create it, then it's a base resource
	-- TODO: take into account whether it generates?
	-- if it doesn't generate, maybe check if a technology gives it
	if not recipes then return 0 end

	local recipeTier = math.huge
	for _, recipe in pairs(recipes) do
		local recipePrototype = data.raw["recipe"][recipe]
		local tempTier = tierSwitch(recipe, recipePrototype)
		-- Skip recipe if it's using something being calculated
		if tempTier >= 0 then
			recipeTier = math.min(recipeTier, tempTier)
		end
	end

	-- It left the loop without a valid tier or returning an invalid one.
	-- That must mean there was no valid recipe. We've discarded barreling
	-- in the recipe processing, and skipped it if it there were *no* recipes.
	-- This _must_ mean that there's something being calculated in the chain.
	if recipeTier == math.huge then
		return -1
	end

	return recipeTier + 1
end
for subtype in pairs(defines.prototypes["item"]) do
	tierSwitch[subtype] = tierSwitch["fluid"]
end

--#region TESTING
local function itemTest(itemID)
	local itemType = ItemTypeLookup[itemID]
	local tier = -1
	local rounds = 0
	while tier < 0 do
		tier = tierSwitch(itemID, data.raw[itemType][itemID])
		rounds = rounds + 1
	end
	return "\t"..itemID..": Tier "..tier.." after "..rounds.." attempt(s)"
end

print(itemTest("iron-ore"))
print(itemTest("iron-plate"))
print(itemTest("steel-plate"))
print(itemTest("stone-furnace"))
print(itemTest("advanced-circuit"))
print(itemTest("electric-furnace"))


print("Done Testing")

