local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")

local blueprints = {}

local settings_grid_width = 850
local widget_height = 190

local BAR_WIDTH = 240
local BAR_HEIGHT = 28

local PREVIEW_WIDTH = 40
local PREVIEW_HEIGHT = 40

-- ############################################################
-- Helpers
-- ############################################################

local function get_value(entry)
	if not entry then
		return 255
	end

	if not entry.setting_id then
		return 255
	end

	local value = entry.get_function()

	if not value then
		return 255
	end

	return value
end

local function set_value(entry, value)
	if not entry then
		return
	end

	entry.changed_callback(value)
end

-- ############################################################
-- Slider Pass Builder
-- ############################################################

local function create_slider(name, x, color, label)
	return {
		{
			pass_type = "hotspot",
			content_id = name .. "_hotspot",
			style_id = name .. "_hotspot_style",
		},
		{
			pass_type = "rect",
			style_id = name .. "_bg",
		},
		{
			pass_type = "rect",
			style_id = name .. "_fill",
		},
		{
			pass_type = "text",
			value_id = name .. "_label",
			style_id = name .. "_label_style",
		},
		{
			pass_type = "text",
			value_id = name .. "_value",
			style_id = name .. "_value_style",
		},
	}, {
		[name .. "_hotspot_style"] = {
			offset = { x, 0, 0 },
			size = { BAR_WIDTH, BAR_HEIGHT },
		},
		[name .. "_label"] = label,
		[name .. "_value"] = "0",
	}, {
		[name .. "_bg"] = {
			color = { 255, 30, 30, 30 },
			offset = { x, 0, 0 },
			size = { BAR_WIDTH, BAR_HEIGHT },
		},

		[name .. "_fill"] = {
			color = color,
			offset = { x, 0, 1 },
			size = { 0, BAR_HEIGHT },
		},

		[name .. "_label_style"] = {
			font_type = "proxima_nova_bold",
			horizontal_alignment = "left",
			vertical_alignment = "center",
			font_size = 24,
			text_color = { 255, 255, 255, 255 },
			offset = { x - 22, -2, 2 },
		},

		[name .. "_value_style"] = {
			font_type = "proxima_nova_bold",
			horizontal_alignment = "left",
			vertical_alignment = "center",
			font_size = 24,
			text_color = { 255, 255, 255, 255 },
			offset = { x + BAR_WIDTH + 5, -2, 2 },
		},
	}
end

-- ############################################################
-- Build Passes
-- ############################################################

local passes = {}
local content = {}
local style = {}

local sliders = {
	{
		name = "r",
		x = PREVIEW_WIDTH + 10,
		color = { 255, 155, 155, 155 },
		label = "R",
	},
	{
		name = "g",
		x = PREVIEW_WIDTH + 10 + (BAR_WIDTH + 100),
		color = { 255, 155, 155, 155 },
		label = "G",
	},
	{
		name = "b",
		x = PREVIEW_WIDTH + 10 + ((BAR_WIDTH + 100) * 2),
		color = { 255, 155, 155, 155 },
		label = "B",
	},
}

for _, slider in ipairs(sliders) do
	local p, c, s = create_slider(slider.name, slider.x, slider.color, slider.label)

	for _, pass in ipairs(p) do
		table.insert(passes, pass)
	end

	for k, v in pairs(c) do
		content[k] = v
	end

	for k, v in pairs(s) do
		style[k] = v
	end
end

table.insert(passes, {
	pass_type = "rect",
	style_id = "preview_style",
})

style.preview_style = {
	color = { 255, 255, 255, 255 },
	offset = { -PREVIEW_WIDTH, -0.25 * PREVIEW_HEIGHT, 0 },
	size = { PREVIEW_WIDTH, PREVIEW_HEIGHT },
}

-- ############################################################
-- Blueprint
-- ############################################################
local DEFAULT_NUM_DECIMALS = 0

