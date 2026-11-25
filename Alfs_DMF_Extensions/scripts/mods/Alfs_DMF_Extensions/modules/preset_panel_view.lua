local mod = get_mod("Alfs_DMF_Extensions")

local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local ViewElementBase = require("scripts/ui/view_elements/view_element_base")
local ViewElementGrid = require("scripts/ui/view_elements/view_element_grid/view_element_grid")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")

local PORTRAIT_MATERIAL = "content/ui/materials/base/ui_portrait_frame_base"
local PORTRAIT_NO_RENDER = "content/ui/materials/base/ui_portrait_frame_base_no_render"

local function ease(progress)
	return math.easeCubic and math.easeCubic(progress) or progress
end

local function panel_scope_key(scope)
	if scope and scope.kind == "global" then
		return "global"
	end

	return scope and scope.mod_name and ("mod:" .. scope.mod_name) or "unknown"
end

local function make_text_style(font_size, offset, color, alignment)
	local style = table.clone(UIFontSettings.body or UIFontSettings.button_primary)

	style.font_size = font_size
	style.text_horizontal_alignment = alignment or "left"
	style.text_vertical_alignment = "center"
	style.horizontal_alignment = "left"
	style.vertical_alignment = "center"
	style.offset = offset
	style.text_color = color or Color.terminal_text_header(255, true)

	return style
end

local info_font_style = make_text_style(18, { 10, 0, 2 }, Color.terminal_text_header(255, true))
local card_name_style = make_text_style(20, { 94, 2, 3 })
local card_archetype_style = make_text_style(17, { 400, 2, 3 }, Color.ui_grey_light and Color.ui_grey_light(255, true) or Color.terminal_text_header(255, true))
local card_check_style = make_text_style(20, { 60, 2, 3 }, Color.terminal_text_header_selected(255, true), "center")
local tooltip_text_style = make_text_style(18, { 12, 0, 2 }, Color.white(255, true))

tooltip_text_style.size = { 1136, 30 }
tooltip_text_style.word_wrap = false

local selected_text_style = make_text_style(18, { 0, 0, 2 }, Color.terminal_text_header_selected(255, true))

local function init_hotspot_widget(parent, widget, element, callback_name)
	widget.content.hotspot.pressed_callback = callback_name and callback(parent, callback_name, widget, element) or nil
	widget.content.text = element.text or ""
	widget.content.original_text = element.text or ""
	widget.content.tooltip_text = element.tooltip or ""
end

local function clear_portrait(widget)
	local style = widget and widget.style and widget.style.character_portrait
	local material_values = style and style.material_values

	if not material_values then
		return
	end

	material_values.use_placeholder_texture = 1
	material_values.rows = nil
	material_values.columns = nil
	material_values.grid_index = nil
	material_values.texture_icon = nil

	if widget.content then
		widget.content.character_portrait = PORTRAIT_NO_RENDER
	end
end

local function set_portrait(widget, grid_index, rows, columns, render_target)
	local style = widget and widget.style and widget.style.character_portrait
	local material_values = style and style.material_values

	if not material_values then
		return
	end

	material_values.use_placeholder_texture = 0
	material_values.rows = rows
	material_values.columns = columns
	material_values.grid_index = grid_index - 1
	material_values.texture_icon = render_target
end

local function load_portrait(parent, widget, element)
	local profile = element and element.profile
	local ui = Managers and Managers.ui

	if not widget or not profile or not ui or type(ui.load_profile_portrait) ~= "function" then
		return
	end

	widget.content.portrait_load_id = ui:load_profile_portrait(profile, function(grid_index, rows, columns, render_target)
		set_portrait(widget, grid_index, rows, columns, render_target)
	end, { size = { 40, 46 } }, function()
		clear_portrait(widget)
	end)
end

local function unload_portrait(parent, widget)
	local ui = Managers and Managers.ui
	local load_id = widget and widget.content and widget.content.portrait_load_id

	if load_id and ui and type(ui.unload_profile_portrait) == "function" then
		ui:unload_profile_portrait(load_id)
	end

	if widget and widget.content then
		widget.content.portrait_load_id = nil
	end

	clear_portrait(widget)
end

