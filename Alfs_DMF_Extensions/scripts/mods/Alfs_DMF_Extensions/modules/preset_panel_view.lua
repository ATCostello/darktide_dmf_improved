local mod = get_mod("Alfs_DMF_Extensions")

local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local ViewElementBase = require("scripts/ui/view_elements/view_element_base")
local ViewElementGrid = require("scripts/ui/view_elements/view_element_grid/view_element_grid")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")

local info_font_style = table.clone(UIFontSettings.body or UIFontSettings.button_primary)
info_font_style.font_size = 20
info_font_style.text_horizontal_alignment = "left"
info_font_style.text_vertical_alignment = "center"
info_font_style.horizontal_alignment = "left"
info_font_style.vertical_alignment = "center"
info_font_style.offset = { 6, 0, 2 }
info_font_style.text_color = Color.terminal_text_header(255, true)

local selected_text_style = table.clone(info_font_style)
selected_text_style.font_size = 18
selected_text_style.text_color = Color.terminal_text_header_selected(255, true)

local tooltip_text_style = table.clone(UIFontSettings.body_small or UIFontSettings.body or UIFontSettings.button_primary)
tooltip_text_style.font_size = 17
tooltip_text_style.text_horizontal_alignment = "left"
tooltip_text_style.text_vertical_alignment = "center"
tooltip_text_style.horizontal_alignment = "left"
tooltip_text_style.vertical_alignment = "center"
tooltip_text_style.offset = { 12, 0, 2 }
tooltip_text_style.size = { 396, 66 }
tooltip_text_style.word_wrap = true
tooltip_text_style.text_color = Color.white(255, true)

local function init_hotspot_widget(parent, widget, element, callback_name)
	widget.content.hotspot.pressed_callback = callback_name and callback(parent, callback_name, widget, element) or nil
	widget.content.text = element.text or ""
	widget.content.original_text = element.text or ""
	widget.content.tooltip_text = element.tooltip or ""
end

local function make_character_toggle_template()
	local template = {}

	for index, pass in ipairs(ButtonPassTemplates.list_button_with_background) do
		local cloned_pass = table.clone(pass)

		if pass.style then
			cloned_pass.style = table.clone(pass.style)
		end

		if cloned_pass.style_id == "text" and cloned_pass.style then
			cloned_pass.style.offset = { 62, 0, 4 }
		end

		template[index] = cloned_pass
	end

	local texture_index = 1

	for index, pass in ipairs(template) do
		if pass.pass_type ~= "hotspot" then
			texture_index = index
			break
		end
	end

	table.insert(template, texture_index, {
		pass_type = "texture",
		value_id = "archetype_icon",
		style_id = "archetype_icon",
		style = {
			horizontal_alignment = "left",
			vertical_alignment = "center",
			color = Color.terminal_text_header(255, true),
			size = { 48, 48 },
			offset = { 8, 0, 3 },
		},
	})

	return template
end

local character_toggle_template = make_character_toggle_template()

local blueprints = {
	preset_entry = {
		size = { 480, 58 },
		pass_template = ButtonPassTemplates.list_button_with_background,
		init = function(parent, widget, element, callback_name)
			init_hotspot_widget(parent, widget, element, callback_name)
			widget.content.name = element.name
			widget.content.hotspot.is_selected = parent and parent._selected_name == element.name or false
		end,
	},
	action_button = {
		size = { 980, 56 },
		pass_template = ButtonPassTemplates.terminal_button,
		init = init_hotspot_widget,
	},
	scope_option = {
		size = { 980, 56 },
		pass_template = ButtonPassTemplates.terminal_button,
		init = init_hotspot_widget,
	},
	character_toggle = {
		size = { 980, 54 },
		pass_template = character_toggle_template,
		init = function(parent, widget, element, callback_name)
			init_hotspot_widget(parent, widget, element, callback_name)
			widget.content.archetype_icon = element.archetype_icon or "content/ui/materials/icons/classes/veteran"
			widget.content.archetype_name = element.archetype_name or ""
		end,
	},
	info = {
		size = { 980, 42 },
		pass_template = {
			{
				pass_type = "text",
				value_id = "text",
				style_id = "text",
				style = info_font_style,
			},
		},
		init = function(_, widget, element)
			widget.content.text = element.text or ""
		end,
	},
}

