---@type event_handler
local handlers = {events={}}

---@class PlayerGlobal.elems.recipe
---@field has_changed boolean whether or not the elems have changed since last confirmed
---@field recipe {[int]:string} the table of recipe values
---@field count {["recipe"]:integer} how many items have a value
---@field last {["recipe"]:integer} the index of the last item with a value

---@class PlayerGlobal.elems.items
---@field has_changed boolean whether or not the elems have changed since last confirmed
---@field ["item"|"fluid"] {[int]:string} the table of values
---@field count {["item"|"fluid"]:integer} how many items have a value
---@field last {["item"|"fluid"]:integer} the index of the last item with a value

---@class PlayerGlobal.tab
---@field elems PlayerGlobal.elems.items the values of this element
---@field result {[integer]:tierResult[]}? the results of this tab's last calculation
---@field calculated simpleItem[]? the list of items last calculated, given has_changed is false

---@class PlayerGlobal
---@field menu LuaGuiElement the menu element everything is attatched to
---@field highlight simpleItem? the item to be highlighted/currently highlighted
---@field highlighted LuaGuiElement[]? the elements that have been highlighted
---@field calculate LuaGuiElement the confirm button for calculation
---@field calculated_tab integer the tab that was last calculated
---@field selected_tab integer the tab that is currently selected
---@field calculated simpleItem[] the list of items last calculated
---@field error LuaGuiElement the element displayed in case of an error
---@field table LuaGuiElement the displayed table of calculated tiers
---@field [1] PlayerGlobal.tab
---@field [2] PlayerGlobal.tab
---@field [3] PlayerGlobal.tab
---@field base_elems PlayerGlobal.elems.items the choose-elem values of the base elements
---@field ignored_elems PlayerGlobal.elems.recipe the chooose-elem values of the ignored elements


---Initializes the player's global variables
---@param player_index integer
local function setupPlayerGlobal(player_index)
	---@type PlayerGlobal
	local player = global.player[player_index] or {}
	global.player[player_index] = player
	player.calculated = player.calculated or {}
	player.calculated_tab = player.calculated_tab or 0
	for tab = 1, 3, 1 do
		player[tab] = player[tab] or {}
		player[tab].elems = player[tab].elems or {}
		if player[tab].elems.has_changed == nil then
			player[tab].elems.has_changed = true
		end
		player[tab].elems["item"] = player[tab].elems["item"] or {}
		player[tab].elems["fluid"] = player[tab].elems["fluid"] or {}
		player[tab].elems.last = player[tab].elems.last or {}
		player[tab].elems.count = player[tab].elems.count or {}
		player[tab].elems.last["item"] = player[tab].elems.last["item"] or 0
		player[tab].elems.count["item"] = player[tab].elems.count["item"] or 0
		player[tab].elems.last["fluid"] = player[tab].elems.last["fluid"] or 0
		player[tab].elems.count["fluid"] = player[tab].elems.count["fluid"] or 0
	end
	player.base_elems = player.base_elems or {}
	player.base_elems["item"] = player.base_elems["item"] or {}
	player.base_elems["fluid"] = player.base_elems["fluid"] or {}
	player.base_elems.count = player.base_elems.count or {}
	player.base_elems.last = player.base_elems.last or {}
	player.base_elems.count["item"] = player.base_elems.count["item"] or 0
	player.base_elems.count["fluid"] = player.base_elems.count["fluid"] or 0
	player.base_elems.last["item"] = player.base_elems.last["item"] or 0
	player.base_elems.last["fluid"] = player.base_elems.last["fluid"] or 0

	player.ignored_elems = player.ignored_elems or {}
	player.ignored_elems.count = player.ignored_elems.count or {}
	player.ignored_elems.last = player.ignored_elems.last or {}
	player.ignored_elems.recipe = player.ignored_elems.recipe or {}
	player.ignored_elems.count.recipe = player.ignored_elems.count.recipe or 0
	player.ignored_elems.last.recipe = player.ignored_elems.last.recipe or 0
end
handlers.events[defines.events.on_player_joined_game] = function (EventData)
	setupPlayerGlobal(EventData.player_index)
end
handlers.events[defines.events.on_player_removed] = function (EventData)
	global.player[EventData.player_index] = nil
end

---Initializes the global variables
local function setup()
	---@type string[]
	global.tick_later = global.tick_later or {}
	---@type PlayerGlobal[]
	global.player = global.player or {}
	for player_index in pairs(game.players) do
		---@cast player_index integer
		setupPlayerGlobal(player_index)
	end
end
function handlers.on_configuration_changed(EventData)
	if EventData.mod_changes[script.mod_name] then
		setup()
	end
end
function handlers.on_init()
	setup()
end

return handlers