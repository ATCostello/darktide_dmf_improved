local mod = get_mod("Alfs_DMF_Extensions")

local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local UIRenderer = require("scripts/managers/ui/ui_renderer")

local Styles = mod._preset_panel_styles
local Portraits = mod._preset_panel_portraits

local Blueprints = mod._preset_panel_blueprints or {}
mod._preset_panel_blueprints = Blueprints

local function init_hotspot_widget(parent, widget, element, callback_name)
	local content = widget and widget.content

	if not content then
		return
	end

	content.hotspot = content.hotspot or {}
	content.hotspot.pressed_callback = callback_name and callback(parent, callback_name, widget, element) or nil
	content.element = element
	content.text = element and element.text or ""
	content.original_text = content.text
	content.tooltip_text = element and element.tooltip or ""
end

local character_glow_pass = Styles.glow_pass("glow", { 12, 12 }, Styles.COLORS.accent_edge)

character_glow_pass.style.rest_color = Styles.copy_color(Styles.COLORS.accent_edge)
character_glow_pass.style.hover_color = Styles.copy_color(Styles.COLORS.accent_edge)
character_glow_pass.style.selected_color = Styles.copy_color(Styles.COLORS.accent_edge)
character_glow_pass.visibility_function = function(content)
	return Styles.hovered_or_selected(content)
end
character_glow_pass.change_function = function(content, style)
	local selected = Styles.selected(content)

	Styles.set_color(style.color, selected and style.selected_color or style.hover_color)
	style.color[1] = selected and 110 or 70
end

local character_toggle_template = {
	{
		content_id = "hotspot",
		pass_type = "hotspot",
		content = {
			use_is_focused = false,
			anim_hover_speed = 8,
			anim_focus_speed = 8,
			anim_input_speed = 8,
			anim_select_speed = 8,
			on_hover_sound = UISoundEvents.default_mouse_hover,
		},
	},
	character_glow_pass,
	{
		pass_type = "texture",
		style_id = "background",
		value = "content/ui/materials/backgrounds/default_square",
		style = {
			scale_to_material = true,
			rest_color = Styles.copy_color(Styles.COLORS.background),
			hover_color = Styles.copy_color(Styles.COLORS.background_hover),
			selected_color = Styles.copy_color(Styles.COLORS.background_selected),
			color = Styles.copy_color(Styles.COLORS.background),
			size_addition = { nil, -2 },
			offset = { 0, 0, 0 },
		},
		visibility_function = function(content)
			return Styles.selected(content)
		end,
		change_function = function(content, style)
			Styles.state_color(content, style)
		end,
	},
	{
		pass_type = "texture",
		style_id = "background_gradient",
		value = "content/ui/materials/masks/gradient_horizontal_sides_dynamic_02",
		style = {
			scale_to_material = true,
			rest_color = Styles.copy_color(Styles.COLORS.gradient),
			hover_color = Styles.copy_color(Styles.COLORS.gradient_hover),
			selected_color = Styles.copy_color(Styles.COLORS.gradient_selected),
			color = Styles.copy_color(Styles.COLORS.gradient),
			size_addition = { nil, -2 },
			offset = { 0, 0, 1 },
		},
		visibility_function = function(content)
			return Styles.hovered_or_selected(content)
		end,
		change_function = function(content, style)
			Styles.state_color(content, style)
		end,
	},
	{
		pass_type = "texture",
		style_id = "frame",
		value = "content/ui/materials/frames/frame_tile_2px",
		style = {
			horizontal_alignment = "center",
			vertical_alignment = "center",
			scale_to_material = true,
			rest_color = Styles.copy_color(Styles.COLORS.line),
			hover_color = Styles.copy_color(Styles.COLORS.line_hover),
			selected_color = Styles.copy_color(Styles.COLORS.line_selected),
			color = Styles.copy_color(Styles.COLORS.line),
			size_addition = { nil, 2 },
			offset = { 0, -1, 4 },
		},
		visibility_function = function(content)
			return Styles.hovered_or_selected(content)
		end,
		change_function = function(content, style)
			Styles.state_color(content, style)
		end,
	},
	{
		pass_type = "texture",
		style_id = "corner",
		value = "content/ui/materials/frames/frame_corner_2px",
		style = {
			horizontal_alignment = "center",
			vertical_alignment = "center",
			scale_to_material = true,
			rest_color = Styles.copy_color(Styles.COLORS.corner),
			hover_color = Styles.copy_color(Styles.COLORS.corner_hover),
			selected_color = Styles.copy_color(Styles.COLORS.corner_selected),
			color = Styles.copy_color(Styles.COLORS.corner),
			size_addition = { nil, 2 },
			offset = { 0, -1, 5 },
		},
		visibility_function = function(content)
			return Styles.hovered_or_selected(content)
		end,
		change_function = function(content, style)
			Styles.state_color(content, style)
		end,
	},
	Portraits.pass({ 52, 58 }, { 8, 0, 3 }),
	{
		pass_type = "text",
		value_id = "assignment_text",
		style_id = "assignment_text",
		style = Styles.make_text_style(22, { 600, 0, 3 }, Styles.COLORS.normal, "right", { 30, 40 }),
	},
	{
		pass_type = "text",
		value_id = "character_name",
		style_id = "character_name",
		style = Styles.make_text_style(20, { 72, -10, 3 }, Styles.COLORS.text, "left", { 260, 26 }),
	},
	{
		pass_type = "text",
		value_id = "character_archetype_title",
		style_id = "character_archetype_title",
		style = Styles.make_text_style(16, { 72, 12, 3 }, Styles.COLORS.muted, "left", { 260, 24 }),
	},
	{
		pass_type = "text",
		value_id = "character_title",
		style_id = "character_title",
		style = Styles.make_text_style(14, { 340, -10, 3 }, Styles.COLORS.normal, "right", { 250, 24 }),
	},
}

