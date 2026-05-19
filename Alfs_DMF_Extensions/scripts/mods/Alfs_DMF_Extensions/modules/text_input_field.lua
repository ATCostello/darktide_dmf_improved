local ENTER_INDEX = Keyboard.button_index("enter")
local ESCAPE_INDEX = Keyboard.button_index("escape")

local _editing_context = nil

local text_input_field = {}

function text_input_field.start_editing(content, value_key, get_current_value_fn)
	if _editing_context and _editing_context.content ~= content then
		local prev = _editing_context
		local prev_key = prev.value_key or value_key
		prev.content[prev_key .. "_editing"] = false
		if type(prev.get_current_value) == "function" then
			prev.content[prev_key .. "_value_text"] = tostring(prev.get_current_value())
		end
	end

	local current = get_current_value_fn and tostring(get_current_value_fn()) or "0"
	content[value_key .. "_editing"] = true
	content[value_key .. "_edit_buffer"] = ""
	content[value_key .. "_value_text"] = ""
	content[value_key .. "_prev_value_text"] = current

	_editing_context = { content = content, value_key = value_key, get_current_value = get_current_value_fn }
end

function text_input_field.stop_editing(content, value_key)
	if _editing_context and (_editing_context.content ~= content or _editing_context.value_key ~= value_key) then
		return
	end

	content[value_key .. "_editing"] = false
	local prev = content[value_key .. "_prev_value_text"]
	if prev then
		content[value_key .. "_value_text"] = prev
	end
	content._last_input_time = nil
	_editing_context = nil
end

function text_input_field.confirm_value(content, value_key, buffer, set_value_fn, min, max)
	local value = tonumber(buffer)
	if value then
		value = math.clamp(value, min or 0, max or 255)
		set_value_fn(value)
	end
	content._last_input_time = nil
end

function text_input_field.process_keystrokes(content, value_key, keystrokes, t)
	if not content[value_key .. "_editing"] then
		return
	end

	local buffer = content[value_key .. "_edit_buffer"] or ""
	local changed = false

	local max_length = content[value_key .. "_max_length"] or 6
	local allow_decimal = content[value_key .. "_allow_decimal"]
	local allow_minus = content[value_key .. "_allow_minus"]

	if keystrokes then
		for i = 1, #keystrokes do
			local ks = keystrokes[i]
			local accept = false

			if #buffer < max_length and type(ks) == "string" and ks:match("^[%d%.%-]$") then
				if ks == "." then
					accept = allow_decimal and not buffer:find("%.")
				elseif ks == "-" then
					accept = allow_minus and #buffer == 0
				else
					accept = true
				end
			end

			if accept then
				buffer = buffer .. ks
				changed = true
			elseif ks == Keyboard.BACKSPACE then
				buffer = buffer:sub(1, #buffer - 1)
				changed = true
			end
		end
	end

	if changed then
		content[value_key .. "_edit_buffer"] = buffer
		content[value_key .. "_value_text"] = buffer
		if t then
			content._last_input_time = t
		end
	end
end

function text_input_field.handle_edit_commands(content, value_key, set_value_fn, min, max)
	if not content[value_key .. "_editing"] then
		return false
	end

	if Keyboard.pressed(ENTER_INDEX) then
		text_input_field.confirm_value(content, value_key, content[value_key .. "_edit_buffer"] or "", set_value_fn, min, max)
		text_input_field.stop_editing(content, value_key)
		return true
	end

	if Keyboard.pressed(ESCAPE_INDEX) then
		text_input_field.stop_editing(content, value_key)
		return true
	end

	return false
end

function text_input_field.update_caret_position(style, value_key, content, base_x, base_y)
	local buf = content[value_key .. "_edit_buffer"] or ""
	local max_length = content[value_key .. "_max_length"] or 6
	local pos = math.min(#buf + 1, max_length + 1)
	local caret_style = style[value_key .. "_caret"]
	if caret_style then
		caret_style.offset[1] = base_x + (pos - 1) * 16
		caret_style.offset[2] = base_y
	end
end

function text_input_field.timeout_inactive(content, t, timeout)
	if not content._last_input_time then
		return false
	end

	if t and timeout and t - content._last_input_time > timeout then
		return true
	end

	return false
end

function text_input_field.is_editing()
	return _editing_context ~= nil
end

function text_input_field.is_field_editing(content, value_key)
	if not _editing_context then
		return false
	end
	return _editing_context.content == content and _editing_context.value_key == value_key
end

return text_input_field
