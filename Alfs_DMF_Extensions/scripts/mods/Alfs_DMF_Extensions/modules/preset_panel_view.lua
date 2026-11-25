local mod = get_mod("Alfs_DMF_Extensions")

local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
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

local function init_hotspot_widget(parent, widget, element, callback_name)
	widget.content.hotspot.pressed_callback = callback_name and callback(parent, callback_name, widget, element) or nil
	widget.content.text = element.text or ""
	widget.content.original_text = element.text or ""
end

local blueprints = {
	preset_entry = {
		size = { 480, 58 },
		pass_template = ButtonPassTemplates.list_button_with_background,
		init = init_hotspot_widget,
	},
	action_button = {
		size = { 980, 56 },
		pass_template = ButtonPassTemplates.terminal_button,
		init = init_hotspot_widget,
	},
	character_toggle = {
		size = { 980, 54 },
		pass_template = ButtonPassTemplates.list_button_with_background,
		init = init_hotspot_widget,
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
		size = { 1600, 40 },
		position = { 140, 190, 101 },
	},
	preset_list_pivot = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 500, 720 },
		position = { 140, 240, 101 },
	},
	actions_pivot = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = { 1000, 720 },
		position = { -180, 240, 101 },
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
	description_text = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "description_text",
			style_id = "description_text",
			style = info_font_style,
		},
	}, "description_text"),
}

local list_grid_settings = {
	scrollbar_width = 8,
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
	use_terminal_background = true,
	ignore_divider_height = true,
	title_height = 0,
	top_padding = 12,
	bottom_chin = 12,
	grid_spacing = { 10, 10 },
	grid_size = { 980, 720 },
	mask_size = { 1000, 720 },
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

PresetEditorPanelView = class("PresetEditorPanelView", "BaseView")

PresetEditorPanelView.init = function(self, settings)
	PresetEditorPanelView.super.init(self, definitions, settings)

	self._pass_draw = false
	self._pass_input = false
	self._scope = nil
	self._selected_name = nil
	self._character_mode = false
	self._character_request_id = 0
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

	self:_rebuild()
end

PresetEditorPanelView.on_exit = function(self)
	PresetEditorPanelView.super.on_exit(self)

	self._list_grid = nil
	self._actions_grid = nil
	self._character_request_id = self._character_request_id + 1
end

PresetEditorPanelView._rebuild = function(self)
	if not self._list_grid or not self._actions_grid then
		return
	end

	self._scope = mod._preset_panel_get_scope()
	self._character_mode = false

	local names = mod._preset_panel_get_names(self._scope)
	local selected_is_valid = false

	for _, name in ipairs(names) do
		if name == self._selected_name then
			selected_is_valid = true
			break
		end
	end

	if not selected_is_valid then
		self._selected_name = names[1]
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
			}
		end
	end

	self._list_grid:present_grid_layout(layout, blueprints, callback(self, "cb_on_preset_pressed"))

	local widgets_by_name = self._widgets_by_name

	if widgets_by_name.title_text then
		widgets_by_name.title_text.content.title_text = mod:localize("preset_editor_title")
	end

	if widgets_by_name.description_text then
		widgets_by_name.description_text.content.description_text = string.format(
			"%s - %s",
			mod:localize("preset_editor_presets"),
			mod._preset_panel_get_scope_name and mod._preset_panel_get_scope_name() or mod:localize("preset_editor_all_mods")
		)
	end

	self:_rebuild_actions()
end

PresetEditorPanelView._rebuild_actions = function(self)
	if not self._actions_grid then
		return
	end

	local layout = {}

	if self._character_mode and self._selected_name then
		layout[#layout + 1] = {
			widget_type = "info",
			text = mod:localize("preset_editor_character_hint", self._selected_name),
		}
		layout[#layout + 1] = {
			widget_type = "action_button",
			action = "back",
			text = mod:localize("preset_editor_back"),
		}

		local request_id = self._character_request_id + 1
		self._character_request_id = request_id

		mod._preset_panel_get_characters(function(profiles)
			if self._character_request_id ~= request_id or not self._actions_grid then
				return
			end

			local character_layout = table.clone(layout)

			for _, profile in ipairs(profiles) do
				local assigned = mod._preset_panel_is_character_assigned(self._scope, self._selected_name, profile.id)

				character_layout[#character_layout + 1] = {
					widget_type = "character_toggle",
					id = profile.id,
					name = profile.name,
					text = string.format(
						"%s  %s",
						assigned and "\226\156\147" or " ",
						tostring(profile.name)
					),
				}
			end

			self._actions_grid:present_grid_layout(character_layout, blueprints, callback(self, "cb_on_character_pressed"))
		end)

		return
	end

	if self._selected_name then
		layout[#layout + 1] = {
			widget_type = "info",
			text = mod:localize("preset_editor_selected", self._selected_name),
		}
		layout[#layout + 1] = {
			widget_type = "action_button",
			action = "apply",
			text = mod:localize("preset_editor_apply"),
		}
		layout[#layout + 1] = {
			widget_type = "action_button",
			action = "export",
			text = mod:localize("preset_editor_export"),
		}
		layout[#layout + 1] = {
			widget_type = "action_button",
			action = "characters",
			text = mod:localize("preset_editor_assign"),
		}
		layout[#layout + 1] = {
			widget_type = "action_button",
			action = "delete",
			text = mod:localize("preset_editor_delete"),
		}
	end

	layout[#layout + 1] = {
		widget_type = "action_button",
		action = "save",
		text = mod:localize("preset_editor_save"),
	}
	layout[#layout + 1] = {
		widget_type = "action_button",
		action = "import",
		text = mod:localize("preset_editor_import"),
	}
	layout[#layout + 1] = {
		widget_type = "action_button",
		action = "export_current",
		text = mod:localize("preset_editor_export_current"),
	}
	layout[#layout + 1] = {
		widget_type = "action_button",
		action = "close",
		text = mod:localize("preset_editor_close"),
	}

	self._actions_grid:present_grid_layout(layout, blueprints, callback(self, "cb_on_action_pressed"))
end

PresetEditorPanelView.cb_on_preset_pressed = function(self, _, element)
	if not element or not element.name then
		return
	end

	self._selected_name = element.name
	self._character_mode = false
	self:_rebuild_actions()
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
		self:_rebuild_actions()
	elseif action == "back" then
		self._character_mode = false
		self:_rebuild_actions()
	elseif action == "close" then
		Managers.ui:close_view(self.view_name)
	end
end

PresetEditorPanelView.cb_on_character_pressed = function(self, _, element)
	if not element or not element.id then
		return
	end

	mod._preset_panel_toggle_character(self._scope, self._selected_name, element.id, element.name)
	self:_rebuild_actions()
end

PresetEditorPanelView._on_back_pressed = function(self)
	if self._character_mode then
		self._character_mode = false
		self:_rebuild_actions()
		return
	end

	Managers.ui:close_view(self.view_name)
end

return PresetEditorPanelView
