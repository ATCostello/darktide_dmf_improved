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
local math_round = math.round
local tostring = tostring
local type = type

local function safe_input_get(input_service, action_name, default)
	if not input_service then
		return default
	end
	local has_method = input_service.has
	if has_method and not has_method(input_service, action_name) then
		return default
	end
	local ok, result = pcall(input_service.get, input_service, action_name)
	return ok and result or default
end

local function format_value(value, decimals)
	if decimals and decimals > 0 then
		local fmt = "%." .. tostring(decimals) .. "f"
		local formatted = string.format(fmt, value)
		formatted = formatted:gsub("0+$", ""):gsub("%.$", "")
		return formatted
	end
	return tostring(math_floor(value + 0.5))
end

local function entry_min(entry)
	return entry and entry.min_value or 0
end

local function entry_max(entry)
	return entry and entry.max_value or 255
end

local function entry_range(entry)
	local lo = entry_min(entry)
	local hi = entry_max(entry)
	return hi - lo
end

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
		return entry_max(entry)
	end

	local value = entry.get_function()

	if value == nil then
		return entry_max(entry)
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
	local lo = content[name .. "_min"] or 0
	local hi = content[name .. "_max"] or 255
	local range = hi - lo
	local decimals = content[name .. "_decimals"] or 0

	if content[slider.value] ~= value then
		content[slider.value] = value
		if not content[name .. "_editing"] then
			content[slider.value_text] = format_value(value, decimals)
		end
	end

	local fraction = range > 0 and ((value - lo) / range) or 0
	widget["_" .. name .. "_fill"].size[1] = math_clamp(fraction, 0, 1) * bar_width
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
	local bar_hotspot = content[slider_name .. "_bar_hotspot"]

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
	local lo = content[slider_name .. "_min"] or 0
	local hi = content[slider_name .. "_max"] or 255
	local range = hi - lo
	local decimals = content[slider_name .. "_decimals"] or 0

	local function snap_to_step(raw_val)
		local step = entry and entry.step_size
		if step then
			return math_round(raw_val / step) * step
		end
		if decimals and decimals > 0 then
			local multiplier = 10 ^ decimals
			return math_round(raw_val * multiplier) / multiplier
		end
		return math_floor(raw_val + 0.5)
	end

	if inside and not dragging then
		local fresh_press = not content._prev_left_hold and left_hold

		if fresh_press or confirm_pressed then
			content[slider.dragging] = true
			dragging = true

			local bar_ui_x = get_bar_ui_x(parent, widget, slider_name)

			content[slider.start_x] = cursor_ui[1]
			content[slider.start_value] = get_value(entry)

			if bar_ui_x then
				local bar_cursor_x = cursor_ui[1] - bar_ui_x
				local raw = lo + (bar_cursor_x / bar_width) * range
				local click_value = math_clamp(snap_to_step(raw), lo, hi)

				content[slider.start_value] = click_value
				set_value(entry, click_value)

				content[slider.start_x] = cursor_ui[1]
			end
		end
	end

	if dragging and not left_hold then
		content[slider.dragging] = false

		return
	end

	if dragging then
		if bar_hotspot and not bar_hotspot.is_hover then
			content[slider.dragging] = false
			set_value(entry, content[slider.value])

			return
		end

		local bar_cursor_x = cursor_ui[1] - content[slider.start_x]
		local raw = content[slider.start_value] + (bar_cursor_x / bar_width) * range
		local value = math_clamp(snap_to_step(raw), lo, hi)

		if content[slider.value] ~= value then
			content[slider.value] = value
			set_value(entry, value)

			if not content[slider_name .. "_editing"] then
				content[slider.value_text] = format_value(value, decimals)
			end
		end

		local fraction = range > 0 and ((value - lo) / range) or 0
		widget["_" .. slider_name .. "_fill"].size[1] = math_clamp(fraction, 0, 1) * bar_width
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
	local decimals = content[slider_name .. "_decimals"] or 0

	content[slider_name .. "_editing"] = false

	local new_value = entry and format_value(get_value(entry), decimals)
	if not new_value or new_value == "" then
		new_value = content[slider_name .. "_prev_value_text"]
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
	local decimals = content[slider_name .. "_decimals"] or 0
	content[slider_name .. "_prev_value_text"] = entry and format_value(get_value(entry), decimals) or "0"

	_editing_context = { content = content, slider_name = slider_name }
