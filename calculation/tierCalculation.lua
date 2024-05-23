local processor = require("__tier-generator__.calculation.DataProcessing")
local lookup ---@type LookupTables
local lib = require("__tier-generator__.library")

---@alias fakePrototype {type:string}
---@alias handledPrototypes fakePrototype|LuaRecipeCategoryPrototype|LuaTechnologyPrototype|LuaRecipePrototype|LuaFluidPrototype|LuaItemPrototype
---@alias handledTypes "LuaRecipeCategoryPrototype"|"LuaTechnologyPrototype"|"LuaRecipePrototype"|"LuaFluidPrototype"|"LuaItemPrototype"

---@enum invalidReason
local invalidReason = {
	calculating = -1,
	no_valid_machine = -2,
	no_valid_technology = -3,
	no_valid_furnace = -4,
	no_valid_rocket = -5,
	no_valid_recipe = -6,
	not_unlockable = -97,
	no_machine = -98,
	error = -99
}
---@alias tier invalidReason|uint

---@alias tierItem {name:string,type:"item"|"fluid"}
---@type table<uint,tierItem[]>
local tierArray = {};

---@type table<handledTypes,{[string]:boolean}>
TierMaps = {};
---@type table<handledTypes,{[string]:boolean}>
calculating = {};
---@alias blockedReason {type:LuaObject.object_name,id:string,reason:invalidReason}
---@alias blockedItem {type:LuaObject.object_name,id:string}
---@type table<handledTypes,table<string,{reason:invalidReason,blocked:blockedItem[]}>>
incalculable = {}
-- for subtype in pairs(defines.prototypes["item"]) do
-- 	TierMaps[subtype] = {}
-- 	calculating[subtype] = {}
-- end

---Clears the incalculable table for the given item and what it blocked
---@param type LuaObject.object_name
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
	for _, nextItem in ipairs(incalculableItem.blocked) do
		unmarkIncalculable(nextItem.type, nextItem.id)
	end
	incalculable[type][prototypeID] = nil
end

--#region Tier calculation
---@class TierSwitch
---@field [handledTypes] fun(prototypeID:string, value:handledPrototypes):tier,blockedReason[]
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
		local incalculableItem = incalculable[type][prototypeID]
		if incalculableItem then -- and incalculableItem.reason ~= invalidReason.calculating then
			return incalculableItem.reason
		end

		-- Attempt to calculate
		calculating[type][prototypeID] = true
		local success, reasons = false, {}
		success, tier, reasons = pcall(self[type], prototypeID, value)
		if not success then
			-- _log({"error-calculating", prototypeID, type, serpent.dump(value)})
			log("Error calculating the "..type.." of "..prototypeID..":\n"..tier)
			tier = invalidReason.error
		end

		-- Finish calculating
		calculating[type][prototypeID] = nil
		if tier >= 0 then -- Discard negative values
			TierMaps[type][prototypeID] = tier
			if type == "LuaFluidPrototype" or type == "LuaItemPrototype" then
				local itemType = (type == "LuaItemPrototype") and "item" or "fluid"
				lib.appendToArrayInTable(tierArray, tier+1, {
					name = prototypeID,
					type = itemType,
				})
			end

			--Remove blocked items, if it was marked incalculable during calculating
			incalculableItem = incalculable[type][prototypeID]
			if incalculableItem then
				unmarkIncalculable(type, prototypeID)
			end
		else -- Mark as incalculable
			incalculable[type][prototypeID] = {
				reason = tier,
				blocked = {}
			}
			for _, reason in ipairs(reasons) do
				incalculableItem = incalculable[reason.type][reason.id]
				if not incalculableItem then
					lib.log("\tMarking "..reason.id.." as incalculable because "..reason.reason)
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
		return tier
	end
})
---Return the highest tier from the ingredients
---@param ingredients Ingredient[]
---@return integer
---@return blockedReason
local function getIngredientsTier(ingredients)
	local ingredientsTier = 0;
	for _, ingredient in pairs(ingredients) do
		local nextName = ingredient.name or ingredient[1]
		local nextType = ingredient.type or "item"
		local nextValue = lib.getItemOrFluid(nextName, nextType)
		local nextTier = tierSwitch(nextName, nextValue)
		-- Skip if machine takes an item being calculated
		if nextTier < 0 then
			return nextTier, {
				type = nextType == "item" and "LuaItemPrototype" or "LuaFluidPrototype",
				id = nextName,
				reason = nextTier
			}
		end
		ingredientsTier = math.max(ingredientsTier, nextTier)
	end
	return ingredientsTier, {}
end

