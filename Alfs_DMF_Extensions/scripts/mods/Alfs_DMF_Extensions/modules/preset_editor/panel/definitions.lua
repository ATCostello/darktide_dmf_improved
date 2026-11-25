local mod = get_mod("Alfs_DMF_Extensions")

local DropdownPassTemplates = require("scripts/ui/pass_templates/dropdown_pass_templates")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local Styles = mod._preset_panel_styles
local Blueprints = mod._preset_panel_blueprints
local Portraits = mod._preset_panel_portraits

local Definitions = mod._preset_panel_definitions or {}
mod._preset_panel_definitions = Definitions

local POPUP_WIDTH = 1180
local POPUP_HEIGHT = 780
local SCOPE_DROPDOWN_WIDTH = 760
local SCOPE_ROW_HEIGHT = 40
local SCOPE_MAX_VISIBLE_OPTIONS = 3

Definitions.POPUP_WIDTH = POPUP_WIDTH
Definitions.POPUP_HEIGHT = POPUP_HEIGHT
Definitions.SCOPE_DROPDOWN_SIZE = { SCOPE_DROPDOWN_WIDTH, SCOPE_ROW_HEIGHT }
Definitions.SCOPE_MAX_VISIBLE_OPTIONS = SCOPE_MAX_VISIBLE_OPTIONS
Definitions.SCOPE_DROPDOWN_ROWS = SCOPE_MAX_VISIBLE_OPTIONS

local function ease(progress)
	return math.easeCubic and math.easeCubic(progress) or progress
end

local function text_style(font_size, offset, text_color, alignment, size)
	return Styles.make_text_style(font_size, offset, text_color, alignment, size)
end

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
		size = { POPUP_WIDTH, POPUP_HEIGHT },
		position = { 0, -8, 101 },
	},
	popup_background = {
		parent = "popup",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		size = { POPUP_WIDTH, POPUP_HEIGHT },
		position = { 0, 0, -2 },
	},
	popup_frame = {
		parent = "popup",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		size = { POPUP_WIDTH, POPUP_HEIGHT },
		position = { 0, 0, -1 },
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
	scope_dropdown = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { SCOPE_DROPDOWN_WIDTH, SCOPE_ROW_HEIGHT },
		position = { 40, 150, 4 },
	},
	selected_preset_text = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = { 320, 40 },
		position = { -40, 150, 2 },
	},
	list_frame = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 420, 460 },
		position = { 40, 210, 2 },
	},
	actions_frame = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = { 660, 460 },
		position = { -40, 210, 2 },
	},
	preset_list_pivot = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 420, 460 },
		position = { 40, 210, 2 },
	},
	actions_pivot = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = { 660, 460 },
		position = { -40, 210, 2 },
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
		size = { 260, 48 },
		position = { 0, 0, 1 },
	},
	bottom_import = {
		parent = "bottom_actions",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 260, 48 },
		position = { 280, 0, 1 },
	},
	bottom_export_current = {
		parent = "bottom_actions",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 260, 48 },
		position = { 560, 0, 1 },
	},
	bottom_close = {
		parent = "bottom_actions",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 260, 48 },
		position = { 840, 0, 1 },
	},
}

local bottom_buttons = {
	{
		name = "bottom_save",
		action = "save",
		text_key = "preset_editor_save",
		tooltip_key = "preset_editor_save_tooltip",
		size = { 260, 48 },
	},
	{
		name = "bottom_import",
		action = "import",
		text_key = "preset_editor_import",
		tooltip_key = "preset_editor_import_tooltip",
		size = { 260, 48 },
	},
	{
		name = "bottom_export_current",
		action = "export_current",
		text_key = "preset_editor_export_current",
		tooltip_key = "preset_editor_export_current_tooltip",
		size = { 260, 48 },
	},
	{
		name = "bottom_close",
		action = "close_back",
		text_key = "preset_editor_close",
		tooltip_key = "preset_editor_close_tooltip",
		size = { 260, 48 },
	},
}

local widget_draw_order = {
	"popup_background",
	"popup_frame",
	"list_frame",
	"actions_frame",
	"title_divider",
	"title_text",
	"description_text",
	"scope_dropdown",
	"selected_preset_text",
	"bottom_save",
	"bottom_import",
	"bottom_export_current",
	"bottom_close",
}

