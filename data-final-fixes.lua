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
local calculating = table.deepcopy(TierMaps)
local debug_printing = settings.startup["tiergen-debug-log"].value --[[@as boolean]]
---@type table<data.RecipeID, boolean>
local ignored_recipes = {}

--#region processedTables

---@type table<data.ItemID,data.RecipeID[]>
local ItemRecipeLookup = {}
---@type table<data.FluidID,data.RecipeID[]>
local FluidRecipeLookup = {}
---@type table<data.RecipeID,data.TechnologyID[]>
local RecipeTechnologyLookup = {}
---@type table<data.ItemID,data.ItemID[]>
local BurningLookup = {}
---@type table<data.RecipeCategoryID, data.ItemID[]>
local CategoryItemLookup = {}
---@type table<data.ItemID, data.ItemSubGroupID>
local ItemTypeLookup = {}
--#endregion

--#region Helper functions

local _log = log
local function log(...)
	if debug_printing then
		return _log(...)
	end
end
---Splits a string at 'sep'
---@param s string
---@param sep string
---@return string[]
function split(s, sep)
	local fields = {}
	
	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)
---@diagnostic disable-next-line: discard-returns
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
	
	return fields
end

---Resolves the type of an item, and errors if one is not found
---@param itemID string
---@return string
local function resolveItemType(itemID)
	local itemType = ItemTypeLookup[itemID]
	if not itemType then
		error("Could not find item type of given item: "..itemID)
	end
	return itemType
