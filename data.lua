local iron_gear = data.raw["item"]["iron-gear-wheel"]
---@type data.ElementImageSet
top_shadow = top_shadow

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
			shadow = top_shadow --[[@as data.ElementImageSetLayer]]
		}
	}
}

styles.tiergen_elem_selector_table_frame = {
	type = "frame_style",
	parent = "deep_frame_in_shallow_frame",
	left_margin = 12
}
styles.tiergen_selection_area_frame = {
	type = "frame_style",
	parent = "bordered_frame_with_extra_side_margins",
	top_margin = 4,
	bottom_padding = 4,
}
styles.tiergen_confirm_button = {
	type = "button_style",
	parent = "confirm_button_without_tooltip",
	minimal_width = 0,
	right_margin = 4,
	top_margin = 4,
}

local label_padding = 4
local label_widths = {37,45,53}
styles.tiergen_tierlabel = {
	type = "label_style",
	right_padding = label_padding
}
local background_graphical_set = styles.slot_button_deep_frame.background_graphical_set
local tierlist_background = table.deepcopy(background_graphical_set)
tierlist_background.overall_tiling_vertical_spacing = 12
tierlist_background.overall_tiling_vertical_padding = 6
tierlist_background.custom_horizontal_tiling_sizes = {
	5, -- Visually obviously wrong
	32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32
}
local tierlist_backgrounds = {
	tierlist_background,
	table.deepcopy(tierlist_background),
	table.deepcopy(tierlist_background),
}
tierlist_backgrounds[1].custom_horizontal_tiling_sizes[1] = label_padding + label_widths[1]
styles.tiergen_tierlist_background = {
	type = "frame_style",
	parent = "slot_button_deep_frame",
	vertically_stretchable = "on",
	horizontally_stretchable = "on",
}
styles.tiergen_tierlabel_1 = {
	type = "label_style",
	parent = "tiergen_tierlabel",
	width = label_widths[1]
}
tierlist_backgrounds[1].custom_horizontal_tiling_sizes[1] = label_padding + label_widths[1]
styles.tiergen_tierlist_1_background = {
	type = "frame_style",
	parent = "tiergen_tierlist_background",
	background_graphical_set = tierlist_backgrounds[1]
}
styles.tiergen_tierlabel_2 = {
	type = "label_style",
	parent = "tiergen_tierlabel",
	width = label_widths[2]
}
tierlist_backgrounds[2].custom_horizontal_tiling_sizes[1] = label_padding + label_widths[2]
styles.tiergen_tierlist_2_background = {
	type = "frame_style",
	parent = "tiergen_tierlist_background",
	background_graphical_set = tierlist_backgrounds[2]
}
styles.tiergen_tierlabel_3 = {
	type = "label_style",
	parent = "tiergen_tierlabel",
	width = label_widths[3]
}
tierlist_backgrounds[3].custom_horizontal_tiling_sizes[1] = label_padding + label_widths[3]
styles.tiergen_tierlist_3_background = {
	type = "frame_style",
	parent = "tiergen_tierlist_background",
	background_graphical_set = tierlist_backgrounds[3]
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