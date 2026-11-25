local mod = get_mod("Alfs_DMF_Extensions")

local Definitions = mod._preset_panel_definitions
local Styles = mod._preset_panel_styles

local Dropdown = mod._preset_panel_dropdown or {}
mod._preset_panel_dropdown = Dropdown

local function scope_key(scope)
	if not scope or scope.kind == "global" or scope.mod_name == nil then
		return "global"
	end

	return "mod:" .. tostring(scope.mod_name)
end

local function build_options(source)
	local result = {}

	for _, entry in ipairs(source or {}) do
		result[#result + 1] = {
			display_name = entry.display_name,
			value = scope_key(entry.scope),
			scope = entry.scope,
			icon = entry.icon,
			icon_style = entry.icon_style,
		}
	end

	return result
end

local function find_index(content, value)
	for index, option in ipairs(content.options or {}) do
		if option.value == value then
			return index
		end
	end

	return 1
end

local function options_key(entries)
	local result = {}

	for index, entry in ipairs(entries) do
		result[index] = scope_key(entry.scope) .. "=" .. tostring(entry.display_name)
	end

	return table.concat(result, "|")
end

local function sync_options(parent)
	local widget = parent and parent._widgets_by_name and parent._widgets_by_name.scope_dropdown
	local content = widget and widget.content

	if not content then
		return nil
	end

	local source = mod._preset_panel_get_scope_options()
	local key = options_key(source)

	if content._options_key ~= key then
		local options = build_options(source)
		local options_by_value = {}

		for _, option in ipairs(options) do
			options_by_value[option.value] = option
		end

		content.options = options
		content.options_by_value = options_by_value
		content._options_key = key

		local visible = math.min(#options, Definitions.SCOPE_MAX_VISIBLE_OPTIONS)
		local row_height = Definitions.SCOPE_DROPDOWN_SIZE[2]

		content.num_visible_options = visible
		content.area_length = row_height * visible
		content.scroll_length = math.max(row_height * #options - content.area_length, 0)
		content.scroll_amount = content.scroll_length > 0 and row_height / content.scroll_length or 0
	end

	content.grow_downwards = true
	content.disabled = false

	local current_scope = mod._preset_panel_get_scope()
	local current_value = scope_key(current_scope)
	local current_option = content.options_by_value and content.options_by_value[current_value]

	content.internal_value = current_value
	content.value_text = current_option and current_option.display_name or mod._preset_panel_get_scope_name()
	content.value_icon = current_option and current_option.icon or nil

	if widget.style and widget.style.icon then
		widget.style.icon.visible = content.value_icon ~= nil
	end

	if content.exclusive_focus ~= true then
		content.selected_index = find_index(content, current_value)
	end

	return content
end

Dropdown.init = function(parent)
	local widget = parent and parent._widgets_by_name and parent._widgets_by_name.scope_dropdown
	local content = widget and widget.content

	if not content then
		return
	end

	content.hotspot = content.hotspot or {}
	content.hotspot.pressed_callback = callback(parent, "cb_on_scope_pressed")
	content.tooltip_text = mod:localize("preset_editor_scope_tooltip")
	content.exclusive_focus = false
	content.scroll_percentage = 0
	content.start_index = 1

	sync_options(parent)
end

Dropdown.sync = function(parent)
	return sync_options(parent)
end

Dropdown.is_open = function(parent)
	local widget = parent and parent._widgets_by_name and parent._widgets_by_name.scope_dropdown
	local content = widget and widget.content

	return content and content.exclusive_focus == true or false
end

Dropdown.open = function(parent)
	local content = sync_options(parent)

	if not content then
		return
	end

	content.exclusive_focus = true
	content.hotspot.is_selected = false
	content.hotspot.is_focused = false
	content.hotspot.on_pressed = false
	content.hotspot._input_pressed = false

	for index = 1, Definitions.SCOPE_MAX_VISIBLE_OPTIONS do
		local option_hotspot = content["option_hotspot_" .. index]

		if option_hotspot then
			option_hotspot.on_pressed = false
			option_hotspot._input_pressed = false
		end
	end

	if parent and type(parent.set_can_exit) == "function" then
		parent:set_can_exit(false)
	end
end

Dropdown.close = function(parent)
	local widget = parent and parent._widgets_by_name and parent._widgets_by_name.scope_dropdown
	local content = widget and widget.content

	if content then
		content.exclusive_focus = false
		content.hotspot.is_selected = false
		content.hotspot.is_focused = false
		content.hotspot.on_pressed = false
		content.hotspot._input_pressed = false
		content.selected_index = find_index(content, content.internal_value)
		content.scroll_percentage = 0
		content.start_index = 1
	end

	if parent and type(parent.set_can_exit) == "function" then
		parent:set_can_exit(true)
	end
end

Dropdown.toggle = function(parent)
	if Dropdown.is_open(parent) then
		Dropdown.close(parent)
	else
		Dropdown.open(parent)
	end
end

local function apply_option(parent, option)
	if not option or type(option.scope) ~= "table" then
		return
	end

	mod._preset_panel_set_scope(parent, option.scope)
end

local function get_input(input_service, action)
	if not input_service or type(input_service.get) ~= "function" then
		return false
	end

	if type(input_service.has) == "function" and not input_service:has(action) then
		return false
	end

	return input_service:get(action) == true
end

local function update_visible_options(parent, widget, input_service, focused)
	local content = widget.content
	local style = widget.style
	local options = content.options or {}
	local num_options = #options
	local num_visible_options = math.max(1, content.num_visible_options or 1)
	local row_height = Definitions.SCOPE_DROPDOWN_SIZE[2]
	local ui_manager = Managers and Managers.ui
	local using_gamepad = ui_manager and type(ui_manager.using_cursor_navigation) == "function"
		and not ui_manager:using_cursor_navigation() or false
	local selected_index = content.selected_index or 1
	local new_index = nil
	local new_value = nil

	if focused and selected_index then
		if get_input(input_service, "navigate_up_continuous") then
			new_index = math.max(selected_index - 1, 1)
		elseif get_input(input_service, "navigate_down_continuous") then
			new_index = math.min(selected_index + 1, num_options)
		end
	end

	if new_index then
		selected_index = new_index
		content.selected_index = selected_index

		if num_options > num_visible_options then
			content.scroll_percentage = (selected_index - 1) / math.max(num_options - num_visible_options + 1, 1)
			content.scroll_add = nil
		end
	end

	local start_index = 1

	if num_options > num_visible_options then
		local steps = num_options - num_visible_options + 1
		start_index = math.max(1, math.ceil((content.scroll_percentage or 0) * steps))
		start_index = math.min(start_index, steps)
	end

	content.start_index = start_index

	local end_index = math.min(start_index + num_visible_options - 1, num_options)
	local option_index = 1
	local option_hovered = false
	local row_width = Definitions.SCOPE_DROPDOWN_SIZE[1]
	local entry_width = num_options > num_visible_options and row_width - 30 or row_width

	for index = start_index, end_index do
		local actual_index = index
		local option = options[actual_index]
		local hotspot = option and content["option_hotspot_" .. option_index]
		local hotspot_style = style and style["option_hotspot_" .. option_index]
		local text_style = style and style["option_text_" .. option_index]
		local icon_style = style and style["option_icon_" .. option_index]
		local outline_style = style and style["outline_" .. option_index]
		local offset_y = row_height * option_index

		if hotspot then
			hotspot.is_selected = actual_index == selected_index
			hotspot.is_hover = hotspot.is_hover or false
			option_hovered = option_hovered or hotspot.is_hover

			if focused and hotspot.on_pressed then
				hotspot.on_pressed = false
				hotspot._input_pressed = false
				new_value = option.value
				content.selected_index = actual_index
			end
		end

		if content and option then
			content["option_text_" .. option_index] = option.display_name
			content["option_icon_" .. option_index] = option.icon or nil
		end

		if hotspot_style and hotspot_style.offset then
			hotspot_style.offset[2] = offset_y
		end

		if text_style and text_style.offset then
			text_style.offset[2] = offset_y
			text_style.size[1] = row_width
		end

		if icon_style and icon_style.offset then
			icon_style.offset[2] = offset_y
			icon_style.visible = option and option.icon ~= nil or false
		end

		if outline_style and outline_style.offset then
			outline_style.offset[2] = offset_y
			outline_style.size[1] = entry_width
		end

		option_index = option_index + 1
	end

	local scrollbar_hotspot = content.scrollbar_hotspot
	local scrollbar_hovered = scrollbar_hotspot and scrollbar_hotspot.is_hover or false
	local pass_input = using_gamepad or new_value ~= nil or not option_hovered and not scrollbar_hovered

	return pass_input, new_value
end

Dropdown.update = function(parent, dt, t, input_service)
	local widget = parent and parent._widgets_by_name and parent._widgets_by_name.scope_dropdown
	local content = widget and widget.content

	if not content then
		return true
	end

	local focused = content.exclusive_focus == true

	if focused and parent and type(parent.can_exit) == "function" and parent:can_exit() then
		if type(parent.set_can_exit) == "function" then
			parent:set_can_exit(false)
		end
	end

	if not focused then
		local ui_manager = Managers and Managers.ui
		local using_gamepad = ui_manager and type(ui_manager.using_cursor_navigation) == "function"
			and not ui_manager:using_cursor_navigation() or false
		local hotspot = content.hotspot or {}

		hotspot.is_selected = using_gamepad
		hotspot.on_pressed = false

		return true
	end

	local pass_input, new_value = update_visible_options(parent, widget, input_service, focused)
	local value = content.internal_value
	local changed = false

	if new_value and new_value ~= value then
		local option = content.options_by_value and content.options_by_value[new_value]

		if option then
			apply_option(parent, option)
			content.internal_value = new_value
			content.value_text = option.display_name
			content.value_icon = option.icon or nil

			if widget.style and widget.style.icon then
				widget.style.icon.visible = content.value_icon ~= nil
			end

			Dropdown.close(parent)
			changed = true
		end
	end

	if not changed then
		local back_input = get_input(input_service, "back")
		local confirm_input = get_input(input_service, "confirm_pressed")

		if back_input or confirm_input then
			Dropdown.close(parent)
		end
	end

	return pass_input
end

return Dropdown