local character_toggle_template = {
	{
		pass_type = "hotspot",
		content_id = "hotspot",
		content = { use_is_focused = true },
	},
	{
		pass_type = "rect",
		style_id = "background",
		style = {
			color = Color.terminal_background(255, true),
		},
		change_function = function(content, style)
			local hotspot = content.hotspot
			local selected = hotspot and hotspot.is_selected
			local hovered = hotspot and (hotspot.is_hover or hotspot.is_focused)

			style.color = selected and Color.terminal_background_gradient_selected(255, true)
				or hovered and Color.terminal_background_gradient(255, true)
				or Color.terminal_background(255, true)
		end,
	},
	{
		pass_type = "texture",
		style_id = "frame",
		value = "content/ui/materials/frames/frame_tile_2px",
		style = {
			color = Color.terminal_corner(255, true),
			scale_to_material = true,
		},
	},
	{
		pass_type = "texture",
		style_id = "character_portrait",
		value = PORTRAIT_MATERIAL,
		value_id = "character_portrait",
		style = {
			horizontal_alignment = "left",
			vertical_alignment = "center",
			size = { 40, 46 },
			offset = { 10, 0, 3 },
			material_values = { use_placeholder_texture = 1 },
		},
	},
	{
		pass_type = "text",
		value_id = "assignment_text",
		style_id = "assignment_text",
		style = card_check_style,
	},
	{
		pass_type = "text",
		value_id = "character_name",
		style_id = "character_name",
		style = card_name_style,
	},
	{
		pass_type = "text",
		value_id = "character_archetype_title",
		style_id = "character_archetype_title",
		style = card_archetype_style,
	},
}

local blueprints = {
	preset_entry = {
		size = { 400, 42 },
		pass_template = ButtonPassTemplates.list_button_with_background,
		init = function(parent, widget, element, callback_name)
			init_hotspot_widget(parent, widget, element, callback_name)
			widget.content.name = element.name
			widget.content.hotspot.is_selected = parent and parent._selected_name == element.name or false
		end,
	},
	action_button = {
		size = { 640, 40 },
		pass_template = ButtonPassTemplates.terminal_button,
		init = init_hotspot_widget,
	},
	scope_option = {
		size = { 640, 40 },
		pass_template = ButtonPassTemplates.terminal_button,
		init = init_hotspot_widget,
	},
	character_toggle = {
		size = { 640, 52 },
		pass_template = character_toggle_template,
		init = function(parent, widget, element, callback_name)
			init_hotspot_widget(parent, widget, element, callback_name)
			widget.content.profile = element.profile
			widget.content.character_portrait = PORTRAIT_MATERIAL
			widget.content.assignment_text = element.assigned and "\226\156\147" or ""
			widget.content.character_name = element.name or ""
			widget.content.character_archetype_title = element.archetype_name or ""
		end,
		load_icon = load_portrait,
		unload_icon = unload_portrait,
		destroy = unload_portrait,
	},
	info = {
		size = { 640, 32 },
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
	popup = {
		parent = "screen",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		size = { 1180, 640 },
		position = { 0, -8, 101 },
	},
	popup_background = {
		parent = "popup",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		size = { 1180, 640 },
		position = { 0, 0, 1 },
	},
	title_divider = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 240, 18 },
		position = { 40, 34, 2 },
	},
	title_text = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 700, 42 },
		position = { 40, 50, 2 },
	},
	description_text = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 760, 44 },
		position = { 40, 96, 2 },
	},
	selected_preset_text = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 700, 24 },
		position = { 40, 142, 2 },
	},
	preset_list_pivot = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 420, 350 },
		position = { 40, 178, 2 },
	},
	actions_pivot = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = { 660, 350 },
		position = { -40, 178, 2 },
	},
	scope_dropdown_pivot = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 760, 220 },
		position = { 40, 142, 3 },
	},
	bottom_actions = {
		parent = "popup",
		vertical_alignment = "bottom",
		horizontal_alignment = "left",
		size = { 1100, 56 },
		position = { 40, -38, 2 },
	},
	bottom_save = {
		parent = "bottom_actions",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 280, 48 },
		position = { 0, 0, 1 },
	},
	bottom_import = {
		parent = "bottom_actions",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 280, 48 },
		position = { 292, 0, 1 },
	},
	bottom_export_current = {
		parent = "bottom_actions",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 280, 48 },
		position = { 584, 0, 1 },
	},
	bottom_close = {
		parent = "bottom_actions",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 80, 48 },
		position = { 1020, 0, 1 },
	},
}

