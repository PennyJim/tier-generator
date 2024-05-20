local calculator = require("__tier-generator__.calculation.calculator")

script.on_init(function ()
	global = calculator()
	log(serpent.dump(global))
end)

script.on_configuration_changed(function (ChangedData)
	if ChangedData.mod_startup_settings_changed  or
			ChangedData.mod_changes or
			ChangedData.migration_applied then
		global = calculator()
	end
end)