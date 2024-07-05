---Loops through the dependencies, and makes an array of all of their dependencies
---@param tierEntry tierEntry
---@param newDependencies tierEntry[]?
---@param completedItems table<tierSwitchTypes,{[string]:boolean}>
---@return tierEntry[]
local function getNextDependencies(tierEntry, newDependencies, completedItems)
	newDependencies = newDependencies or {}
	for _, dependency in pairs(tierEntry.dependencies) do
		if not completedItems[dependency.type][dependency.id] then
			completedItems[dependency.type][dependency.id] = true
			newDependencies[#newDependencies+1] = TierMaps[dependency.type][dependency.id]
		end
	end
	return newDependencies
end

---Turns the givenItems into a dependency[] for the itterable uses
---@param givenItems simpleItem[]
---@return tierEntry[]
local function getGivenAsDependencyArray(givenItems)
	---@type tierEntry[]
	local dependencies = {}
	for _, givenItem in pairs(givenItems) do
		---@type tierSwitchTypes
		local type = givenItem.type == "item" and "LuaItemPrototype" or "LuaFluidPrototype"
		dependencies[#dependencies+1] = TierMaps[type][givenItem.name]
	end
	return dependencies
end

---@class DependencyIteratorState
---@field current tierEntry[]?
---@field nextDependencies tierEntry[]?
---@field currentIndex integer?
---@field completedItems table<tierSwitchTypes,{[string]:boolean}>

---Itterates over a dependency graph
---@param s DependencyIteratorState
---@return simpleItem?
local function iterator(s)
	---@type tierEntry[]
	local nextItem
	while not nextItem do
		--Make sure we have an index into dependencies
		if not s.currentIndex then
			-- Start indexing into tierEntry[]
			s.current = s.nextDependencies
			s.currentIndex, nextItem = next(s.current)
			-- If we still don't have dependencies, then we finished
			if not s.currentIndex then return nil end
			s.nextDependencies = getNextDependencies(nextItem, nil, s.completedItems)
		else
			-- Get next index of tierEntry[]
			s.currentIndex, nextItem = next(s.current, s.currentIndex)
			if s.currentIndex then
				s.nextDependencies = getNextDependencies(nextItem, s.nextDependencies, s.completedItems)
			end
		end
	end

	---@type simpleItem
	return lib.item(
		nextItem.id,
		nextItem.type == "LuaItemPrototype" and "item" or "fluid",
		nextItem.tier
	)
end

---Returns an itterable for the dependencies of givenItems
---@param givenItems simpleItem[]
---@return fun(s:DependencyIteratorState):simpleItem?
---@return DependencyIteratorState
local function eachDependency(givenItems)
	if #givenItems == 0 then
		return function ()
			return nil
		end, {}
	end
	local items = getGivenAsDependencyArray(givenItems)
	---@type table<tierSwitchTypes,table<string,tierEntry>>
	local completedItems = lib.initTierMapTables{}
	for _, item in pairs(items) do
		completedItems[item.type][item.id] = item
	end
	return iterator, {
		nextDependencies = items,
		completedItems = completedItems
	}
end

return eachDependency