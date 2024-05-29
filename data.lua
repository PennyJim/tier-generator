local iron_gear = data.raw["item"]["iron-gear-wheel"]
data:extend{
	{
		type = "custom-input",
		name = "tiergen-menu",
		key_sequence = "SHIFT + T"
	},
	{
		type = "shortcut",
		name = "tiergen-menu",
		associated_control_input = "tiergen-menu",
		action = "lua",
		icon = {
			filename = iron_gear.icon,
			size = iron_gear.icon_size,
			mipmap_count = iron_gear.icon_mipmaps,
		},
		toggleable = true,
	}
}