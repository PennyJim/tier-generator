local module = {module_type = "elem_selector_table", handlers = {} --[[@as GuiModuleEventHandlers]]}

local handler_names = {
	-- A generic place to make sure handler names match
	-- in both handler definitons and in the build_func
	elem_changed = "elem_selector_table.elem_changed" -- Standardly prepended with module name to avoid naming collisions
}

---@class ElemList
---@field last integer The last index of a chosen element
---@field count integer How many elements have been chosen
---@field [integer] string|SignalID the chosen element at an index

---@class WindowState.ElemSelectorTable : WindowState
-- Where custom fields would go
---@field selector_table table<string,ElemList>
---@field selector_update_rows update_row_obj

---@class update_row_obj
---@field valid boolean
---@field call fun(table:LuaGuiElement,last_index:integer,elem_type:ElemType,self:WindowState.ElemSelectorTable)?
local update_row_meta = {__index = {
	valid = false,

	---@param table LuaGuiElement
	---@param last_index integer
	---@param elem_type ElemType
	---@param self WindowState.ElemSelectorTable
	call = function (table, last_index, elem_type, self)
		local columns = table.column_count
		local desired_rows = math.ceil(last_index/columns)+1
		local children = table.children
		local children_count = #children
		local current_rows = children_count/columns
		if current_rows > desired_rows then
			-- Remove elements
			for remove_index = children_count, desired_rows*columns+1, -1 do
				children[remove_index].destroy()
			end
		else
			-- Add elements
			for _ = children_count, desired_rows*columns-1, 1 do
				self.gui.add(self.namespace, table, {
					type = "choose-elem-button",
					elem_type = elem_type,
					handler = {[defines.events.on_gui_elem_changed] = handler_names.elem_changed}
				}, true)
			end
		end
	end
}}
if not data then -- Is required during data to check its structure.
	script.register_metatable("update_row_meta", update_row_meta)
end

---@param self WindowState.ElemSelectorTable
module.setup_state = function (self)
	self.selector_table = self.selector_table or {}
	self.selector_update_rows = self.selector_update_rows or setmetatable({valid = false}, update_row_meta)
end

---@class ElemSelectorTableParams : ModuleDef
---@field module_type "elem_selector_table"
---@field name string
---@field height integer How many elements tall this table takes up
---@field width integer How many elements wide this table is
---@field elem_type ElemType
---@field frame_style string
---@field on_elem_changed string?
-- where LuaLS parameter definitons go
---@type ModuleParameterDict
module.parameters = {
	-- Where gui-modules parameter definitons go
	name = {is_optional = false, type = {"string"}},
	height = {is_optional = false, type = {"number"}},
	width  = {is_optional = false, type = {"number"}},
	elem_type = {
		is_optional = false, type = {"string"},
		enum = {
			"achievement",
			"decorative",
			"entity",
			"equipment",
			"fluid",
			"item",
			"item-group",
			"recipe",
			"signal",
			"technology",
			"tile",
		}
	},
	frame_style = {is_optional = true, type = {"string"}},
	on_elem_changed = {is_optional = true, type = {"string"}}
}

---Creates the frame for a window with an exit button
---@param params ElemSelectorTableParams
---@return GuiElemDef
function module.build_func(params)
	local button = {
		type = "choose-elem-button",
		elem_type = params.elem_type,
		handler = {[defines.events.on_gui_elem_changed] = handler_names.elem_changed}
		-- style = "slot_button",
	}
	local buttons = {}
	for i = 1, params.width, 1 do
		buttons[i] = button
	end
	return {
		type = "frame", style = params.frame_style,
		children = {
			{
				type = "scroll-pane", style = "naked_scroll_pane",
---@diagnostic disable-next-line: missing-fields
				style_mods = {height = 40*params.height},
				children = {
					{
						type = "frame", style = "slot_button_deep_frame",
						children = {
							{
								type = "table", style = "filter_slot_table",
								name = params.name, column_count = params.width,
---@diagnostic disable-next-line: missing-fields
								style_mods = {
									width = 40*params.width,
									minimal_height = 40*params.height,
								},
								children = buttons,
								handler = params.on_elem_changed and {[defines.events.on_gui_elem_changed] = params.on_elem_changed} or nil
							}
						}
					}
				}
			}
		}
	} --[[@as GuiElemDef]]
end

-- How to define handlers
---@param self WindowState.ElemSelectorTable
---@param OriginalEvent EventData.on_gui_elem_changed
module.handlers[handler_names.elem_changed] = function (self, elem, OriginalEvent)
	local table = elem.parent --[[@as LuaGuiElement]]
	local elem_list = self.selector_table[table.name] or {count=0,last=0} --[[@as ElemList]]
	self.selector_table[table.name] = elem_list
	local elem = OriginalEvent.element
	local index = elem.get_index_in_parent()
	local type = elem.elem_type
	local new_value, old_value = elem.elem_value, elem_list[index]

	-- Element was not actually changed
	if new_value == old_value then return end

	-- Update the count
	if new_value == nil
	and old_value ~= nil then
		elem_list.count = elem_list.count - 1
	elseif new_value ~= nil
	and old_value == nil then
		elem_list.count = elem_list.count + 1
	end

	-- Update list
	elem_list[index] = new_value


	if index > elem_list.last then
		-- Set new last index and update rows
		elem_list.last = index
		self.selector_update_rows.call(table, index, type, self)
	elseif index == elem_list.last then
		-- Decrement the last_index to the last item with a value
		for new_last = index, 0, -1 do
			if elem_list[new_last] or new_last == 0 then
				elem_list.last = new_last
				break
			end
		end
		-- Update the rows
		local last_index = elem_list.last
		self.selector_update_rows.call(table, last_index, type, self)
	end

	return table
end

return module --[[@as GuiModuleDef]]