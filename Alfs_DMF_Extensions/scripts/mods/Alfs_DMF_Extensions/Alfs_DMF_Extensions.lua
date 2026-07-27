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
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/rgb_widget")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/dropdown_icons")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/font_type_support")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/scrollable_dropdown")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/mod_reload_keybind")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/keybindings_fix")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/icon_package_loader")

-- NOTE: Slider text input has been removed. The new DMF (dmf_test_patch) includes
-- NumericInput natively in its value_slider blueprint, providing click-to-type on
-- slider values. Our previous custom implementation conflicted with it.

mod.last_category = nil
mod.current_category = nil

local function get_mod_storage_key(category)
	return string.format("%s_%s", tostring(category), tostring(category or "unknown_category"))
end

mod.get_mod_storage_key_for_tab = get_mod_storage_key

local function has_multiple_tabs(self)
	local category = self._selected_category
	if not category then
		return false
	end
	local tabs = mod.get_tabs and mod.get_tabs(self, category)
	return tabs and #tabs > 1
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

mod:hook(CLASS.BaseView, "init", function(func, self, definitions, settings, context, dynamic_package_name)
	func(self, definitions, settings, context, dynamic_package_name)

	if self.view_name ~= "dmf_options_view" then
		return
	end

	mod._ensure_icon_packages_loaded()

	local defs = self._definitions
	defs.scenegraph_definition = defs.scenegraph_definition or {}

	defs.scenegraph_definition.mod_tab_area = {
		parent = "settings_header",
		horizontal_alignment = "left",
		vertical_alignment = "top",
		size = { 900, 60 },
		position = { 50, -55, 10 },
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

	self._ui_scenegraph = UIScenegraph.init_scenegraph(defs.scenegraph_definition)

	if mod:get("enable_tab_reset") then
		local reset_tab_title = mod:localize("reset_tab_to_default")
		local reset_tab_text = mod:localize("reset_tab_to_default_description")

		if Managers.localization then
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
		table.insert(defs.legend_inputs, {
			input_action = "hotkey_menu_special_1",
			display_name = "loc_alf_dmf_ext_reset_tab",
			on_pressed_callback = "cb_reset_tab_to_default",
			visibility_function = function(parent)
				if not mod:get("enable_tab_reset") then
					return false
				end
				if not mod:get("enable_mod_tabs") then
					return false
				end
				return has_multiple_tabs(parent)
			end,
		})
	end
end)

mod:hook_safe(CLASS.BaseView, "on_exit", function(self)
	mod.last_category = nil

	if self.view_name == "dmf_options_view" then
		mod._gen_tabs_toggle_widgets = {}
		mod._tab_inject_state = {}
	end
end)

mod:hook_safe(CLASS.BaseView, "on_enter", function(self)
	if self.view_name == "dmf_options_view" then
		mod._rgb_last_category = nil
		mod._ensure_icon_packages_loaded()
	end
end)

mod:hook_safe(CLASS.BaseView, "update", function(self, dt, t, input_service)
	if self.view_name ~= "dmf_options_view" and self.view_name ~= "options_view" then
		return
	end

	mod.current_category = self._selected_category

	if mod:get("enable_scroll_position_saving") then
		mod._saveScrollPosition(self)
	end

	mod._addModTabs(self, dt, t, input_service)

	if mod:get("enable_RGB_widget") then
		mod._addRgbSliders(self)
	end
	if mod:get("enable_RGB_widget") then
		mod._updateRGBSliders(self, input_service, dt, t)
	end

	if mod:get("enable_dropdown_icons") then
		mod._addDropdownIcons(self, dt, t, input_service)
	end
	if mod:get("enable_font_support") then
		mod._addFontSupport(self, dt, t, input_service)
	end
	if mod:get("enable_scrollable_dropdown") then
		mod._addScrollableDropdown(self, dt, t, input_service)
	end

	mod.last_category = mod.current_category
end)
