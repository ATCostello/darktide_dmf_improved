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
local POPUP_BORDER_WIDTH = POPUP_WIDTH + 10
local POPUP_BORDER_HEIGHT = POPUP_HEIGHT + 30
local POPUP_BACKING_WIDTH = POPUP_BORDER_WIDTH
local POPUP_BACKING_HEIGHT = POPUP_BORDER_HEIGHT
local SCOPE_DROPDOWN_WIDTH = 504
local SCOPE_ROW_HEIGHT = 30
local SCOPE_MAX_VISIBLE_OPTIONS = 6
local ACTIONS_LIST_HEIGHT = 499

Definitions.POPUP_WIDTH = POPUP_WIDTH
Definitions.POPUP_HEIGHT = POPUP_HEIGHT
Definitions.POPUP_BORDER_WIDTH = POPUP_BORDER_WIDTH
Definitions.POPUP_BORDER_HEIGHT = POPUP_BORDER_HEIGHT
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
	popup_backing_box = {
		parent = "popup",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		size = { POPUP_BACKING_WIDTH, POPUP_BACKING_HEIGHT },
		position = { 0, 0, -3 },
	},
	popup_background = {
		parent = "popup",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		size = { POPUP_BORDER_WIDTH, POPUP_BORDER_HEIGHT },
		position = { 0, 0, -2 },
	},
	popup_frame = {
		parent = "popup",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		size = { POPUP_BORDER_WIDTH, POPUP_BORDER_HEIGHT },
		position = { 0, 0, -1 },
	},
	title_divider = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 240, 18 },
		position = { 40, 75, 2 },
	},
	title_text = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 700, 42 },
		position = { 40, 28, 2 },
	},
	header_rule = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = { 1100, 1 },
		position = { 0, 142, 2 },
	},
	bottom_rule = {
		parent = "popup",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = { 1100, 1 },
		position = { 0, -100, 2 },
	},
	scope_dropdown = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { SCOPE_DROPDOWN_WIDTH, SCOPE_ROW_HEIGHT },
		position = { 40, 96, 4 },
	},
	selected_preset_text = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = { 260, 40 },
		position = { -40, 96, 2 },
	},
	list_frame = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 420, 531 },
		position = { 40, 150, 2 },
	},
	actions_frame = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = { 660, 531 },
		position = { -40, 150, 2 },
	},
	preset_list_pivot = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = { 404, 499 },
		position = { 48, 166, 2 },
	},
	actions_pivot = {
		parent = "popup",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = { 644, ACTIONS_LIST_HEIGHT },
		position = { -48, 166, 2 },
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
	"popup_backing_box",
	"popup_background",
	"popup_frame",
	"list_frame",
	"actions_frame",
	"title_divider",
	"title_text",
	"header_rule",
	"bottom_rule",
	"scope_dropdown",
	"selected_preset_text",
	"bottom_save",
	"bottom_import",
	"bottom_export_current",
	"bottom_close",
}

local tooltip_background_color = Styles.copy_color(Styles.COLORS.tooltip_background)
local tooltip_gradient_color = Styles.copy_color(Styles.COLORS.tooltip_gradient)
local tooltip_frame_color = Styles.copy_color(Styles.COLORS.frame)
local tooltip_text_color = Styles.copy_color(Styles.COLORS.text)
local tooltip_accent_color = Styles.copy_color(Styles.COLORS.normal)
local tooltip_cog_color = Styles.copy_color(Styles.COLORS.normal)

tooltip_cog_color[1] = 45

local function tooltip_color_change(color, visible_alpha)
	return function(content, style)
		Styles.set_color(style.color, color)
		style.color[1] = content.visible and (visible_alpha or color[1]) or 0
	end
end

local tooltip_shadow_pass = Styles.shadow_pass("tooltip_shadow", { 12, 12 }, Styles.COLORS.tooltip_shadow)
tooltip_shadow_pass.change_function = tooltip_color_change(Styles.COLORS.tooltip_shadow, 210)

local tooltip_inner_shadow_pass = Styles.inner_shadow_pass("tooltip_inner_shadow")
tooltip_inner_shadow_pass.change_function = tooltip_color_change(Styles.COLORS.inner_shadow, 150)

local tooltip_text_style = text_style(16, { 18, 0, 4 }, tooltip_text_color, "left", { 300, 30 })
tooltip_text_style.font_type = "machine_medium"

