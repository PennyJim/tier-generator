local lib = require("__tier-generator__.library")
local tier = require("__tier-generator__.calculation.tierCalculation")

return {
	calculate = function ()
		tier.uncalculate()
		lib.log("Setting base item overrides")
		local baseItems = lib.getSetting("tiergen-base-items") --[[@as string]]
		for _, itemID in pairs(lib.split(baseItems, ",")) do
			-- Trim whitespace
			itemID = itemID:match("^%s*(.-)%s*$")
			lib.log("\tSetting "..itemID.." to tier 0")
			tier.set(itemID)
		end
		lib.log("Calculating items")
		local items = lib.getSetting("tiergen-item-calculation") --[[@as string]]
		for _, itemID in pairs(lib.split(items, ",")) do
			-- Trim whitespace
			itemID = itemID:match("^%s*(.-)%s*$")
			tier.calculate(itemID)
		end
	
		lib.log("Done!\n")
	
		return tier.get()
	end,
	clearCache = tier.clearCache
}