local scenegraph_definition = {
	screen = {
		scale = "fit",
		size = { 1920, 1080 },
		position = { 0, 0, 100 },
	},
	title_divider = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 380, 18 },
		position = { 140, 130, 101 },
	},
	title_text = {
		parent = "title_divider",
		vertical_alignment = "bottom",
		horizontal_alignment = "left",
		size = { 900, 50 },
		position = { 0, -35, 101 },
	},
	description_text = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 900, 50 },
		position = { 140, 180, 101 },
	},
	selected_preset_text = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 1000, 30 },
		position = { 140, 224, 101 },
	},
	preset_list_pivot = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 500, 720 },
		position = { 140, 260, 101 },
	},
	actions_pivot = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = { 1000, 560 },
		position = { -180, 260, 101 },
	},
	bottom_actions = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 1000, 64 },
		position = { 740, 930, 101 },
	},
	bottom_save = {
		parent = "bottom_actions",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 280, 56 },
		position = { 0, 0, 1 },
	},
	bottom_import = {
		parent = "bottom_actions",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 280, 56 },
		position = { 300, 0, 1 },
	},
	bottom_export_current = {
		parent = "bottom_actions",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 280, 56 },
		position = { 600, 0, 1 },
	},
	bottom_close = {
		parent = "bottom_actions",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 80, 56 },
		position = { 920, 0, 1 },
	},
}

local function scope_key(scope)
	if scope and scope.kind == "global" then
		return "global"
	end

	return scope and scope.mod_name and ("mod:" .. tostring(scope.mod_name)) or "unknown"
end

local bottom_buttons = {
	{
		name = "bottom_save",
		action = "save",
		text_key = "preset_editor_save",
		tooltip_key = "preset_editor_save_tooltip",
		size = { 280, 56 },
	},
	{
		name = "bottom_import",
		action = "import",
		text_key = "preset_editor_import",
		tooltip_key = "preset_editor_import_tooltip",
		size = { 280, 56 },
	},
	{
		name = "bottom_export_current",
		action = "export_current",
		text_key = "preset_editor_export_current",
		tooltip_key = "preset_editor_export_current_tooltip",
		size = { 280, 56 },
	},
	{
		name = "bottom_close",
		action = "close_back",
		text_key = "preset_editor_close",
		tooltip_key = "preset_editor_close_tooltip",
		size = { 80, 56 },
	},
}

local tooltip_definitions = {
	scenegraph_definition = {
		screen = {
			scale = "fit",
			size = { 1920, 1080 },
			position = { 0, 0, 100 },
		},
		tooltip = {
			parent = "screen",
			vertical_alignment = "top",
			horizontal_alignment = "left",
			size = { 420, 78 },
			position = { 0, 0, 105 },
		},
	},
	widget_definitions = {
		tooltip = UIWidget.create_definition({
			{
				pass_type = "rect",
				style_id = "background",
				style = {
					color = Color.black(0, true),
				},
				change_function = function(content, style)
					style.color[1] = content.visible and 230 or 0
				end,
			},
			{
				pass_type = "texture",
				style_id = "frame",
				value = "content/ui/materials/frames/frame_tile_2px",
				style = {
					color = Color.terminal_frame(0, true),
					scale_to_material = true,
				},
				change_function = function(content, style)
					style.color[1] = content.visible and 255 or 0
				end,
			},
			{
				pass_type = "text",
				value_id = "tooltip_text",
				style_id = "tooltip_text",
				style = tooltip_text_style,
				change_function = function(content, style)
					style.text_color[1] = content.visible and 255 or 0
				end,
			},
		}, "tooltip"),
	},
}

local widget_definitions = {
	scrim = UIWidget.create_definition({
		{
			pass_type = "rect",
			style = {
				color = Color.black(190, true),
			},
		},
	}, "screen"),
	title_divider = UIWidget.create_definition({
		{
			pass_type = "texture",
			value = "content/ui/materials/dividers/skull_rendered_left_01",
		},
	}, "title_divider"),
	title_text = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "title_text",
			style_id = "title_text",
			style = table.clone(UIFontSettings.header_1 or UIFontSettings.header_3 or UIFontSettings.button_primary),
		},
	}, "title_text"),
	description_text = UIWidget.create_definition(ButtonPassTemplates.terminal_button, "description_text", {
		text = "",
		original_text = "",
		tooltip_text = "",
		hotspot = {},
	}, { 900, 50 }),
	selected_preset_text = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "selected_text",
			style_id = "selected_text",
			style = selected_text_style,
		},
	}, "selected_preset_text"),
}

