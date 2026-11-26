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
	if not input_service or type(input_service.get) ~= "function" then
		return default
	end

	if type(input_service.has) == "function" and not input_service:has(action_name) then
		return default
	end

	local result = input_service:get(action_name)

	if result == nil then
		return default
	end

	return result
end

local format_string_cache = {}

local function format_value(value, decimals)
	if decimals and decimals > 0 then
		local fmt = format_string_cache[decimals]

		if not fmt then
			fmt = "%." .. tostring(decimals) .. "f"
			format_string_cache[decimals] = fmt
		end

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

local function snap_to_step(raw_val, entry, decimals)
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

for name, slider in pairs(sliders_cached) do
	slider.min = name .. "_min"
	slider.max = name .. "_max"
	slider.decimals = name .. "_decimals"
	slider.editing = name .. "_editing"
	slider.buffer = name .. "_edit_buffer"
	slider.prev_value_text = name .. "_prev_value_text"
	slider.entry = name .. "_entry"
	slider.value_hotspot = name .. "_value_hotspot"
	slider.label_hotspot = name .. "_label_hotspot"
	slider.bar_hotspot = name .. "_bar_hotspot"
	slider.bg = name .. "_bg"
	slider.fill = name .. "_fill"
	slider.fill_widget = "_" .. name .. "_fill"
end

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
	local lo = content[slider.min] or 0
	local hi = content[slider.max] or 255
	local range = hi - lo
	local decimals = content[slider.decimals] or 0

	if content[slider.value] ~= value then
		content[slider.value] = value

		if not content[slider.editing] then
			content[slider.value_text] = format_value(value, decimals)
		end
	end

	local fraction = range > 0 and ((value - lo) / range) or 0
	widget[slider.fill_widget].size[1] = math_clamp(fraction, 0, 1) * bar_width
end

local cursor_scratch = { 0, 0 }

local function cursor_to_ui_space(input_service, parent, t)
	if not input_service or type(input_service.get) ~= "function" then
		return nil
	end

	if t and parent and parent._alfs_cursor_frame == t then
		return parent._alfs_cursor_valid and cursor_scratch or nil
	end

	local cursor = input_service:get("cursor")

	if parent then
		parent._alfs_cursor_frame = t
		parent._alfs_cursor_valid = cursor ~= nil
	end

	if not cursor then
		return nil
	end

	if IS_XBS or IS_PLAYSTATION then
		cursor_scratch[1] = cursor[1]
		cursor_scratch[2] = cursor[2]
	else
		local render_scale = parent and parent._render_scale or 1
		cursor_scratch[1] = cursor[1] / render_scale
		cursor_scratch[2] = cursor[2] / render_scale
	end

	return cursor_scratch
end

local function get_bar_ui_x(parent, widget, slider)
	local pivot_pos = parent and parent:_scenegraph_world_position("settings_grid_content_pivot")

	if not pivot_pos then
		return nil
	end

	local bg_style = widget.style[slider.bg]

	if not bg_style then
		return nil
	end

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

	if content[slider.editing] then
		return
	end

	local hotspot = content[slider.hotspot]
	local value_hotspot = content[slider.value_hotspot]
	local label_hotspot = content[slider.label_hotspot]
	local bar_hotspot = content[slider.bar_hotspot]

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
	local lo = content[slider.min] or 0
	local hi = content[slider.max] or 255
	local range = hi - lo
	local decimals = content[slider.decimals] or 0

	if inside and not dragging then
		local fresh_press = not content._prev_left_hold and left_hold

		if fresh_press or confirm_pressed then
			content[slider.dragging] = true
			dragging = true

			local bar_ui_x = get_bar_ui_x(parent, widget, slider)

			content[slider.start_x] = cursor_ui[1]
			content[slider.start_value] = get_value(entry)

			if bar_ui_x then
				local bar_cursor_x = cursor_ui[1] - bar_ui_x
				local raw = lo + (bar_cursor_x / bar_width) * range
				local click_value = math_clamp(snap_to_step(raw, entry, decimals), lo, hi)

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
		local value = math_clamp(snap_to_step(raw, entry, decimals), lo, hi)

		if content[slider.value] ~= value then
			content[slider.value] = value
			set_value(entry, value)

			if not content[slider.editing] then
				content[slider.value_text] = format_value(value, decimals)
			end
		end

		local fraction = range > 0 and ((value - lo) / range) or 0
		widget[slider.fill_widget].size[1] = math_clamp(fraction, 0, 1) * bar_width
	end
