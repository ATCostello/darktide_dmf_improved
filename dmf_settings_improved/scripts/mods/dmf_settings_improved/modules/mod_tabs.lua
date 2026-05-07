local mod = get_mod("dmf_settings_improved")

local UIWidgetGrid = require("scripts/ui/widget_logic/ui_widget_grid")
local UIWidget = require("scripts/managers/ui/ui_widget")

local view_settings = mod.dmf:io_dofile("dmf/scripts/mods/dmf/modules/ui/options/dmf_options_view_settings")
local _content_blueprints =
	mod:io_dofile("dmf_settings_improved/scripts/mods/dmf_settings_improved/modules/mod_tabs_blueprints")

mod.selected_tabs = mod.selected_tabs or {}

mod.inject_tabs_into_widgets = function(self, category)
	local widgets = self._settings_category_widgets and self._settings_category_widgets[category]

	if not widgets or not self._options_templates then
		return
	end

	-- ############################################################
	-- Build ordered template map
	-- ############################################################

	local template_data = {}

	local current_group_tab = nil
	local fallback_tab = mod.default_tab

	for _, template in ipairs(self._options_templates.settings or {}) do
		if template.category == category then
			local display_name = template.display_name
			local setting_type = template.widget_type

			-- ############################################################
			-- Group header logic
			-- ############################################################
			if setting_type == "group_header" then
				-- group header owns the tab for following entries
				current_group_tab = template.tab
			end

			template_data[display_name] = current_group_tab or fallback_tab
		end
	end

	-- ############################################################
	-- Inject tabs into runtime widgets
	-- ############################################################

	for _, data in ipairs(widgets) do
		local widget = data.widget

		if widget and widget.content then
			local content = widget.content

			local widget_text = content.text or content.display_name

			local tab = template_data[widget_text]

			if tab then
				content.tab = tab

				-- optional debug
				--mod:echo(string.format("Injected tab '%s' into '%s'", tostring(tab), tostring(widget_text)))
			else
				-- absolute safety fallback
				content.tab = fallback_tab
			end
		end
	end
end

-- ############################################################
-- Get tabs
-- ############################################################

mod.get_tabs = function(self, category)
	local found = {}

	for _, setting in ipairs(self._options_templates.settings) do
		if setting.category == category and setting.tab then
			found[setting.tab] = true
		end
	end

	local tabs = {
		mod.default_tab,
	}

	for tab_name, _ in pairs(found) do
		tabs[#tabs + 1] = tab_name
	end

	--table.sort(tabs)

	return tabs
end

-- ############################################################
-- Create tab bar
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
	local widget = nil
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

mod.create_tab_bar = function(self, category)
	local tabs = mod.get_tabs(self, category)

	if #tabs <= 1 then
		self._mod_tab_grid = nil
		self._mod_tab_widgets = nil
		return
	end

	mod.selected_tabs[category] = mod.selected_tabs[category] or tabs[1]

	local widgets = {}
	local alignment_list = {}

	for i, tab_name in ipairs(tabs) do
		local entry = {
			widget_type = "settings_button",
			display_name = tab_name,
		}

		local widget, alignment_widget =
			_create_settings_widget_from_config(self, entry, category, "mod_tab_" .. i, nil, nil)

		local width = 140
		local height = 60

		alignment_widget.size = { width, height }

		if widget then
			widget.content.size = { width, height }

			-- override default DMF callback system
			local hotspot = widget.content.hotspot

			if hotspot then
				hotspot.pressed_callback = function()
					mod.selected_tabs[category] = tab_name
					mod.filter_settings(self, category)
				end
			end
		end

		widgets[#widgets + 1] = widget
		alignment_list[#alignment_list + 1] = alignment_widget
	end

	local grid = UIWidgetGrid:new(widgets, alignment_list, self._ui_scenegraph, "mod_tab_content", "right", { 16, 16 })

	grid:set_render_scale(self._render_scale)

	self._mod_tab_widgets = widgets
	self._mod_tab_grid = grid

	local scrollbar_widget = self._widgets_by_name.settings_scrollbar

	if scrollbar_widget then
		grid:assign_scrollbar(scrollbar_widget, "mod_tab_content", "mod_tab_area", true)
	end
end

-- ############################################################
-- Filter settings (visibility only)
-- ############################################################

mod.filter_settings = function(self, category)
	local selected_tab = mod.selected_tabs[category]

	if not selected_tab then
		return
	end

	local category_widgets = self._settings_category_widgets and self._settings_category_widgets[category]

	if not category_widgets then
		return
	end

	-- ############################################################
	-- Rebuild vertical layout manually
	-- ############################################################

	local spacing = view_settings.settings_grid_spacing or { 10, 0 }
	local current_y = 24

	for _, data in ipairs(category_widgets) do
		local widget = data.widget
		local alignment_widget = data.alignment_widget

		if widget and alignment_widget then
			local content = widget.content or {}

			local widget_tab = content.tab

			local visible = (widget_tab == nil) or (widget_tab == selected_tab)

			-- force title and description to be visible always
			if _ == 1 or _ == 2 then
				visible = true
			end

			-- ############################################################
			-- Reflow visible widgets
			-- ############################################################
			if visible then
				widget.offset[2] = current_y
				current_y = current_y + (alignment_widget.size[2] + spacing[2])
			end

			-- ############################################################
			-- Visibility
			-- ############################################################
			widget.visible = visible
			alignment_widget.visible = visible
		end
	end

	-- ############################################################
	-- Refresh grid/nav
	-- ############################################################

	if self._settings_grid then
		self._settings_grid:force_update_list_size()
	end

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

	local interaction_widget = self._widgets_by_name.grid_interaction_widget
		or self._widgets_by_name.grid_interaction
		or self._widgets_by_name.settings_grid_interaction

	if not interaction_widget then
		return
	end

	local hotspot = interaction_widget.content.hotspot

	if hotspot then
		-- Save original state
		local old_hover = hotspot.is_hover

		-- Force hover so SortModMenu processes clicks
		hotspot.is_hover = true

		for _, widget in ipairs(self._mod_tab_widgets) do
			local hotspot = widget.content.hotspot

			if hotspot and hotspot.on_pressed then
				local tab_name = widget.content.text

				mod.selected_tabs[mod.current_category] = tab_name
				mod.filter_settings(self, mod.current_category)

				hotspot.on_pressed = false
			end
		end

		self:_draw_grid(grid, self._mod_tab_widgets, interaction_widget, dt, t, input_service)

		-- Restore original state
		hotspot.is_hover = old_hover
	end
end)

-- ############################################################
-- Update
-- ############################################################

mod._addModTabs = function(self, dt, t, input_service)
	if mod.current_category ~= mod.last_category then
		mod.last_category = mod.current_category

		mod.inject_tabs_into_widgets(self, mod.current_category)
		mod.create_tab_bar(self, mod.current_category)
		mod.filter_settings(self, mod.current_category)
	end

	if self._mod_tab_grid then
		self._mod_tab_grid:update(dt, t, input_service)
	end
end
