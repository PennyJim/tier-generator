local buildLookup = require("__tier-generator__.calculation.DataProcessing")
local lookup ---@type LookupTables
local lib = require("__tier-generator__.library")

---@alias fakePrototype {type:string}
---@alias handledPrototypes fakePrototype|LuaRecipeCategoryPrototype|LuaTechnologyPrototype|LuaRecipePrototype|LuaFluidPrototype|LuaItemPrototype
---@alias handledTypes "LuaRecipeCategoryPrototype"|"LuaTechnologyPrototype"|"LuaRecipePrototype"|"LuaFluidPrototype"|"LuaItemPrototype"

---@enum invalidReason
local invalidReason = {
	calculating = -1,
	no_machine = -2,
	no_valid_machine = -3,
	no_valid_technology = -4,
	no_valid_furnace = -5,
	no_valid_rocket = -6,
	no_valid_recipe = -7,
	error = -99
}
---@alias tier invalidReason|uint

---@type table<uint,string[]>
local tierArray = {};

---@type table<handledTypes,table<string,number>>
TierMaps = {
	["LuaRecipeCategoryPrototype"] = {},
	["LuaTechnologyPrototype"] = {},
	["LuaRecipePrototype"] = {},
	["LuaFluidPrototype"] = {},
	["LuaItemPrototype"] = {}
};
---@type table<handledTypes,table<string,boolean>>
calculating = {
	["LuaRecipeCategoryPrototype"] = {},
	["LuaTechnologyPrototype"] = {},
	["LuaRecipePrototype"] = {},
	["LuaFluidPrototype"] = {},
	["LuaItemPrototype"] = {}
};
-- for subtype in pairs(defines.prototypes["item"]) do
-- 	TierMaps[subtype] = {}
-- 	calculating[subtype] = {}
-- end

--#region Tier calculation
---@class TierSwitch
---@field [string] fun(prototypeID:string, value:handledPrototypes):tier
---@overload fun(prototypeID:string,value:handledPrototypes):tier
local tierSwitch = setmetatable({}, {
	---Base switching case of tierSwich
	---@param self TierSwitch
	---@param prototypeID string
	---@param value handledPrototypes
	---@return tier
	__call = function(self, prototypeID, value)
		local type = value.object_name
		local tier = TierMaps[type][prototypeID]
		if tier ~= nil then return tier end
		if calculating[type][prototypeID] then return invalidReason.calculating end

		calculating[type][prototypeID] = true
		local success = false
		success, tier = pcall(self[type], prototypeID, value)
		if not success then
			-- _log({"error-calculating", prototypeID, type, serpent.dump(value)})
			log("Error calculating the "..type.." of "..prototypeID..":\n"..tier)
			tier = invalidReason.error
		end
		calculating[type][prototypeID] = nil
		if tier >= 0 then -- Discard negative values
			TierMaps[type][prototypeID] = tier
			if type == "LuaFluidPrototype" or type == "LuaItemPrototype" then
				lib.appendToArrayInTable(tierArray, tier+1, prototypeID)
			end
		end
		return tier
	end
})
---Return the highest tier from the ingredients
---@param ingredients Ingredient[]
---@return integer
local function getIngredientsTier(ingredients)
	local ingredientsTier = 0;
	for _, ingredient in pairs(ingredients) do
		local nextName = ingredient.name or ingredient[1]
		local nextType = ingredient.type or "item"
		local nextValue = lib.getItemOrFluid(nextName, nextType)
		local nextTier = tierSwitch(nextName, nextValue)
		-- Skip if machine takes an item being calculated
		if nextTier < 0 then return nextTier end
		ingredientsTier = math.max(ingredientsTier, nextTier)
	end
	return ingredientsTier
end

