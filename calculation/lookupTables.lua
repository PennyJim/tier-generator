--- A table of lookup tables
---@class LookupTables
local lookup = {}

--#region Standard lookup tables
---@type table<data.ItemID,data.RecipeID[]>
lookup.ItemRecipe = {}
---@type table<data.FluidID,data.RecipeID[]>
lookup.FluidRecipe = {}
---@type table<data.RecipeID,data.TechnologyID[]>
lookup.RecipeTechnology = {}
---@type table<data.RecipeCategoryID, data.ItemID[]>
lookup.CategoryItem = {}
--#endregion
--#region Fake recipe lookup tables

---@type table<data.ItemID,data.ItemID[]>
lookup.Burning = {}
---@class SingleItemFakeRecipe
---@field input data.ItemID
---@field category data.RecipeCategoryID
---@type table<data.ItemID,SingleItemFakeRecipe[]>
lookup.Rocket = {}
---@class SingleFluidFakeRecipe
---@field input data.FluidID
---@field category data.RecipeCategoryID
---@type table<data.FluidID,{input:data.FluidID,category:data.RecipeCategoryID}[]>
lookup.Boiling = {}
---@type table<data.FluidID,data.RecipeCategoryID[]>
lookup.OffshorePumping = {}
--#endregion

return lookup