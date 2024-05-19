local lookup = require("__tier-generator__.lookupTables")
local lib = require("__tier-generator__.library")
-- Process data.raw
require("__tier-generator__.calculation.DataProcessing")

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

--#region Tier calculation
--@type table<string,fun(string,data.PrototypeBase)>

---@alias fakePrototype {type:string}
---@class TierSwitch
---@overload fun(prototypeID:string,value:data.AnyPrototype|fakePrototype):number
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
		log("Error calculating the "..value.type.." of "..prototypeID..":\n"..tier)
		tier = -math.huge
	end
	calculating[value.type][prototypeID] = nil
	if tier >= 0 then -- Discard negative values
		TierMaps[value.type][prototypeID] = tier
		if value.type == "fluid" or defines.prototypes["item"][value.type] == 0 then
			lib.appendToArrayInTable(tierArray, tier+1, prototypeID)
		end
	end
	return tier
end

---Determine the tier of the given recipe category
---@param CategoryID data.RecipeCategoryID
---@param category data.RecipeCategory
---@return integer
tierSwitch["recipe-category"] = function (CategoryID, category)
	local machines = lookup.CategoryItem[CategoryID]
	if not machines then
		lib.log("\tCategory "..CategoryID.." has no machines")
		return -math.huge
	end
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

	if categoryTier == math.huge then
		return -math.huge
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
		local nextType = ingredient.type or lookup.ItemType[nextName]
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
	local techData = lib.alwaysTechnologyData(technology)
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
	local recipeData = lib.alwaysRecipeData(recipe)
	if not recipeData.ingredients then
		lib.log("\t"..recipeID.." didn't require anything? Means it's a t0?")
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
		local technologies = lookup.RecipeTechnology[recipeID]
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
	local burningRecipes = lookup.Burning[ItemID]
	local tier = math.huge

	for _, fuelID in pairs(burningRecipes) do
		local fuelTier = getIngredientsTier{{fuelID}}
		if fuelTier < 0 then
			return fuelTier
		end
		local fuel = data.raw[lookup.ItemType[fuelID]][fuelID]
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

---Determine the tier of launching an item into space
---@param ItemID data.ItemID
---@param value data.ItemPrototype
tierSwitch["rocket-launch"] = function (ItemID, value)
	local rocketRecipes = lookup.Rocket[ItemID]
	local tier = math.huge

	for _, satelliteID in pairs(rocketRecipes) do
		local satelliteTier = getIngredientsTier{{satelliteID}}
		if satelliteTier < 0 then
			return satelliteTier
		end
		local categoryTier = tierSwitch("tiergen-rocket-launch", {
			type = "recipe-category",
		})
		if categoryTier < 0 then
			return categoryTier
		end
		local recipeTier = math.max(satelliteTier, categoryTier)
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
		recipes = lookup.FluidRecipe[ItemID]
	else
		recipes = lookup.ItemRecipe[ItemID]
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
--#endregion

---Calculates the tier of a given itemID
---@param itemID string
---@return string?
local function calculateTier(itemID)
	local validItem, itemType = pcall(lib.resolveItemType, itemID)
	if not validItem then
		log("\tWas given an invalid item: "..itemID)
		return
	end
	local tier = -1
	local rounds = 0
	while tier < 0 and rounds < 5 do
		tier = tierSwitch(itemID, data.raw[itemType][itemID])
		rounds = rounds + 1
	end
	if rounds == 5 then
		log("Gave up trying to calculate "..itemID.."'s tier")
	else
		lib.log("\t"..itemID..": Tier "..tier.." after "..rounds.." attempt(s)")
		return
	end
end

---Directly set the tier of a given itemID
---@param itemID string
local function setTier(itemID)
	local itemType = lib.resolveItemType(itemID)
	TierMaps[itemType][itemID] = 0
end

return {
	set = setTier,
	calculate = calculateTier,
	get = function ()
		return tierArray
	end
}