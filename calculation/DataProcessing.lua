local lookup = require("__tier-generator__.lookupTables")
local lib = require("__tier-generator__.library")

---@type table<data.RecipeID, boolean>
local ignored_recipes = {}
local ignoredRecipes = settings.startup["tiergen-ignored-recipes"].value --[[@as string]]
-- Turn array into lookup table
for index, recipeID in ipairs(lib.split(ignoredRecipes, ",")) do
	-- Remove whitespace
	recipeID = recipeID:match("^%s*(.-)%s*$")
	ignored_recipes[recipeID] = true
end

--#region Process functions & loops
lib.log("Processing data.raw")
--#region Recipe Processing

---Parses `data.raw.recipe` items
---@param recipeID data.RecipeID
---@param recipePrototype data.RecipePrototype
local function processRecipe(recipeID, recipePrototype)
	if ignored_recipes[recipeID] then
		lib.log("\t\t"..recipeID.." was in ignored settings. Ignoring...")
		return
	end

	---@type data.RecipePrototype|data.RecipeData
	local recipeData = lib.alwaysRecipeData(recipePrototype);

	if not recipeData.results then
		lib.log("\t\t"..recipeID.." didn't result in anything?")
		lib.log(serpent.line(recipeData))
		return
	end

	-- Ignore unbarreling recipes
	if recipePrototype.subgroup == "empty-barrel" then
		lib.log("\t\t"..recipeID.." is unbarreling. Ignoring...")
		return
	end

	for _, rawResult in pairs(recipeData.results) do
		-- Get resultID
		local result = rawResult[1] or rawResult.name;
		if result == nil then
			lib.log("\t\tCouldn't find ingredientID:")
			lib.log(serpent.line(rawResult))
			goto continue
		end

		if rawResult.type == "fluid" then
			lib.appendToArrayInTable(lookup.FluidRecipe, result, recipeID)
		else
			lib.appendToArrayInTable(lookup.ItemRecipe, result, recipeID)
		end
	::continue::
	end
end
lib.log("\tProcessing recipes")
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
			lib.log("\t\t"..technologyID.." didn't unlock anything")
			-- log(serpent.line(technologyPrototype))
			return;
		end
	end

	for _, modifier in pairs(technologyData.effects) do
		if modifier.type == "unlock-recipe" then
			lib.appendToArrayInTable(lookup.RecipeTechnology, modifier.recipe, technologyID)
		end
		-- Theoretically, it can give an item. Should we make that
		-- item inherit the tier of the technology that gives it?
	end
end
lib.log("\tProcessing technology")
for technologyID, technologyData in pairs(data.raw["technology"]) do
	processTechnology(technologyID, technologyData)
end
--#endregion
--#region Category Processing

---Parses `data.raw.assembling` and `data.raw.furnace` items
---@param EntityID data.EntityID
---@param machinePrototype data.CraftingMachinePrototype
local function processCraftingMachine(EntityID, machinePrototype)
	local machineItem = lib.getEntityItem(EntityID, machinePrototype)
	if not machineItem then return end
	for _, category in pairs(machinePrototype.crafting_categories) do
		lib.appendToArrayInTable(lookup.CategoryItem, category, machineItem)
	end
end
lib.log("\tProcessing crafting categories")
for EntityID, machinePrototype in pairs(data.raw["assembling-machine"]) do
	processCraftingMachine(EntityID, machinePrototype)
end
for EntityID, furnacePrototype in pairs(data.raw["furnace"]) do
	processCraftingMachine(EntityID, furnacePrototype)
end
-- Add crafting as simplest recipe (first)
lib.prependToArrayInTable(lookup.CategoryItem, "crafting", "hand")

