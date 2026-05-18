local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")

local blueprints = {}

local settings_grid_width = 850
local widget_height = 190

local BAR_WIDTH_RGB = 160 --240
local BAR_WIDTH_ARGB = 160
local BAR_HEIGHT = 28

local PREVIEW_WIDTH = 40
local PREVIEW_HEIGHT = 40

-- ############################################################
-- Colors
-- ############################################################

local COLORS = {
	text_normal = Color.terminal_text_header(nil, true),
	text_hover = Color.terminal_text_header_selected(nil, true),
	text_selected = Color.terminal_text_header_selected(nil, true),

	background = Color.terminal_background(nil, true),
	background_hover = Color.terminal_background_gradient(nil, true),
	background_selected = Color.terminal_background_gradient_selected(nil, true),

	frame = Color.terminal_corner(nil, true),
	frame_hover = Color.terminal_corner_hover(nil, true),
	frame_selected = Color.terminal_frame_selected(nil, true),

	divider = Color.terminal_frame(nil, true),
}

-- ############################################################
-- Cached constants
-- ############################################################

local math_clamp = math.clamp
local math_floor = math.floor

local tostring = tostring

local sliders_cached = {
	a = {
		hotspot = "a_hotspot",
		dragging = "a_dragging",
		start_x = "a_drag_start_cursor_x",
		start_value = "a_drag_start_value",
		value = "a_value",
		value_text = "a_value_text",
		fill = "a_fill",
	},
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
		if not content[name .. "_editing"] then
			content[slider.value_text] = tostring(value)
		end
	end

	-- cached fill style reference
	widget["_" .. name .. "_fill"].size[1] = (value / 255) * BAR_WIDTH_RGB
end

local function slider_input(widget, content, cursor, left_hold, confirm_pressed, slider_name, entry)
	local slider = sliders_cached[slider_name]

	if content[slider_name .. "_editing"] then
		return
	end

	local hotspot = content[slider.hotspot]
	local value_hotspot = content[slider_name .. "_value_hotspot"]

	if not hotspot or not cursor then
		return
	end

	local inside = hotspot.is_hover

	-- prevent text hotspot from triggering slider drag
	if value_hotspot and value_hotspot.is_hover then
		inside = false
	end

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

		local value = math_clamp(math_floor(start_value + (delta / BAR_WIDTH_RGB) * 255 + 0.5), 0, 255)

		set_value(entry, value)
	end
end

local function value_text_input(widget, content, input_service, slider_name, entry)
	local editing_key = slider_name .. "_editing"
	local buffer_key = slider_name .. "_edit_buffer"
	local hotspot_key = slider_name .. "_value_hotspot"
	local text_key = slider_name .. "_value_text"

	local hotspot = content[hotspot_key]

	if not hotspot then
		return
	end

	-- ############################################################
	-- Begin Editing
	-- ############################################################

	if hotspot.on_pressed then
		content[editing_key] = true

		local current = tostring(get_value(entry))

		content[buffer_key] = current
		content[text_key] = current

		return
	end

	-- ############################################################
	-- Not Editing
	-- ############################################################

	if not content[editing_key] then
		return
	end

	-- ############################################################
	-- Read Typed Characters
	-- ############################################################

	local keystrokes = Keyboard.keystrokes()

	if keystrokes then
		local buffer = content[buffer_key]

		for i = 1, #keystrokes do
			local char = keystrokes[i]

			if char:match("%d") then
				if #buffer < 3 then
					buffer = buffer .. char
				end
			end
		end

		content[buffer_key] = buffer
		content[text_key] = buffer
	end

	-- ############################################################
	-- Backspace
	-- ############################################################

	if Keyboard.pressed(Keyboard.button_index("backspace")) then
		local buffer = content[buffer_key]

		buffer = buffer:sub(1, #buffer - 1)

		content[buffer_key] = buffer
		content[text_key] = buffer
	end

	-- ############################################################
	-- Confirm
	-- ############################################################

	if Keyboard.pressed(Keyboard.button_index("enter")) then
		local value = tonumber(content[buffer_key])

		if value then
			value = math_clamp(value, 0, 255)

			set_value(entry, value)
		end

		content[editing_key] = false
	end

	-- ############################################################
	-- Cancel
	-- ############################################################

	if Keyboard.pressed(Keyboard.button_index("escape")) then
		content[editing_key] = false

		local value = get_value(entry)

		content[text_key] = tostring(value)
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
			pass_type = "hotspot",
			content_id = name .. "_value_hotspot",
			style_id = name .. "_value_hotspot_style",
		},

		{
			pass_type = "rect",
			style_id = name .. "_bg",
		},

		{
			pass_type = "texture",

			value_id = name .. "_frame_texture",

			style_id = name .. "_frame",

			visibility_function = function(content, style)
				local hotspot = content[name .. "_hotspot"]

				return hotspot and hotspot.is_hover
			end,
		},

		{
			pass_type = "texture",

			value_id = name .. "_frame_texture",

			style_id = name .. "_value_frame",

			visibility_function = function(content, style)
				local hotspot = content[name .. "_value_hotspot"]

				return hotspot and hotspot.is_hover
			end,
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
		[name .. "_value_hotspot"] = {},

		[name .. "_dragging"] = false,

		[name .. "_label"] = label,

		[name .. "_frame_texture"] = "content/ui/materials/frames/frame_tile_1px",

		[name .. "_value"] = -1,
		[name .. "_value_text"] = "0",

		[name .. "_editing"] = false,
		[name .. "_edit_buffer"] = "",
	}, {
		[name .. "_hotspot_style"] = {
			offset = { x, 0, 10 },
			size = { PREVIEW_WIDTH + BAR_WIDTH_RGB, BAR_HEIGHT },
			visible = true,
		},

		[name .. "_value_hotspot_style"] = {
			offset = { PREVIEW_WIDTH + x + BAR_WIDTH_RGB + 2, 0, 10 },
			size = { 60, BAR_HEIGHT },
			visible = true,
		},

		[name .. "_bg"] = {
			color = COLORS.background,
			offset = { PREVIEW_WIDTH + x, 0, 0 },
			size = { BAR_WIDTH_RGB, BAR_HEIGHT },
		},

		[name .. "_frame"] = {
			scale_to_material = true,

			color = COLORS.frame_hover,

			offset = { PREVIEW_WIDTH + x - 2, -2, 4 },

			size = { BAR_WIDTH_RGB + 4, BAR_HEIGHT + 4 },
		},

		[name .. "_value_frame"] = {
			scale_to_material = true,

			color = COLORS.frame_hover,

			offset = { PREVIEW_WIDTH + x + BAR_WIDTH_RGB, -2, 4 },

			size = { 55, BAR_HEIGHT + 4 },
		},

		[name .. "_fill"] = {
			color = color,
			offset = { PREVIEW_WIDTH + x, 0, 1 },
			size = { 0, BAR_HEIGHT },
		},

		[name .. "_label_style"] = {
			font_type = "proxima_nova_bold",
			horizontal_alignment = "left",
			vertical_alignment = "center",
			font_size = 24,
			text_color = { 255, 255, 255, 255 },
			offset = { PREVIEW_WIDTH + x - 22, -2, 2 },
		},

		[name .. "_value_style"] = {
			font_type = "proxima_nova_bold",
			horizontal_alignment = "left",
			vertical_alignment = "center",
			font_size = 24,
			text_color = { 255, 255, 255, 255 },
			offset = { PREVIEW_WIDTH + x + BAR_WIDTH_RGB + 5, -2, 2 },
		},
	}
end

-- ############################################################
-- Blueprint builder
-- ############################################################

local function build_blueprint(has_alpha)
	local slider_configs = has_alpha and {
		{ name = "a", label = "A" },
		{ name = "r", label = "R" },
		{ name = "g", label = "G" },
		{ name = "b", label = "B" },
	} or {
		{ name = "r", label = "R" },
		{ name = "g", label = "G" },
		{ name = "b", label = "B" },
	}

	local passes = {}
	local content = {}
	local style = {}

	for i, config in ipairs(slider_configs) do
		local x = PREVIEW_WIDTH + 5 + (BAR_WIDTH_RGB + 85) * (i - 1)
		local p, c, s = create_slider(config.name, x, COLORS.frame, config.label)

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
		offset = { 0, -0.25 * PREVIEW_HEIGHT, 0 },
		size = { PREVIEW_WIDTH, PREVIEW_HEIGHT },
	}

	local function cache_fills(widget, style)
		for _, config in ipairs(slider_configs) do
			widget["_" .. config.name .. "_fill"] = style[config.name .. "_fill"]
		end
		widget._preview_color = style.preview_style.color
	end

	local function get_values(content)
		local values = {}
		for _, config in ipairs(slider_configs) do
			values[config.name] = get_value(content[config.name .. "_entry"])
		end
		return values
	end

	local function update_visuals(widget, values)
		for name, value in pairs(values) do
			update_slider_visuals(widget, name, value)
		end
	end

	local function handle_inputs(widget, content, cursor, left_hold, confirm_pressed, input_service)
		for _, config in ipairs(slider_configs) do
			slider_input(widget, content, cursor, left_hold, confirm_pressed, config.name, content[config.name .. "_entry"])
		end
	end

	local function handle_text_inputs(widget, content, input_service)
		for _, config in ipairs(slider_configs) do
			value_text_input(widget, content, input_service, config.name, content[config.name .. "_entry"])
		end
	end

	local init = function(parent, widget, entry)
		local content = widget.content
		local style = widget.style

		cache_fills(widget, style)

		local values = get_values(content)

		update_visuals(widget, values)

		local preview_color = widget._preview_color

		preview_color[1] = has_alpha and (values.a or 255) or 255
		preview_color[2] = values.r
		preview_color[3] = values.g
		preview_color[4] = values.b
	end

	local update_fn = function(parent, widget, input_service, dt, t)
		local content = widget.content

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
		handle_inputs(widget, content, cursor, left_hold, confirm_pressed, input_service)

		-- ############################################################
		-- Text Value Input
		-- ############################################################
		handle_text_inputs(widget, content, input_service)

		-- ############################################################
		-- Refresh Values
		-- ############################################################
		local values = get_values(content)

		update_visuals(widget, values)

		local preview_color = widget._preview_color

		preview_color[1] = has_alpha and (values.a or 255) or 255
		preview_color[2] = values.r
		preview_color[3] = values.g
		preview_color[4] = values.b

		return true
	end

	return {
		size = {
			settings_grid_width,
			widget_height,
		},

		pass_template = passes,
		content = content,
		style = style,
		init = init,
		update = update_fn,
	}
end

-- ############################################################
-- Blueprints
-- ############################################################

blueprints = {
	rgb_widget = build_blueprint(false),
	rgb_widget_argb = build_blueprint(true),
}

return blueprints
