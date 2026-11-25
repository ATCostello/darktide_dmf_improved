local mod = get_mod("Alfs_DMF_Extensions")

local Utils = mod._preset_utils
local Constants = mod._preset_constants

local Core = mod._preset_core or {}
mod._preset_core = Core

Core.silent = false

local setting_ids_cache = {}
local preset_store_cache = nil
local global_preset_store_cache = nil
local presets_enabled_cache = nil

local EXCLUDED_MODS = {
	DMF = true,
}

local EXCLUDED_SETTINGS = {
	has_been_imported = true,
	settings_profile_importer_state = true,
	dmf_initialized = true,
	show_developer_console = true,
	disabled_mods_list = true,
	chat_history = true,
	[Constants.PRESET_SETTING] = true,
	[Constants.GLOBAL_PRESET_SETTING] = true,
	[Constants.PRESETS_SETTING] = true,
}

local function is_excluded_setting(mod_name, setting_id)
	if not setting_id or type(setting_id) ~= "string" then
		return true
	end

	if EXCLUDED_MODS[mod_name] or EXCLUDED_SETTINGS[setting_id] then
		return true
	end

	return string.sub(setting_id, 1, 13) == "options_menu_" or string.sub(setting_id, 1, 14) == "preset_editor_"
end

local function setting_needs_update(target_mod, setting_id, value)
	if type(value) == "table" then
		return true
	end

	return target_mod:get(setting_id) ~= value
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
	if preset_store_cache then
		return preset_store_cache
	end

	local presets = mod:get(Constants.PRESET_SETTING)

	if type(presets) ~= "table" then
		presets = {}
	end

	preset_store_cache = presets

	return presets
end

Core.save_preset_store = function(presets)
	preset_store_cache = presets
	mod:set(Constants.PRESET_SETTING, presets)

	local dmf = Utils.get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end
end

Core.get_global_preset_store = function()
	if global_preset_store_cache then
		return global_preset_store_cache
	end

	local presets = mod:get(Constants.GLOBAL_PRESET_SETTING)

	if type(presets) ~= "table" then
		presets = {}
	end

	global_preset_store_cache = presets

	return presets
end

Core.save_global_preset_store = function(presets)
	global_preset_store_cache = presets
	mod:set(Constants.GLOBAL_PRESET_SETTING, presets)

	local dmf = Utils.get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end
end

Core.get_config_setting_ids = function(target_mod_name)
	local resolved = Utils.resolve_mod_name(target_mod_name) or target_mod_name

	if not resolved or EXCLUDED_MODS[resolved] then
		return {}, 0
	end

	local application = rawget(_G, "Application")
	local all_settings = application and type(application.user_setting) == "function"
		and application.user_setting("mods_settings")
		or nil

	if type(all_settings) ~= "table" then
		return {}, 0
	end

	local namespace = all_settings[resolved]

	if type(namespace) ~= "table" then
		namespace = all_settings[target_mod_name]

		if type(namespace) ~= "table" then
			return {}, 0
		end
	end

	local ids = {}
	local count = 0

	for setting_id, value in pairs(namespace) do
		if not is_excluded_setting(resolved, setting_id) and value ~= nil then
			count = count + 1
			ids[count] = setting_id
		end
	end

	return ids, count
end

Core.get_setting_ids = function(target_mod_name)
	if not target_mod_name then
		return {}, 0
	end

	local widget_ids, widget_count = {}, 0
	local dmf = Utils.get_dmf()
	local widgets_data = dmf and dmf.options_widgets_data

	if widgets_data then
		local cached = setting_ids_cache[target_mod_name]

		if cached then
			if widgets_data[cached.index] == cached.widgets then
				widget_ids, widget_count = cached.ids, cached.count
			else
				setting_ids_cache[target_mod_name] = nil
			end
		end

		if not setting_ids_cache[target_mod_name] then
			for index = 1, #widgets_data do
				local mod_widgets = widgets_data[index]
				local header = mod_widgets and mod_widgets[1]

				if header and header.mod_name == target_mod_name then
					local ids = {}
					local seen = {}
					local count = 0

					for i = 2, #mod_widgets do
						local widget = mod_widgets[i]
						local setting_id = widget and widget.setting_id

						if
							setting_id
							and widget.type ~= "group"
							and widget.type ~= "button"
							and not seen[setting_id]
						then
							seen[setting_id] = true
							count = count + 1
							ids[count] = setting_id
						end
					end

					setting_ids_cache[target_mod_name] = {
						ids = ids,
						count = count,
						index = index,
						widgets = mod_widgets,
					}
					widget_ids, widget_count = ids, count
					break
				end
			end
		end
	end

	local config_ids, config_count = Core.get_config_setting_ids(target_mod_name)

	if config_count == 0 then
		return widget_ids, widget_count
	end

	local ids = {}
	local seen = {}
	local count = 0

	for i = 1, widget_count do
		local setting_id = widget_ids[i]

		if not seen[setting_id] then
			seen[setting_id] = true
			count = count + 1
			ids[count] = setting_id
		end
	end

	for i = 1, config_count do
		local setting_id = config_ids[i]

		if not seen[setting_id] then
			seen[setting_id] = true
			count = count + 1
			ids[count] = setting_id
		end
	end

	return ids, count
