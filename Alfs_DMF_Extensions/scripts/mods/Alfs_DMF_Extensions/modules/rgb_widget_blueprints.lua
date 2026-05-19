local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIResolution = require("scripts/managers/ui/ui_resolution")

local blueprints = {}

local settings_grid_width = 850
local widget_height = 190

local BAR_WIDTH_RGB = 240
local BAR_WIDTH_ARGB = 160
local BAR_HEIGHT = 28

local PREVIEW_WIDTH = 40
local PREVIEW_HEIGHT = 40

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

local function update_slider_visuals(widget, name, value, bar_width)
	local content = widget.content
	local slider = sliders_cached[name]

	if content[slider.value] ~= value then
		content[slider.value] = value
		if not content[name .. "_editing"] then
			content[slider.value_text] = tostring(value)
		end
	end

	widget["_" .. name .. "_fill"].size[1] = (value / 255) * bar_width
end

local function cursor_to_ui_space(input_service, parent)
	if not input_service then
		return nil
	end

	local cursor = input_service:get("cursor")

	if not cursor then
		return nil
	end

	if IS_XBS or IS_PLAYSTATION then
		return { cursor[1], cursor[2] }
	end

	local render_scale = parent and parent._render_scale or 1

	return UIResolution.inverse_scale_vector(cursor, 1 / render_scale)
end

local function get_bar_ui_x(parent, widget, slider_name)
	local pivot_pos = parent and parent:_scenegraph_world_position("settings_grid_content_pivot")

	if not pivot_pos then
		return nil
	end

	local bg_style = widget.style[slider_name .. "_bg"]

	return pivot_pos[1] + (widget.offset and widget.offset[1] or 0) + bg_style.offset[1]
end

local function slider_input(
	parent,
	widget,
	content,
	cursor_ui,
	left_hold,
	confirm_pressed,
	slider_name,
	entry,
	bar_width
)
	local slider = sliders_cached[slider_name]

	if content[slider_name .. "_editing"] then
		return
	end

	local hotspot = content[slider.hotspot]
	local value_hotspot = content[slider_name .. "_value_hotspot"]
	local label_hotspot = content[slider_name .. "_label_hotspot"]

	if not hotspot or not cursor_ui then
		return
	end

	local inside = hotspot.is_hover

	if value_hotspot and value_hotspot.is_hover then
		inside = false
	end

	if label_hotspot and label_hotspot.is_hover then
		inside = false
	end

	local dragging = content[slider.dragging]

	if inside and (left_hold or confirm_pressed) and not dragging then
		content[slider.dragging] = true
		dragging = true

		content[slider.start_x] = cursor_ui[1]
		content[slider.start_value] = get_value(entry)

		local bar_ui_x = get_bar_ui_x(parent, widget, slider_name)

		if bar_ui_x then
			local bar_cursor_x = cursor_ui[1] - bar_ui_x
			local click_value = math_clamp(math_floor((bar_cursor_x / bar_width) * 255), 0, 255)

			content[slider.start_value] = click_value
			set_value(entry, click_value)

			content[slider.start_x] = cursor_ui[1]
		end
	end

	if dragging and not left_hold then
		content[slider.dragging] = false

		return
	end

	if dragging then
		local delta = cursor_ui[1] - content[slider.start_x]
		local value = math_clamp(math_floor(content[slider.start_value] + (delta / bar_width) * 255), 0, 255)

		if content[slider.value] ~= value then
			content[slider.value] = value
			set_value(entry, value)

			if not content[slider_name .. "_editing"] then
				content[slider.value_text] = tostring(value)
			end
		end

		widget["_" .. slider_name .. "_fill"].size[1] = (value / 255) * bar_width
	end
end

local ENTER_INDEX = Keyboard.button_index("enter")
local ESCAPE_INDEX = Keyboard.button_index("escape")

local _editing_context = nil

