local processor = require("__tier-generator__.calculation.DataProcessing")
lookup = nil ---@type LookupTables

---@alias fakeRecipes "mining"|"hand-mining"|"burning"|"rocket-launch"|"boil"|"offshore-pump"
---@class fakePrototype : LuaObject
---@field object_name fakeRecipes|"LuaRecipeCategoryPrototype"
---@field real_object_name LuaObject.object_name
---@alias handledPrototypes LuaRecipeCategoryPrototype|LuaTechnologyPrototype|LuaRecipePrototype|LuaFluidPrototype|LuaItemPrototype
---@alias tierSwitchValues fakePrototype|handledPrototypes
---@alias tierSwitchTypes fakeRecipes|LuaObject.object_name

---@enum invalidReason
invalidReason = {
	busy_calculating = -1,
	no_valid_machine = -2,
	no_valid_technology = -3,
	no_valid_miner = -4,
	no_valid_furnace = -5,
	no_valid_rocket = -6,
	no_valid_recipe = -7,
	no_valid_boiler = -8,
	no_valid_offshore_pump = -9,
	no_valid_injection = -10,
	not_player_mineable = -94,
	not_unlockable = -95,
	ignored_recipe = -96,
	no_recipe = -97,
	no_machine = -98,
	error = -99,
	not_an_item = -100,
}
for key, value in pairs(invalidReason) do
---@diagnostic disable-next-line: no-unknown
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
---@field isDirect boolean
---@class tierTable
---@field ["item"] tierTableItem[]
---@field ["fluid"] tierTableItem[]
---@class simpleItem
---@field name string
---@field type "item"|"fluid"
---@field count integer?
-- ---@field isDirect boolean
---@class tierArray
---@field [uint] simpleItem[]

---@class dependency
---@field type tierSwitchTypes
---@field id string
---@class tierEntry
---@field tier uint
---@field type tierSwitchTypes
---@field id string
---@field dependencies dependency[]
---@class tierMap
---@field [string] tierEntry
---@type {[tierSwitchTypes]:tierMap}
TierMaps = {};
---@type table<tierSwitchTypes,{[string]:boolean}>
calculating = {};
---@class blockedReason: dependency
---@field type tierSwitchTypes
---@field id string
---@field reason invalidReason
---@type table<tierSwitchTypes,table<string,{reason:invalidReason,blocked:dependency[]}>>
incalculable = {}
lib.initTierMapTables(TierMaps, calculating, incalculable)

---Clears the incalculable table for the given item and what it blocked
---@param type tierSwitchTypes
---@param prototypeID string
local function unmarkIncalculable(type, prototypeID)
	local incalculableItem = incalculable[type][prototypeID]
	if not incalculableItem then
		return -- Already marked calculable
	end
	if incalculableItem.reason <= invalidReason.not_player_mineable then
		return lib.debug("\tWill not unmark an item marked invalid for a static reason. type: "..type.." id: "..prototypeID)
	end
	incalculable[type][prototypeID] = nil
	for _, nextItem in ipairs(incalculableItem.blocked) do
		unmarkIncalculable(nextItem.type, nextItem.id)
	end
end

