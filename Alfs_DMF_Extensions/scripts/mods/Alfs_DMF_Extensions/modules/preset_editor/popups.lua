local mod = get_mod("Alfs_DMF_Extensions")

local Utils = mod._preset_utils
local Core = mod._preset_core
local Constants = mod._preset_constants

local Popups = mod._preset_popups or {}
mod._preset_popups = Popups

local active_popups = {}
Popups.active_popups = active_popups

local function clear_view_popup_id(view, id)
	if view and view._popup_id == id then
		view._popup_id = nil
	end
end

Popups.untrack = function(id, view)
	if id then
		active_popups[id] = nil
	end

	clear_view_popup_id(view, id)
end

Popups.dismiss = function(id, view)
	local event_manager = Managers and Managers.event

	if id and event_manager and type(event_manager.trigger) == "function" then
		event_manager:trigger("event_remove_ui_popup", id)
	end

	Popups.untrack(id, view)
end

Popups.dismiss_for_view = function(view)
	if not view then
		return
	end

	local ids = {}
	local seen = {}
	local id = view._popup_id

	if id then
		ids[#ids + 1] = id
		seen[id] = true
	end

	for popup_id, owner in pairs(active_popups) do
		if owner == view and not seen[popup_id] then
			ids[#ids + 1] = popup_id
			seen[popup_id] = true
		end
	end

	for _, popup_id in ipairs(ids) do
		Popups.dismiss(popup_id, view)
	end

	view._popup_id = nil
end

Popups.dismiss_all = function()
	local entries = {}

	for id, owner in pairs(active_popups) do
		entries[#entries + 1] = {
			id = id,
			view = type(owner) == "table" and owner or nil,
		}
	end

	for _, entry in ipairs(entries) do
		Popups.dismiss(entry.id, entry.view)
	end
end

Popups.install_state_change_hook = function()
	if mod._preset_popup_state_hook_target or type(mod.hook_safe) ~= "function" then
		return
	end

	local class_registry = rawget(_G, "CLASS") or rawget(_G, "CLASSES")

	if type(class_registry) ~= "table" then
		return
	end

	local ui_manager = class_registry.UIManager or class_registry.ui_manager

	if type(ui_manager) ~= "table" or type(ui_manager.cb_on_game_state_change) ~= "function" then
		return
	end

	mod._preset_popup_state_hook_target = ui_manager

	mod:hook_safe(ui_manager, "cb_on_game_state_change", function()
		local popups = mod._preset_popups

		if popups and type(popups.dismiss_all) == "function" then
			popups.dismiss_all()
		end
	end)
end

Popups.install_state_change_hook()
mod._install_preset_popup_hooks = Popups.install_state_change_hook

mod._dismiss_preset_popup = function(id, view)
	Popups.dismiss(id, view)
end

mod._dismiss_preset_popup_for_view = function(view)
	Popups.dismiss_for_view(view)
end

Popups.show_popup = function(view, context)
	if type(context) ~= "table" then
		return
	end

	local event_manager = Managers and Managers.event

	if not event_manager or type(event_manager.trigger) ~= "function" then
		return
	end

	context.type = context.type or "default"

	local popup_ref = { id = nil }

	local function untrack_this_popup()
		local id = popup_ref.id

		if id then
			active_popups[id] = nil
			clear_view_popup_id(view, id)
		end
	end

	for _, option in ipairs(context.options or {}) do
		if type(option.callback) == "function" then
			local original_callback = option.callback

			option.callback = function(...)
				untrack_this_popup()
				return original_callback(...)
			end
		end
	end

	event_manager:trigger("event_show_ui_popup", context, function(id)
		popup_ref.id = id
		active_popups[id] = view or true

		if view then
			view._popup_id = id
		end
	end)
end

Popups.show_message = function(view, title, text)
	Popups.show_popup(view, {
		title_text_unlocalized = tostring(title or "Preset Editor"),
		description_text_unlocalized = tostring(text or ""),
		type = "default",
		options = {
			{
				text = "loc_popup_button_close",
				close_on_pressed = true,
				hotkey = "back",
			},
		},
	})
end

mod._show_preset_message = function(view, title, text)
	Popups.show_message(view, title, text)
end

Popups.copy_json_to_clipboard = function(view, json)
	local clipboard = rawget(_G, "Clipboard") or rawget(_G, "clipboard")

	if not clipboard or type(clipboard.put) ~= "function" then
		Popups.show_message(
			view,
			mod:localize("preset_editor_copy_failed_title"),
			mod:localize("preset_editor_copy_failed_description")
		)
		return false
	end

	clipboard.put(json)
	Popups.show_message(
		view,
		mod:localize("preset_editor_copied_title"),
		mod:localize("preset_editor_copied_description")
	)

	return true
end

Popups.show_confirmation = function(view, title, description, on_confirm)
	if type(on_confirm) ~= "function" then
		return
	end

	Popups.show_popup(view, {
		title_text_unlocalized = tostring(title or "Confirm"),
		description_text_unlocalized = tostring(description or ""),
		type = "default",
		options = {
			{
				text = "loc_popup_button_confirm",
				close_on_pressed = true,
				callback = function()
					on_confirm()
				end,
			},
			{
				text = "loc_popup_button_cancel_settings_reset_default",
				template_type = "terminal_button_small",
				close_on_pressed = true,
				hotkey = "back",
			},
		},
	})
end

Popups.refresh_preset_panel = function(view)
	local ui = Managers and Managers.ui
	local instance = nil

	if ui and type(ui.view_instance) == "function" then
		instance = ui:view_instance(Constants.PRESET_PANEL_VIEW)
	end

	if instance and type(instance._rebuild) == "function" then
		instance:_rebuild()
	elseif view and type(view._rebuild) == "function" then
		view:_rebuild()
	end
end

mod._preset_panel_refresh = function(view)
	Popups.refresh_preset_panel(view)
end

local function export_options(view, json)
	local options = {}
	local clipboard = rawget(_G, "Clipboard") or rawget(_G, "clipboard")

	if clipboard and type(clipboard.put) == "function" then
		options[#options + 1] = {
			text = "Copy to clipboard",
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				Popups.copy_json_to_clipboard(view, json)
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
	}

	return options
end

Popups.show_export = function(view, name, settings, target_mod_name)
	local json = Utils.encode_json(Core.build_payload(name, settings, target_mod_name))
	local options = export_options(view, json)
	local description =
		string.format("Share this string with another player for %s.", Utils.get_display_mod_name(target_mod_name))

	Popups.show_popup(view, {
		title_text_unlocalized = "Export Preset JSON",
		description_text_unlocalized = description,
		type = "default",
		options = options,
	})
end

Popups.show_global_export = function(view, name, mods)
	local json = Utils.encode_json(Core.build_global_payload(name, mods))
	local options = export_options(view, json)
	local description =
		string.format("Share this string with another player for %s.", mod:localize("preset_editor_all_mods"))

	Popups.show_popup(view, {
		title_text_unlocalized = "Export Global Preset JSON",
		description_text_unlocalized = description,
		type = "default",
		options = options,
	})
end

Popups.copy_per_mod_selected_json = function(view, name, settings, target_mod_name)
	return Popups.copy_json_to_clipboard(view, Utils.encode_json(Core.build_payload(name, settings, target_mod_name)))
end

Popups.copy_global_selected_json = function(view, name, mods)
	return Popups.copy_json_to_clipboard(view, Utils.encode_json(Core.build_global_payload(name, mods)))
end

Popups.copy_per_mod_current_json = function(view, settings, target_mod_name)
	return Popups.copy_json_to_clipboard(
		view,
		Utils.encode_json(Core.build_payload("Current Settings", settings, target_mod_name))
	)
end

Popups.copy_global_current_json = function(view, mods)
	return Popups.copy_json_to_clipboard(
		view,
		Utils.encode_json({
			format = Constants.GLOBAL_PRESET_FORMAT,
			name = "Current Settings",
			mods = mods,
		})
	)
end

Popups.show_import = function(view, category, target_mod_name)
	target_mod_name = Utils.resolve_mod_name(target_mod_name)

	if not target_mod_name then
		Popups.show_message(view, "Import Failed", "The target mod could not be found.")
		return
	end

	local options = {
		{
			template_type = "terminal_input_field",
			keyboard_title = "Preset JSON",
		},
		{
			text = "Import",
			no_localization = true,
			close_on_pressed = true,
			callback = function(json_text)
				local ok, decoded = Utils.decode_json(json_text)

				if not ok or type(decoded) ~= "table" then
					Popups.show_message(view, "Import Failed", "The JSON string could not be read.")
					return
				end

				if decoded.format ~= Constants.PRESET_FORMAT then
					Popups.show_message(view, "Import Failed", "This is not an Alfs DMF Extensions preset string.")
					return
				end

				if Utils.resolve_mod_name(decoded.mod_name) ~= Utils.resolve_mod_name(target_mod_name) then
					Popups.show_message(
						view,
						"Import Failed",
						string.format(
							"That preset is for '%s', not '%s'.",
							Utils.get_display_mod_name(decoded.mod_name),
							Utils.get_display_mod_name(target_mod_name)
						)
					)
					return
				end

				if type(decoded.settings) ~= "table" then
					Popups.show_message(view, "Import Failed", "The preset does not contain any settings.")
					return
				end

				local name = Utils.trim(decoded.name)

				if name == "" then
					name = "Imported Preset"
				end

				Popups.show_confirmation(
					view,
					"Import Preset",
					string.format(
						"Import '%s' into %s? All current settings for this mod will be overwritten.",
						name,
						Utils.get_display_mod_name(target_mod_name)
					),
					function()
						Core.backup_global_settings()

						local presets, mod_presets = Core.get_mod_preset_bucket(target_mod_name, true)

						mod_presets[name] = Core.preserve_assignment_fields(mod_presets[name], {
							settings = decoded.settings,
							imported = true,
						})
						Core.save_preset_store(presets)
						Core.apply_settings(view, target_mod_name, decoded.settings, name)
						Popups.refresh_preset_panel(view)
					end
				)
			end,
		},
		{
			text = "loc_popup_button_cancel_settings_reset_default",
			template_type = "terminal_button_small",
			close_on_pressed = true,
			hotkey = "back",
		},
	}

	Popups.show_popup(view, {
		title_text_unlocalized = "Import Preset JSON",
		description_text_unlocalized = "Paste a preset JSON string, then press Import.",
		type = "default",
		options = options,
	})
end

Popups.show_global_import = function(view)
	local options = {
		{
			template_type = "terminal_input_field",
			keyboard_title = "Global Preset JSON",
		},
		{
			text = "Import",
			no_localization = true,
			close_on_pressed = true,
			callback = function(json_text)
				local ok, decoded = Utils.decode_json(json_text)

				if not ok or type(decoded) ~= "table" then
					Popups.show_message(view, "Import Failed", "The JSON string could not be read.")
					return
				end

				if decoded.format ~= Constants.GLOBAL_PRESET_FORMAT then
					Popups.show_message(
						view,
						"Import Failed",
						"This is not an Alfs DMF Extensions global preset string."
					)
					return
				end

				local mods = Core.normalize_global_mods(decoded.mods)

				if not mods then
					Popups.show_message(view, "Import Failed", "The preset does not contain any mod settings.")
					return
				end

				local name = Utils.trim(decoded.name)

				if name == "" then
					name = "Imported Global Preset"
				end

				Popups.show_confirmation(
					view,
					"Import Global Preset",
					string.format(
						"Import '%s' for %s? All current settings for every mod will be overwritten.",
						name,
						mod:localize("preset_editor_all_mods")
					),
					function()
						Core.backup_global_settings()

						local presets = Core.get_global_preset_store()

						presets[name] = Core.preserve_assignment_fields(presets[name], {
							mods = mods,
							imported = true,
						})
						Core.save_global_preset_store(presets)
						Core.apply_global_settings(view, mods, name)
						Popups.refresh_preset_panel(view)
					end
				)
			end,
		},
		{
			text = "loc_popup_button_cancel_settings_reset_default",
			template_type = "terminal_button_small",
			close_on_pressed = true,
			hotkey = "back",
		},
	}

	Popups.show_popup(view, {
		title_text_unlocalized = "Import Global Preset JSON",
		description_text_unlocalized = "Paste a global preset JSON string, then press Import.",
		type = "default",
		options = options,
	})
end

Popups.show_save = function(view, category, target_mod_name)
	target_mod_name = Utils.resolve_mod_name(target_mod_name)

	if not target_mod_name then
		Popups.show_message(view, "Save Failed", "The target mod could not be found.")
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
				local name = Utils.trim(name_text)

				if name == "" then
					Popups.show_message(view, "Save Failed", "Enter a preset name.")
					return
				end

				local function do_save()
					local settings = Core.capture_settings(target_mod_name)

					if not settings then
						Popups.show_message(view, "Save Failed", "The target mod could not be found.")
						return
					end

					local presets, mod_presets = Core.get_mod_preset_bucket(target_mod_name, true)

					mod_presets[name] = Core.preserve_assignment_fields(mod_presets[name], {
						settings = settings,
					})
					Core.save_preset_store(presets)
					Popups.refresh_preset_panel(view)
					Popups.show_message(view, "Preset Saved", string.format("Saved '%s'.", name))
				end

				local _, mod_presets = Core.get_mod_preset_bucket(target_mod_name, false)

				if mod_presets and mod_presets[name] then
					Popups.show_confirmation(
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
		},
	}

	Popups.show_popup(view, {
		title_text_unlocalized = "Save Preset",
		description_text_unlocalized = "Enter a name for the new preset.",
		type = "default",
		options = options,
	})
end

Popups.show_global_save = function(view)
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
				local name = Utils.trim(name_text)

				if name == "" then
					Popups.show_message(view, "Save Failed", "Enter a preset name.")
					return
				end

				local function do_save()
					local mods = Core.capture_all_settings()

					if not mods then
						Popups.show_message(view, "Save Failed", "No mod settings could be saved.")
						return
					end

					local presets = Core.get_global_preset_store()

					presets[name] = Core.preserve_assignment_fields(presets[name], {
						mods = mods,
					})
					Core.save_global_preset_store(presets)
					Popups.refresh_preset_panel(view)
					Popups.show_message(view, "Preset Saved", string.format("Saved global preset '%s'.", name))
				end

				local presets = Core.get_global_preset_store()

				if presets[name] then
					Popups.show_confirmation(
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
		},
	}

	Popups.show_popup(view, {
		title_text_unlocalized = "Save Global Preset",
		description_text_unlocalized = string.format(
			"Enter a name for the new %s preset.",
			mod:localize("preset_editor_all_mods")
		),
		type = "default",
		options = options,
	})
