local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")

mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/Alfs_DMF_Extensions_localization")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/load_dmf")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/step_size_value")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/save_scroll_position")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/mod_tabs")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/rgb_widget")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/dropdown_icons")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/font_type_support")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/scrollable_dropdown")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/mod_reload_keybind")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/keybindings_fix")

local text_input_field = mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/text_input_field")

local SLIDER_COLORS = {
	text_normal = Color.terminal_text_header(nil, true),
	text_selected = Color.terminal_text_header_selected(nil, true),
	background_hover = Color.terminal_background_gradient(nil, true),
	frame_hover = Color.terminal_corner_hover(nil, true),
}

mod.last_category = nil
mod.current_category = nil

local SLIDER_TYPES = {
	value_slider = true,
	percent_slider = true,
	slider = true,
}

local function get_value_text_style(widget)
	local style = widget.style
	return style.value_text or style.value_text_style
end

local function safe_input_get(input_service, action_name, default)
	local ok, result = pcall(input_service.get, input_service, action_name)
	return ok and result or default
end

local SliderPassTemplates = require("scripts/ui/pass_templates/slider_pass_templates")

local function add_value_hotspot_to_pass_template(passes, width, height)
	for i = 1, #passes do
		if passes[i].content_id == "value_hotspot" then
			return
		end
	end

	local value_text_x = width - 20
	local text_area_width = 80
	local insert_before = #passes + 1

	for i = 1, #passes do
		local pass = passes[i]
		if pass.value_id == "value_text" then
			if pass.style and pass.style.offset then
				value_text_x = pass.style.offset[1]
			end
			if pass.style and pass.style.size then
				text_area_width = pass.style.size[1]
			end
			insert_before = i
			break
		end
	end

	local right_edge = value_text_x + text_area_width
	local hotspot_w = math.min(text_area_width - 16, 48)
	local hotspot_h = math.max(height - 16, 16)
	local hotspot_x = right_edge - hotspot_w
	local hotspot_y = math.max(math.floor((height - hotspot_h) / 2), 1)
	local new_passes = {}

	new_passes[#new_passes + 1] = {
		pass_type = "texture",
		value = "content/ui/materials/frames/frame_tile_1px",
		style_id = "value_frame",
		visibility_function = function(content, style)
			local hotspot = content.value_hotspot
			return content.value_editing or (hotspot and hotspot.is_hover)
		end,
		style = {
			scale_to_material = true,
			color = SLIDER_COLORS.frame_hover,
			offset = { hotspot_x - 2, hotspot_y - 2, 4 },
			size = { hotspot_w + 4, hotspot_h + 4 },
		},
	}

	new_passes[#new_passes + 1] = {
		pass_type = "rect",
		style_id = "value_edit_bg",
		visibility_function = function(content, style)
			return content.value_editing
		end,
		style = {
			color = SLIDER_COLORS.background_hover,
			offset = { hotspot_x, hotspot_y, 3 },
			size = { hotspot_w, hotspot_h },
		},
	}

	new_passes[#new_passes + 1] = {
		pass_type = "rect",
		style_id = "value_caret",
		visibility_function = function(content, style)
			return content.value_editing
		end,
		style = {
			color = SLIDER_COLORS.text_selected,
			offset = { hotspot_x + 2, hotspot_y + 2, 5 },
			size = { 2, hotspot_h - 4 },
		},
	}

	for j = 1, #new_passes do
		table.insert(passes, insert_before + j - 1, new_passes[j])
	end

	passes[#passes + 1] = {
		pass_type = "hotspot",
		content_id = "value_hotspot",
		style_id = "value_hotspot_style",
		style = {
			offset = { hotspot_x, hotspot_y, 10 },
			size = { hotspot_w, hotspot_h },
			visible = true,
		},
	}
end

local orig_settings_value_slider = SliderPassTemplates.settings_value_slider
SliderPassTemplates.settings_value_slider = function(width, height, value_width, interactive)
	local passes = orig_settings_value_slider(width, height, value_width, interactive)
	if passes then
		add_value_hotspot_to_pass_template(passes, width, height)
	end
	return passes
end

local orig_settings_percent_slider = SliderPassTemplates.settings_percent_slider
if orig_settings_percent_slider then
	SliderPassTemplates.settings_percent_slider = function(width, height, value_width, interactive)
		local passes = orig_settings_percent_slider(width, height, value_width, interactive)
		if passes then
			add_value_hotspot_to_pass_template(passes, width, height)
		end
		return passes
	end
end