local tooltip_definitions = {
	scenegraph_definition = {
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
		tooltip = {
			parent = "popup",
			horizontal_alignment = "right",
			vertical_alignment = "top",
			size = { 380, 44 },
			position = { -40, 28, 5 },
		},
	},
	widget_definitions = {
		tooltip = UIWidget.create_definition({
			tooltip_shadow_pass,
			{
				pass_type = "texture",
				style_id = "background",
				value = "content/ui/materials/backgrounds/default_square",
				style = {
					color = Styles.copy_color(tooltip_background_color),
					scale_to_material = true,
					offset = { 0, 0, 0 },
				},
				change_function = tooltip_color_change(tooltip_background_color, 250),
			},
			{
				pass_type = "texture",
				style_id = "gradient",
				value = "content/ui/materials/gradients/gradient_vertical",
				style = {
					color = Styles.copy_color(tooltip_gradient_color),
					scale_to_material = true,
					offset = { 0, 0, 1 },
				},
				change_function = tooltip_color_change(tooltip_gradient_color, 80),
			},
			tooltip_inner_shadow_pass,
			{
				pass_type = "texture",
				style_id = "top_line",
				value = "content/ui/materials/dividers/horizontal_dynamic_upper",
				style = {
					color = Styles.copy_color(tooltip_frame_color),
					horizontal_alignment = "center",
					vertical_alignment = "top",
					scale_to_material = true,
					size = { 380, 6 },
					offset = { 0, 0, 1 },
				},
				change_function = tooltip_color_change(tooltip_frame_color, 150),
			},
			{
				pass_type = "texture",
				style_id = "bottom_line",
				value = "content/ui/materials/dividers/horizontal_dynamic_lower",
				style = {
					color = Styles.copy_color(tooltip_frame_color),
					horizontal_alignment = "center",
					vertical_alignment = "bottom",
					scale_to_material = true,
					size = { 380, 6 },
					offset = { 0, 0, 1 },
				},
				change_function = tooltip_color_change(tooltip_frame_color, 150),
			},
			{
				pass_type = "texture",
				style_id = "frame",
				value = "content/ui/materials/frames/frame_tile_2px",
				style = {
					color = Styles.copy_color(tooltip_frame_color),
					scale_to_material = true,
					offset = { 0, 0, 2 },
				},
				change_function = tooltip_color_change(tooltip_frame_color, 255),
			},
			{
				pass_type = "texture",
				style_id = "corner",
				value = "content/ui/materials/frames/frame_corner_2px",
				style = {
					color = Styles.copy_color(tooltip_frame_color),
					scale_to_material = true,
					offset = { 0, 0, 2 },
				},
				change_function = tooltip_color_change(tooltip_frame_color, 255),
			},
			{
				pass_type = "rect",
				style_id = "accent_left",
				style = {
					color = Styles.copy_color(tooltip_accent_color),
					horizontal_alignment = "left",
					vertical_alignment = "center",
					size = { 4, 24 },
					offset = { 6, 0, 3 },
				},
				change_function = tooltip_color_change(tooltip_accent_color, 180),
			},
			{
				pass_type = "rect",
				style_id = "accent_right",
				style = {
					color = Styles.copy_color(tooltip_accent_color),
					horizontal_alignment = "right",
					vertical_alignment = "center",
					size = { 4, 24 },
					offset = { -6, 0, 3 },
				},
				change_function = tooltip_color_change(tooltip_accent_color, 180),
			},
			{
				pass_type = "slug_icon",
				style_id = "cog",
				value = "content/ui/vector_textures/symbols/cog_skull_01",
				style = {
					color = Styles.copy_color(tooltip_cog_color),
					horizontal_alignment = "right",
					vertical_alignment = "center",
					size = { 28, 28 },
					offset = { -8, 0, 4 },
				},
				change_function = tooltip_color_change(tooltip_cog_color, 45),
			},
			{
				pass_type = "text",
				value_id = "tooltip_text",
				style_id = "tooltip_text",
				style = tooltip_text_style,
				change_function = function(content, style)
					Styles.set_color(style.text_color, tooltip_text_color)
					style.text_color[1] = content.visible and 255 or 0
				end,
			},
		}, "tooltip"),
	},
}

local title_text_style =
	table.clone(UIFontSettings.header_1 or UIFontSettings.header_3 or UIFontSettings.button_primary or {})
title_text_style.text_horizontal_alignment = "left"
title_text_style.text_vertical_alignment = "center"
title_text_style.text_color = Styles.copy_color(Styles.COLORS.title)
title_text_style.offset = { 0, 0, 2 }

local selected_text_style = text_style(18, { 0, 0, 2 }, Styles.COLORS.normal, "right", { 260, 40 })

local dropdown_passes = Styles.customize_dropdown(
	DropdownPassTemplates.settings_dropdown(
		SCOPE_DROPDOWN_WIDTH,
		SCOPE_ROW_HEIGHT,
		SCOPE_DROPDOWN_WIDTH,
		SCOPE_MAX_VISIBLE_OPTIONS,
		false
	)
)

local popup_background_style = {
	horizontal_alignment = "center",
	vertical_alignment = "center",
	scale_to_material = true,
	offset = { 0, 0, 0 },
	size = { POPUP_BORDER_WIDTH, POPUP_BORDER_HEIGHT },
	size_addition = { 18, 24 },
	color = Color.terminal_grid_background(255, true),
}

local backing_solid_color = Color.terminal_background and Color.terminal_background(255, true)
	or Color.terminal_grid_background(255, true)
local backing_gradient_color = Color.terminal_background_gradient and Color.terminal_background_gradient(0, true)
	or Color.terminal_grid_background(0, true)
