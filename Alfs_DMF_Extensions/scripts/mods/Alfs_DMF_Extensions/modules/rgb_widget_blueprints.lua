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
-- Cached constants
-- ############################################################

local math_clamp = math.clamp
local math_floor = math.floor

local tostring = tostring

local sliders_cached = {
	r = {
		hotspot = "r_hotspot",
		dragging = "r_dragging",
		start_x = "r_drag_start_cursor_x",
		start_value = "r_drag_start_value",
		value = "r_value",
		value_text = "r_value_text",
		fill = "r_fill",
	},
	g = {
		hotspot = "g_hotspot",
		dragging = "g_dragging",
		start_x = "g_drag_start_cursor_x",
		start_value = "g_drag_start_value",
		value = "g_value",
		value_text = "g_value_text",
		fill = "g_fill",
	},
	b = {
		hotspot = "b_hotspot",
		dragging = "b_dragging",
		start_x = "b_drag_start_cursor_x",
		start_value = "b_drag_start_value",
		value = "b_value",
		value_text = "b_value_text",
		fill = "b_fill",
	},
}

-- ############################################################
-- Helpers
-- ############################################################

local function get_value(entry)
	if not entry or not entry.get_function then
		return 255
	end

	local value = entry.get_function()

	if value == nil then
		return 255
	end

	return value
end

local function set_value(entry, value)
	if not entry then
		return
	end

	if entry.on_activated then
		entry.on_activated(value, entry)
	end

	if entry.changed_callback then
		entry.changed_callback(value)
	end
end

local function update_slider_visuals(widget, name, value)
	local content = widget.content
	local slider = sliders_cached[name]

	-- only update text when changed
	if content[slider.value] ~= value then
		content[slider.value] = value
		content[slider.value_text] = tostring(value)
	end

	-- cached fill style reference
	widget["_" .. name .. "_fill"].size[1] = (value / 255) * BAR_WIDTH
end

local function slider_input(widget, content, cursor, left_hold, confirm_pressed, slider_name, entry)
	local slider = sliders_cached[slider_name]

	local hotspot = content[slider.hotspot]

	if not hotspot or not cursor then
		return
	end

	local inside = hotspot.is_hover

	-- ############################################################
	-- Start Drag
	-- ############################################################

	local dragging = content[slider.dragging]

	if inside and (left_hold or confirm_pressed) and not dragging then
		content[slider.dragging] = true
		content[slider.start_x] = cursor[1]
		content[slider.start_value] = get_value(entry)

		dragging = true
	end

	-- ############################################################
	-- End Drag
	-- ############################################################

	if dragging and not left_hold then
		content[slider.dragging] = false
		return
	end

	-- ############################################################
	-- Mouse leaves area
	-- ############################################################

	if dragging and not inside then
		content[slider.dragging] = false
		return
	end

	-- ############################################################
	-- Drag Update
	-- ############################################################

	if dragging then
		local start_x = content[slider.start_x] or cursor[1]
		local start_value = content[slider.start_value] or 0

		local delta = cursor[1] - start_x

		local value = math_clamp(math_floor(start_value + (delta / BAR_WIDTH) * 255 + 0.5), 0, 255)

		set_value(entry, value)
	end
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
			value_id = name .. "_value_text",
			style_id = name .. "_value_style",
		},
	}, {
		[name .. "_hotspot"] = {},
		[name .. "_dragging"] = false,

		[name .. "_label"] = label,

		[name .. "_value"] = -1,
		[name .. "_value_text"] = "0",
	}, {
		[name .. "_hotspot_style"] = {
			offset = { x, 0, 10 },
			size = { BAR_WIDTH, BAR_HEIGHT },
			visible = true,
		},

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
		color = { 255, 255, 80, 80 },
		label = "R",
	},
	{
		name = "g",
		x = PREVIEW_WIDTH + 10 + (BAR_WIDTH + 100),
		color = { 255, 80, 255, 80 },
		label = "G",
	},
	{
		name = "b",
		x = PREVIEW_WIDTH + 10 + ((BAR_WIDTH + 100) * 2),
		color = { 255, 80, 80, 255 },
		label = "B",
	},
}

