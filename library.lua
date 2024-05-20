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
---@generic Key : string
---@generic Value : string
---@param table {[Key]:Value[]}
---@param key Key
---@param newValue Value
function library.appendToArrayInTable(table, key, newValue)
	local array = table[key] or {}
	array[#array+1] = newValue;
	table[key] = array;
end
---Prepends to an array within a table
---@generic Key : string
---@generic Value : string
---@param table {[Key]:Value[]}
---@param key Key
---@param newValue Value
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