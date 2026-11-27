local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIResolution = require("scripts/managers/ui/ui_resolution")
local ViewElementGrid = require("scripts/ui/view_elements/view_element_grid/view_element_grid")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")

local Definitions = mod._preset_panel_definitions
local Blueprints = mod._preset_panel_blueprints
local Dropdown = mod._preset_panel_dropdown
local Styles = mod._preset_panel_styles

local widget_draw_order = Definitions.widget_draw_order or {}
local widget_draw_order_count = #widget_draw_order
local bottom_buttons = Definitions.bottom_buttons or {}
local bottom_button_count = #bottom_buttons
local tabs = Definitions.tabs or {}
local tab_count = #tabs
local tab_width = Definitions.TAB_WIDTH or 0
local tab_divider_width = Definitions.TAB_DIVIDER_WIDTH or 0
local full_actions_width = Definitions.FULL_ACTIONS_PIVOT_WIDTH or 1084
local actions_pivot_margin = Definitions.ACTIONS_PIVOT_MARGIN or 16
local actions_list_height = 499
local default_actions_y = Definitions.scenegraph_definition
		and Definitions.scenegraph_definition.actions_pivot
		and Definitions.scenegraph_definition.actions_pivot.position
		and Definitions.scenegraph_definition.actions_pivot.position[2]
	or 166
local characters_actions_y = Definitions.CHARACTERS_ACTIONS_PIVOT_Y or 104
local characters_actions_height = Definitions.CHARACTERS_ACTIONS_HEIGHT
	or (actions_list_height + default_actions_y - characters_actions_y)
local actions_frame_top_padding = 16
local detail_upper_height = Definitions.DETAIL_UPPER_HEIGHT or 286
local detail_dropdown_y = Definitions.DETAIL_DROPDOWN_Y or 414
local detail_dropdown_x = Definitions.DETAIL_DROPDOWN_X or 48
local default_dropdown_x = Definitions.DEFAULT_DROPDOWN_X or 40
local default_dropdown_y = Definitions.DEFAULT_DROPDOWN_Y or 96
local default_scope_label_y = Definitions.DEFAULT_SCOPE_LABEL_Y or 126
local detail_scope_label_y = Definitions.DETAIL_SCOPE_LABEL_Y or (detail_dropdown_y + 32)
local default_actions_width = Definitions.actions_grid_settings
		and Definitions.actions_grid_settings.grid_size
		and Definitions.actions_grid_settings.grid_size[1]
	or 644
local default_list_frame_width = Definitions.scenegraph_definition
		and Definitions.scenegraph_definition.list_frame
		and Definitions.scenegraph_definition.list_frame.size
		and Definitions.scenegraph_definition.list_frame.size[1]
	or 420
local default_list_grid_width = Definitions.list_grid_settings
		and Definitions.list_grid_settings.grid_size
		and Definitions.list_grid_settings.grid_size[1]
	or 404
local list_width_margin = math.max(0, default_list_frame_width - default_list_grid_width)
local preset_entry_default_width = Blueprints.preset_entry
		and Blueprints.preset_entry.size
		and Blueprints.preset_entry.size[1]
	or 400
local preset_button_margin = math.max(0, default_list_grid_width - preset_entry_default_width)
local option_hotspot_keys = {}
local option_hotspot_key_count = 0

for index = 1, (Definitions.SCOPE_MAX_VISIBLE_OPTIONS or 0) do
	option_hotspot_keys[index] = "option_hotspot_" .. index
	option_hotspot_key_count = index
end

local function panel_scope_key(scope)
	if not scope or scope.kind == "global" or scope.mod_name == nil then
		return "global"
	end

	return "mod:" .. tostring(scope.mod_name)
end

local function tooltip_text_for_widget(widget)
	local content = widget and widget.content

	if not content or not content.tooltip_text or content.tooltip_text == "" then
		return nil
	end

	local hotspot = content.hotspot

	if not hotspot or not (hotspot.is_hover or hotspot.is_focused) then
		return nil
	end

	return content.tooltip_text
end

local function hovered_grid_widget(grid)
	local ui_grid = grid and grid._grid
	local index = ui_grid and type(ui_grid.hovered_grid_index) == "function" and ui_grid:hovered_grid_index()

	return index and grid._grid_widgets and grid._grid_widgets[index] or nil
end

local PresetTooltipElement = class("PresetTooltipElementPanel", "ViewElementBase")

PresetTooltipElement.init = function(self, parent, draw_layer, start_scale)
	PresetTooltipElement.super.init(self, parent, draw_layer, start_scale, Definitions.tooltip_definitions)

	local tooltip = self._widgets_by_name and self._widgets_by_name.tooltip

	if tooltip then
		tooltip.content.visible = false
		tooltip.content.tooltip_text = ""
		tooltip.offset[1] = 0
		tooltip.offset[2] = 0
	end
end

PresetTooltipElement.set_tooltip = function(self, text, x, y, visible)
	local tooltip = self._widgets_by_name and self._widgets_by_name.tooltip

	if not tooltip then
		return
	end

	tooltip.content.visible = visible == true
	tooltip.content.tooltip_text = visible and text or ""
	tooltip.offset[1] = x or 0
	tooltip.offset[2] = y or 0
end

PresetEditorPanelView = class("PresetEditorPanelView", "BaseView")

PresetEditorPanelView.ui_renderer = function(self)
	return self._ui_renderer
end

PresetEditorPanelView._draw_widgets = function(self, dt, t, input_service, ui_renderer, render_settings)
	local widgets_by_name = self._widgets_by_name
	local drawn_widgets = self._drawn_widgets
	local scope_widget = widgets_by_name and widgets_by_name.scope_dropdown

	table.clear(drawn_widgets)

	for index = 1, widget_draw_order_count do
		local widget = widgets_by_name and widgets_by_name[widget_draw_order[index]]

		if widget and widget ~= scope_widget then
			UIWidget.draw(widget, ui_renderer)
			drawn_widgets[widget] = true
		end
	end

	local widgets = self._widgets

	if widgets then
		for index = 1, #widgets do
			local widget = widgets[index]

			if widget and widget ~= scope_widget and not drawn_widgets[widget] then
				UIWidget.draw(widget, ui_renderer)
			end
		end
	end
end