---Determine the tier of the given technology
---@type fun(technologyID:data.TechnologyID,technology:LuaTechnologyPrototype):tier,blockedReason[]
tierSwitch["LuaTechnologyPrototype"] = function (technologyID, technology)
	local ingredients = technology.research_unit_ingredients
	local ingredientsTier, ingredientBlocked = getIngredientsTier(ingredients)
	if ingredientsTier < 0 then
		return ingredientsTier, {ingredientBlocked}
	end

	local prereqTier = 0;
	for _, prerequisite in pairs(technology.prerequisites) do
		local preTier = tierSwitch(prerequisite.name, prerequisite)
		-- Skip if technology takes an item being calculated
		if preTier < 0 then
			return preTier, {{
				type = "LuaTechnologyPrototype",
				id = prerequisite.name,
				reason = preTier
			}}
		end
		prereqTier = math.max(prereqTier, preTier)
	end

	local tier = math.max(ingredientsTier, prereqTier)
	if tier == 0 then
		log("I don't think a technology should ever be t0: "..technologyID)
	elseif lib.getSetting("tiergen-reduce-technology") then
		tier = tier - 1
	end
	return tier, {}
end
---Determine the tier of the given recipe category
---@type fun(CategoryID:data.RecipeCategoryID,category:LuaRecipeCategoryPrototype):tier,blockedReason[]
tierSwitch["LuaRecipeCategoryPrototype"] = function (CategoryID, category)
	local machines = lookup.CategoryItem[CategoryID]
	if not machines then
		lib.log("\tCategory "..CategoryID.." has no machines")
		return invalidReason.no_machine, {}
	end
	local categoryTier = math.huge;
	local blockedCategories = {}
	for _, item in pairs(machines) do
		-- If it's craftable by hand, it's a base recipe.
		if item == "hand" then return 0, {} end
		local itemTier = tierSwitch(item, lib.getItem(item))
		-- Don't consider the machine if it takes something being calculated.
		if itemTier >= 0 then
			categoryTier = math.min(categoryTier, itemTier)
		else
			blockedCategories[#blockedCategories+1] = {
				type = "LuaItemPrototype",
				id = item,
				reason = itemTier
			}
		end
	end

	if categoryTier == math.huge then
		return invalidReason.no_valid_machine, blockedCategories
	end

	if lib.getSetting("tiergen-reduce-category") and categoryTier > 0 then
		categoryTier = categoryTier - 1
	end
	return categoryTier, {}
end
---Determine the tier of the given recipe
---@type fun(recipeID:data.RecipeID,recipe:LuaRecipePrototype):tier,blockedReason[]
tierSwitch["LuaRecipePrototype"] = function (recipeID, recipe)
	if #recipe.ingredients == 0 then
		lib.log("\t"..recipeID.." didn't require anything? Means it's a t0?")
		return 0, {}
	end

	-- Get recipe ingredients tier
	local ingredientsTier, blockedIngredient = getIngredientsTier(recipe.ingredients)
	-- Exit early if child-tier isn't currently calculable
	if ingredientsTier < 0 then return ingredientsTier, {blockedIngredient} end

	-- Get category tier
	local category = lib.getRecipeCategory(recipe.category)
	local machineTier = tierSwitch(category.name, category)
	-- Exit early if child-tier isn't currently calculable
	if machineTier < 0 then
		return machineTier, {{
			type = "LuaRecipeCategoryPrototype",
			id = category.name,
			reason = machineTier,
		}}
	end

	-- Get technology tier if it isn't enabled to start with
	local technologyTier = 0
	local blockedTechnology = {}
	if not recipe.enabled then
		technologyTier = math.huge
		local technologies = lookup.RecipeTechnology[recipeID]
		if not technologies then
			print("\t"..recipeID.." is not an unlockable recipe.")
			return invalidReason.not_unlockable, {}
		end

		for _, technology in pairs(technologies) do
			local nextValue = lib.getTechnology(technology)
			local nextTier = tierSwitch(technology, nextValue)
			-- Assume currently calculating technology to be of higher tier
			if nextTier >= 0 then
				technologyTier = math.min(technologyTier, nextTier)
			else
				blockedTechnology[#blockedTechnology+1] = {
					type = "LuaTechnologyPrototype",
					id = technology,
					reason = nextTier
				}
			end
		end
	end

	if technologyTier == math.huge then
		return invalidReason.no_valid_technology, blockedTechnology
	end

	return math.max(ingredientsTier, machineTier, technologyTier), {}
