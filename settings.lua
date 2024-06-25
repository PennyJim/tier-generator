local default_items = "space-science-pack"
local default_bases = "raw-fish"
local default_ignored = ""

data:extend{
	{
		type = "bool-setting",
		name = "tiergen-consider-autoplace-setting",
		setting_type = "runtime-global",
		default_value = true,
		order = "global-a[autoplace]"
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
		type = "bool-setting",
		name = "tiergen-reduce-category",
		setting_type = "runtime-global",
		default_value = true,
		order = "global-b[category]"
	},
	{
		type = "bool-setting",
		name = "tiergen-debug-log",
		setting_type = "runtime-global",
		default_value = false,
		order = "global-z",
	}
}