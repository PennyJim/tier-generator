---@type modules.GuiModuleDef
---@diagnostic disable-next-line: missing-fields
local module = {
	module_type = "elem_selector_table",
	handlers = {}
}

local handler_names = {
	-- A generic place to make sure handler names match
	-- in both handler definitons and in the build_func
	elem_changed = "elem_selector_table.elem_changed" -- Standardly prepended with module name to avoid naming collisions
}

---@class ElemList : {[integer]: string|SignalID}
---@field last integer The last index of a chosen element
---@field count integer How many elements have been chosen
--@field [integer] string|SignalID the chosen element at an index

---@class WindowState.ElemSelectorTable : modules.WindowState
-- Where custom fields would go
---@field selector_table table<string,ElemList>
---@field selector_funcs selector_functions
---@field selector_enabled table<string,boolean>

---@class selector_functions
---@field valid boolean
---@field clear fun(state:WindowState.ElemSelectorTable,table_name:string)?
---@field set_index (fun(state:WindowState.ElemSelectorTable,table_name:string,index:integer,value:string|SignalID?):boolean)?
---@field set_enabled fun(state:WindowState.ElemSelectorTable,table_name:string,enabled:boolean)?

---@param state WindowState.ElemSelectorTable
---@param table LuaGuiElement
---@param last integer
local function update_rows(state, table, last) -- TODO: Add a setter instead of calling this constantly
	--MARK: update row
	local elem_type = table.tags["type"] --[[@as ElemType]]
	local enabled = table.enabled

	local columns = table.column_count
	local desired_rows = math.ceil(last/columns)+1

	local children = table.children
	local children_count = #children
	local current_rows = children_count/columns

	---@type modules.GuiElemDef
	local new_child = {
		args = {
			type = "choose-elem-button",
			elem_type = elem_type,
		},
		handler = {[defines.events.on_gui_elem_changed] = handler_names.elem_changed},
		elem_mods = not enabled and {enabled = enabled} or nil
	}

	if current_rows > desired_rows then
		-- Remove elements
		for remove_index = children_count, desired_rows*columns+1, -1 do
			children[remove_index].destroy()
		end
	else
		-- Add elements
		for _ = children_count, desired_rows*columns-1, 1 do
			state.gui.add(state.namespace, table, new_child)
		end
	end
end

local selector_funcs = {valid = true}
---@param state WindowState.ElemSelectorTable
---@param table_name string
function selector_funcs.clear(state, table_name)
	state.selector_table[table_name] = {count=0,last=0}
	local table = state.elems[table_name]
	update_rows(state, table, 0)
	for _, elem in pairs(table.children) do
		elem.elem_value = nil
	end
end
---@param state WindowState.ElemSelectorTable
---@param table_name string
---@param index integer
---@param value string|SignalID?
---@param update_elem false?
---@returns boolean did_change
function selector_funcs.set_index(state, table_name, index, value, update_elem)
	--MARK: set index
	local table = state.elems[table_name]
	local list = state.selector_table[table_name]

	local elem = table.children[index]
	old_value = list[index]

	if old_value == value then return false end
	update_elem = update_elem ~= false

	-- Update the row-count
	if index > list.last then
		-- Set new last index and update rows
		list.last = index
		update_rows(state, table, index)
	elseif index == list.last and value == nil then
		-- Decrement the last_index to the last item with a value
		for new_last = index-1, 0, -1 do
			if list[new_last] or new_last == 0 then
				list.last = new_last
				break
			end
		end
		-- Update the rows
		update_rows(state, table, list.last)

		-- Don't update if it'll modify a deleted element
		if update_elem then
			local last_real = #table.children
			update_elem = index <= last_real
		end
	end

	-- Update the count
	if value == nil
	and old_value ~= nil then
		list.count = list.count - 1
	elseif value ~= nil
	and old_value == nil then
		list.count = list.count + 1
	end

	-- Update list (and elem)
	list[index] = value
	if update_elem then
		elem.elem_value = value
	end
	return true
