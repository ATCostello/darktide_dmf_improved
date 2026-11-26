local mod = get_mod("Alfs_DMF_Extensions")

local Utils = mod._preset_utils
local Core = mod._preset_core
local Constants = mod._preset_constants
local Popups = mod._preset_popups

local View = mod._preset_view or {}
mod._preset_view = View

local function clear_stale_preset_panel_view(handler)
	local active_views_data = handler and handler._active_views_data
	local active_views_array = handler and handler._active_views_array

	if not active_views_data or not active_views_array then
		return
	end

	local view_data = active_views_data[Constants.PRESET_PANEL_VIEW]
	local instance = view_data and view_data.instance

	if not instance then
		active_views_data[Constants.PRESET_PANEL_VIEW] = nil

		if mod._preset_panel_restore_settings_state_bound_if_settings_closed then
			mod._preset_panel_restore_settings_state_bound_if_settings_closed()
		end
	end

	local keep = instance and 1 or 0
	local index = 1

	while index <= #active_views_array do
		if active_views_array[index] == Constants.PRESET_PANEL_VIEW then
			if keep > 0 then
				keep = keep - 1
				index = index + 1
			else
				table.remove(active_views_array, index)
			end
		else
			index = index + 1
		end
	end

	handler._num_active_views = #active_views_array
end

local function install_stale_preset_panel_hook()
	if mod._preset_panel_stale_view_hook_installed or type(mod.hook_safe) ~= "function" then
		return
	end

	local class_registry = rawget(_G, "CLASS") or rawget(_G, "CLASSES")
	local handler_class = type(class_registry) == "table" and class_registry.UIViewHandler or nil

	if type(handler_class) ~= "table" or type(handler_class._force_close) ~= "function" then
		return
	end

	mod._preset_panel_stale_view_hook_installed = true

	mod:hook_safe(handler_class, "_force_close", function(self, view_name)
		if view_name == Constants.PRESET_PANEL_VIEW then
			clear_stale_preset_panel_view(self)
		end
	end)
end

local function install_settings_close_guard()
	if mod._preset_panel_close_guard_installed or type(mod.hook) ~= "function" then
		return
	end

	local class_registry = rawget(_G, "CLASS") or rawget(_G, "CLASSES")
	local ui_manager = type(class_registry) == "table" and (class_registry.UIManager or class_registry.ui_manager) or nil

	if type(ui_manager) ~= "table" or type(ui_manager.close_view) ~= "function" then
		return
	end

	mod._preset_panel_close_guard_installed = true

	local function should_block_settings_close(self, view_name, force_close)
		if view_name ~= "dmf_options_view" or force_close then
			return false
		end

		local handler = self
		local ui = Managers and Managers.ui
		local ui_handler = ui and ui._view_handler or nil

		if ui_handler and handler ~= ui_handler then
			handler = ui_handler
		end

		return type(handler) == "table"
			and type(handler.view_active) == "function"
			and handler:view_active(Constants.PRESET_PANEL_VIEW)
			and not handler:is_view_closing(Constants.PRESET_PANEL_VIEW)
	end

	mod:hook(ui_manager, "close_view", function(func, self, view_name, force_close, ...)
		if should_block_settings_close(self, view_name, force_close) then
			return
		end

		return func(self, view_name, force_close, ...)
	end)

	local handler_class = type(class_registry) == "table" and class_registry.UIViewHandler or nil

	if type(handler_class) == "table" and type(handler_class.close_view) == "function" then
		mod:hook(handler_class, "close_view", function(func, self, view_name, force_close, ...)
			if should_block_settings_close(self, view_name, force_close) then
				return
			end

			return func(self, view_name, force_close, ...)
		end)
	end
end

local function settings_view_settings()
	local ok, views = pcall(require, "scripts/ui/views/views")

	if not ok or type(views) ~= "table" then
		return nil
	end

	local settings = views["dmf_options_view"]

	return type(settings) == "table" and settings or nil
end