for i = 1, #sliders do
	local slider = sliders[i]

	local p, c, s = create_slider(slider.name, slider.x, slider.color, slider.label)

	for j = 1, #p do
		passes[#passes + 1] = p[j]
	end

	for k, v in pairs(c) do
		content[k] = v
	end

	for k, v in pairs(s) do
		style[k] = v
	end
end

passes[#passes + 1] = {
	pass_type = "rect",
	style_id = "preview_style",
}

style.preview_style = {
	color = { 255, 255, 255, 255 },
	offset = { -PREVIEW_WIDTH, -0.25 * PREVIEW_HEIGHT, 0 },
	size = { PREVIEW_WIDTH, PREVIEW_HEIGHT },
}

-- ############################################################
-- Blueprint
-- ############################################################

blueprints = {
	rgb_widget = {
		size = {
			settings_grid_width,
			widget_height,
		},

		pass_template = passes,
		content = content,
		style = style,

		init = function(parent, widget, entry)
			local content = widget.content
			local style = widget.style

			-- cache style refs
			widget._r_fill = style.r_fill
			widget._g_fill = style.g_fill
			widget._b_fill = style.b_fill

			widget._preview_color = style.preview_style.color

			local r = get_value(content.r_entry)
			local g = get_value(content.g_entry)
			local b = get_value(content.b_entry)

			update_slider_visuals(widget, "r", r)
			update_slider_visuals(widget, "g", g)
			update_slider_visuals(widget, "b", b)

			local preview_color = widget._preview_color

			preview_color[1] = 255
			preview_color[2] = r
			preview_color[3] = g
			preview_color[4] = b
		end,

		update = function(parent, widget, input_service, dt, t)
			local content = widget.content

			-- ############################################################
			-- Cached input lookups
			-- ############################################################

			local cursor = input_service:get("cursor")

			if not cursor then
				return true
			end

			local left_hold = input_service:get("left_hold")
			local confirm_pressed = input_service:get("confirm_pressed")

			-- ############################################################
			-- Dynamic Layout Tracking
			-- ############################################################

			local offset = widget.offset

			local alignment = widget._alignment_widget
			local anchor = widget._anchor_widget
			local group = widget._group_widget

			local target_offset = nil

			if alignment and alignment.offset then
				target_offset = alignment.offset
			elseif anchor and anchor.offset then
				target_offset = anchor.offset
			elseif group and group.offset then
				target_offset = group.offset
			end

			if target_offset then
				local y = target_offset[2]

				if target_offset == group.offset then
					y = y - 50
				end

				if offset[1] ~= target_offset[1] or offset[2] ~= y then
					offset[1] = target_offset[1]
					offset[2] = y
					offset[3] = target_offset[3] or 0
				end
			end

			-- ############################################################
			-- Slider Input
			-- ############################################################

			slider_input(widget, content, cursor, left_hold, confirm_pressed, "r", content.r_entry)

			slider_input(widget, content, cursor, left_hold, confirm_pressed, "g", content.g_entry)

			slider_input(widget, content, cursor, left_hold, confirm_pressed, "b", content.b_entry)

			-- ############################################################
			-- Refresh Values
			-- ############################################################

			local r = get_value(content.r_entry)
			local g = get_value(content.g_entry)
			local b = get_value(content.b_entry)

			update_slider_visuals(widget, "r", r)
			update_slider_visuals(widget, "g", g)
			update_slider_visuals(widget, "b", b)

			local preview_color = widget._preview_color

			preview_color[1] = 255
			preview_color[2] = r
			preview_color[3] = g
			preview_color[4] = b

			return true
		end,
	},
}

return blueprints
