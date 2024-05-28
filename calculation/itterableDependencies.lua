---@class dependencyEntry
---@field dependencies dependency[]
---@field tier tier
---@field type tierSwitchTypes
---@field id string
---@class tierResult
---@field tier tier
---@field type "item"|"fluid"
---@field name string

---Loops through the dependencies, and makes an array of all of their dependencies
---@param tierEntry dependencyEntry
---@param newDependencies dependencyEntry[]?
---@param completedItems table<tierSwitchTypes,{[string]:boolean}>
---@return dependencyEntry[]
local function getNextDependencies(tierEntry, newDependencies, completedItems)
	newDependencies = newDependencies or {}
	for _, dependency in ipairs(tierEntry.dependencies) do
		if not completedItems[dependency.type][dependency.id] then
			completedItems[dependency.type][dependency.id] = true
			local nextTierEntry = TierMaps[dependency.type][dependency.id]
			newDependencies[#newDependencies+1] = {
				dependencies = nextTierEntry.dependencies,
				tier = nextTierEntry.tier,
				type = dependency.type,
				id = dependency.id
			}
		end
	end
	return newDependencies
end

---Turns the givenItems into dependencyEntries that the itterable uses
---@param givenItems tierArrayItem[]
---@return dependencyEntry[]
local function getGivenAsDependency(givenItems)
	---@type dependencyEntry[]
	local dependency = {
		tier = -math.huge,
		type = "mining",
		id = "FAKE_ENTRY",
		dependencies = {}
	}
	local dependencies = dependency.dependencies
	for _, givenItem in ipairs(givenItems) do
		---@type tierSwitchTypes
		local type = givenItem.type == "item" and "LuaItemPrototype" or "LuaFluidPrototype"
		---@type dependency
		dependencies[#dependencies+1] = {
			type = type,
			id = givenItem.name
		}
	end
	return {dependency}
end

---@class DependencyIteratorState
---@field current dependencyEntry[]?
---@field nextDependencies dependencyEntry[]?
---@field currentIndex integer?
---@field completedItems table<tierSwitchTypes,{[string]:boolean}>

---Itterates over a dependency graph
---@param s DependencyIteratorState
---@return tierResult?
local function iterator(s)
	---@type dependencyEntry[]
	local nextItem
	while not (
		nextItem
		and(nextItem.type == "LuaItemPrototype"
		or	nextItem.type == "LuaFluidPrototype")
	)do
		--Make sure we have an index into dependencies
		if not s.currentIndex then
			-- Start indexing into dependencyEntry[]
			s.current = s.nextDependencies
			s.currentIndex, nextItem = next(s.current)
			-- If we still don't have dependencies, then we finished
			if not s.currentIndex then return nil end
			s.nextDependencies = getNextDependencies(nextItem, nil, s.completedItems)
		else
			-- Get next index of dependencyEntry[]
			s.currentIndex, nextItem = next(s.current, s.currentIndex)
			if s.currentIndex then
				s.nextDependencies = getNextDependencies(nextItem, s.nextDependencies, s.completedItems)
			end
		end
	end

	local nextItemTier = TierMaps[nextItem.type][nextItem.id].tier
	---@type tierResult
	return {
		tier = nextItemTier,
		name = nextItem.id,
		type = nextItem.type == "LuaItemPrototype" and "item" or "fluid"
	}
end

---Returns an itterable for the dependencies of givenItems
---@param givenItems tierArrayItem[]
---@return fun(s:DependencyIteratorState):tierResult?
---@return DependencyIteratorState
local function eachDependency(givenItems)
	if #givenItems == 0 then
		return function ()
			return nil
		end, {}
	end
	return iterator, {
		nextDependencies = getGivenAsDependency(givenItems),
		completedItems = lib.initTierMapTables{}
	}
end

return eachDependency