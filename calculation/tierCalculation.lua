local processor = require("__tier-generator__.calculation.DataProcessing")
lookup = nil ---@type LookupTables
local lib = require("__tier-generator__.library")

---@alias fakeCategory "LuaRecipeCategoryPrototype"
---@alias fakeRecipes "burning"|"rocket-launch"|"boil"|"offshore-pump"
---@alias handledPrototypes LuaRecipeCategoryPrototype|LuaTechnologyPrototype|LuaRecipePrototype|LuaFluidPrototype|LuaItemPrototype
---@alias tierSwitchValues handledPrototypes|fakeCategory|fakeRecipes
---@alias tierSwitchTypes LuaObject.object_name|fakeRecipes

---@enum invalidReason
invalidReason = {
	calculating = -1,
	no_valid_machine = -2,
	no_valid_technology = -3,
	no_valid_furnace = -4,
	no_valid_rocket = -5,
	no_valid_recipe = -6,
	no_valid_boiler = -7,
	no_valid_offshore_pump = -8,
	not_unlockable = -97,
	no_machine = -98,
	error = -99,
	not_an_item = -100,
}
for key, value in pairs(invalidReason) do
	invalidReason[value] = key
end
setmetatable(invalidReason, {
	__index = function(self, key)
		return rawget(self, key) or "unknown"
	end
})
---@alias tier invalidReason|uint

---@class tierTableItem
---@field name string
---@field tier uint
---@class tierTable
---@field ["item"] tierTableItem[]
---@field ["fluid"] tierTableItem[]
---@class tierArrayItem
---@field name string
---@field type "item"|"fluid"
---@class tierArray
---@field [uint] tierArrayItem[]

---@class dependency
---@field type tierSwitchTypes
---@field id string
---@class tierEntry
---@field tier uint
---@field dependencies dependency[]
---@class tierMap
---@field [string] tierEntry
---@type {[tierSwitchTypes]:tierMap}
TierMaps = {};
---@type {[string]:boolean}
local baseOverride = {};
---@type table<tierSwitchTypes,{[string]:boolean}>
calculating = {};
---@class blockedReason: dependency
---@field type tierSwitchTypes
---@field id string
---@field reason invalidReason
---@type table<tierSwitchTypes,table<string,{reason:invalidReason,blocked:dependency[]}>>
incalculable = {}

---Takes the given table of tierSwitchTypes to arrays and resets them
---@param ... table<tierSwitchTypes,any>
local function resetTierMapTables(...)
	local prototypes = {
		"LuaRecipeCategoryPrototype",
		"LuaTechnologyPrototype",
		"LuaRecipePrototype",
		"LuaFluidPrototype",
		"LuaItemPrototype",
		"burning",
		"rocket-launch",
		"boil",
		"offshore-pump",
	}
	for _, prototype in ipairs(prototypes) do
		for _, table in ipairs{...} do
			table[prototype] = {}
		end
	end
end

---Clears the incalculable table for the given item and what it blocked
---@param type tierSwitchTypes
---@param prototypeID string
local function unmarkIncalculable(type, prototypeID)
	local incalculableItem = incalculable[type][prototypeID]
	if not incalculableItem then
		return lib.log("\tLikely was incalculable?? type: "..type.." id: "..prototypeID)
	end
	if incalculableItem.reason == invalidReason.error
	or incalculableItem.reason == invalidReason.no_machine
	or incalculableItem.reason == invalidReason.not_unlockable then
		return lib.log("\tWill not unmark an item marked invalid for a static reason. type: "..type.." id: "..prototypeID)
	end
	incalculable[type][prototypeID] = nil
	for _, nextItem in ipairs(incalculableItem.blocked) do
		unmarkIncalculable(nextItem.type, nextItem.id)
	end
end