end
---Appends to an array within a table
---@param table table
---@param key any
---@param newValue any
local function appendToArrayInTable(table, key, newValue)
	local array = table[key] or {}
	array[#array+1] = newValue;
	table[key] = array;
end

---Prepends to an array within a table
---@param table table
---@param key any
---@param newValue any
local function prependToArrayInTable(table, key, newValue)
	local array = table[key] or {}
	local shiftedValue = newValue
	for	index, oldValue in ipairs(array) do
		array[index] = shiftedValue
		shiftedValue = oldValue
	end
	array[#array+1] = shiftedValue
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
		results = alwaysPluralResults(table) or alwaysPluralResults(oldRecipeData)
	}
	if table then
		recipeData.enabled = table.enabled
	elseif oldRecipeData then
		recipeData.enabled = oldRecipeData.enabled
	end
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

---Gets the placable item that results in the entity
---@param EntityID data.EntityID
---@param entityPrototype data.EntityPrototype
---@return data.ItemID?
local function getEntityItem(EntityID, entityPrototype)
	if entityPrototype.placeable_by then
		return entityPrototype.placeable_by.item
	elseif entityPrototype.minable then
		local items = alwaysPluralResults(entityPrototype.minable)

		for _, item in pairs(items) do
			if data.raw["item"][item.name].place_result == EntityID then
				return item.name
			end
		end
		
		log("\t\t"..EntityID.."'s mined items aren't placable. Ignoring...")
	else
		log("\t\t"..EntityID.." Isn't placable _or_ mineable. Ignoring...")
	end
	return nil
end

--#endregion


local ignoredRecipes = settings.startup["tiergen-ignored-recipes"].value --[[@as string]]
-- Turn array into lookup table
for index, recipeID in ipairs(split(ignoredRecipes, ",")) do
	-- Remove whitespace
	recipeID = recipeID:match("^%s*(.-)%s*$")
	ignored_recipes[recipeID] = true
end

--#region Process functions & loops
log("Processing data.raw")
--#region Recipe Processing

---Parses `data.raw.recipe` items
---@param recipeID data.RecipeID
---@param recipePrototype data.RecipePrototype
local function processRecipe(recipeID, recipePrototype)
	if ignored_recipes[recipeID] then
		log("\t\t"..recipeID.." was in ignored settings. Ignoring...")
		return
	end

	---@type data.RecipePrototype|data.RecipeData
	local recipeData = alwaysRecipeData(recipePrototype);

	if not recipeData.results then
		log("\t\t"..recipeID.." didn't result in anything?")
		log(serpent.line(recipeData))
		return
	end

	-- Ignore unbarreling recipes
	if recipePrototype.subgroup == "empty-barrel" then
		log("\t\t"..recipeID.." is unbarreling. Ignoring...")
		return
	end

	for _, rawResult in pairs(recipeData.results) do
		-- Get resultID
		local result = rawResult[1] or rawResult.name;
		if result == nil then
			log("\t\tCouldn't find ingredientID:")
			log(serpent.line(rawResult))
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
log("\tProcessing recipes")
for recipeID, rawRecipe in pairs(data.raw["recipe"]) do
	processRecipe(recipeID, rawRecipe);
end
--#endregion
--#region Technology Proesssing

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
			log("\t\t"..technologyID.." didn't unlock anything")
			-- log(serpent.line(technologyPrototype))
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
log("\tProcessing technology")
for technologyID, technologyData in pairs(data.raw["technology"]) do
	processTechnology(technologyID, technologyData)
end
--#endregion
--#region Category Processing

---Parses `data.raw.assembling` and `data.raw.furnace` items
---@param EntityID data.EntityID
---@param machinePrototype data.CraftingMachinePrototype
local function processCraftingMachine(EntityID, machinePrototype)
	local machineItem = getEntityItem(EntityID, machinePrototype)
	if not machineItem then return end
	for _, category in pairs(machinePrototype.crafting_categories) do
		appendToArrayInTable(CategoryItemLookup, category, machineItem)
	end
end
log("\tProcessing crafting categories")
for EntityID, machinePrototype in pairs(data.raw["assembling-machine"]) do
	processCraftingMachine(EntityID, machinePrototype)
end
for EntityID, furnacePrototype in pairs(data.raw["furnace"]) do
	processCraftingMachine(EntityID, furnacePrototype)
end
for EntityID, RocketSiloPrototype in pairs(data.raw["rocket-silo"]) do
	processCraftingMachine(EntityID, RocketSiloPrototype)
end
-- Add crafting as simplest recipe (first)
prependToArrayInTable(CategoryItemLookup, "crafting", "hand")

---Parses `data.raw.burner-generator` items
---@param EntityID data.EntityID
---@param machinePrototype data.EntityPrototype
---@param machineBurner data.BurnerEnergySource
local function processBurnerMachines(EntityID, machinePrototype, machineBurner)
	local burnerItem = getEntityItem(EntityID, machinePrototype)
	if not burnerItem then return end
	local categories = machineBurner.fuel_categories or {machineBurner.fuel_category}
	for _, category in pairs(categories) do
		appendToArrayInTable(CategoryItemLookup, "tiergen-fuel-"..category, burnerItem)
	end
end
log("\tProcessing burner categories")
for EnityID, BurnerMachinesPrototype in pairs(data.raw["burner-generator"]) do
	processBurnerMachines(EnityID, BurnerMachinesPrototype, BurnerMachinesPrototype.burner)
end
for EnityID, ReactorPrototype in pairs(data.raw["reactor"]) do
	local energy_source = ReactorPrototype.energy_source
	if energy_source.type == "burner" then
		---@cast energy_source data.BurnerEnergySource
		processBurnerMachines(EnityID, ReactorPrototype, energy_source)
	end
end
--#endregion
--#region Item Processing

---Parses all items and creates a `recipe` out of the burnt_result
---@param ItemID data.ItemID
---@param itemPrototype data.ItemPrototype
local function processBurningRecipe(ItemID, itemPrototype)
	if itemPrototype.fuel_category and itemPrototype.burnt_result then
		local result = itemPrototype.burnt_result
		-- Prepend because burning is usually simpler than crafting
		prependToArrayInTable(ItemRecipeLookup, result, "tiergen-burning")
		appendToArrayInTable(BurningLookup, result, ItemID)
	end
end

---Parses all item-subtypes
---@param SubgroupID data.ItemSubGroupID
local function processItemSubtype(SubgroupID)
	for ItemID, itemPrototype in pairs(data.raw[SubgroupID]) do
		if ItemTypeLookup[ItemID] then
			error(ItemID.." already assigned a type??")
		end

---@diagnostic disable-next-line: assign-type-mismatch
		ItemTypeLookup[ItemID] = itemPrototype.type
---@diagnostic disable-next-line: param-type-mismatch
		processBurningRecipe(ItemID, itemPrototype)
	end
end
log("\tProcessing items")
for subtype in pairs(defines.prototypes["item"]) do
	processItemSubtype(subtype)
end
--#endregion
--#endregion

--#region Tier calculation
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
	local success = false
	success, tier = pcall(tierSwitch[value.type], prototypeID, value)
	if not success then
		-- _log({"error-calculating", prototypeID, value.type, serpent.dump(value)})
		_log("Error calculating the "..value.type.." of "..prototypeID..":\n"..tier)
		tier = -math.huge
	end
	calculating[value.type][prototypeID] = nil
	if tier >= 0 then -- Discard negative values
		TierMaps[value.type][prototypeID] = tier
		if value.type == "fluid" or defines.prototypes["item"][value.type] == 0 then
			appendToArrayInTable(tierArray, tier+1, prototypeID)
		end
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
	if settings.startup["tiergen-reduce-category"].value then
		categoryTier = categoryTier - 1
	end
	return categoryTier
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
		log("\t"..recipeID.." didn't require anything? Means it's a t0?")
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
		if not technologies then
			print("\t"..recipeID.." is not an unlockable recipe.")
			return -math.huge -- Ignore this recipe
		end

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

---Determine the tier of burning an item
---@param ItemID data.ItemID
---@param value data.ItemPrototype
tierSwitch["burning"] = function (ItemID, value)
	local burningRecipes = BurningLookup[ItemID]
	local tier = math.huge

	for _, fuelID in pairs(burningRecipes) do
		local fuelTier = getIngredientsTier{{fuelID}}
		if fuelTier < 0 then
			return fuelTier
		end
		local fuel = data.raw[ItemTypeLookup[fuelID]][fuelID]
		local categoryTier = tierSwitch("tiergen-fuel-"..fuel.fuel_category, {
			type = "recipe-category",
		})
		if categoryTier < 0 then
			return categoryTier
		end
		local recipeTier = math.max(fuelTier, categoryTier)
		tier = math.min(tier, recipeTier)
	end
	return tier
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
		-- if the recipeID starts with "tiergen-" then it's a fake recipe
		-- this mod *will not* make recipes (not for smuggling this data out)
		local _, realstart = recipe:find("^tiergen[-]")
		local tempTier = math.huge
		if realstart then
			local fakeRecipeID = recipe:sub(realstart+1)
			tempTier = tierSwitch[fakeRecipeID](ItemID, value)
		else
			local recipePrototype = data.raw["recipe"][recipe]
			tempTier = tierSwitch(recipe, recipePrototype)
		end
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

---Calculates the tier of a given itemID
---@param itemID string
---@return string?
local function calculateTier(itemID)
	local itemType = resolveItemType(itemID)
	local tier = -1
	local rounds = 0
	while tier < 0 and rounds < 5 do
		tier = tierSwitch(itemID, data.raw[itemType][itemID])
		rounds = rounds + 1
	end
	if rounds == 5 then
		_log("Gave up trying to calculate "..itemID.."'s tier")
	else
		return "\t"..itemID..": Tier "..tier.." after "..rounds.." attempt(s)"
	end
end

---Directly set the tier of a given itemID
---@param itemID string
local function setTier(itemID)
	local itemType = resolveItemType(itemID)
	TierMaps[itemType][itemID] = 0
end

-- TODO: figure out how to get the 'recipe' of space science!
-- I know that it is made in the rocket silo, but I
-- would like to not hard-code it if I don't have to.
--#endregion

log("Setting base item overrides")
local baseItems = settings.startup["tiergen-base-items"].value --[[@as string]]
for _, itemID in pairs(split(baseItems, ",")) do
	-- Trim whitespace
	itemID = itemID:match("^%s*(.-)%s*$")
	log("\tSetting "..itemID.." to tier 0")
	setTier(itemID)
end
log("Calculating items")
local items = settings.startup["tiergen-item-calculation"].value --[[@as string]]
for _, itemID in pairs(split(items, ",")) do
	-- Trim whitespace
	itemID = itemID:match("^%s*(.-)%s*$")
	log(calculateTier(itemID))
end

log("Done!\n")

_log(serpent.dump(tierArray))