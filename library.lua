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

---A renamed version of `type` so it can be used as a local variable
---without losing the function
library.type = type
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
---Adds the tabs, concatenates the id and reason with spaces
---as well as adds "Ignoring..." to the end. Just for fewer repetition
---@param id string
---@param reason string
function library.ignore(id, reason)
	library.log("\t\t"..id.." "..reason.." Ignoring...")
end
---Essentially `TiergenLibrary.ignore` but with
---"has no items placing it?" as the passed reason
---@param id string
function library.noItems(id)
	library.log("\t\t"..id.." has no items placing it? Ignoring...")
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
---@overload fun(table:table<data.FluidID,OptionalFluidFakeRecipe[]>,key:data.FluidID,newValue:OptionalFluidFakeRecipe)
---@overload fun(table:table<data.ItemID,SingleItemFakeRecipe[]>,key:data.ItemID,newValue:SingleItemFakeRecipe)
---@overload fun(table:table<data.FluidID,SingleFluidFakeRecipe[]>,key:data.FluidID,newValue:SingleFluidFakeRecipe)
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
---@overload fun(table:table<data.FluidID,OptionalFluidFakeRecipe[]>,key:data.FluidID,newValue:OptionalFluidFakeRecipe)
---@overload fun(table:table<data.ItemID,SingleItemFakeRecipe[]>,key:data.ItemID,newValue:SingleItemFakeRecipe)
---@overload fun(table:table<data.FluidID,SingleFluidFakeRecipe[]>,key:data.FluidID,newValue:SingleFluidFakeRecipe)
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
--#region TierCalculation functions

---Takes an array and calls the given function for each item.
---Returns the minimum tier and the dependencies of it
---@nodiscard
---@generic item : any
---@param array item[]
---@param invalid invalidReason
---@param callback fun(item:item):tier,dependency[]?
---@return tier
---@return dependency[]?
function library.getMinTierInArray(array, invalid, callback)
	---@type dependency[]?
	local dependencies
	local tier = math.huge

	for _, item in ipairs(array) do
		local itemTier, itemDependencies = callback(item)
		if itemTier >= 0 and itemTier < tier then
			tier = itemTier
			dependencies = itemDependencies
		end
	end

	if tier == math.huge then
		tier = invalid
	end
	return tier, dependencies
end

---Takes the given table of tierSwitchTypes to arrays and resets them
---@param ... table<tierSwitchTypes,any>
function library.initTierMapTables(...)
	local tables = {...}
	local prototypes = {
		"LuaRecipeCategoryPrototype",
		"LuaTechnologyPrototype",
		"LuaRecipePrototype",
		"LuaFluidPrototype",
		"LuaItemPrototype",
		"mining",
		"hand-mining",
		"burning",
		"rocket-launch",
		"boil",
		"offshore-pump",
	}
	for _, prototype in ipairs(prototypes) do
		for _, table in ipairs(tables) do
			table[prototype] = {}
		end
	end
	return tables[1]
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
end
--#endregion
--#region GUI functions

---Gets the root element of a custom Gui. Eg: elements added like player.gui.screen.add{}
---@param element LuaGuiElement
---@return LuaGuiElement
function library.getRootElement(element)
	local lastElem = nil
	while element.parent do
		lastElem = element
		element = element.parent --[[@as LuaGuiElement]]
	end
	return lastElem or element
end

--#endregion

return library