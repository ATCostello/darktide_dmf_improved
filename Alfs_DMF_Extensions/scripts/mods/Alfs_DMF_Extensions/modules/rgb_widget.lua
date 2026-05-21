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

	if category ~= mod._rgb_last_category then
		mod._rgb_last_category = category
		mod.inject_rgb_widgets(self, category)
		mod.filter_settings(self, category)
	elseif self._settings_content_grid ~= mod._grid_ref then
		mod.inject_rgb_widgets(self, category)
		mod.filter_settings(self, category)
	end

	mod._grid_ref = self._settings_content_grid
end