for _, button in ipairs(bottom_buttons) do
	widget_definitions[button.name] = UIWidget.create_definition(ButtonPassTemplates.terminal_button, button.name, {
		text = mod:localize(button.text_key),
		original_text = mod:localize(button.text_key),
		tooltip_text = mod:localize(button.tooltip_key),
		hotspot = {},
	}, button.size)
end

local list_grid_settings = {
	scrollbar_width = 8,
	no_resource_rendering = true,
	use_terminal_background = true,
	ignore_divider_height = true,
	title_height = 0,
	top_padding = 12,
	bottom_chin = 12,
	grid_spacing = { 10, 10 },
	grid_size = { 480, 720 },
	mask_size = { 500, 720 },
	edge_padding = 20,
}

local actions_grid_settings = {
	scrollbar_width = 8,
	no_resource_rendering = true,
	use_terminal_background = true,
	ignore_divider_height = true,
	title_height = 0,
	top_padding = 12,
	bottom_chin = 12,
	grid_spacing = { 10, 10 },
	grid_size = { 980, 560 },
	mask_size = { 1000, 560 },
	edge_padding = 20,
}

local legend_inputs = {
	{
		input_action = "back",
		on_pressed_callback = "_on_back_pressed",
		display_name = "loc_class_selection_button_back",
		alignment = "left_alignment",
	},
}

local definitions = {
	scenegraph_definition = scenegraph_definition,
	widget_definitions = widget_definitions,
	blueprints = blueprints,
	legend_inputs = legend_inputs,
	list_grid_settings = list_grid_settings,
	actions_grid_settings = actions_grid_settings,
}

local PresetTooltipElement = class("PresetTooltipElement", "ViewElementBase")

PresetTooltipElement.init = function(self, parent, draw_layer, start_scale)
	PresetTooltipElement.super.init(self, parent, draw_layer, start_scale, tooltip_definitions)

	local tooltip = self._widgets_by_name.tooltip

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

PresetEditorPanelView.init = function(self, settings)
	PresetEditorPanelView.super.init(self, definitions, settings)

	self._pass_draw = false
	self._pass_input = false
	self._scope = nil
	self._selected_name = nil
	self._rebuilt_scope_key = nil
	self._character_mode = false
	self._scope_mode = false
	self._character_request_id = 0
	self._pending_actions_rebuild = false
	self._pending_full_rebuild = false
	self._pending_scope = nil

	local description = self._widgets_by_name.description_text

	if description then
		description.content.hotspot.pressed_callback = callback(self, "cb_on_scope_pressed")
		description.content.tooltip_text = mod:localize("preset_editor_scope_tooltip")
	end

	for _, button in ipairs(bottom_buttons) do
		local widget = self._widgets_by_name[button.name]

		if widget then
			widget.content.hotspot.pressed_callback = callback(self, "cb_on_bottom_pressed", button.action)
		end
	end
end

PresetEditorPanelView.update = function(self, dt, t, input_service)
	PresetEditorPanelView.super.update(self, dt, t, input_service)

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

	local tooltip_text
	local tooltip_x = 0
	local tooltip_y = 0
	local tooltip_width, tooltip_height = 420, 78

	if type(tooltip_element._scenegraph_size) == "function" then
		local width, height = tooltip_element:_scenegraph_size("tooltip")

		if width then
			tooltip_width = width
		end

		if height then
			tooltip_height = height
		end
	end

	local function apply_widget(widget, x, y, width, height)
		if tooltip_text then
			return
		end

		local content = widget and widget.content

		if not content or not content.tooltip_text or content.tooltip_text == "" then
			return
		end

		local hotspot = content.hotspot

		if hotspot and hotspot.is_hover == false then
			return
		end

		tooltip_text = content.tooltip_text
		local widget_x = x + (widget.offset and widget.offset[1] or 0)
		local widget_y = y + (widget.offset and widget.offset[2] or 0)
		local widget_width = width or content.size and content.size[1] or 0
		local widget_height = height or content.size and content.size[2] or 0
		local gap = 20

		if widget_x + widget_width + gap + tooltip_width <= 1920 then
			tooltip_x = widget_x + widget_width + gap
		else
			tooltip_x = widget_x - tooltip_width - gap
		end

		tooltip_y = widget_y + (widget_height - tooltip_height) * 0.5
	end

	for _, grid in ipairs({ self._list_grid, self._actions_grid }) do
		local ui_grid = grid and grid._grid
		local index = ui_grid and type(ui_grid.hovered_grid_index) == "function" and ui_grid:hovered_grid_index()
		local widget = index and grid._grid_widgets and grid._grid_widgets[index]
		local grid_position

		if widget then
			if type(grid.scenegraph_world_position) == "function" then
				grid_position = grid:scenegraph_world_position("grid_content_pivot", grid._render_scale)
			elseif type(grid.scenegraph_position) == "function" then
				grid_position = grid:scenegraph_position("grid_content_pivot")
			end
		end

		apply_widget(widget, grid_position and grid_position[1] or 0, grid_position and grid_position[2] or 0)
	end

	if not tooltip_text and type(self._scenegraph_world_position) == "function" then
		for _, button in ipairs(bottom_buttons) do
			local widget = self._widgets_by_name[button.name]
			local position = self:_scenegraph_world_position(button.name)

			apply_widget(widget, position and position[1] or 0, position and position[2] or 0, button.size[1], button.size[2])
		end

		local description = self._widgets_by_name.description_text
		local description_position = self:_scenegraph_world_position("description_text")

		apply_widget(description, description_position and description_position[1] or 0, description_position and description_position[2] or 0, 900, 50)
	end

	tooltip_element:set_tooltip(
		tooltip_text,
		math.max(0, math.min(tooltip_x, 1920 - tooltip_width)),
		math.max(0, math.min(tooltip_y, 1080 - tooltip_height)),
		tooltip_text ~= nil
	)
