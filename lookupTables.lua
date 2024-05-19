--- A table of lookup tables
---@class LookupTables
local lookup = {}

---@type table<data.ItemID,data.RecipeID[]>
lookup.ItemRecipe = {}
---@type table<data.FluidID,data.RecipeID[]>
lookup.FluidRecipe = {}
---@type table<data.RecipeID,data.TechnologyID[]>
lookup.RecipeTechnology = {}
---@type table<data.ItemID,data.ItemID[]>
lookup.Burning = {}
---@type table<data.ItemID,data.ItemID[]>
lookup.Rocket = {}
---@type table<data.RecipeCategoryID, data.ItemID[]>
lookup.CategoryItem = {}
---@type table<data.ItemID, data.ItemSubGroupID>
lookup.ItemType = {}

return lookup