---@class dependencyEntry
---@field dependencies dependency[]
---@field tier tier
---@field type tierSwitchTypes
---@field id string

---Loops through the dependencies, and makes an array of all of their dependencies
---@param tierEntry dependencyEntry
---@param newDependencies dependencyEntry[]?
---@param completedItems table<tierSwitchTypes,{[string]:boolean}>
---@return dependencyEntry[]
local function getNextDependencies(tierEntry, newDependencies, completedItems)
	newDependencies = newDependencies or {}
	for _, dependency in ipairs(tierEntry.dependencies) do
		if not completedItems[dependency.type][dependency.id] then
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
local function getGivenAsDependencies(givenItems)
	---@type dependencyEntry[]
	local givenDependencies = {}
	for _, givenItem in ipairs(givenItems) do
		---@type tierSwitchTypes
		local type = givenItem.type == "item" and "LuaItemPrototype" or "LuaFluidPrototype"
		local dependency = TierMaps[type][givenItem.name]
		givenDependencies[#givenDependencies+1] = {
			dependencies = dependency.dependencies,
			tier = dependency.tier,
			type = type,
			id = givenItem.name
		}
	end
	return givenDependencies
end

---@class DependencyIteratorState
---@field current dependencyEntry[]?
---@field nextDependencies dependencyEntry[]?
---@field currentIndex integer?
---@field itemIndex integer?
---@field completedItems table<tierSwitchTypes,{[string]:boolean}>

---Itterates over a dependency graph
---@param s DependencyIteratorState
---@return tierArrayItem?
local function iterator(s)
	---@type dependency
	local nextItem
	while not nextItem
	and	nextItem.type ~= "LuaItemPrototype"
	and	nextItem.type ~= "LuaFluidPrototype" do
		local dependencyEntry
		--Make sure we have an index into dependents
		if not s.itemIndex then
			--Make sure we have an index into dependencies
			if not s.currentIndex then
				-- Start indexing into dependencyEntry[]
				s.current = s.nextDependencies
				s.currentIndex, dependencyEntry = next(s.current)
				s.nextDependencies = getNextDependencies(dependencyEntry, nil, s.completedItems)
				-- If we still don't have dependencies, then we finished
				if not s.currentIndex then return end
			else
				-- Get next index of dependencyEntry[]
				s.currentIndex, dependencyEntry = next(s.current, s.currentIndex)
				s.nextDependencies = getNextDependencies(dependencyEntry, s.nextDependencies, s.completedItems)
			end

			-- Start indexing dependency[]
			s.itemIndex, nextItem = next(s.current[s.currentIndex].dependencies)
		else
			-- Get next index of dependency[]
			s.itemIndex, nextItem = next(s.current[s.currentIndex].dependencies, s.itemIndex)
		end
		s.completedItems[nextItem.type][nextItem.id] = true
	end

	---@type tierArrayItem
	return {
		name = nextItem.id,
		type = nextItem.type == "LuaItemPrototype" and "item" or "fluid"
	}
end

---Returns an itterable for the dependencies of givenItems
---@param givenItems tierArrayItem[]
local function eachDependency(givenItems)
	return iterator, {
		nextDependencies = getGivenAsDependencies(givenItems),
		completedItems = lib.initTierMapTables{}
	}
end

return eachDependency