---Determine the tier of the given technology
---@type fun(technologyID:data.TechnologyID,technology:LuaTechnologyPrototype):tier
tierSwitch["LuaTechnologyPrototype"] = function (technologyID, technology)
	local ingredients = technology.research_unit_ingredients
	local ingredientsTier = getIngredientsTier(ingredients)

	local prereqTier = 0;
	for _, prerequisite in pairs(technology.prerequisites) do
		local preTier = tierSwitch(prerequisite.name, prerequisite)
		-- Skip if technology takes an item being calculated
		if preTier < 0 then return preTier end
		prereqTier = math.max(prereqTier, preTier)
	end

	if ingredientsTier == 0 and prereqTier == 0 then
		log("I don't think a technology should ever be t0")
	end
	return math.max(ingredientsTier, prereqTier)
end
---Determine the tier of the given recipe category
---@type fun(CategoryID:data.RecipeCategoryID,category:LuaRecipeCategoryPrototype):tier
tierSwitch["LuaRecipeCategoryPrototype"] = function (CategoryID, category)
	local machines = lookup.CategoryItem[CategoryID]
	if not machines then
		lib.log("\tCategory "..CategoryID.." has no machines")
		return invalidReason.no_machine
	end
	local categoryTier = math.huge;
	for _, item in pairs(machines) do
		-- If it's craftable by hand, it's a base recipe.
		if item == "hand" then return 0 end
		local itemTier = tierSwitch(item, lib.getItem(item))
		-- Don't consider the machine if it takes something being calculated.
		-- It must mean that it uses something a tier too high, Right..?
		if itemTier >= 0 then
			categoryTier = math.min(categoryTier, itemTier)
		end
	end

	if categoryTier == math.huge then
		return invalidReason.no_valid_machine
	end

	if settings.startup["tiergen-reduce-category"].value and categoryTier > 0 then
		categoryTier = categoryTier - 1
	end
	return categoryTier
end
---Determine the tier of the given recipe
---@type fun(recipeID:data.RecipeID,recipe:LuaRecipePrototype):tier
tierSwitch["LuaRecipePrototype"] = function (recipeID, recipe)
	if #recipe.ingredients == 0 then
		lib.log("\t"..recipeID.." didn't require anything? Means it's a t0?")
		return 0
	end

	-- Get recipe ingredients tier
	local ingredientsTier = getIngredientsTier(recipe.ingredients)
	-- Exit early if child-tier isn't currently calculable
	if ingredientsTier < 0 then return ingredientsTier end

	-- Get category tier
	local category = lib.getRecipeCategory(recipe.category)
	local machineTier = tierSwitch(category.name, category)
	-- Exit early if child-tier isn't currently calculable
	if machineTier < 0 then return machineTier end

	-- Get technology tier if it isn't enabled to start with
	local technologyTier = 0
	if not recipe.enabled then
		technologyTier = math.huge
		local technologies = lookup.RecipeTechnology[recipeID]
		if not technologies then
			print("\t"..recipeID.." is not an unlockable recipe.")
			return -math.huge -- Ignore this recipe
		end

		for _, technology in pairs(technologies) do
			local nextValue = lib.getTechnology(technology)
			local nextTier = tierSwitch(technology, nextValue)
			-- Assume currently calculating technology to be of higher tier
			if nextTier >= 0 then
				technologyTier = math.min(technologyTier, nextTier)
			end
		end
	end

	if technologyTier == math.huge then
		return invalidReason.no_valid_technology
	end

	return math.max(ingredientsTier, machineTier, technologyTier)
end
---Determine the tier of burning an item
---@type fun(ItemID:data.ItemID,value:LuaItemPrototype):tier
tierSwitch["burning"] = function (ItemID, value)
	local burningRecipes = lookup.Burning[ItemID]
	local tier = math.huge

	for _, fuelID in pairs(burningRecipes) do
		local fuelTier = getIngredientsTier{{fuelID}}
		if fuelTier < 0 then
			goto continue
		end
		local fuel = lib.getItem(fuelID)
		local categoryTier = tierSwitch("tiergen-fuel-"..fuel.fuel_category, {
			object_name = "LuaRecipeCategoryPrototype",
		})
		if categoryTier < 0 then
			goto continue
		end
		local recipeTier = math.max(fuelTier, categoryTier)
		tier = math.min(tier, recipeTier)
	  	::continue::
	end

	if tier == math.huge then
		return invalidReason.no_valid_furnace
	end

	return tier
