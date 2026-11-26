local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")

mod.compound_key = function(category, key)
	if not category then
		return tostring(key)
	end
	return tostring(category) .. "|" .. tostring(key)
end

mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/Alfs_DMF_Extensions_localization")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/load_dmf")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/step_size_value")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/save_scroll_position")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/per_mod_tabs_toggle")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/mod_tabs")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/settings_profile_importer")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/rgb_widget")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/dropdown_icons")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/font_type_support")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/scrollable_dropdown")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/mod_reload_keybind")

if mod._install_character_hooks then
	mod._install_character_hooks()
end

if mod._sync_auto_presets_with_current_player then
	mod._sync_auto_presets_with_current_player()
end

mod.get_time = function()
	local tm = Managers and Managers.time
	local fallback = os.clock() or 0
	if tm then
		if tm:has_timer("gameplay") then
			return tm:time("gameplay") or fallback
		end
		if tm:has_timer("ui") then
			return tm:time("ui") or fallback
		end
		if tm:has_timer("main") then
			return tm:time("main") or fallback
		end
	end
	return fallback
end

local auto_preset_time = 0

mod.update = function(dt)
	auto_preset_time = auto_preset_time + (dt or 0)

	if mod._update_auto_presets then
		mod._update_auto_presets(auto_preset_time)
	end
end

mod.last_category = nil
mod.current_category = nil

local storage_keys = {}

local function get_mod_storage_key(category)
	local key = storage_keys[category]

	if not key then
		key = string.format("%s_%s", tostring(category), tostring(category or "unknown_category"))
		storage_keys[category] = key
	end

	return key
end

mod.get_mod_storage_key_for_tab = get_mod_storage_key

local function has_multiple_tabs(self)
	return (self and self._mod_tab_widget_count or 0) > 1
end

local option_values = {}
local reset_tab_localization_added = false

mod.on_setting_changed = function(setting_id)
	option_values[setting_id] = nil

	local Core = mod._preset_core

	if Core and type(Core.invalidate_setting) == "function" then
		Core.invalidate_setting(setting_id)
	end
end

local function cached_option(setting_id)
	if option_values[setting_id] == nil then
		option_values[setting_id] = mod:get(setting_id)
	end

	return option_values[setting_id]
end

mod.cached_option = cached_option

local cached_group_widgets
local cached_group_widgets_for
local cached_group_count = 0

local function group_header_widgets(self)
	local widgets = self._settings_content_widgets

	if not widgets then
		return nil, 0
	end

	if widgets == cached_group_widgets_for and cached_group_widgets then
		return cached_group_widgets, cached_group_count
	end

	local headers = {}
	local count = 0

	for index = 1, #widgets do
		local widget = widgets[index]
		local entry = widget and widget.content and widget.content.entry

		if entry and entry.widget_type == "group_header" then
			count = count + 1
			headers[count] = widget
		end
	end

	cached_group_widgets_for = widgets
	cached_group_widgets = headers
	cached_group_count = count

	return headers, count
end

local function hovered_group_tooltip(self)
	local headers, count = group_header_widgets(self)
	local category = self._selected_category
	local category_mod = category and mod._category_mod_map and mod._category_mod_map[category] or nil

	if not headers or not category_mod then
		return nil, nil
	end

	local lookup = mod._group_tooltip_lookup

	for index = 1, count do
		local widget = headers[index]
		local content = widget and widget.content
		local hotspot = content and content.hotspot
		local entry = content and content.entry

		if hotspot and hotspot.is_hover and entry and not entry.tooltip_text then
			local tooltip = nil

			if entry._alfs_tooltip_for ~= category_mod then
				entry._alfs_tooltip_for = category_mod
				entry._alfs_tooltip_display_key = entry.display_name and (category_mod .. "|" .. entry.display_name)
					or nil
				entry._alfs_tooltip_setting_key = entry.setting_id and (category_mod .. "|" .. entry.setting_id) or nil
			end

			if entry.display_name then
				tooltip = lookup and lookup[entry._alfs_tooltip_display_key]
			end

			if not tooltip and entry.setting_id then
				tooltip = lookup and lookup[entry._alfs_tooltip_setting_key]
			end

			if tooltip then
				return tooltip, content
			end
		end
	end

	return nil, nil
end

