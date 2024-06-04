local lookup = require("__tier-generator__.calculation.lookupTables")
local processFunctions = {}

--#region Process functions & loops
--#region Recipe Processing

---Parses `data.raw.recipe` items
---@param recipeID data.RecipeID
---@param recipePrototype LuaRecipePrototype
local function processRecipe(recipeID, recipePrototype)
	if global.config.ignored_recipes[recipeID] then
		return lib.ignore(recipeID, "was in ignored settings.")
	end
	if #recipePrototype.products == 0 then
		lib.log("\t\t"..recipeID.." didn't result in anything?")
		-- lib.log(serpent.line(recipePrototype)) -- Does not print anything useful
		return
	end
	-- Ignore unbarreling recipes
	if recipePrototype.subgroup.name == "empty-barrel" then
		return lib.ignore(recipeID, "is unbarreling.")
	end

	for _, result in pairs(recipePrototype.products) do
		if result.type == "fluid" then
			lib.appendToArrayInTable(lookup.FluidRecipe, result.name, recipeID)
		else
			lib.appendToArrayInTable(lookup.ItemRecipe, result.name, recipeID)
		end
	end
end
processFunctions[#processFunctions+1] = function ()
	lib.log("\tProcessing recipes")
	for recipeID, rawRecipe in pairs(game.recipe_prototypes) do
		processRecipe(recipeID, rawRecipe);
	end
end
--#endregion
--#region Autoplace Processing

-- ---Processes resources
-- ---@param EntityID data.EntityID
-- ---@param Resource LuaEntityPrototype
-- function ProcessMining(EntityID, Resource)
-- 	local mineable = Resource.mineable_properties
-- 	if not mineable.minable then
-- 		return lib.ignore(EntityID, "Is not mineable.")
-- 	end
-- 	local category = Resource.resource_category
-- 	if not category then
-- 		return lib.ignore(EntityID, "has no resource category!?")
-- 	end

-- 	for _, item in ipairs(mineable.products) do
-- 		local recipeLookup = item.type == "item" and lookup.ItemRecipe or lookup.FluidRecipe
-- 		local miningLookup = item.type == "item" and lookup.ItemMining or lookup.FluidMining
-- 		category = "tiergen-mining-"..category
-- 		local altCategory
-- 		if not mineable.required_fluid then
-- 			altCategory = category.."-noinput"
-- 		end
-- 		---@type OptionalFluidFakeRecipe
-- 		local recipe = {
-- 			input = mineable.required_fluid,
-- 			category = altCategory or category
-- 		}
-- 		lib.appendToArrayInTable(recipeLookup, item.name, "tiergen-mining")
-- 		lib.appendToArrayInTable(miningLookup, item.name, recipe)
-- 	end
-- end
---Processes entities placed by autoplace
---@param EntityID data.EntityID
---@param placedEntity LuaEntityPrototype
function ProcessAutoplace(EntityID, placedEntity)
	local autoplace = placedEntity.autoplace_specification
	if not autoplace then
		return lib.ignore(EntityID, "has no autoplace!?")
	end

	local mining = placedEntity.mineable_properties
	if not mining.minable then
		return lib.ignore(EntityID, "is not mineable.")
	end

	local category = placedEntity.resource_category
	local resource_category, player_category
	if category then
		resource_category = "tiergen-mining-"..category
		player_category = "tiergen-hand-mining-"..category
	else
		player_category = "hand"
	end

	for _, item in ipairs(mining.products or {}) do
		local recipeLookup = item.type == "item" and lookup.ItemRecipe or lookup.FluidRecipe
		local miningLookup = item.type == "item" and lookup.ItemMining or lookup.FluidMining
		if category then
			lib.appendToArrayInTable(recipeLookup, item.name, "tiergen-mining")
			lib.appendToArrayInTable(miningLookup, item.name, {
				input = mining.required_fluid,
				category = resource_category
			})
		end
		if item.type == "item" and not mining.required_fluid then
			lib.appendToArrayInTable(recipeLookup, item.name, "tiergen-hand-mining")
			lib.appendToArrayInTable(lookup.HandMining, item.name, player_category)
		end
	end
end
processFunctions[#processFunctions+1] = function ()
	lib.log("\tProcessing autoplace resources")
	for EntityID, entityPrototype in pairs(game.get_filtered_entity_prototypes{
---@diagnostic disable-next-line: missing-fields
		{filter = "autoplace"}
	}) do
		ProcessAutoplace(EntityID, entityPrototype)
	end
end
--#endregion
--#region Technology Processing

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
processFunctions[#processFunctions+1] = function ()
	lib.log("\tProcessing technology")
	for technologyID, technologyData in pairs(game.technology_prototypes) do
		processTechnology(technologyID, technologyData)
	end
end
--#endregion
--#region Crafting Machines

---Parses `data.raw.assembling` and `data.raw.furnace` items
---@param EntityID data.EntityID
---@param machinePrototype LuaEntityPrototype
local function processCraftingMachine(EntityID, machinePrototype)
	local machineItems = lib.getEntityItem(EntityID, machinePrototype)
	if #machineItems == 0 then return end
	for _,machineItem in pairs(machineItems) do
		for category in pairs(machinePrototype.crafting_categories) do
			lib.appendToArrayInTable(lookup.CategoryItem, category, machineItem.name)
		end
	end
end
processFunctions[#processFunctions+1] = function ()
	lib.log("\tProcessing crafting categories")
	for EntityID, machinePrototype in pairs(game.get_filtered_entity_prototypes{
		{filter = "type", type = "assembling-machine"},
		{filter = "type", type = "furnace"}
	}) do
		processCraftingMachine(EntityID, machinePrototype)
	end
end
--#endregion
--#region Miners

---Processes miners for what they can mine
---@param EntityID data.EntityID
---@param Miner LuaEntityPrototype
function ProcessMiners(EntityID, Miner)
	local categories = Miner.resource_categories
	if not categories then
		return lib.ignore(EntityID, "can't mine any resources.")
	end

	local items = lib.getEntityItem(EntityID, Miner)
	if #items == 0 then
		return lib.noItems(EntityID)
	end

	for _, item in ipairs(items) do
		for category in pairs(categories) do
			-- Two fake categories so we can keep hand-mining separate from recipes that take fluid
			lib.appendToArrayInTable(lookup.CategoryItem, "tiergen-mining-"..category, item.name)
			lib.appendToArrayInTable(lookup.CategoryItem, "tiergen-mining-"..category.."-noinput", item.name)
		end
	end
end
processFunctions[#processFunctions+1] = function ()
	lib.log("\tProcessing miners")
	for EntityID, entityPrototype in pairs(game.get_filtered_entity_prototypes{
		{filter = "type", type = "mining-drill"}
	}) do
		ProcessMiners(EntityID, entityPrototype)
	end
end
--#endregion
--#region Character Crafting/Mining

---Processes a character prototype and adds the "hand" machine to its crafting_categories
---@param EntityID data.EntityID
---@param CharacterPrototype LuaEntityPrototype
local function processCharacterCrafting(EntityID, CharacterPrototype)
	local categories = CharacterPrototype.crafting_categories
	if not categories then
		return lib.ignore(EntityID, "cannot craft.")
	end

	for category in pairs(categories) do
		lib.prependToArrayInTable(lookup.CategoryItem, category, "hand")
	end
end
---Processes a character prototype and adds the "hand" machine to its crafting_categories
---@param EntityID data.EntityID
---@param CharacterPrototype LuaEntityPrototype
local function processCharacterMining(EntityID, CharacterPrototype)
	local categories = CharacterPrototype.resource_categories
	if not categories then
		return lib.ignore(EntityID, "can't mine any ores.")
	end

	for category in pairs(categories) do
		lib.prependToArrayInTable(lookup.CategoryItem, "tiergen-hand-mining-"..category, "hand")
	end
end
processFunctions[#processFunctions+1] = function ()
	lib.log("\tProcessing CharacterPrototypes")
	for EntityID, EntityPrototype in pairs(game.get_filtered_entity_prototypes{
		{filter = "type", type = "character"}
	}) do
		if EntityID ~= "character" then
			lib.log("\t\t"..EntityID.." is a custom CharacterPrototype")
			-- Maybe return to discard custom CharacterPrototypes?
		end
		processCharacterCrafting(EntityID, EntityPrototype)
		processCharacterMining(EntityID, EntityPrototype)
	end
end
--#endregion
--#region Burner Machines

---Parses `data.raw.burner-generator` items
---@param EntityID data.EntityID
---@param machinePrototype LuaEntityPrototype
---@param machineBurner LuaBurnerPrototype
local function processBurnerMachines(EntityID, machinePrototype, machineBurner)
	local burnerItems = lib.getEntityItem(EntityID, machinePrototype)
	for _, burnerItem in ipairs(burnerItems) do
		local categories = machineBurner.fuel_categories
		for category in pairs(categories) do
			lib.appendToArrayInTable(lookup.CategoryItem, "tiergen-fuel-"..category, burnerItem.name)
		end
	end
end
processFunctions[#processFunctions+1] = function ()
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
end
--#endregion
--#region Rocket Silos

---Processes rocket silos
---@param EntityID data.EntityID
---@param RocketSiloPrototype LuaEntityPrototype
local function processRocketSilos(EntityID, RocketSiloPrototype)
	local fixed_recipe = RocketSiloPrototype.fixed_recipe
	if not fixed_recipe then
		return lib.ignore(EntityID, "doesn't have a set rocket recipe?")
	end
	local rocket_parts = lib.getRecipe(fixed_recipe).products
	if #rocket_parts ~= 1 then
		return lib.ignore(EntityID, "has more than one product to its fixed_recipe?")
	end

	local itemIDs = lib.getEntityItem(EntityID, RocketSiloPrototype)
	if #itemIDs == 0 then
		return -- Ignore machine if not placeable
	end

	for _, itemID in ipairs(itemIDs) do
		lib.appendToArrayInTable(lookup.CategoryItem, "tiergen-rocket-launch", rocket_parts[1].name)
	end
end
processFunctions[#processFunctions+1] = function ()
	lib.log("\tProcessing rocket silos")
	for EntityID, RocketSiloPrototype in pairs(game.get_filtered_entity_prototypes{
		{filter = "type", type = "rocket-silo"}
	}) do
		processCraftingMachine(EntityID, RocketSiloPrototype)
		processRocketSilos(EntityID, RocketSiloPrototype)
	end
end
--#endregion
--#region Boilers

---Processes boiler prototypes
---@param BoilerID data.EntityID
---@param boilerPrototype LuaEntityPrototype
local function processBoilers(BoilerID, boilerPrototype)
	local fluidboxes = boilerPrototype.fluidbox_prototypes
	if #fluidboxes ~= 2 then
		return lib.ignore(BoilerID, "is not a standard boiler?")
	end
	local input = fluidboxes[1].filter
	local output = fluidboxes[2].filter

	if not input or not output then
		return lib.ignore(BoilerID, "fluidboxes aren't filtered?")
	end

	local entityItems = lib.getEntityItem(BoilerID, boilerPrototype)
	if #entityItems == 0 then
		return lib.noItems(BoilerID)
	end

	lib.appendToArrayInTable(lookup.FluidRecipe, output.name, "tiergen-boil")
	lib.appendToArrayInTable(lookup.Boiling, output.name, {
		input = input.name,
		category = "tiergen-boil-"..BoilerID,
	})
	for _, entityItem in ipairs(entityItems) do
		lib.appendToArrayInTable(lookup.CategoryItem, "tiergen-boil-"..BoilerID, entityItem.name)
	end
end
processFunctions[#processFunctions+1] = function ()
	lib.log("\tProcessing boiler recipes")
	for boilerID, boilerPrototype in pairs(game.get_filtered_entity_prototypes{
		{filter = "type", type = "boiler"},
	}) do
		processBoilers(boilerID, boilerPrototype)
	end
end
--#endregion
--#region Offshore Pumps

---Processes offshore pumps to make them a recipe
---@param PumpID data.EntityID
---@param pumpPrototype LuaEntityPrototype
local function processOffshorePumps(PumpID, pumpPrototype)
	local fluid = pumpPrototype.fluid
	if not fluid then
		return lib.ignore(PumpID, "has no fluid output!?")
	end

	local items = lib.getEntityItem(PumpID, pumpPrototype)
	if #items == 0 then
		return lib.noItems(PumpID)
	end

	lib.appendToArrayInTable(lookup.FluidRecipe, fluid.name, "tiergen-offshore-pump")
	lib.appendToArrayInTable(lookup.OffshorePumping, fluid.name, "tiergen-pump-"..PumpID)
	for _, item in ipairs(items) do
		lib.appendToArrayInTable(lookup.CategoryItem, "tiergen-pump-"..PumpID, item.name)
	end
end
processFunctions[#processFunctions+1] = function ()
	lib.log("\tProcessing offshore pumps")
	for EntityID, entityPrototype in pairs(game.get_filtered_entity_prototypes{
		{filter = "type", type = "offshore-pump"}
	}) do
		processOffshorePumps(EntityID, entityPrototype)
	end
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
		local name = product.name or product[1]
		if not name then
			log("No name found?\n"..serpent.dump(product))
		else
			lib.appendToArrayInTable(lookup.ItemRecipe, name, "tiergen-rocket-launch")
			lib.appendToArrayInTable(lookup.Rocket, name, ItemID)
		end
	end
end
processFunctions[#processFunctions+1] = function ()
	lib.log("\tProcessing items")
	for ItemID, itemPrototype in pairs(game.item_prototypes) do
		-- processItemSubtype(ItemID, itemPrototype)
		processBurningRecipe(ItemID, itemPrototype)
		processRocketRecipe(ItemID, itemPrototype)
	end
end
--#endregion
--#endregion

local hasReturned = false
return {
	process = function ()
		if not hasReturned then
			lib.log("Processing prototypes")
			for _, processFunction in ipairs(processFunctions) do
				processFunction()
			end
			hasReturned = true
		end
		return lookup
	end,
	unprocess = function ()
		for key in pairs(lookup) do
			lookup[key] = {}
		end
		hasReturned = false
	end
}