mod:hook(CLASS.BaseView, "init", function(func, self, definitions, settings, context, dynamic_package_name)
	func(self, definitions, settings, context, dynamic_package_name)

	if self.view_name ~= "dmf_options_view" then
		return
	end

	local defs = self._definitions
	defs.scenegraph_definition = defs.scenegraph_definition or {}

	defs.scenegraph_definition.mod_tab_area = {
		parent = "settings_grid_content_pivot",
		horizontal_alignment = "left",
		vertical_alignment = "top",
		size = { 900, 60 },
		position = { 0, 45, 800 },
	}

	defs.scenegraph_definition.mod_tab_content = {
		parent = "mod_tab_area",
		horizontal_alignment = "left",
		vertical_alignment = "center",
		size = { 900, 60 },
		position = { 0, 0, 801 },
	}

	defs.scenegraph_definition.mod_tab_scrollbar = {
		parent = "mod_tab_area",
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		size = { 900, 8 },
		position = { 0, -10, 802 },
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

	defs.scenegraph_definition.settings_grid_background.size[2] = 1012
	defs.scenegraph_definition.settings_grid_background.position[2] = 16
	defs.scenegraph_definition.settings_scrollbar.size[2] = 1012
	defs.scenegraph_definition.settings_grid_mask.size[2] = 2000
	defs.scenegraph_definition.settings_grid_mask.position[2] = -10
	defs.scenegraph_definition.settings_grid_interaction.size[2] = 1012

	self._ui_scenegraph = UIScenegraph.init_scenegraph(defs.scenegraph_definition)
end)

mod:hook_safe(CLASS.BaseView, "on_exit", function(self)
	mod.last_category = nil
end)

mod:hook_safe(CLASS.BaseView, "on_enter", function(self)
	if self.view_name == "dmf_options_view" then
		mod._rgb_last_category = nil
		mod.update_default_tab()
	end
end)

mod._processSliderTextInput = function(self, input_service, dt, t)
	local category = mod.current_category

	if not category then
		return
	end

	local widgets = self._settings_category_widgets and self._settings_category_widgets[category]

	if not widgets then
		return
	end

	for _, row in ipairs(widgets) do
		local widget = row.widget

		if widget and SLIDER_TYPES[widget.type] then
			local content = widget.content
			local entry = content.entry

			if entry and entry.get_function then
				local value_hotspot = content.value_hotspot
				local left_hold = safe_input_get(input_service, "left_hold", false)
				local prev_left_hold = content._txt_prev_left_hold
				content._txt_prev_left_hold = left_hold

				local value_text_style = get_value_text_style(widget)

				local min = entry.min_value or 0
				local max = entry.max_value or 999999
			local num_decimals = entry.num_decimals
			if num_decimals == nil or num_decimals == 0 then
				if entry.step_size and entry.step_size < 1 then
					num_decimals = 2
				elseif min ~= math.floor(min) or max ~= math.floor(max) then
					num_decimals = 2
				else
					num_decimals = 0
				end
			end
			local abs_max = math.max(math.abs(min), math.abs(max))
			local int_digits = #tostring(math.floor(abs_max))
			local max_length = int_digits + (num_decimals > 0 and (num_decimals + 1) or 0) + (min < 0 and 1 or 0)
			content.value_max_length = math.max(max_length, 1)
			content.value_allow_decimal = num_decimals > 0
			content.value_allow_minus = min < 0

				if value_hotspot and value_hotspot.on_pressed and not content.value_editing then
					local prev_display = content.value_text
					text_input_field.start_editing(content, "value", function()
						return entry.get_function()
					end)
					if prev_display then
						content._prev_value_text = prev_display
					end
					if value_text_style then
						content._txt_orig_color = table.clone(value_text_style.text_color)
					end
				end

				if content.value_editing then
					local keystrokes = Keyboard.keystrokes()
					text_input_field.process_keystrokes(content, "value", keystrokes, t)

					local set_value_fn = function(val)
						if entry.on_activated then
							entry.on_activated(val, entry)
						end
						if entry.changed_callback then
							entry.changed_callback(val)
						end
					end

					text_input_field.handle_edit_commands(content, "value", set_value_fn, min, max)

					if content.value_editing then
						content.value_text = content.value_edit_buffer or ""

						if value_text_style then
							value_text_style.text_color[2] = SLIDER_COLORS.text_selected[2]
							value_text_style.text_color[3] = SLIDER_COLORS.text_selected[3]
							value_text_style.text_color[4] = SLIDER_COLORS.text_selected[4]
						end

						local hotspot_style = widget.style.value_hotspot_style
						local vt_x = hotspot_style and hotspot_style.offset[1]
							or (value_text_style and value_text_style.offset[1] or 935)
						local buf = content.value_edit_buffer or ""
						local pos = math.min(#buf + 1, max_length + 1)
						local caret = widget.style.value_caret
						if caret then
							caret.offset[1] = vt_x + 2 + (pos - 1) * 16
						end
					end

					if not content._last_input_time then
						content._last_input_time = t
					end

					if text_input_field.timeout_inactive(content, t, 5) then
						text_input_field.confirm_value(
							content,
							"value",
							content.value_edit_buffer or "",
							set_value_fn,
							min,
							max
						)
						text_input_field.stop_editing(content, "value")
					end

					if left_hold and not prev_left_hold and not (value_hotspot and value_hotspot.is_hover) then
						text_input_field.confirm_value(
							content,
							"value",
							content.value_edit_buffer or "",
							set_value_fn,
							min,
							max
						)
						text_input_field.stop_editing(content, "value")
					end

					content.drag_active = false
					content.drag_previously_active = false
				end

				if not content.value_editing and content._txt_orig_color then
					local orig = content._txt_orig_color

					if value_text_style then
						local tc = value_text_style.text_color
						tc[2] = orig[2]
						tc[3] = orig[3]
						tc[4] = orig[4]
					end

					content._txt_orig_color = nil
				end
			end
		end
	end
end

mod:hook_safe(CLASS.BaseView, "update", function(self, dt, t, input_service)
	if self.view_name ~= "dmf_options_view" then
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

	mod._processSliderTextInput(self, input_service, dt, t)

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