PresetEditorPanelView._draw_background_dim = function(self, dt, t, input_service, layer)
	local ui_renderer = self._ui_renderer
	local render_settings = self._render_settings

	if not ui_renderer or not render_settings then
		return
	end

	local previous_start_layer = render_settings.start_layer
	local previous_scale = render_settings.scale
	local previous_inverse_scale = render_settings.inverse_scale
	local render_scale = self._render_scale
	local screen_size = self._ui_scenegraph.screen and self._ui_scenegraph.screen.size or nil
	local screen_width = screen_size and screen_size[1] or 1920
	local screen_height = screen_size and screen_size[2] or 1080

	render_settings.start_layer = math.max(1, (layer or 1) - 10)
	render_settings.scale = render_scale
	render_settings.inverse_scale = render_scale and 1 / render_scale or nil

	UIRenderer.begin_pass(ui_renderer, self._ui_scenegraph, input_service, dt, render_settings)
	UIRenderer.draw_rect(ui_renderer, Vector3(0, 0, 0), Vector3(screen_width, screen_height, 0), Color(90, 0, 0, 0))
	UIRenderer.end_pass(ui_renderer)

	render_settings.start_layer = previous_start_layer
	render_settings.scale = previous_scale
	render_settings.inverse_scale = previous_inverse_scale
end

PresetEditorPanelView.draw = function(self, dt, t, input_service, layer)
	self:_draw_background_dim(dt, t, input_service, layer)

	PresetEditorPanelView.super.draw(self, dt, t, input_service, layer)

	local widget = self._widgets_by_name and self._widgets_by_name.scope_dropdown
	local ui_renderer = self._ui_renderer
	local render_settings = self._render_settings

	if not widget or not ui_renderer or not render_settings then
		return
	end

	local previous_layer = render_settings.start_layer or 0

	render_settings.start_layer = previous_layer + 210
	UIRenderer.begin_pass(ui_renderer, self._ui_scenegraph, input_service, dt, render_settings)
	UIWidget.draw(widget, ui_renderer)
	UIRenderer.end_pass(ui_renderer)
	render_settings.start_layer = previous_layer
end

PresetEditorPanelView._null_input_service = function(self, input_service)
	if Dropdown.is_open(self) and input_service and type(input_service.null_service) == "function" then
		return input_service:null_service()
	end

	return input_service
end

PresetEditorPanelView._draw_elements = function(self, dt, t, ui_renderer, render_settings, input_service)
	local elements_array = self._elements_array
	local grid_input_service = self:_null_input_service(input_service)

	if elements_array then
		for index = 1, #elements_array do
			local element = elements_array[index]

			if element then
				local element_input_service = input_service

				if
					element == self._list_grid
					or element == self._actions_grid
					or element == self._available_grid
				then
					element_input_service = grid_input_service
				end

				element:draw(dt, t, ui_renderer, render_settings, element_input_service)
			end
		end
	end
end

PresetEditorPanelView._update_elements = function(self, dt, t, input_service)
	local elements_array = self._elements_array
	local grid_input_service = self:_null_input_service(input_service)

	if elements_array then
		for index = 1, #elements_array do
			local element = elements_array[index]

			if element then
				local element_input_service = input_service

				if
					element == self._list_grid
					or element == self._actions_grid
					or element == self._available_grid
				then
					element_input_service = grid_input_service

					local hidden = false

					if element == self._list_grid then
						hidden = self._list_pane_visible == false
					elseif element == self._available_grid then
						hidden = self._available_grid_visible == false
					end

					if hidden and input_service and type(input_service.null_service) == "function" then
						element_input_service = input_service:null_service()
					end
				end

				element:update(dt, t, element_input_service)
			end
		end
	end
end

PresetEditorPanelView.init = function(self, settings, context)
	PresetEditorPanelView.super.init(self, Definitions, settings, context)

	self._pass_draw = true
	self._pass_input = false
	self._allow_close_hotkey = true
	self._scope = type(context) == "table" and (context.kind == "global" or context.mod_name ~= nil) and context or nil
	self._selected_name = nil
	self._rebuilt_scope_key = nil
	self._character_mode = false
	self._characters_view_mode = false
	self._character_detail_mode = false
	self._selected_character_id = nil
	self._selected_character = nil
	self._selected_character_name = nil
	self._character_assignment_cache = nil
	self._characters_scope = self._scope or mod._preset_panel_get_scope()
	self._dropdown_x = default_dropdown_x
	self._dropdown_y = default_dropdown_y
	self._scope_label_x = default_dropdown_x
	self._scope_label_y = default_scope_label_y
	self._actions_height = actions_list_height
	self._actions_height_target = actions_list_height
	self._actions_y = default_actions_y
	self._actions_y_target = default_actions_y
	self._applied_actions_height = actions_list_height
	self._applied_actions_y = default_actions_y
	self._dropdown_widgets_visible = nil
	self._available_grid_visible = nil
	self._character_request_id = 0
	self._drawn_widgets = {}
	self._pending_actions_rebuild = false
	self._pending_full_rebuild = false
	self._pending_character_detail_rebuild = false
	self._pending_scope = nil
	self._open_anim_id = nil
	self._close_anim_id = nil
	self._has_presets = false
	self._actions_width = default_actions_width
	self._actions_width_target = default_actions_width
	self._applied_actions_width = default_actions_width
	self._applied_list_width = default_list_frame_width
	self._list_button_width = preset_entry_default_width
	self._list_pane_visible = true
	self._divider_x = nil
	self._save_button_widget = self._widgets_by_name and self._widgets_by_name.bottom_save or nil

	for index = 1, bottom_button_count do
		local button = bottom_buttons[index]
		local widget = self._widgets_by_name[button.name]

		if widget and widget.content.hotspot then
			widget.content.hotspot.pressed_callback = callback(self, "cb_on_bottom_pressed", button.action)
		end
	end

	for index = 1, tab_count do
		local tab = tabs[index]
		local widget = self._widgets_by_name[tab.name]

		if widget and widget.content.hotspot then
			widget.content.hotspot.pressed_callback = callback(self, "cb_on_tab_pressed", tab.action)
		end
	end

	Dropdown.init(self)
end

