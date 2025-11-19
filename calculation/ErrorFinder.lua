local core = require("__tier-generator__.calculation.tierCalculation")
---Either print or log depending on if player_index is positive
---@param player_index integer
---@param message LocalisedString
local function print(player_index, message)
	if player_index >= 0 then
		lib.print(player_index, message)
	else
		lib.log(message)
	end
end

local error_messages = {
	[-100] = "tiergen-debug-command.invalid-item",
	[ -99] = "tiergen-debug-command.errored-out",
	[ -97] = "tiergen-debug-command.no-recipe",
}

---Processes the result
---@param player_index integer
---@param item data.ItemID
---@param result integer
---@return boolean seek_further Whether or not to follow this item's ingredients
local function process_result(player_index, item, result)
	if result >= 0 then
		print(player_index, {"tiergen-debug-command.calculated-tier", item, result})
		return false
	end

	local error_message = error_messages[result]
	if error_message then
		print(player_index, {error_message, item})
		return false
	else
		local result_reason = core.invalid_lookup(result)
		print(player_index, {"tiergen-debug-command.invalid-reason", item, result_reason})
	end

	return true
end

---@class TierStorage
---@field debug_table table<integer, debug_state>

---@class debug_state
---@field last_index integer
---@field cur_index integer
---@field [integer] table<string,"item"|"fluid">
---@field considered_items table<string, true>

---Gets the ingredients of the next item and then process's them
---@param player_index integer
---@param item data.ItemID
---@param item_type "item"|"fluid"
---@param debug_state debug_state
local function process_ingredients(player_index, item, item_type, debug_state)
	local result = core.calculate(item, item_type)
	local continue = process_result(player_index, item, result)

	if continue then
		local new_index = debug_state.last_index + 1
		debug_state.last_index = new_index
		local new_ingredients = core.get_ingredients(item, item_type)
		local considered_items = debug_state.considered_items
		-- Remove considered items
		for item in pairs(new_ingredients) do
			if considered_items[item] then
				new_ingredients[item] = nil
			else
				considered_items[item] = true
			end
		end
		debug_state[new_index] = new_ingredients
	end
end

local function debug_command_tick()
	local debug_table = storage.debug_table
	---@type integer[]
	local finished_players = {}

	for player_index, debug_state in pairs(debug_table or {}) do
		local cur_index = debug_state.cur_index + 1
		debug_state.cur_index = cur_index
		local ingredients = debug_state[cur_index]

		for item, item_type in pairs(ingredients) do
			process_ingredients(player_index, item, item_type, debug_state)
		end
	
		if not debug_state[cur_index+1] then
			finished_players[#finished_players+1] = player_index
		end
	end

	for _, player in pairs(finished_players) do
		debug_table[player] = nil
	end

	if next(debug_table) then
		lib.tick_later("debug_command_tick")
	end
end
lib.register_func("debug_command_tick", debug_command_tick)

commands.add_command("tierdebug", {"tiergen-debug-command.help"}, function (CommandData)
	local player_index = CommandData.player_index or -1

	local item = CommandData.parameter
	if not item then
		print(player_index, {"tiergen-debug-command.no-item-passed"})
		return
	end

	---@type table<integer,debug_state>
	local debug_table = storage.debug_table or {}
	storage.debug_table = debug_table
	if debug_table[player_index] then
		print(player_index, {"tiergen-debug-command.already-debugging"})
		return
	end

	local result = core.calculate(item, "item")
	if not process_result(player_index, item, result) then
		return
	end

	local debug_state = {
		cur_index = 0, last_index = 0,
		considered_items = {}
	}
	storage.debug_table[player_index] = debug_state
	process_ingredients(player_index, item, "item", debug_state)

	lib.tick_later("debug_command_tick")
end)