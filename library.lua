local lookup = require("__tier-generator__.calculation.lookupTables")

--- A table full of functions to simplify complex things
---@class TiergenLibrary
local library = {}


--#region Settings
---@alias tierSettings
---| "tiergen-reduce-category"
---| "tiergen-consider-technology"
---| "tiergen-reduce-technology"
---| "tiergen-item-calculation"
---| "tiergen-base-items"
---| "tiergen-ignored-recipes"
---| "tiergen-debug-log"
---@type {[tierSettings]:any}
local tiergenSettings = {
	["tiergen-reduce-category"] = true,
	["tiergen-consider-technology"] = true,
	["tiergen-reduce-technology"] = true,
	["tiergen-item-calculation"] = true,
	["tiergen-base-items"] = true,
	["tiergen-ignored-recipes"] = true,
	["tiergen-debug-log"] = true,
}
local cachedSettings = {}
---Gets the global setting, and caches it
---@param setting tierSettings
---@return any
function library.getSetting(setting)
	local value = cachedSettings[setting]
	if value then return value end

	value = settings.global[setting].value
	cachedSettings[setting] = value
	return value
end
---Clears the settings cache
---@param setting tierSettings?
function library.clearSettingCache(setting)
	if setting then
		cachedSettings[setting] = nil
	else
		cachedSettings = {}
	end
end
---Return whether or not the setting is ours
---@param setting string
---@return boolean
function library.isOurSetting(setting)
	return tiergenSettings[setting]
end
--#endregion
--#region Basic functions

---Logs from a centralized point
---@param ... any
---@see log
function library.log(...)
	return log(...)
end
---Only logs if debug_printing is enabled
---@param ... any
---@see log
function library.debug(...)
	if library.getSetting("tiergen-debug-log") then
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
---@param table {[string]:string[]}
---@param key string
---@param newValue string
---@overload fun(table:tierTable,key:"fluid"|"item",newValue:tierTableItem)
---@overload fun(table:tierArray,key:uint,newValue:tierArrayItem)
function library.appendToArrayInTable(table, key, newValue)
	local array = table[key] or {}
	array[#array+1] = newValue;
	table[key] = array;
end
---Prepends to an array within a table
---@param table {[string]:string[]}
---@param key string
---@param newValue string
---@overload fun(table:tierTable,key:"fluid"|"item",newValue:tierTableItem)
---@overload fun(table:tierArray,key:uint,newValue:tierArrayItem)
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
--#region Item Resolvers

---A generic function to get a prototype
---@generic P : any
---@param name string
---@param table table<string,P>
---@return P
local function getGeneric(name, table)
	if not name then
		error("Was passed a nil instead of an ID", 3)
	end
	local prototype = table[name]
	if not prototype then
		error("Didn't find what we looked for: "..name, 2)
	end
	return prototype
end

---Returns the given item
---@param name data.ItemID
---@return LuaItemPrototype
function library.getItem(name)
	return getGeneric(name, game.item_prototypes)
end
---Returns the given fluid
---@param name data.FluidID
---@return LuaFluidPrototype
function library.getFluid(name)
	return getGeneric(name, game.fluid_prototypes)
end
---Returns the given item or fluid
---@param name data.ItemID|data.FluidID
---@param type "item"|"fluid"
---@return LuaItemPrototype|LuaFluidPrototype
function library.getItemOrFluid(name, type)
	local table
	if type == "item" then
		table = game.item_prototypes
	else
		table = game.fluid_prototypes
	end
	return getGeneric(name, table)
end
---Returns the given recipe category
---@param name data.RecipeCategoryID
---@return LuaRecipeCategoryPrototype
function library.getRecipeCategory(name)
	return getGeneric(name, game.recipe_category_prototypes)
end
---Returns the given recipe category
---@param name data.TechnologyID
---@return LuaTechnologyPrototype
function library.getTechnology(name)
	return getGeneric(name, game.technology_prototypes)
end
---Returns the given recipe category
---@param name data.RecipeID
---@return LuaRecipePrototype
function library.getRecipe(name)
	return getGeneric(name, game.recipe_prototypes)
end

---Gets the placable item that results in the entity
---@param EntityID data.EntityID
---@param entityPrototype LuaEntityPrototype
---@return ItemStackDefinition[]
function library.getEntityItem(EntityID, entityPrototype)
	local items = entityPrototype.items_to_place_this
	if not items then
		library.log("\t\t"..EntityID.." isn't placable. Ignoring...")
		return {}
	end

	return items
	-- Unecessary?
	-- for _, item in ipairs(items) do
	-- 	local itemPrototype = library.getItemOrFluid(item.name, "item")

	-- 	if itemPrototype.place_result and itemPrototype.place_result.name == EntityID then
	-- 		return item.name
	-- 	end
	-- end
end
--#endregion

return library