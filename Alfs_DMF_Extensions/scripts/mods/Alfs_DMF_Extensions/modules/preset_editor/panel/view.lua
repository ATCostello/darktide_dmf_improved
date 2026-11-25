local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local ViewElementGrid = require("scripts/ui/view_elements/view_element_grid/view_element_grid")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")

local Definitions = mod._preset_panel_definitions
local Blueprints = mod._preset_panel_blueprints
local Dropdown = mod._preset_panel_dropdown
local Styles = mod._preset_panel_styles

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

	for _, name in ipairs(Definitions.widget_draw_order) do
		local widget = widgets_by_name and widgets_by_name[name]

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

PresetEditorPanelView.draw = function(self, dt, t, input_service, layer)
	PresetEditorPanelView.super.draw(self, dt, t, input_service, layer)

	local widget = self._widgets_by_name and self._widgets_by_name.scope_dropdown
	local ui_renderer = self._ui_renderer
	local render_settings = self._render_settings

	if not widget or not ui_renderer or not render_settings then
		return
	end

	local previous_layer = render_settings.start_layer or 0

	render_settings.start_layer = previous_layer + 104
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

				if element == self._list_grid or element == self._actions_grid then
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

				if element == self._list_grid or element == self._actions_grid then
					element_input_service = grid_input_service
				end

				element:update(dt, t, element_input_service)
			end
		end
	end
end

PresetEditorPanelView.init = function(self, settings)
	PresetEditorPanelView.super.init(self, Definitions, settings)

	self._pass_draw = false
	self._pass_input = false
	self._allow_close_hotkey = true
	self._scope = nil
	self._selected_name = nil
	self._rebuilt_scope_key = nil
	self._character_mode = false
	self._character_request_id = 0
	self._drawn_widgets = {}
	self._pending_actions_rebuild = false
	self._pending_full_rebuild = false
	self._pending_scope = nil
	self._open_anim_id = nil
	self._close_anim_id = nil

	for _, button in ipairs(Definitions.bottom_buttons) do
		local widget = self._widgets_by_name[button.name]

		if widget and widget.content.hotspot then
			widget.content.hotspot.pressed_callback = callback(self, "cb_on_bottom_pressed", button.action)
		end
	end

	Dropdown.init(self)
end

PresetEditorPanelView.update = function(self, dt, t, input_service)
	PresetEditorPanelView.super.update(self, dt, t, input_service)

	Dropdown.update(self, dt, t, input_service)

	if Dropdown.is_open(self) then
		self._pass_input = false
	end

	if self._pending_full_rebuild then
		self._pending_full_rebuild = false
		self._pending_actions_rebuild = false

		if self._pending_scope then
			self._scope = self._pending_scope
			self._pending_scope = nil
		end

		self:_rebuild()
	elseif self._pending_actions_rebuild then
		self._pending_actions_rebuild = false
		self:_rebuild_actions()
	end

	self:_update_tooltip()
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
		tooltip_text = tooltip_text_for_widget(self._widgets_by_name.scope_dropdown)
	end

	if not tooltip_text then
		for _, button in ipairs(Definitions.bottom_buttons) do
			tooltip_text = tooltip_text_for_widget(self._widgets_by_name[button.name])

			if tooltip_text then
				break
			end
		end
	end

	tooltip_element:set_tooltip(tooltip_text, 0, 0, tooltip_text ~= nil)
end

PresetEditorPanelView.on_enter = function(self)
	PresetEditorPanelView.super.on_enter(self)

	self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 100)

	for _, legend_input in ipairs(Definitions.legend_inputs) do
		local on_pressed_callback = legend_input.on_pressed_callback and callback(self, legend_input.on_pressed_callback)

		self._input_legend_element:add_entry(
			legend_input.display_name,
			legend_input.input_action,
			legend_input.visibility_function,
			on_pressed_callback,
			legend_input.alignment
		)
	end

	self._list_grid = self:_add_element(ViewElementGrid, "preset_list", 102, Definitions.list_grid_settings, "preset_list_pivot")
	self._actions_grid = self:_add_element(ViewElementGrid, "preset_actions", 103, Definitions.actions_grid_settings, "actions_pivot")
	self._tooltip_element = self:_add_element(PresetTooltipElement, "preset_tooltip", 105)
	self._selected_name = nil
	self._rebuilt_scope_key = nil

	self:_rebuild()
	self._open_anim_id = self:_start_animation("on_enter", self._widgets_by_name, self)
