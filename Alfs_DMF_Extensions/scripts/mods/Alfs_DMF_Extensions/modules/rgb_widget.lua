local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")

local view_settings = mod.dmf:io_dofile("dmf/scripts/mods/dmf/modules/ui/options/dmf_options_view_settings")

local rgb_blueprints =
	mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/rgb_widget_blueprints")

-- ############################################################
-- Helpers
-- ############################################################

local function ends_with(str, ending)
	return str and ending ~= "" and str:sub(-#ending) == ending
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

	local id = entry.setting_id
	return ends_with(id, "_R") or ends_with(id, "_G") or ends_with(id, "_B") or ends_with(id, "_A")
end

-- ############################################################
-- Extract RGB group safely
-- ############################################################

local function extract_rgb_group(widgets, start_index)
	local found = {}

	for j = start_index, start_index + 3 do
		local row = widgets[j]

		if row and row.widget and row.widget.content then
			local e = row.widget.content.entry

			if e and e.setting_id then
				if ends_with(e.setting_id, "_R") then
					found.R = e
				elseif ends_with(e.setting_id, "_G") then
					found.G = e
				elseif ends_with(e.setting_id, "_B") then
					found.B = e
				elseif ends_with(e.setting_id, "_A") then
					found.A = e
				end
			end
		end
	end

	if found.R and found.G and found.B then
		return found
	end
end

-- ############################################################
-- Widget creation
-- ############################################################

local function create_rgb_widget(self, group_widget, rgb_entries)
	if not group_widget or not rgb_entries then
		return nil
	end

	local template = rgb_blueprints.rgb_widget

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

	widget.content.tab = group_widget.content.tab or rgb_entries.R.tab or mod.default_tab

	template.init(self, widget, rgb_entries.R)

	return widget
end

-- ############################################################
-- Main injection pass
-- ############################################################

mod.inject_rgb_widgets = function(self, category)
	if not self._settings_category_widgets then
		return
	end

	local widgets = self._settings_category_widgets[category]

	if not widgets then
		return
	end

	local i = 1
	local replaced = 0

	while i <= #widgets do
		local row = widgets[i] -- get group header widget

		-- ONLY group headers
		if is_group(row.widget) then
			local rgb = extract_rgb_group(widgets, i + 1)

			if rgb then
				local r_row = widgets[i + 1]

				local rgb_widget = create_rgb_widget(self, r_row.widget, rgb)

				if rgb_widget then
					widgets[i + 1] = {
						widget = rgb_widget,
						alignment_widget = r_row.alignment_widget,
					}

					-- remove sub widgets
					local remove = {}

					for j = i + 2, #widgets do
						local e2 = widgets[j]
							and widgets[j].widget
							and widgets[j].widget.content
							and widgets[j].widget.content.entry

						if is_rgb_child(e2) then
							remove[#remove + 1] = j
						else
							break
						end
					end

					for k = #remove, 1, -1 do
						table.remove(widgets, remove[k])
					end

					-- set rgb widget offset to that of the group header
					-- NEED TO CHANGE THIS TO BE DYNAMIC/UPDATE BASED ON THE ORIGINAL _R/TOP WIDGET UNDER THE GROUP'S POSITION, AND MOVE TO FOLLOW THE GROUP HEADER AS THAT CHANGES POSITION
					-- store dynamic anchor refs
					rgb_widget._group_widget = row.widget
					rgb_widget._anchor_widget = r_row.widget
					rgb_widget._alignment_widget = r_row.alignment_widget

					replaced = replaced + 1
				end
			end
		end

		i = i + 1
	end
end

-- ############################################################
-- Hook entry point
-- ############################################################
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
	-- NEED TO RE-RUN THIS WHEN THE TABS CHANGES, IF CUSTOM TABS ARE ENABLED...
	if mod.current_category ~= mod.last_category then
		mod.inject_rgb_widgets(self, mod.current_category)
	end
end