local function reset_tab_settings(self)
	local category = self._selected_category
	if not category then
		return
	end

	local mod_storage_key = get_mod_storage_key(category)
	local selected_tab = mod.selected_tabs and mod.selected_tabs[mod_storage_key]
	if not selected_tab then
		return
	end

	local category_widgets = self._settings_category_widgets and self._settings_category_widgets[category]
	if not category_widgets then
		return
	end

	local settings_default_values = self._settings_category_default_values
		and self._settings_category_default_values[category]
	if not settings_default_values then
		return
	end

	for _, data in ipairs(category_widgets) do
		local widget = data.widget
		if widget and widget.content then
			local tab = widget.content.tab
			if tab and tab == selected_tab then
				local entry = widget.content.entry
				if entry then
					local default_value = settings_default_values[entry]
					if default_value ~= nil and entry.on_activated then
						entry.on_activated(default_value, entry)
					end
				end

				local rgb_entries =
					{ widget.content.r_entry, widget.content.g_entry, widget.content.b_entry, widget.content.a_entry }
				for _, rgb_entry in ipairs(rgb_entries) do
					if rgb_entry then
						local default_value = settings_default_values[rgb_entry]
						if default_value ~= nil and rgb_entry.on_activated then
							rgb_entry.on_activated(default_value, rgb_entry)
						end
					end
				end
			end
		end
	end
end

local orig_settings_grid_background = nil
local orig_settings_grid_mask = nil
local orig_settings_grid_interaction = nil
local orig_settings_header = nil

mod:hook_safe(CLASS.BaseView, "init", function(self, definitions, settings, context, dynamic_package_name)
	mod._install_character_hooks()

	if self.view_name ~= "dmf_options_view" then
		return
	end

	mod._prepare_global_preset_cog(definitions, settings)
	mod._install_preset_cog_hooks()

	local defs = self._definitions
	defs.scenegraph_definition = defs.scenegraph_definition or {}

	defs.scenegraph_definition.mod_tab_area = {
		parent = "settings_header",
		horizontal_alignment = "left",
		vertical_alignment = "top",
		size = { 900, 60 },
		position = { 0, -55, 20 },
	}

	defs.scenegraph_definition.mod_tab_content = {
		parent = "mod_tab_area",
		horizontal_alignment = "left",
		vertical_alignment = "center",
		size = { 900, 60 },
		position = { 0, 0, 1 },
	}

	defs.scenegraph_definition.mod_tab_scrollbar = {
		parent = "mod_tab_area",
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		size = { 900, 8 },
		position = { 0, -10, 2 },
	}

	if
		defs.scenegraph_definition.settings_grid_start and not defs.scenegraph_definition.settings_grid_start.position
	then
		defs.scenegraph_definition.settings_grid_start.position = { 0, 0, 0 }
	end

	if
		defs.scenegraph_definition.settings_grid_content_pivot
		and not defs.scenegraph_definition.settings_grid_content_pivot.position
	then
		defs.scenegraph_definition.settings_grid_content_pivot.position = { 0, 0, 0 }
	end

	if not orig_settings_grid_background then
		orig_settings_grid_background = defs.scenegraph_definition.settings_grid_background
	end
	if not orig_settings_grid_mask then
		orig_settings_grid_mask = defs.scenegraph_definition.settings_grid_mask
	end
	if not orig_settings_grid_interaction then
		orig_settings_grid_interaction = defs.scenegraph_definition.settings_grid_interaction
	end
	if not orig_settings_header then
		orig_settings_header = defs.scenegraph_definition.settings_header
	end

	local scenegraph_definition = defs.scenegraph_definition
	local header = scenegraph_definition.settings_header
	local grid_background = scenegraph_definition.settings_grid_background
	local scrollbar = scenegraph_definition.settings_scrollbar
	local grid_interaction = scenegraph_definition.settings_grid_interaction
	local grid_mask = scenegraph_definition.settings_grid_mask

	if header and header.position and orig_settings_header and orig_settings_header.position then
		header.position[2] = orig_settings_header.position[2] - 40
	end

	if
		grid_background
		and grid_background.size
		and grid_background.position
		and orig_settings_grid_background
		and orig_settings_grid_background.size
		and orig_settings_grid_background.position
	then
		grid_background.size[1] = orig_settings_grid_background.size[1] + 80
		grid_background.size[2] = 1012
		grid_background.position[1] = orig_settings_grid_background.position[1] + 80
		grid_background.position[2] = 16
	end

	if scrollbar and scrollbar.size then
		scrollbar.size[2] = 1012
	end

	if grid_interaction and grid_interaction.size then
		grid_interaction.size[2] = 1012
	end

	if
		grid_mask
		and grid_mask.size
		and grid_mask.position
		and grid_interaction
		and grid_interaction.size
		and grid_interaction.position
	then
		grid_mask.size[1] = grid_interaction.size[1] + 20
		grid_mask.size[2] = grid_interaction.size[2] + 20
		grid_mask.position[1] = grid_interaction.position[1] - 20
		grid_mask.position[2] = grid_interaction.position[2]
	end

	if self._ui_scenegraph then
		self._ui_scenegraph = UIScenegraph.init_scenegraph(defs.scenegraph_definition, self._render_scale)
	end

	if mod:get("enable_tab_reset") then
		local reset_tab_title = mod:localize("reset_tab_to_default")
		local reset_tab_text = mod:localize("reset_tab_to_default_description")

		if Managers.localization and not reset_tab_localization_added then
			reset_tab_localization_added = true
			Managers.localization:append_backend_localizations({
				["loc_alf_dmf_ext_reset_tab"] = reset_tab_title,
				["loc_alf_dmf_ext_reset_tab_desc"] = reset_tab_text,
			})
		end

		self.cb_reset_tab_to_default = function(self_view)
			local category = self_view._selected_category
			if not category then
				return
			end

			local context = {
				title_text_unlocalized = reset_tab_title,
				description_text_unlocalized = reset_tab_text,
				type = "warning",
				options = {
					{
						text = "loc_popup_button_settings_reset_default",
						close_on_pressed = true,
						callback = callback(function()
							reset_tab_settings(self_view)
							self_view._popup_id = nil
						end),
					},
					{
						text = "loc_popup_button_cancel_settings_reset_default",
						template_type = "terminal_button_small",
						close_on_pressed = true,
						hotkey = "back",
						callback = function()
							self_view._popup_id = nil
						end,
					},
				},
			}

			Managers.event:trigger("event_show_ui_popup", context, function(id)
				self_view._popup_id = id
			end)
		end

		defs.legend_inputs = defs.legend_inputs or {}

		if not defs._alfs_reset_legend_added then
			defs._alfs_reset_legend_added = true
			table.insert(defs.legend_inputs, {
				input_action = mod:get("keybind_reset_tab"),
				display_name = "loc_alf_dmf_ext_reset_tab",
				on_pressed_callback = "cb_reset_tab_to_default",
				visibility_function = function(parent)
					if not mod.cached_option("enable_tab_reset") then
						return false
					end
					if not mod.cached_option("enable_mod_tabs") then
						return false
					end
					if self.is_text_input_focused then
						return false
					end
					return has_multiple_tabs(parent)
				end,
			})
		end
	end
end)

