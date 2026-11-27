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

local function wrap_assignment_text(ui_renderer, widget, text, max_rows)
	local style = widget and widget.style and widget.style.character_title

	if not ui_renderer or not style or not style.font_type or not style.font_size or text == "" then
		return text or ""
	end

	local width = style.size and style.size[1]

	if not width then
		return text
	end

	local rows = UIRenderer.word_wrap(ui_renderer, text, style.font_type, style.font_size, width)
	local row_count = rows and #rows or 0

	if row_count <= 1 then
		return text
	end

	max_rows = max_rows or 2
	local visible_rows = {}

	for index = 1, math.min(row_count, max_rows) do
		visible_rows[index] = rows[index]
	end

	if row_count > max_rows then
		local last_index = #visible_rows
		local last_row = visible_rows[last_index] or ""

		visible_rows[last_index] = UIRenderer.styled_crop_text_width(ui_renderer, last_row .. " …", style, width)
	end

	return table.concat(visible_rows, "\n")
end

Blueprints.wrap_assignment_text = wrap_assignment_text

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
		style = Styles.make_text_style(20, { 72, -26, 3 }, Styles.COLORS.text, "left", { 500, 26 }),
	},
	{
		pass_type = "text",
		value_id = "character_archetype_title",
		style_id = "character_archetype_title",
		style = Styles.make_text_style(16, { 72, -2, 3 }, Styles.COLORS.muted, "left", { 500, 24 }),
	},
	{
		pass_type = "text",
		value_id = "character_title",
		style_id = "character_title",
		style = Styles.make_text_style(16, { 72, 24, 3 }, Styles.COLORS.normal, "left", { 548, 42 }),
	},
}

local preset_entry_size = { 400, 42 }
local preset_text_offset = { 12, 0, 3 }
local preset_text_margin = 12

local function preset_entry_text_width(width)
	return math.max(1, width - preset_text_offset[1] - preset_text_margin)
end

local preset_text_width = preset_entry_text_width(preset_entry_size[1])
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

Blueprints.resize_preset_entry = function(widget, width)
	local content = widget and widget.content

	if not content or not content.size then
		return
	end

	content.size[1] = math.max(1, width)

	local text_style = widget.style and widget.style.text
	local text_width = preset_entry_text_width(content.size[1])

	if text_style then
		if type(text_style.size) == "table" then
			text_style.size[1] = text_width
		else
			text_style.size = { text_width, preset_entry_size[2] }
		end
	end
end

local preset_toggle_text_offset = { 12, 0, 3 }

local function make_preset_toggle(size, font_size)
	local text_width = size[1] - 104
	local passes = Styles.button_passes("left", font_size or 20, preset_toggle_text_offset)

	for _, pass in ipairs(passes) do
		if pass.style_id == "text" and pass.style then
			pass.style.size = { text_width, size[2] }
			pass.style.text_fit_with = true
		end
	end

	passes[#passes + 1] = {
		pass_type = "text",
		value_id = "toggle_mark",
		style_id = "toggle_mark",
		style = Styles.make_text_style(22, { size[1] - 54, 0, 4 }, Styles.COLORS.normal, "right", { 36, size[2] }),
	}

	return {
		size = size,
		pass_template = passes,
		init = function(parent, widget, element, callback_name, secondary_callback_name, ui_renderer)
			init_hotspot_widget(parent, widget, element, callback_name)

			local content = widget and widget.content

			if not content then
				return
			end

			content.name = element and element.name or nil
			content.assigned = element and element.assigned == true or false
			content.toggle_mark = content.assigned and "\226\156\147" or ""
			content.extra_margin = -size[2]

			if content.hotspot then
				content.hotspot.is_selected = content.assigned
			end

			local text_style = widget.style and widget.style.text
			local text = content.original_text or content.text or ""

			if ui_renderer and text_style and text ~= "" then
				local cropped = UIRenderer.styled_crop_text_width(ui_renderer, text, text_style, text_width)

				if cropped and cropped ~= text then
					content.original_text = cropped
					content.text = cropped
				end
			end
		end,
	}
end

Blueprints.preset_toggle = make_preset_toggle({ 1084, 42 })
Blueprints.preset_toggle_half = make_preset_toggle({ 528, 42 }, 18)

Blueprints.action_button = {
	size = { 640, 40 },
	pass_template = Styles.button_passes("center", 20),
	init = init_hotspot_widget,
}

Blueprints.character_toggle = {
	size = { 640, 96 },
	pass_template = character_toggle_template,
	init = function(parent, widget, element, callback_name, secondary_callback_name, ui_renderer)
		init_hotspot_widget(parent, widget, element, callback_name)

		local content = widget and widget.content

		if not content then
			return
		end

		local archetype_name = element and element.archetype_name or ""
		local level = element and element.level or ""
		local assignment_text = element and element.title or ""

		content.extra_margin = -96
		content.profile = element and element.profile or nil
		Portraits.set_frame(widget, content.profile)
		content.assigned = element and element.assigned == true
		content.assignment_text = content.assigned and "\226\156\147" or ""
		content.character_name = element and element.name or ""
		content.character_archetype_title = level ~= "" and (archetype_name .. "  " .. level) or archetype_name
		content.character_title = wrap_assignment_text(ui_renderer, widget, assignment_text, 2)
	end,
	load_icon = Portraits.load,
	unload_icon = Portraits.unload,
	destroy = Portraits.unload,
}

local character_summary_template = table.clone(character_toggle_template)

for index, pass in ipairs(character_summary_template) do
	local style_id = pass.style_id

	if style_id == "character_name" then
		character_summary_template[index] = {
			pass_type = "text",
			value_id = "character_name",
			style_id = "character_name",
			style = Styles.make_text_style(20, { 72, -22, 3 }, Styles.COLORS.text, "left", { 980, 24 }),
		}
	elseif style_id == "character_archetype_title" then
		character_summary_template[index] = {
			pass_type = "text",
			value_id = "character_archetype_title",
			style_id = "character_archetype_title",
			style = Styles.make_text_style(16, { 72, 2, 3 }, Styles.COLORS.muted, "left", { 980, 22 }),
		}
	elseif style_id == "character_title" then
		local title_style = Styles.make_text_style(14, { 72, 26, 3 }, Styles.COLORS.normal, "left", { 980, 22 })

		title_style.text_fit_with = true
		character_summary_template[index] = {
			pass_type = "text",
			value_id = "character_title",
			style_id = "character_title",
			style = title_style,
		}
	elseif style_id == "assignment_text" then
		character_summary_template[index] = {
			pass_type = "text",
			value_id = "assignment_text",
			style_id = "assignment_text",
			style = Styles.make_text_style(1, { 0, 0, 0 }, Styles.COLORS.normal, "right", { 1, 1 }),
		}
	end
end

Blueprints.character_summary = {
	size = { 1084, 88 },
	pass_template = character_summary_template,
	init = function(parent, widget, element, callback_name)
		init_hotspot_widget(parent, widget, element, callback_name)

		local content = widget and widget.content

		if not content then
			return
		end

		local archetype_name = element and element.archetype_name or ""
		local level = element and element.level or ""

		content.extra_margin = -88
		content.profile = element and element.profile or nil
		Portraits.set_frame(widget, content.profile)
		content.assigned = false
		content.assignment_text = ""
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

Blueprints.wide_info = {
	size = { 1084, 32 },
	pass_template = Styles.info_passes(18, { 10, 0, 2 }),
	init = function(_, widget, element)
		local content = widget and widget.content

		if content then
			content.text = element and element.text or ""
			content.extra_margin = -32
		end
	end,
}

return Blueprints