end
---Determine the tier of burning an item
---@type fun(ItemID:data.ItemID,value:LuaItemPrototype):tier,blockedReason[]
tierSwitch["burning"] = function (ItemID, value)
	local burningRecipes = lookup.Burning[ItemID]
	local tier = math.huge

	local blockedBy = {}
	for _, fuelID in pairs(burningRecipes) do
		local fuelTier, blockedFuel = getIngredientsTier{{fuelID}}
		if fuelTier < 0 then
			blockedBy[#blockedBy+1] = blockedFuel
			goto continue
		end
		local fuel = lib.getItem(fuelID)
		local categoryTier = tierSwitch("tiergen-fuel-"..fuel.fuel_category, {
			object_name = "LuaRecipeCategoryPrototype",
		})
		if categoryTier < 0 then
			blockedBy[#blockedBy+1] = {
				type = "LuaRecipeCategoryPrototype",
				id = "tiergen-fuel-"..fuel.fuel_category,
				reason = categoryTier,
			}
			goto continue
		end
		local recipeTier = math.max(fuelTier, categoryTier)
		tier = math.min(tier, recipeTier)
	  	::continue::
	end

	if tier == math.huge then
		return invalidReason.no_valid_furnace, blockedBy
	end

	return tier, {}
end
---Determine the tier of launching an item into space
---@type fun(ItemID:data.ItemID,value:LuaItemPrototype):tier,blockedReason[]
tierSwitch["rocket-launch"] = function (ItemID, value)
	local rocketRecipes = lookup.Rocket[ItemID]
	-- FIXME: actually consider the rocket-parts
	local tier = math.huge
	local blockedBy = {}

	for _, satelliteID in pairs(rocketRecipes) do
		local satelliteTier, blockedSatellite = getIngredientsTier{{satelliteID}}
		if satelliteTier < 0 then
			blockedBy[#blockedBy+1] = blockedSatellite
			goto continue
		end
		local categoryTier = tierSwitch("tiergen-rocket-launch", {
			object_name = "LuaRecipeCategoryPrototype",
		})
		if categoryTier < 0 then
			blockedBy[#blockedBy+1] = {
				type = "LuaRecipeCategoryPrototype",
				id = "tiergen-rocket-launch",
				reason = categoryTier,
			}
			goto continue
		end
		local recipeTier = math.max(satelliteTier, categoryTier)
		tier = math.min(tier, recipeTier)
	    ::continue::
	end

	if tier == math.huge then
		return invalidReason.no_valid_rocket, blockedBy
	end

	return tier, {}
end
---Determine the tier of the given item or fluid
---@type fun(ItemID:data.ItemID|data.FluidID,value:LuaItemPrototype|LuaFluidPrototype):tier,blockedReason[]
tierSwitch["LuaFluidPrototype"] = function (ItemID, value)
	local recipes
	if value.object_name == "LuaItemPrototype" then
		recipes = lookup.ItemRecipe[ItemID]
	else
		recipes = lookup.FluidRecipe[ItemID]
	end

	-- No recipes create it, then it's a base resource
	-- if it doesn't generate, maybe check if a technology gives it
	if not recipes then return 0, {} end

	local recipeTier = math.huge
	local blockedRecipes = {}
	for _, recipe in pairs(recipes) do
		-- if the recipeID starts with "tiergen-" then it's a fake recipe
		-- this mod *will not* make recipes
		local _, realstart = recipe:find("^tiergen[-]")
		local tempTier = math.huge
		local tempBlocked = nil
		if realstart then
			local fakeRecipeID = recipe:sub(realstart+1)
			tempTier, tempBlocked = tierSwitch[fakeRecipeID](ItemID, value)
		else
			local recipePrototype = lib.getRecipe(recipe)
			tempTier = tierSwitch(recipe, recipePrototype)
		end
		-- Skip recipe if it's using something being calculated
		if tempTier >= 0 then
			recipeTier = math.min(recipeTier, tempTier)
		elseif tempBlocked then
			for _, blocked in ipairs(tempBlocked) do
				blockedRecipes[#blockedRecipes+1] = blocked
			end
		else
			blockedRecipes[#blockedRecipes+1] = {
				type = "LuaRecipePrototype",
				id = recipe,
				reason = tempTier
			}
		end
	end

	-- It left the loop without a valid tier or returning an invalid one.
	-- That must mean there was no valid recipe. We've discarded barreling
	-- in the recipe processing, and skipped it if it there were *no* recipes.
	-- This _must_ mean that there's something being calculated in the chain.
	if recipeTier == math.huge then
		return invalidReason.no_valid_recipe, blockedRecipes
	end

	return recipeTier + 1, {}
end
tierSwitch["LuaItemPrototype"] = tierSwitch["LuaFluidPrototype"] --[[@as fun(ItemID:data.ItemID|data.FluidID,value:LuaItemPrototype|LuaFluidPrototype):tier,blockedReason[] ]]
--#endregion

local function checkLookup()
	if not lookup then
		lookup = processor.process()
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

---Clears the tierArray and processing tables
local function uncalculate()
	tierArray = {}
	local prototypes = {
		"LuaRecipeCategoryPrototype",
		"LuaTechnologyPrototype",
		"LuaRecipePrototype",
		"LuaFluidPrototype",
		"LuaItemPrototype",
	}
	for _, prototype in ipairs(prototypes) do
		TierMaps[prototype] = {}
		calculating[prototype] = {}
		incalculable[prototype] = {}
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
	end,
	uncalculate = uncalculate,
	clearCache = function ()
		processor.clearCache()
---@diagnostic disable-next-line: cast-local-type
		lookup = nil
		uncalculate()
	end
}