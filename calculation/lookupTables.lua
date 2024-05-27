--- A table of lookup tables
---@class LookupTables
local lookup = {}

---@class OptionalFluidFakeRecipe
---@field input data.FluidID?
---@field category data.RecipeCategoryID
---@class SingleFluidFakeRecipe
---@field input data.FluidID
---@field category data.RecipeCategoryID
---@class SingleItemFakeRecipe
---@field input data.ItemID
---@field category data.RecipeCategoryID

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

---@type table<data.ItemID,OptionalFluidFakeRecipe[]>
lookup.ItemMining = {}
---@type table<data.FluidID,OptionalFluidFakeRecipe[]>
lookup.FluidMining = {}
---@type table<data.ItemID,data.RecipeCategoryID[]>
lookup.HandMining = {}
---@type table<data.ItemID,data.ItemID[]>
lookup.Burning = {}
---@type table<data.ItemID,data.RecipeCategoryID[]>
lookup.Rocket = {}
---@type table<data.FluidID,SingleFluidFakeRecipe[]>
lookup.Boiling = {}
---@type table<data.FluidID,data.RecipeCategoryID[]>
lookup.OffshorePumping = {}
--#endregion

return lookup