end
---@param state WindowState.ElemSelectorTable
---@param table_name string
---@param enabled boolean
function selector_funcs.set_enabled(state, table_name, enabled)
	--MARK: set enabled
	local table = state.elems[table_name]
	state.selector_enabled[table_name] = enabled

	if table.enabled ~= enabled then
		table.enabled = enabled
		table.ignored_by_interaction = not enabled
		for _, button in pairs(table.children) do
			button.enabled = enabled
			button.ignored_by_interaction = not enabled
		end
	end
end

local selector_meta = {__index = selector_funcs}
if not data then -- Is required during data to check its structure.
	script.register_metatable("update_row_meta", selector_meta)
end
local selector_with_meta = setmetatable({}, selector_meta)

---@param state WindowState.ElemSelectorTable
module.setup_state = function (state)
	--MARK: setup
	state.selector_table = state.selector_table or {}
	state.selector_enabled = state.selector_enabled or {}
	state.selector_funcs = state.selector_funcs or selector_with_meta

	-- Restore enabled status
	for table_name, enabled in pairs (state.selector_enabled) do
		selector_funcs.set_enabled(state, table_name, enabled)
	end
	-- Restore table entries
	for table_name, table_entries in pairs(state.selector_table) do
		local table = state.elems[table_name]
		update_rows(state, table, table_entries.last)
		for index, item in pairs(table_entries) do
			if type(index) == "number" then
				table.children[index].elem_value = item
			end
		end
	end
end

---@alias (partial) modules.types
---| "elem_selector_table"
---@alias (partial) modules.ModuleElem
---| ElemSelectorTableElem
---@class ElemSelectorTableElem
---@field module_type "elem_selector_table"
---@field args ElemSelectorTableArgs

---@class ElemSelectorTableArgs
-- where LuaLS parameter definitons go
---@field name string
---@field height integer How many elements tall this table takes up
---@field width integer How many elements wide this table is
---@field elem_type ElemType
---@field frame_style string
---@field on_elem_changed string?
---@type ModuleParameterDict
module.parameters = {
	--MARK: parameters
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
---@param params ElemSelectorTableArgs
---@return modules.GuiElemDef.base
function module.build_func(params)
	--MARK: build
	---@type modules.GuiElemDef
	local button = {
		args = {
			type = "choose-elem-button",
			elem_type = params.elem_type,
		},
		handler = {[defines.events.on_gui_elem_changed] = handler_names.elem_changed}
		-- style = "slot_button",
	}
	---@type modules.GuiElemDef[]
	local buttons = {}
	for i = 1, params.width, 1 do
		buttons[i] = button
	end
	return {
		args = {
			type = "frame", style = params.frame_style,
		},
		children = {
			{
				args = {
					type = "scroll-pane", style = "naked_scroll_pane",
				},
---@diagnostic disable-next-line: missing-fields
				style_mods = {height = 40*params.height},
				children = {
					{
						args = {
							type = "frame", style = "slot_button_deep_frame",
						},
						children = {
							{
								args = {
									type = "table", style = "filter_slot_table",
									name = params.name, column_count = params.width,
									tags = {["type"] = params.elem_type},
								},
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
	} --[[@as modules.GuiElemDef.base]]
end

-- How to define handlers
---@param state WindowState.ElemSelectorTable
---@param OriginalEvent EventData.on_gui_elem_changed
module.handlers[handler_names.elem_changed] = function (state, elem, OriginalEvent)
	--MARK: on_elem_changed
	local table = elem.parent --[[@as LuaGuiElement]]
	local elem_list = state.selector_table[table.name] or {count=0,last=0} --[[@as ElemList]]
	state.selector_table[table.name] = elem_list
	local index = elem.get_index_in_parent()

	local did_change = selector_funcs.set_index(state, table.name, index, elem.elem_value--[[@as SignalID]], false)

	return did_change and table or nil
end

return module --[[@as modules.GuiModuleDef]]