local function stop_editing(content, slider_name)
	if _editing_context and (_editing_context.content ~= content or _editing_context.slider_name ~= slider_name) then
		return
	end

	local entry = content[slider_name .. "_entry"]

	content[slider_name .. "_editing"] = false

	local new_value = entry and tostring(get_value(entry))
	if not new_value or new_value == "" then
		new_value = content[content.slider_name .. "_prev_value_text"]
	end

	content[slider_name .. "_value_text"] = new_value
	content._last_input_time = nil
	_editing_context = nil
end

local function start_editing(content, slider_name)
	if _editing_context and _editing_context.content ~= content then
		local prev = _editing_context
		local prev_entry = prev.content[prev.slider_name .. "_entry"]

		prev.content[prev.slider_name .. "_editing"] = false
		prev.content[prev.slider_name .. "_value_text"] = "" --prev_entry and tostring(get_value(prev_entry)) or "0"
	end

	content[slider_name .. "_editing"] = true

	local entry = content[slider_name .. "_entry"]
	local current = "" --entry and tostring(get_value(entry)) or "0"

	content[slider_name .. "_edit_buffer"] = current
	content[slider_name .. "_value_text"] = current
	content[slider_name .. "_prev_value_text"] = entry and tostring(get_value(entry)) or "0"

	_editing_context = { content = content, slider_name = slider_name }
end

local function confirm_value(content, slider_name, buffer)
	local entry = content[slider_name .. "_entry"]
	local value = tonumber(buffer)

	if value then
		value = math_clamp(value, 0, 255)
		set_value(entry, value)
	end

	content._last_input_time = nil
end