local bottom_buttons = {
	{
		name = "bottom_save",
		action = "save",
		text_key = "preset_editor_save",
		tooltip_key = "preset_editor_save_tooltip",
		size = { 280, 48 },
	},
	{
		name = "bottom_import",
		action = "import",
		text_key = "preset_editor_import",
		tooltip_key = "preset_editor_import_tooltip",
		size = { 280, 48 },
	},
	{
		name = "bottom_export_current",
		action = "export_current",
		text_key = "preset_editor_export_current",
		tooltip_key = "preset_editor_export_current_tooltip",
		size = { 280, 48 },
	},
	{
		name = "bottom_close",
		action = "close_back",
		text_key = "preset_editor_close",
		tooltip_key = "preset_editor_close_tooltip",
		size = { 80, 48 },
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
			horizontal_alignment = "left",
			vertical_alignment = "top",
			size = { 1160, 44 },
			position = { 380, 1010, 105 },
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
				color = Color.black(70, true),
			},
		},
	}, "screen"),
	popup_background = UIWidget.create_definition({
		{
			pass_type = "rect",
			style = {
				color = Color.terminal_background(215, true),
			},
		},
		{
			pass_type = "texture",
			value = "content/ui/materials/frames/frame_tile_2px",
			style = {
				color = Color.terminal_corner(255, true),
				scale_to_material = true,
			},
		},
	}, "popup_background"),
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
	}, { 760, 44 }),
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
	scrollbar_width = 6,
	no_resource_rendering = true,
	use_terminal_background = true,
	ignore_divider_height = true,
	title_height = 0,
	top_padding = 8,
	bottom_chin = 8,
	grid_spacing = { 6, 6 },
	grid_size = { 420, 350 },
	mask_size = { 420, 350 },
	edge_padding = 14,
}

local actions_grid_settings = {
	scrollbar_width = 6,
	no_resource_rendering = true,
	use_terminal_background = true,
	ignore_divider_height = true,
	title_height = 0,
	top_padding = 8,
	bottom_chin = 8,
	grid_spacing = { 6, 6 },
	grid_size = { 660, 350 },
	mask_size = { 660, 350 },
	edge_padding = 14,
}

local scope_grid_settings = {
	scrollbar_width = 6,
	no_resource_rendering = true,
	use_terminal_background = true,
	ignore_divider_height = true,
	title_height = 0,
	top_padding = 6,
	bottom_chin = 6,
	grid_spacing = { 4, 4 },
	grid_size = { 760, 220 },
	mask_size = { 760, 220 },
	edge_padding = 12,
}

local legend_inputs = {
	{
		input_action = "back",
		on_pressed_callback = "_on_back_pressed",
		display_name = "loc_class_selection_button_back",
		alignment = "left_alignment",
	},
}

local animation_definitions = {
	on_enter = {
		{
			name = "fade_in",
			start_time = 0,
			end_time = 0.18,
			init = function(parent)
				parent._render_settings.alpha_multiplier = 0
			end,
			update = function(parent, _, _, _, progress)
				parent._render_settings.alpha_multiplier = ease(progress)
			end,
			on_complete = function(parent)
				parent._render_settings.alpha_multiplier = 1
			end,
		},
	},
	on_exit = {
		{
			name = "fade_out",
			start_time = 0,
			end_time = 0.14,
			init = function(parent)
				parent._render_settings.alpha_multiplier = 1
			end,
			update = function(parent, _, _, _, progress)
				parent._render_settings.alpha_multiplier = 1 - ease(progress)
			end,
			on_complete = function(parent)
				parent._render_settings.alpha_multiplier = 0
			end,
		},
	},
}

