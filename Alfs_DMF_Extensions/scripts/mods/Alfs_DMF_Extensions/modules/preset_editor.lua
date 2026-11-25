local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local Archetypes = require("scripts/settings/archetype/archetypes")

local PRESET_SETTING = "preset_editor_presets"
local PRESETS_SETTING = "enable_presets"
local PRESET_FORMAT = "alfs_dmf_extensions_preset_v1"
local GLOBAL_PRESET_SETTING = "preset_editor_global_presets"
local GLOBAL_PRESET_FORMAT = "alfs_dmf_extensions_global_preset_v1"

local MOD_COG_ID = "preset_mod_cog"
local GLOBAL_COG_ID = "global_preset_cog"
local COG_SIZE = 32
local COG_GAP = 6
local COG_Y = 14
local PIN_SIZE = 44
local COG_MATERIAL = "content/ui/materials/symbols/cog_small"
local PRESET_PANEL_VIEW = "alfs_preset_editor_panel_view"
local PRESET_PANEL_PATH = "Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_panel_view"

local show_global_export
local show_global_import
local show_global_save
local refresh_preset_panel

local COG_NORMAL_COLOR = { 255, 226, 199, 126 }
local COG_HOVER_COLOR = Color.ui_brown_super_light and Color.ui_brown_super_light(255, true)
	or Color.terminal_text_header_selected(nil, true)

local COLORS = {
	normal = COG_NORMAL_COLOR,
	hover = COG_HOVER_COLOR,

	background = Color.terminal_background(nil, true),
	background_hover = Color.terminal_background_gradient(nil, true),
	background_selected = Color.terminal_background_gradient_selected(nil, true),

	frame = Color.terminal_corner(nil, true),
	frame_hover = Color.terminal_corner_hover(nil, true),
	frame_selected = Color.terminal_frame_selected(nil, true),
}

local header_button_text_style = table.clone(UIFontSettings.header_3)
header_button_text_style.text_horizontal_alignment = "center"
header_button_text_style.text_vertical_alignment = "center"
header_button_text_style.text_color = COLORS.normal
header_button_text_style.hover_text_color = COLORS.hover
header_button_text_style.offset = { 0, 0, 3 }

local function trim(value)
	return tostring(value or ""):match("^%s*(.-)%s*$") or ""
end

local function clone_table(value)
	if type(value) ~= "table" then
		return value
	end

	local result = {}

	for key, child in pairs(value) do
		result[key] = clone_table(child)
	end

	return result
end

local function get_dmf()
	return mod.dmf or get_mod("DMF")
end

local function resolve_mod_name(value)
	if not value then
		return nil
	end

	if get_mod(value) then
		return value
	end

	if mod._category_mod_map and mod._category_mod_map[value] then
		return mod._category_mod_map[value]
	end

	local dmf = get_dmf()

	if dmf then
		for _, mod_widgets in ipairs(dmf.options_widgets_data or {}) do
			local header = mod_widgets[1]

			if header and (header.mod_name == value or header.readable_mod_name == value) then
				return header.mod_name or value
			end
		end
	end

	return value
end

local function get_target_mod_name(category)
	return resolve_mod_name(category)
end

local function get_display_mod_name(target_mod_name)
	local mod_name = resolve_mod_name(target_mod_name)
	local dmf = get_dmf()

	if dmf then
		for _, mod_widgets in ipairs(dmf.options_widgets_data or {}) do
			local header = mod_widgets[1]

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

local function get_preset_store()
	local presets = mod:get(PRESET_SETTING)

	if type(presets) ~= "table" then
		presets = {}
	end

	return presets
end

local function save_preset_store(presets)
	mod:set(PRESET_SETTING, presets)

	local dmf = get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end
end

local function get_global_preset_store()
	local presets = mod:get(GLOBAL_PRESET_SETTING)

	if type(presets) ~= "table" then
		presets = {}
	end

	return presets
end

local function save_global_preset_store(presets)
	mod:set(GLOBAL_PRESET_SETTING, presets)

	local dmf = get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end
end

local function get_setting_ids(target_mod_name)
	local dmf = get_dmf()

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

local function capture_settings(target_mod_name)
	local mod_name = resolve_mod_name(target_mod_name)
	local target_mod = mod_name and get_mod(mod_name) or nil

	if not target_mod then
		return nil
	end

	local settings = {}

	for _, setting_id in ipairs(get_setting_ids(mod_name)) do
		local value = target_mod:get(setting_id)

		if value ~= nil then
			settings[setting_id] = value
		end
	end

	return settings
end

local function capture_all_settings()
	local dmf = get_dmf()

	if not dmf then
		return nil
	end

	local mods = {}

	for _, mod_widgets in ipairs(dmf.options_widgets_data or {}) do
		local header = mod_widgets[1]
		local mod_name = header and header.mod_name

		if mod_name and #mod_widgets > 1 and get_mod(mod_name) then
			local settings = capture_settings(mod_name)

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

local function make_backup_name()
	local base = "BACKUP " .. tostring(os.date("%Y-%m-%d %H-%M-%S"))
	local presets = get_global_preset_store()
	local name = base
	local index = 2

	while presets[name] do
		name = string.format("%s (%d)", base, index)
		index = index + 1
	end

	return name
end

local function backup_global_settings()
	local mods = capture_all_settings()

	if not mods then
		return false
	end

	local presets = get_global_preset_store()

	presets[make_backup_name()] = {
		mods = mods,
		backup = true,
	}
	save_global_preset_store(presets)

	return true
end

local function make_mod_scope(mod_name, category)
	return {
		kind = "mod",
		mod_name = mod_name,
		category = category or mod_name,
	}
end

local function make_global_scope()
	return {
		kind = "global",
	}
end

local function scope_key(scope)
	if scope and scope.kind == "global" then
		return "global"
	end

	return scope and scope.mod_name and ("mod:" .. scope.mod_name) or "unknown"
end

local function scope_display_name(scope)
	if not scope or scope.kind == "global" then
		return mod:localize("preset_editor_all_mods")
	end

	return get_display_mod_name(scope.mod_name)
end

local function get_scope_presets(scope)
	if not scope then
		return {}
	end

	if scope.kind == "global" then
		return get_global_preset_store()
	end

	local store = get_preset_store()
	local presets = store[scope.mod_name]

	return type(presets) == "table" and presets or {}
end

local function save_scope_presets(scope, presets)
	if not scope or type(presets) ~= "table" then
		return
	end

	if scope.kind == "global" then
		save_global_preset_store(presets)
		return
	end

	local store = get_preset_store()
	store[scope.mod_name] = presets
	save_preset_store(store)
end

local function get_scope_preset(scope, name)
	local presets = get_scope_presets(scope)
	local preset = name and presets[name]

	return type(preset) == "table" and preset or nil
end

local function normalize_global_mods(mods)
	if type(mods) ~= "table" then
		return nil
	end

	local normalized = {}

	for mod_name, settings in pairs(mods) do
		local resolved_name = resolve_mod_name(mod_name)

		if type(resolved_name) == "string" and type(settings) == "table" and get_mod(resolved_name) then
			normalized[resolved_name] = settings
		end
	end

	if not next(normalized) then
		return nil
	end

	return normalized