local function value_text_input(parent, widget, content, input_service, slider_name, entry, bar_width, keystrokes, t)
	local editing_key = slider_name .. "_editing"
	local buffer_key = slider_name .. "_edit_buffer"
	local text_key = slider_name .. "_value_text"
	local hotspot = content[slider_name .. "_value_hotspot"]

	if not hotspot then
		return
	end

	-- click detection (on_pressed persists from previous draw)
	if hotspot.on_pressed and not content[editing_key] then
		start_editing(content, slider_name)
	end

	if not content[editing_key] then
		return
	end

	local buffer = content[buffer_key] or ""
	local changed = false

	if keystrokes then
		for i = 1, #keystrokes do
			local ks = keystrokes[i]

			if type(ks) == "string" and ks:match("^%d$") then
				if #buffer < 3 then
					buffer = buffer .. ks
					changed = true
				elseif #buffer >= 3 then
					buffer = buffer:sub(1, 2) .. ks
					changed = true
				end
			elseif ks == Keyboard.BACKSPACE then
				buffer = buffer:sub(1, #buffer - 1)
				changed = true
			end
		end
	end

	if changed then
		content[buffer_key] = buffer
		content[text_key] = buffer

		if t then
			content._last_input_time = t
		end
	end

	-- Enter to confirm
	if Keyboard.pressed(ENTER_INDEX) then
		confirm_value(content, slider_name, buffer)
		stop_editing(content, slider_name)
		return
	end

	-- Escape to cancel
	if Keyboard.pressed(ESCAPE_INDEX) then
		stop_editing(content, slider_name)
		return
	end
end

local _gamepad_slider_index = 0

local function slider_gamepad_input(
	parent,
	widget,
	content,
	input_service,
	slider_name,
	entry,
	bar_width,
	slider_index,
	num_sliders
)
	if content[slider_name .. "_editing"] then
		return
	end

	if input_service:get("navigate_next") then
		_gamepad_slider_index = (_gamepad_slider_index + 1) % num_sliders

		return
	end

	if slider_index ~= _gamepad_slider_index then
		return
	end

	local left = input_service:get("navigate_left_continuous_fast")
	local right = input_service:get("navigate_right_continuous_fast")
	local current = get_value(entry)

	if left then
		local new_value = math_clamp(current - 1, 0, 255)

		if new_value ~= current then
			set_value(entry, new_value)
			content[sliders_cached[slider_name].value] = new_value
			content[sliders_cached[slider_name].value_text] = tostring(new_value)
			widget["_" .. slider_name .. "_fill"].size[1] = (new_value / 255) * bar_width
		end
	elseif right then
		local new_value = math_clamp(current + 1, 0, 255)

		if new_value ~= current then
			set_value(entry, new_value)
			content[sliders_cached[slider_name].value] = new_value
			content[sliders_cached[slider_name].value_text] = tostring(new_value)
			widget["_" .. slider_name .. "_fill"].size[1] = (new_value / 255) * bar_width
		end
	end
end

local function create_slider(name, x, color, label, bar_width, label_color)
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
			change_function = function(hotspot_content, style)
				if hotspot_content.on_pressed then
					local content = hotspot_content.parent
					start_editing(content, name)
				end
			end,
		},
		{
			pass_type = "hotspot",
			content_id = name .. "_label_hotspot",
			style_id = name .. "_label_hotspot_style",
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
				return content[name .. "_editing"] or (hotspot and hotspot.is_hover)
			end,
		},
		{
			pass_type = "rect",
			style_id = name .. "_edit_bg",
			visibility_function = function(content, style)
				return content[name .. "_editing"]
			end,
		},
		{
			pass_type = "rect",
			style_id = name .. "_caret",
			visibility_function = function(content, style)
				return content[name .. "_editing"]
			end,
			change_function = function(content, style)
				local buf = content[name .. "_edit_buffer"] or ""
				local pos = math.min(#buf + 1, 4)
				style.offset[1] = PREVIEW_WIDTH + x + bar_width + 5 + (pos - 1) * 16
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
			change_function = function(content, style)
				if content[name .. "_editing"] then
					style.text_color[2] = COLORS.text_selected[2]
					style.text_color[3] = COLORS.text_selected[3]
					style.text_color[4] = COLORS.text_selected[4]
				else
					style.text_color[2] = COLORS.text_normal[2]
					style.text_color[3] = COLORS.text_normal[3]
					style.text_color[4] = COLORS.text_normal[4]
				end
			end,
		},
	}, {
		[name .. "_hotspot"] = {},
		[name .. "_value_hotspot"] = {},
		[name .. "_label_hotspot"] = {},
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
			size = { PREVIEW_WIDTH + bar_width, BAR_HEIGHT },
			visible = true,
		},
		[name .. "_value_hotspot_style"] = {
			offset = { PREVIEW_WIDTH + x + bar_width + 2, 0, 10 },
			size = { 60, BAR_HEIGHT },
			visible = true,
		},
		[name .. "_label_hotspot_style"] = {
			offset = { PREVIEW_WIDTH + x - 26, 0, 9 },
			size = { 24, BAR_HEIGHT },
			visible = true,
		},
		[name .. "_bg"] = {
			color = COLORS.background,
			offset = { PREVIEW_WIDTH + x, 0, 0 },
			size = { bar_width, BAR_HEIGHT },
		},
		[name .. "_frame"] = {
			scale_to_material = true,
			color = COLORS.frame_hover,
			offset = { PREVIEW_WIDTH + x - 2, -2, 4 },
			size = { bar_width + 4, BAR_HEIGHT + 4 },
		},
		[name .. "_value_frame"] = {
			scale_to_material = true,
			color = COLORS.frame_hover,
			offset = { PREVIEW_WIDTH + x + bar_width, -2, 4 },
			size = { 55, BAR_HEIGHT + 4 },
		},
		[name .. "_edit_bg"] = {
			color = COLORS.background_hover,
			offset = { PREVIEW_WIDTH + x + bar_width + 2, 0, 0 },
			size = { 53, BAR_HEIGHT },
		},
		[name .. "_caret"] = {
			color = COLORS.text_selected,
			offset = { PREVIEW_WIDTH + x + bar_width + 5, 2, 5 },
			size = { 2, 24 },
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
			text_color = label_color or COLORS.text_selected,
			offset = { PREVIEW_WIDTH + x - 22, -2, 2 },
		},
		[name .. "_value_style"] = {
			font_type = "proxima_nova_bold",
			horizontal_alignment = "left",
			vertical_alignment = "center",
			font_size = 24,
			text_color = COLORS.text_selected,
			offset = { PREVIEW_WIDTH + x + bar_width + 5, -2, 2 },
		},
	}