local definitions = {
	scenegraph_definition = scenegraph_definition,
	widget_definitions = widget_definitions,
	blueprints = blueprints,
	legend_inputs = legend_inputs,
	list_grid_settings = list_grid_settings,
	actions_grid_settings = actions_grid_settings,
	scope_grid_settings = scope_grid_settings,
	animations = animation_definitions,
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

	self._pass_draw = true
	self._pass_input = false
	self._allow_close_hotkey = true
	self._scope = nil
	self._selected_name = nil
	self._rebuilt_scope_key = nil
	self._character_mode = false
	self._scope_mode = false
	self._character_request_id = 0
	self._pending_actions_rebuild = false
	self._pending_full_rebuild = false
	self._pending_scope = nil
	self._open_anim_id = nil
	self._close_anim_id = nil

	local description = self._widgets_by_name.description_text

	if description then
		description.content.hotspot.pressed_callback = callback(self, "cb_on_scope_pressed")
		description.content.tooltip_text = mod:localize("preset_editor_scope_tooltip")
	end

	for _, button in ipairs(bottom_buttons) do
		local widget = self._widgets_by_name[button.name]

		if widget and widget.content.hotspot then
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

	local function check_widget(widget)
		local content = widget and widget.content

		if not content or not content.tooltip_text or content.tooltip_text == "" then
			return
		end

		local hotspot = content.hotspot

		if not hotspot or not (hotspot.is_hover or hotspot.is_focused) then
			return
		end

		tooltip_text = content.tooltip_text
	end

	if not self._scope_mode then
		for _, grid in ipairs({ self._list_grid, self._actions_grid }) do
			local ui_grid = grid and grid._grid
			local index = ui_grid and type(ui_grid.hovered_grid_index) == "function" and ui_grid:hovered_grid_index()
			local widget = index and grid._grid_widgets and grid._grid_widgets[index]

			check_widget(widget)
		end
	else
		local ui_grid = self._scope_grid and self._scope_grid._grid
		local index = ui_grid and type(ui_grid.hovered_grid_index) == "function" and ui_grid:hovered_grid_index()
		local widget = index and self._scope_grid._grid_widgets and self._scope_grid._grid_widgets[index]

		check_widget(widget)
	end

	for _, button in ipairs(bottom_buttons) do
		check_widget(self._widgets_by_name[button.name])
	end

	tooltip_element:set_tooltip(tooltip_text, 0, 0, tooltip_text ~= nil)
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
	self._scope_grid = self:_add_element(ViewElementGrid, "scope_dropdown", 104, scope_grid_settings, "scope_dropdown_pivot")
	self._tooltip_element = self:_add_element(PresetTooltipElement, "preset_tooltip", 105)
	self._selected_name = nil
	self._rebuilt_scope_key = nil

	self:_rebuild()
	self._open_anim_id = self:_start_animation("on_enter", self._widgets_by_name, self)
end

PresetEditorPanelView.on_exit = function(self)
	PresetEditorPanelView.super.on_exit(self)

	self._open_anim_id = nil
	self._close_anim_id = nil
	self._list_grid = nil
	self._actions_grid = nil
	self._scope_grid = nil
	self._tooltip_element = nil
	self._character_request_id = self._character_request_id + 1
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
	if not self._list_grid or not self._actions_grid or not self._scope_grid then
		return
	end

	self._scope = mod._preset_panel_get_scope()
	self._character_mode = false
	self._scope_mode = false

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
	if not self._actions_grid or not self._scope_grid then
		return
	end

	self:_update_selected_text()

	if self._scope_mode then
		self._actions_grid:set_visibility(false)
		self._scope_grid:set_visibility(true)

		local layout = {
			{
				widget_type = "info",
				text = mod:localize("preset_editor_select_scope_title"),
			},
		}

		for _, entry in ipairs(mod._preset_panel_get_scope_options()) do
			layout[#layout + 1] = {
				widget_type = "scope_option",
				scope = entry.scope,
				text = entry.display_name,
				tooltip = mod:localize("preset_editor_scope_tooltip"),
			}
		end

		self._scope_grid:present_grid_layout(layout, blueprints, callback(self, "cb_on_scope_option_pressed"))
		self:_update_bottom_buttons()

		return
	end

	self._actions_grid:set_visibility(true)
	self._scope_grid:set_visibility(false)

	local layout = {}

	if self._character_mode and self._selected_name then
		layout[1] = {
			widget_type = "info",
			text = mod:localize("preset_editor_character_hint", self._selected_name),
		}

		local request_id = self._character_request_id + 1
		local applied = false

		self._character_request_id = request_id

		local function present_characters(profiles)
			if self._character_request_id ~= request_id or not self._actions_grid then
				return
			end

			applied = true
			layout = {
				{
					widget_type = "info",
					text = mod:localize("preset_editor_character_hint", self._selected_name),
				},
			}

			for _, profile in ipairs(profiles) do
				layout[#layout + 1] = {
					widget_type = "character_toggle",
					id = profile.id,
					name = profile.name,
					archetype_name = profile.archetype_name,
					profile = profile.profile,
					assigned = mod._preset_panel_is_character_assigned(self._scope, self._selected_name, profile.id),
					text = profile.name,
					tooltip = mod:localize("preset_editor_character_tooltip", tostring(profile.name)),
				}
			end

			self._actions_grid:present_grid_layout(layout, blueprints, callback(self, "cb_on_character_pressed"))
			self:_update_bottom_buttons()
		end

		mod._preset_panel_get_characters(present_characters)

		if not applied then
			self._actions_grid:present_grid_layout(layout, blueprints, callback(self, "cb_on_character_pressed"))
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

return PresetEditorPanelView