end

local ENTER_INDEX = Keyboard.button_index("enter")
local ESCAPE_INDEX = Keyboard.button_index("escape")

local _editing_context = nil

local function stop_editing(content, slider_name)
	if _editing_context and (_editing_context.content ~= content or _editing_context.slider_name ~= slider_name) then
		return
	end

	local slider = sliders_cached[slider_name]
	local entry = content[slider.entry]
	local decimals = content[slider.decimals] or 0

	content[slider.editing] = false

	local new_value = entry and format_value(get_value(entry), decimals)
	if not new_value or new_value == "" then
		new_value = content[slider.prev_value_text]
	end

	content[slider.value_text] = new_value
	content._last_input_time = nil
	_editing_context = nil
end

local function start_editing(content, slider_name)
	if _editing_context and _editing_context.content ~= content then
		local prev = _editing_context
		local prev_slider = sliders_cached[prev.slider_name]

		prev.content[prev_slider.editing] = false
		prev.content[prev_slider.value_text] = ""
	end

	local slider = sliders_cached[slider_name]

	content[slider.editing] = true

	local entry = content[slider.entry]
	local current = ""

	content[slider.buffer] = current
	content[slider.value_text] = current
	local decimals = content[slider.decimals] or 0
	content[slider.prev_value_text] = entry and format_value(get_value(entry), decimals) or "0"

	_editing_context = { content = content, slider_name = slider_name }
end

