local mod = get_mod("Alfs_DMF_Extensions")

local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local Styles = mod._preset_panel_styles or {}
mod._preset_panel_styles = Styles

local function color(value, fallback)
	return value and value(255, true) or fallback
end

local function named_color(name, alpha, fallback)
	local value = Color and Color[name]

	return type(value) == "function" and value(alpha, true) or fallback
end

local function rgba(rgb, alpha)
	return { alpha or 255, rgb[1], rgb[2], rgb[3] }
end

Styles.copy_color = function(value)
	if type(value) ~= "table" then
		return value
	end

	return { value[1], value[2], value[3], value[4] }
end

Styles.set_color = function(target, value)
	if type(target) ~= "table" or type(value) ~= "table" then
		return target
	end

	target[1], target[2], target[3], target[4] = value[1], value[2], value[3], value[4]

	return target
end

local function copy_value(value)
	if type(value) ~= "table" then
		return value
	end

	local result = {}

	for key, child in pairs(value) do
		result[key] = copy_value(child)
	end

	return result
end

local function has_prefix(value, prefix)
	return type(value) == "string" and string.sub(value, 1, #prefix) == prefix
end

Styles.COLORS = {
	normal = { 255, 226, 199, 126 },
	text = Color.terminal_text_header(255, true),
	text_hover = Color.terminal_text_header_selected(255, true),
	muted = color(Color.ui_grey_light, Color.terminal_text_header(255, true)),
	panel = Color.terminal_grid_background(255, true),
	frame = Color.terminal_corner(255, true),
	frame_selected = Color.terminal_frame_selected(255, true),
	line = named_color("terminal_frame", 255, Color.terminal_corner(255, true)),
	line_hover = named_color("terminal_frame_hover", 255, Color.terminal_frame_selected(255, true)),
	line_selected = Color.terminal_frame_selected(255, true),
	corner = Color.terminal_corner(255, true),
	corner_hover = named_color("terminal_corner_hover", 255, Color.terminal_corner(255, true)),
	corner_selected = named_color("terminal_corner_selected", 255, Color.terminal_frame_selected(255, true)),
	background = named_color("terminal_background", 100, Color.terminal_grid_background(100, true)),
	background_hover = named_color("terminal_background", 140, Color.terminal_grid_background(140, true)),
	background_selected = named_color("terminal_background_selected", 110, Color.terminal_grid_background(110, true)),
	gradient = named_color("terminal_background_gradient", 90, Color.terminal_grid_background(90, true)),
	gradient_selected = named_color("terminal_frame_selected", 150, Color.terminal_frame_selected(150, true)),
	popup_background = Color.terminal_grid_background(70, true),
	tooltip_background = Color.black(230, true),
	gold_edge = rgba({ 250, 189, 73 }, 255),
	gold_text = { 255, 226, 199, 126 },
	gold_bar = rgba({ 218, 165, 32 }, 255),
	green_key = rgba({ 169, 191, 153 }, 255),
	bone = rgba({ 232, 224, 206 }, 255),
	shadow = Color.black(170, true),
	inner_shadow = Color.black(150, true),
	hairline = rgba({ 121, 136, 109 }, 90),
}

Styles.rgba = rgba

Styles.materials = {
	square = "content/ui/materials/backgrounds/default_square",
	gradient_vertical = "content/ui/materials/gradients/gradient_vertical",
	gradient_horizontal = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
	frame_tile = "content/ui/materials/frames/frame_tile_2px",
	frame_corner = "content/ui/materials/frames/frame_corner_2px",
	frame_glow = "content/ui/materials/frames/frame_glow_01",
	dropshadow = "content/ui/materials/frames/dropshadow_medium",
	inner_shadow = "content/ui/materials/frames/inner_shadow_medium",
}

Styles.make_text_style = function(font_size, offset, text_color, alignment, size)
	local style = table.clone(UIFontSettings.body or UIFontSettings.button_primary or UIFontSettings.header_3 or {})

	style.font_size = font_size
	style.text_horizontal_alignment = alignment or "left"
	style.text_vertical_alignment = "center"
	style.horizontal_alignment = alignment == "center" and "center" or "left"
	style.vertical_alignment = "center"
	style.offset = offset
	style.size = size or nil
	style.text_color = Styles.copy_color(text_color or Styles.COLORS.text)

	return style
end

Styles.make_state_text_style = function(font_size, offset, text_color, alignment, size, hover_color, selected_color)
	local style = Styles.make_text_style(font_size, offset, text_color, alignment, size)

	style.font_type = style.font_type or "proxima_nova_bold"
	style.drop_shadow = true
	style.line_spacing = style.line_spacing or 1.2
	style.rest_color = Styles.copy_color(text_color or Styles.COLORS.text)
	style.hover_color = Styles.copy_color(hover_color or Styles.COLORS.text_hover)
	style.selected_color = Styles.copy_color(selected_color or Styles.COLORS.normal)
	style.disabled_color = style.disabled_color or Styles.copy_color(Styles.COLORS.muted)

	return style
end

Styles.copy_button_passes = function(template_name)
	local template = ButtonPassTemplates[template_name]

	if type(template) ~= "table" then
		return {}
	end

	return copy_value(template)
end

Styles.assigned = function(content)
	return content and content.assigned == true or false
end

Styles.hovered_or_selected = function(content)
	local hotspot = content and content.hotspot or {}

	return Styles.assigned(content)
		or hotspot.is_hover
		or hotspot.is_focused
		or hotspot.is_selected
		or (hotspot.anim_hover_progress or 0) > 0
		or (hotspot.anim_focus_progress or 0) > 0
		or (hotspot.anim_select_progress or 0) > 0
end

Styles.selected = function(content)
	local hotspot = content and content.hotspot or {}

	return Styles.assigned(content)
		or hotspot.is_selected
		or (hotspot.anim_select_progress or 0) > 0
end

Styles.state_color = function(content, style)
	local selected = Styles.selected(content)
	local hovered = Styles.hovered_or_selected(content)
	local value = selected and (style.selected_color or style.hover_color or style.rest_color)
		or hovered and (style.hover_color or style.rest_color)
		or style.rest_color
		or style.color

	local target = style.text_color or style.color

	if type(value) == "table" and type(target) == "table" then
		Styles.set_color(target, value)
	end
end

Styles.button_passes = function(alignment, font_size, offset, template_name)
	local passes = Styles.copy_button_passes(template_name or "terminal_button")

	for _, pass in ipairs(passes) do
		local style = pass.style
		local style_id = pass.style_id

		if style then
			if style_id == "background" then
				style.default_color = Styles.copy_color(Styles.COLORS.background)
				style.selected_color = Styles.copy_color(Styles.COLORS.background_selected)
			elseif style_id == "background_gradient" then
				style.default_color = Styles.copy_color(Styles.COLORS.gradient)
				style.selected_color = Styles.copy_color(Styles.COLORS.gradient_selected)
			elseif style_id == "outer_shadow" then
				style.color = Styles.copy_color(Styles.COLORS.shadow)
				style.size_addition = { 16, 16 }
			elseif style_id == "frame" then
				style.default_color = Styles.copy_color(Styles.COLORS.line)
				style.hover_color = Styles.copy_color(Styles.COLORS.line_hover)
				style.selected_color = Styles.copy_color(Styles.COLORS.gold_edge)
			elseif style_id == "corner" then
				style.default_color = Styles.copy_color(Styles.COLORS.corner)
				style.hover_color = Styles.copy_color(Styles.COLORS.corner_hover)
				style.selected_color = Styles.copy_color(Styles.COLORS.gold_edge)
			elseif style_id == "text" then
				style.font_size = font_size or style.font_size
				style.offset = offset and copy_value(offset) or style.offset
				style.text_horizontal_alignment = alignment or "center"
				style.horizontal_alignment = alignment == "center" and "center" or "left"
				style.default_color = Styles.copy_color(Styles.COLORS.text)
				style.hover_color = Styles.copy_color(Styles.COLORS.text_hover)
				style.selected_color = Styles.copy_color(Styles.COLORS.normal)
			end
		end
	end

	return passes
end

Styles.info_passes = function(font_size, offset)
	return {
		{
			pass_type = "text",
			value_id = "text",
			style_id = "text",
			style = Styles.make_text_style(font_size or 18, offset or { 10, 0, 2 }, Styles.COLORS.muted),
		},
	}
end

Styles.frame_passes = function(material, color, corner_color)
	return {
		{
			pass_type = "texture",
			style_id = "frame",
			value = material or "content/ui/materials/frames/frame_tile_2px",
			style = {
				color = Styles.copy_color(color or Styles.COLORS.line),
				scale_to_material = true,
			},
		},
		{
			pass_type = "texture",
			style_id = "corner",
			value = "content/ui/materials/frames/frame_corner_2px",
			style = {
				color = Styles.copy_color(corner_color or Styles.COLORS.corner),
				scale_to_material = true,
			},
		},
	}
end

Styles.customize_dropdown = function(passes)
	for _, pass in ipairs(passes or {}) do
		local style = pass.style
		local style_id = pass.style_id

		if style then
			if style_id == "background" then
				style.color = Styles.copy_color(Styles.COLORS.frame)
			elseif style_id == "fill" then
				style.color = Styles.copy_color(Styles.COLORS.normal)
			elseif style_id == "line" then
				style.color = Styles.copy_color(Styles.COLORS.frame_selected)
			elseif style_id == "dropdown_background" then
				style.color = Styles.copy_color(Styles.COLORS.panel)
			elseif style_id == "text" then
				style.text_color = Styles.copy_color(Styles.COLORS.normal)
			elseif style_id == "icon" then
				style.visible = false
			elseif has_prefix(style_id, "option_text_") then
				style.default_color = Styles.copy_color(Styles.COLORS.normal)
				style.hover_color = Styles.copy_color(Styles.COLORS.text_hover)
				Styles.set_color(style.text_color, Styles.COLORS.normal)
			elseif has_prefix(style_id, "option_icon_") then
				style.default_color = Styles.copy_color(Styles.COLORS.normal)
				style.hover_color = Styles.copy_color(Styles.COLORS.text_hover)
				Styles.set_color(style.color, Styles.COLORS.normal)
			elseif has_prefix(style_id, "outline_") then
				Styles.set_color(style.color, Styles.COLORS.frame)
			end
		end
	end

	return passes
end
