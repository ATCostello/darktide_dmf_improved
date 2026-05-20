local mod = get_mod("Alfs_DMF_Extensions")

local dmf = get_mod("DMF")

local InputUtils = require("scripts/managers/input/input_utils")

local DISPLAY_TO_GLOBAL = {
	["Left"] = "mouse_button_0",
	["Right"] = "mouse_button_1",
	["Middle"] = "mouse_button_2",
	["mouse_left"] = "mouse_button_0",
	["mouse_right"] = "mouse_button_1",
	["mouse_middle"] = "mouse_button_2",
}

local LOCAL_TO_GLOBAL = {
	["button_0"] = "mouse_button_0",
	["button_1"] = "mouse_button_1",
	["button_2"] = "mouse_button_2",
}

local orig_keywatch_to_local = dmf.keywatch_result_to_local_keys
dmf.keywatch_result_to_local_keys = function(keywatch_result)
	if keywatch_result and keywatch_result.main then
		local mapped = DISPLAY_TO_GLOBAL[keywatch_result.main]
		if mapped then
			keywatch_result = table.clone(keywatch_result)
			keywatch_result.main = mapped
		end
	end

	return orig_keywatch_to_local(keywatch_result)
end

local orig_local_to_keywatch = dmf.local_keys_to_keywatch_result
dmf.local_keys_to_keywatch_result = function(keys)
	local result = orig_local_to_keywatch(keys)

	if result == nil and keys and keys[1] then
		local global_name = LOCAL_TO_GLOBAL[keys[1]]
		if global_name then
			local device = Managers.input:_find_active_device("mouse")
			if device then
				local index = device:button_index(global_name)
				if index then
					result = {
						main = global_name,
						enablers = {},
						disablers = {},
					}
				end
			end
		end
	end

	return result
end