---Takes the given dependency graph and resolves down to just items
---@param dependencies dependency[]
---@return dependency[]
local function resolve_to_items(dependencies)
	---@type dependency[], table<string,true>
	local new_dependencies, dependency_lookup = {}, {}
	for _, dependency in pairs(dependencies) do
		if not dependency then goto continue end

		if dependency.type ~= "LuaItemPrototype"
		and dependency.type ~= "LuaFluidPrototype" then
			for _, new_dependency in pairs(TierMaps[dependency.type][dependency.id].dependencies) do
				-- Add if not already added
				if new_dependency and not dependency_lookup[new_dependency.type..new_dependency.id] then
					new_dependencies[#new_dependencies+1] = new_dependency
					dependency_lookup[new_dependency.type..new_dependency.id] = true
				end
			end
		-- Add if not already added
		elseif not dependency_lookup[dependency.type..dependency.id] then
			new_dependencies[#new_dependencies+1] = dependency
			dependency_lookup[dependency.type..dependency.id] = true
		end
		::continue::
	end
	return new_dependencies
end


--#region Tier calculation
---@class TierSwitch
---@field [tierSwitchTypes] fun(prototypeID:string, value:tierSwitchValues):tier,blockedReason[]
local tierSwitch = {}

---Base switching case of tierSwitch
---@param prototypeID string
---@param value tierSwitchValues
---@return tier
local function CallTierSwitch(prototypeID, value)
	local type = value.object_name

	local tier = TierMaps[type][prototypeID]
	if tier ~= nil then return tier.tier end
	if calculating[type][prototypeID] then return invalidReason.busy_calculating end
	local incalculableItem = incalculable[type][prototypeID]
	if incalculableItem then -- and incalculableItem.reason ~= invalidReason.calculating then
		return incalculableItem.reason
	end

	-- Attempt to calculate
	calculating[type][prototypeID] = true
	-- lib.debug("Starting to calculate "..type..":"..prototypeID)
	---@type integer, dependency[]|blockedReason[]
	local result, dependencies = tierSwitch[type](prototypeID, value)
	-- lib.debug("Done calculating "..type..":"..prototypeID.." with a tier of "..result.." or error "..invalidReason[result])

	-- Finish calculating
	calculating[type][prototypeID] = nil
	if result >= 0 then -- Discard negative values
		tier = {
			tier = result,
			dependencies = resolve_to_items(dependencies),
			type = type,
			id = prototypeID
		} --[[@as tierEntry]]
---@diagnostic disable-next-line: cast-local-type
		dependencies = nil -- Memory management?
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
		local alreadyIncalculable = incalculable[type][prototypeID]
		if not alreadyIncalculable then
			incalculable[type][prototypeID] = {
				reason = result,
				blocked = {}
			}
		else
			alreadyIncalculable.reason = math.min(result, alreadyIncalculable.reason)
		end
		for _, reason in ipairs(dependencies) do
			incalculableItem = incalculable[reason.type][reason.id]
			if not incalculableItem then
				if reason.reason ~= invalidReason.busy_calculating then
					lib.debug("\tMarking "..reason.id.." as incalculable because "..reason.reason)
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
	return result
end

---@type table<string,dependency>
local dependencyCache = setmetatable({}, {__mode = "v"})
---@param id string
---@param type LuaObject.object_name
---@return dependency
local function getDependency(id, type)
	---@type string
	local lookup_string = type..id
	local dependency = dependencyCache[lookup_string]

	if dependency then
		return dependency
	end

	---@type dependency
	dependency = {
		type = type,
		id = id
	}
	dependencyCache[lookup_string] = dependency
	return dependency
end
---@type table<string,blockedReason>
local blockedCache = setmetatable({}, {__mode = "v"})
---@param id string
---@param type LuaObject.object_name
---@param reason invalidReason
---@return blockedReason
local function getBlocked(id, type, reason)
	---@type string
	local lookup_string = type..id
	local blocked = blockedCache[lookup_string]

	if blocked then
		if blocked.reason > reason then
			blocked.reason = reason
		end
		return blocked
	end

	---@type blockedReason
	blocked = {
		type = type,
		id = id,
		reason = reason,
	}
	dependencyCache[lookup_string] = blocked
	return blocked
end

---Like calling tierSwitch but without having to handle the dependency
---@param id string
---@param value tierSwitchValues
---@param blockedArray blockedReason[]
---@param dependencyArray dependency[]
local function resolveTierWithDependency(id, value, dependencyArray, blockedArray)
	local tier = CallTierSwitch(id, value)
	if tier < 0 then
		blockedArray[#blockedArray+1] = getBlocked(id, value.object_name, tier)
	else
		dependencyArray[#dependencyArray+1] = getDependency(id, value.object_name)
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
		category, {object_name = "LuaRecipeCategoryPrototype",
			real_object_name = "LuaRecipeCategoryPrototype"
		}, dependencies, blocked
	)
	if categoryTier < 0 then return categoryTier end
	local customTier = callback and callback(dependencies) or 0
	if customTier < 0 then return customTier end

	if #ingredients ~= 0 then
		ingredientsTier = ingredientsTier + 1
	end

	return math.max(ingredientsTier, categoryTier, customTier), dependencies
end
---Returns the tier and either the dependencies or blockedReason depending on tier
---@param tier tier
---@param dependency dependency[]?
---@param blocked blockedReason[]
---@return tier
---@return dependency[]|blockedReason[]
local function blockedOrDependency(tier, dependency, blocked)
	if tier < 0 then
		return tier, blocked
	else
		---@cast dependency dependency[]
		return tier, dependency
	end
end

---Determine the tier of mining an item or fluid
---@type fun(ItemID:data.ItemID|data.FluidID,prototype:fakePrototype):tier,blockedReason[]|dependency[]
tierSwitch["mining"] = function (ItemID, prototype)
	---@type table<string, OptionalFluidFakeRecipe[]|OptionalFluidFakeRecipe[]>
	local miningRecipes
	if prototype.real_object_name == "LuaItemPrototype" then
		miningRecipes = lookup.ItemMining[ItemID]
	else
		miningRecipes = lookup.FluidMining[ItemID]
	end
	---@type blockedReason[]
	local blockedBy = {}

	local tier, dependencies = lib.getMinTierInArray(
		miningRecipes, invalidReason.no_valid_miner,
		function (item)
			---@type Ingredient.fluid?
			local ingredient
			if item.input then
				ingredient = {name = item.input, type = "fluid"}
			end
			return doRecipe(
				{ingredient},
				item.category,
				blockedBy
			)
		end
	)
	return blockedOrDependency(tier, dependencies, blockedBy)
end
---Determine if a player can mine an item
---@type fun(ItemID:data.ItemID,_:fakePrototype):tier,blockedReason[]|dependency[]
tierSwitch["hand-mining"] = function (ItemID, _)
	local miningRecipes = lookup.HandMining[ItemID]
	---@type blockedReason[]
	local blockedBy = {}

	local tier, dependencies = lib.getMinTierInArray(
		miningRecipes, invalidReason.not_player_mineable,
		function (category)
			if category == "hand" then
				return 0, {}
			end
			return doRecipe(
				{},
				category,
				blockedBy
			)
		end
	)
	return blockedOrDependency(tier, dependencies, blockedBy)
end
---Determine the tier of burning an item
---@type fun(ItemID:data.ItemID,_:fakePrototype):tier,blockedReason[]|dependency[]
tierSwitch["burning"] = function (ItemID, _)
	local burningRecipes = lookup.Burning[ItemID]
	---@type blockedReason[]
	local blockedBy = {}

	local tier, dependencies = lib.getMinTierInArray(
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
	return blockedOrDependency(tier, dependencies, blockedBy)
end
---Determine the tier of launching an item into space
---@type fun(ItemID:data.ItemID,_:fakePrototype):tier,blockedReason[]|dependency[]
tierSwitch["rocket-launch"] = function (ItemID, _)
	local rocketRecipes = lookup.Rocket[ItemID]
	---@type blockedReason[]
	local blockedBy = {}

	local tier, dependencies = lib.getMinTierInArray(
		rocketRecipes, invalidReason.no_valid_rocket,
		function (satellite)
			return doRecipe(
				{{satellite}},
				"tiergen-rocket-launch",
				blockedBy
			)
		end
	)
	return blockedOrDependency(tier, dependencies, blockedBy)
end
---Determine the tier of boiling a liquid
---@type fun(FluidID:data.FluidID,_:fakePrototype):tier,blockedReason[]|dependency[]
tierSwitch["boil"] = function (FluidID,_)
	local recipes = lookup.Boiling[FluidID]
	---@type blockedReason[]
	local blockedBy = {}

	local tier, dependencies = lib.getMinTierInArray(
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
	return blockedOrDependency(tier, dependencies, blockedBy)
end
---Determine the tier of pumping fluid out of a lake
---@type fun(FluidID:data.FluidID,_:fakePrototype):tier,blockedReason[]|dependency[]
tierSwitch["offshore-pump"] = function (FluidID, _)
	local recipes = lookup.OffshorePumping[FluidID]
	---@type blockedReason[]
	local blockedBy = {}

	local tier, dependencies = lib.getMinTierInArray(
		recipes, invalidReason.no_valid_offshore_pump,
		function (recipe)
			return doRecipe(
				{}, -- No ingredients
				recipe,
				blockedBy
			)
		end
	)
	return blockedOrDependency(tier, dependencies, blockedBy)
end
tierSwitch["injected"] = function (RecipeID, _)
	local recipes = lookup.Injected[RecipeID]
	---@type blockedReason[]
	local blockedBy = {}

	local recipeTier, dependencies = lib.getMinTierInArray(
		recipes, invalidReason.no_valid_injection,
		function (recipe)
			local dependencies = {}
			return resolveTierWithDependency(
				recipe.id, recipe, dependencies, blockedBy
			), dependencies
		end
	)
	return blockedOrDependency(recipeTier, dependencies, blockedBy)
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

	if not lib.getSetting("tiergen-reduce-technology") and ingredientsTier > 0 then
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
		lib.debug("\tCategory "..CategoryID.." has no machines")
		return invalidReason.no_machine, {}
	end
	---@type blockedReason[]
	local blockedBy = {}
	local tier, dependencies = lib.getMinTierInArray(
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

	---
	if not lib.getSetting("tiergen-reduce-category") and tier > 0 then
		-- Used to be subtraction, but a refactor now implicitly does this.
		-- now the opposite of the setting determines if we undo it
		tier = tier + 1
	end
	return tier, dependencies
end
---Determine the tier of the given recipe
---@type fun(recipeID:data.RecipeID,recipe:LuaRecipePrototype|CompleteFakeRecipe):tier,blockedReason[]|dependency[]
tierSwitch["LuaRecipePrototype"] = function (recipeID, recipe)
	---@type blockedReason[]
	local blockedBy = {}

	if global.config.ignored_recipes[recipeID] then
		lib.ignore(recipeID, "is currently ignored", true)
		return invalidReason.ignored_recipe, blockedBy
	end

	---@type (fun(p1:dependency[]):tier)?
	local considerTechnology
	if lib.getSetting("tiergen-consider-technology") and not recipe.enabled then
		local technologies = lookup.RecipeTechnology[recipeID] or rawget(recipe, "technologies")
		if not technologies then
			print("\t"..recipeID.." is not an unlockable recipe.")
			return invalidReason.not_unlockable, {}
		end
		---@type (fun(p1:dependency[]):tier)?
		considerTechnology = function (dependencies)
			local tier, techDependencies = lib.getMinTierInArray(
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
	return blockedOrDependency(recipeTier, dependencies, blockedBy)
end
---Determine the tier of the given item or fluid
---@type fun(ItemID:data.ItemID|data.FluidID,value:LuaItemPrototype|LuaFluidPrototype):tier,blockedReason[]|dependency[]
tierSwitch["LuaFluidPrototype"] = function (ItemID, value)
	---@type table<string, string[]>
	local recipes
	if value.object_name == "LuaItemPrototype" then
		recipes = lookup.ItemRecipe[ItemID]
	else
		recipes = lookup.FluidRecipe[ItemID]
	end
	---@type blockedReason[]
	local blockedBy = {}

	if not recipes then
		lib.debug(value.object_name..":"..ItemID.." has no recipes!")
		return invalidReason.no_recipe, {}
		-- return 0, {}
	end


	local tier, dependencies = lib.getMinTierInArray(
		recipes, invalidReason.no_valid_recipe,
		function (recipe)
			---@type dependency[]
			local dependencies = {}

			local _, realstart = recipe:find("^tiergen[-]")
			---@type string, tierSwitchValues
			local id, prototype
			if realstart then
				id = ItemID
				prototype = {
					object_name = recipe:sub(realstart+1),
					real_object_name = value.object_name
				} --[[@as fakePrototype ]]
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
	return blockedOrDependency(tier, dependencies, blockedBy)
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
---@param type "item"|"fluid"
---@return uint
local function calculateTier(itemID, type)
	checkLookup()
	local isValid, itemPrototype = pcall(lib.getItemOrFluid, itemID, type)
	if not isValid then
		lib.log("\tWas given an invalid item: "..itemID)
		return invalidReason.not_an_item
	end
	local success, tier = pcall(CallTierSwitch, itemID, itemPrototype)
	if not success then
		tier = invalidReason.error
	end
	if tier < 0 then
		lib.log("Failed to calculate "..itemID.."'s tier: "..invalidReason[tier])
		lib.debug(serpent.dump(incalculable))
	else
		lib.debug("\t"..itemID..": Tier "..tier)
	end
	return tier
end

---Directly set the tier of a given itemID
---@param item simpleItem
local function setTier(item)
	checkLookup()
	local isValid, prototype = pcall(lib.getItemOrFluid, item.name, item.type)
	if not isValid then
		lib.log("\tWas given an invalid item: "..item)
		return
	end
	TierMaps[prototype.object_name][item.name] = {
		-- tier = item.count or 0,
		-- item.count is now used for something else
		tier = 0,
		id = item.name,
		type = item.type == "item" and "LuaItemPrototype" or "LuaFluidPrototype",
		dependencies = {}
	}
end

---Clears the working tables
local function uncalculate()
	lib.initTierMapTables(TierMaps, calculating, incalculable)
end

return {
	set = setTier,
	unset = uncalculate,
	calculate = calculateTier,
	unprocess = function ()
		processor.unprocess()
		uncalculate()
---@diagnostic disable-next-line: cast-local-type
		lookup = nil
	end,
	--Debugging

	---Look up the string corresponding an invalid reason
	---@param invalid_id integer
	---@return string
	invalid_lookup = function (invalid_id)
		return invalidReason[invalid_id]
	end,

	---Gets the array of ingredients for the given item
	---@param item data.ItemID
	---@param type "item"|"fluid"
	---@return table<data.ItemID|data.FluidID,"item"|"fluid">
	get_ingredients = function (item, type)
		---@type table<string, string[]>
		local recipes
		if type == "item" then
			recipes = lookup.ItemRecipe[item]
		else
			recipes = lookup.FluidRecipe[item]
		end

		if not recipes then
			error("Should not have been hit!")
		end

		---@type table<data.ItemID|data.FluidID,"item"|"fluid">
		local ingredients = {}
		for _, recipe in pairs(recipes) do
			local _, realstart = recipe:find("^tiergen[-]")
			if not realstart then

				-- Process regular recipe
				local nextIngredients = lib.getRecipe(recipe).ingredients
				for _, ingredient in pairs(nextIngredients) do
					-- Add each ingredient to the list
					local old_type = ingredients[ingredient.name]
					if old_type and old_type ~= ingredient.type then
						lib.debug("Item and Fluid Ingredient have the same name:", ingredient.name)
					elseif not old_type then
						ingredients[ingredient.name] = ingredient.type
					end
				end

			else
				-- Custom recipe handling
			end
		end
		return ingredients
	end
}