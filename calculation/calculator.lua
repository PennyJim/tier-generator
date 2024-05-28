local tier = require("__tier-generator__.calculation.tierCalculation")

local function updateBase ()
	tier.unset()
	lib.log("Setting base item overrides")
	local baseItems = lib.getSetting("tiergen-base-items") --[[@as string]]
	for _, itemID in pairs(lib.split(baseItems, ",")) do
		-- Trim whitespace
		itemID = itemID:match("^%s*(.-)%s*$")
		lib.log("\tSetting "..itemID.." to tier 0")
		tier.set(itemID)
	end
end

-- TODO: refactor some of tierCalculation into here

return {
	calculate = function ()
		lib.log("Calculating items")
		local itemString = lib.getSetting("tiergen-item-calculation") --[[@as string]]
		local itemIDs = lib.split(itemString, ",")
		-- Trim whitespace
		for index, itemID in pairs(lib.split(itemString, ",")) do
			itemIDs[index] = itemID:match("^%s*(.-)%s*$")
		end
	
		lib.log("Done!\n")
	
		return tier.get(itemIDs, "item")
	end,
	get = tier.get,
	updateBase = updateBase,
	reprocess = function ()
		tier.reprocess()
		updateBase()
	end
}