local function dropdown_blocks_outside_close(view, input_service)
	local widget = view._widgets_by_name and view._widgets_by_name.scope_dropdown
	local content = widget and widget.content

	if not content or content.exclusive_focus ~= true then
		return false
	end

	local holding_left = input_service:get("left_hold") == true
	local scrollbar_hotspot = content.scrollbar_hotspot

	if
		holding_left
		and (
			content.drag_active or (scrollbar_hotspot and (scrollbar_hotspot.is_hover or scrollbar_hotspot.on_pressed))
		)
	then
		return true
	end

	for index = 1, option_hotspot_key_count do
		local hotspot = content[option_hotspot_keys[index]]

		if hotspot and (hotspot.is_hover or hotspot.on_pressed) then
			return true
		end
	end

	return false
end

PresetEditorPanelView._maybe_close_on_outside_click = function(self, input_service)
	if not self._using_cursor_navigation or self._close_anim_id then
		return
	end

	if not input_service or type(input_service.is_null_service) == "function" and input_service:is_null_service() then
		return
	end

	if type(input_service.get) ~= "function" or not input_service:get("left_pressed") then
		return
	end

	if dropdown_blocks_outside_close(self, input_service) then
		return
	end

	if Dropdown.is_open(self) then
		Dropdown.close(self)
		return
	end

	local cursor = input_service:get("cursor")

	if not cursor then
		return
	end

	local inverse_scale = 1 / math.max(self:render_scale() or 1, 0.001)
	local cursor_position = UIResolution.inverse_scale_vector(cursor, inverse_scale)
	local popup_position = self:_scenegraph_world_position("popup_background")
	local x, y = popup_position[1], popup_position[2]
	local width, height = self:_scenegraph_size("popup_background")
	local scratch_min = self._alfs_outside_min or { 0, 0 }
	local scratch_max = self._alfs_outside_max or { 0, 0 }

	self._alfs_outside_min = scratch_min
	self._alfs_outside_max = scratch_max
	scratch_min[1] = x - 2
	scratch_min[2] = y - 2
	scratch_max[1] = width + 4
	scratch_max[2] = height + 4

	if math.point_is_inside_2d_box(cursor_position, scratch_min, scratch_max) then
		return
	end

	local ui = Managers and Managers.ui

	if not ui or type(ui.close_view) ~= "function" then
		return
	end

	if type(ui.view_active) == "function" and not ui:view_active(self.view_name) then
		return
	end

	if type(ui.is_view_closing) == "function" and ui:is_view_closing(self.view_name) then
		return
	end

	ui:close_view(self.view_name)
end

PresetEditorPanelView._hide_grid_empty_message = function(self, grid)
	local widget = grid and grid._widgets_by_name and grid._widgets_by_name.grid_empty

	if widget and widget.content then
		widget.content.visible = false
	end
end

PresetEditorPanelView.update = function(self, dt, t, input_service)
	self:_update_layout_animation(dt)

	local pass_input, pass_draw = PresetEditorPanelView.super.update(self, dt, t, input_service)

	Dropdown.update(self, dt, t, input_service)

	if Dropdown.is_open(self) then
		self._pass_input = false
	end

	if input_service and (type(input_service.is_null_service) ~= "function" or not input_service:is_null_service()) then
		if self._outside_click_ignore_frames and self._outside_click_ignore_frames > 0 then
			self._outside_click_ignore_frames = self._outside_click_ignore_frames - 1
		else
			self._outside_click_ignore_frames = nil
			self:_maybe_close_on_outside_click(input_service)
		end
	end

	if self._pending_full_rebuild then
		self._pending_full_rebuild = false
		self._pending_actions_rebuild = false
		self._pending_character_detail_rebuild = false

		if self._pending_scope then
			self._scope = self._pending_scope
			self._pending_scope = nil
		end

		self:_rebuild()
	elseif self._pending_actions_rebuild then
		self._pending_actions_rebuild = false
		self:_rebuild_actions()
	elseif self._pending_character_detail_rebuild then
		self._pending_character_detail_rebuild = false
		self:_rebuild_character_detail()
	end

	if self._characters_view_mode then
		self:_hide_grid_empty_message(self._list_grid)
		self:_hide_grid_empty_message(self._actions_grid)
		self:_hide_grid_empty_message(self._available_grid)
	end

	self:_update_tooltip()
	self:_update_save_pulse(t)

	return pass_input, pass_draw
end

PresetEditorPanelView._update_tooltip = function(self)
	local tooltip_element = self._tooltip_element

	if not tooltip_element then
		return
	end

	local tooltip_text = tooltip_text_for_widget(hovered_grid_widget(self._list_grid))

	if not tooltip_text then
		tooltip_text = tooltip_text_for_widget(hovered_grid_widget(self._actions_grid))
	end

	if not tooltip_text then
		tooltip_text = tooltip_text_for_widget(hovered_grid_widget(self._available_grid))
	end

	if not tooltip_text then
		tooltip_text = tooltip_text_for_widget(self._widgets_by_name.scope_dropdown)
	end

	if not tooltip_text then
		for index = 1, tab_count do
			tooltip_text = tooltip_text_for_widget(self._widgets_by_name[tabs[index].name])

			if tooltip_text then
				break
			end
		end
	end

	if not tooltip_text then
		for index = 1, bottom_button_count do
			tooltip_text = tooltip_text_for_widget(self._widgets_by_name[bottom_buttons[index].name])

			if tooltip_text then
				break
			end
		end
	end

	local visible = tooltip_text ~= nil

	if self._last_tooltip_text ~= tooltip_text or self._last_tooltip_visible ~= visible then
		self._last_tooltip_text = tooltip_text
		self._last_tooltip_visible = visible
		tooltip_element:set_tooltip(tooltip_text, 0, 0, visible)
	end
end

PresetEditorPanelView._update_save_pulse = function(self, t)
	local widget = self._save_button_widget

	if not widget or not widget.content then
		return
	end

	local content = widget.content
	local active = self._has_presets ~= true and not self._close_anim_id

	if content.pulse_save ~= active then
		content.pulse_save = active
	end

	if not active or type(t) ~= "number" then
		if content.save_pulse_progress ~= 0 then
			content.save_pulse_progress = 0
		end

		return
	end

	content.save_pulse_progress = 0.5 + 0.5 * math.sin(t * 2)
end

