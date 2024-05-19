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

log(serpent.dump(tier.get()))

-- Smuggle out
local extension = {}
extension[#extension+1] = {
	type = "recipe-category",
	name = "tiergen"
}
extension[#extension+1] = {
	type = "item-subgroup",
	name = "tiergen",
	group = "other"
}
for curTier, itemArray in ipairs(tier.get()) do
	curTier = curTier - 1
	local normalized_tier = string.format("%03d", curTier)
	---@type data.RecipePrototype
	local tierRecipe = {
		type = "recipe",
		name = "tier"..normalized_tier,
		category = "tiergen",
		subgroup = "tiergen",
		icon = "__base__/graphics/icons/iron-gear-wheel.png",
		icon_size = 64, icon_mipmaps = 4,
		order = normalized_tier,
		ingredients = {},
		results = {},
		allow_decomposition = false,
	}

	for _, itemID in ipairs(itemArray) do
		local isItem, itemType = pcall(lib.resolveItemType, itemID)
		if isItem then
			itemType = "item"
		else
			itemType = "fluid"
		end
		local ingredient = {
			type = itemType,
			name = itemID,
			amount = 1,
		}
		tierRecipe.ingredients[#tierRecipe.ingredients+1] = ingredient
	end
	extension[#extension+1] = tierRecipe
end
data:extend(extension)