local mod = get_mod("Alfs_DMF_Extensions")

local Utils = mod._preset_utils
local Constants = mod._preset_constants

local Core = mod._preset_core or {}
mod._preset_core = Core

Core.silent = false

local IMPORT_STATE_MOD = "Alfs_Darktide_Improved_profile_settings"
local IMPORT_STATE_SETTING = "has_been_imported"

local function is_import_state_setting(mod_name, setting_id)
	return setting_id == IMPORT_STATE_SETTING and Utils.resolve_mod_name(mod_name) == IMPORT_STATE_MOD
end

Core.set_silent = function(value)
	Core.silent = value == true
end

local function message(view, title, text)
	if Core.silent then
		return
	end

	local popups = mod._preset_popups

	if popups and type(popups.show_message) == "function" then
		popups.show_message(view, title, text)
	end
end

Core.get_preset_store = function()
	local presets = mod:get(Constants.PRESET_SETTING)

	if type(presets) ~= "table" then
		presets = {}
	end

	return presets
end

Core.save_preset_store = function(presets)
	mod:set(Constants.PRESET_SETTING, presets)

	local dmf = Utils.get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end
end

Core.get_global_preset_store = function()
	local presets = mod:get(Constants.GLOBAL_PRESET_SETTING)

	if type(presets) ~= "table" then
		presets = {}
	end

	return presets
end

Core.save_global_preset_store = function(presets)
	mod:set(Constants.GLOBAL_PRESET_SETTING, presets)

	local dmf = Utils.get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end
end