for _, pass in ipairs(character_toggle_template) do
	if pass.style_id == "character_title" and pass.style then
		pass.style.text_fit_with = true
	end
end

local preset_entry_size = { 400, 42 }
local preset_text_offset = { 12, 0, 3 }
local preset_text_width = preset_entry_size[1] - preset_text_offset[1] - 12
local preset_button_passes = Styles.button_passes("left", 20, preset_text_offset)

for _, pass in ipairs(preset_button_passes) do
	if pass.style_id == "text" and pass.style then
		pass.style.size = { preset_text_width, preset_entry_size[2] }
		pass.style.text_fit_with = true
	end
end

Blueprints.preset_entry = {
	size = preset_entry_size,
	pass_template = preset_button_passes,
	init = function(parent, widget, element, callback_name, secondary_callback_name, ui_renderer)
		init_hotspot_widget(parent, widget, element, callback_name)

		local content = widget and widget.content

		if not content then
			return
		end

		content.name = element and element.name or nil
		content.hotspot.is_selected = parent and parent._selected_name == content.name or false

		local text_style = widget.style and widget.style.text
		local text = content.original_text or content.text or ""

		if ui_renderer and text_style and text ~= "" then
			local cropped = UIRenderer.styled_crop_text_width(ui_renderer, text, text_style, preset_text_width)

			if cropped and cropped ~= text then
				content.original_text = cropped
				content.text = cropped
			end
		end
	end,
}

Blueprints.action_button = {
	size = { 640, 40 },
	pass_template = Styles.button_passes("center", 20),
	init = init_hotspot_widget,
}

Blueprints.character_toggle = {
	size = { 640, 64 },
	pass_template = character_toggle_template,
	init = function(parent, widget, element, callback_name)
		init_hotspot_widget(parent, widget, element, callback_name)

		local content = widget and widget.content

		if not content then
			return
		end

		local archetype_name = element and element.archetype_name or ""
		local level = element and element.level or ""

		content.profile = element and element.profile or nil
		Portraits.set_frame(widget, content.profile)
		content.assigned = element and element.assigned == true
		content.assignment_text = content.assigned and "\226\156\147" or ""
		content.character_name = element and element.name or ""
		content.character_archetype_title = level ~= "" and (archetype_name .. "  " .. level) or archetype_name
		content.character_title = element and element.title or ""
	end,
	load_icon = Portraits.load,
	unload_icon = Portraits.unload,
	destroy = Portraits.unload,
}

Blueprints.info = {
	size = { 640, 32 },
	pass_template = Styles.info_passes(18, { 10, 0, 2 }),
	init = function(_, widget, element)
		local content = widget and widget.content

		if content then
			content.text = element and element.text or ""
		end
	end,
}

return Blueprints
