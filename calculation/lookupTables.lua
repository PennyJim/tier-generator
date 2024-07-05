--- A table of lookup tables
---@class LookupTables
local lookup = {}

---@class OptionalItemFakeRecipe
---@field input data.ItemID?
---@field category data.RecipeCategoryID
---@class OptionalFluidFakeRecipe
---@field input data.FluidID?
---@field category data.RecipeCategoryID
---@class SingleFluidFakeRecipe
---@field input data.FluidID
---@field category data.RecipeCategoryID
---@class SingleItemFakeRecipe
---@field input data.ItemID
---@field category data.RecipeCategoryID
---@class CompleteFakeRecipe : fakePrototype
---@field id data.RecipeID
---@field isFluid boolean?
---@field enabled boolean
---@field category data.RecipeCategoryID
---@field technologies data.TechnologyID[]?
---@field ingredients Ingredient.base[]
---@field object_name "LuaRecipePrototype"

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

---@type table<data.ItemID,OptionalItemFakeRecipe[]>
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
---@type table<data.ItemID,CompleteFakeRecipe[]>
lookup.Injected = {}
--#endregion

return lookup