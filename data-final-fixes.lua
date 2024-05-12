local tierArray = {};
local TierMaps = {
	["items"] = {},
	["fluids"] = {},
};

---Appends to an array within a table
---@param table table
---@param key any
---@param newValue any
local function appendToArrayInTable(table, key, newValue)
	local array = table[key] or {}
	array[#array+1] = newValue;
	table[key] = array;
end

---@type table<data.ItemID,data.RecipeID[]>
local ItemRecipeLookup = {}
---@type table<data.FluidID,data.RecipeID[]>
local FluidRecipeLookup = {}
---Parses `data.raw.recipe` items
---@param recipeID data.RecipeID
---@param recipePrototype data.RecipePrototype
local function processRecipe(recipeID, recipePrototype)
	---@type data.RecipePrototype|data.RecipeData
	local recipeData = recipePrototype;

	if recipeData.result == nil and recipeData.results == nil then
		recipeData = recipeData.normal or recipeData.expensive
		if recipeData == nil then
			print(recipeID.." didn't result in anything?")
			print(serpent.line(recipeData))
			return;
		end
	end

	if recipeData.result ~= nil then
		appendToArrayInTable(ItemRecipeLookup, recipeData.result, recipeID)
	elseif recipeData.results ~= nil then
		for _, rawResult in pairs(recipeData.results) do
			-- Get resultID
				local result = rawResult[1] or rawResult.name;
				if result == nil then
					print("Couldn't find ingredientID:\n")
					print(serpent.line(rawResult))
					goto continue
				end

				if rawResult.type == "fluid" then
					appendToArrayInTable(FluidRecipeLookup, result, recipeID)
				else
					appendToArrayInTable(ItemRecipeLookup, result, recipeID)
				end
			::continue::
		end
	else
		print(recipeID.." didn't result in anything?")
		print(serpent.line(recipeData))
	end
end

for recipeID, rawRecipe in pairs(data.raw["recipe"]) do
	processRecipe(recipeID, rawRecipe);
end

---Determine the tier of the given prototype
---@param prototypeID string
---@param value data.ItemPrototype|data.FluidPrototype
---@return unknown
local function determineTier(prototypeID, value)
	local tier = TierMaps[value.type][prototypeID]
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
	TierMaps[value.type][prototypeID] = tier
	return tier
end

-- for item, value in pairs(data.raw["item"]) do
-- 	tierArray[determineTier(item, value)] = item;
-- end

-- for fluid, value in pairs(data.raw["fluid"]) do
-- 	tierArray[determineTier(fluid, value)] = fluid;
-- end