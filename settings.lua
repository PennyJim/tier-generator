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
		default_value = "space-science-pack",
		order = "startup-b"
	},
	{
		type = "string-setting",
		name = "tiergen-base-items",
		setting_type = "startup",
		default_value = "raw-fish",
		allow_blank = true,
		order = "startup-c"
	},
	{
		type = "string-setting",
		name = "tiergen-ignored-recipes",
		setting_type = "startup",
		default_value = "",
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