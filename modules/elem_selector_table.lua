local module = {module_type = "elem_selector_table", handlers = {} --[[@as GuiModuleEventHandlers]]}

local handler_names = {
	-- A generic place to make sure handler names match
	-- in both handler definitons and in the build_func
	elem_changed = "elem_selector_table.elem_changed" -- Standardly prepended with module name to avoid naming collisions
}

---@class ElemList : {[integer]: string|SignalID}
---@field last integer The last index of a chosen element
---@field count integer How many elements have been chosen
--@field [integer] string|SignalID the chosen element at an index

---@class WindowState.ElemSelectorTable : WindowState
-- Where custom fields would go
---@field selector_table table<string,ElemList>
---@field selector_funcs selector_functions
---@field selector_enabled table<string,boolean>

---@class selector_functions
---@field valid boolean
---@field set_index (fun(state:WindowState.ElemSelectorTable,table_name:string,index:integer,value:string|SignalID):boolean)?
---@field update_rows fun(state:WindowState.ElemSelectorTable,table_name:string)?
---@field set_enabled fun(is_enabled:boolean)?

local selector_funcs = {valid = true}
---@param state WindowState.ElemSelectorTable
---@param table_name string
---@param index integer
---@param value string|SignalID
---@param reactionary true?
---@returns boolean did_change
function selector_funcs.set_index(state, table_name, index, value, reactionary)
	--MARK: set index
	local table = state.elems[table_name]
	local list = state.selector_table[table_name]

	local elem = table.children[index]
	old_value = list[index]

	if old_value == value then return false end

	-- Update the row-count
	if index > list.last then
		-- Set new last index and update rows
		list.last = index
		selector_funcs.update_rows(state, table.name)
	elseif index == list.last and value == nil then
		-- Decrement the last_index to the last item with a value
		for new_last = index, 0, -1 do
			if list[new_last] or new_last == 0 then
				list.last = new_last
				break
			end
		end
		-- Update the rows
		selector_funcs.update_rows(state, table.name)
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
	if not reactionary then
		elem.elem_value = value
	end
	return true
end
---@param state WindowState.ElemSelectorTable
---@param table_name string
function selector_funcs.update_rows(state, table_name) -- TODO: Add a setter instead of calling this constantly
	--MARK: update row
	local table = state.elems[table_name]
	local elem_type = table.tags["type"]

	local last_index = state.selector_table[table_name].last
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
			state.gui.add(state.namespace, table, {
				type = "choose-elem-button",
				elem_type = elem_type,
				handler = {[defines.events.on_gui_elem_changed] = handler_names.elem_changed}
			}, true)
		end
	end
end

local selector_meta = {__index = selector_funcs}
if not data then -- Is required during data to check its structure.
	script.register_metatable("update_row_meta", selector_meta)
end

---@param state WindowState.ElemSelectorTable
module.setup_state = function (state)
	state.selector_table = state.selector_table or {}
	state.selector_funcs = state.selector_funcs or setmetatable({valid = false}, selector_meta)

	-- Restore table entries
	for table_name, table_entries in pairs(state.selector_table) do
		local table = state.elems[table_name]
		local type = table.children[1].elem_type
		selector_funcs.update_rows(state, table_name)
		for index, item in pairs(table_entries) do
			table.children[index].elem_value = item
		end
	end
end

---@class ElemSelectorTableParams : ModuleDef
---@field module_type "elem_selector_table"
-- where LuaLS parameter definitons go
---@field name string
---@field height integer How many elements tall this table takes up
---@field width integer How many elements wide this table is
---@field elem_type ElemType
---@field frame_style string
---@field on_elem_changed string?
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
	---@type GuiElemModuleDef
	local button = {
		type = "choose-elem-button",
		elem_type = params.elem_type,
		handler = {[defines.events.on_gui_elem_changed] = handler_names.elem_changed}
		-- style = "slot_button",
	}
	---@type GuiElemModuleDef[]
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
								tags = {["type"] = params.elem_type},
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
---@param state WindowState.ElemSelectorTable
---@param OriginalEvent EventData.on_gui_elem_changed
module.handlers[handler_names.elem_changed] = function (state, elem, OriginalEvent)
	local table = elem.parent --[[@as LuaGuiElement]]
	local elem_list = state.selector_table[table.name] or {count=0,last=0} --[[@as ElemList]]
	state.selector_table[table.name] = elem_list
	local index = elem.get_index_in_parent()

	local did_change = selector_funcs.set_index(state, table.name, index, elem.elem_value, true)

	return did_change and table or nil
end

return module --[[@as GuiModuleDef]]