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

---Always return plural results
---Absolutely no gurantees it works for everything
---@param table data.RecipePrototype|data.MinableProperties|any
---@return data.ProductPrototype[]
local function alwaysPluralResults(table)
	---@type data.ProductPrototype[]
	local results = table.results
	if not results then
		results = {{
			type = "item",
			name = table.result,
			amount = table.result_count or table.count
		}}
	end
	return results
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
---@diagnostic disable-next-line: cast-local-type
		recipeData = recipeData.normal or recipeData.expensive
		if not recipeData then
			print(recipeID.." didn't result in anything?")
			print(serpent.line(recipeData))
			return;
		end
	end

	local results = alwaysPluralResults(recipeData)
	if not results then
		print(recipeID.." didn't result in anything?")
		print(serpent.line(recipeData))
		return
	end

	for _, rawResult in pairs(results) do
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
end

for recipeID, rawRecipe in pairs(data.raw["recipe"]) do
	processRecipe(recipeID, rawRecipe);
end

---@type table<data.RecipeID,data.TechnologyID>
local RecipeTechnologyLookup = {}
---Parses `data.raw.technology` items
---@param technologyID data.TechnologyID
---@param technologyPrototype data.TechnologyPrototype
local function processTechnology(technologyID, technologyPrototype)
	---@type data.TechnologyPrototype|data.TechnologyData
	local technologyData = technologyPrototype

	if technologyData.effects == nil then
---@diagnostic disable-next-line: cast-local-type
		technologyData = technologyData.normal or technologyData.expensive
		if not technologyData then
			print(technologyID.." didn't result in anything")
			-- print(serpent.line(technologyPrototype))
			return;
		end
	end

	for _, modifier in pairs(technologyData.effects) do
		if modifier.type == "unlock-recipe" then
			appendToArrayInTable(RecipeTechnologyLookup, modifier.recipe, technologyID)
		end
		-- Theoretically, it can give an item. Should we make that
		-- item inherit the tier of the technology that gives it?
	end
end
for technologyID, technologyData in pairs(data.raw["technology"]) do
	processTechnology(technologyID, technologyData)
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

	-- Get Technology Requirements (min)
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