end

local function confirm_value(content, slider_name, buffer)
	local entry = content[slider_name .. "_entry"]
	local value = tonumber(buffer)

	if value then
		local lo = content[slider_name .. "_min"] or 0
		local hi = content[slider_name .. "_max"] or 255
		local decimals = content[slider_name .. "_decimals"] or 0
		if decimals and decimals > 0 then
			local multiplier = 10 ^ decimals
			value = math_clamp(math_round(value * multiplier) / multiplier, lo, hi)
		else
			value = math_clamp(math_floor(value + 0.5), lo, hi)
		end
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

	if hotspot.on_pressed and not content[editing_key] then
		start_editing(content, slider_name)
	end

	if not content[editing_key] then
		return
	end

	local buffer = content[buffer_key] or ""
	local changed = false

	local abs_max =
		math.max(math.abs(content[slider_name .. "_min"] or 0), math.abs(content[slider_name .. "_max"] or 255))
	local int_digits = #tostring(math.floor(abs_max))
	local max_digits = int_digits + 3
	local allow_decimal = true

	if keystrokes then
		for i = 1, #keystrokes do
			local ks = keystrokes[i]

			if type(ks) == "string" and ks:match("^[%d%.]$") then
				if ks == "." then
					if allow_decimal and not buffer:find("%.") then
						buffer = buffer .. ks
						changed = true
					end
				elseif #buffer < max_digits then
					buffer = buffer .. ks
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

	if Keyboard.pressed(ENTER_INDEX) then
		confirm_value(content, slider_name, buffer)
		stop_editing(content, slider_name)
		return
	end

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

	if safe_input_get(input_service, "navigate_next") then
		_gamepad_slider_index = (_gamepad_slider_index + 1) % num_sliders

		return
	end

	if slider_index ~= _gamepad_slider_index then
		return
	end

	local left = safe_input_get(input_service, "navigate_left_continuous_fast")
	local right = safe_input_get(input_service, "navigate_right_continuous_fast")
	local current = get_value(entry)
	local lo = content[slider_name .. "_min"] or 0
	local hi = content[slider_name .. "_max"] or 255
	local range = hi - lo

	local decimals = content[slider_name .. "_decimals"] or 0

	if left then
		local new_value = math_clamp(current - 1, lo, hi)

		if new_value ~= current then
			set_value(entry, new_value)
			content[sliders_cached[slider_name].value] = new_value
			content[sliders_cached[slider_name].value_text] = format_value(new_value, decimals)
			local fraction = range > 0 and ((new_value - lo) / range) or 0
			widget["_" .. slider_name .. "_fill"].size[1] = math_clamp(fraction, 0, 1) * bar_width
		end
	elseif right then
		local new_value = math_clamp(current + 1, lo, hi)

		if new_value ~= current then
			set_value(entry, new_value)
			content[sliders_cached[slider_name].value] = new_value
			content[sliders_cached[slider_name].value_text] = format_value(new_value, decimals)
			local fraction = range > 0 and ((new_value - lo) / range) or 0
			widget["_" .. slider_name .. "_fill"].size[1] = math_clamp(fraction, 0, 1) * bar_width
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
			pass_type = "hotspot",
			content_id = name .. "_bar_hotspot",
			style_id = name .. "_bar_hotspot_style",
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
		[name .. "_bar_hotspot"] = {},
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
		[name .. "_bar_hotspot_style"] = {
			offset = { PREVIEW_WIDTH + x, 0, 9 },
			size = { bar_width, BAR_HEIGHT },
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

		local any_editing = false

		for _, config in ipairs(slider_configs) do
			if content[config.name .. "_editing"] then
				any_editing = true
				break
			end
		end

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

		for _, config in ipairs(slider_configs) do
			local ch_entry = content[config.name .. "_entry"]
			content[config.name .. "_min"] = entry_min(ch_entry)
			content[config.name .. "_max"] = entry_max(ch_entry)
			local entry_decimals = ch_entry and ch_entry.num_decimals
			if entry_decimals ~= nil and entry_decimals > 0 then
				content[config.name .. "_decimals"] = entry_decimals
			elseif ch_entry and ch_entry.step_size and ch_entry.step_size < 1 then
				content[config.name .. "_decimals"] = 2
			elseif
				ch_entry
				and (
					ch_entry.min_value ~= math.floor(ch_entry.min_value)
					or ch_entry.max_value ~= math.floor(ch_entry.max_value)
				)
			then
				content[config.name .. "_decimals"] = 2
			else
				content[config.name .. "_decimals"] = 0
			end
		end

		local preview_color = widget._preview_color

		for _, config in ipairs(slider_configs) do
			local ch_entry = content[config.name .. "_entry"]
			local value = get_value(ch_entry)
			local lo = entry_min(ch_entry)
			local hi = entry_max(ch_entry)
			local range = hi - lo

			update_slider_visuals(widget, config.name, value, bar_width)

			local normalized = range > 0 and (((value - lo) / range) * 255) or 0
			if config.name == "a" then
				preview_color[1] = normalized
			elseif config.name == "r" then
				preview_color[2] = normalized
			elseif config.name == "g" then
				preview_color[3] = normalized
			elseif config.name == "b" then
				preview_color[4] = normalized
			end
		end

		if not has_alpha then
			preview_color[1] = 255
		end
	end

	local function is_dropdown_open(parent)
		if parent and parent._settings_content_widgets then
			for i = 1, #parent._settings_content_widgets do
				local w = parent._settings_content_widgets[i]
				if w and w.type == "dropdown" and w.content then
					if w.content.exclusive_focus and w.content.selected_index then
						return true
					end
				end
			end
		end
		return false
	end

	local update_fn = function(parent, widget, input_service, dt, t)
		local content = widget.content

		local cursor_ui = cursor_to_ui_space(input_service, parent)
		local dropdown_open = is_dropdown_open(parent)

		local dropdown_just_closed = content._prev_dropdown_open and not dropdown_open
		content._prev_dropdown_open = dropdown_open

		if not cursor_ui then
			local ok_gamepad, cursor_result = pcall(parent.using_cursor_navigation, parent)
			local using_gamepad = ok_gamepad and not cursor_result or false

			if using_gamepad and not dropdown_open and not dropdown_just_closed then
				handle_gamepad_inputs(parent, widget, content, input_service)
			end

			return true
		end

		local left_hold = safe_input_get(input_service, "left_hold")
		local confirm_pressed = safe_input_get(input_service, "confirm_pressed")

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

		if not dropdown_open and not dropdown_just_closed then
			handle_inputs(parent, widget, content, cursor_ui, left_hold, confirm_pressed)
			handle_text_inputs(parent, widget, content, input_service, dt, t)
		end

		local prev_left_hold = content._prev_left_hold
		content._prev_left_hold = left_hold

		if not dropdown_open and not dropdown_just_closed then
			for _, config in ipairs(slider_configs) do
				if content[config.name .. "_editing"] then
					local value_hotspot = content[config.name .. "_value_hotspot"]

					if left_hold and not prev_left_hold and not (value_hotspot and value_hotspot.is_hover) then
						local buffer = content[config.name .. "_edit_buffer"]
						confirm_value(content, config.name, buffer)
						stop_editing(content, config.name)
					end

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
		end

		local ok_cursor, cursor_result = pcall(parent.using_cursor_navigation, parent)
		local using_gamepad = ok_cursor and not cursor_result or false

		if using_gamepad and not dropdown_open and not dropdown_just_closed then
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
					tooltip.offset[2] = (pivot_pos and pivot_pos[2] or 0)
						+ (widget.offset and widget.offset[2] or 0)
						- height
						- 10
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

		-- Normalize each channel to 0-255 for the preview color swatch
		for _, config in ipairs(slider_configs) do
			local ch_val = content[sliders_cached[config.name].value]
			local lo = content[config.name .. "_min"] or 0
			local hi = content[config.name .. "_max"] or 255
			local range = hi - lo
			local normalized = range > 0 and (((ch_val - lo) / range) * 255) or 0

			if config.name == "a" then
				preview_color[1] = normalized
			elseif config.name == "r" then
				preview_color[2] = normalized
			elseif config.name == "g" then
				preview_color[3] = normalized
			elseif config.name == "b" then
				preview_color[4] = normalized
			end
		end

		if not has_alpha then
			preview_color[1] = 255
		end

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
