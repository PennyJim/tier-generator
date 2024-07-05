local core = require("__tier-generator__.calculation.tierCalculation")
local eachDependency = require("__tier-generator__.calculation.iterableDependencies")
---@class Calculator
local calculator = {}

local has_setup_core = false

---Tells the core calculator to drop its cache and consider sets its base items
local function updateBase()
	lib.log("Setting base item overrides")
	local baseItems = global.config.base_items
	for _, item in pairs(baseItems) do
		lib.log("\tSetting "..tostring(item).." to tier 0")
		core.set(item)
	end
	has_setup_core = true
end

---Calculates the tiers and returns items that were successful
---@param items simpleItem[]
---@return simpleItem[]
local function get(items)
	if not has_setup_core then
		updateBase()
	end
	---@type simpleItem[]
	local successfulItems = {}
	for _, item in ipairs(items) do
		local tier = core.calculate(item.name, item.type)
		if tier >= 0 then
			successfulItems[#successfulItems+1] = item
		end
	end
	return successfulItems
end
---Returns an iterator for the items and their dependencies
---@param items simpleItem[]
---@return fun(p1:DependencyIteratorState):simpleItem?
---@return DependencyIteratorState
function calculator.get(items)
	return eachDependency(get(items))
end
---Turns a tier result iterator into tierArrayItem[]
---@param items simpleItem[]
---@return {[integer]:simpleItem[]}
local function toArray(items)
	---@type tierArray
	local array = {}
	for item in eachDependency(items) do
		---@type simpleItem
		lib.appendToArrayInTable(array, item.count+1, {
			name = item.name,
			type = item.type
		})
	end
	return array
end
---Returns an array of the items and their dependencies
---@param items simpleItem[]
---@return {[integer]:simpleItem[]}
function calculator.getArray(items)
	return toArray(get(items))
end

function calculator.unprocess()
	core.unprocess()
	has_setup_core = false
end
function calculator.uncalculate()
	core.unset()
	has_setup_core = false
end

-- TODO: refactor some more of tierCalculation into here

return calculator