end

PresetEditorPanelView.on_enter = function(self)
	PresetEditorPanelView.super.on_enter(self)

	self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 100)

	for _, legend_input in ipairs(definitions.legend_inputs) do
		local on_pressed_callback = legend_input.on_pressed_callback and callback(self, legend_input.on_pressed_callback)

		self._input_legend_element:add_entry(
			legend_input.display_name,
			legend_input.input_action,
			legend_input.visibility_function,
			on_pressed_callback,
			legend_input.alignment
		)
	end

	self._list_grid = self:_add_element(ViewElementGrid, "preset_list", 102, list_grid_settings, "preset_list_pivot")
	self._actions_grid = self:_add_element(ViewElementGrid, "preset_actions", 103, actions_grid_settings, "actions_pivot")
	self._list_grid:set_visibility(true)
	self._actions_grid:set_visibility(true)
	self._tooltip_element = self:_add_element(PresetTooltipElement, "preset_tooltip", 104)
	self._selected_name = nil
	self._rebuilt_scope_key = nil

	self:_rebuild()
end

PresetEditorPanelView.on_exit = function(self)
	PresetEditorPanelView.super.on_exit(self)

	self._list_grid = nil
	self._actions_grid = nil
	self._tooltip_element = nil
	self._character_request_id = self._character_request_id + 1
end

PresetEditorPanelView._rebuild = function(self)
	if not self._list_grid or not self._actions_grid then
		return
	end

	self._scope = mod._preset_panel_get_scope()
	self._character_mode = false
	self._scope_mode = false

	local current_scope_key = scope_key(self._scope)
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

	self._list_grid:present_grid_layout(layout, blueprints, callback(self, "cb_on_preset_pressed"))
	self:_update_preset_selection()

	local widgets_by_name = self._widgets_by_name

	if widgets_by_name.title_text then
		widgets_by_name.title_text.content.title_text = mod:localize("preset_editor_title")
	end

	if widgets_by_name.description_text then
		local text = string.format(
			"%s - %s",
			mod:localize("preset_editor_presets"),
			mod._preset_panel_get_scope_name and mod._preset_panel_get_scope_name() or mod:localize("preset_editor_all_mods")
		)

		widgets_by_name.description_text.content.text = text
		widgets_by_name.description_text.content.original_text = text
	end

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

	if self._scope_mode or not self._selected_name then
		widget.content.selected_text = ""
		return
	end

	widget.content.selected_text = mod:localize("preset_editor_selected", self._selected_name)
end