PresetEditorPanelView.on_enter = function(self)
	PresetEditorPanelView.super.on_enter(self)

	self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 200)

	for _, legend_input in ipairs(Definitions.legend_inputs) do
		local on_pressed_callback = legend_input.on_pressed_callback
			and callback(self, legend_input.on_pressed_callback)

		self._input_legend_element:add_entry(
			legend_input.display_name,
			legend_input.input_action,
			legend_input.visibility_function,
			on_pressed_callback,
			legend_input.alignment
		)
	end

	self._list_grid =
		self:_add_element(ViewElementGrid, "preset_list", 202, Definitions.list_grid_settings, "preset_list_pivot")
	self._actions_grid =
		self:_add_element(ViewElementGrid, "preset_actions", 204, Definitions.actions_grid_settings, "actions_pivot")
	self._available_grid =
		self:_add_element(
			ViewElementGrid,
			"available_presets",
			205,
			Definitions.available_grid_settings,
			"available_pivot"
		)
	self._tooltip_element = self:_add_element(PresetTooltipElement, "preset_tooltip", 206)
	self._last_tooltip_text = nil
	self._last_tooltip_visible = nil
	self._outside_click_ignore_frames = 2
	self._selected_name = nil
	self._rebuilt_scope_key = nil
	self._has_presets = false

	self:_rebuild()
	self._open_anim_id = self:_start_animation("on_enter", self._widgets_by_name, self)
end

PresetEditorPanelView.on_exit = function(self)
	if Dropdown.is_open(self) then
		Dropdown.close(self)
	end

	self:_invalidate_character_request()
	self._character_assignment_cache = nil

	PresetEditorPanelView.super.on_exit(self)

	self._open_anim_id = nil
	self._close_anim_id = nil
	self._list_grid = nil
	self._actions_grid = nil
	self._available_grid = nil
	self._tooltip_element = nil
	self._has_presets = false
	self._save_button_widget = nil

	if mod._preset_panel_restore_settings_state_bound_if_settings_closed then
		mod._preset_panel_restore_settings_state_bound_if_settings_closed()
	end
end

PresetEditorPanelView.trigger_on_exit_animation = function(self)
	if self._close_anim_id then
		return
	end

	self._close_anim_id = self:_start_animation("on_exit", self._widgets_by_name, self)
end

PresetEditorPanelView.on_exit_animation_done = function(self)
	return self._close_anim_id ~= nil and self:_is_animation_completed(self._close_anim_id)
end

PresetEditorPanelView._rebuild = function(self)
	if not self._list_grid or not self._actions_grid or not self._available_grid then
		return
	end

	if type(self._scope) ~= "table" then
		self._scope = mod._preset_panel_get_scope()
	end

	mod._preset_panel_context = self._scope
	self._character_mode = false
	self:_update_tabs()

	local widgets_by_name = self._widgets_by_name

	if self._characters_view_mode then
		self._list_grid:present_grid_layout({}, Blueprints)
		local selected_text = widgets_by_name.selected_preset_text

		if selected_text and selected_text.content then
			selected_text.content.selected_text = ""
		end

		Dropdown.sync(self)
		self:_rebuild_characters_view()
		return
	end

	self._actions_height_target = actions_list_height
	self:_set_character_widgets_visible(true, false)

	local current_scope_key = panel_scope_key(self._scope)
	local names = mod._preset_panel_get_names(self._scope)

	self._has_presets = #names > 0

	local selected_is_valid = false

	if self._rebuilt_scope_key ~= current_scope_key then
		self._selected_name = nil
		self._rebuilt_scope_key = current_scope_key
	end

	for _, name in ipairs(names) do
		if name == self._selected_name then
			selected_is_valid = true
			break
		end
	end

	if not selected_is_valid then
		self._selected_name = nil
	end

	local layout = {}

	if #names == 0 then
		layout[1] = {
			widget_type = "info",
			text = mod:localize("preset_editor_no_presets"),
		}
	else
		for _, name in ipairs(names) do
			layout[#layout + 1] = {
				widget_type = "preset_entry",
				name = name,
				text = name,
				tooltip = mod:localize("preset_editor_preset_tooltip", name),
			}
		end
	end

	self._list_grid:present_grid_layout(layout, Blueprints, callback(self, "cb_on_preset_pressed"))
	self:_apply_list_button_width()
	self:_update_preset_selection()

	local scope_label = widgets_by_name.scope_label

	if scope_label and scope_label.content then
		local scope_name = mod._preset_panel_get_scope_name and mod._preset_panel_get_scope_name() or ""

		scope_label.content.scope_label = mod:localize("preset_editor_viewing_presets_for_mod", tostring(scope_name))
	end

	Dropdown.sync(self)
	self:_rebuild_actions()
end

PresetEditorPanelView._update_preset_selection = function(self)
	local grid_widgets = self._list_grid and self._list_grid._grid_widgets

	if not grid_widgets then
		return
	end

	for _, widget in ipairs(grid_widgets) do
		local content = widget and widget.content
		local hotspot = content and content.hotspot

		if hotspot then
			hotspot.is_selected = content.name == self._selected_name
		end
	end
end

PresetEditorPanelView._update_selected_text = function(self)
	local widget = self._widgets_by_name.selected_preset_text

	if not widget then
		return
	end

	if not self._selected_name then
		widget.content.selected_text = ""
	end
end

PresetEditorPanelView._invalidate_character_request = function(self)
	self._character_request_id = self._character_request_id + 1
end

local function character_assignment_key(scope, name)
	return panel_scope_key(scope) .. "|" .. tostring(name)
end

PresetEditorPanelView._reset_character_detail = function(self)
	self._character_detail_mode = false
	self._selected_character_id = nil
	self._selected_character = nil
	self._selected_character_name = nil
	self._character_assignment_cache = nil
end