mod._preset_panel_suspend_settings_state_bound = function()
	if mod._preset_panel_saved_settings_state_bound ~= nil then
		return
	end

	local settings = settings_view_settings()

	if not settings then
		return
	end

	mod._preset_panel_saved_settings_state_bound = settings.state_bound
	settings.state_bound = false
end

mod._preset_panel_restore_settings_state_bound = function()
	if mod._preset_panel_saved_settings_state_bound == nil then
		return
	end

	local saved_state_bound = mod._preset_panel_saved_settings_state_bound

	mod._preset_panel_saved_settings_state_bound = nil

	local settings = settings_view_settings()

	if settings then
		settings.state_bound = saved_state_bound
	end
end

mod._preset_panel_restore_settings_state_bound_if_settings_closed = function()
	local ui = Managers and Managers.ui

	if ui and type(ui.view_active) == "function" and ui:view_active("dmf_options_view") then
		return
	end

	mod._preset_panel_restore_settings_state_bound()
end

mod._close_preset_panel_if_open = function()
	local ui = Managers and Managers.ui

	if not ui then
		return
	end

	clear_stale_preset_panel_view(ui._view_handler)

	if type(ui.view_active) == "function" and ui:view_active(Constants.PRESET_PANEL_VIEW) and type(ui.close_view) == "function" then
		ui:close_view(Constants.PRESET_PANEL_VIEW, true)
	end
end

View.open_panel = function(scope)
	if not Core.presets_enabled() then
		return false
	end

	install_stale_preset_panel_hook()
	install_settings_close_guard()

	if not mod._preset_panel_registered then
		return false
	end

	local ui = Managers and Managers.ui

	if not ui or type(ui.open_view) ~= "function" then
		return false
	end

	clear_stale_preset_panel_view(ui._view_handler)

	mod._preset_panel_context = scope

	if type(ui.view_active) == "function" and ui:view_active(Constants.PRESET_PANEL_VIEW) then
		local instance = type(ui.view_instance) == "function" and ui:view_instance(Constants.PRESET_PANEL_VIEW) or nil

		if instance and type(instance._set_scope) == "function" then
			instance:_set_scope(scope)
		end

		return true
	end

	mod._preset_panel_suspend_settings_state_bound()

	local opened = ui:open_view(
		Constants.PRESET_PANEL_VIEW,
		nil,
		false,
		false,
		nil,
		scope,
		{ use_transition_ui = false, game_world_blur = Constants.PRESET_PANEL_BLUR }
	)

	if opened == false then
		mod._preset_panel_restore_settings_state_bound()
	end

	return true
end

mod._preset_panel_get_scope = function()
	return mod._preset_panel_context or Core.make_global_scope()
end

mod._preset_panel_scope_for_view = function(view)
	if view then
		if type(view._scope) == "table" then
			return view._scope
		end

		if type(view._pending_scope) == "table" then
			return view._pending_scope
		end
	end

	return mod._preset_panel_get_scope()
end

mod._preset_panel_get_scope_name = function()
	return Core.scope_display_name(mod._preset_panel_get_scope())
end

mod._preset_panel_get_names = function(scope)
	return Core.get_preset_names(scope)
end

mod._preset_panel_get_preset = function(scope, name)
	return Core.get_scope_preset(scope, name)
end

mod._preset_panel_get_settings = function(scope)
	return Core.scope_capture_settings(scope)
end

mod._preset_panel_apply = function(view, scope, name)
	local preset = Core.get_scope_preset(scope, name)
	local preset_settings = Core.get_preset_settings(scope, preset)

	if not preset_settings then
		Popups.show_message(view, "Preset Error", string.format("Preset '%s' could not be found.", tostring(name)))
		return
	end

	Popups.show_confirmation(
		view,
		"Apply Preset",
		string.format(
			"Apply '%s' to %s? All current settings will be overwritten.",
			name,
			Core.scope_display_name(scope)
		),
		function()
			Core.apply_scope_settings(scope, preset_settings, name, view, true)
			Popups.refresh_preset_panel(view)
		end
	)