PresetEditorPanelView._rebuild_actions = function(self)
	if not self._actions_grid then
		return
	end

	self:_update_selected_text()

	local layout = {}

	if self._scope_mode then
		layout[#layout + 1] = {
			widget_type = "info",
			text = mod:localize("preset_editor_select_scope_title"),
		}

		for _, entry in ipairs(mod._preset_panel_get_scope_options()) do
			layout[#layout + 1] = {
				widget_type = "scope_option",
				scope = entry.scope,
				text = entry.display_name,
				tooltip = mod:localize("preset_editor_scope_tooltip"),
			}
		end

		self._actions_grid:present_grid_layout(layout, blueprints, callback(self, "cb_on_scope_option_pressed"))
		self:_update_bottom_buttons()

		return
	end

	if self._character_mode and self._selected_name then
		local loading_layout = {
			{
				widget_type = "info",
				text = mod:localize("preset_editor_character_hint", self._selected_name),
			},
		}
		local request_id = self._character_request_id + 1
		local applied = false

		self._character_request_id = request_id

		local function present_characters(profiles)
			if self._character_request_id ~= request_id or not self._actions_grid then
				return
			end

			applied = true
			layout = table.clone(loading_layout)

			for _, profile in ipairs(profiles) do
				local assigned = mod._preset_panel_is_character_assigned(self._scope, self._selected_name, profile.id)

				local archetype_name = profile.archetype_name or ""
				local character_text = string.format(
					"%s  %s%s",
					assigned and "\226\156\147" or " ",
					tostring(profile.name),
					archetype_name ~= "" and ("  -  " .. archetype_name) or ""
				)

				layout[#layout + 1] = {
					widget_type = "character_toggle",
					id = profile.id,
					name = profile.name,
					archetype_name = archetype_name,
					archetype_icon = profile.archetype_icon,
					text = character_text,
					tooltip = mod:localize("preset_editor_character_tooltip", tostring(profile.name)),
				}
			end

			self._actions_grid:present_grid_layout(layout, blueprints, callback(self, "cb_on_character_pressed"))
			self:_update_bottom_buttons()
		end

		mod._preset_panel_get_characters(present_characters)

		if not applied then
			self._actions_grid:present_grid_layout(loading_layout, blueprints, callback(self, "cb_on_character_pressed"))
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

	self._actions_grid:present_grid_layout(layout, blueprints, callback(self, "cb_on_action_pressed"))
	self:_update_bottom_buttons()
end

PresetEditorPanelView._update_bottom_buttons = function(self)
	local close_widget = self._widgets_by_name.bottom_close

	for _, button in ipairs(bottom_buttons) do
		local widget = self._widgets_by_name[button.name]

		if widget then
			local text_key = button.text_key
			local tooltip_key = button.tooltip_key

			if button.action == "close_back" and (self._scope_mode or self._character_mode) then
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

	self._pending_scope = scope
	self._pending_full_rebuild = true
end

PresetEditorPanelView._handle_close_back = function(self)
	if self._scope_mode then
		self._scope_mode = false
		self._pending_actions_rebuild = true
		return
	end

	if self._character_mode then
		self._character_mode = false
		self._pending_actions_rebuild = true
		return
	end

	Managers.ui:close_view(self.view_name)
end

PresetEditorPanelView.cb_on_preset_pressed = function(self, _, element)
	if not element or not element.name then
		return
	end

	self._selected_name = element.name
	self._character_mode = false
	self._scope_mode = false
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
		self._scope_mode = false
		self._pending_actions_rebuild = true
	elseif action == "back" or action == "close" or action == "close_back" then
		self:_handle_close_back()
	end
end

PresetEditorPanelView.cb_on_bottom_pressed = function(self, action)
	self:cb_on_action_pressed(nil, { action = action })
end

PresetEditorPanelView.cb_on_scope_pressed = function(self)
	self._scope_mode = not self._scope_mode
	self._character_mode = false
	self._pending_actions_rebuild = true
end

PresetEditorPanelView.cb_on_scope_option_pressed = function(self, _, element)
	if not element or type(element.scope) ~= "table" then
		return
	end

	mod._preset_panel_set_scope(self, element.scope)
end

PresetEditorPanelView.cb_on_character_pressed = function(self, widget, element)
	local action = element and element.action

	if action == "back" or action == "close" or action == "close_back" then
		self:_handle_close_back()
		return
	end

	if not element or not element.id then
		return
	end

	local assigned = mod._preset_panel_toggle_character(self._scope, self._selected_name, element.id, element.name)
	local archetype_name = element.archetype_name or ""
	local text = string.format(
		"%s  %s%s",
		assigned and "\226\156\147" or " ",
		tostring(element.name),
		archetype_name ~= "" and ("  -  " .. archetype_name) or ""
	)

	if widget and widget.content then
		widget.content.text = text
		widget.content.original_text = text
	end
end

PresetEditorPanelView._on_back_pressed = function(self)
	self:_handle_close_back()
end

return PresetEditorPanelView
