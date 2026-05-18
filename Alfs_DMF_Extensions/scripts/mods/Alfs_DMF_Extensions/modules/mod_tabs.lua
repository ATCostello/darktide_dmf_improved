local mod = get_mod("Alfs_DMF_Extensions")

local UIWidgetGrid = require("scripts/ui/widget_logic/ui_widget_grid")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local view_settings = mod.dmf:io_dofile("dmf/scripts/mods/dmf/modules/ui/options/dmf_options_view_settings")

local _content_blueprints =
	mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/mod_tabs_blueprints")

mod.selected_tabs = mod.selected_tabs or {}
mod.tab_scroll_index = mod.tab_scroll_index or {}

local function truncate_tab_title(text)
	if not text then return text end
	local words = {}
	for word in text:gmatch("%S+") do
		words[#words + 1] = word
	end
	if #words <= 3 then
		return text
	end
	local result = ""
	for i = 1, 3 do
		result = result .. words[i]
		if i < 3 then
			result = result .. " "
		end
	end
	return result .. ".."
end

local function get_current_mod_name(self, category)
	if not self._selected_category then
		return "unknown_mod"
	end

	return self._selected_category
end

local function get_mod_storage_key(self, category)
	local mod_name = get_current_mod_name(self, category)

	return string.format("%s_%s", tostring(mod_name), tostring(category or "unknown_category"))
end

local function category_has_explicit_tabs(self, category)
	local templates = self._options_templates and self._options_templates.settings
	if not templates then return false end

	for _, template in ipairs(templates) do
		if template.category == category and template.tab then
			return true
		end
	end

	return false
end

-- horizontal scrolling state
mod.max_visible_tabs = 5

-- ############################################################
-- Inject tabs into widgets
-- ############################################################

mod.inject_tabs_into_widgets = function(self, category)
	local widgets = self._settings_category_widgets and self._settings_category_widgets[category]

	if not widgets or not self._options_templates then
		return
	end

	self._dmfimproved = mod

	local template_data = {}

	local current_group_tab = nil
	local fallback_tab = mod.default_tab

	for _, template in ipairs(self._options_templates.settings or {}) do
		if template.category == category then
			local display_name = template.display_name
			local setting_type = template.widget_type

			if setting_type == "group_header" then
				current_group_tab = template.tab
			end

			template_data[display_name] = current_group_tab or fallback_tab
		end
	end

	for _, data in ipairs(widgets) do
		local widget = data.widget

		if widget and widget.content then
			local content = widget.content
			local widget_text = content.text or content.display_name

			if widget_text then
				local tab = template_data[widget_text]

				content.tab = tab or fallback_tab
			end
		end
	end
end

-- ############################################################
-- Auto-generate tabs from group_header + indentation_level
-- ############################################################

mod.inject_generalised_tabs = function(self, category)
	if category_has_explicit_tabs(self, category) then
		mod.inject_tabs_into_widgets(self, category)
		return
	end

	local templates = self._options_templates and self._options_templates.settings
	if not templates then return end

	local widgets = self._settings_category_widgets and self._settings_category_widgets[category]
	if not widgets then return end

	local current_tab = mod.default_tab
	local ti = 1
	local widget_count = 0

	for _, data in ipairs(widgets) do
		local widget = data.widget
		if not (widget and widget.content) then goto continue end

		widget_count = widget_count + 1

		while ti <= #templates do
			local tpl = templates[ti]
			ti = ti + 1

			if tpl.category == category then
				if widget_count > 2 and tpl.widget_type == "group_header" then
					local next_indentation = nil
					for j = ti, math.min(ti + 4, #templates) do
						local next_tpl = templates[j]
						if next_tpl and next_tpl.category == category then
							local nt = next_tpl.widget_type
							if nt ~= "group_header" and nt ~= "spacer" and nt ~= "description" and nt ~= "title" and nt ~= "spacing_vertical" then
								next_indentation = next_tpl.indentation_level or 0
								break
							end
						end
					end

					if next_indentation == 1 then
						current_tab = tpl.display_name or current_tab
					end
				end

				break
			end
		end

		widget.content.tab = current_tab or mod.default_tab

		::continue::
	end
end

-- ############################################################
-- Get tabs
-- ############################################################

mod.get_tabs = function(self, category)
	local found = {}
	local tab_counts = {}
	local tabs = {}

	local fallback_tab = mod.default_tab

	if mod:get("enable_generalised_mod_tabs") and not category_has_explicit_tabs(self, category) then
		local current_tab = nil
		local entry_count = 0

		for i, setting in ipairs(self._options_templates.settings or {}) do
			if setting.category == category then
				entry_count = entry_count + 1
				if entry_count <= 2 then goto skip_entry end

				local setting_type = setting.widget_type

				if setting_type == "group_header" then
					local group_name = setting.display_name

					local next_indentation = nil
					for j = i + 1, math.min(i + 5, #self._options_templates.settings) do
						local next_tpl = self._options_templates.settings[j]
						if next_tpl.category == category then
							local nt = next_tpl.widget_type
							if nt ~= "group_header" and nt ~= "spacer" and nt ~= "description" and nt ~= "title" and nt ~= "spacing_vertical" then
								next_indentation = next_tpl.indentation_level or 0
								break
							end
						end
					end

					if next_indentation == 1 then
						current_tab = group_name

						if not found[current_tab] then
							found[current_tab] = true
							tabs[#tabs + 1] = current_tab
						end
					elseif next_indentation and next_indentation > 1 then
						-- subheader, keep current tab
					end
				else
					local tab = current_tab or fallback_tab
					local ignore = setting_type == "description" or setting_type == "title" or setting_type == "spacer"

					if not ignore then
						tab_counts[tab] = (tab_counts[tab] or 0) + 1
					end
				end

				::skip_entry::
			end
		end
	else
		local current_group_tab = nil

		for _, setting in ipairs(self._options_templates.settings or {}) do
			if setting.category == category then
				local setting_type = setting.widget_type

				if setting_type == "group_header" then
					current_group_tab = setting.tab
				else
					local tab = current_group_tab or fallback_tab

					local ignore = setting_type == "description" or setting_type == "title" or setting_type == "spacer"

					if not ignore then
						tab_counts[tab] = (tab_counts[tab] or 0) + 1

						if not found[tab] then
							found[tab] = true
							tabs[#tabs + 1] = tab
						end
					end
				end
			end
		end
	end

	local filtered_tabs = {}

	for _, tab in ipairs(tabs) do
		if tab ~= fallback_tab then
			filtered_tabs[#filtered_tabs + 1] = tab
		end
	end

	if (tab_counts[fallback_tab] or 0) > 0 then
		local already_present = false
		for _, t in ipairs(filtered_tabs) do
			if t == fallback_tab then
				already_present = true
				break
			end
		end

		if not already_present then
			table.insert(filtered_tabs, 1, fallback_tab)
		end
	end

	return filtered_tabs
end

-- ############################################################
-- Create widget helper
-- ############################################################

local _create_settings_widget_from_config = function(
	self,
	config,
	category,
	suffix,
	callback_name,
	changed_callback_name
)
	local scenegraph_id = "settings_grid_content_pivot"

	local template = _content_blueprints["mod_tab_button"]

	local size = template.size_function and template.size_function(self, config) or template.size

	local indentation_level = config.indentation_level or 0

	local indentation_spacing = view_settings.indentation_spacing * indentation_level

	local new_size = {
		size[1] - indentation_spacing,
		size[2],
	}

	local pass_template_function = template.pass_template_function

	local pass_template = pass_template_function and pass_template_function(self, config, new_size)
		or template.pass_template

	local widget_definition = pass_template and UIWidget.create_definition(pass_template, scenegraph_id, nil, new_size)

	local name = "widget_" .. suffix

	local widget = nil

	if widget_definition then
		widget = self:_create_widget(name, widget_definition)

		widget.type = "mod_tab_button"

		local init = template.init

		if init then
			init(self, widget, config, callback_name, changed_callback_name)
		end
	end

	if widget then
		return widget, {
			horizontal_alignment = "right",
			size = size,
			name = name,
		}
	else
		return nil, {
			size = size,
		}
	end
end

-- ############################################################
-- Create arrow button
-- ############################################################

local function create_arrow_button(self, category, text, callback)
	local entry = {
		widget_type = "settings_button",
		display_name = text,
		is_arrow = true,
	}

	local widget, alignment_widget =
		_create_settings_widget_from_config(self, entry, category, "arrow_" .. text, nil, nil)

	local width = 60
	local height = 60

	alignment_widget.size = { width, height }

	if widget then
		widget.content.size = { width, height }

		-- Override the font/style only for arrow buttons
		if entry.is_arrow then
			for _, pass in ipairs(widget.passes) do
				if pass.pass_type == "text" and pass.value_id == "text" then
					-- Change the style
					widget.style[pass.style_id] = table.clone(UIFontSettings.header_1)
					widget.style[pass.style_id].text_horizontal_alignment = "center"
				end
			end
		end

		local hotspot = widget.content.hotspot

		if hotspot then
			hotspot.pressed_callback = callback
		end
	end

	return widget, alignment_widget
end

-- ############################################################
-- Create tab bar
-- ############################################################

mod.create_tab_bar = function(self, category)
	local tabs = mod.get_tabs(self, category)

	if #tabs <= 1 then
		self._mod_tab_grid = nil
		self._mod_tab_widgets = nil
		return
	end

	local mod_storage_key = get_mod_storage_key(self, category)
	mod.selected_tabs[mod_storage_key] = mod.selected_tabs[mod_storage_key] or tabs[1]

	mod.tab_scroll_index[mod_storage_key] = mod.tab_scroll_index[mod_storage_key] or 1

	local widgets = {}
	local alignment_list = {}

	local total_tabs = #tabs

	local start_index = mod.tab_scroll_index[mod_storage_key]

	local end_index = math.min(start_index + mod.max_visible_tabs - 1, total_tabs)

	-- ############################################################
	-- LEFT ARROW
	-- ############################################################

	if total_tabs > mod.max_visible_tabs then
		local left_widget, left_alignment = create_arrow_button(self, category, "<", function()
			local current = mod.tab_scroll_index[mod_storage_key]

			mod.tab_scroll_index[mod_storage_key] = math.max(current - 1, 1)

			mod.create_tab_bar(self, category)
		end)

		local left_hotspot = left_widget.content.hotspot

		if start_index <= 1 then
			left_hotspot.disabled = true
			left_widget.visible = false
		end

		widgets[#widgets + 1] = left_widget
		alignment_list[#alignment_list + 1] = left_alignment
	end

	-- ############################################################
	-- TABS
	-- ############################################################

	for i = start_index, end_index do
		local tab_name = tabs[i]

		local entry = {
			widget_type = "settings_button",
			display_name = truncate_tab_title(tab_name),
		}

		local widget, alignment_widget =
			_create_settings_widget_from_config(self, entry, category, "mod_tab_" .. i, nil, nil)

		local width = 140
		local height = 60

		alignment_widget.size = { width, height }
		if widget then
			widget.content.size = { width, height }
			widget.content._tab_key = tab_name
			local hotspot = widget.content.hotspot

			if hotspot then
				hotspot.pressed_callback = function()
					mod.selected_tabs[mod_storage_key] = tab_name
					mod.filter_settings(self, category)
				end
			end
			widget.content.selected_tab_key = mod_storage_key
			widget.content.tab_name = tab_name
			widget.content.mod_reference = mod
		end

		widgets[#widgets + 1] = widget
		alignment_list[#alignment_list + 1] = alignment_widget
	end

	-- ############################################################
	-- RIGHT ARROW
	-- ############################################################

	if total_tabs > mod.max_visible_tabs then
		local right_widget, right_alignment = create_arrow_button(self, category, ">", function()
			local current = mod.tab_scroll_index[mod_storage_key]

			mod.tab_scroll_index[mod_storage_key] = math.min(current + 1, total_tabs - mod.max_visible_tabs + 1)

			mod.create_tab_bar(self, category)
		end)

		local right_hotspot = right_widget.content.hotspot

		if end_index >= total_tabs then
			right_hotspot.disabled = true
			right_widget.visible = false
		end

		if total_tabs <= mod.max_visible_tabs then
			right_widget.visible = false
		end

		widgets[#widgets + 1] = right_widget
		alignment_list[#alignment_list + 1] = right_alignment
	end

	-- ############################################################
	-- GRID
	-- ############################################################

	local grid = UIWidgetGrid:new(widgets, alignment_list, self._ui_scenegraph, "mod_tab_content", "right", { 16, 16 })

	grid:set_render_scale(self._render_scale)

	self._mod_tab_widgets = widgets
	self._mod_tab_grid = grid

end

-- ############################################################
-- Filter settings
-- ############################################################

mod.filter_settings = function(self, category)
	local mod_storage_key = get_mod_storage_key(self, category)

	local selected_tab = mod.selected_tabs[mod_storage_key] or mod.default_tab

	local category_widgets = self._settings_category_widgets and self._settings_category_widgets[category]

	if not category_widgets then
		return
	end

	local visible_widgets = {}
	local visible_alignment = {}

	local spacing = view_settings.settings_grid_spacing or { 15, 0 }

	-- add spacer if tabs are visible
	-- spacer above settings when tabs are visible
	if self._mod_tab_grid then
		local spacer_config = {
			widget_type = "spacing_vertical",
			size = 100,
		}

		local spacer_widget, spacer_alignment =
			self:_create_settings_widget_from_config(spacer_config, category, "tab_spacer", nil, nil)

		visible_widgets[#visible_widgets + 1] = spacer_widget
		visible_alignment[#visible_alignment + 1] = spacer_alignment
	end

	for index, data in ipairs(category_widgets) do
		local widget = data.widget
		local alignment_widget = data.alignment_widget

		if widget and alignment_widget then
			local content = widget.content or {}

			local widget_tab = content.tab

			local visible = (widget_tab == nil) or (widget_tab == selected_tab)

			if index == 1 or index == 2 then
				visible = true
			end

			widget.visible = visible
			alignment_widget.visible = visible

			if visible then
				visible_widgets[#visible_widgets + 1] = widget
				visible_alignment[#visible_alignment + 1] = alignment_widget
			end
		end
	end

	-- fallback: if no widgets match (except forced first two), show everything
	if #visible_widgets <= 2 then
		for index, data in ipairs(category_widgets) do
			local widget = data.widget
			local alignment_widget = data.alignment_widget

			if widget and alignment_widget then
				if not widget.visible then
					widget.visible = true
					alignment_widget.visible = true

					visible_widgets[#visible_widgets + 1] = widget
					visible_alignment[#visible_alignment + 1] = alignment_widget
				end
			end
		end
	end

	self._settings_content_widgets = visible_widgets
	self._settings_alignment_list = visible_alignment

	self._settings_content_grid = UIWidgetGrid:new(
		visible_widgets,
		visible_alignment,
		self._ui_scenegraph,
		"settings_grid_background",
		"down",
		spacing,
		nil,
		false
	)

	self._settings_content_grid:set_render_scale(self._render_scale)

	local scrollbar_widget = self._widgets_by_name.settings_scrollbar

	if scrollbar_widget then
		self._settings_content_grid:assign_scrollbar(
			scrollbar_widget,
			"settings_grid_content_pivot",
			"settings_grid_background",
			true
		)

		self._settings_content_grid:set_scrollbar_progress(0)
	end

	self._navigation_grids[2] = self._settings_content_grid

	self._navigation_widgets[2] = visible_widgets

	self._navigation_grid_index = 2
	self._navigation_widget_index = 1

	self:_update_grid_navigation_selection()
end

-- ############################################################
-- Draw tabs
-- ############################################################

mod:hook(CLASS.BaseView, "draw", function(func, self, dt, t, input_service, layer)
	func(self, dt, t, input_service, layer)

	if self.view_name ~= "dmf_options_view" then
		return
	end

	local grid = self._mod_tab_grid

	if not grid then
		return
	end

	local using_gamepad = not self:using_cursor_navigation()

	if using_gamepad then
		self:_draw_grid(grid, self._mod_tab_widgets, nil, dt, t, input_service)

		return
	end

	local interaction_widget = self._widgets_by_name.grid_interaction_widget
		or self._widgets_by_name.grid_interaction
		or self._widgets_by_name.settings_grid_interaction

	if not interaction_widget then
		return
	end

	local hotspot = interaction_widget.content.hotspot
	local mod_storage_key = get_mod_storage_key(self, mod.current_category)

	if hotspot then
		local old_hover = hotspot.is_hover

		hotspot.is_hover = true

		for _, widget in ipairs(self._mod_tab_widgets) do
			local w_hotspot = widget.content.hotspot

			if w_hotspot and w_hotspot.on_pressed then
				local tab_key = widget.content._tab_key or widget.content.text

				if tab_key == "<" or tab_key == ">" then
					w_hotspot.on_pressed = false
				else
					mod.selected_tabs[mod_storage_key] = tab_key

					mod.filter_settings(self, mod.current_category)

					w_hotspot.on_pressed = false
				end
			end
		end

		self:_draw_grid(grid, self._mod_tab_widgets, interaction_widget, dt, t, input_service)

		hotspot.is_hover = old_hover
	end
end)

-- ############################################################
-- Update
-- ############################################################

mod._addModTabs = function(self, dt, t, input_service)
	if mod.current_category ~= mod.last_category then
		if mod:get("enable_mod_tabs") then
			mod.create_tab_bar(self, mod.current_category)
		end

		if mod:get("enable_generalised_mod_tabs") then
			mod.inject_generalised_tabs(self, mod.current_category)
		else
			mod.inject_tabs_into_widgets(self, mod.current_category)
		end
		mod.filter_settings(self, mod.current_category)
	end

	if self._mod_tab_grid then
		self._mod_tab_grid:update(dt, t, input_service)
	end

	if mod:get("enable_mod_tabs") and input_service then
		local using_gamepad = not self:using_cursor_navigation()

		if using_gamepad then
			local navigate_left = input_service:get("navigate_left_continuous")
			local navigate_right = input_service:get("navigate_right_continuous")

			if navigate_left or navigate_right then
				local tabs = mod.get_tabs(self, mod.current_category)

				if #tabs > 1 then
					local mod_storage_key = get_mod_storage_key(self, mod.current_category)
					local current_tab = mod.selected_tabs[mod_storage_key] or mod.default_tab
					local current_idx = 1

					for i, tab in ipairs(tabs) do
						if tab == current_tab then
							current_idx = i
							break
						end
					end

					if navigate_right and current_idx < #tabs then
						current_idx = current_idx + 1
					elseif navigate_left and current_idx > 1 then
						current_idx = current_idx - 1
					end

					local new_tab = tabs[current_idx]

					if new_tab and new_tab ~= current_tab then
						mod.selected_tabs[mod_storage_key] = new_tab

						mod.filter_settings(self, mod.current_category)

						local start_index = mod.tab_scroll_index[mod_storage_key] or 1

						if current_idx < start_index then
							mod.tab_scroll_index[mod_storage_key] = current_idx
							mod.create_tab_bar(self, mod.current_category)
						elseif current_idx > start_index + mod.max_visible_tabs - 1 then
							mod.tab_scroll_index[mod_storage_key] = current_idx - mod.max_visible_tabs + 1
							mod.create_tab_bar(self, mod.current_category)
						end
					end
				end
			end
		end
	end
end
