local tierArray = {};
local itemTierMap = {};

---Appends to an array within a table
---@param table table
---@param key any
---@param newValue any
local function appendToArrayInTable(table, key, newValue)
	local array = table[key] or {}
	array[#array+1] = newValue;
	table[key] = array;
end

---Determine the tier of the given prototype
---@param prototypeID string
---@param value data.ItemPrototype|data.FluidPrototype
---@return unknown
local function determineTier(prototypeID, value)
	local tier = itemTierMap[prototypeID]
	if tier ~= nil then return tier end

	-- Get Recipes (max)
	local recipeTier;

	-- Get Machine Requirements (min)
	local machineTier;

	-- Get Technology Requirements (max)
	local technologyTier

	-- Determine tier, increment, and cache.
	tier = math.max(recipeTier, machineTier, technologyTier)+1
	appendToArrayInTable(tierArray, tier, prototypeID)
	itemTierMap[prototypeID] = tier
	return tier
end

-- for item, value in pairs(data.raw["item"]) do
-- 	tierArray[determineTier(item, value)] = item;
-- end

-- for fluid, value in pairs(data.raw["fluid"]) do
-- 	tierArray[determineTier(fluid, value)] = fluid;
-- end