local function confirm_value(content, slider_name, buffer)
	local slider = sliders_cached[slider_name]
	local entry = content[slider.entry]
	local value = tonumber(buffer)

	if value then
		local lo = content[slider.min] or 0
		local hi = content[slider.max] or 255
		local decimals = content[slider.decimals] or 0
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
	local slider = sliders_cached[slider_name]
	local editing_key = slider.editing
	local buffer_key = slider.buffer
	local text_key = slider.value_text
	local hotspot = content[slider.value_hotspot]

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

	local abs_max = math.max(math.abs(content[slider.min] or 0), math.abs(content[slider.max] or 255))
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
	local slider = sliders_cached[slider_name]

	if content[slider.editing] then
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
	local lo = content[slider.min] or 0
	local hi = content[slider.max] or 255
	local range = hi - lo

	local decimals = content[slider.decimals] or 0

	if left then
		local new_value = math_clamp(current - 1, lo, hi)

		if new_value ~= current then
			set_value(entry, new_value)
			content[slider.value] = new_value
			content[slider.value_text] = format_value(new_value, decimals)
			local fraction = range > 0 and ((new_value - lo) / range) or 0
			widget[slider.fill_widget].size[1] = math_clamp(fraction, 0, 1) * bar_width
		end
	elseif right then
		local new_value = math_clamp(current + 1, lo, hi)

		if new_value ~= current then
			set_value(entry, new_value)
			content[slider.value] = new_value
			content[slider.value_text] = format_value(new_value, decimals)
			local fraction = range > 0 and ((new_value - lo) / range) or 0
			widget[slider.fill_widget].size[1] = math_clamp(fraction, 0, 1) * bar_width
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

	local num_slider_configs = #slider_configs
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
		for config_index = 1, num_slider_configs do
			local config = slider_configs[config_index]
			local slider = sliders_cached[config.name]
			local fill_style = style[slider.fill]

			if fill_style then
				local own_fill = table.clone(fill_style)
				own_fill.size = table.clone(fill_style.size)
				style[slider.fill] = own_fill
				widget[slider.fill_widget] = own_fill
			end
		end

		local preview_style = style.preview_style

		if preview_style then
			local own_preview = table.clone(preview_style)
			own_preview.color = table.clone(preview_style.color)
			style.preview_style = own_preview
			widget._preview_color = own_preview.color
		end
	end

	local function handle_inputs(parent, widget, content, cursor_ui, left_hold, confirm_pressed)
		for config_index = 1, num_slider_configs do
			local config = slider_configs[config_index]
			slider_input(
				parent,
				widget,
				content,
				cursor_ui,
				left_hold,
				confirm_pressed,
				config.name,
				content[sliders_cached[config.name].entry],
				bar_width
			)
		end
	end

	local function handle_text_inputs(parent, widget, content, input_service, dt, t)
		for config_index = 1, num_slider_configs do
			local config = slider_configs[config_index]
			value_text_input(
				parent,
				widget,
				content,
				input_service,
				config.name,
				content[sliders_cached[config.name].entry],
				bar_width,
				nil,
				t
			)
		end

		local any_editing = false

		for config_index = 1, num_slider_configs do
			local config = slider_configs[config_index]
			if content[sliders_cached[config.name].editing] then
				any_editing = true
				break
			end
		end

		if any_editing then
			local keystrokes = Keyboard.keystrokes()

			for config_index = 1, num_slider_configs do
			local config = slider_configs[config_index]
				if content[sliders_cached[config.name].editing] then
					value_text_input(
						parent,
						widget,
						content,
						input_service,
						config.name,
						content[sliders_cached[config.name].entry],
						bar_width,
						keystrokes,
						t
					)
				end
			end
		end
	end

	local function handle_gamepad_inputs(parent, widget, content, input_service)
		local num_sliders = num_slider_configs

		for i, config in ipairs(slider_configs) do
			slider_gamepad_input(
				parent,
				widget,
				content,
				input_service,
				config.name,
				content[sliders_cached[config.name].entry],
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

		for config_index = 1, num_slider_configs do
			local config = slider_configs[config_index]
			local ch_entry = content[sliders_cached[config.name].entry]
			content[sliders_cached[config.name].min] = entry_min(ch_entry)
			content[sliders_cached[config.name].max] = entry_max(ch_entry)
			local entry_decimals = ch_entry and ch_entry.num_decimals
			if entry_decimals ~= nil and entry_decimals > 0 then
				content[sliders_cached[config.name].decimals] = entry_decimals
			elseif ch_entry and ch_entry.step_size and ch_entry.step_size < 1 then
				content[sliders_cached[config.name].decimals] = 2
			elseif
				ch_entry
				and (
					ch_entry.min_value ~= math.floor(ch_entry.min_value)
					or ch_entry.max_value ~= math.floor(ch_entry.max_value)
				)
			then
				content[sliders_cached[config.name].decimals] = 2
			else
				content[sliders_cached[config.name].decimals] = 0
			end
		end

		local preview_color = widget._preview_color

		for config_index = 1, num_slider_configs do
			local config = slider_configs[config_index]
			local ch_entry = content[sliders_cached[config.name].entry]
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

	local function is_dropdown_open(parent, t)
		if not parent then
			return false
		end

		if t ~= nil and parent._alfs_dropdown_open_t == t then
			return parent._alfs_dropdown_open or false
		end

		local open = false
		local widgets = parent._settings_content_widgets

		if widgets then
			for i = 1, #widgets do
				local w = widgets[i]

				if w and w.type == "dropdown" and w.content then
					if w.content.exclusive_focus and w.content.selected_index then
						open = true
						break
					end
				end
			end
		end

		if t ~= nil then
			parent._alfs_dropdown_open_t = t
			parent._alfs_dropdown_open = open
		end

		return open
	end

	local update_fn = function(parent, widget, input_service, dt, t)
		local content = widget.content

		local using_gamepad = false

		if parent and type(parent.using_cursor_navigation) == "function" then
			using_gamepad = not parent:using_cursor_navigation()
		end

		local cursor_ui = cursor_to_ui_space(input_service, parent, t)
		local dropdown_open = is_dropdown_open(parent, t)

		local dropdown_just_closed = content._prev_dropdown_open and not dropdown_open
		content._prev_dropdown_open = dropdown_open

		if not cursor_ui then
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
			for config_index = 1, num_slider_configs do
				local config = slider_configs[config_index]

				if content[sliders_cached[config.name].editing] then
					local value_hotspot = content[sliders_cached[config.name].value_hotspot]

					if left_hold and not prev_left_hold and not (value_hotspot and value_hotspot.is_hover) then
						local buffer = content[sliders_cached[config.name].buffer]
						confirm_value(content, config.name, buffer)
						stop_editing(content, config.name)
					end

					if not content._last_input_time then
						content._last_input_time = t
					end

					if t - content._last_input_time > 5 then
						local buffer = content[sliders_cached[config.name].buffer]
						confirm_value(content, config.name, buffer)
						stop_editing(content, config.name)
					end
				end
			end
		end

		if using_gamepad and not dropdown_open and not dropdown_just_closed then
			handle_gamepad_inputs(parent, widget, content, input_service)
		end

		local hovered_slider = nil
		local any_hover = false

		for config_index = 1, num_slider_configs do
			local config = slider_configs[config_index]
			local label_hotspot = content[sliders_cached[config.name].label_hotspot]

			if label_hotspot and label_hotspot.is_hover then
				hovered_slider = config.name
				any_hover = true
				break
			end
		end

		content.hotspot.is_hover = any_hover

		if any_hover and hovered_slider then
			local hovered_cached = sliders_cached[hovered_slider]
			local entry = hovered_cached and content[hovered_cached.entry]

			if entry and (entry.tooltip_text or entry.disabled_by) then
				local tooltip = parent._widgets_by_name and parent._widgets_by_name.tooltip

				if tooltip then
					tooltip.content.visible = true
					tooltip.content.text = entry.tooltip_text or ""

					local text_style = tooltip.style.text
					local pivot_pos = parent:_scenegraph_world_position("settings_grid_content_pivot")
					local tooltip_width = (widget.content.size and widget.content.size[1] or settings_grid_width) * 0.5
					local text_size_scratch = widget._alfs_rgb_text_size or { 0, 0 }
					local tooltip_size = widget._alfs_rgb_tooltip_size or { 0, 0 }

					widget._alfs_rgb_text_size = text_size_scratch
					widget._alfs_rgb_tooltip_size = tooltip_size

					text_size_scratch[1] = tooltip_width
					text_size_scratch[2] = 0

					local _, text_height = parent:_text_size(entry.tooltip_text or "", text_style, text_size_scratch)
					local height = text_height

					tooltip_size[1] = tooltip_width
					tooltip_size[2] = height
					tooltip.content.size = tooltip_size

					local left_edge_x = pivot_pos and pivot_pos[1] + (widget.offset and widget.offset[1] or 0) or 0
					tooltip.offset[1] = left_edge_x - tooltip_width - 10
					tooltip.offset[2] = (pivot_pos and pivot_pos[2] or 0)
						+ (widget.offset and widget.offset[2] or 0)
						- height
						- 10
				end

				local tooltip_data = widget._alfs_rgb_tooltip_data or { widget = nil, text = nil }

				widget._alfs_rgb_tooltip_data = tooltip_data
				tooltip_data.widget = widget
				tooltip_data.text = entry.tooltip_text or ""
				parent._tooltip_data = tooltip_data
			end
		elseif parent._tooltip_data and parent._tooltip_data.widget == widget then
			local tooltip_data = widget._alfs_rgb_tooltip_data or { widget = nil, text = nil }

			widget._alfs_rgb_tooltip_data = tooltip_data
			tooltip_data.widget = nil
			tooltip_data.text = nil
			parent._tooltip_data = tooltip_data

			local tooltip = parent._widgets_by_name and parent._widgets_by_name.tooltip

			if tooltip then
				tooltip.content.visible = false
			end
		end

		local preview_color = widget._preview_color

		for config_index = 1, num_slider_configs do
			local config = slider_configs[config_index]
			local cached_slider = sliders_cached[config.name]
			local value

			if content[cached_slider.dragging] then
				value = content[cached_slider.value]
			else
				value = get_value(content[cached_slider.entry])
			end

			update_slider_visuals(widget, config.name, value, bar_width)

			local lo = content[cached_slider.min] or 0
			local hi = content[cached_slider.max] or 255
			local range = hi - lo
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