end

mod._preset_panel_delete = function(view, scope, name)
	Popups.show_confirmation(view, "Delete Preset", string.format("Delete preset '%s'?", name), function()
		local presets = Core.get_scope_presets(scope)

		presets[name] = nil
		Core.save_scope_presets(scope, presets)
		Popups.refresh_preset_panel(view)
	end)
end

mod._preset_panel_show_save = function(view, scope)
	if Core.is_global_scope(scope) then
		Popups.show_global_save(view)
		return
	end

	local mod_name = Utils.resolve_mod_name(scope.mod_name) or nil

	if not mod_name then
		Popups.show_message(view, "Save Failed", "The target mod could not be found.")
		return
	end

	Popups.show_save(view, scope and scope.category, mod_name)
end

mod._preset_panel_show_import = function(view, scope)
	if Core.is_global_scope(scope) then
		Popups.show_global_import(view)
		return
	end

	local mod_name = Utils.resolve_mod_name(scope.mod_name) or nil

	if not mod_name then
		Popups.show_message(view, "Import Failed", "The target mod could not be found.")
		return
	end

	Popups.show_import(view, scope and scope.category, mod_name)
end

mod._preset_panel_show_export = function(view, scope, name)
	local preset = Core.get_scope_preset(scope, name)
	local preset_settings = Core.get_preset_settings(scope, preset)

	if not preset_settings then
		Popups.show_message(view, "Export Failed", string.format("Preset '%s' could not be found.", tostring(name)))
		return
	end

	if Core.is_global_scope(scope) then
		Popups.copy_global_selected_json(view, name, preset_settings)
		return
	end

	local target_mod_name = Utils.resolve_mod_name(scope.mod_name) or nil

	if not target_mod_name then
		Popups.show_message(view, "Export Failed", "The target mod could not be found.")
		return
	end

	Popups.copy_per_mod_selected_json(view, name, preset_settings, target_mod_name)
end

mod._preset_panel_show_current_export = function(view, scope)
	local settings = Core.scope_capture_settings(scope)

	if type(settings) ~= "table" or not next(settings) then
		Popups.show_message(view, "Export Failed", "No settings could be exported.")
		return
	end

	if Core.is_global_scope(scope) then
		Popups.copy_global_current_json(view, settings)
		return
	end

	local mod_name = Utils.resolve_mod_name(scope.mod_name) or nil

	if not mod_name then
		Popups.show_message(view, "Export Failed", "The target mod could not be found.")
		return
	end

	Popups.copy_per_mod_current_json(view, settings, mod_name)
end

