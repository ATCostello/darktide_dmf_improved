local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")

local view_settings = mod.dmf:io_dofile("dmf/scripts/mods/dmf/modules/ui/options/dmf_options_view_settings")

local rgb_blueprints =
	mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/rgb_widget_blueprints")

local function ends_with(str, ending)
	return str and ending ~= "" and str:sub(-#ending):lower() == ending:lower()
end

local SUFFIX_MAP = {
	["_R"] = "R",
	["_red"] = "R",
	["_G"] = "G",
	["_green"] = "G",
	["_B"] = "B",
	["_blue"] = "B",
	["_A"] = "A",
	["_alpha"] = "A",
	["_opacity"] = "A",
	["_transparency"] = "A",
}

local function get_suffix_type(id)
	for suffix, type in pairs(SUFFIX_MAP) do
		if ends_with(id, suffix) then
			return type
		end
	end
	return nil
end

local function strip_suffix(id)
	for suffix, _ in pairs(SUFFIX_MAP) do
		if ends_with(id, suffix) then
			return id:sub(1, -#suffix - 1)
		end
	end
	return id
end

local function is_slider(widget)
	if not widget then
		return false
	end

	if widget.type ~= "value_slider" then
		return false
	end

	return true
end

local function is_group(widget)
	if not widget then
		return false
	end

	if widget.type ~= "group_header" then
		return false
	end

	return true
end

local function is_rgb_child(entry)
	if not entry or not entry.setting_id then
		return false
	end

	return get_suffix_type(entry.setting_id) ~= nil
end

local function extract_rgb_group(widgets, start_index)
	local found = {}
	local indices = {}

	for j = start_index, #widgets do
		local row = widgets[j]

		if row and row.widget then
			if is_group(row.widget) then
				break
			end

			if row.widget.content then
				local e = row.widget.content.entry

				if e and e.setting_id then
					local suffix_type = get_suffix_type(e.setting_id)

					if not suffix_type then
						break
					end

					if is_slider(row.widget) and suffix_type and not found[suffix_type] then
						found[suffix_type] = e
						indices[suffix_type] = j
					end
				end
			end
		end
	end

	if found.R and found.G and found.B then
		return found, indices
	end

	return nil
end

local function extract_rgb_cluster(widgets, start_index)
	local found = {}
	local base_name = nil

	for j = start_index, math.min(start_index + 7, #widgets) do
		local row = widgets[j]

		if not row or not row.widget or not row.widget.content then
			break
		end

		local e = row.widget.content.entry

		if not e or not e.setting_id then
			break
		end

		local suffix_type = get_suffix_type(e.setting_id)

		if not suffix_type then
			break
		end

		if is_slider(row.widget) and suffix_type then
			local name = strip_suffix(e.setting_id)

			if not base_name then
				base_name = name
			elseif name ~= base_name then
				break
			end

			if found[suffix_type] then
				break
			end

			found[suffix_type] = e
		end

		if found.R and found.G and found.B then
			break
		end
	end

	if found.R and found.G and found.B then
		return found, base_name
	end
end

local function create_rgb_widget(self, group_widget, rgb_entries)
	if not rgb_entries then
		return nil
	end

	local has_alpha = rgb_entries.A ~= nil
	local template = has_alpha and rgb_blueprints.rgb_widget_argb or rgb_blueprints.rgb_widget

	local widget_def =
		UIWidget.create_definition(template.pass_template, "settings_grid_content_pivot", nil, template.size)

	widget_def.content = table.clone(template.content or {})
	widget_def.style = table.clone(template.style or {})

	local widget = self:_create_widget("rgb_widget_" .. rgb_entries.R.setting_id, widget_def)

	if not widget then
		return nil
	end

	widget.type = "rgb_widget"
	widget.update = template.update

	widget.content.r_entry = rgb_entries.R
	widget.content.g_entry = rgb_entries.G
	widget.content.b_entry = rgb_entries.B
	widget.content.a_entry = rgb_entries.A

	if not widget.content.tab then
		widget.content.tab = group_widget and group_widget.content.tab or rgb_entries.R.tab or mod.default_tab
	end

	template.init(self, widget, rgb_entries.R)

	return widget
end

local function inject_group_rgb_widgets(self, widgets)
	local i = 1
	local replaced = 0

	while i <= #widgets do
		local row = widgets[i]

		if is_group(row.widget) then
			local rgb, indices = extract_rgb_group(widgets, i + 1)

			if rgb then
				local first_idx = math.min(indices.R, indices.G, indices.B, indices.A or math.huge)
				local r_row = widgets[first_idx]

				local rgb_widget = create_rgb_widget(self, r_row.widget, rgb)

				if rgb_widget then
					rgb_widget.content.tab = row.widget.content.tab

					widgets[first_idx] = {
						entry = r_row.entry,
						widget = rgb_widget,
						alignment_widget = r_row.alignment_widget,
					}

					local remove = {}
					for _, j in pairs(indices) do
						if j ~= first_idx then
							remove[#remove + 1] = j
						end
					end
					table.sort(remove)
					for k = #remove, 1, -1 do
						table.remove(widgets, remove[k])
					end

					rgb_widget._group_widget = row.widget
					rgb_widget._anchor_widget = r_row.widget
					rgb_widget._alignment_widget = r_row.alignment_widget

					replaced = replaced + 1
				end
			end
		end

		i = i + 1
	end

	return replaced
end

local function inject_cluster_rgb_widgets(self, widgets)
	local i = 1
	while i <= #widgets do
		local row = widgets[i]

		if row and row.widget then
			if not is_group(row.widget) then
				local entry = row.widget.content and row.widget.content.entry

				if entry and entry.setting_id then
					local suffix = get_suffix_type(entry.setting_id)

					if suffix == "R" or suffix == "G" or suffix == "B" or suffix == "A" then
						local rgb, base_name = extract_rgb_cluster(widgets, i)

						if rgb then
							local r_row = widgets[i]

							local rgb_widget = create_rgb_widget(self, nil, rgb)

							if rgb_widget then
								rgb_widget.content.tab = r_row.widget.content.tab

								widgets[i] = {
									entry = r_row.entry,
									widget = rgb_widget,
									alignment_widget = r_row.alignment_widget,
								}

								local remove = {}

								for j = i + 1, #widgets do
									local e2 = widgets[j]
										and widgets[j].widget
										and widgets[j].widget.content
										and widgets[j].widget.content.entry

									if e2 and e2.setting_id and get_suffix_type(e2.setting_id) then
										local name = strip_suffix(e2.setting_id)

										if name == base_name then
											remove[#remove + 1] = j
										else
											break
										end
									else
										break
									end
								end

								for k = #remove, 1, -1 do
									table.remove(widgets, remove[k])
								end

								rgb_widget._anchor_widget = r_row.widget
								rgb_widget._alignment_widget = r_row.alignment_widget
							end
						end
					end
				end
			end
		end

		i = i + 1
	end
end

mod.inject_rgb_widgets = function(self, category)
	if not self._settings_category_widgets then
		return
	end

	local widgets = self._settings_category_widgets[category]

	if not widgets then
		return
	end

	inject_group_rgb_widgets(self, widgets)
	inject_cluster_rgb_widgets(self, widgets)
end

mod._updateRGBSliders = function(self, input_service, dt, t)
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

		if widget and widget.type == "rgb_widget" and widget.update then
			widget.update(self, widget, input_service, dt, t)
		end
	end
end

mod._addRgbSliders = function(self)
	local category = mod.current_category

	if not category then
		return
	end

	local mode = mod:get("enable_RGB_widget")
	local mode_changed = mode ~= mod._rgb_last_mode

	if category ~= mod._rgb_last_category or mode_changed then
		mod._rgb_last_category = category
		mod._rgb_last_mode = mode
		mod.inject_rgb_widgets(self, category)
		mod.filter_settings(self, category)
	elseif self._settings_content_grid ~= mod._grid_ref then
		mod.inject_rgb_widgets(self, category)
		mod.filter_settings(self, category)
	end

	mod._grid_ref = self._settings_content_grid
end

local function create_dmf_color_widget(self, base_name, rgb_entries, has_alpha, original_widget)
	local ColorUtils = mod.dmf:io_dofile("dmf/scripts/mods/dmf/modules/ui/options/color/color_utils")
	local ColorWidgetPasses = mod.dmf:io_dofile("dmf/scripts/mods/dmf/modules/ui/options/color/color_widget_passes")

	local colors_equal = ColorUtils.equal
	local copy_color = ColorUtils.copy

	local COLOR_VALUE_IDS = {
		"color_value_1",
		"color_value_2",
		"color_value_3",
		"color_value_4",
	}

	local function first_channel_index(alpha)
		return alpha and 1 or 2
	end

	local function stop_gamepad_channel_edit(content)
		content.gamepad_active_channel = nil
		content.gamepad_channel_value = nil
	end

	local function refresh_color_value_text(content)
		local first_channel = first_channel_index(content.entry.has_alpha)

		for i = first_channel, 4 do
			content[COLOR_VALUE_IDS[i]] = string.format("%.0f", content.preview_color[i])
		end

		content.color_value_text_dirty = false
	end

	local function get_combined_color()
		local r = rgb_entries.R.get_function() or 0
		local g = rgb_entries.G.get_function() or 0
		local b = rgb_entries.B.get_function() or 0
		local a = has_alpha and rgb_entries.A.get_function() or 255
		return { a, r, g, b }
	end

	local function set_combined_color(new_color)
		if rgb_entries.R.on_activated then
			rgb_entries.R.on_activated(new_color[2] or 0)
		end
		if rgb_entries.G.on_activated then
			rgb_entries.G.on_activated(new_color[3] or 0)
		end
		if rgb_entries.B.on_activated then
			rgb_entries.B.on_activated(new_color[4] or 0)
		end
		if has_alpha and rgb_entries.A.on_activated then
			rgb_entries.A.on_activated(new_color[1] or 255)
		end
	end

	local default_color = get_combined_color()

	local entry = {
		widget_type = "color",
		mod_name = rgb_entries.R.mod_name or "Alfs_DMF_Extensions",
		setting_id = base_name,
		display_name = rgb_entries.R.display_name and rgb_entries.R.display_name:gsub(" R$", "") or base_name,
		has_alpha = has_alpha,
		default_value = default_color,
		tab = rgb_entries.R.tab,
		get_function = function()
			return get_combined_color()
		end,
		on_activated = function(new_color)
			set_combined_color(new_color)
		end,
		changed_callback = function() end,
	}

	local settings_grid_width = 1000
	local settings_value_width = 500
	local settings_value_height = 64

	local pass_template = ColorWidgetPasses.create(settings_grid_width, settings_value_height, settings_value_width, has_alpha)
	local widget_definition = UIWidget.create_definition(pass_template, "settings_grid_content_pivot", nil, {
		settings_grid_width,
		settings_value_height,
	})

	local widget_name = "color_widget_" .. base_name
	local widget = self:_create_widget(widget_name, widget_definition)

	if not widget then
		return nil
	end

	widget.type = "color"

	local content = widget.content
	local color = get_combined_color()

	content.text = ""
	content.entry = entry
	content.preview_color = copy_color(color)
	content.color_value_text_dirty = true
	content.preview_hotspot.use_is_focused = true
	content.hotspot.pressed_callback = function()
		if not entry.disabled and not Managers.ui:using_cursor_navigation() then
			self:cb_on_settings_pressed(widget, entry)
		end
	end
	content.gamepad_input_handler = function(input_service)
		local GAMEPAD_CHANNEL_SPEED = 150
		local gamepad_selected_control = content.gamepad_selected_control
		local gamepad_active_channel = content.gamepad_active_channel

		if gamepad_active_channel then
			local gamepad_channel_value = content.gamepad_channel_value or content.preview_color[gamepad_active_channel]
			local dt = Manager.time:dt("ui")

			if input_service:get("move_left_per_second") then
				gamepad_channel_value = math.max(0, gamepad_channel_value - GAMEPAD_CHANNEL_SPEED * dt)
			elseif input_service:get("move_right_per_second") then
				gamepad_channel_value = math.min(255, gamepad_channel_value + GAMEPAD_CHANNEL_SPEED * dt)
			end

			if input_service:get("confirm") then
				content.preview_color[gamepad_active_channel] = gamepad_channel_value
				content.on_color_changed()
				stop_gamepad_channel_edit(content)
			elseif input_service:get("back") then
				stop_gamepad_channel_edit(content)
			else
				content.gamepad_channel_value = gamepad_channel_value
				content.preview_color[gamepad_active_channel] = gamepad_channel_value
				content.on_color_changed()
			end
		end
	end
	content.on_navigation_input_changed = function()
		ColorWidgetPasses.stop_drag(content)
		stop_gamepad_channel_edit(content)
		content.gamepad_selected_control = nil
	end
	content.on_color_changed = function()
		content.color_value_text_dirty = true
		entry.on_activated(copy_color(content.preview_color))
		entry.changed_callback()
	end

	entry.changed_callback = function()
		self:cb_on_settings_changed(widget, entry)
	end

	refresh_color_value_text(content)

	local original_update = nil
	local GAMEPAD_CHANNEL_SPEED_UPDATE = 150

	local function color_widget_update(parent, widget, input_service, dt)
		local content = widget.content
		local entry = content.entry
		local is_disabled = entry.disabled or false
		local drag_active = content.drag_active and not is_disabled
		local using_gamepad = not parent:using_cursor_navigation()

		content.disabled = is_disabled

		if not content.exclusive_focus or not using_gamepad then
			content.gamepad_selected_control = nil
			stop_gamepad_channel_edit(content)
		elseif not content.gamepad_selected_control then
			content.gamepad_selected_control = "preview"
		end

		if content.preview_hotspot.on_pressed and not is_disabled and not using_gamepad then
			parent:show_color_picker(entry)
		elseif not drag_active and not content.gamepad_active_channel then
			local setting_color = get_combined_color()

			if not colors_equal(content.preview_color, setting_color) then
				content.preview_color = copy_color(setting_color)
				content.color_value_text_dirty = true
			end
		end

		if drag_active and not parent._selected_settings_widget then
			parent:set_exclusive_focus_on_grid_widget(widget.name)
		elseif content.drag_previously_active and not drag_active then
			parent:set_exclusive_focus_on_grid_widget(nil)
		end

		if content.gamepad_active_channel then
			local gamepad_channel_value = content.gamepad_channel_value or content.preview_color[content.gamepad_active_channel]
			local dt_real = Manager.time:dt("ui")

			if input_service:get("move_left_per_second") then
				gamepad_channel_value = math.max(0, gamepad_channel_value - GAMEPAD_CHANNEL_SPEED_UPDATE * dt_real)
			elseif input_service:get("move_right_per_second") then
				gamepad_channel_value = math.min(255, gamepad_channel_value + GAMEPAD_CHANNEL_SPEED_UPDATE * dt_real)
			end

			if input_service:get("confirm") then
				content.preview_color[content.gamepad_active_channel] = gamepad_channel_value
				content.on_color_changed()
				stop_gamepad_channel_edit(content)
			elseif input_service:get("back") then
				stop_gamepad_channel_edit(content)
			else
				content.gamepad_channel_value = gamepad_channel_value
				content.preview_color[content.gamepad_active_channel] = gamepad_channel_value
				content.on_color_changed()
			end
		end

		content.drag_previously_active = drag_active

		if content.color_value_text_dirty then
			refresh_color_value_text(content)
		end

		return true
	end

	widget.update = color_widget_update

	local alignment_widget = original_widget and original_widget.alignment_widget or {
		horizontal_alignment = "right",
		size = { settings_grid_width, settings_value_height },
	}

	return widget, alignment_widget
end

local function inject_color_widget_replacements(self, widgets)
	local i = 1
	local replaced = 0

	while i <= #widgets do
		local row = widgets[i]

		if is_group(row.widget) then
			local rgb, indices = extract_rgb_group(widgets, i + 1)

			if rgb then
				local has_alpha = rgb.A ~= nil
				local base_name = strip_suffix(rgb.R.setting_id)
				local first_idx = math.min(indices.R, indices.G, indices.B, has_alpha and indices.A or math.huge)
				local r_row = widgets[first_idx]

				local color_widget, alignment_widget = create_dmf_color_widget(self, base_name, rgb, has_alpha, r_row)

				if color_widget then
					color_widget.content.tab = row.widget.content.tab

					local final_alignment = alignment_widget or r_row.alignment_widget
					final_alignment.name = color_widget.name

					widgets[first_idx] = {
						entry = r_row.entry,
						widget = color_widget,
						alignment_widget = final_alignment,
					}

					local remove = {}
					for _, j in pairs(indices) do
						if j ~= first_idx then
							remove[#remove + 1] = j
						end
					end
					table.sort(remove)
					for k = #remove, 1, -1 do
						table.remove(widgets, remove[k])
					end

					replaced = replaced + 1
				end
			end
		end

		i = i + 1
	end

	i = 1

	while i <= #widgets do
		local row = widgets[i]

		if not is_group(row.widget) then
			local entry = row.widget.content and row.widget.content.entry

			if entry and entry.setting_id then
				local suffix = get_suffix_type(entry.setting_id)

				if suffix == "R" or suffix == "G" or suffix == "B" or suffix == "A" then
					local rgb, base_name = extract_rgb_cluster(widgets, i)

					if rgb then
						local has_alpha = rgb.A ~= nil
						local color_widget, alignment_widget = create_dmf_color_widget(self, base_name, rgb, has_alpha, row)

						if color_widget then
							color_widget.content.tab = row.widget.content.tab

							local final_alignment = alignment_widget or row.alignment_widget
							final_alignment.name = color_widget.name

							widgets[i] = {
								entry = row.entry,
								widget = color_widget,
								alignment_widget = final_alignment,
							}

							local remove = {}
							for j = i + 1, #widgets do
								local e2 = widgets[j] and widgets[j].widget and widgets[j].widget.content
									and widgets[j].widget.content.entry
								if e2 and e2.setting_id and get_suffix_type(e2.setting_id) then
									local name = strip_suffix(e2.setting_id)
									if name == base_name then
										remove[#remove + 1] = j
									else
										break
									end
								else
									break
								end
							end

							for k = #remove, 1, -1 do
								table.remove(widgets, remove[k])
							end

							replaced = replaced + 1
						end
					end
				end
			end
		end

		i = i + 1
	end

	return replaced
end

mod.inject_color_widgets = function(self, category)
	if not self._settings_category_widgets then
		return
	end

	local widgets = self._settings_category_widgets[category]

	if not widgets then
		return
	end

	inject_color_widget_replacements(self, widgets)
end

mod._addColorWidgetReplacements = function(self)
	local category = mod.current_category

	if not category then
		return
	end

	local mode = mod:get("enable_RGB_widget")
	local mode_changed = mode ~= mod._color_widget_last_mode

	if category ~= mod._color_widget_last_category or mode_changed then
		mod._color_widget_last_category = category
		mod._color_widget_last_mode = mode
		mod.inject_color_widgets(self, category)
		mod.filter_settings(self, category)
	elseif self._settings_content_grid ~= mod._grid_ref then
		mod.inject_color_widgets(self, category)
		mod.filter_settings(self, category)
	end

	mod._grid_ref = self._settings_content_grid
end
