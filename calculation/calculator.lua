local lib = require("__tier-generator__.library")
local tier = require("__tier-generator__.calculation.tierCalculation")

lib.log("Setting base item overrides")
local baseItems = settings.startup["tiergen-base-items"].value --[[@as string]]
for _, itemID in pairs(lib.split(baseItems, ",")) do
	-- Trim whitespace
	itemID = itemID:match("^%s*(.-)%s*$")
	lib.log("\tSetting "..itemID.." to tier 0")
	tier.set(itemID)
end
lib.log("Calculating items")
local items = settings.startup["tiergen-item-calculation"].value --[[@as string]]
for _, itemID in pairs(lib.split(items, ",")) do
	-- Trim whitespace
	itemID = itemID:match("^%s*(.-)%s*$")
	tier.calculate(itemID)
end

lib.log("Done!\n")