mod._preset_panel_get_scope_options = function()
	local regular_options = {}
	local pinned_options = {}
	local dmf = Utils.get_dmf()
	local seen = {}
	local favorites = dmf and type(dmf.get) == "function" and dmf:get("options_menu_favorite_mods") or nil
	local favorite_lookup = {}

	if type(favorites) == "table" then
		for _, favorite in pairs(favorites) do
			favorite_lookup[Utils.resolve_mod_name(favorite) or favorite] = true
		end
	end

	if dmf then
		for _, mod_widgets in ipairs(dmf.options_widgets_data or {}) do
			local header = mod_widgets[1]
			local mod_name = header and Utils.resolve_mod_name(header.mod_name)
			local display_name = Utils.get_display_mod_name(mod_name)

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
					sort_name = string.lower(tostring(display_name)),
					scope = Core.make_mod_scope(mod_name),
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

	local function sort_entries(entries)
		table.sort(entries, function(left, right)
			return (left.sort_name or "") < (right.sort_name or "")
		end)
	end

	sort_entries(pinned_options)
	sort_entries(regular_options)

	local options = {
		{
			display_name = mod:localize("preset_editor_all_mods"),
			sort_name = "",
			scope = Core.make_global_scope(),
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
	else
		Popups.refresh_preset_panel(view)
	end
end

mod._preset_panel_show_scope_dropdown = function(view)
	local dropdown = mod._preset_panel_dropdown

	if dropdown and type(dropdown.open) == "function" then
		dropdown.open(view)
	end
end

if not mod._preset_panel_registered and type(mod.add_require_path) == "function" and type(mod.register_view) == "function" then
	mod:add_require_path(Constants.PRESET_PANEL_PATH)
	mod:register_view({
		view_name = Constants.PRESET_PANEL_VIEW,
		view_settings = {
			init_view_function = function()
				return true
			end,
			class = "PresetEditorPanelView",
			path = Constants.PRESET_PANEL_PATH,
			disable_game_world = false,
			game_world_blur = Constants.PRESET_PANEL_BLUR,
			close_on_hotkey_pressed = false,
			state_bound = false,
			parent_transition_view = "dmf_options_view",
			use_transition_ui = false,
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
install_settings_close_guard()

mod.open_preset_editor = function(view, category)
	if not Core.presets_enabled() then
		return
	end

	local target_mod_name = Utils.get_target_mod_name(category)

	if not target_mod_name or not get_mod(target_mod_name) then
		Popups.show_message(view, "Preset Editor", "This mod has no settings that can be saved as a preset.")
		return
	end

	if View.open_panel(Core.make_mod_scope(target_mod_name, category)) then
		return
	end

	local _, mod_presets = Core.get_mod_preset_bucket(target_mod_name, false)
	local names = {}

	if mod_presets then
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
				Popups.show_preset_options(view, category, target_mod_name, name)
			end,
		}
	end

	options[#options + 1] = {
		text = "Save current settings as preset",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			Popups.show_save(view, category, target_mod_name)
		end,
	}

	options[#options + 1] = {
		text = "Export current settings JSON",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			local settings = Core.capture_settings(target_mod_name)

			if not settings then
				Popups.show_message(view, "Export Failed", "The target mod could not be found.")
				return
			end

			Popups.copy_per_mod_current_json(view, settings, target_mod_name)
		end,
	}

	options[#options + 1] = {
		text = "Import preset JSON",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			Popups.show_import(view, category, target_mod_name)
		end,
	}

	options[#options + 1] = {
		text = "loc_popup_button_close",
		template_type = "terminal_button_small",
		close_on_pressed = true,
		hotkey = "back",
	}

	Popups.show_popup(view, {
		title_text_unlocalized = mod:localize("preset_editor_title"),
		description_text_unlocalized = mod:localize("preset_editor_description", Utils.get_display_mod_name(target_mod_name)),
		type = "default",
		options = options,
	})
end

mod.open_global_preset_editor = function(view)
	if not Core.presets_enabled() then
		return
	end

	if View.open_panel(Core.make_global_scope()) then
		return
	end

	local presets = Core.get_global_preset_store()
	local names = {}

	for name, preset in pairs(presets) do
		if type(preset) == "table" and Core.normalize_global_mods(preset.mods) then
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
				Popups.show_global_preset_options(view, name)
			end,
		}
	end

	options[#options + 1] = {
		text = "Save current settings as global preset",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			Popups.show_global_save(view)
		end,
	}

	options[#options + 1] = {
		text = "Export current settings JSON",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			local mods = Core.capture_all_settings()

			if not mods then
				Popups.show_message(view, "Export Failed", "No mod settings could be exported.")
				return
			end

			Popups.copy_global_current_json(view, mods)
		end,
	}

	options[#options + 1] = {
		text = "Import global preset JSON",
		no_localization = true,
		close_on_pressed = true,
		callback = function()
			Popups.show_global_import(view)
		end,
	}

	options[#options + 1] = {
		text = "loc_popup_button_close",
		template_type = "terminal_button_small",
		close_on_pressed = true,
		hotkey = "back",
	}

	Popups.show_popup(view, {
		title_text_unlocalized = mod:localize("preset_editor_global_title"),
		description_text_unlocalized = mod:localize("preset_editor_global_description"),
		type = "default",
		options = options,
	})
end
