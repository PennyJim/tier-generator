local default_items = "space-science-pack"
local default_bases = "raw-fish"
local default_ignored = ""

if mods["Ultracube"] then
	default_items = "cube-complete-annihilation-card"
	default_bases = "cube-ultradense-utility-cube"
end

data:extend{
	{
		type = "bool-setting",
		name = "tiergen-reduce-category",
		setting_type = "startup",
		default_value = true,
		order = "startup-a[category]"
	},
	{
		type = "bool-setting",
		name = "tiergen-reduce-technology",
		setting_type = "startup",
		default_value = true,
		order = "startup-a[technology]"
	},
	{
		type = "string-setting",
		name = "tiergen-item-calculation",
		setting_type = "startup",
		default_value = default_items,
		order = "startup-b"
	},
	{
		type = "string-setting",
		name = "tiergen-base-items",
		setting_type = "startup",
		default_value = default_bases,
		allow_blank = true,
		order = "startup-c"
	},
	{
		type = "string-setting",
		name = "tiergen-ignored-recipes",
		setting_type = "startup",
		default_value = default_ignored,
		allow_blank = true,
		order = "startup-d"
	},
	{
		type = "bool-setting",
		name = "tiergen-debug-log",
		setting_type = "startup",
		default_value = false,
		order = "startup-z",
	}
}