end
---Determine the tier of launching an item into space
---@type fun(ItemID:data.ItemID,value:LuaItemPrototype):tier
tierSwitch["rocket-launch"] = function (ItemID, value)
	local rocketRecipes = lookup.Rocket[ItemID]
	-- FIXME: actually consider the rocket-parts
	local tier = math.huge

	for _, satelliteID in pairs(rocketRecipes) do
		local satelliteTier = getIngredientsTier{{satelliteID}}
		if satelliteTier < 0 then
			goto continue
		end
		local categoryTier = tierSwitch("tiergen-rocket-launch", {
			object_name = "LuaRecipeCategoryPrototype",
		})
		if categoryTier < 0 then
			goto continue
		end
		local recipeTier = math.max(satelliteTier, categoryTier)
		tier = math.min(tier, recipeTier)
	    ::continue::
	end

	if tier == math.huge then
		return invalidReason.no_valid_rocket
	end

	return tier
end
---Determine the tier of the given item or fluid
---@type fun(ItemID:data.ItemID|data.FluidID,value:LuaItemPrototype|LuaFluidPrototype):tier
tierSwitch["LuaFluidPrototype"] = function (ItemID, value)
	local recipes
	if value.object_name == "LuaItemPrototype" then
		recipes = lookup.ItemRecipe[ItemID]
	else
		recipes = lookup.FluidRecipe[ItemID]
	end

	-- No recipes create it, then it's a base resource
	-- if it doesn't generate, maybe check if a technology gives it
	if not recipes then return 0 end

	local recipeTier = math.huge
	for _, recipe in pairs(recipes) do
		-- if the recipeID starts with "tiergen-" then it's a fake recipe
		-- this mod *will not* make recipes
		local _, realstart = recipe:find("^tiergen[-]")
		local tempTier = math.huge
		if realstart then
			local fakeRecipeID = recipe:sub(realstart+1)
			tempTier = tierSwitch[fakeRecipeID](ItemID, value)
		else
			local recipePrototype = lib.getRecipe(recipe)
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
		return invalidReason.no_valid_recipe
	end

	return recipeTier + 1
end
tierSwitch["LuaItemPrototype"] = tierSwitch["LuaFluidPrototype"] --[[@as fun(ItemID:data.ItemID|data.FluidID,value:LuaItemPrototype|LuaFluidPrototype):number]]
--#endregion

local function checkLookup()
	if not lookup then
		lookup = buildLookup()
	end
end

---Calculates the tier of a given itemID
---@param itemID string
---@return string?
local function calculateTier(itemID)
	checkLookup()
	local isValid, itemPrototype = pcall(lib.getItem, itemID)
	if not isValid then
		log("\tWas given an invalid item: "..itemID)
		return
	end
	local tier = -1
	local rounds = 0
	while tier < 0 and rounds < 5 do
		tier = tierSwitch(itemID, itemPrototype)
		rounds = rounds + 1
	end
	if rounds == 5 then
		log("Gave up trying to calculate "..itemID.."'s tier")
	else
		if rounds > 1 then
			log("MULTIPLE ROUNDS ACTUALLY DOES SOMETHING")
		end
		lib.log("\t"..itemID..": Tier "..tier.." after "..rounds.." attempt(s)")
		return
	end
end

---Directly set the tier of a given itemID
---@param itemID string
local function setTier(itemID)
	checkLookup()
	local isValid, itemPrototype = pcall(lib.getItem, itemID)
	if not isValid then
		log("\tWas given an invalid item: "..itemID)
		return
	end
	TierMaps[itemPrototype.object_name][itemID] = 0
end

return {
	set = setTier,
	calculate = calculateTier,
	get = function ()
		return tierArray
	end
}