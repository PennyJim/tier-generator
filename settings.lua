local default_items = "space-science-pack"
local default_bases = "raw-fish"
local default_ignored = ""

data:extend{
	{
		type = "bool-setting",
		name = "tiergen-reduce-category",
		setting_type = "runtime-global",
		default_value = true,
		order = "global-a[category]"
	},
	{
		type = "bool-setting",
		name = "tiergen-consider-technology",
		setting_type = "runtime-global",
		default_value = true,
		order = "global-a[technology-a]"
	},
	{
		type = "bool-setting",
		name = "tiergen-reduce-technology",
		setting_type = "runtime-global",
		default_value = true,
		order = "global-a[technology-b]"
	},
	{
		type = "string-setting",
		name = "tiergen-item-calculation",
		setting_type = "runtime-global",
		default_value = default_items,
		order = "global-b"
	},
	{
		type = "string-setting",
		name = "tiergen-base-items",
		setting_type = "runtime-global",
		default_value = default_bases,
		allow_blank = true,
		order = "global-c"
	},
	{
		type = "string-setting",
		name = "tiergen-ignored-recipes",
		setting_type = "runtime-global",
		default_value = default_ignored,
		allow_blank = true,
		order = "global-d"
	},
	{
		type = "bool-setting",
		name = "tiergen-debug-log",
		setting_type = "runtime-global",
		default_value = false,
		order = "global-z",
	}
}