--#region Tier calculation
---@class TierSwitch
---@field [tierSwitchTypes] fun(prototypeID:string, value:tierSwitchValues):tier,blockedReason[]
---@overload fun(prototypeID:string,value:tierSwitchValues):tier
local tierSwitch = setmetatable({}, {
	---Base switching case of tierSwitch
	---@param self TierSwitch
	---@param prototypeID string
	---@param value tierSwitchValues
	---@return tier
	__call = function(self, prototypeID, value)
		local type
		if lib.type(value) == "string" then
			---@cast value string
			type = value
		else
			---@cast value handledPrototypes
			type = value.object_name
		end

		local tier = TierMaps[type][prototypeID]
		if tier ~= nil then return tier.tier end
		if type == "LuaItemPrototype" and baseOverride[prototypeID] then
			TierMaps[type][prototypeID] = {
				tier = 0,
				dependencies = {}
			}
			return 0
		end
		if calculating[type][prototypeID] then return invalidReason.calculating end
		local incalculableItem = incalculable[type][prototypeID]
		if incalculableItem then -- and incalculableItem.reason ~= invalidReason.calculating then
			return incalculableItem.reason
		end

		-- Attempt to calculate
		calculating[type][prototypeID] = true
		lib.debug("Starting to calculate "..type..":"..prototypeID)
		local success, result, dependencies = false, -math.huge, {}
		success, result, dependencies = pcall(self[type], prototypeID, value)
		if not success then
			-- _log({"error-calculating", prototypeID, type, serpent.dump(value)})
			lib.log("Error calculating the "..type.." of "..prototypeID..":\n"..result)
			result = invalidReason.error
			dependencies = {}
		end
		lib.debug("Done calculating "..type..":"..prototypeID.." with a tier of "..result.." or error "..invalidReason[result])
		tier = {
			tier = result,
			dependencies = dependencies
		}

		-- Finish calculating
		calculating[type][prototypeID] = nil
		if result >= 0 then -- Discard negative values
			TierMaps[type][prototypeID] = tier
			-- if type == "LuaFluidPrototype" or type == "LuaItemPrototype" then
			-- 	local itemType = (type == "LuaItemPrototype") and "item" or "fluid"
			-- 	lib.appendToArrayInTable(tierArray, tier+1, {
			-- 		name = prototypeID,
			-- 		type = itemType,
			-- 	})
			-- end

			--Remove blocked items, if it was marked incalculable during calculating
			incalculableItem = incalculable[type][prototypeID]
			if incalculableItem then
				unmarkIncalculable(type, prototypeID)
			end
		else -- Mark as incalculable
			incalculable[type][prototypeID] = {
				reason = tier.tier,
				blocked = {}
			}
			for _, reason in ipairs(dependencies) do
				incalculableItem = incalculable[reason.type][reason.id]
				if not incalculableItem then
					if reason.reason ~= invalidReason.calculating then
						lib.log("\tMarking "..reason.id.." as incalculable because "..reason.reason)
					end
					incalculableItem = {
						reason = reason.reason,
						blocked = {}
					}
					incalculable[reason.type][reason.id] = incalculableItem

				-- Lower numbers are more static reasons and therefore more important
				elseif incalculableItem.reason > reason.reason then
					incalculableItem.reason = reason.reason
				end
				incalculableItem.blocked[#incalculableItem.blocked+1] = {
					type = type,
					id = prototypeID
				}
			end
		end
		return tier.tier
	end
})