blueprints = {
	rgb_widget = {
		size = {
			settings_grid_width,
			widget_height,
		},

		pass_template = passes,
		content = content,
		style = style,
		pass_template_function = function(parent, config, size)
			return SliderPassTemplates.settings_value_slider(size[1], BAR_WIDTH, BAR_HEIGHT, true)
		end,
		init = function(parent, widget, entry)
			local content = widget.content
			local style = widget.style

			local r = get_value(content.r_entry)
			local g = get_value(content.g_entry)
			local b = get_value(content.b_entry)

			if r == nil then
				r = 0
			end
			if g == nil then
				g = 0
			end
			if b == nil then
				b = 0
			end

			mod:echo("[RGB DEBUG] r: " .. tostring(r) .. " g: " .. tostring(g) .. " b: " .. tostring(b))

			content.r_value = tostring(r)
			content.g_value = tostring(g)
			content.b_value = tostring(b)

			style.r_fill.size[1] = (r / 255) * BAR_WIDTH
			style.g_fill.size[1] = (g / 255) * BAR_WIDTH
			style.b_fill.size[1] = (b / 255) * BAR_WIDTH

			style.preview_style.color = {
				255,
				r,
				g,
				b,
			}

			local display_name = entry.display_name or Managers.localization:localize("loc_settings_option_unavailable")
			content.text = display_name
			content.entry = entry
			content.area_length = BAR_WIDTH
			content.step_size = entry.step_size_fraction
			content.apply_on_drag = entry.apply_on_drag and true
			local get_function = entry.get_function
			local value, value_fraction = get_function(entry)
			content.previous_slider_value = value_fraction
			content.slider_value = value_fraction
			entry.pressed_callback = callback(parent, callback_name, widget, entry)

			entry.changed_callback = function(changed_value)
				callback(parent, changed_callback_name, widget, entry)()
			end
		end,

		update = function(parent, widget, input_service, dt, t)
			local content = widget.content
			local style = widget.style

			local r = get_value(content.r_entry)
			local g = get_value(content.g_entry)
			local b = get_value(content.b_entry)

			mod:echo("[RGB DEBUG] r: " .. r .. " g: " .. g .. " b: " .. b)

			content.r_value = tostring(r)
			content.g_value = tostring(g)
			content.b_value = tostring(b)

			style.r_fill.size[1] = (r / 255) * BAR_WIDTH
			style.g_fill.size[1] = (g / 255) * BAR_WIDTH
			style.b_fill.size[1] = (b / 255) * BAR_WIDTH

			style.preview_style.color = {
				255,
				r,
				g,
				b,
			}

			local content = widget.content
			local entry = content.entry
			local pass_input = true
			local is_disabled = entry.disabled or false
			content.disabled = is_disabled
			local using_gamepad = not parent:using_cursor_navigation()
			local get_function = entry.get_function
			local value, value_fraction = get_function(entry)
			local on_activated = entry.on_activated
			local format_value_function = entry.format_value_function
			local num_decimals = entry.num_decimals
			local drag_value, new_value_fraction = nil
			local apply_on_drag = entry.apply_on_drag and not is_disabled
			local drag_active = content.drag_active and not is_disabled
			local drag_previously_active = content.drag_previously_active
			local focused = content.exclusive_focus and using_gamepad and not is_disabled

			if drag_active or focused then
				drag_value = math.lerp(entry.min_value, entry.max_value, content.slider_value)
			elseif not focused or drag_previously_active then
				local previous_slider_value = content.previous_slider_value
				local slider_value = content.slider_value

				if drag_previously_active then
					if previous_slider_value ~= slider_value then
						new_value_fraction = slider_value
						drag_value = math.lerp(entry.min_value, entry.max_value, new_value_fraction)
					end
				elseif value_fraction ~= slider_value then
					content.slider_value = value_fraction
					content.previous_slider_value = value_fraction
					content.scroll_add = nil
				end

				content.previous_slider_value = slider_value
			end

			content.drag_previously_active = drag_active
			local display_value = nil

			if format_value_function then
				display_value = format_value_function(entry, drag_value or value)
			else
				local number_format = string.format("%%.%sf", num_decimals or DEFAULT_NUM_DECIMALS)
				display_value = string.format(number_format, drag_value or value)
			end

			if display_value then
				content.value_text = display_value
			end

			local hotspot = content.hotspot

			if hotspot.on_pressed and not is_disabled then
				if focused then
					new_value_fraction = content.slider_value
				elseif not hotspot.is_hover then
					entry.pressed_callback()
				end
			end

			if focused and parent:can_exit() then
				parent:set_can_exit(false)
			end

			if
				apply_on_drag
				and drag_value
				and not new_value_fraction
				and content.slider_value ~= content.previous_slider_value
			then
				new_value_fraction = content.slider_value
			end

			if new_value_fraction then
				local new_value = math.lerp(entry.min_value, entry.max_value, new_value_fraction)

				on_activated(new_value, entry)
				entry.changed_callback(new_value)

				content.slider_value = new_value_fraction
				content.previous_slider_value = new_value_fraction
				content.scroll_add = nil
			end

			return pass_input
		end,
	},
}

return blueprints