mod:hook_safe(CLASS.BaseView, "on_exit", function(self)
	mod.last_category = nil

	if mod._dismiss_preset_popup_for_view then
		mod._dismiss_preset_popup_for_view(self)
	end

	if self.view_name == "dmf_options_view" then
		cached_group_widgets = nil
		cached_group_widgets_for = nil
		cached_group_count = 0
		mod._gen_tabs_toggle_widgets = {}
		mod._tab_inject_state = {}
		mod._preset_editor_widgets = {}
		mod._rgb_original_widgets = {}
		mod._grid_ref = nil
		mod._rgb_last_category = nil
		mod._color_widget_last_category = nil
		mod._rgb_active_mode = nil
	end

	orig_settings_grid_background = nil
	orig_settings_grid_mask = nil
	orig_settings_grid_interaction = nil
	orig_settings_header = nil
end)

mod:hook_safe(CLASS.BaseView, "on_enter", function(self)
	mod._install_character_hooks()

	if mod._install_preset_popup_hooks then
		mod._install_preset_popup_hooks()
	end

	mod._sync_auto_presets_with_current_player()
	mod._try_show_pending_profile_prompts()

	if self.view_name == "dmf_options_view" then
		mod._rgb_original_widgets = {}
		mod._rgb_last_category = nil
		mod._color_widget_last_category = nil
		mod._rgb_active_mode = mod.current_rgb_mode and mod.current_rgb_mode() or cached_option("enable_RGB_widget")
	end
end)

mod:hook_safe(CLASS.BaseView, "update", function(self, dt, t, input_service)
	if self.view_name ~= "dmf_options_view" then
		return
	end

	mod._handle_global_preset_cog(self)

	mod.current_category = self._selected_category

	local tooltip, tooltip_content = hovered_group_tooltip(self)

	if tooltip and tooltip_content and tooltip_content.entry then
		tooltip_content.entry.tooltip_text = tooltip
		tooltip_content.tooltip_text = tooltip
	end

	if mod.sync_rgb_mode then
		mod.sync_rgb_mode(self)
	end

	mod._addModTabs(self, dt, t, input_service)

	local rgb_mode = mod._rgb_active_mode
		or (mod.current_rgb_mode and mod.current_rgb_mode() or cached_option("enable_RGB_widget"))

	if rgb_mode == "argb_sliders" then
		mod._addRgbSliders(self)
	elseif rgb_mode == "color_widget" then
		mod._addColorWidgetReplacements(self)
	end

	if rgb_mode ~= "disabled" then
		mod._updateRGBSliders(self, input_service, dt, t)
	end

	if cached_option("enable_font_support") then
		mod._addFontSupport(self, dt, t, input_service)
	end

	if cached_option("enable_scrollable_dropdown") then
		mod._addScrollableDropdown(self, dt, t, input_service)
	end

	mod.last_category = mod.current_category
end)