end

Core.capture_settings = function(target_mod_name)
	local mod_name = Utils.resolve_mod_name(target_mod_name)
	local target_mod = mod_name and get_mod(mod_name) or nil

	if not target_mod then
		return nil
	end

	local settings = {}
	local ids, count = Core.get_setting_ids(mod_name)

	for i = 1, count do
		local setting_id = ids[i]

		if not is_excluded_setting(mod_name, setting_id) then
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
	local seen = {}
	local widgets_data = dmf.options_widgets_data or {}

	for index = 1, #widgets_data do
		local mod_widgets = widgets_data[index]
		local header = mod_widgets and mod_widgets[1]
		local mod_name = header and header.mod_name

		if mod_name and #mod_widgets > 1 and get_mod(mod_name) then
			local settings = Core.capture_settings(mod_name)
			local resolved = Utils.resolve_mod_name(mod_name) or mod_name

			if settings and next(settings) then
				mods[resolved] = settings
				seen[resolved] = true
			end
		end
	end

	local application = rawget(_G, "Application")
	local all_settings = application and type(application.user_setting) == "function"
		and application.user_setting("mods_settings")
		or nil

	if type(all_settings) == "table" then
		for mod_name, namespace in pairs(all_settings) do
			local resolved = Utils.resolve_mod_name(mod_name) or mod_name

			if type(namespace) == "table" and not seen[resolved] and get_mod(resolved) then
				local settings = Core.capture_settings(mod_name)

				if settings and next(settings) then
					mods[resolved] = settings
					seen[resolved] = true
				end
			end
		end
	end

	if not next(mods) then
		return nil
	end

	return mods
end

Core.make_backup_name = function()
	local base = mod:localize("preset_editor_backup_prefix") .. tostring(os.date("%Y-%m-%d %H-%M-%S"))
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

	table.clear(setting_ids_cache)
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

Core.apply_settings = function(view, target_mod_name, settings, target_label, defer_flush)
	local mod_name = Utils.resolve_mod_name(target_mod_name)
	local target_mod = mod_name and get_mod(mod_name) or nil

	if not target_mod or type(settings) ~= "table" then
		message(view, mod:localize("preset_editor_error_title"), mod:localize("preset_editor_target_mod_missing"))
		return
	end

	for setting_id, value in pairs(settings) do
		if
			not is_excluded_setting(mod_name, setting_id)
			and value ~= nil
			and setting_needs_update(target_mod, setting_id, value)
		then
			target_mod:set(setting_id, value, true)
		end
	end

	if not defer_flush then
		Core.flush_settings()
		Core.refresh_options_view(view, mod_name)
	end

	if target_label then
		message(
			view,
			mod:localize("preset_editor_applied_title"),
			mod:localize("preset_editor_applied", tostring(target_label))
		)
	end
end

Core.apply_global_settings = function(view, mods, target_label, defer_flush)
	if type(mods) ~= "table" then
		message(view, mod:localize("preset_editor_error_title"), mod:localize("preset_editor_global_unreadable"))
		return
	end

	for mod_name, settings in pairs(mods) do
		local resolved_name = Utils.resolve_mod_name(mod_name)
		local target_mod = resolved_name and get_mod(resolved_name) or nil

		if target_mod and type(settings) == "table" then
			for setting_id, value in pairs(settings) do
				if
					not is_excluded_setting(resolved_name, setting_id)
					and value ~= nil
					and setting_needs_update(target_mod, setting_id, value)
				then
					target_mod:set(setting_id, value, true)
				end
			end
		end
	end

	if not defer_flush then
		Core.flush_settings()
		Core.refresh_options_view(view)
	end

	if target_label then
		message(
			view,
			mod:localize("preset_editor_applied_title"),
			mod:localize("preset_editor_applied_global", tostring(target_label))
		)
	end
end

Core.apply_scope_settings = function(scope, settings, target_label, view, show_message, defer_flush)
	if Core.is_global_scope(scope) then
		Core.apply_global_settings(view, settings, show_message and target_label or nil, defer_flush)
	else
		Core.apply_settings(view, scope.mod_name, settings, show_message and target_label or nil, defer_flush)
	end
end

Core.flush_settings = function()
	local dmf = Utils.get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end
end

Core.invalidate_setting = function(setting_id)
	if setting_id == Constants.PRESETS_SETTING then
		presets_enabled_cache = nil
	end

	table.clear(setting_ids_cache)
end

Core.presets_enabled = function()
	if presets_enabled_cache == nil then
		presets_enabled_cache = mod:get(Constants.PRESETS_SETTING) ~= false
	end

	return presets_enabled_cache
end
