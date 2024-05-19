local lookup = require("__tier-generator__.calculation.DataProcessing")
local lib = require("__tier-generator__.library")

---@alias fakePrototype {type:string}
---@alias handledPrototypes fakePrototype|LuaRecipeCategoryPrototype|LuaTechnologyPrototype|LuaRecipePrototype|LuaFluidPrototype|LuaItemPrototype
---@alias handledTypes "recipe-category"|"technology"|"recipe"|"fluid"|"item"

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
	["recipe-category"] = {},
	["technology"] = {},
	["recipe"] = {},
	["fluid"] = {},
	["item"] = {}
};
for subtype in pairs(defines.prototypes["item"]) do
	TierMaps[subtype] = {}
end
---@type table<handledTypes,table<string,boolean>>
---@diagnostic disable-next-line: assign-type-mismatch
local calculating = table.deepcopy(TierMaps)

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
		local tier = TierMaps[value.type][prototypeID]
		if tier ~= nil then return tier end
		if calculating[value.type][prototypeID] then return invalidReason.calculating end

		calculating[value.type][prototypeID] = true
		local success = false
		success, tier = pcall(self[value.type], prototypeID, value)
		if not success then
			-- _log({"error-calculating", prototypeID, value.type, serpent.dump(value)})
			log("Error calculating the "..value.type.." of "..prototypeID..":\n"..tier)
			tier = invalidReason.error
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
})
---Return the highest tier from the ingredients
---@param ingredients Ingredient[]
---@return integer
local function getIngredientsTier(ingredients)
	local ingredientsTier = 0;
	for _, ingredient in pairs(ingredients) do
		local nextName = ingredient.name
		local nextType = ingredient.type
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
tierSwitch["technology"] = function (technologyID, technology)
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
tierSwitch["recipe-category"] = function (CategoryID, category)
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

	if settings.startup["tiergen-reduce-category"].value then
		categoryTier = categoryTier - 1
	end
	return categoryTier
end
---Determine the tier of the given recipe
---@type fun(recipeID:data.RecipeID,recipe:LuaRecipePrototype):tier
tierSwitch["recipe"] = function (recipeID, recipe)
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
			type = "recipe-category",
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
	local tier = math.huge

	for _, satelliteID in pairs(rocketRecipes) do
		local satelliteTier = getIngredientsTier{{satelliteID}}
		if satelliteTier < 0 then
			goto continue
		end
		local categoryTier = tierSwitch("tiergen-rocket-launch", {
			type = "recipe-category",
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
tierSwitch["fluid"] = function (ItemID, value)
	local recipes
	if value.type == "fluid" then
		recipes = lookup.FluidRecipe[ItemID]
	else
		recipes = lookup.ItemRecipe[ItemID]
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
for subtype in pairs(defines.prototypes["item"]) do
	tierSwitch[subtype] = tierSwitch["fluid"] --[[@as fun(ItemID:data.ItemID|data.FluidID,value:data.ItemPrototype|data.FluidPrototype):number]]
end
--#endregion

---Calculates the tier of a given itemID
---@param itemID string
---@return string?
local function calculateTier(itemID)
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
	local isValid, itemPrototype = pcall(lib.getItem, itemID)
	if not isValid then
		log("\tWas given an invalid item: "..itemID)
		return
	end
	TierMaps[itemPrototype.type][itemID] = 0
end

return {
	set = setTier,
	calculate = calculateTier,
	get = function ()
		return tierArray
	end
}