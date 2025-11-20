---@type modules.GuiModuleDef
---@diagnostic disable-next-line: missing-fields
local module = {
	module_type = "tiergen_selection_area",
	handlers = {}
}

---@class WindowState.tiergen_selection_area : modules.WindowState
-- Where custom fields would go

---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	children = {is_optional = false, type = {"table"}},
	caption = {is_optional = false, type = {"table", "string"}},
	confirm_name = {is_optional = false, type = {"string"}},
	confirm_locale = {is_optional = false, type = {"table", "string"}},
	confirm_handler = {is_optional = true, type = {"string"}},
	confirm_enabled_default = {is_optional = true, type = {"boolean"}, default = true},
	style_mods = {is_optional = true, type = {"table"}},
}

---@alias (partial) modules.types
---| "tiergen_selection_area"
---@alias (partial) modules.ModuleElems
---| SelectionAreaElem
---| ElemSelectorTableElem
---@class SelectionAreaElem
---@field module_type "tiergen_selection_area"
---@field args SelectionAreaArgs

---@class SelectionAreaArgs
-- where LuaLS parameter definitons go
---@field children modules.GuiElemDef[]
---@field caption LocalisedString
---@field confirm_name string
---@field confirm_locale LocalisedString
---@field confirm_handler string?
---@field confirm_enabled_default boolean?
---@field style_mods LuaStyle?

---Creates the frame for a window with an exit button
---@param params SelectionAreaArgs
---@return modules.GuiElemDef.base
function module.build_func(params)
	---@type modules.GuiElemDef[]
	local children = params.children
	-- Add the label as the first element
	table.insert(children, 1, {args = {
		type = "label", style = "caption_label",
		caption = params.caption
	}})

	-- Add the confirm button as last element
	table.insert(children, {
		args = {
			type = "flow", direction = "horizontal",
		},
		children = {
			{args={type = "empty-widget", style = "modules_horizontal_pusher"}},
			{
				args={
					type = "button", style = "tiergen_confirm_button",
					name = params.confirm_name,
					caption = params.confirm_locale,
				},
				handler = params.confirm_handler and {
					[defines.events.on_gui_click] = params.confirm_handler
				} or nil,
---@diagnostic disable-next-line: missing-fields
				elem_mods = params.confirm_enabled_default == false and {
					enabled = false
				} --[[@as LuaGuiElement]] or nil
			}
		}
	}--[[@as modules.GuiElemDef]])
	return {
		args = {
			type = "frame", style = "tiergen_selection_area_frame",
			style_mods = params.style_mods,
			direction = "vertical",
		},
		children = children
	}
end

return module --[[@as modules.GuiModuleDef]]