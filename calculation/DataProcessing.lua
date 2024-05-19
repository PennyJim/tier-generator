local lookup = require("__tier-generator__.calculation.lookupTables")
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
---@param recipePrototype LuaRecipePrototype
local function processRecipe(recipeID, recipePrototype)
	if ignored_recipes[recipeID] then
		lib.log("\t\t"..recipeID.." was in ignored settings. Ignoring...")
		return
	end
	if #recipePrototype.products == 0 then
		lib.log("\t\t"..recipeID.." didn't result in anything?")
		lib.log(serpent.line(recipePrototype))
		return
	end
	-- Ignore unbarreling recipes
	if recipePrototype.subgroup == "empty-barrel" then
		lib.log("\t\t"..recipeID.." is unbarreling. Ignoring...")
		return
	end

	for _, result in pairs(recipePrototype.products) do
		if result.type == "fluid" then
			lib.appendToArrayInTable(lookup.FluidRecipe, result.name, recipeID)
		else
			lib.appendToArrayInTable(lookup.ItemRecipe, result.name, recipeID)
		end
	end
end
lib.log("\tProcessing recipes")
for recipeID, rawRecipe in pairs(game.recipe_prototypes) do
	processRecipe(recipeID, rawRecipe);
end
--#endregion
--#region Technology Proesssing

---Parses `data.raw.technology` items
---@param technologyID data.TechnologyID
---@param technologyPrototype LuaTechnologyPrototype
local function processTechnology(technologyID, technologyPrototype)
	if technologyPrototype.effects == nil then
		lib.log("\t\t"..technologyID.." didn't unlock anything")
		return
	end

	for _, modifier in pairs(technologyPrototype.effects) do
		if modifier.type == "unlock-recipe" then
			lib.appendToArrayInTable(lookup.RecipeTechnology, modifier.recipe, technologyID)
		end
		-- Theoretically, it can give an item.
		-- TODO: make that a recipe
	end
end
lib.log("\tProcessing technology")
for technologyID, technologyData in pairs(game.technology_prototypes) do
	processTechnology(technologyID, technologyData)
end
--#endregion
--#region Category Processing

---Parses `data.raw.assembling` and `data.raw.furnace` items
---@param EntityID data.EntityID
---@param machinePrototype LuaEntityPrototype
local function processCraftingMachine(EntityID, machinePrototype)
	local machineItem = lib.getEntityItem(EntityID, machinePrototype)
	if not machineItem then return end
	for _, category in pairs(machinePrototype.crafting_categories) do
		lib.appendToArrayInTable(lookup.CategoryItem, category, machineItem)
	end
end
lib.log("\tProcessing crafting categories")
for EntityID, machinePrototype in pairs(game.get_filtered_entity_prototypes{
	{filter = "type", type = "assembling-machine"},
	{filter = "type", type = "furnace"}
}) do
	if machinePrototype.type == "assembling-machine" then
		processCraftingMachine(EntityID, machinePrototype)
	elseif machinePrototype.type == "furnace" then
		processCraftingMachine(EntityID, machinePrototype)
	end
end
-- TODO: figure out how to *properly* check this
-- Add hand-crafting as simplest (first) recipe
lib.prependToArrayInTable(lookup.CategoryItem, "crafting", "hand")

---Parses `data.raw.burner-generator` items
---@param EntityID data.EntityID
---@param machinePrototype LuaEntityPrototype
---@param machineBurner LuaBurnerPrototype
local function processBurnerMachines(EntityID, machinePrototype, machineBurner)
	local burnerItems = lib.getEntityItem(EntityID, machinePrototype)
	for _, burnerItem in ipairs(burnerItems) do
		local categories = machineBurner.fuel_categories
		for category in pairs(categories) do
			lib.appendToArrayInTable(lookup.CategoryItem, "tiergen-fuel-"..category, burnerItem)
		end
	end
end
lib.log("\tProcessing burner categories")
-- Not all the right places to look?
for EntityID, BurnerMachinePrototype in pairs(game.get_filtered_entity_prototypes{
	{filter = "type", type = "burner"},
	{filter = "type", type = "boiler"},
	{filter = "type", type = "reactor"},
}) do
	local burner = BurnerMachinePrototype.burner_prototype
	if burner then
		processBurnerMachines(EntityID, BurnerMachinePrototype, burner)
	end
end

---Processes rocket silos
---@param EntityID data.EntityID
---@param RocketSiloPrototype LuaEntityPrototype
local function processRocketSilos(EntityID, RocketSiloPrototype)
	local itemIDs = lib.getEntityItem(EntityID, RocketSiloPrototype)
	if #itemIDs == 0 then
		return -- Ignore machine if not placeable
	end
	for _, itemID in ipairs(itemIDs) do
		lib.appendToArrayInTable(lookup.CategoryItem, "tiergen-rocket-launch", {itemID})
	end
end
lib.log("\tProcessing rocket silos")
for EntityID, RocketSiloPrototype in pairs(game.get_filtered_entity_prototypes{
	{filter = "type", type = "rocket-silo"}
}) do
	processCraftingMachine(EntityID, RocketSiloPrototype)
	processRocketSilos(EntityID, RocketSiloPrototype)
end
--#endregion
--#region Item Processing

---Parses all items and creates a `recipe` out of the burnt_result
---@param ItemID data.ItemID
---@param itemPrototype LuaItemPrototype
local function processBurningRecipe(ItemID, itemPrototype)
	local result = itemPrototype.burnt_result
	if itemPrototype.fuel_category and result then
		-- Prepend because burning is usually simpler than crafting
		lib.prependToArrayInTable(lookup.ItemRecipe, result.name, "tiergen-burning")
		lib.appendToArrayInTable(lookup.Burning, result.name, ItemID)
	end
end
---Processes an item and creates a 'recipe' out of the rocket results
---@param ItemID data.ItemID
---@param itemPrototype LuaItemPrototype
local function processRocketRecipe(ItemID, itemPrototype)
	local rocket_products = itemPrototype.rocket_launch_products
	for _, product in pairs(rocket_products) do
		local name = product.name
		if not name then
			log("No name found?\n"..serpent.dump(product))
		else
			lib.appendToArrayInTable(lookup.ItemRecipe, name, "tiergen-rocket-launch")
			lib.appendToArrayInTable(lookup.Rocket, name, ItemID)
		end
	end
end
-- ---Parses all item-subtypes
-- ---@param ItemID data.ItemID
-- ---@param itemPrototype LuaItemPrototype
-- local function processItemSubtype(ItemID, itemPrototype)
-- 	if lookup.ItemType[ItemID] then
-- 		error(ItemID.." already assigned a type??")
-- 	end
-- 	lookup.ItemType[ItemID] = itemPrototype.type
-- end
lib.log("\tProcessing items")
for ItemID, itemPrototype in pairs(game.item_prototypes) do
	-- processItemSubtype(ItemID, itemPrototype)
	processBurningRecipe(ItemID, itemPrototype)
	processRocketRecipe(ItemID, itemPrototype)
end
--#endregion

-- TODO: take into account whether a resource generates?

return lookup