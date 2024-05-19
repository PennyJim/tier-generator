local lookup = require("__tier-generator__.calculation.lookupTables")

--- A table full of functions to simplify complex things
---@class TiergenLibrary
local library = {}

--#region Basic functions
local debug_printing = settings.startup["tiergen-debug-log"].value --[[@as boolean]]
---Only logs if debug_printing is enabled
---@param ... any
---@see log
function library.log(...)
	if debug_printing then
		return log(...)
	end
end
---Splits a string at 'sep'
---@param s string
---@param sep string
---@return string[]
function library.split(s, sep)
	local fields = {}
	
	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)
---@diagnostic disable-next-line: discard-returns
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
	
	return fields
end
--#endregion
--#region Array Operations

---Appends to an array within a table
---@param table table
---@param key any
---@param newValue any
function library.appendToArrayInTable(table, key, newValue)
	local array = table[key] or {}
	array[#array+1] = newValue;
	table[key] = array;
end
---Prepends to an array within a table
---@param table table
---@param key any
---@param newValue any
function library.prependToArrayInTable(table, key, newValue)
	local array = table[key] or {}
	local shiftedValue = newValue
	for	index, oldValue in ipairs(array) do
		array[index] = shiftedValue
		shiftedValue = oldValue
	end
	array[#array+1] = shiftedValue
	table[key] = array;
end
--#endregion
--#region data.raw standardization

---Always return plural results
---Absolutely no gurantees it works for everything
---@param table data.RecipePrototype|data.MinableProperties|any
---@return data.ProductPrototype[]
function library.alwaysPluralResults(table)
	---@type data.ProductPrototype[]
	local results = table.results
	if not results then
		results = {{
			type = "item",
			name = table.result,
		}}
	end
	if results[1] and results[1].name or results[1] and results[1][1] then
		return results
	else
---@diagnostic disable-next-line: return-type-mismatch
		return false
	end
end
---Always return RecipeData
---@param table data.RecipePrototype
---@return data.RecipeData
function library.alwaysRecipeData(table)
	---@type data.RecipeData
---@diagnostic disable-next-line: assign-type-mismatch
	local oldRecipeData = table.normal or table.expensive or {}
	local recipeData = {
		ingredients = table.ingredients or oldRecipeData.ingredients,
		results = library.alwaysPluralResults(table) or library.alwaysPluralResults(oldRecipeData)
	}
	if table then
		recipeData.enabled = table.enabled
	elseif oldRecipeData then
		recipeData.enabled = oldRecipeData.enabled
	end
	-- has to check if it's nil specifically, as it'll just always be true otherwise
	if recipeData.enabled == nil then
		recipeData.enabled = true;
	end

	return recipeData
end
---Always returns TechnologyData
---@param table data.TechnologyPrototype
---@return data.TechnologyData
function library.alwaysTechnologyData(table)
	---@type data.TechnologyData
---@diagnostic disable-next-line: assign-type-mismatch
	local oldTechnologyData = table.normal or table.expensive or {}
	local technologyData = {
		unit = table.unit or oldTechnologyData.unit,
		prerequisites = table.prerequisites or oldTechnologyData.prerequisites or {}
	}
	return technologyData
end
--#endregion
--#region Item Resolvers

---Gets the placable item that results in the entity
---@param EntityID data.EntityID
---@param entityPrototype data.EntityPrototype
---@return data.ItemID?
function library.getEntityItem(EntityID, entityPrototype)
	if entityPrototype.placeable_by then
		return entityPrototype.placeable_by.item
	elseif entityPrototype.minable then
		local items = library.alwaysPluralResults(entityPrototype.minable) or {}

		for _, item in pairs(items) do
			if data.raw["item"][item.name].place_result == EntityID then
				return item.name
			end
		end
		
		library.log("\t\t"..EntityID.."'s mined items aren't placable. Ignoring...")
	else
		library.log("\t\t"..EntityID.." Isn't placable _or_ mineable. Ignoring...")
	end
	return nil
end
---Resolves the type of an item, and errors if one is not found
---@param itemID string
---@return string
function library.resolveItemType(itemID)
	local itemType = lookup.ItemType[itemID]
	if not itemType then
		error("Could not find item type of given item: "..itemID)
	end
	return itemType
end
--#endregion

return library