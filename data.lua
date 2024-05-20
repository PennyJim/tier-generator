local iron_gear = data.raw["item"]["iron-gear-wheel"]
data:extend{
	{
		type = "shortcut",
		name = "tiergen-menu",
		action = "lua",
		icon = {
			filename = iron_gear.icon,
			size = iron_gear.icon_size,
			mipmap_count = iron_gear.icon_mipmaps,
		},
		toggleable = true,
	}
}