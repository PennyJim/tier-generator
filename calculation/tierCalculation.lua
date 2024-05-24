local processor = require("__tier-generator__.calculation.DataProcessing")
lookup = nil ---@type LookupTables
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
	error = -99,
	not_an_item = -100,
}
setmetatable(invalidReason,{
	---Returns the key of the given value
	---@param self table<string,integer>
	---@param reason int
	---@return string
	__call = function (self, reason)
		for key, value in pairs(self) do
			if value == reason then return key end
		end
		return "unknown"
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
---@field type handledTypes
---@field id string
---@class tierEntry
---@field tier uint
---@field dependencies dependency[]
---@class tierMap
---@field [string] tierEntry
---@type {[handledTypes]:tierMap}
TierMaps = {};
---@type {[string]:boolean}
local baseOverride = {};
---@type table<handledTypes,{[string]:boolean}>
calculating = {};
---@class blockedReason: dependency
---@field type handledTypes
---@field id string
---@field reason invalidReason
---@type table<handledTypes,table<string,{reason:invalidReason,blocked:dependency[]}>>
incalculable = {}

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
	lib.debug(type..":"..prototypeID.." has been unmarked as incalculable")
	incalculable[type][prototypeID] = nil
	for _, nextItem in ipairs(incalculableItem.blocked) do
		unmarkIncalculable(nextItem.type, nextItem.id)
	end
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
		local type = value.object_name --[[@as handledTypes]]
		local tier = TierMaps[type][prototypeID]
		if tier ~= nil then return tier.tier end
		if type == "LuaItemPrototype" and baseOverride[prototypeID] then
			-- lib.appendToArrayInTable(tierArray, 1, {
			-- 	name = prototypeID,
			-- 	type = "item",
			-- })
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
		local success, result, dependencies = false, -math.huge, {}
		success, result, dependencies = pcall(self[type], prototypeID, value)
		if not success then
			-- _log({"error-calculating", prototypeID, type, serpent.dump(value)})
			log("Error calculating the "..type.." of "..prototypeID..":\n"..result)
			result = invalidReason.error
			dependencies = {}
		end
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
			lib.debug(type..":"..prototypeID.." failed because \""..invalidReason(result).."\"")
			incalculable[type][prototypeID] = {
				reason = tier.tier,
				blocked = {}
			}
			for _, reason in ipairs(dependencies) do
				incalculableItem = incalculable[reason.type][reason.id]
				if not incalculableItem then
					if reason.reason ~= invalidReason.calculating then
						log("\tMarking "..reason.id.." as incalculable because "..reason.reason)
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
---Return the highest tier from the ingredients
---@param ingredients Ingredient[]
---@return integer
---@return blockedReason[]|dependency[]
local function getIngredientsTier(ingredients)
	local ingredientsTier = 0;
	---@type dependency[]
	local dependencies = {}
	for _, ingredient in pairs(ingredients) do
		local nextName = ingredient.name or ingredient[1]
		local nextType = ingredient.type or "item"
		local nextValue = lib.getItemOrFluid(nextName, nextType)
		local nextTier = tierSwitch(nextName, nextValue)
		dependencies[#dependencies+1] = {
			type = nextType == "item" and "LuaItemPrototype" or "LuaFluidPrototype",
			id = nextName,
		}
		-- Skip if machine takes an item being calculated
		if nextTier < 0 then
			return nextTier, {{
				type = nextType == "item" and "LuaItemPrototype" or "LuaFluidPrototype",
				id = nextName,
				reason = nextTier
			}}
		end
		ingredientsTier = math.max(ingredientsTier, nextTier)
	end
	return ingredientsTier, dependencies
end

---Determine the tier of the given technology
---@type fun(technologyID:data.TechnologyID,technology:LuaTechnologyPrototype):tier,blockedReason[]|dependency[]
tierSwitch["LuaTechnologyPrototype"] = function (technologyID, technology)
	local ingredients = technology.research_unit_ingredients
	local ingredientsTier, dependencies = getIngredientsTier(ingredients)
	if ingredientsTier < 0 then
		return ingredientsTier, dependencies
	end
	---@cast dependencies dependency[]

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
		dependencies[#dependencies+1] = {
			type = "LuaTechnologyPrototype",
			id = prerequisite.name
		}
		prereqTier = math.max(prereqTier, preTier)
	end

	if ingredientsTier > 0 and lib.getSetting("tiergen-reduce-technology") then
		ingredientsTier = ingredientsTier - 1
	end
	local tier = math.max(ingredientsTier, prereqTier)
	if tier == 0 then
		log("I don't think a technology should ever be t0: "..technologyID)
	end
	return tier, dependencies
end
---Determine the tier of the given recipe category
---@type fun(CategoryID:data.RecipeCategoryID,category:LuaRecipeCategoryPrototype):tier,blockedReason[]|dependency[]
tierSwitch["LuaRecipeCategoryPrototype"] = function (CategoryID, category)
	local machines = lookup.CategoryItem[CategoryID]
	if not machines then
		lib.log("\tCategory "..CategoryID.." has no machines")
		return invalidReason.no_machine, {}
	end
	local categoryTier = math.huge;
	---@type blockedReason[]
	local blockedCategories = {}
	---@type dependency
	local machineDependant
	for _, item in pairs(machines) do
		-- If it's craftable by hand, it's a base recipe.
		if item == "hand" then return 0, {} end
		local itemTier = tierSwitch(item, lib.getItem(item))
		-- Don't consider the machine if it takes something being calculated.
		if itemTier >= 0 then
			if itemTier < categoryTier then
				categoryTier = itemTier
				machineDependant = {
					type = "LuaItemPrototype",
					id = item
				}
			end
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
	return categoryTier, {machineDependant}
end
---Determine the tier of the given recipe
---@type fun(recipeID:data.RecipeID,recipe:LuaRecipePrototype):tier,blockedReason[]|dependency[]
tierSwitch["LuaRecipePrototype"] = function (recipeID, recipe)
	if #recipe.ingredients == 0 then
		lib.log("\t"..recipeID.." didn't require anything? Means it's a t0?")
		return 0, {}
	end
	---@type dependency[]
	local dependencies = {}

	-- Get technology tier if it isn't enabled to start with
	local technologyTier = 0
	local blockedTechnology = {}
	if lib.getSetting("tiergen-consider-technology") and not recipe.enabled then
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
				if nextTier < technologyTier then
					technologyTier = nextTier
					dependencies[#dependencies+1] = {
						type = "LuaTechnologyPrototype",
						id = technology,
					}
				end
			else
				blockedTechnology[#blockedTechnology+1] = {
					type = "LuaTechnologyPrototype",
					id = technology,
					reason = nextTier
				}
			end
		end
	end

	if technologyTier < 0 then
		return invalidReason.no_valid_technology, blockedTechnology
	end

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
	dependencies[#dependencies+1] = {
		type = "LuaRecipeCategoryPrototype",
		id = category.name,
	}

	-- Get recipe ingredients tier
	local ingredientsTier, itemDependencies = getIngredientsTier(recipe.ingredients)
	-- Exit early if child-tier isn't currently calculable
	if ingredientsTier < 0 then return ingredientsTier, itemDependencies end
	---@cast itemDependencies dependency[]
	for index, dependency in ipairs(itemDependencies) do
		dependencies[index+1] = dependency
	end

	if technologyTier == math.huge then
		return invalidReason.no_valid_technology, blockedTechnology
	end

	return math.max(ingredientsTier, machineTier, technologyTier), dependencies
end
---Determine the tier of burning an item
---@type fun(ItemID:data.ItemID,value:LuaItemPrototype):tier,blockedReason[]|dependency[]
tierSwitch["burning"] = function (ItemID, value)
	local burningRecipes = lookup.Burning[ItemID]
	local tier = math.huge
	
	---@type dependency[]
	local dependencies
	---@type blockedReason[]
	local blockedBy = {}
	for _, fuelID in pairs(burningRecipes) do
		local fuelTier, recipeDependencies = getIngredientsTier{{fuelID}}
		if fuelTier < 0 then
			---@cast recipeDependencies blockedReason[]
			for _, recipeDependency in ipairs(recipeDependencies) do
				blockedBy[#blockedBy+1] = recipeDependency
			end
			goto continue
		end
		---@cast dependencies dependency[]
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
		recipeDependencies[#recipeDependencies+1] = {
			type = "LuaRecipeCategoryPrototype",
			id = "tiergen-fuel-"..fuel.fuel_category,
		}
		local recipeTier = math.max(fuelTier, categoryTier)
		if recipeTier < tier then
			tier = recipeTier
			dependencies = recipeDependencies
		end
	  	::continue::
	end

	if tier == math.huge then
		return invalidReason.no_valid_furnace, blockedBy
	end

	return tier, dependencies
end
---Determine the tier of launching an item into space
---@type fun(ItemID:data.ItemID,value:LuaItemPrototype):tier,blockedReason[]|dependency[]
tierSwitch["rocket-launch"] = function (ItemID, value)
	local rocketRecipes = lookup.Rocket[ItemID]
	-- FIXME: actually consider the rocket-parts
	local tier = math.huge
	---@type dependency[]
	local dependencies
	---@type blockedReason[]
	local blockedBy = {}

	for _, satelliteID in pairs(rocketRecipes) do
		local satelliteTier, itemDependencies = getIngredientsTier{{satelliteID}}
		if satelliteTier < 0 then
			---@cast itemDependencies blockedReason[]
			for _, itemDependency in ipairs(itemDependencies) do
				blockedBy[#blockedBy+1] = itemDependency
			end
			goto continue
		end
		---@cast itemDependencies dependency[]
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
		itemDependencies[#itemDependencies+1] = {
			type = "LuaRecipeCategoryPrototype",
			id = "tiergen-rocket-launch",
		}
		local recipeTier = math.max(satelliteTier, categoryTier)
		if recipeTier < tier then
			tier = recipeTier
			dependencies = itemDependencies
		end
	    ::continue::
	end

	if tier == math.huge then
		return invalidReason.no_valid_rocket, blockedBy
	end

	return tier, dependencies
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

	-- No recipes create it, then it's a base resource
	-- if it doesn't generate, maybe check if a technology gives it
	if not recipes then return 0, {} end

	local recipeTier = math.huge
	---@type dependency[]
	local dependencies
	---@type blockedReason[]
	local blockedRecipes = {}
	for _, recipe in pairs(recipes) do
		-- if the recipeID starts with "tiergen-" then it's a fake recipe
		-- this mod *will not* make recipes
		local _, realstart = recipe:find("^tiergen[-]")
		local tempTier = math.huge
		local tempDependencies = nil
		if realstart then
			local fakeRecipeID = recipe:sub(realstart+1)
			tempTier, tempDependencies = tierSwitch[fakeRecipeID](ItemID, value)
		else
			local recipePrototype = lib.getRecipe(recipe)
			tempTier = tierSwitch(recipe, recipePrototype)
		end
		-- Skip recipe if it's using something being calculated
		if tempTier >= 0 then
			if tempTier < recipeTier then
				recipeTier = tempTier
				if tempDependencies then
					dependencies = tempDependencies
				else
					dependencies = {{
						type = "LuaRecipePrototype",
						id = recipe,
					}}
				end
			end
		elseif tempDependencies then
			for _, blocked in ipairs(tempDependencies) do
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

	return recipeTier + 1, dependencies
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
		log("\tWas given an invalid item: "..itemID)
		return invalidReason.not_an_item
	end
	local tier = tierSwitch(itemID, itemPrototype)
	if tier < 0 then
		log("Failed to calculate "..itemID.."'s tier")
	else
		lib.log("\t"..itemID..": Tier "..tier)
	end
	return tier
end

---Takes an item and turns it into a table of item/fluid tiers
---@param dependency dependency
---@param table tierTable
---@param processed table<handledTypes,{[string]:boolean}>
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
		log("\tWas given an invalid item: "..itemID)
		return
	end
	baseOverride[itemID] = true
end
---Clears the working tables
local function uncalculate()
	baseOverride = {}
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

---comment
---@param itemIDs data.ItemID[]
---@return tierArray
local function getTier(itemIDs)
	local table, processed = {},{
		["LuaRecipeCategoryPrototype"] = {},
		["LuaTechnologyPrototype"] = {},
		["LuaRecipePrototype"] = {},
		["LuaFluidPrototype"] = {},
		["LuaItemPrototype"] = {},
	}
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