local tooltip_background_color = Styles.copy_color(Styles.COLORS.tooltip_background)
local tooltip_frame_color = Styles.copy_color(Styles.COLORS.frame)
local tooltip_text_color = Styles.copy_color(Styles.COLORS.text)

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
					color = Styles.copy_color(tooltip_background_color),
				},
				change_function = function(content, style)
					Styles.set_color(style.color, tooltip_background_color)
					style.color[1] = content.visible and 230 or 0
				end,
			},
			{
				pass_type = "texture",
				style_id = "frame",
				value = "content/ui/materials/frames/frame_tile_2px",
				style = {
					color = Styles.copy_color(tooltip_frame_color),
					scale_to_material = true,
				},
				change_function = function(content, style)
					Styles.set_color(style.color, tooltip_frame_color)
					style.color[1] = content.visible and 255 or 0
				end,
			},
			{
				pass_type = "text",
				value_id = "tooltip_text",
				style_id = "tooltip_text",
				style = text_style(18, { 12, 0, 2 }, tooltip_text_color, "left", { 1136, 30 }),
				change_function = function(content, style)
					Styles.set_color(style.text_color, tooltip_text_color)
					style.text_color[1] = content.visible and 255 or 0
				end,
			},
		}, "tooltip"),
	},
}

local title_text_style = table.clone(UIFontSettings.header_1 or UIFontSettings.header_3 or UIFontSettings.button_primary or {})
title_text_style.text_horizontal_alignment = "left"
title_text_style.text_vertical_alignment = "center"
title_text_style.text_color = Styles.copy_color(Styles.COLORS.normal)
title_text_style.offset = { 0, 0, 2 }

local selected_text_style = text_style(18, { 0, 0, 2 }, Styles.COLORS.normal, "right", { 320, 40 })

local dropdown_passes = Styles.customize_dropdown(DropdownPassTemplates.settings_dropdown(
	SCOPE_DROPDOWN_WIDTH,
	SCOPE_ROW_HEIGHT,
	SCOPE_DROPDOWN_WIDTH,
	SCOPE_MAX_VISIBLE_OPTIONS,
	false
))

local widget_definitions = {
	popup_background = UIWidget.create_definition({
		{
			pass_type = "texture_uv",
			style_id = "terminal",
			value = "content/ui/materials/backgrounds/terminal_basic",
			style = {
				color = Styles.COLORS.popup_background,
				horizontal_alignment = "center",
				vertical_alignment = "center",
				scale_to_material = true,
				offset = { 0, 0, 0 },
				size = { POPUP_WIDTH, POPUP_HEIGHT },
				size_addition = { 0, 0 },
				uvs = { { 0, 0 }, { 1, 1 } },
			},
		},
	}, "popup_background"),
	popup_frame = UIWidget.create_definition(Styles.frame_passes("content/ui/materials/frames/frame_tile_2px", Styles.COLORS.frame), "popup_frame"),
	list_frame = UIWidget.create_definition(Styles.frame_passes("content/ui/materials/frames/frame_tile_2px", Styles.COLORS.frame), "list_frame"),
	actions_frame = UIWidget.create_definition(Styles.frame_passes("content/ui/materials/frames/frame_tile_2px", Styles.COLORS.frame), "actions_frame"),
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
			style = title_text_style,
		},
	}, "title_text"),
	description_text = UIWidget.create_definition({
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			style = text_style(18, { 10, 0, 3 }, Styles.COLORS.text, "left", { 740, 44 }),
		},
	}, "description_text", {
		text = "",
	}, { 760, 44 }),
	scope_dropdown = UIWidget.create_definition(dropdown_passes, "scope_dropdown", {
		options = {},
		options_by_value = {},
		num_visible_options = SCOPE_MAX_VISIBLE_OPTIONS,
		selected_index = nil,
		exclusive_focus = false,
		grow_downwards = true,
		value_text = "",
		internal_value = "global",
		disabled = false,
	}, Definitions.SCOPE_DROPDOWN_SIZE),
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
	widget_definitions[button.name] = UIWidget.create_definition(Styles.button_passes("center", 20), button.name, {
		text = mod:localize(button.text_key),
		original_text = mod:localize(button.text_key),
		tooltip_text = mod:localize(button.tooltip_key),
		hotspot = {},
	}, button.size)
end

local function grid_settings(width, height)
	return {
		scrollbar_width = 6,
		no_resource_rendering = true,
		use_terminal_background = false,
		hide_background = true,
		hide_dividers = true,
		ignore_divider_height = true,
		title_height = 0,
		top_padding = 16,
		bottom_chin = 16,
		grid_spacing = { 6, 6 },
		grid_size = { width, height },
		mask_size = { width, height - 26 },
		edge_padding = 14,
	}
end

Definitions.scenegraph_definition = scenegraph_definition
Definitions.widget_definitions = widget_definitions
Definitions.widget_draw_order = widget_draw_order
Definitions.tooltip_definitions = tooltip_definitions
Definitions.blueprints = Blueprints
Definitions.bottom_buttons = bottom_buttons
Definitions.list_grid_settings = grid_settings(420, 460)
Definitions.actions_grid_settings = grid_settings(660, 460)
Definitions.legend_inputs = {
	{
		input_action = "back",
		on_pressed_callback = "_on_back_pressed",
		display_name = "loc_class_selection_button_back",
		alignment = "left_alignment",
	},
}
Definitions.animations = {
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

Definitions.portraits = Portraits
Definitions.styles = Styles

return Definitions