end

Popups.show_preset_options = function(view, category, target_mod_name, name)
	local _, mod_presets = Core.get_mod_preset_bucket(target_mod_name, false)
	local preset = mod_presets and mod_presets[name] or nil

	if type(preset) ~= "table" or type(preset.settings) ~= "table" then
		Popups.show_message(view, "Preset Error", string.format("Preset '%s' could not be found.", tostring(name)))
		return
	end

	local options = {
		{
			text = string.format("Apply '%s'", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				Popups.show_confirmation(
					view,
					"Apply Preset",
					string.format(
						"Apply '%s' to %s? All current settings for this mod will be overwritten.",
						name,
						Utils.get_display_mod_name(target_mod_name)
					),
					function()
						Core.apply_settings(view, target_mod_name, preset.settings, name)
					end
				)
			end,
		},
		{
			text = string.format("Export '%s' JSON", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				Popups.show_export(view, name, preset.settings, target_mod_name)
			end,
		},
		{
			text = string.format("Delete '%s'", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				Popups.show_confirmation(view, "Delete Preset", string.format("Delete preset '%s'?", name), function()
					local current_presets, current_mod_presets = Core.get_mod_preset_bucket(target_mod_name, false)

					if current_mod_presets then
						current_mod_presets[name] = nil
						Core.save_preset_store(current_presets)
					end

					Popups.refresh_preset_panel(view)
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

	Popups.show_popup(view, {
		title_text_unlocalized = tostring(name),
		description_text_unlocalized = mod:localize(
			"preset_editor_description",
			Utils.get_display_mod_name(target_mod_name)
		),
		type = "default",
		options = options,
	})
end

Popups.show_global_preset_options = function(view, name)
	local presets = Core.get_global_preset_store()
	local preset = presets[name]
	local mods = type(preset) == "table" and Core.normalize_global_mods(preset.mods) or nil

	if not mods then
		Popups.show_message(
			view,
			"Preset Error",
			string.format("Global preset '%s' could not be found.", tostring(name))
		)
		return
	end

	local options = {
		{
			text = string.format("Apply '%s'", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				Popups.show_confirmation(
					view,
					"Apply Global Preset",
					string.format(
						"Apply '%s' to %s? All current settings for every mod will be overwritten.",
						name,
						mod:localize("preset_editor_all_mods")
					),
					function()
						Core.apply_global_settings(view, mods, name)
					end
				)
			end,
		},
		{
			text = string.format("Export '%s' JSON", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				Popups.show_global_export(view, name, mods)
			end,
		},
		{
			text = string.format("Delete '%s'", name),
			no_localization = true,
			close_on_pressed = true,
			callback = function()
				Popups.show_confirmation(
					view,
					"Delete Preset",
					string.format("Delete global preset '%s'?", name),
					function()
						local current_presets = Core.get_global_preset_store()

						current_presets[name] = nil
						Core.save_global_preset_store(current_presets)
						Popups.refresh_preset_panel(view)
					end
				)
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

	Popups.show_popup(view, {
		title_text_unlocalized = tostring(name),
		description_text_unlocalized = mod:localize("preset_editor_global_description"),
		type = "default",
		options = options,
	})
end

mod.decode_global_profile_settings = function(data)
	local decoded = data

	if type(data) == "string" then
		local ok

		ok, decoded = Utils.decode_json(data)

		if not ok then
			return nil
		end
	end

	if type(decoded) ~= "table" then
		return nil
	end

	if decoded.format and decoded.format ~= Constants.GLOBAL_PRESET_FORMAT then
		return nil
	end

	return Core.normalize_global_mods(decoded.mods or decoded.settings or decoded)
end

mod.apply_global_profile_settings = function(mods)
	if type(mods) ~= "table" or not next(mods) then
		return false
	end

	if not Core.silent then
		Core.backup_global_settings()
	end

	Core.apply_global_settings(nil, mods, nil)
	Core.flush_settings()

	return true
end
