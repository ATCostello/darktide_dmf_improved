local mod = get_mod("Alfs_DMF_Extensions")

local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local Styles = mod._preset_panel_styles or {}
mod._preset_panel_styles = Styles

local function color(value, fallback)
	return value and value(255, true) or fallback
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
	popup_background = Color.terminal_grid_background(70, true),
	tooltip_background = Color.black(230, true),
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

Styles.copy_button_passes = function(template_name)
	local template = ButtonPassTemplates[template_name]

	if type(template) ~= "table" then
		return {}
	end

	return copy_value(template)
end

Styles.button_passes = function(alignment, font_size, offset, template_name)
	local passes = Styles.copy_button_passes(template_name or "terminal_button")

	for _, pass in ipairs(passes) do
		if pass.style_id == "text" and type(pass.style) == "table" then
			local style = pass.style

			style.font_size = font_size or style.font_size
			style.offset = offset and copy_value(offset) or style.offset
			style.text_horizontal_alignment = alignment or "center"
			style.horizontal_alignment = alignment == "center" and "center" or "left"
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

Styles.frame_passes = function(material, color)
	return {
		{
			pass_type = "texture",
			style_id = "frame",
			value = material or "content/ui/materials/frames/frame_tile_2px",
			style = {
				color = Styles.copy_color(color or Styles.COLORS.frame),
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
