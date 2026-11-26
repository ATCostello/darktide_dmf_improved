local mod = get_mod("Alfs_DMF_Extensions")

local Utils = mod._preset_utils or {}
mod._preset_utils = Utils

Utils.clone = function(value)
	if type(value) ~= "table" then
		return value
	end

	local result = {}

	for key, child in pairs(value) do
		result[key] = Utils.clone(child)
	end

	return result
end

Utils.trim = function(value)
	return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

Utils.unit_is_alive = function(unit)
	if unit == nil then
		return true
	end

	if type(Unit) ~= "table" or type(Unit.alive) ~= "function" then
		return false
	end

	return Unit.alive(unit) or false
end

Utils.notify = function(text, notification_type)
	local event_manager = Managers and Managers.event

	if not event_manager or type(event_manager.trigger) ~= "function" then
		return false
	end

	event_manager:trigger(
		"event_add_notification_message",
		notification_type or "default",
		tostring(text or ""),
		nil,
		nil
	)

	return true
end

Utils.get_dmf = function()
	return mod.dmf or get_mod("DMF")
end

Utils.resolve_mod_name = function(value)
	if not value then
		return nil
	end

	if get_mod(value) then
		return value
	end

	if mod._category_mod_map and mod._category_mod_map[value] then
		return mod._category_mod_map[value]
	end

	local dmf = Utils.get_dmf()

	if dmf then
		local widgets_data = dmf.options_widgets_data or {}

		for index = 1, #widgets_data do
			local mod_widgets = widgets_data[index]
			local header = mod_widgets and mod_widgets[1]

			if header and (header.mod_name == value or header.readable_mod_name == value) then
				return header.mod_name or value
			end
		end
	end

	return value
end

Utils.get_target_mod_name = function(category)
	return Utils.resolve_mod_name(category)
end

Utils.get_display_mod_name = function(target_mod_name)
	local mod_name = Utils.resolve_mod_name(target_mod_name)
	local dmf = Utils.get_dmf()

	if dmf then
		local widgets_data = dmf.options_widgets_data or {}

		for index = 1, #widgets_data do
			local mod_widgets = widgets_data[index]
			local header = mod_widgets and mod_widgets[1]

			if header and header.mod_name == mod_name then
				return header.readable_mod_name or header.mod_name or mod_name
			end
		end
	end

	if mod_name then
		local target_mod = get_mod(mod_name)

		if target_mod and type(target_mod.get_readable_name) == "function" then
			return target_mod:get_readable_name() or mod_name
		end
	end

	return mod_name or ""
end

Utils.encode_json = function(data)
	if ScriptCJson and type(ScriptCJson.encode_lua_to_json_for_lua) == "function" then
		return ScriptCJson.encode_lua_to_json_for_lua(data)
	end

	return cjson.encode(data)
end

Utils.decode_json = function(text)
	if not cjson then
		return false, nil
	end

	local dmf = Utils.get_dmf()

	if dmf and type(dmf.safe_call) == "function" then
		return dmf.safe_call(mod, { mod:localize("preset_editor_invalid_json") }, cjson.decode, text)
	end

	return true, cjson.decode(text)
end
