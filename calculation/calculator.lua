local core = require("__tier-generator__.calculation.tierCalculation")
local eachDependency = require("__tier-generator__.calculation.itterableDependencies")
---@class Calculator
local calculator = {}

---Tells the core calculator to drop its cache and consider sets its base items
function calculator.updateBase()
	core.unset()
	lib.log("Setting base item overrides")
	local baseItems = global.config.base_items
	for _, item in pairs(baseItems) do
		lib.log("\tSetting "..item.." to tier 0")
		core.set(item)
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

---Calculates the tiers and returns items that were successful
---@param items simpleItem[]
---@return simpleItem[]
local function get(items)
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
	return successfulItems
end
---Returns an iterator for the items and their dependencies
---@param items simpleItem[]
---@return fun(p1:DependencyIteratorState):tierResult?
---@return DependencyIteratorState
function calculator.get(items)
	return eachDependency(get(items))
end
---Turns a tier result iterator into tierArrayItem[]
---@param items simpleItem[]
---@return simpleItem[]
local function toArray(items)
	---@type tierArray
	local array = {}
	for item in eachDependency(items) do
		---@type simpleItem
		lib.appendToArrayInTable(array, item.tier+1, {
			name = item.name,
			type = item.type
		})
	end
	return array
end
---Returns an array of the items and their dependencies
---@param items simpleItem[]
---@return simpleItem[]
function calculator.getArray(items)
	return toArray(get(items))
end

function calculator.reprocess()
	core.reprocess()
	calculator.updateBase()
end

-- TODO: refactor some more of tierCalculation into here

return calculator