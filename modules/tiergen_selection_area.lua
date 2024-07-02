local module = {module_type = "tiergen_selection_area", handlers = {} --[[@as GuiModuleEventHandlers]]}

---@class WindowState.tiergen_selection_area : WindowState
-- Where custom fields would go

---@class SelectionAreaParams : ModuleDef
---@field module_type "tiergen_selection_area"
-- where LuaLS parameter definitons go
---@field children GuiElemModuleDef[]
---@field caption LocalisedString
---@field confirm_name string
---@field confirm_locale LocalisedString
---@field confirm_handler string?
---@field style_mods LuaStyle?

---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	children = {is_optional = false, type = {"table"}},
	caption = {is_optional = false, type = {"table", "string"}},
	confirm_name = {is_optional = false, type = {"string"}},
	confirm_locale = {is_optional = false, type = {"table", "string"}},
	confirm_handler = {is_optional = true, type = {"string"}},
	style_mods = {is_optional = true, type = {"table"}},
}

---Creates the frame for a window with an exit button
---@param params SelectionAreaParams
---@return GuiElemDef
function module.build_func(params)
	---@type GuiElemModuleDef[]
	local children = params.children
	-- Add the label as the first element
	table.insert(children, 1, {
		type = "label", style = "caption_label",
		caption = params.caption
	})

	-- Add the confirm button as last element
	table.insert(children, {
		type = "flow", direction = "horizontal",
		children = {
			{type = "empty-widget", style = "flib_horizontal_pusher"},
			{
				type = "button", style = "tiergen_confirm_button",
				name = params.confirm_name,
				caption = params.confirm_locale,
				handler = params.confirm_handler and {
					[defines.events.on_gui_click] = params.confirm_handler
				} or nil
			}
		}
	})
	return {
		type = "frame", style = "tiergen_selection_area_frame",
		style_mods = params.style_mods,
		direction = "vertical",
		children = children
	}
end

return module --[[@as GuiModuleDef]]