local backing_cog_color = Styles.copy_color(Styles.COLORS.normal)

backing_cog_color[1] = 25

local popup_backing_passes = {
	Styles.shadow_pass("popup_shadow", { 24, 24 }, Styles.COLORS.popup_shadow),
	{
		pass_type = "rect",
		style_id = "solid",
		style = {
			horizontal_alignment = "center",
			vertical_alignment = "center",
			offset = { 0, 0, 0 },
			color = backing_solid_color,
		},
	},
	{
		pass_type = "texture",
		style_id = "gradient",
		value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
		style = {
			horizontal_alignment = "center",
			vertical_alignment = "center",
			scale_to_material = true,
			size_addition = { 150, -2 },
			offset = { -20, 0, 1 },
			color = backing_gradient_color,
		},
	},
	Styles.inner_shadow_pass("popup_inner_shadow"),
	{
		pass_type = "slug_icon",
		style_id = "settings_cog",
		value = "content/ui/vector_textures/symbols/cog_skull_01",
		style = {
			horizontal_alignment = "right",
			vertical_alignment = "center",
			size = { 360, 360 },
			offset = { -40, 0, 2 },
			color = backing_cog_color,
		},
	},
}

for _, pass in
	ipairs(Styles.frame_passes("content/ui/materials/frames/frame_tile_2px", Styles.COLORS.frame, Styles.COLORS.corner))
do
	popup_backing_passes[#popup_backing_passes + 1] = pass
end

local function divider_pass(material, vertical_alignment, height, offset_y)
	return {
		pass_type = "texture",
		style_id = "frame_" .. vertical_alignment,
		value = material,
		style = {
			horizontal_alignment = "center",
			vertical_alignment = vertical_alignment,
			scale_to_material = true,
			size = { POPUP_BORDER_WIDTH + 75, height + 50 },
			size_addition = { 0, 0 },
			offset = { 0, offset_y, 3 },
		},
	}
end

local widget_definitions = {
	popup_backing_box = UIWidget.create_definition(
		popup_backing_passes,
		"popup_backing_box",
		nil,
		{ POPUP_BACKING_WIDTH, POPUP_BACKING_HEIGHT }
	),
	popup_background = UIWidget.create_definition({
		{
			pass_type = "texture",
			style_id = "terminal",
			value = "content/ui/materials/backgrounds/terminal_basic",
			style = popup_background_style,
		},
		divider_pass("content/ui/materials/frames/premium_store/details_upper", "top", 66, -82),
		divider_pass("content/ui/materials/frames/premium_store/details_lower_basic", "bottom", 82, 48),
	}, "popup_background"),
	popup_frame = UIWidget.create_definition(
		Styles.frame_passes("content/ui/materials/frames/frame_tile_2px", Styles.COLORS.line, Styles.COLORS.corner),
		"popup_frame"
	),
	list_frame = UIWidget.create_definition(
		Styles.frame_passes("content/ui/materials/frames/frame_tile_2px", Styles.COLORS.line, Styles.COLORS.corner),
		"list_frame"
	),
	actions_frame = UIWidget.create_definition(
		Styles.frame_passes("content/ui/materials/frames/frame_tile_2px", Styles.COLORS.line, Styles.COLORS.corner),
		"actions_frame"
	),
	title_divider = UIWidget.create_definition({
		{
			pass_type = "texture",
			value = "content/ui/materials/dividers/skull_rendered_left_01",
			style = {
				color = Styles.copy_color(Styles.COLORS.frame),
				scale_to_material = true,
				offset = { 0, 0, 2 },
			},
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
	header_rule = UIWidget.create_definition({
		Styles.rule_pass("rule"),
	}, "header_rule"),
	bottom_rule = UIWidget.create_definition({
		Styles.rule_pass("rule"),
	}, "bottom_rule"),
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

local function grid_settings(width, height, visual_margin)
	local inner_width = math.max(1, width - 16)
	local inner_height = math.max(1, height - 32)

	return {
		scrollbar_width = 6,
		scrollbar_vertical_margin = -40,
		no_resource_rendering = true,
		use_terminal_background = false,
		hide_background = true,
		hide_dividers = true,
		ignore_divider_height = true,
		title_height = 0,
		top_padding = 0,
		bottom_chin = 0,
		widget_visual_margin = visual_margin or -8,
		grid_spacing = { 6, 6 },
		grid_size = { inner_width, inner_height },
		mask_size = { inner_width, inner_height },
		edge_padding = 0,
	}
end

Definitions.scenegraph_definition = scenegraph_definition
Definitions.widget_definitions = widget_definitions
Definitions.widget_draw_order = widget_draw_order
Definitions.tooltip_definitions = tooltip_definitions
Definitions.blueprints = Blueprints
Definitions.bottom_buttons = bottom_buttons
Definitions.list_grid_settings = grid_settings(420, 531)
Definitions.actions_grid_settings = grid_settings(660, ACTIONS_LIST_HEIGHT + 32, -64)
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
			end_time = 0.0,
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
			end_time = 0.0,
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
