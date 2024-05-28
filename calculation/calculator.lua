local core = require("__tier-generator__.calculation.tierCalculation")
local eachDependency = require("__tier-generator__.calculation.itterableDependencies")
---@class Calculator
local calculator = {}

---Tells the core calculator to drop its cache and consider sets its base items
function calculator.updateBase()
	core.unset()
	lib.log("Setting base item overrides")
	local baseItems = lib.getSetting("tiergen-base-items") --[[@as string]]
	for _, itemID in pairs(lib.split(baseItems, ",")) do
		-- Trim whitespace
		itemID = itemID:match("^%s*(.-)%s*$")
		lib.log("\tSetting "..itemID.." to tier 0")
		core.set(itemID)
	end
end

-- ---Takes an item and turns it into a table of item/fluid tiers
-- ---@param dependency dependency
-- ---@param table tierTable
-- ---@param processed table<tierSwitchTypes,{[string]:boolean}>
-- ---@param passedTop boolean?
-- local function resolveDependencies(dependency, table, processed, passedTop)
-- 	local isTop = passedTop == nil or passedTop
-- 	local item = TierMaps[dependency.type][dependency.id]
-- 	if processed[dependency.type][dependency.id] then return end
-- 	if dependency.type == "LuaFluidPrototype"
-- 	or dependency.type == "LuaItemPrototype" then
-- 		local type = dependency.type == "LuaFluidPrototype" and "fluid" or "item"
-- 		lib.appendToArrayInTable(table, type, {
-- 			name = dependency.id,
-- 			tier = item.tier,
-- 			isDirect = passedTop or false,
-- 		})
-- 		if passedTop then isTop = false end
-- 	end
-- 	processed[dependency.type][dependency.id] = true
-- 	for _, dependency in ipairs(item.dependencies) do
-- 		resolveDependencies(dependency, table, processed, isTop)
-- 	end
-- end


-- ---Turns a table of resolved dependencies into a tier array
-- ---@param dependencies tierTable
-- ---@return tierArray
-- local function depenenciesToArray(dependencies)
-- 	---@type tierArray
-- 	local tierArray = {}
-- 	for _, type in ipairs({"item","fluid"}) do
-- 		if not dependencies[type] then goto continue end
-- 		for _, tierItem in ipairs(dependencies[type]) do
-- 			lib.appendToArrayInTable(tierArray, tierItem.tier+1, {
-- 				name = tierItem.name,
-- 				type = type,
-- 				isDirect = tierItem.isDirect,
-- 			})
-- 		end
--     ::continue::
-- 	end
-- 	return tierArray
-- end

---Turns a tier result iterator into tierArrayItem[]
---@param items tierArrayItem[]
---@return tierArrayItem[]
local function toArray(items)
	---@type tierArray
	local array = {}
	for item in eachDependency(items) do
		---@type tierArrayItem
		lib.appendToArrayInTable(array, item.tier, {
			name = item.name,
			type = item.type
		})
	end
	return array
end

---Returns an iterator for the items
---@param items tierArrayItem[]
---@return unknown
function calculator.get(items)
	lib.log("Calculating items")
	local successfulItems, processed = {},{}
	lib.initTierMapTables(processed)
	for _, item in ipairs(items) do
		local tier = core.calculate(item.name, item.type)
		if tier >= 0 then
			successfulItems[#successfulItems+1] = item
		end
	end

	lib.log("Done!\n")
	return toArray(successfulItems)
end

---Just calls regular get for the item(s) set in the settings
function calculator.calculate()
	local itemString = lib.getSetting("tiergen-item-calculation") --[[@as string]]
	local itemIDs = lib.split(itemString, ",")
	---@type tierArrayItem[]
	local items = {}
	-- Trim whitespace
	for index, itemID in pairs(lib.split(itemString, ",")) do
		local cleanID = itemID:match("^%s*(.-)%s*$")
		items[#items+1] = {
			name = cleanID,
			type = "item"
		}
	end

	return calculator.get(items)
end

function calculator.reprocess()
	core.reprocess()
	calculator.updateBase()
end

-- TODO: refactor some more of tierCalculation into here

return calculator