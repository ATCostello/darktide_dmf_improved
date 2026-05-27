local mod = get_mod("Alfs_DMF_Extensions")

local UIWidgetGrid = require("scripts/ui/widget_logic/ui_widget_grid")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local view_settings = mod.dmf:io_dofile("dmf/scripts/mods/dmf/modules/ui/options/dmf_options_view_settings")

local _content_blueprints =
	mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/mod_tabs_blueprints")

mod.selected_tabs = mod.selected_tabs or {}
mod.tab_scroll_index = mod.tab_scroll_index or {}
mod._tab_inject_state = mod._tab_inject_state or {}

local function clean_tab_title(text)
	if not text then
		return text
	end

	text = text:gsub("{#[^}]*}", "")

	return text:gsub("%s*[-]+%s*$", "")
end

local function truncate_tab_title(text, max_words)
	if not text then
		return text
	end
	text = clean_tab_title(text)
	local limit = max_words or 4
	local words = {}
	for word in text:gmatch("%S+") do
		words[#words + 1] = word
	end
	if #words <= limit then
		return text
	end
	local result = ""
	for i = 1, limit do
		result = result .. words[i]
		if i < limit then
			result = result .. " "
		end
	end
	return result .. mod:localize("tab_title_truncated")
end

local function calculate_font_size(self, text, max_width, base_size)
	if not self or not text or #text == 0 then
		return base_size or 22
	end

	local min_size = 8
	local size = base_size or 22
	local usable_width = max_width - 16

	for _ = 1, 12 do
		local style = { font_type = "proxima_nova_bold", font_size = size }
		local text_width, _ = self:_text_size(text, style)
		if text_width and text_width <= usable_width then
			break
		end
		size = size - 1
		if size <= min_size then
			size = min_size
			break
		end
	end

	return size
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
	if not mod:get("enable_generalised_mod_tabs") then
		local is_genuine = mod._genuine_explicit_tab_mods and mod._genuine_explicit_tab_mods[category]
		return is_genuine or false
	end

	local templates = self._options_templates and self._options_templates.settings
	if templates then
		for _, template in ipairs(templates) do
			if template.category == category and template.tab then
				return true
			end
		end
	end

	local dmf_mod = mod.dmf or get_mod("DMF")

	if dmf_mod then
		for _, mod_widgets in ipairs(dmf_mod.options_widgets_data or {}) do
			local header = mod_widgets[1]
			local cat_name = (header and (header.readable_mod_name or header.mod_name)) or ""
			if cat_name == category then
				for _, w in ipairs(mod_widgets) do
					if w.tab then
						return true
					end
				end
				break
			end
		end
	end

	return false
end

local function could_have_tabs(self, category)
	local templates = self._options_templates and self._options_templates.settings
	if not templates then
		return false
	end

	local seen_tabs = {}
	local current_tab_name = nil
	local fallback_tab = mod.default_tab

	for i = 1, #templates do
		local tpl = templates[i]
		if tpl.category == category then
			if tpl.widget_type == "group_header" then
				if tpl.indentation_level and tpl.indentation_level == 0 then
					current_tab_name = tpl.display_name
				end
			elseif
				tpl.widget_type ~= "description"
				and tpl.widget_type ~= "title"
				and tpl.widget_type ~= "spacer"
				and tpl.widget_type ~= "spacing_vertical"
			then
				local tab = current_tab_name or fallback_tab
				seen_tabs[tab] = true
			end
		end
	end

	local count = 0
	for _ in pairs(seen_tabs) do
		count = count + 1
	end

	return count > 1
end

local TOOLTIP_WIDTH = 400

mod.max_visible_tabs = 5

local function resolve_widget_tab_from_dmf_data(category, setting_id, display_name)
	if category then
		if setting_id and mod.custom_tab_data then
			local compound = mod.compound_key(category, setting_id)
			if mod.custom_tab_data[compound] then
				return mod.custom_tab_data[compound]
			end
		end
		if display_name and mod.custom_tab_data then
			local compound = mod.compound_key(category, display_name)
			if mod.custom_tab_data[compound] then
				return mod.custom_tab_data[compound]
			end
		end
	end

	local dmf_mod = mod.dmf or get_mod("DMF")
	if not dmf_mod then
		return nil
	end

	for _, mod_widgets in ipairs(dmf_mod.options_widgets_data or {}) do
		local header = mod_widgets[1]
		local cat_name = (header and (header.readable_mod_name or header.mod_name)) or ""
		if cat_name == category then
			if display_name then
				for _, w in ipairs(mod_widgets) do
					if w.title == display_name and w.setting_id then
						local compound = mod.compound_key(cat_name, w.setting_id)
						local tab = mod.custom_tab_data and mod.custom_tab_data[compound]
						if tab then
							return tab
						end
					end
				end
			end

			for _, w in ipairs(mod_widgets) do
				if
					(w.setting_id and w.setting_id == setting_id)
					or (w.title and display_name and w.title == display_name)
				then
					if w.tab then
						return w.tab
					end
				end
			end
			break
		end
	end

	return nil
end

mod.inject_tabs_into_widgets = function(self, category)
	local widgets = self._settings_category_widgets and self._settings_category_widgets[category]

	if not widgets or not self._options_templates then
		return
	end

	local gen_tabs_enabled = mod:get("enable_generalised_mod_tabs")
	local current_group_tab = nil
	local fallback_tab = mod.default_tab
	local templates = self._options_templates.settings or {}

	local cat_templates = {}
	for _, tpl in ipairs(templates) do
		if tpl.category == category then
			cat_templates[#cat_templates + 1] = tpl
		end
	end

	for i, data in ipairs(widgets) do
		local widget = data.widget

		if not (widget and widget.content) then
			goto continue
		end

		local tpl = cat_templates[i]

		if tpl then
			widget.content.indentation_level = tpl.indentation_level

			if tpl.widget_type == "group_header" then
				if tpl.tab then
					if gen_tabs_enabled or not tpl._auto_tab then
						current_group_tab = tpl.tab
					end
				elseif tpl.indentation_level and tpl.indentation_level == 0 then
					current_group_tab = nil
				end
			end
		end

		widget.content.tab = current_group_tab or fallback_tab

		::continue::
	end
end

local function get_tab_inject_state(self, category)
	local gen_tabs_on = mod:get("enable_generalised_mod_tabs")
	local per_mod_on = mod.is_gen_tabs_enabled_for_mod(category)
	return string.format("%s_%s_%s", tostring(category), tostring(gen_tabs_on), tostring(per_mod_on))
end

mod.inject_generalised_tabs = function(self, category)
	local widgets = self._settings_category_widgets and self._settings_category_widgets[category]

	if not widgets then
		return
	end

	local state_key = "gen_" .. tostring(category)

	if not mod.is_gen_tabs_enabled_for_mod(category) then
		local new_state = get_tab_inject_state(self, category)
		if mod._tab_inject_state[state_key] == new_state then
			return
		end
		mod._tab_inject_state[state_key] = new_state
		for _, data in ipairs(widgets) do
			if data.widget and data.widget.content then
				data.widget.content.tab = nil
			end
		end
		return
	end

	if category_has_explicit_tabs(self, category) then
		local explicit_state_key = "explicit_" .. tostring(mod:get("enable_generalised_mod_tabs"))
		if mod._tab_inject_state[state_key] == explicit_state_key then
			return
		end
		mod._tab_inject_state[state_key] = explicit_state_key
		mod.inject_tabs_into_widgets(self, category)
		return
	end

	if not mod:get("enable_generalised_mod_tabs") then
		local new_state = get_tab_inject_state(self, category)
		if mod._tab_inject_state[state_key] == new_state then
			return
		end
		mod._tab_inject_state[state_key] = new_state
		for _, data in ipairs(widgets) do
			if data.widget and data.widget.content then
				data.widget.content.tab = nil
			end
		end
		return
	end

	local templates = self._options_templates and self._options_templates.settings
	if not templates then
		return
	end

	local new_state = get_tab_inject_state(self, category)
	if mod._tab_inject_state[state_key] == new_state then
		return
	end
	mod._tab_inject_state[state_key] = new_state

	local current_tab = mod.default_tab
	local ti = 1

	for _, data in ipairs(widgets) do
		local widget = data.widget
		if not (widget and widget.content) then
			goto continue
		end

		while ti <= #templates do
			local tpl = templates[ti]
			ti = ti + 1

			if tpl.category == category then
				if tpl.widget_type == "group_header" and tpl.indentation_level and tpl.indentation_level == 0 then
					current_tab = tpl.display_name or current_tab
				end

				break
			end
		end

		widget.content.tab = current_tab or mod.default_tab

		::continue::
	end
end

mod.get_tabs = function(self, category)
	local found = {}
	local tab_counts = {}
	local tabs = {}

	local fallback_tab = mod.default_tab

	local gen_tabs_enabled = mod:get("enable_generalised_mod_tabs")
	local has_explicit = category_has_explicit_tabs(self, category)
	local per_mod_enabled = mod.is_gen_tabs_enabled_for_mod(category)

	if per_mod_enabled and gen_tabs_enabled and not has_explicit then
		local current_tab = nil

		for _, setting in ipairs(self._options_templates.settings or {}) do
			if setting.category == category then
				local setting_type = setting.widget_type

				if setting_type == "group_header" then
					if setting.indentation_level and setting.indentation_level == 0 then
						current_tab = setting.display_name
					end
				elseif setting_type ~= "group_header" then
					local tab = current_tab or fallback_tab

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
	elseif per_mod_enabled and has_explicit then
		local current_group_tab = nil

		for _, setting in ipairs(self._options_templates.settings or {}) do
			if setting.category == category then
				local setting_type = setting.widget_type

				if setting_type == "group_header" then
					if gen_tabs_enabled or not setting._auto_tab then
						local resolved = setting.tab
							or resolve_widget_tab_from_dmf_data(category, setting.setting_id, setting.display_name)

						if resolved then
							current_group_tab = resolved
						elseif setting.indentation_level and setting.indentation_level == 0 then
							current_group_tab = nil
						end
					end
				elseif setting_type ~= "group_header" then
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
			table.insert(filtered_tabs, #filtered_tabs + 1, fallback_tab)
		end
	end

	return filtered_tabs
end

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

		if entry.is_arrow then
			for _, pass in ipairs(widget.passes) do
				if pass.pass_type == "text" and pass.value_id == "text" then
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

	local max_visible_tabs = tonumber(mod.max_visible_tabs) or 5
	local start_index = tonumber(mod.tab_scroll_index[mod_storage_key]) or 1

	local end_index = math.min(start_index + max_visible_tabs - 1, total_tabs)

	if total_tabs > max_visible_tabs then
		local left_widget, left_alignment = create_arrow_button(
			self,
			category,
			mod:localize("tab_arrow_left"),
			function()
				local current = tonumber(mod.tab_scroll_index[mod_storage_key]) or 1

				mod.tab_scroll_index[mod_storage_key] = math.max(current - 1, 1)

				mod.create_tab_bar(self, category)
			end
		)

		local left_hotspot = left_widget.content.hotspot

		if start_index <= 1 then
			left_hotspot.disabled = true
			left_widget.visible = false
		end

		widgets[#widgets + 1] = left_widget
		alignment_list[#alignment_list + 1] = left_alignment
	end

	for i = start_index, end_index do
		local tab_name = tabs[i]

		local overrides =
			table.clone(mod.tab_overrides_lookup and mod.tab_overrides_lookup[category .. "|" .. tab_name] or {})

		local display_name = truncate_tab_title(tab_name, overrides.truncate_num)
		local font_size = calculate_font_size(self, display_name, 140, overrides.font_size or 22)
		overrides.font_size = font_size

		local entry = {
			widget_type = "settings_button",
			display_name = display_name,
			tab_overrides = overrides,
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

	if total_tabs > max_visible_tabs then
		local right_widget, right_alignment = create_arrow_button(
			self,
			category,
			mod:localize("tab_arrow_right"),
			function()
				local current = mod.tab_scroll_index[mod_storage_key]
				local current_num = tonumber(current) or 1

				mod.tab_scroll_index[mod_storage_key] = math.min(current_num + 1, total_tabs - max_visible_tabs + 1)

				mod.create_tab_bar(self, category)
			end
		)

		local right_hotspot = right_widget.content.hotspot

		if end_index >= total_tabs then
			right_hotspot.disabled = true
			right_widget.visible = false
		end

		if total_tabs <= max_visible_tabs then
			right_widget.visible = false
		end

		widgets[#widgets + 1] = right_widget
		alignment_list[#alignment_list + 1] = right_alignment
	end

	local grid = UIWidgetGrid:new(widgets, alignment_list, self._ui_scenegraph, "mod_tab_content", "right", { 16, 16 })

	grid:set_render_scale(self._render_scale)

	self._mod_tab_widgets = widgets
	self._mod_tab_grid = grid
end

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

	local has_toggle = category
		and mod:get("enable_generalised_mod_tabs")
		and not (mod._genuine_explicit_tab_mods and mod._genuine_explicit_tab_mods[category])
		and could_have_tabs(self, category)

	if self._mod_tab_grid then
		if has_toggle then
			mod.inject_gen_tabs_toggle_into_content(self, category, visible_widgets, visible_alignment)
		else
			local spacer_config = { widget_type = "spacing_vertical", size = 110 }
			local spacer_widget, spacer_alignment =
				self:_create_settings_widget_from_config(spacer_config, category, "tab_spacer", nil, nil)
			visible_widgets[#visible_widgets + 1] = spacer_widget
			visible_alignment[#visible_alignment + 1] = spacer_alignment
		end
	elseif has_toggle then
		mod.inject_gen_tabs_toggle_into_content(self, category, visible_widgets, visible_alignment)
	end

	for index, data in ipairs(category_widgets) do
		local widget = data.widget
		local alignment_widget = data.alignment_widget

		if widget and alignment_widget then
			local content = widget.content or {}

			local visible

			if not self._mod_tab_grid then
				visible = true
			else
				local widget_tab = content.tab
				visible = (widget_tab == nil) or (widget_tab == selected_tab)

				-- Force show mod_title and description!
				if index == 1 or index == 2 then
					if widget.type == "description" or widget.type == "group_header" then
						visible = true
					end
				end
				if has_toggle and (index == 2 or index == 3) then
					if widget.type == "description" then
						visible = true
					end
				end
			end

			widget.visible = visible
			alignment_widget.visible = visible

			if visible then
				visible_widgets[#visible_widgets + 1] = widget
				visible_alignment[#visible_alignment + 1] = alignment_widget
			end
		end
	end

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

mod:hook(CLASS.BaseView, "draw", function(func, self, dt, t, input_service, layer)
	if self.view_name == "dmf_options_view" then
		local grid = self._mod_tab_grid

		if grid then
			local using_gamepad = not self:using_cursor_navigation()

			if not using_gamepad then
				local interaction_widget = self._widgets_by_name.grid_interaction_widget
					or self._widgets_by_name.grid_interaction
					or self._widgets_by_name.settings_grid_interaction

				if interaction_widget then
					local hotspot = interaction_widget.content.hotspot
					local mod_storage_key = get_mod_storage_key(self, mod.current_category)

					if hotspot then
						local old_hover = hotspot.is_hover

						hotspot.is_hover = true

						for _, widget in ipairs(self._mod_tab_widgets) do
							local w_hotspot = widget.content.hotspot

							if w_hotspot and w_hotspot.on_pressed then
								local tab_key = widget.content._tab_key or widget.content.text

								if
									tab_key == mod:localize("tab_arrow_left")
									or tab_key == mod:localize("tab_arrow_right")
								then
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
				end
			else
				self:_draw_grid(grid, self._mod_tab_widgets, nil, dt, t, input_service)
			end
		end
	end

	local tooltip = self._widgets_by_name and self._widgets_by_name.tooltip
	if tooltip then
		local found = false

		for _, w in ipairs(self._mod_tab_widgets or {}) do
			local wh = w.content.hotspot
			local overrides = w.content.tab_overrides or {}
			if wh and wh.is_hover and overrides.tooltip then
				tooltip.content.visible = true
				tooltip.content.text = overrides.tooltip

				local text_style = tooltip.style.text
				local pivot_pos = self:_scenegraph_world_position("mod_tab_content")
				local tooltip_width = TOOLTIP_WIDTH
				local _, text_height = self:_text_size(overrides.tooltip, text_style, { tooltip_width, 0 })
				local height = text_height

				tooltip.content.size = { tooltip_width, height }

				local left_edge_x = pivot_pos and pivot_pos[1] + (w.offset and w.offset[1] or 0) or 0
				tooltip.offset[1] = left_edge_x - tooltip_width - 10
				tooltip.offset[2] = (pivot_pos and pivot_pos[2] or 0)
					+ (w.offset and w.offset[2] or 0)
					+ (w.content.size and w.content.size[2] or 48)
					+ 10

				self._tooltip_data = {
					widget = w,
					text = overrides.tooltip,
				}

				found = true
				break
			end
		end

		if not found then
			local toggle_widget, _ = mod.get_gen_tabs_toggle(mod.current_category)
			if toggle_widget then
				local th = toggle_widget.content.hotspot
				if th and th.is_hover then
					local tooltip_text = toggle_widget.content._toggle_tooltip_text
					if tooltip_text then
						tooltip.content.visible = true
						tooltip.content.text = tooltip_text

						local text_style = tooltip.style.text
						local pivot_pos = self:_scenegraph_world_position("settings_grid_content_pivot")
						local tooltip_width = TOOLTIP_WIDTH
						local _, text_height = self:_text_size(tooltip_text, text_style, { tooltip_width, 0 })
						local height = text_height

						tooltip.content.size = { tooltip_width, height }

						local left_edge_x = pivot_pos
								and pivot_pos[1] + (toggle_widget.offset and toggle_widget.offset[1] or 0)
							or 0
						local scroll_addition = self._settings_content_grid
								and self._settings_content_grid:length_scrolled()
							or 0
						tooltip.offset[1] = left_edge_x - tooltip_width - 10
						tooltip.offset[2] = (pivot_pos and pivot_pos[2] or 0)
							+ (toggle_widget.offset and toggle_widget.offset[2] or 0)
							- scroll_addition
							+ (toggle_widget.content.size and toggle_widget.content.size[2] or 22)
							+ 10

						self._tooltip_data = {
							widget = toggle_widget,
							text = tooltip_text,
						}

						found = true
					end
				end
			end
		end
	end

	func(self, dt, t, input_service, layer)
end)

mod._addModTabs = function(self, dt, t, input_service)
	local category = mod.current_category
	local mod_tabs_enabled = mod:get("enable_mod_tabs")

	if mod._prev_mod_tabs_enabled == nil then
		mod._prev_mod_tabs_enabled = mod_tabs_enabled
	end

	if category then
		if category ~= mod.last_category or mod_tabs_enabled ~= mod._prev_mod_tabs_enabled then
			mod.last_category = category

			if mod_tabs_enabled then
				mod.create_tab_bar(self, category)
				mod.inject_generalised_tabs(self, category)
			end

			mod.filter_settings(self, category)
		else
			if mod_tabs_enabled then
				local state_key = "gen_" .. tostring(category)
				local old_inject_state = mod._tab_inject_state[state_key]

				mod.inject_generalised_tabs(self, category)

				local new_inject_state = mod._tab_inject_state[state_key]
				local should_refresh = old_inject_state ~= new_inject_state

				if should_refresh then
					mod.create_tab_bar(self, category)
				end

				if should_refresh or self._settings_content_grid ~= mod._grid_ref then
					mod.filter_settings(self, category)
				end
			else
				if self._mod_tab_grid then
					self._mod_tab_grid = nil
					self._mod_tab_widgets = nil
				end

				mod.filter_settings(self, category)
			end
		end

		mod._prev_mod_tabs_enabled = mod_tabs_enabled
		mod._grid_ref = self._settings_content_grid
	end

	if self._mod_tab_grid then
		self._mod_tab_grid:update(dt, t, input_service)
	end

	if mod:get("enable_mod_tabs") and input_service then
		local ok, err = pcall(function()
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

							local start_index = tonumber(mod.tab_scroll_index[mod_storage_key]) or 1
							local max_visible_tabs = tonumber(mod.max_visible_tabs) or 5

							if current_idx < start_index then
								mod.tab_scroll_index[mod_storage_key] = current_idx
								mod.create_tab_bar(self, mod.current_category)
							elseif current_idx > start_index + max_visible_tabs - 1 then
								mod.tab_scroll_index[mod_storage_key] = current_idx - max_visible_tabs + 1
								mod.create_tab_bar(self, mod.current_category)
							end
						end
					end
				end
			end
		end)

		if not ok then
			mod:debug("mod_tabs input error: %s", tostring(err))
		end
	end
end