PresetEditorPanelView._sync_character_assignment_cache = function(self)
	self._character_assignment_cache = self._character_assignment_cache or {}

	local cache = self._character_assignment_cache
	local lookup = {}

	for _, entry in ipairs(cache) do
		lookup[character_assignment_key(entry.scope, entry.name)] = entry
	end

	if type(mod._preset_panel_get_character_assignments) ~= "function" then
		return cache
	end

	for _, assignment in ipairs(mod._preset_panel_get_character_assignments(self._selected_character_id) or {}) do
		local key = character_assignment_key(assignment.scope, assignment.name)

		if not lookup[key] then
			local entry = {
				scope = assignment.scope,
				scope_name = assignment.scope_name or "",
				name = assignment.name,
				preset = assignment.preset,
				display_name = assignment.display_name or assignment.name,
				assigned = true,
			}

			cache[#cache + 1] = entry
			lookup[key] = entry
		end
	end

	return cache
end

PresetEditorPanelView._set_character_assignment_state = function(self, scope, name, scope_name, assigned)
	if type(scope) ~= "table" or not name then
		return
	end

	local cache = self:_sync_character_assignment_cache()
	local key = character_assignment_key(scope, name)

	for _, entry in ipairs(cache) do
		if character_assignment_key(entry.scope, entry.name) == key then
			entry.assigned = assigned == true
			entry.scope_name = scope_name or entry.scope_name
			return
		end
	end

	local display_name = name

	if scope_name and scope_name ~= "" then
		display_name = scope_name .. ": " .. name
	end

	cache[#cache + 1] = {
		scope = scope,
		scope_name = scope_name or "",
		name = name,
		display_name = display_name,
		assigned = assigned == true,
	}
end

PresetEditorPanelView._rebuild_characters_view = function(self)
	if not self._actions_grid then
		return
	end

	if self._character_detail_mode and self._selected_character_id then
		self:_rebuild_character_detail()
		return
	end

	self:_invalidate_character_request()
	self._actions_height_target = characters_actions_height
	self:_set_character_widgets_visible(false, false)

	local request_id = self._character_request_id
	local layout = {}
	local callback_name = callback(self, "cb_on_character_pressed")

	local function present_characters(profiles)
		if
			self._character_request_id ~= request_id
			or not self._actions_grid
			or not self._characters_view_mode
			or self._character_detail_mode
		then
			return
		end

		for _, profile in ipairs(profiles or {}) do
			layout[#layout + 1] = {
				widget_type = "character_summary",
				action = "character_summary",
				id = profile.id,
				name = profile.name,
				archetype_name = profile.archetype_name,
				profile = profile.profile,
				level = profile.level,
				title = profile.title or "",
				text = profile.name,
				tooltip = mod:localize("preset_editor_character_tooltip", tostring(profile.name)),
			}
		end

		self._actions_grid:present_grid_layout(layout, Blueprints, callback_name)
		self:_update_bottom_buttons()
	end

	mod._preset_panel_get_characters(present_characters)
	self:_update_bottom_buttons()
end

PresetEditorPanelView._rebuild_character_detail = function(self)
	if not self._actions_grid or not self._available_grid or not self._selected_character_id then
		return
	end

	self._actions_height_target = detail_upper_height
	self:_set_character_widgets_visible(true, true)
	Dropdown.sync(self)

	local widgets_by_name = self._widgets_by_name
	local scope_widget = widgets_by_name and widgets_by_name.scope_dropdown
	local scope_content = scope_widget and scope_widget.content
	local scope_name = scope_content and scope_content.value_text or ""
	local scope_label = widgets_by_name and widgets_by_name.scope_label

	if scope_label and scope_label.content then
		scope_label.content.scope_label = mod:localize("preset_editor_viewing_presets_for_mod", tostring(scope_name))
	end

	local character = self._selected_character or {}
	local character_id = self._selected_character_id
	local character_name = self._selected_character_name or character.name or character_id

	local layout = {
		{
			widget_type = "character_summary",
			action = "character_summary",
			id = character_id,
			name = character_name,
			archetype_name = character.archetype_name or "",
			profile = character.profile,
			level = character.level or "",
			title = "",
			text = character_name,
		},
		{
			widget_type = "wide_info",
			text = mod:localize("preset_editor_assigned_presets_header"),
		},
	}

	local assignments = self:_sync_character_assignment_cache()

	if #assignments == 0 then
		layout[#layout + 1] = {
			widget_type = "wide_info",
			text = mod:localize("preset_editor_character_no_assignments"),
		}
	else
		for _, assignment in ipairs(assignments) do
			local assigned = assignment.assigned == true
			local tooltip_key = assigned and "preset_editor_assigned_preset_tooltip" or "preset_editor_unassigned_preset_tooltip"
			local display_name = assignment.display_name or (tostring(assignment.scope_name or "") .. ": " .. tostring(assignment.name))

			layout[#layout + 1] = {
				widget_type = "preset_toggle_half",
				action = "preset_toggle",
				scope = assignment.scope,
				name = assignment.name,
				scope_name = assignment.scope_name,
				assigned = assigned,
				text = tostring(display_name),
				tooltip = mod:localize(tooltip_key, tostring(assignment.name), tostring(character_name)),
			}
		end
	end

	self._actions_grid:present_grid_layout(layout, Blueprints, callback(self, "cb_on_character_pressed"))

	local available_layout = {
		{
			widget_type = "wide_info",
			text = mod:localize("preset_editor_available_presets_header"),
		},
	}
	local names = mod._preset_panel_get_names(self._characters_scope)

	if #names == 0 then
		available_layout[#available_layout + 1] = {
			widget_type = "wide_info",
			text = mod:localize("preset_editor_no_presets"),
		}
	else
		for _, name in ipairs(names) do
			local assigned = mod._preset_panel_is_character_assigned(self._characters_scope, name, character_id)
			local tooltip_key = assigned and "preset_editor_assigned_preset_tooltip" or "preset_editor_unassigned_preset_tooltip"

			available_layout[#available_layout + 1] = {
				widget_type = "preset_toggle",
				action = "preset_toggle",
				scope = self._characters_scope,
				name = name,
				scope_name = scope_name,
				assigned = assigned,
				text = name,
				tooltip = mod:localize(tooltip_key, tostring(name), tostring(character_name)),
			}
		end
	end

	self._available_grid:present_grid_layout(available_layout, Blueprints, callback(self, "cb_on_character_pressed"))
	self:_update_bottom_buttons()
end

PresetEditorPanelView._rebuild_actions = function(self)
	if not self._actions_grid then
		return
	end

	if self._characters_view_mode then
		return
	end

	self:_update_selected_text()

	local layout = {}

	if self._character_mode and self._selected_name then
		local selected_name = self._selected_name

		layout[1] = {
			widget_type = "info",
			text = mod:localize("preset_editor_character_hint", selected_name),
		}

		local request_id = self._character_request_id + 1
		local applied = false

		self._character_request_id = request_id

		local function present_characters(profiles)
			if
				self._character_request_id ~= request_id
				or not self._actions_grid
				or not self._character_mode
				or self._selected_name ~= selected_name
			then
				return
			end

			applied = true
			layout = {
				{
					widget_type = "info",
					text = mod:localize("preset_editor_character_hint", selected_name),
				},
			}

			for _, profile in ipairs(profiles or {}) do
				layout[#layout + 1] = {
					widget_type = "character_toggle",
					id = profile.id,
					name = profile.name,
					archetype_name = profile.archetype_name,
					profile = profile.profile,
					level = profile.level,
					title = profile.title or "",
					assigned = mod._preset_panel_is_character_assigned(
						mod._preset_panel_scope_for_view(self),
						selected_name,
						profile.id
					),
					text = profile.name,
					tooltip = mod:localize("preset_editor_character_tooltip", tostring(profile.name)),
				}
			end

			self._actions_grid:present_grid_layout(layout, Blueprints, callback(self, "cb_on_character_pressed"))
			self:_update_bottom_buttons()
		end

		mod._preset_panel_get_characters(present_characters)

		if not applied then
			self._actions_grid:present_grid_layout(layout, Blueprints, callback(self, "cb_on_character_pressed"))
		end

		self:_update_bottom_buttons()

		return
	end

	if self._selected_name then
		layout[#layout + 1] = {
			widget_type = "action_button",
			action = "apply",
			text = mod:localize("preset_editor_apply"),
			tooltip = mod:localize("preset_editor_apply_tooltip"),
		}
		layout[#layout + 1] = {
			widget_type = "action_button",
			action = "export",
			text = mod:localize("preset_editor_export"),
			tooltip = mod:localize("preset_editor_export_tooltip"),
		}
		layout[#layout + 1] = {
			widget_type = "action_button",
			action = "characters",
			text = mod:localize("preset_editor_assign"),
			tooltip = mod:localize("preset_editor_assign_tooltip"),
		}
		layout[#layout + 1] = {
			widget_type = "action_button",
			action = "delete",
			text = mod:localize("preset_editor_delete"),
			tooltip = mod:localize("preset_editor_delete_tooltip"),
		}
	elseif self._has_presets then
		layout[#layout + 1] = {
			widget_type = "info",
			text = mod:localize("preset_editor_select_preset_hint"),
		}
	end

	self._actions_grid:present_grid_layout(layout, Blueprints, callback(self, "cb_on_action_pressed"))
	self:_update_bottom_buttons()
end

PresetEditorPanelView._set_list_visible = function(self, visible)
	if self._list_pane_visible == visible then
		return
	end

	self._list_pane_visible = visible

	local list_frame = self._widgets_by_name and self._widgets_by_name.list_frame

	if list_frame then
		list_frame.visible = visible
	end

	if self._list_grid and type(self._list_grid.set_visibility) == "function" then
		self._list_grid:set_visibility(visible)
	end
end

PresetEditorPanelView._set_actions_height = function(self, height)
	local rounded = math.floor(height + 0.5)

	if rounded < 1 or self._applied_actions_height == rounded then
		return
	end

	self._applied_actions_height = rounded

	local grid = self._actions_grid
	local settings = grid and grid._menu_settings

	if settings and type(settings.grid_size) == "table" and type(settings.mask_size) == "table" then
		settings.grid_size[2] = rounded
		settings.mask_size[2] = rounded

		if type(grid._update_window_size) == "function" then
			grid:_update_window_size()
		end
	end

	if type(self._set_scenegraph_size) == "function" then
		self:_set_scenegraph_size("actions_frame", nil, rounded + actions_frame_top_padding * 2)
		self:_set_scenegraph_size("actions_pivot", nil, rounded)
	end
end

PresetEditorPanelView._set_actions_y = function(self, y)
	local rounded = math.floor(y + 0.5)

	if rounded < 1 or self._applied_actions_y == rounded then
		return
	end

	self._applied_actions_y = rounded

	if type(self._set_scenegraph_position) == "function" then
		self:_set_scenegraph_position("actions_pivot", nil, rounded)
		self:_set_scenegraph_position("actions_frame", nil, rounded - actions_frame_top_padding)
	end
end

PresetEditorPanelView._set_actions_width = function(self, width)
	local rounded = math.floor(width + 0.5)

	if rounded < 1 or self._applied_actions_width == rounded then
		return
	end

	self._applied_actions_width = rounded

	if type(self._set_scenegraph_size) == "function" then
		self:_set_scenegraph_size("actions_frame", rounded + actions_pivot_margin, nil)
		self:_set_scenegraph_size("actions_pivot", rounded, nil)
		self:_set_scenegraph_size("available_pivot", rounded, nil)
	end

	local grid = self._actions_grid
	local settings = grid and grid._menu_settings

	if settings and type(settings.grid_size) == "table" and type(settings.mask_size) == "table" then
		settings.grid_size[1] = rounded
		settings.mask_size[1] = rounded

		if type(grid._update_window_size) == "function" then
			grid:_update_window_size()
		end
	end

	local available_grid = self._available_grid
	local available_settings = available_grid and available_grid._menu_settings

	if
		available_settings
		and type(available_settings.grid_size) == "table"
		and type(available_settings.mask_size) == "table"
	then
		available_settings.grid_size[1] = rounded
		available_settings.mask_size[1] = rounded

		if type(available_grid._update_window_size) == "function" then
			available_grid:_update_window_size()
		end
	end
end

PresetEditorPanelView._apply_list_button_width = function(self)
	if type(Blueprints.resize_preset_entry) ~= "function" then
		return
	end

	local widgets = self._list_grid and self._list_grid._grid_widgets

	if not widgets then
		return
	end

	local width = self._list_button_width or preset_entry_default_width

	for index = 1, #widgets do
		local widget = widgets[index]

		if widget and widget.type == "preset_entry" then
			Blueprints.resize_preset_entry(widget, width)
		end
	end
end

PresetEditorPanelView._set_list_width = function(self, width)
	local rounded = math.max(0, math.floor(width + 0.5))

	if rounded == self._applied_list_width then
		return
	end

	self._applied_list_width = rounded

	local grid_width = math.max(1, rounded - list_width_margin)

	if type(self._set_scenegraph_size) == "function" then
		self:_set_scenegraph_size("list_frame", rounded, nil)
		self:_set_scenegraph_size("preset_list_pivot", grid_width, nil)
	end

	local grid = self._list_grid
	local settings = grid and grid._menu_settings

	self._list_button_width = math.max(1, grid_width - preset_button_margin)
	self:_apply_list_button_width()

	if settings and type(settings.grid_size) == "table" and type(settings.mask_size) == "table" then
		settings.grid_size[1] = grid_width
		settings.mask_size[1] = grid_width

		if type(grid._update_window_size) == "function" then
			grid:_update_window_size()
		end
	end
end

PresetEditorPanelView._set_pane_mode = function(self, characters_active)
	self._actions_width_target = characters_active and full_actions_width or default_actions_width
	self._actions_y_target = characters_active and characters_actions_y or default_actions_y

	local header_rule = self._widgets_by_name and self._widgets_by_name.header_rule

	if header_rule then
		header_rule.visible = not characters_active
	end
end

PresetEditorPanelView._set_character_widgets_visible = function(self, dropdown_visible, available_visible)
	if
		self._dropdown_widgets_visible == dropdown_visible
		and self._available_grid_visible == available_visible
	then
		return
	end

	local dropdown_changed = self._dropdown_widgets_visible ~= dropdown_visible

	self._dropdown_widgets_visible = dropdown_visible
	self._available_grid_visible = available_visible

	if dropdown_changed then
		local scope_dropdown = self._widgets_by_name and self._widgets_by_name.scope_dropdown

		if scope_dropdown then
			scope_dropdown.visible = dropdown_visible

			if not dropdown_visible and scope_dropdown.content and scope_dropdown.content.exclusive_focus then
				Dropdown.close(self)
			end
		end

		local scope_label = self._widgets_by_name and self._widgets_by_name.scope_label

		if scope_label then
			scope_label.visible = dropdown_visible
		end
	end

	if self._available_grid and type(self._available_grid.set_visibility) == "function" then
		self._available_grid:set_visibility(available_visible)
	end
end

PresetEditorPanelView._set_dropdown_position = function(self, characters_active)
	self._dropdown_x = characters_active and detail_dropdown_x or default_dropdown_x
	self._dropdown_y = characters_active and detail_dropdown_y or default_dropdown_y
	self._scope_label_x = characters_active and detail_dropdown_x or default_dropdown_x
	self._scope_label_y = characters_active and detail_scope_label_y or default_scope_label_y

	if type(self._set_scenegraph_position) == "function" then
		self:_set_scenegraph_position("scope_dropdown", self._dropdown_x, self._dropdown_y)
		self:_set_scenegraph_position("scope_label", self._scope_label_x, self._scope_label_y)
	end
end

PresetEditorPanelView._update_layout_animation = function(self, dt)
	if type(dt) ~= "number" then
		return
	end

	local width = self._actions_width or default_actions_width
	local target_width = self._actions_width_target or default_actions_width

	if width ~= target_width then
		local difference = target_width - width
		local factor = math.min(1, dt * 10)
		local next_width = width + difference * factor

		if math.abs(difference) < 0.5 then
			next_width = target_width
		end

		self._actions_width = next_width
		self:_set_actions_width(next_width)
	end

	local height = self._actions_height or actions_list_height
	local target_height = self._actions_height_target or actions_list_height

	if height ~= target_height then
		local difference = target_height - height
		local factor = math.min(1, dt * 10)
		local next_height = height + difference * factor

		if math.abs(difference) < 0.5 then
			next_height = target_height
		end

		self._actions_height = next_height
		self:_set_actions_height(next_height)
	end

	local actions_y = self._actions_y or default_actions_y
	local target_actions_y = self._actions_y_target or default_actions_y

	if actions_y ~= target_actions_y then
		local difference = target_actions_y - actions_y
		local factor = math.min(1, dt * 10)
		local next_y = actions_y + difference * factor

		if math.abs(difference) < 0.5 then
			next_y = target_actions_y
		end

		self._actions_y = next_y
		self:_set_actions_y(next_y)
	end

	local list_width = math.max(0, math.min(default_list_frame_width, full_actions_width - 20 - width))

	self:_set_list_width(list_width)
	self:_set_list_visible(list_width >= 24)
end

PresetEditorPanelView._update_tabs = function(self)
	local characters_active = self._characters_view_mode == true
	local active_tab = nil
	local divider_widget = self._widgets_by_name and self._widgets_by_name.title_divider
	local divider_content = divider_widget and divider_widget.content

	self:_set_pane_mode(characters_active)
	self:_set_dropdown_position(characters_active)

	for index = 1, tab_count do
		local tab = tabs[index]
		local widget = self._widgets_by_name and self._widgets_by_name[tab.name]
		local hotspot = widget and widget.content and widget.content.hotspot
		local active = (tab.action == "characters_overview") == characters_active

		if hotspot then
			hotspot.is_selected = active
		end

		if active then
			active_tab = tab
		end
	end

	if active_tab then
		local target_x = active_tab.x + (tab_width - tab_divider_width) * 0.5

		if self._divider_x ~= target_x then
			self._divider_x = target_x

			if divider_content then
				divider_content.anim_select_progress = 1
			end

			if type(self._set_scenegraph_position) == "function" then
				self:_set_scenegraph_position("title_divider", target_x)
			end
		end
	end
end

PresetEditorPanelView._update_bottom_buttons = function(self)
	local close_widget = self._widgets_by_name.bottom_close

	for index = 1, bottom_button_count do
		local button = bottom_buttons[index]
		local widget = self._widgets_by_name[button.name]

		if widget then
			local text_key = button.text_key
			local tooltip_key = button.tooltip_key

			if button.action == "close_back" and (self._character_mode or self._characters_view_mode) then
				text_key = "preset_editor_back"
				tooltip_key = "preset_editor_back_tooltip"
			end

			widget.content.text = mod:localize(text_key)
			widget.content.original_text = widget.content.text
			widget.content.tooltip_text = mod:localize(tooltip_key)
		end
	end

	if close_widget and close_widget.content.hotspot then
		close_widget.content.hotspot.pressed_callback = callback(self, "cb_on_bottom_pressed", "close_back")
	end
end

PresetEditorPanelView._set_characters_scope = function(self, scope)
	if type(scope) ~= "table" then
		return
	end

	self._characters_scope = scope
	self._pending_character_detail_rebuild = true
	Dropdown.sync(self)
end

PresetEditorPanelView._set_scope = function(self, scope)
	if type(scope) ~= "table" then
		return
	end

	self:_invalidate_character_request()
	self:_reset_character_detail()
	self._scope = scope
	self._characters_scope = scope
	self._pending_scope = scope
	self._pending_full_rebuild = true
	self._character_mode = false
	self._characters_view_mode = false
	self:_update_tabs()
end

PresetEditorPanelView._handle_close_back = function(self)
	if Dropdown.is_open(self) then
		Dropdown.close(self)
		return
	end

	if self._characters_view_mode then
		if self._character_detail_mode then
			self:_reset_character_detail()
			self._pending_full_rebuild = true
			self:_update_tabs()
			return
		end

		self:_invalidate_character_request()
		self._characters_view_mode = false
		self._pending_full_rebuild = true
		self:_update_tabs()
		return
	end

	if self._character_mode then
		self:_invalidate_character_request()
		self._character_mode = false
		self._pending_actions_rebuild = true
		return
	end

	local ui = Managers and Managers.ui

	if not ui or type(ui.close_view) ~= "function" then
		return
	end

	if type(ui.view_active) == "function" and not ui:view_active(self.view_name) then
		return
	end

	if type(ui.is_view_closing) == "function" and ui:is_view_closing(self.view_name) then
		return
	end

	ui:close_view(self.view_name)
end

PresetEditorPanelView.cb_on_preset_pressed = function(self, _, element)
	if not element or not element.name then
		return
	end

	if Dropdown.is_open(self) then
		Dropdown.close(self)
		return
	end

	self:_invalidate_character_request()
	self._selected_name = element.name
	self._character_mode = false
	self._characters_view_mode = false
	self:_update_tabs()
	self:_update_preset_selection()
	self:_update_selected_text()
	self._pending_actions_rebuild = true
end

PresetEditorPanelView.cb_on_action_pressed = function(self, _, element)
	local action = element and element.action
	local scope = mod._preset_panel_scope_for_view(self)

	if action == "apply" then
		mod._preset_panel_apply(self, scope, self._selected_name)
	elseif action == "export" then
		mod._preset_panel_show_export(self, scope, self._selected_name)
	elseif action == "export_current" then
		mod._preset_panel_show_current_export(self, scope)
	elseif action == "delete" then
		mod._preset_panel_delete(self, scope, self._selected_name)
	elseif action == "save" then
		mod._preset_panel_show_save(self, scope)
	elseif action == "import" then
		mod._preset_panel_show_import(self, scope)
	elseif action == "characters" then
		self._character_mode = true
		self._pending_actions_rebuild = true
	elseif action == "characters_overview" then
		self:_invalidate_character_request()
		self:_reset_character_detail()
		self._characters_scope = scope
		self._character_mode = false
		self._characters_view_mode = true
		self._pending_full_rebuild = true
		self:_update_tabs()
	elseif action == "back" or action == "close" or action == "close_back" then
		self:_handle_close_back()
	end
end

PresetEditorPanelView.cb_on_bottom_pressed = function(self, action)
	if Dropdown.is_open(self) then
		Dropdown.close(self)
		return
	end

	self:cb_on_action_pressed(nil, { action = action })
end

PresetEditorPanelView.cb_on_tab_pressed = function(self, tab)
	if Dropdown.is_open(self) then
		Dropdown.close(self)
		return
	end

	if tab == "presets" then
		if not self._characters_view_mode and not self._character_mode then
			return
		end

		self:_invalidate_character_request()
		self:_reset_character_detail()
		self._character_mode = false
		self._characters_view_mode = false
		self._pending_full_rebuild = true
		self:_update_tabs()
	elseif tab == "characters_overview" then
		if self._characters_view_mode then
			return
		end

		self:_invalidate_character_request()
		self:_reset_character_detail()
		self._characters_scope = mod._preset_panel_scope_for_view(self)
		self._character_mode = false
		self._characters_view_mode = true
		self._pending_full_rebuild = true
		self:_update_tabs()
	end
end

PresetEditorPanelView.cb_on_scope_pressed = function(self)
	Dropdown.toggle(self)
end

PresetEditorPanelView.cb_on_character_pressed = function(self, widget, element)
	local action = element and element.action

	if Dropdown.is_open(self) then
		Dropdown.close(self)
		return
	end

	if action == "back" or action == "close" or action == "close_back" then
		self:_handle_close_back()
		return
	end

	if self._characters_view_mode then
		if self._character_detail_mode then
			if
				action == "preset_toggle"
				and element.scope
				and element.name
				and self._selected_character_id
			then
				local assigned = mod._preset_panel_toggle_character(
					element.scope,
					element.name,
					self._selected_character_id,
					self._selected_character_name
				)

				self:_set_character_assignment_state(element.scope, element.name, element.scope_name, assigned)
				self._pending_character_detail_rebuild = true
			end

			return
		end

		if action == "character_summary" and element.id then
			self:_invalidate_character_request()
			self._selected_character_id = element.id
			self._selected_character_name = element.name or element.id
			self._selected_character = element
			self._character_assignment_cache = nil
			self._character_detail_mode = true
			self._pending_character_detail_rebuild = true
			self:_update_tabs()
		end

		return
	end

	if action == "character_summary" then
		return
	end

	if not element or not element.id then
		return
	end

	local assigned = mod._preset_panel_toggle_character(
		mod._preset_panel_scope_for_view(self),
		self._selected_name,
		element.id,
		element.name
	)
	local content = widget and widget.content

	if content then
		local archetype_name = element.archetype_name or ""
		local level = element.level or ""

		content.assigned = assigned == true
		content.assignment_text = assigned and "\226\156\147" or ""
		content.character_name = element.name or ""
		content.character_archetype_title = level ~= "" and (archetype_name .. "  " .. level) or archetype_name

		local assignment_text = element.title or ""

		if type(mod._preset_panel_assigned_preset_text) == "function" then
			assignment_text = mod._preset_panel_assigned_preset_text(element.id) or ""
		end

		if type(Blueprints.wrap_assignment_text) == "function" then
			content.character_title = Blueprints.wrap_assignment_text(self:ui_renderer(), widget, assignment_text, 2)
		else
			content.character_title = assignment_text
		end
	end
end

PresetEditorPanelView._on_back_pressed = function(self)
	self:_handle_close_back()
end

PresetEditorPanelView._styles = Styles

return PresetEditorPanelView
