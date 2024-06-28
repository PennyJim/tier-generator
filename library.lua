local lookup = require("__tier-generator__.calculation.lookupTables")

--- A table full of functions to simplify complex things
---@class TiergenLibrary
local library = {}


--#region Settings
---@alias tierSettings
---| "tiergen-consider-autoplace-setting"
---| "tiergen-consider-technology"
---| "tiergen-reduce-technology"
---| "tiergen-reduce-category"
---| "tiergen-debug-log"
---@type {[tierSettings]:any}
local tiergenSettings = {
	["tiergen-consider-autoplace-setting"] = true,
	["tiergen-consider-technology"] = true,
	["tiergen-reduce-technology"] = true,
	["tiergen-reduce-category"] = true,
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
--#region Logging

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
--#endregion
--#region Printing

---Prints a message to a player
---@param player_index integer
---@param message LocalisedString
function library.print(player_index, message)
	if remote.interfaces["better-chat"] then
		remote.call("better-chat", "send", message, nil, "player", player_index, false)
	else
		local player = game.get_player(player_index)
		if not player then return end
		player.print(message)
	end
end

---Prints a message to a player
---@param force_index integer
---@param message LocalisedString
function library.force_print(force_index, message)
	if remote.interfaces["better-chat"] then
		remote.call("better-chat", "send", message, nil, "player", force_index, false)
	else
		local force = game.forces[force_index]
		if not force then return end
		force.print(message)
	end
end

function library.global_print(message)
	if remote.interfaces["better-chat"] then
		remote.call("better-chat", "send", message, nil, "global", nil, false)
	else
		game.print(message)
	end
end
--#endregion
--#region Array Operations

---Appends to an array within a table
---@param table {[string]:string[]}
---@param key string
---@param newValue string
---@overload fun(table:tierTable,key:"fluid"|"item",newValue:tierTableItem)
---@overload fun(table:tierArray,key:uint,newValue:simpleItem)
---@overload fun(table:table<data.FluidID,OptionalFluidFakeRecipe[]>,key:data.FluidID,newValue:OptionalFluidFakeRecipe)
---@overload fun(table:table<data.ItemID,SingleItemFakeRecipe[]>,key:data.ItemID,newValue:SingleItemFakeRecipe)
---@overload fun(table:table<data.FluidID,SingleFluidFakeRecipe[]>,key:data.FluidID,newValue:SingleFluidFakeRecipe)
---@overload fun(table:table<data.ItemID,CompleteFakeRecipe[]>,key:data.ItemID,newValue:CompleteFakeRecipe)
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
---@overload fun(table:tierArray,key:uint,newValue:simpleItem)
---@overload fun(table:table<data.FluidID,OptionalFluidFakeRecipe[]>,key:data.FluidID,newValue:OptionalFluidFakeRecipe)
---@overload fun(table:table<data.ItemID,SingleItemFakeRecipe[]>,key:data.ItemID,newValue:SingleItemFakeRecipe)
---@overload fun(table:table<data.FluidID,SingleFluidFakeRecipe[]>,key:data.FluidID,newValue:SingleFluidFakeRecipe)
---@overload fun(table:table<data.ItemID,CompleteFakeRecipe[]>,key:data.ItemID,newValue:CompleteFakeRecipe)
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
		"injected",
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

local itemMetatable = {
	__tostring = function (self)
		return self.type..":"..self.name
	end,
	__eq = function (self, other)
		return self.type == other.type and self.name == other.name
	end
}
script.register_metatable("simple-item", itemMetatable)
---Creates an item object
---@param name data.ItemID|data.FluidID
---@param type "item"|"fluid"?
---@return simpleItem
function library.item(name, type)
	return setmetatable({
		name = name,
		type = type or "item"
	}, itemMetatable)
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
--#region Timing functions

---@type {[string]:fun(d:NthTickEventData)}
local nth_tick_handlers = {}
---Puts the function in a table. Should be treated like
---script.register_metatable for desync safety
---@param name string
---@param func fun(data:NthTickEventData)
function library.register_func(name, func)
	if nth_tick_handlers[name] then
		error("Two handlers cannot share a name", 2)
	end
	nth_tick_handlers[name] = func
end
---The handler for the next tick
---@param data NthTickEventData
local function tick(data)
	-- reset tick data so handlers can re-register without fear
	local this_tick = global.tick_later
	global.tick_later = {}
	global.next_tick = nil
	script.on_nth_tick(data.nth_tick, nil)

	for _, funcName in ipairs(this_tick) do
		local success, error = pcall(nth_tick_handlers[funcName], data)
		if not success then
			lib.log(error)
		end
	end
end
---Calls the given function next tick
---@param func_name string
function library.tick_later(func_name)
	global.tick_later[#global.tick_later+1] = func_name
	if not global.next_tick then
		global.next_tick = true
		script.on_nth_tick(1, tick)
	end
end

---The handler for seconds_later
---@param data NthTickEventData
local function seconds_later_tick(data)
	if data.nth_tick ~= data.tick then
		error("Should only ever be called once for an nth_tick")
	end
	local func_name = global.seconds[data.tick]
	local success, error = pcall(nth_tick_handlers[func_name], data)
	if not success then
		lib.log(error)
	end
	global.seconds[data.tick] = nil
	script.on_nth_tick(data.nth_tick, nil)
end
---Will only be used when seconds_later is called on tick 0. Will run at tick 1
local function register_all_seconds()
	for time in pairs(global.seconds) do
		script.on_nth_tick(time, seconds_later_tick)
	end
end
library.register_func("register-seconds", register_all_seconds)
---Calls the given functions at 60 the given seconds_later
---If two functions need the same tick, the one registered later will
---be pushed back to the next available tick
---@param seconds number
---@param func_name string
function library.seconds_later(seconds, func_name)
	local cur_tick = game.tick
	local next_tick = math.floor(seconds*60 + cur_tick)
	local registered_table = global.seconds or {}
	while registered_table[next_tick] do
		next_tick = next_tick + 1
	end
	registered_table[next_tick] = func_name
	global.seconds = registered_table

	if cur_tick == 0 then
		library.tick_later("register-seconds")
	else
		script.on_nth_tick(next_tick, seconds_later_tick)
	end
end

---To reregister the tick for tick_later.
function library.register_load()
	if global.next_tick then
		script.on_nth_tick(1, tick)
	end
	
	if global.seconds and #global.seconds > 0 then
		register_all_seconds()
	end
end
--#endregion

return library