---Like calling tierSwitch but without having to handle the dependency
---@param id string
---@param value tierSwitchValues
---@param blockedArray blockedReason[]
---@param dependencyArray dependency[]
local function resolveTierWithDependency(id, value, dependencyArray, blockedArray)
	local tier = tierSwitch(id, value)
	local dependency = {
		type = type(value) == "table" and value.object_name or value,
		id = id
	}
	if tier < 0 then
		---@cast dependency blockedReason
		dependency.reason = tier
		blockedArray[#blockedArray+1] = dependency
	else
		dependencyArray[#dependencyArray+1] = dependency
	end
	return tier
end

---Return the highest tier from the ingredients
---Adds each ingredient to dependencies if valid,
---or returns after adding to blocked if its not. 
---@param ingredients Ingredient[]
---@param dependencies dependency[]
---@param blocked blockedReason[]
---@return integer
local function getIngredientsTier(ingredients, dependencies, blocked)
	local ingredientsTier = 0;
	---@type dependency[]
	for _, ingredient in pairs(ingredients) do
		local itemName = ingredient.name or ingredient[1]
		local itemType = ingredient.type or "item"
		local itemPrototype = lib.getItemOrFluid(itemName, itemType)
		local itemTier = resolveTierWithDependency(
			itemName, itemPrototype, dependencies, blocked
		)
		if itemTier < 0 then
			return itemTier
		end
		ingredientsTier = math.max(ingredientsTier, itemTier)
	end
	return ingredientsTier
end

---Does everything that both real and all fake recipes require
---@param ingredients Ingredient[]
---@param category string
---@param blocked blockedReason[]
---@param callback (fun(p1:dependency[]):tier)?
---@return tier
---@return dependency[]?
local function doRecipe(ingredients, category, blocked, callback)
	---@type dependency[]
	local dependencies = {}

	local ingredientsTier = getIngredientsTier(ingredients, dependencies, blocked)
	if ingredientsTier < 0 then return ingredientsTier end
	local categoryTier = resolveTierWithDependency(
		category, "LuaRecipeCategoryPrototype", dependencies, blocked
	)
	if categoryTier < 0 then return categoryTier end
	local customTier = callback and callback(dependencies) or 0
	if customTier < 0 then return customTier end

	if #ingredients ~= 0 then
		ingredientsTier = ingredientsTier + 1
	end

	return math.max(ingredientsTier, categoryTier, customTier), dependencies
end

---Determine the tier of burning an item
---@type fun(ItemID:data.ItemID,_:LuaItemPrototype):tier,blockedReason[]|dependency[]
tierSwitch["burning"] = function (ItemID, _)
	local burningRecipes = lookup.Burning[ItemID]
	---@type blockedReason[]
	local blockedBy = {}

	local tier, dependencies = lib.getMinTierArray(
		burningRecipes, invalidReason.no_valid_furnace,
		function (fuelID)
			local fuel = lib.getItem(fuelID)
			return doRecipe(
				{{fuelID}},
				"tiergen-fuel-"..fuel.fuel_category,
				blockedBy
			)
		end
	)
	if tier < 0 then
		return tier, blockedBy
	else
		---@cast dependencies dependency[]
		return tier, dependencies
	end
end
---Determine the tier of launching an item into space
---@type fun(ItemID:data.ItemID,_:LuaItemPrototype):tier,blockedReason[]|dependency[]
tierSwitch["rocket-launch"] = function (ItemID, _)
	local rocketRecipes = lookup.Rocket[ItemID]
	---@type blockedReason[]
	local blockedBy = {}

	local tier, dependencies = lib.getMinTierArray(
		rocketRecipes, invalidReason.no_valid_rocket,
		function (satellite)
			return doRecipe(
				{{satellite}},
				"tiergen-rocket-launch",
				blockedBy
			)
		end
	)

	if tier < 0 then
		return tier, blockedBy
	else
		---@cast dependencies dependency[]
		return tier, dependencies
	end
end
---Determine the tier of boiling a liquid
---@type fun(FluidID:data.FluidID,_:LuaFluidPrototype):tier,blockedReason[]|dependency[]
tierSwitch["boil"] = function (FluidID,_)
	local recipes = lookup.Boiling[FluidID]
	---@type blockedReason[]
	local blockedBy = {}

	local tier, dependencies = lib.getMinTierArray(
		recipes, invalidReason.no_valid_boiler,
		function (recipe)
			return doRecipe(
				{
					{name = recipe.input, type = "fluid"}
				},
				recipe.category,
				blockedBy
			)
		end
	)
	if tier < 0 then
		return tier, blockedBy
	else
		---@cast dependencies dependency[]
		return tier, dependencies
	end
end
---Determine the tier of pumping fluid out of a lake
---@type fun(FluidID:data.FluidID,_:LuaFluidPrototype):tier,blockedReason[]|dependency[]
tierSwitch["offshore-pump"] = function (FluidID, _)
	local recipes = lookup.OffshorePumping[FluidID]
	---@type blockedReason[]
	local blockedby = {}

	local tier, dependencies = lib.getMinTierArray(
		recipes, invalidReason.no_valid_offshore_pump,
		function (recipe)
			return doRecipe(
				{}, -- No ingredients
				recipe,
				blockedby
			)
		end
	)
	if tier < 0 then
		return tier, blockedby
	else
		---@cast dependencies dependency[]
		return tier, dependencies
	end
end

---Determine the tier of the given technology
---@type fun(technologyID:data.TechnologyID,technology:LuaTechnologyPrototype):tier,blockedReason[]|dependency[]
tierSwitch["LuaTechnologyPrototype"] = function (technologyID, technology)
	---@type dependency[]
	local dependencies = {}
	---@type blockedReason[]
	local blockedBy = {}

	local ingredients = technology.research_unit_ingredients
	local ingredientsTier = getIngredientsTier(ingredients, dependencies, blockedBy)
	if ingredientsTier < 0 then
		return ingredientsTier, blockedBy
	end

	local prereqTier = 0;
	for _, prerequisite in pairs(technology.prerequisites) do
		local preTier = resolveTierWithDependency(
			prerequisite.name, prerequisite, dependencies, blockedBy
		)
		if preTier < 0 then
			return preTier, blockedBy
		end
		prereqTier = math.max(prereqTier, preTier)
	end

	if ingredientsTier > 0 and not lib.getSetting("tiergen-reduce-technology") then
		-- Used to be subtraction, but a refactor now implicitly does this.
		-- now the opposite of the setting determines if we undo it
		ingredientsTier = ingredientsTier + 1
	end
	local tier = math.max(ingredientsTier, prereqTier)
	if tier == 0 then
		lib.log("I don't think a technology should ever be t0: "..technologyID)
	end
	return tier, dependencies
end
---Determine the tier of the given recipe category
---@type fun(CategoryID:data.RecipeCategoryID):tier,blockedReason[]|dependency[]
tierSwitch["LuaRecipeCategoryPrototype"] = function (CategoryID)
	local machines = lookup.CategoryItem[CategoryID]
	if not machines then
		lib.log("\tCategory "..CategoryID.." has no machines")
		return invalidReason.no_machine, {}
	end
	---@type blockedReason[]
	local blockedBy = {}
	local tier, dependencies = lib.getMinTierArray(
		machines, invalidReason.no_valid_machine,
		function (item)
			---@type dependency[]
			local dependencies = {}
			if item == "hand" then
				return 0, {}
			end
			local tier = resolveTierWithDependency(
				item, lib.getItem(item), dependencies, blockedBy
			)
			return tier, dependencies
		end
	)
	if tier < 0 then
		return tier, blockedBy
	end
	---@cast dependencies dependency[]

	if lib.getSetting("tiergen-reduce-category") and tier > 0 then
		tier = tier - 1
	end
	return tier, dependencies
end
---Determine the tier of the given recipe
---@type fun(recipeID:data.RecipeID,recipe:LuaRecipePrototype):tier,blockedReason[]|dependency[]
tierSwitch["LuaRecipePrototype"] = function (recipeID, recipe)
	---@type blockedReason[]
	local blockedBy = {}

	local considerTechnology
	if lib.getSetting("tiergen-consider-technology") and not recipe.enabled then
		local technologies = lookup.RecipeTechnology[recipeID]
		if not technologies then
			print("\t"..recipeID.." is not an unlockable recipe.")
			return invalidReason.not_unlockable, {}
		end
		---@type (fun(p1:dependency[]):tier)?
		considerTechnology = function (dependencies)
			local tier, techDependencies = lib.getMinTierArray(
				technologies, invalidReason.no_valid_technology,
				function (technologyID)
					local technology = lib.getTechnology(technologyID)
					---@type dependency[]
					local techDependencies = {}
					local technologyTier = resolveTierWithDependency(
						technologyID, technology, techDependencies, blockedBy
					)
					return technologyTier, techDependencies
				end
			)
			if tier >= 0 then
				---@cast techDependencies dependency[]
				for _, tech in ipairs(techDependencies) do
					dependencies[#dependencies+1] = tech
				end
			end
			return tier
		end
	end

	local recipeTier, dependencies = doRecipe(
		recipe.ingredients, recipe.category, blockedBy,
		considerTechnology
	)

	if recipeTier < 0 then
		return recipeTier, blockedBy
	else
		---@cast dependencies dependency[]
		return recipeTier, dependencies
	end
end
---Determine the tier of the given item or fluid
---@type fun(ItemID:data.ItemID|data.FluidID,value:LuaItemPrototype|LuaFluidPrototype):tier,blockedReason[]|dependency[]
tierSwitch["LuaFluidPrototype"] = function (ItemID, value)
	local recipes
	if value.object_name == "LuaItemPrototype" then
		recipes = lookup.ItemRecipe[ItemID]
	else
		recipes = lookup.FluidRecipe[ItemID]
	end
	---@type blockedReason[]
	local blockedBy = {}

	-- No recipes create it, then it's a base resource
	-- TODO: remove once all (determinable) ways of getting a base item is accounted for
	if not recipes then return 0, {} end


	local tier, dependencies = lib.getMinTierArray(
		recipes, invalidReason.no_valid_recipe,
		function (recipe)
			---@type dependency[]
			local dependencies = {}

			local _, realstart = recipe:find("^tiergen[-]")
			local id, prototype
			if realstart then
				id = ItemID
				prototype = recipe:sub(realstart+1)
			else
				id = recipe
				prototype = lib.getRecipe(recipe)
			end

			local tier = resolveTierWithDependency(
				id, prototype, dependencies, blockedBy
			)
			return tier, dependencies
		end
	)

	if tier < 0 then
		return tier, blockedBy
	else
		---@cast dependencies dependency[]
		return tier, dependencies
	end
end
tierSwitch["LuaItemPrototype"] = tierSwitch["LuaFluidPrototype"] --[[@as fun(ItemID:data.ItemID|data.FluidID,value:LuaItemPrototype|LuaFluidPrototype):tier,blockedReason[]|dependency[] ]]
--#endregion

local function checkLookup()
	if not lookup then
		lookup = processor.process()
	end
end

---Calculates the tier of a given itemID
---@param itemID string
---@return uint
local function calculateTier(itemID)
	checkLookup()
	local isValid, itemPrototype = pcall(lib.getItem, itemID)
	if not isValid then
		lib.log("\tWas given an invalid item: "..itemID)
		return invalidReason.not_an_item
	end
	local tier = tierSwitch(itemID, itemPrototype)
	if tier < 0 then
		lib.log("Failed to calculate "..itemID.."'s tier")
		lib.debug(serpent.dump(incalculable))
	else
		lib.log("\t"..itemID..": Tier "..tier)
	end
	return tier
end

---Takes an item and turns it into a table of item/fluid tiers
---@param dependency dependency
---@param table tierTable
---@param processed table<tierSwitchTypes,{[string]:boolean}>
local function resolveDependencies(dependency, table, processed)
	local item = TierMaps[dependency.type][dependency.id]
	if processed[dependency.type][dependency.id] then return end
	if dependency.type == "LuaFluidPrototype"
	or dependency.type == "LuaItemPrototype" then
		local type = dependency.type == "LuaFluidPrototype" and "fluid" or "item"
		lib.appendToArrayInTable(table, type, {
			name = dependency.id,
			tier = item.tier,
		})
	end
	processed[dependency.type][dependency.id] = true
	for _, dependency in ipairs(item.dependencies) do
		resolveDependencies(dependency, table, processed)
	end
end

---Turns a table of resolved dependencies into a tier array
---@param dependencies tierTable
---@return tierArray
local function depenenciesToArray(dependencies)
	---@type tierArray
	local tierArray = {}
	for _, type in ipairs({"item","fluid"}) do
		if not dependencies[type] then goto continue end
		for _, tierItem in ipairs(dependencies[type]) do
			lib.appendToArrayInTable(tierArray, tierItem.tier+1, {
				name = tierItem.name,
				type = type,
			})
		end
    ::continue::
	end
	return tierArray
end

---Directly set the tier of a given itemID
---@param itemID string
local function setTier(itemID)
	checkLookup()
	local isValid, itemPrototype = pcall(lib.getItem, itemID)
	if not isValid then
		lib.log("\tWas given an invalid item: "..itemID)
		return
	end
	baseOverride[itemID] = true
end

---Clears the working tables
local function uncalculate()
	baseOverride = {}
	resetTierMapTables(TierMaps, calculating, incalculable)
	-- for _, prototype in ipairs(prototypes) do
	-- 	TierMaps[prototype] = {}
	-- 	calculating[prototype] = {}
	-- 	incalculable[prototype] = {}
	-- end
end

---comment
---@param itemIDs data.ItemID[]
---@return tierArray
local function getTier(itemIDs)
	local table, processed = {},{}
	resetTierMapTables(processed)
	for _, itemID in ipairs(itemIDs) do
		local tier = calculateTier(itemID)
		if tier >= 0 then
			resolveDependencies({
				type = "LuaItemPrototype",
				id = itemID
			}, table, processed)
		end
	end
	return depenenciesToArray(table)
end

return {
	set = setTier,
	unset = uncalculate,
	calculate = calculateTier,
	get = getTier,
	reprocess = function ()
		processor.unprocess()
---@diagnostic disable-next-line: cast-local-type
		lookup = nil
	end
}