end

local function get_preset_settings(scope, preset)
	if type(preset) ~= "table" then
		return nil
	end

	if scope and scope.kind == "global" then
		return normalize_global_mods(preset.mods)
	end

	return type(preset.settings) == "table" and preset.settings or nil
end

local function get_preset_names(scope)
	local names = {}
	local presets = get_scope_presets(scope)

	for name, preset in pairs(presets) do
		if get_preset_settings(scope, preset) then
			names[#names + 1] = name
		end
	end

	table.sort(names)

	return names
end

local function scope_capture_settings(scope)
	if not scope or scope.kind == "global" then
		return capture_all_settings()
	end

	return capture_settings(scope.mod_name)
end

local function refresh_options_view(view, target_mod_name)
	if not view then
		return
	end

	mod._tab_inject_state = {}
	mod._gen_tabs_toggle_widgets = {}
	mod._preset_editor_widgets = {}

	local dmf = get_dmf()

	if dmf and target_mod_name and view._options_templates and type(dmf.update_mod_options_visibility) == "function" then
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

local function apply_settings(view, target_mod_name, settings, target_label)
	local mod_name = resolve_mod_name(target_mod_name)
	local target_mod = mod_name and get_mod(mod_name) or nil

	if not target_mod or type(settings) ~= "table" then
		mod._show_preset_message(view, "Preset Error", "The target mod could not be found.")
		return
	end

	for _, setting_id in ipairs(get_setting_ids(mod_name)) do
		local value = settings[setting_id]

		if value ~= nil then
			target_mod:set(setting_id, value, true)
		end
	end

	local dmf = get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end

	refresh_options_view(view, mod_name)

	if target_label then
		mod._show_preset_message(view, "Preset Applied", string.format("Applied '%s'.", tostring(target_label)))
	end
end

local function apply_global_settings(view, mods, target_label)
	if type(mods) ~= "table" then
		mod._show_preset_message(view, "Preset Error", "The global preset could not be read.")
		return
	end

	for mod_name, settings in pairs(mods) do
		local resolved_name = resolve_mod_name(mod_name)
		local target_mod = resolved_name and get_mod(resolved_name) or nil

		if target_mod and type(settings) == "table" then
			for _, setting_id in ipairs(get_setting_ids(resolved_name)) do
				local value = settings[setting_id]

				if value ~= nil then
					target_mod:set(setting_id, value, true)
				end
			end
		end
	end

	local dmf = get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end

	refresh_options_view(view)

	if target_label then
		mod._show_preset_message(view, "Preset Applied", string.format("Applied global preset '%s'.", tostring(target_label)))
	end
end

local function apply_scope_settings(scope, settings, target_label, view, show_message)
	if not scope or scope.kind == "global" then
		apply_global_settings(view, settings, show_message and target_label or nil)
	else
		apply_settings(view, scope.mod_name, settings, show_message and target_label or nil)
	end
end

local function flush_settings()
	local dmf = get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end
end

local function get_local_player()
	local player_manager = Managers and Managers.player

	if not player_manager or type(player_manager.local_player) ~= "function" then
		return nil
	end

	return player_manager:local_player(1)
end

local function get_local_player_profile()
	local local_player = get_local_player()

	if local_player and type(local_player.profile) == "function" then
		return local_player:profile()
	end

	return nil
end

local function get_current_character_id()
	local local_player = get_local_player()

	if local_player and type(local_player.character_id) == "function" then
		local character_id = local_player:character_id()

		if character_id then
			return character_id
		end
	end

	local player_manager = Managers and Managers.player

	if player_manager and type(player_manager.local_player_backend_profile) == "function" then
		local profile = player_manager:local_player_backend_profile()

		if type(profile) == "table" then
			return profile.character_id
		end
	end

	return nil
end

local auto_apply_state = {
	character_id = nil,
	scopes = {},
}

local function get_active_options_view()
	local ui = Managers and Managers.ui

	if not ui or type(ui.view_instance) ~= "function" then
		return nil
	end

	return ui:view_instance("dmf_options_view")
end

local function get_assigned_preset(scope, character_id)
	if not character_id then
		return nil, nil
	end

	local names = get_preset_names(scope)

	for _, name in ipairs(names) do
		local preset = get_scope_preset(scope, name)
		local characters = preset and preset.characters

		if type(characters) == "table" and characters[character_id] then
			return name, preset
		end
	end

	return nil, nil
end

local function get_auto_scopes()
	local scopes = { make_global_scope() }

	for mod_name, presets in pairs(get_preset_store()) do
		if get_mod(mod_name) and type(presets) == "table" then
			scopes[#scopes + 1] = make_mod_scope(mod_name)
		end
	end

	return scopes
end

local function sync_auto_presets(character_id)
	if not character_id or character_id == auto_apply_state.character_id then
		return
	end

	for _, scope in ipairs(get_auto_scopes()) do
		local key = scope_key(scope)
		local state = auto_apply_state.scopes[key] or {}
		local name, preset = get_assigned_preset(scope, character_id)
		local preset_settings = get_preset_settings(scope, preset)

		if name and preset_settings then
			if not state.snapshot then
				state.snapshot = scope_capture_settings(scope)
			end

			apply_scope_settings(scope, preset_settings, nil, nil, false)
			state.applied_name = name
		elseif state.snapshot then
			apply_scope_settings(scope, state.snapshot, nil, nil, false)
			state.snapshot = nil
			state.applied_name = nil
		else
			state.applied_name = nil
		end

		auto_apply_state.scopes[key] = state
	end

	auto_apply_state.character_id = character_id
	flush_settings()

	local view = get_active_options_view()

	if view then
		refresh_options_view(view)
	end
end

mod._sync_auto_presets = function(character_id)
	sync_auto_presets(character_id)
end

mod._sync_auto_presets_with_current_player = function()
	sync_auto_presets(get_current_character_id())
end

mod._install_character_hooks = function()
	local classes = rawget(_G, "CLASSES") or rawget(_G, "CLASS")

	if type(classes) ~= "table" or type(mod.hook_safe) ~= "function" then
		return
	end

	local human_player = classes.HumanPlayer

	if type(human_player) == "table" and type(human_player.set_profile) == "function" and mod._character_hook_target ~= human_player then
		mod:hook_safe(human_player, "set_profile", function(self, profile)
			if self.viewport_name ~= "player1" then
				return
			end

			local character_id = profile and type(profile) == "table" and profile.character_id or nil

			if not character_id and type(self.character_id) == "function" then
				character_id = self:character_id()
			end

			sync_auto_presets(character_id)
		end)

		mod._character_hook_target = human_player
	end

	local state_main_menu = classes.StateMainMenu

	if type(state_main_menu) == "table" and type(state_main_menu._set_profiles) == "function" and mod._profile_cache_hook_target ~= state_main_menu then
		mod:hook_safe(state_main_menu, "_set_profiles", function(_, profiles)
			if type(profiles) == "table" then
				mod._preset_character_profiles = profiles
			end
		end)

		mod._profile_cache_hook_target = state_main_menu
	end
end

local function show_popup(view, context)
	context.type = context.type or "default"
	Managers.event:trigger("event_show_ui_popup", context, function(id)
		if view then
			view._popup_id = id
		end
	end)
end

mod._show_preset_message = function(view, title, text)
	show_popup(view, {
		title_text_unlocalized = tostring(title or "Preset Editor"),
		description_text_unlocalized = tostring(text or ""),
		type = "default",
		options = {
			{
				text = "loc_popup_button_close",
				close_on_pressed = true,
				hotkey = "back",
				callback = function()
					if view then
						view._popup_id = nil
					end
				end,
			},
		},
	})
end

local function copy_json_to_clipboard(view, json)
	local clipboard = rawget(_G, "Clipboard") or rawget(_G, "clipboard")

	if not clipboard or type(clipboard.put) ~= "function" then
		mod._show_preset_message(
			view,
			mod:localize("preset_editor_copy_failed_title"),
			mod:localize("preset_editor_copy_failed_description")
		)
		return false
	end

	clipboard.put(json)
	mod._show_preset_message(
		view,
		mod:localize("preset_editor_copied_title"),
		mod:localize("preset_editor_copied_description")
	)

	return true
end

local function show_confirmation(view, title, description, on_confirm)
	show_popup(view, {
		title_text_unlocalized = tostring(title or "Confirm"),
		description_text_unlocalized = tostring(description or ""),
		type = "default",
		options = {
			{
				text = "loc_popup_button_confirm",
				close_on_pressed = true,
				callback = function()
					if view then
						view._popup_id = nil
					end
					on_confirm()
				end,
			},
			{
				text = "loc_popup_button_cancel_settings_reset_default",
				template_type = "terminal_button_small",
				close_on_pressed = true,
				hotkey = "back",
				callback = function()
					if view then
						view._popup_id = nil
					end
				end,
			},
		},
	})
end

local function encode_json(data)
	if ScriptCJson and type(ScriptCJson.encode_lua_to_json_for_lua) == "function" then
		return ScriptCJson.encode_lua_to_json_for_lua(data)
	end

	return cjson.encode(data)
end

local function decode_json(text)
	if not cjson then
		return false, nil
	end

	local dmf = get_dmf()

	if dmf and type(dmf.safe_call) == "function" then
		return dmf.safe_call(mod, { "[Preset Editor] Invalid preset JSON" }, cjson.decode, text)
	end

	return true, cjson.decode(text)
end

local function preserve_assignment_fields(existing, preset)
	if type(existing) ~= "table" or type(preset) ~= "table" then
		return preset
	end

	if type(existing.characters) == "table" then
		preset.characters = clone_table(existing.characters)
	end

	if type(existing.character_names) == "table" then
		preset.character_names = clone_table(existing.character_names)
	end

	return preset
end

local function build_payload(name, settings, target_mod_name)
	return {
		format = PRESET_FORMAT,
		mod_name = target_mod_name,
		name = name,
		settings = settings,
	}
end

local function copy_per_mod_current_json(view, settings, target_mod_name)
	return copy_json_to_clipboard(view, encode_json(build_payload("Current Settings", settings, target_mod_name)))
end

local function copy_global_current_json(view, mods)
	return copy_json_to_clipboard(view, encode_json({
		format = GLOBAL_PRESET_FORMAT,
		name = "Current Settings",
		mods = mods,
	}))
end

local function show_export(view, name, settings, target_mod_name)
	local payload = build_payload(name, settings, target_mod_name)
	local json = encode_json(payload)
	local options = {}

	if Clipboard and type(Clipboard.set) == "function" then
		options[#options + 1] = {
			text = "Copy to clipboard",
			no_localization = true,
			close_on_pressed = false,
			callback = function()
				Clipboard.set(json)
			end,
		}
	end

	options[#options + 1] = {
		template_type = "text",
		no_localization = true,
		text = json,
	}

	options[#options + 1] = {
		text = "loc_popup_button_close",
		template_type = "terminal_button_small",
		close_on_pressed = true,
		hotkey = "back",
		callback = function()
			if view then
				view._popup_id = nil
			end
		end,
	}

	show_popup(view, {
		title_text_unlocalized = "Export Preset JSON",
		description_text_unlocalized = string.format(
			"Share this string with another player for %s.",
			get_display_mod_name(target_mod_name)
		),
		type = "default",
		options = options,
	})
end

local function show_import(view, category, target_mod_name)
	target_mod_name = resolve_mod_name(target_mod_name)

	if not target_mod_name then
		mod._show_preset_message(view, "Import Failed", "The target mod could not be found.")
		return
	end

	local options = {
		{
			template_type = "terminal_input_field",
			max_length = 65536,
			keyboard_title = "Preset JSON",
		},
		{
			text = "Import",
			no_localization = true,
			close_on_pressed = true,
			callback = function(json_text)
				local ok, decoded = decode_json(json_text)

				if not ok or type(decoded) ~= "table" then
					mod._show_preset_message(view, "Import Failed", "The JSON string could not be read.")
					return
				end

				if decoded.format ~= PRESET_FORMAT then
					mod._show_preset_message(view, "Import Failed", "This is not an Alfs DMF Extensions preset string.")
					return
				end

				if resolve_mod_name(decoded.mod_name) ~= resolve_mod_name(target_mod_name) then
					mod._show_preset_message(
						view,
						"Import Failed",
						string.format(
							"That preset is for '%s', not '%s'.",
							get_display_mod_name(decoded.mod_name),
							get_display_mod_name(target_mod_name)
						)
					)
					return
				end

				if type(decoded.settings) ~= "table" then
					mod._show_preset_message(view, "Import Failed", "The preset does not contain any settings.")
					return
				end

				local name = trim(decoded.name)

				if name == "" then
					name = "Imported Preset"
				end

				local description = string.format(
					"Import '%s' into %s? All current settings for this mod will be overwritten.",
					name,
					get_display_mod_name(target_mod_name)
				)

				show_confirmation(view, "Import Preset", description, function()
					backup_global_settings()

					local presets = get_preset_store()
					local mod_presets = presets[target_mod_name]

					if type(mod_presets) ~= "table" then
						mod_presets = {}
						presets[target_mod_name] = mod_presets
					end

					mod_presets[name] = preserve_assignment_fields(mod_presets[name], {
						settings = decoded.settings,
						imported = true,
					})
					save_preset_store(presets)
					apply_settings(view, target_mod_name, decoded.settings, name)
				end)
			end,
		},
		{
			text = "loc_popup_button_cancel_settings_reset_default",
			template_type = "terminal_button_small",
			close_on_pressed = true,
			hotkey = "back",
			callback = function()
				if view then
					view._popup_id = nil
				end
			end,
		},
	}

	show_popup(view, {
		title_text_unlocalized = "Import Preset JSON",
		description_text_unlocalized = "Paste a preset JSON string, then press Import.",
		type = "default",
		options = options,
	})
end

local function show_save(view, category, target_mod_name)
	target_mod_name = resolve_mod_name(target_mod_name)

	if not target_mod_name then
		mod._show_preset_message(view, "Save Failed", "The target mod could not be found.")
		return
	end

	local options = {
		{
			template_type = "terminal_input_field",
			max_length = 60,
			keyboard_title = "Preset name",
		},
		{
			text = "Save",
			no_localization = true,
			close_on_pressed = true,
			callback = function(name_text)
				local name = trim(name_text)

				if name == "" then
					mod._show_preset_message(view, "Save Failed", "Enter a preset name.")
					return
				end

				local function do_save()
					local settings = capture_settings(target_mod_name)

					if not settings then
						mod._show_preset_message(view, "Save Failed", "The target mod could not be found.")
						return
					end

					local presets = get_preset_store()
					local mod_presets = presets[target_mod_name]

					if type(mod_presets) ~= "table" then
						mod_presets = {}
						presets[target_mod_name] = mod_presets
					end

					mod_presets[name] = preserve_assignment_fields(mod_presets[name], {
						settings = settings,
					})
					save_preset_store(presets)
					mod._show_preset_message(view, "Preset Saved", string.format("Saved '%s'.", name))
				end

				local presets = get_preset_store()
				local mod_presets = presets[target_mod_name]

				if type(mod_presets) == "table" and mod_presets[name] then
					show_confirmation(
						view,
						"Overwrite Preset",
						string.format("Overwrite the existing preset '%s'?", name),
						do_save
					)
				else
					do_save()
				end
			end,
		},
		{
			text = "loc_popup_button_cancel_settings_reset_default",
			template_type = "terminal_button_small",
			close_on_pressed = true,
			hotkey = "back",
			callback = function()
				if view then
					view._popup_id = nil
				end
			end,
		},
	}

	show_popup(view, {
		title_text_unlocalized = "Save Preset",
		description_text_unlocalized = "Enter a name for the new preset.",
		type = "default",
		options = options,
	})
end

local function show_preset_options(view, category, target_mod_name, name)
	local presets = get_preset_store()
	local mod_presets = presets[target_mod_name]
	local preset = type(mod_presets) == "table" and mod_presets[name] or nil

	if type(preset) ~= "table" or type(preset.settings) ~= "table" then
		mod._show_preset_message(view, "Preset Error", string.format("Preset '%s' could not be found.", tostring(name)))
		return
	end

	local options = {
		{
			text = string.format("Apply '%s'", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				show_confirmation(
					view,
					"Apply Preset",
					string.format(
						"Apply '%s' to %s? All current settings for this mod will be overwritten.",
						name,
						get_display_mod_name(target_mod_name)
					),
					function()
						apply_settings(view, target_mod_name, preset.settings, name)
					end
				)
			end,
		},
		{
			text = string.format("Export '%s' JSON", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				show_export(view, name, preset.settings, target_mod_name)
			end,
		},
		{
			text = string.format("Delete '%s'", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				show_confirmation(view, "Delete Preset", string.format("Delete preset '%s'?", name), function()
					local current_presets = get_preset_store()
					local current_mod_presets = current_presets[target_mod_name]

					if type(current_mod_presets) == "table" then
						current_mod_presets[name] = nil
						save_preset_store(current_presets)
					end

					refresh_preset_panel(view)
				end)
			end,
		},
		{
			text = "loc_view_back",
			template_type = "terminal_button_small",
			close_on_pressed = true,
			hotkey = "back",
			callback = function()
				mod.open_preset_editor(view, category)
			end,
		},
	}

	show_popup(view, {
		title_text_unlocalized = tostring(name),
		description_text_unlocalized = mod:localize("preset_editor_description", get_display_mod_name(target_mod_name)),
		type = "default",
		options = options,
	})
end

refresh_preset_panel = function(view)
	local ui = Managers and Managers.ui
	local instance = nil

	if ui and type(ui.view_instance) == "function" then
		instance = ui:view_instance(PRESET_PANEL_VIEW)
	end

	if instance and type(instance._rebuild) == "function" then
		instance:_rebuild()
	elseif view and type(view._rebuild) == "function" then
		view:_rebuild()
	end
end

local function presets_enabled()
	return mod:get(PRESETS_SETTING) ~= false
end

local function clear_stale_preset_panel_view(handler)
	local active_views_data = handler and handler._active_views_data
	local active_views_array = handler and handler._active_views_array
	local view_data = active_views_data and active_views_data[PRESET_PANEL_VIEW]

	if not view_data or view_data.instance then
		return
	end

	if active_views_array then
		for index = #active_views_array, 1, -1 do
			if active_views_array[index] == PRESET_PANEL_VIEW then
				table.remove(active_views_array, index)
			end
		end

		handler._num_active_views = #active_views_array
	end

	active_views_data[PRESET_PANEL_VIEW] = nil
end

local function install_stale_preset_panel_hook()
	if mod._preset_panel_stale_view_hook_installed or type(mod.hook) ~= "function" then
		return
	end

	local class_registry = rawget(_G, "CLASS")
	local handler_class = type(class_registry) == "table" and class_registry.UIViewHandler or nil

	if type(handler_class) ~= "table" then
		local classes = rawget(_G, "CLASSES")

		handler_class = type(classes) == "table" and classes.UIViewHandler or nil
	end

	if not handler_class or type(handler_class._update_transition_progress) ~= "function" then
		return
	end

	mod._preset_panel_stale_view_hook_installed = true

	mod:hook(handler_class, "_update_transition_progress", function(func, self, dt, transition_progress)
		clear_stale_preset_panel_view(self)

		return func(self, dt, transition_progress)
	end)
end

mod._close_preset_panel_if_open = function()
	local ui = Managers and Managers.ui

	if not ui then
		return
	end

	clear_stale_preset_panel_view(ui._view_handler)

	if type(ui.view_active) == "function" and ui:view_active(PRESET_PANEL_VIEW) and type(ui.close_view) == "function" then
		ui:close_view(PRESET_PANEL_VIEW)
	end
end

local function open_preset_panel(scope)
	if not presets_enabled() then
		return false
	end

	install_stale_preset_panel_hook()

	if not mod._preset_panel_registered then
		return false
	end

	local ui = Managers and Managers.ui

	if not ui or type(ui.open_view) ~= "function" then
		return false
	end

	clear_stale_preset_panel_view(ui._view_handler)

	if type(ui.view_active) == "function" and ui:view_active(PRESET_PANEL_VIEW) then
		return false
	end

	mod._preset_panel_context = scope
	ui:open_view(PRESET_PANEL_VIEW, nil, nil, nil, nil, {})

	return true
end

local function profile_display_name(profile)
	if type(profile) ~= "table" then
		return nil
	end

	return profile.name or profile.character_name or profile.character_id
end

local function get_archetype(profile)
	local archetype = type(profile) == "table" and profile.archetype or nil

	if type(archetype) == "string" then
		return type(Archetypes) == "table" and Archetypes[archetype] or nil
	end

	return type(archetype) == "table" and archetype or nil
end

local function archetype_display_name(archetype)
	if not archetype then
		return ""
	end

	local name = archetype.archetype_name or archetype.name

	if not name then
		return ""
	end

	if type(Localize) == "function" then
		return Localize(name) or tostring(name)
	end

	return tostring(name)
end

mod._preset_panel_get_scope = function()
	return mod._preset_panel_context or make_global_scope()
end

mod._preset_panel_get_scope_name = function()
	return scope_display_name(mod._preset_panel_get_scope())
end

mod._preset_panel_get_names = function(scope)
	return get_preset_names(scope)
end

mod._preset_panel_get_preset = function(scope, name)
	return get_scope_preset(scope, name)
end

mod._preset_panel_get_settings = function(scope)
	return scope_capture_settings(scope)
end

mod._preset_panel_refresh = function(view)
	refresh_preset_panel(view)
end

mod._preset_panel_apply = function(view, scope, name)
	local preset = get_scope_preset(scope, name)
	local preset_settings = get_preset_settings(scope, preset)

	if not preset_settings then
		mod._show_preset_message(view, "Preset Error", string.format("Preset '%s' could not be found.", tostring(name)))
		return
	end

	show_confirmation(
		view,
		"Apply Preset",
		string.format(
			"Apply '%s' to %s? All current settings will be overwritten.",
			name,
			scope_display_name(scope)
		),
		function()
			apply_scope_settings(scope, preset_settings, name, view, true)
			refresh_preset_panel(view)
		end
	)
end

mod._preset_panel_delete = function(view, scope, name)
	show_confirmation(view, "Delete Preset", string.format("Delete preset '%s'?", name), function()
		local presets = get_scope_presets(scope)

		presets[name] = nil
		save_scope_presets(scope, presets)
		refresh_preset_panel(view)
	end)
end

mod._preset_panel_show_save = function(view, scope)
	if scope and (scope.kind == "global" or scope_key(scope) == "global") then
		show_global_save(view)
		return
	end

	local mod_name = scope and resolve_mod_name(scope.mod_name) or nil

	if not mod_name then
		mod._show_preset_message(view, "Save Failed", "The target mod could not be found.")
		return
	end

	show_save(view, scope and scope.category, mod_name)
end

mod._preset_panel_show_import = function(view, scope)
	if scope and scope.kind == "global" then
		show_global_import(view)
		return
	end

	local mod_name = scope and resolve_mod_name(scope.mod_name) or nil

	if not mod_name then
		mod._show_preset_message(view, "Import Failed", "The target mod could not be found.")
		return
	end

	show_import(view, scope and scope.category, mod_name)
end

mod._preset_panel_show_export = function(view, scope, name)
	local preset = get_scope_preset(scope, name)
	local preset_settings = get_preset_settings(scope, preset)

	if not preset_settings then
		mod._show_preset_message(view, "Export Failed", string.format("Preset '%s' could not be found.", tostring(name)))
		return
	end

	if scope and scope.kind == "global" then
		show_global_export(view, name, preset_settings)
	else
		show_export(view, name, preset_settings, scope and scope.mod_name)
	end
end

mod._preset_panel_show_current_export = function(view, scope)
	local settings = scope_capture_settings(scope)

	if type(settings) ~= "table" or not next(settings) then
		mod._show_preset_message(view, "Export Failed", "No settings could be exported.")
		return
	end

	if scope and scope.kind == "global" then
		copy_global_current_json(view, settings)
		return
	end

	local mod_name = scope and resolve_mod_name(scope.mod_name) or nil

	if not mod_name then
		mod._show_preset_message(view, "Export Failed", "The target mod could not be found.")
		return
	end

	copy_per_mod_current_json(view, settings, mod_name)
end

mod._preset_panel_get_characters = function(callback)
	if type(callback) ~= "function" then
		return
	end

	local current_id = get_current_character_id()
	local profiles = mod._preset_character_profiles
	local called = false

	local function finish(result)
		if called then
			return
		end

		called = true
		callback(result or {})
	end

	local function build(profiles_list)
		local result = {}
		local seen = {}

		if type(profiles_list) == "table" then
			for _, profile in ipairs(profiles_list) do
				local id = type(profile) == "table" and profile.character_id or nil

				if id and not seen[id] then
					local archetype = get_archetype(profile)

					seen[id] = true
					result[#result + 1] = {
						id = id,
						name = profile_display_name(profile) or id,
						archetype_name = archetype_display_name(archetype),
						profile = profile,
					}
				end
			end
		end

		if current_id and not seen[current_id] then
			local profile = get_local_player_profile()
			local archetype = get_archetype(profile)

			result[#result + 1] = {
				id = current_id,
				name = profile_display_name(profile) or current_id,
				archetype_name = archetype_display_name(archetype),
				profile = profile,
			}
		end

		table.sort(result, function(a, b)
			return tostring(a.name) < tostring(b.name)
		end)

		return result
	end

	if type(profiles) == "table" then
		finish(build(profiles))
		return
	end

	local data_service = Managers and Managers.data_service
	local profiles_service = data_service and data_service.profiles

	if profiles_service and type(profiles_service.fetch_all_profiles) == "function" then
		local promise = profiles_service:fetch_all_profiles()

		if promise and type(promise.next) == "function" then
			promise:next(function(data)
				mod._preset_character_profiles = type(data) == "table" and data.profiles or {}
				finish(build(mod._preset_character_profiles))
			end)

			return
		end
	end

	finish(build({}))
end

mod._preset_panel_get_scope_options = function()
	local regular_options = {}
	local pinned_options = {}
	local dmf = get_dmf()
	local seen = {}
	local favorites = dmf and type(dmf.get) == "function" and dmf:get("options_menu_favorite_mods") or nil
	local favorite_lookup = {}

	if type(favorites) == "table" then
		for _, favorite in pairs(favorites) do
			favorite_lookup[resolve_mod_name(favorite) or favorite] = true
		end
	end

	if dmf then
		for _, mod_widgets in ipairs(dmf.options_widgets_data or {}) do
			local header = mod_widgets[1]
			local mod_name = header and resolve_mod_name(header.mod_name)
			local display_name = get_display_mod_name(mod_name)

			if
				mod_name
				and not seen[mod_name]
				and get_mod(mod_name)
				and type(mod_widgets) == "table"
				and #mod_widgets > 1
			then
				seen[mod_name] = true

				local entry = {
					display_name = display_name,
					scope = make_mod_scope(mod_name),
				}

				if favorite_lookup[mod_name] then
					entry.display_name = "{#color(226,199,126)}\u{e02a}{#reset()} " .. tostring(display_name)
					pinned_options[#pinned_options + 1] = entry
				else
					regular_options[#regular_options + 1] = entry
				end
			end
		end
	end

	local options = {
		{
			display_name = mod:localize("preset_editor_all_mods"),
			scope = make_global_scope(),
		},
	}

	for _, entry in ipairs(pinned_options) do
		options[#options + 1] = entry
	end

	for _, entry in ipairs(regular_options) do
		options[#options + 1] = entry
	end

	return options
end

mod._preset_panel_set_scope = function(view, scope)
	if type(scope) ~= "table" then
		return
	end

	mod._preset_panel_context = scope

	if view then
		view._scope = scope
	end

	if view and type(view._set_scope) == "function" then
		view:_set_scope(scope)
	elseif view then
		refresh_preset_panel(view)
	end
end

mod._preset_panel_show_scope_dropdown = function(view)
	local scope_options = mod._preset_panel_get_scope_options()
	local options = {}

	for _, entry in ipairs(scope_options) do
		options[#options + 1] = {
			text = entry.display_name,
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				mod._preset_panel_set_scope(view, entry.scope)
			end,
		}
	end

	options[#options + 1] = {
		text = "loc_popup_button_close",
		template_type = "terminal_button_small",
		close_on_pressed = true,
		hotkey = "back",
		callback = function()
			if view then
				view._popup_id = nil
			end
		end,
	}

	show_popup(view, {
		title_text_unlocalized = mod:localize("preset_editor_select_scope_title"),
		description_text_unlocalized = mod:localize("preset_editor_select_scope_description"),
		type = "default",
		options = options,
	})
end

mod._preset_panel_is_character_assigned = function(scope, name, character_id)
	local preset = get_scope_preset(scope, name)
	local characters = preset and preset.characters

	return type(characters) == "table" and characters[character_id] == true
end

mod._preset_panel_toggle_character = function(scope, name, character_id, character_name)
	if not character_id then
		return
	end

	local presets = get_scope_presets(scope)
	local preset = presets[name]

	if type(preset) ~= "table" then
		return
	end

	preset.characters = type(preset.characters) == "table" and preset.characters or {}
	preset.character_names = type(preset.character_names) == "table" and preset.character_names or {}

	local assigned

	if preset.characters[character_id] then
		preset.characters[character_id] = nil
		preset.character_names[character_id] = nil
		assigned = false
	else
		preset.characters[character_id] = true
		preset.character_names[character_id] = character_name or character_id
		assigned = true
	end

	save_scope_presets(scope, presets)

	return assigned
end

if not mod._preset_panel_registered and type(mod.add_require_path) == "function" and type(mod.register_view) == "function" then
	mod:add_require_path(PRESET_PANEL_PATH)
	mod:register_view({
		view_name = PRESET_PANEL_VIEW,
		view_settings = {
			init_view_function = function()
				return true
			end,
			class = "PresetEditorPanelView",
			path = PRESET_PANEL_PATH,
			disable_game_world = false,
			load_always = true,
			load_in_hub = true,
			game_world_blur = 1.1,
			state_bound = true,
		},
		view_transitions = {},
		view_options = {
			close_all = false,
			close_previous = false,
		},
	})
	mod._preset_panel_registered = true
end

install_stale_preset_panel_hook()

mod.open_preset_editor = function(view, category)
	if not presets_enabled() then
		return
	end

	local target_mod_name = get_target_mod_name(category)

	if not target_mod_name or not get_mod(target_mod_name) then
		mod._show_preset_message(view, "Preset Editor", "This mod has no settings that can be saved as a preset.")
		return
	end

	if open_preset_panel(make_mod_scope(target_mod_name, category)) then
		return
	end

	local presets = get_preset_store()
	local mod_presets = presets[target_mod_name]
	local names = {}

	if type(mod_presets) == "table" then
		for name, preset in pairs(mod_presets) do
			if type(preset) == "table" and type(preset.settings) == "table" then
				names[#names + 1] = name
			end
		end
	end

	table.sort(names)

	local options = {}

	for _, name in ipairs(names) do
		options[#options + 1] = {
			text = string.format("%s", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				show_preset_options(view, category, target_mod_name, name)
			end,
		}
	end

	options[#options + 1] = {
		text = "Save current settings as preset",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			show_save(view, category, target_mod_name)
		end,
	}

	options[#options + 1] = {
		text = "Export current settings JSON",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			local settings = capture_settings(target_mod_name)

			if not settings then
				mod._show_preset_message(view, "Export Failed", "The target mod could not be found.")
				return
			end

			copy_per_mod_current_json(view, settings, target_mod_name)
		end,
	}

	options[#options + 1] = {
		text = "Import preset JSON",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			show_import(view, category, target_mod_name)
		end,
	}

	options[#options + 1] = {
		text = "loc_popup_button_close",
		template_type = "terminal_button_small",
		close_on_pressed = true,
		hotkey = "back",
		callback = function()
			if view then
				view._popup_id = nil
			end
		end,
	}

	show_popup(view, {
		title_text_unlocalized = mod:localize("preset_editor_title"),
		description_text_unlocalized = mod:localize("preset_editor_description", get_display_mod_name(target_mod_name)),
		type = "default",
		options = options,
	})
end

local function build_global_payload(name, mods)
	return {
		format = GLOBAL_PRESET_FORMAT,
		name = name,
		mods = mods,
	}
end

show_global_export = function(view, name, mods)
	local payload = build_global_payload(name, mods)
	local json = encode_json(payload)
	local options = {}

	if Clipboard and type(Clipboard.set) == "function" then
		options[#options + 1] = {
			text = "Copy to clipboard",
			no_localization = true,
			close_on_pressed = false,
			callback = function()
				Clipboard.set(json)
			end,
		}
	end

	options[#options + 1] = {
		template_type = "text",
		no_localization = true,
		text = json,
	}

	options[#options + 1] = {
		text = "loc_popup_button_close",
		template_type = "terminal_button_small",
		close_on_pressed = true,
		hotkey = "back",
		callback = function()
			if view then
				view._popup_id = nil
			end
		end,
	}

	show_popup(view, {
		title_text_unlocalized = "Export Global Preset JSON",
		description_text_unlocalized = string.format(
			"Share this string with another player for %s.",
			mod:localize("preset_editor_all_mods")
		),
		type = "default",
		options = options,
	})
end

show_global_import = function(view)
	local options = {
		{
			template_type = "terminal_input_field",
			max_length = 65536,
			keyboard_title = "Global Preset JSON",
		},
		{
			text = "Import",
			no_localization = true,
			close_on_pressed = true,
			callback = function(json_text)
				local ok, decoded = decode_json(json_text)

				if not ok or type(decoded) ~= "table" then
					mod._show_preset_message(view, "Import Failed", "The JSON string could not be read.")
					return
				end

				if decoded.format ~= GLOBAL_PRESET_FORMAT then
					mod._show_preset_message(view, "Import Failed", "This is not an Alfs DMF Extensions global preset string.")
					return
				end

				local mods = normalize_global_mods(decoded.mods)

				if not mods then
					mod._show_preset_message(view, "Import Failed", "The preset does not contain any mod settings.")
					return
				end

				local name = trim(decoded.name)

				if name == "" then
					name = "Imported Global Preset"
				end

				local description = string.format(
					"Import '%s' for %s? All current settings for every mod will be overwritten.",
					name,
					mod:localize("preset_editor_all_mods")
				)

				show_confirmation(view, "Import Global Preset", description, function()
					backup_global_settings()

					local presets = get_global_preset_store()

					presets[name] = preserve_assignment_fields(presets[name], {
						mods = mods,
						imported = true,
					})
					save_global_preset_store(presets)
					apply_global_settings(view, mods, name)
				end)
			end,
		},
		{
			text = "loc_popup_button_cancel_settings_reset_default",
			template_type = "terminal_button_small",
			close_on_pressed = true,
			hotkey = "back",
			callback = function()
				if view then
					view._popup_id = nil
				end
			end,
		},
	}

	show_popup(view, {
		title_text_unlocalized = "Import Global Preset JSON",
		description_text_unlocalized = "Paste a global preset JSON string, then press Import.",
		type = "default",
		options = options,
	})
end

show_global_save = function(view)
	local options = {
		{
			template_type = "terminal_input_field",
			max_length = 60,
			keyboard_title = "Global preset name",
		},
		{
			text = "Save",
			no_localization = true,
			close_on_pressed = true,
			callback = function(name_text)
				local name = trim(name_text)

				if name == "" then
					mod._show_preset_message(view, "Save Failed", "Enter a preset name.")
					return
				end

				local function do_save()
					local mods = capture_all_settings()

					if not mods then
						mod._show_preset_message(view, "Save Failed", "No mod settings could be saved.")
						return
					end

					local presets = get_global_preset_store()

					presets[name] = preserve_assignment_fields(presets[name], {
						mods = mods,
					})
					save_global_preset_store(presets)
					mod._show_preset_message(view, "Preset Saved", string.format("Saved global preset '%s'.", name))
				end

				local presets = get_global_preset_store()

				if presets[name] then
					show_confirmation(
						view,
						"Overwrite Preset",
						string.format("Overwrite the existing global preset '%s'?", name),
						do_save
					)
				else
					do_save()
				end
			end,
		},
		{
			text = "loc_popup_button_cancel_settings_reset_default",
			template_type = "terminal_button_small",
			close_on_pressed = true,
			hotkey = "back",
			callback = function()
				if view then
					view._popup_id = nil
				end
			end,
		},
	}

	show_popup(view, {
		title_text_unlocalized = "Save Global Preset",
		description_text_unlocalized = string.format("Enter a name for the new %s preset.", mod:localize("preset_editor_all_mods")),
		type = "default",
		options = options,
	})
end

local function show_global_preset_options(view, name)
	local presets = get_global_preset_store()
	local preset = presets[name]
	local mods = type(preset) == "table" and normalize_global_mods(preset.mods) or nil

	if not mods then
		mod._show_preset_message(view, "Preset Error", string.format("Global preset '%s' could not be found.", tostring(name)))
		return
	end

	local options = {
		{
			text = string.format("Apply '%s'", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				show_confirmation(
					view,
					"Apply Global Preset",
					string.format(
						"Apply '%s' to %s? All current settings for every mod will be overwritten.",
						name,
						mod:localize("preset_editor_all_mods")
					),
					function()
						apply_global_settings(view, mods, name)
					end
				)
			end,
		},
		{
			text = string.format("Export '%s' JSON", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				show_global_export(view, name, mods)
			end,
		},
		{
			text = string.format("Delete '%s'", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				show_confirmation(view, "Delete Preset", string.format("Delete global preset '%s'?", name), function()
					local current_presets = get_global_preset_store()

					current_presets[name] = nil
					save_global_preset_store(current_presets)
					refresh_preset_panel(view)
				end)
			end,
		},
		{
			text = "loc_view_back",
			template_type = "terminal_button_small",
			close_on_pressed = true,
			hotkey = "back",
			callback = function()
				mod.open_global_preset_editor(view)
			end,
		},
	}

	show_popup(view, {
		title_text_unlocalized = tostring(name),
		description_text_unlocalized = mod:localize("preset_editor_global_description"),
		type = "default",
		options = options,
	})
end

mod.open_global_preset_editor = function(view)
	if not presets_enabled() then
		return
	end

	if open_preset_panel(make_global_scope()) then
		return
	end

	local presets = get_global_preset_store()
	local names = {}

	for name, preset in pairs(presets) do
		if type(preset) == "table" and normalize_global_mods(preset.mods) then
			names[#names + 1] = name
		end
	end

	table.sort(names)

	local options = {}

	for _, name in ipairs(names) do
		options[#options + 1] = {
			text = string.format("%s", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				show_global_preset_options(view, name)
			end,
		}
	end

	options[#options + 1] = {
		text = "Save current settings as global preset",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			show_global_save(view)
		end,
	}

	options[#options + 1] = {
		text = "Export current settings JSON",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			local mods = capture_all_settings()

			if not mods then
				mod._show_preset_message(view, "Export Failed", "No mod settings could be exported.")
				return
			end

			copy_global_current_json(view, mods)
		end,
	}

	options[#options + 1] = {
		text = "Import global preset JSON",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			show_global_import(view)
		end,
	}

	options[#options + 1] = {
		text = "loc_popup_button_close",
		template_type = "terminal_button_small",
		close_on_pressed = true,
		hotkey = "back",
		callback = function()
			if view then
				view._popup_id = nil
			end
		end,
	}

	show_popup(view, {
		title_text_unlocalized = mod:localize("preset_editor_global_title"),
		description_text_unlocalized = mod:localize("preset_editor_global_description"),
		type = "default",
		options = options,
	})
end

mod.decode_global_profile_settings = function(data)
	local decoded = data

	if type(data) == "string" then
		local ok

		ok, decoded = decode_json(data)

		if not ok then
			return nil
		end
	end

	if type(decoded) ~= "table" then
		return nil
	end

	if decoded.format and decoded.format ~= GLOBAL_PRESET_FORMAT then
		return nil
	end

	return normalize_global_mods(decoded.mods or decoded.settings or decoded)
end

mod.apply_global_profile_settings = function(mods)
	if type(mods) ~= "table" or not next(mods) then
		return false
	end

	backup_global_settings()
	apply_global_settings(nil, mods, nil)
	flush_settings()

	return true
end

local function cog_pass_template(size)
	return {
		{
			pass_type = "hotspot",
			content_id = "hotspot",
			content = { use_is_focused = true },
		},
		{
			pass_type = "texture",
			style_id = "icon",
			value = COG_MATERIAL,
			style = {
				color = COLORS.normal,
				offset = { 0, 0, 2 },
				size = size,
			},
			change_function = function(content, style)
				local hotspot = content.hotspot
				local highlighted = hotspot and (hotspot.is_hover or hotspot.is_focused)

				style.color = highlighted and COLORS.hover or COLORS.normal
			end,
		},
	}
end

local function add_global_cog_definitions(definitions)
	if definitions._alfs_global_preset_cog then
		return
	end

	definitions._alfs_global_preset_cog = true

	local size = { COG_SIZE, COG_SIZE }

	definitions.scenegraph_definition[GLOBAL_COG_ID] = {
		parent = "title_divider",
		horizontal_alignment = "left",
		vertical_alignment = "bottom",
		size = size,
		position = { 340, -35, 2 },
	}

	definitions.widget_definitions[GLOBAL_COG_ID] = UIWidget.create_definition(cog_pass_template(size), GLOBAL_COG_ID, {
		visible = true,
		tooltip_text = mod:localize("preset_editor_global_tooltip"),
	}, size)
end

local function add_mod_cog_definitions(definitions)
	if definitions.scenegraph_definition[MOD_COG_ID] then
		return
	end

	local size = { COG_SIZE, COG_SIZE }

	definitions.scenegraph_definition[MOD_COG_ID] = {
		parent = "panel",
		horizontal_alignment = "left",
		vertical_alignment = "top",
		size = size,
		position = { 0, COG_Y, 4 },
	}

	definitions.widget_definitions[MOD_COG_ID] = UIWidget.create_definition(cog_pass_template(size), MOD_COG_ID, {
		visible = false,
		tooltip_text = mod:localize("preset_editor_tooltip"),
	}, size)
end

local function is_options_header(self)
	local class_table = getmetatable(self)

	return class_table and class_table.__class_name == "ViewElementOptionsHeader"
end

local function mod_cog_content(self)
	local widget = self and self._widgets_by_name and self._widgets_by_name[MOD_COG_ID]

	return widget and widget.content or nil
end

local function sync_mod_cog(self)
	local content = mod_cog_content(self)

	if not content then
		return nil
	end

	local category_entry = self._category_entry
	local mod_name = category_entry and category_entry.mod_name
	local visible = presets_enabled()
		and mod_name ~= nil
		and not category_entry.is_toggle_mods_category
		and get_mod(mod_name) ~= nil

	content.visible = visible
	content.tooltip_text = mod:localize("preset_editor_tooltip")

	local hotspot = content.hotspot

	if hotspot then
		hotspot.use_is_focused = true
	end

	return content, category_entry
end

local function handle_global_preset_cog(view)
	if not view or view.view_name ~= "dmf_options_view" or view._popup_id then
		return
	end

	local widget = view._widgets_by_name and view._widgets_by_name[GLOBAL_COG_ID]
	local content = widget and widget.content

	if content then
		content.visible = presets_enabled()
	end

	if not content or not content.visible then
		return
	end

	local hotspot = content.hotspot

	if hotspot and hotspot.on_pressed then
		hotspot.on_pressed = nil
		mod.open_global_preset_editor(view)
	end
end

mod._handle_global_preset_cog = handle_global_preset_cog

mod._prepare_global_preset_cog = function(definitions, settings)
	if
		settings
		and settings.name == "dmf_options_view"
		and type(definitions) == "table"
		and type(definitions.scenegraph_definition) == "table"
		and type(definitions.widget_definitions) == "table"
	then
		add_global_cog_definitions(definitions)
	end
end

local function position_mod_cog(self)
	local content = mod_cog_content(self)

	if not content or not content.visible then
		return
	end

	local title_width = self:_scenegraph_size("title") or 0
	local cog_x = title_width + COG_GAP
	local cog_y = COG_Y

	if self._has_pin then
		local pin_position = type(self.scenegraph_position) == "function" and self:scenegraph_position("pin") or nil
		local pin_x = pin_position and pin_position[1] or (title_width + COG_GAP)
		local pin_y = pin_position and pin_position[2] or (COG_Y - (PIN_SIZE - COG_SIZE) * 0.5)

		cog_x = pin_x + PIN_SIZE + COG_GAP
		cog_y = pin_y + (PIN_SIZE - COG_SIZE) * 0.5
	end

	if self._alfs_cog_x == cog_x and self._alfs_cog_y == cog_y then
		return
	end

	self._alfs_cog_x = cog_x
	self._alfs_cog_y = cog_y
	self:_set_scenegraph_position(MOD_COG_ID, cog_x, cog_y)
	self:_force_update_scenegraph()
end

local function position_cog_tooltip(self)
	local tooltip = self._widgets_by_name and self._widgets_by_name.tooltip
	local cog_widget = self._widgets_by_name and self._widgets_by_name[MOD_COG_ID]

	if not tooltip or not cog_widget then
		return
	end

	local tooltip_width = self:_scenegraph_size("tooltip") or 0
	local cog_position = self:scenegraph_position(MOD_COG_ID) or { 0, 0, 0 }
	local widget_x = cog_position[1] + (cog_widget.offset and cog_widget.offset[1] or 0)
	local widget_y = cog_position[2] + (cog_widget.offset and cog_widget.offset[2] or 0)

	tooltip.offset[1] = widget_x + (COG_SIZE - tooltip_width) * 0.5
	tooltip.offset[2] = widget_y + COG_SIZE + COG_GAP
end

mod._install_preset_cog_hooks = function()
	if mod._preset_cog_hooks_installed or type(mod.hook) ~= "function" then
		return
	end

	local classes = rawget(_G, "CLASSES") or rawget(_G, "CLASS")

	if type(classes) ~= "table" then
		return
	end

	local view_element_base = classes.ViewElementBase

	if type(view_element_base) ~= "table" then
		return
	end

	mod._preset_cog_hooks_installed = true

	mod:hook(view_element_base, "init", function(func, self, parent, draw_layer, start_scale, definitions, ...)
		if is_options_header(self) and type(definitions) == "table" then
			add_mod_cog_definitions(definitions)
		end

		return func(self, parent, draw_layer, start_scale, definitions, ...)
	end)

	mod:hook(view_element_base, "update", function(func, self, ...)
		local result = func(self, ...)

		if not is_options_header(self) then
			return result
		end

		local content, category_entry = sync_mod_cog(self)
		local hotspot = content and content.hotspot

		position_mod_cog(self)

		if hotspot and content.visible and hotspot.on_pressed and self._parent then
			hotspot.on_pressed = nil
			mod.open_preset_editor(self._parent, category_entry and category_entry.mod_name)
		end

		return result
	end)

	local header_class = classes.ViewElementOptionsHeader

	if type(header_class) ~= "table" then
		return
	end

	if type(header_class._position_tooltip) == "function" then
		mod:hook(header_class, "_position_tooltip", function(func, self, hovered_widget)
			if hovered_widget and hovered_widget == self._widgets_by_name[MOD_COG_ID] then
				position_cog_tooltip(self)
				return
			end

			func(self, hovered_widget)
		end)
	end

	if type(header_class._update_text_layout) == "function" then
		mod:hook(header_class, "_update_text_layout", function(func, self, ui_renderer)
			func(self, ui_renderer)
			position_mod_cog(self)
		end)
	end

	if type(header_class._update_tooltip) == "function" then
		mod:hook(header_class, "_update_tooltip", function(func, self, ...)
			func(self, ...)

			local content = mod_cog_content(self)

			if not content or not content.visible then
				local tooltip = self._widgets_by_name and self._widgets_by_name.tooltip

				if tooltip and self._hovered_tooltip_widget == self._widgets_by_name[MOD_COG_ID] then
					tooltip.content.visible = false
					self._hovered_tooltip_widget = nil
				end

				return
			end

			local hotspot = content.hotspot

			if not hotspot or not (hotspot.is_hover or hotspot.is_focused) then
				return
			end

			local tooltip = self._widgets_by_name.tooltip
			local tooltip_text = content.tooltip_text or mod:localize("preset_editor_tooltip")

			if
				self._hovered_tooltip_widget ~= self._widgets_by_name[MOD_COG_ID]
				or tooltip.content.text ~= tooltip_text
				or tooltip.content.mod_name_text ~= ""
			then
				self._hovered_tooltip_widget = self._widgets_by_name[MOD_COG_ID]
				self._tooltip_layout_dirty = true
			end

			tooltip.content.visible = true
			tooltip.content.text = tooltip_text
			tooltip.content.mod_name_text = ""
			self:_position_tooltip(self._widgets_by_name[MOD_COG_ID])
		end)
	end
end
