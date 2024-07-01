local iron_gear = data.raw["item"]["iron-gear-wheel"]
data:extend{
	{
		type = "custom-input",
		name = "tiergen-menu",
		key_sequence = "SHIFT + T",
		action = "lua",
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

local styles = data.raw["gui-style"].default
styles.tiergen_tabbed_pane = {
	type = "tabbed_pane_style",
	tab_content_frame = {
		type = "frame_style",
		parent = "tabbed_pane_frame",
		graphical_set = {
			base = {
				top = {position = {76, 0}, size = {1, 8}},
				center = {position = {76, 8}, size = {1, 1}}
			},
			shadow = top_shadow
		}
	}
}

styles.tiergen_elem_selector_table_frame = {
	type = "frame_style",
	parent = "deep_frame_in_shallow_frame",
	left_margin = 12
}
styles.tiergen_confirm_button = {
	type = "button_style",
	parent = "confirm_button_without_tooltip",
	minimal_width = 0,
	right_margin = 4,
	top_margin = 4,
}

--#region Isn't scalable
-- Only works on 125% scale
-- styles.tiergen_wide_horizontal_flow = {
-- 	type = "horizontal_flow_style",
-- 	left_padding = -7,
-- 	right_padding = -3,
-- 	horizontal_spacing = 0
-- }
-- data:extend{
-- 	{
-- 		type = "sprite",
-- 		name = "bottom_left_inside_corner",
-- 		filename = styles.default_tileset,
-- 		position = {85, 9},
-- 		size = {8, 8},
-- 		flags = {
-- 			"gui"
-- 		}
-- 	},
-- 	{
-- 		type = "sprite",
-- 		name = "bottom_right_inside_corner",
-- 		filename = styles.default_tileset,
-- 		position = {94, 9},
-- 		size = {8, 8},
-- 		flags = {
-- 			"gui"
-- 		}
-- 	}
-- }
--#endregion