end

local function build_blueprint(has_alpha)
	local label_colors = {
		a = { 255, 200, 200, 200 },
		r = { 255, 255, 60, 60 },
		g = { 255, 60, 200, 60 },
		b = { 255, 60, 60, 255 },
	}

	local slider_configs = has_alpha
			and {
				{ name = "a", label = "A" },
				{ name = "r", label = "R" },
				{ name = "g", label = "G" },
				{ name = "b", label = "B" },
			}
		or {
			{ name = "r", label = "R" },
			{ name = "g", label = "G" },
			{ name = "b", label = "B" },
		}

	local bar_width = has_alpha and BAR_WIDTH_ARGB or BAR_WIDTH_RGB

	local passes = {}
	local content = {}
	local style = {}

	for i, config in ipairs(slider_configs) do
		local x = PREVIEW_WIDTH + 5 + (bar_width + 85) * (i - 1)
		local p, c, s = create_slider(config.name, x, COLORS.frame, config.label, bar_width, label_colors[config.name])

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

	local function handle_inputs(parent, widget, content, cursor_ui, left_hold, confirm_pressed)
		for _, config in ipairs(slider_configs) do
			slider_input(
				parent,
				widget,
				content,
				cursor_ui,
				left_hold,
				confirm_pressed,
				config.name,
				content[config.name .. "_entry"],
				bar_width
			)
		end
	end

	local function handle_text_inputs(parent, widget, content, input_service, dt, t)
		-- first pass: detect clicks (start editing) without consuming keystrokes
		for _, config in ipairs(slider_configs) do
			value_text_input(
				parent,
				widget,
				content,
				input_service,
				config.name,
				content[config.name .. "_entry"],
				bar_width,
				nil,
				t
			)
		end

		-- check if any slider is now editing
		local any_editing = false

		for _, config in ipairs(slider_configs) do
			if content[config.name .. "_editing"] then
				any_editing = true
				break
			end
		end

		-- second pass: process keystrokes for editing sliders
		if any_editing then
			local keystrokes = Keyboard.keystrokes()

			for _, config in ipairs(slider_configs) do
				if content[config.name .. "_editing"] then
					value_text_input(
						parent,
						widget,
						content,
						input_service,
						config.name,
						content[config.name .. "_entry"],
						bar_width,
						keystrokes,
						t
					)
				end
			end
		end
	end

	local function handle_gamepad_inputs(parent, widget, content, input_service)
		local num_sliders = #slider_configs

		for i, config in ipairs(slider_configs) do
			slider_gamepad_input(
				parent,
				widget,
				content,
				input_service,
				config.name,
				content[config.name .. "_entry"],
				bar_width,
				i - 1,
				num_sliders
			)
		end
	end

	local init = function(parent, widget, entry)
		local content = widget.content
		local style = widget.style

		cache_fills(widget, style)
		content.hotspot = {}

		local preview_color = widget._preview_color

		for _, config in ipairs(slider_configs) do
			local value = get_value(content[config.name .. "_entry"])

			update_slider_visuals(widget, config.name, value, bar_width)

			if config.name == "a" then
				preview_color[1] = value
			elseif config.name == "r" then
				preview_color[2] = value
			elseif config.name == "g" then
				preview_color[3] = value
			elseif config.name == "b" then
				preview_color[4] = value
			end
		end

		if not has_alpha then
			preview_color[1] = 255
		end
	end

	local update_fn = function(parent, widget, input_service, dt, t)
		local content = widget.content

		local cursor_ui = cursor_to_ui_space(input_service, parent)

		if not cursor_ui then
			return true
		end

		local left_hold = input_service:get("left_hold")
		local confirm_pressed = input_service:get("confirm_pressed")

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

			if group and target_offset == group.offset then
				y = y - 50
			end

			if offset[1] ~= target_offset[1] or offset[2] ~= y then
				offset[1] = target_offset[1]
				offset[2] = y
				offset[3] = target_offset[3] or 0
			end
		end

		handle_inputs(parent, widget, content, cursor_ui, left_hold, confirm_pressed)
		handle_text_inputs(parent, widget, content, input_service, dt, t)

		-- auto-accept checks for editing sliders
		local prev_left_hold = content._prev_left_hold
		content._prev_left_hold = left_hold

		for _, config in ipairs(slider_configs) do
			if content[config.name .. "_editing"] then
				local value_hotspot = content[config.name .. "_value_hotspot"]

				-- click-off: left mouse pressed while not over value hotspot
				if left_hold and not prev_left_hold and not (value_hotspot and value_hotspot.is_hover) then
					local buffer = content[config.name .. "_edit_buffer"]
					confirm_value(content, config.name, buffer)
					stop_editing(content, config.name)
				end

				-- timeout: 5 seconds without input
				if not content._last_input_time then
					content._last_input_time = t
				end

				if t - content._last_input_time > 5 then
					local buffer = content[config.name .. "_edit_buffer"]
					confirm_value(content, config.name, buffer)
					stop_editing(content, config.name)
				end
			end
		end

		local using_gamepad = not parent:using_cursor_navigation()

		if using_gamepad then
			handle_gamepad_inputs(parent, widget, content, input_service)
		end

		local hovered_slider = nil
		local any_hover = false

		for _, config in ipairs(slider_configs) do
			local label_hotspot = content[config.name .. "_label_hotspot"]

			if label_hotspot and label_hotspot.is_hover then
				hovered_slider = config.name
				any_hover = true
				break
			end
		end

		content.hotspot.is_hover = any_hover

		if any_hover and hovered_slider then
			local entry = content[hovered_slider .. "_entry"]

			if entry and (entry.tooltip_text or entry.disabled_by) then
				local tooltip = parent._widgets_by_name and parent._widgets_by_name.tooltip

				if tooltip then
					tooltip.content.visible = true
					tooltip.content.text = entry.tooltip_text or ""

					local text_style = tooltip.style.text
					local pivot_pos = parent:_scenegraph_world_position("settings_grid_content_pivot")
					local tooltip_width = (widget.content.size and widget.content.size[1] or settings_grid_width) * 0.5
					local _, text_height = parent:_text_size(entry.tooltip_text or "", text_style, { tooltip_width, 0 })
					local height = text_height

					tooltip.content.size = { tooltip_width, height }

					local left_edge_x = pivot_pos and pivot_pos[1] + (widget.offset and widget.offset[1] or 0) or 0
					tooltip.offset[1] = left_edge_x - tooltip_width - 10
					tooltip.offset[2] = (pivot_pos and pivot_pos[2] or 0) + (widget.offset and widget.offset[2] or 0) - height - 10
				end

				parent._tooltip_data = {
					widget = widget,
					text = entry.tooltip_text or "",
				}
			end
		elseif parent._tooltip_data and parent._tooltip_data.widget == widget then
			parent._tooltip_data = {}

			local tooltip = parent._widgets_by_name and parent._widgets_by_name.tooltip

			if tooltip then
				tooltip.content.visible = false
			end
		end

		for _, config in ipairs(slider_configs) do
			local value

			if content[config.name .. "_dragging"] then
				value = content[sliders_cached[config.name].value]
			else
				value = get_value(content[config.name .. "_entry"])
			end

			update_slider_visuals(widget, config.name, value, bar_width)
		end

		local preview_color = widget._preview_color

		preview_color[1] = has_alpha and (content.a_value or 255) or 255
		preview_color[2] = content.r_value
		preview_color[3] = content.g_value
		preview_color[4] = content.b_value

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

blueprints = {
	rgb_widget = build_blueprint(false),
	rgb_widget_argb = build_blueprint(true),
}

return blueprints