Core.get_setting_ids = function(target_mod_name)
	local dmf = Utils.get_dmf()

	if not dmf then
		return {}
	end

	for _, mod_widgets in ipairs(dmf.options_widgets_data or {}) do
		local header = mod_widgets[1]

		if header and header.mod_name == target_mod_name then
			local ids = {}
			local seen = {}

			for i = 2, #mod_widgets do
				local widget = mod_widgets[i]

				if
					widget
					and widget.setting_id
					and widget.type ~= "group"
					and widget.type ~= "button"
					and not seen[widget.setting_id]
				then
					seen[widget.setting_id] = true
					ids[#ids + 1] = widget.setting_id
				end
			end

			return ids
		end
	end

	return {}
end

Core.capture_settings = function(target_mod_name)
	local mod_name = Utils.resolve_mod_name(target_mod_name)
	local target_mod = mod_name and get_mod(mod_name) or nil

	if not target_mod then
		return nil
	end

	local settings = {}

	for _, setting_id in ipairs(Core.get_setting_ids(mod_name)) do
		if not is_import_state_setting(mod_name, setting_id) then
			local value = target_mod:get(setting_id)

			if value ~= nil then
				settings[setting_id] = value
			end
		end
	end

	return settings
end

Core.capture_all_settings = function()
	local dmf = Utils.get_dmf()

	if not dmf then
		return nil
	end

	local mods = {}

	for _, mod_widgets in ipairs(dmf.options_widgets_data or {}) do
		local header = mod_widgets[1]
		local mod_name = header and header.mod_name

		if mod_name and #mod_widgets > 1 and get_mod(mod_name) then
			local settings = Core.capture_settings(mod_name)

			if settings and next(settings) then
				mods[mod_name] = settings
			end
		end
	end

	if not next(mods) then
		return nil
	end

	return mods
end

Core.make_backup_name = function()
	local base = "BACKUP " .. tostring(os.date("%Y-%m-%d %H-%M-%S"))
	local presets = Core.get_global_preset_store()
	local name = base
	local index = 2

	while presets[name] do
		name = string.format("%s (%d)", base, index)
		index = index + 1
	end

	return name
end

Core.backup_global_settings = function()
	local mods = Core.capture_all_settings()

	if not mods then
		return false
	end

	local presets = Core.get_global_preset_store()

	presets[Core.make_backup_name()] = {
		mods = mods,
		backup = true,
	}
	Core.save_global_preset_store(presets)

	return true
end

Core.make_mod_scope = function(mod_name, category)
	return {
		kind = "mod",
		mod_name = mod_name,
		category = category or mod_name,
	}
end

Core.make_global_scope = function()
	return {
		kind = "global",
	}
end

Core.is_global_scope = function(scope)
	return not scope or scope.kind == "global" or scope.mod_name == nil
end

Core.preset_store_key = function(scope)
	if Core.is_global_scope(scope) then
		return nil
	end

	local store = Core.get_preset_store()
	local raw_name = scope.mod_name
	local mod_name = Utils.resolve_mod_name(raw_name) or raw_name

	if not mod_name then
		return nil
	end

	if type(store[mod_name]) == "table" then
		return mod_name
	end

	if raw_name and type(store[raw_name]) == "table" then
		return raw_name
	end

	local display_name = Utils.get_display_mod_name(mod_name)

	if display_name and display_name ~= "" and type(store[display_name]) == "table" then
		return display_name
	end

	for key, presets in pairs(store) do
		if type(presets) == "table" and Utils.resolve_mod_name(key) == mod_name then
			return key
		end
	end

	return mod_name
end

Core.get_mod_preset_bucket = function(target_mod_name, create)
	local store = Core.get_preset_store()
	local key = Core.preset_store_key(Core.make_mod_scope(target_mod_name))
	local presets = key and store[key] or nil

	if type(presets) ~= "table" and create and key then
		presets = {}
		store[key] = presets
	end

	return store, type(presets) == "table" and presets or nil, key
end

Core.scope_key = function(scope)
	if Core.is_global_scope(scope) then
		return "global"
	end

	return "mod:" .. (Utils.resolve_mod_name(scope.mod_name) or scope.mod_name)
end

Core.scope_display_name = function(scope)
	if Core.is_global_scope(scope) then
		return mod:localize("preset_editor_all_mods")
	end

	return Utils.get_display_mod_name(scope.mod_name)
end

Core.get_scope_presets = function(scope)
	if Core.is_global_scope(scope) then
		return Core.get_global_preset_store()
	end

	local store = Core.get_preset_store()
	local key = Core.preset_store_key(scope)
	local presets = key and store[key] or nil

	return type(presets) == "table" and presets or {}
end

Core.save_scope_presets = function(scope, presets)
	if type(presets) ~= "table" then
		return
	end

	if Core.is_global_scope(scope) then
		Core.save_global_preset_store(presets)
		return
	end

	local store = Core.get_preset_store()
	local key = Core.preset_store_key(scope) or Utils.resolve_mod_name(scope.mod_name) or scope.mod_name

	store[key] = presets
	Core.save_preset_store(store)
end

Core.get_scope_preset = function(scope, name)
	local presets = Core.get_scope_presets(scope)
	local preset = name and presets[name]

	return type(preset) == "table" and preset or nil
end

Core.normalize_global_mods = function(mods)
	if type(mods) ~= "table" then
		return nil
	end

	local normalized = {}

	for mod_name, settings in pairs(mods) do
		local resolved_name = Utils.resolve_mod_name(mod_name)

		if type(resolved_name) == "string" and type(settings) == "table" and get_mod(resolved_name) then
			normalized[resolved_name] = settings
		end
	end

	if not next(normalized) then
		return nil
	end

	return normalized
end

Core.get_preset_settings = function(scope, preset)
	if type(preset) ~= "table" then
		return nil
	end

	if Core.is_global_scope(scope) then
		return Core.normalize_global_mods(preset.mods)
	end

	return type(preset.settings) == "table" and preset.settings or nil
end

Core.get_preset_names = function(scope)
	local names = {}
	local presets = Core.get_scope_presets(scope)

	for name, preset in pairs(presets) do
		if Core.get_preset_settings(scope, preset) then
			names[#names + 1] = name
		end
	end

	table.sort(names)

	return names
end

Core.scope_capture_settings = function(scope)
	if Core.is_global_scope(scope) then
		return Core.capture_all_settings()
	end

	return Core.capture_settings(scope.mod_name)
end

Core.build_payload = function(name, settings, target_mod_name)
	return {
		format = Constants.PRESET_FORMAT,
		mod_name = target_mod_name,
		name = name,
		settings = settings,
	}
end

Core.build_global_payload = function(name, mods)
	return {
		format = Constants.GLOBAL_PRESET_FORMAT,
		name = name,
		mods = mods,
	}
end

Core.preserve_assignment_fields = function(existing, preset)
	if type(existing) ~= "table" or type(preset) ~= "table" then
		return preset
	end

	if type(existing.characters) == "table" then
		preset.characters = Utils.clone(existing.characters)
	end

	if type(existing.character_names) == "table" then
		preset.character_names = Utils.clone(existing.character_names)
	end

	return preset
end

Core.refresh_options_view = function(view, target_mod_name)
	if not view then
		return
	end

	mod._tab_inject_state = {}
	mod._gen_tabs_toggle_widgets = {}
	mod._preset_editor_widgets = {}

	local dmf = Utils.get_dmf()

	if
		dmf
		and target_mod_name
		and view._options_templates
		and type(dmf.update_mod_options_visibility) == "function"
	then
		dmf:update_mod_options_visibility(view._options_templates, target_mod_name)
	end

	if type(view._refresh_dynamic_options) == "function" then
		view:_refresh_dynamic_options()
	elseif type(view._reset_options_view) == "function" then
		view:_reset_options_view(false)
	elseif type(mod.filter_settings) == "function" and view._selected_category then
		mod.filter_settings(view, view._selected_category, true)
	end
end

Core.apply_settings = function(view, target_mod_name, settings, target_label)
	local mod_name = Utils.resolve_mod_name(target_mod_name)
	local target_mod = mod_name and get_mod(mod_name) or nil

	if not target_mod or type(settings) ~= "table" then
		message(view, "Preset Error", "The target mod could not be found.")
		return
	end

	for _, setting_id in ipairs(Core.get_setting_ids(mod_name)) do
		if not is_import_state_setting(mod_name, setting_id) then
			local value = settings[setting_id]

			if value ~= nil then
				target_mod:set(setting_id, value, true)
			end
		end
	end

	Core.flush_settings()
	Core.refresh_options_view(view, mod_name)

	if target_label then
		message(view, "Preset Applied", string.format("Applied '%s'.", tostring(target_label)))
	end
end

Core.apply_global_settings = function(view, mods, target_label)
	if type(mods) ~= "table" then
		message(view, "Preset Error", "The global preset could not be read.")
		return
	end

	for mod_name, settings in pairs(mods) do
		local resolved_name = Utils.resolve_mod_name(mod_name)
		local target_mod = resolved_name and get_mod(resolved_name) or nil

		if target_mod and type(settings) == "table" then
			for _, setting_id in ipairs(Core.get_setting_ids(resolved_name)) do
				if not is_import_state_setting(resolved_name, setting_id) then
					local value = settings[setting_id]

					if value ~= nil then
						target_mod:set(setting_id, value, true)
					end
				end
			end
		end
	end

	Core.flush_settings()
	Core.refresh_options_view(view)

	if target_label then
		message(view, "Preset Applied", string.format("Applied global preset '%s'.", tostring(target_label)))
	end
end

Core.apply_scope_settings = function(scope, settings, target_label, view, show_message)
	if Core.is_global_scope(scope) then
		Core.apply_global_settings(view, settings, show_message and target_label or nil)
	else
		Core.apply_settings(view, scope.mod_name, settings, show_message and target_label or nil)
	end
end

Core.flush_settings = function()
	local dmf = Utils.get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end
end

Core.presets_enabled = function()
	return mod:get(Constants.PRESETS_SETTING) ~= false
end