end

PresetEditorPanelView.on_exit = function(self)
	if Dropdown.is_open(self) then
		Dropdown.close(self)
	end

	self:_invalidate_character_request()

	PresetEditorPanelView.super.on_exit(self)

	self._open_anim_id = nil
	self._close_anim_id = nil
	self._list_grid = nil
	self._actions_grid = nil
	self._tooltip_element = nil
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
	if not self._list_grid or not self._actions_grid then
		return
	end

	self._scope = mod._preset_panel_get_scope()
	self._character_mode = false

	local current_scope_key = panel_scope_key(self._scope)
	local names = mod._preset_panel_get_names(self._scope)
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
	self:_update_preset_selection()

	local widgets_by_name = self._widgets_by_name

	if widgets_by_name.title_text then
		widgets_by_name.title_text.content.title_text = mod:localize("preset_editor_title")
	end

	if widgets_by_name.description_text then
		local scope_name = mod._preset_panel_get_scope_name and mod._preset_panel_get_scope_name()
			or mod:localize("preset_editor_all_mods")

		widgets_by_name.description_text.content.text = mod:localize("preset_editor_description", scope_name)
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
		return
	end

	widget.content.selected_text = mod:localize("preset_editor_selected", self._selected_name)
end

PresetEditorPanelView._invalidate_character_request = function(self)
	self._character_request_id = self._character_request_id + 1
end

PresetEditorPanelView._rebuild_actions = function(self)
	if not self._actions_grid then
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
			if self._character_request_id ~= request_id
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
					assigned = mod._preset_panel_is_character_assigned(self._scope, selected_name, profile.id),
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
	else
		layout[#layout + 1] = {
			widget_type = "info",
			text = mod:localize("preset_editor_select_preset_hint"),
		}
	end

	self._actions_grid:present_grid_layout(layout, Blueprints, callback(self, "cb_on_action_pressed"))
	self:_update_bottom_buttons()
end

PresetEditorPanelView._update_bottom_buttons = function(self)
	local close_widget = self._widgets_by_name.bottom_close

	for _, button in ipairs(Definitions.bottom_buttons) do
		local widget = self._widgets_by_name[button.name]

		if widget then
			local text_key = button.text_key
			local tooltip_key = button.tooltip_key

			if button.action == "close_back" and self._character_mode then
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

PresetEditorPanelView._set_scope = function(self, scope)
	if type(scope) ~= "table" then
		return
	end

	self:_invalidate_character_request()
	self._pending_scope = scope
	self._pending_full_rebuild = true
	self._character_mode = false
end

PresetEditorPanelView._handle_close_back = function(self)
	if Dropdown.is_open(self) then
		Dropdown.close(self)
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
	self:_update_preset_selection()
	self:_update_selected_text()
	self._pending_actions_rebuild = true
end

PresetEditorPanelView.cb_on_action_pressed = function(self, _, element)
	local action = element and element.action

	if action == "apply" then
		mod._preset_panel_apply(self, self._scope, self._selected_name)
	elseif action == "export" then
		mod._preset_panel_show_export(self, self._scope, self._selected_name)
	elseif action == "export_current" then
		mod._preset_panel_show_current_export(self, self._scope)
	elseif action == "delete" then
		mod._preset_panel_delete(self, self._scope, self._selected_name)
	elseif action == "save" then
		mod._preset_panel_show_save(self, self._scope)
	elseif action == "import" then
		mod._preset_panel_show_import(self, self._scope)
	elseif action == "characters" then
		self._character_mode = true
		self._pending_actions_rebuild = true
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

	if not element or not element.id then
		return
	end

	local assigned = mod._preset_panel_toggle_character(self._scope, self._selected_name, element.id, element.name)
	local content = widget and widget.content

	if content then
		content.assignment_text = assigned and "\226\156\147" or ""
		content.character_name = element.name or ""
		content.character_archetype_title = element.archetype_name or ""
	end
end

PresetEditorPanelView._on_back_pressed = function(self)
	self:_handle_close_back()
end

PresetEditorPanelView._styles = Styles

return PresetEditorPanelView