---Parses `data.raw.burner-generator` items
---@param EntityID data.EntityID
---@param machinePrototype data.EntityPrototype
---@param machineBurner data.BurnerEnergySource
local function processBurnerMachines(EntityID, machinePrototype, machineBurner)
	local burnerItem = lib.getEntityItem(EntityID, machinePrototype)
	if not burnerItem then return end
	local categories = machineBurner.fuel_categories or {machineBurner.fuel_category}
	for _, category in pairs(categories) do
		lib.appendToArrayInTable(lookup.CategoryItem, "tiergen-fuel-"..category, burnerItem)
	end
end
lib.log("\tProcessing burner categories")
-- Not the right place to look? tbd
-- for EnityID, BurnerMachinesPrototype in pairs(data.raw["burner-generator"]) do
-- 	processBurnerMachines(EnityID, BurnerMachinesPrototype, BurnerMachinesPrototype.burner)
-- end
for EntityID, BoilerPrototype in pairs(data.raw["boiler"]) do
	local energy_source = BoilerPrototype.energy_source
	if energy_source.type == "burner" then
		---@cast energy_source data.BurnerEnergySource
		processBurnerMachines(EntityID, BoilerPrototype, energy_source)
	end
end
for EntityID, ReactorPrototype in pairs(data.raw["reactor"]) do
	local energy_source = ReactorPrototype.energy_source
	if energy_source.type == "burner" then
		---@cast energy_source data.BurnerEnergySource
		processBurnerMachines(EntityID, ReactorPrototype, energy_source)
	end
end

---Processes rocket silos
---@param EntityID data.EntityID
---@param RocketSiloPrototype data.RocketSiloPrototype
local function processRocketSilos(EntityID, RocketSiloPrototype)
	local itemID = lib.getEntityItem(EntityID, RocketSiloPrototype)
	if not itemID then
		return -- Ignore machine if not placeable
	end
	lib.appendToArrayInTable(lookup.CategoryItem, "tiergen-rocket-launch", itemID)
end
lib.log("\tProcessing rocekt silos")
for EntityID, RocketSiloPrototype in pairs(data.raw["rocket-silo"]) do
	processCraftingMachine(EntityID, RocketSiloPrototype)
	processRocketSilos(EntityID, RocketSiloPrototype)
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
		lib.prependToArrayInTable(lookup.ItemRecipe, result, "tiergen-burning")
		lib.appendToArrayInTable(lookup.Burning, result, ItemID)
	end
end
---Processes an item and creates a 'recipe' out of the rocket results
---@param ItemID data.ItemID
---@param itemPrototype data.ItemPrototype
local function processRocketRecipe(ItemID, itemPrototype)
	local rocket_products = itemPrototype.rocket_launch_products
	if not rocket_products then
		if not itemPrototype.rocket_launch_product then
			return -- No products
		end

		rocket_products = {itemPrototype.rocket_launch_product}
	end

	for _, product in pairs(rocket_products) do
		local name = product.name or product[1]
		if not name then
			log("No name found?\n"..serpent.dump(product))
		else
			lib.appendToArrayInTable(lookup.ItemRecipe, name, "tiergen-rocket-launch")
			lib.appendToArrayInTable(lookup.Rocket, name, ItemID)
		end
	end
end
---Parses all item-subtypes
---@param SubgroupID data.ItemSubGroupID
local function processItemSubtype(SubgroupID)
	for ItemID, itemPrototype in pairs(data.raw[SubgroupID]) do
		if lookup.ItemType[ItemID] then
			error(ItemID.." already assigned a type??")
		end

---@diagnostic disable-next-line: assign-type-mismatch
		lookup.ItemType[ItemID] = itemPrototype.type
---@diagnostic disable-next-line: param-type-mismatch
		processBurningRecipe(ItemID, itemPrototype)
---@diagnostic disable-next-line: param-type-mismatch
		processRocketRecipe(ItemID, itemPrototype)
	end
end
lib.log("\tProcessing items")
for subtype in pairs(defines.prototypes["item"]) do
	processItemSubtype(subtype)
end
--#endregion

return lookup