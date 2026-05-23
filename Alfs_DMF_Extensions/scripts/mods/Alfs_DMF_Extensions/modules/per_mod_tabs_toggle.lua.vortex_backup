local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local function get_storage_key(category)
	return "gen_tabs_per_mod_" .. tostring(category or "unknown")
end

mod.is_gen_tabs_enabled_for_mod = function(category)
	if not category then
		return true
	end

	local stored = mod:get(get_storage_key(category))

	return stored ~= false
end

mod.toggle_gen_tabs_for_mod = function(category)
	if not category then
		return
	end

	local new_state = not mod.is_gen_tabs_enabled_for_mod(category)

	mod:set(get_storage_key(category), new_state)

	return new_state
end

mod.reset_all_per_mod_toggles = function()
	local dmf_mod = mod.dmf or get_mod("DMF")

	if not dmf_mod then
		return
	end

	for _, mod_widgets in ipairs(dmf_mod.options_widgets_data or {}) do
		local header = mod_widgets[1]
		local cat_name = (header and (header.readable_mod_name or header.mod_name)) or ""

		if cat_name ~= "" then
			local key = get_storage_key(cat_name)
			local stored = mod:get(key)

			if stored ~= nil then
				mod:set(key, nil)
			end
		end
	end
end

local COLORS = {
	normal = Color.terminal_text_header(nil, true),
	hover = Color.terminal_text_header_selected(nil, true),

	background = Color.terminal_background(nil, true),
	background_hover = Color.terminal_background_gradient(nil, true),
	background_selected = Color.terminal_background_gradient_selected(nil, true),

	frame = Color.terminal_corner(nil, true),
	frame_hover = Color.terminal_corner_hover(nil, true),
	frame_selected = Color.terminal_frame_selected(nil, true),
}

local toggle_font_style = table.clone(UIFontSettings.button_primary)
toggle_font_style.font_size = 18
toggle_font_style.text_horizontal_alignment = "center"
toggle_font_style.text_vertical_alignment = "center"
toggle_font_style.default_color = COLORS.normal
toggle_font_style.hover_color = COLORS.hover
toggle_font_style.offset = { 0, 0, 5 }
toggle_font_style.drop_shadow = true

mod._gen_tabs_toggle_widgets = mod._gen_tabs_toggle_widgets or {}

mod.create_gen_tabs_toggle = function(self, category)
	local entry = {
		widget_type = "settings_button",
		display_name = mod.is_gen_tabs_enabled_for_mod(category) and mod:localize("gen_tabs_toggle_on")
			or mod:localize("gen_tabs_toggle_off"),
		tooltip_text = mod:localize("gen_tabs_toggle_tooltip"),
	}

	local scenegraph_id = "settings_grid_content_pivot"
	local width = 130
	local height = 22
	local size = { width, height }

	local pass_template = {
		{
			pass_type = "hotspot",
			content_id = "hotspot",
		},
		{
			pass_type = "rect",
			style_id = "background",
			style = {
				color = { 100, 10, 10, 10 },
				offset = { 0, 0, 0 },
				size = size,
			},
		},
		{
			pass_type = "rect",
			style_id = "overlay",
			style = {
				color = { 15, 80, 130, 80 },
				offset = { 0, 0, 1 },
				size_addition = { 0, 0 },
			},
			change_function = function(content, style)
				local hotspot = content.hotspot
				if hotspot.is_hover then
					style.color[1] = 30
				else
					style.color[1] = 15
				end
			end,
		},
		{
			pass_type = "texture",
			style_id = "frame",
			value = "content/ui/materials/frames/frame_tile_1px",
			style = {
				scale_to_material = true,
				color = COLORS.frame,
				offset = { 0, 0, 2 },
			},
			change_function = function(content, style)
				local hotspot = content.hotspot
				if hotspot.is_hover then
					style.color = COLORS.frame_hover
				else
					style.color = COLORS.frame
				end
			end,
		},
		{
			pass_type = "text",
			style_id = "text",
			value_id = "text",
			style = table.clone(toggle_font_style),
		},
	}

	local widget_definition = UIWidget.create_definition(pass_template, scenegraph_id, nil, size)

	if not widget_definition then
		return nil, nil
	end

	local name = "gen_tabs_toggle_" .. tostring(category)
	local widget = self:_create_widget(name, widget_definition)
	widget.type = "settings_button"
	widget.content.text = entry.display_name
	widget.content.entry = entry
	widget.content.size = size

	local hotspot = widget.content.hotspot

	if hotspot then
		hotspot.pressed_callback = function()
			local new_state = mod.toggle_gen_tabs_for_mod(category)
			widget.content.text = new_state and mod:localize("gen_tabs_toggle_on")
				or mod:localize("gen_tabs_toggle_off")
		end
	end

	local alignment = {
		horizontal_alignment = "right",
		size = size,
		name = name,
	}

	mod._gen_tabs_toggle_widgets[category] = {
		widget = widget,
		alignment = alignment,
	}

	return widget, alignment
end

mod.get_gen_tabs_toggle = function(category)
	local toggle = mod._gen_tabs_toggle_widgets and mod._gen_tabs_toggle_widgets[category]
	return toggle and toggle.widget or nil, toggle and toggle.alignment or nil
end

mod.inject_gen_tabs_toggle_into_content = function(self, category, visible_widgets, visible_alignment)
	local widget, alignment = mod.get_gen_tabs_toggle(category)

	if not widget then
		widget, alignment = mod.create_gen_tabs_toggle(self, category)
	end

	if widget and alignment then
		alignment.offset = { 740, 80 }

		widget.visible = true
		alignment.visible = true
		visible_widgets[#visible_widgets + 1] = widget
		visible_alignment[#visible_alignment + 1] = alignment
	end
end
