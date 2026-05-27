local mod = get_mod("Alfs_DMF_Extensions")

mod._release_dropdown_materials = function()
end

local SETTINGS_VALUE_WIDTH = 500
local ICON_CONSTANT_OFFSET = 28

local function copy_color(color)
	if not color then
		return nil
	end
	return { color[1], color[2], color[3], color[4] }
end

local function get_widget_icon_x(widget)
	local widget_size = widget.content and widget.content.size
	local widget_width = widget_size and widget_size[1]
	if widget_width then
		return widget_width - SETTINGS_VALUE_WIDTH + ICON_CONSTANT_OFFSET
	end
	return nil
end

local function apply_preview_icon_color(icon_style, text_style, icon_colour)
	if icon_style then
		if icon_colour then
			icon_style.color = copy_color(icon_colour)
			icon_style.default_color = copy_color(icon_colour)
			icon_style.selected_color = copy_color(icon_colour)
		elseif text_style and text_style.text_color then
			icon_style.color = copy_color(text_style.text_color)
			icon_style.default_color = copy_color(text_style.text_color)
			icon_style.selected_color = copy_color(text_style.text_color)
		end
	end
end

local function apply_option_icon_color(icon_style, text_style, icon_colour)
	if icon_style then
		if icon_colour then
			icon_style.default_color = copy_color(icon_colour)
			icon_style.hover_color = copy_color(icon_colour)
		elseif text_style and text_style.text_color then
			icon_style.default_color = copy_color(text_style.text_color)
			if text_style.hover_color then
				icon_style.hover_color = copy_color(text_style.hover_color)
			else
				icon_style.hover_color = copy_color(text_style.text_color)
			end
		end
	end
end

mod._addDropdownIcons = function(self, dt, t, input_service)
	local category = mod.current_category
	if not category then
		return
	end

	local widgets = self._settings_category_widgets and self._settings_category_widgets[category]
	if not widgets then
		return
	end

	for i = 1, #widgets do
		local row = widgets[i]
		local widget = row.widget

		if widget and widget.type == "dropdown" then
			local content = widget.content
			local entry = content.entry
			local options = content.options

			if entry and options then
				local value = entry.get_function and entry:get_function() or content.internal_value
				local preview_option = content.options_by_value and content.options_by_value[value]
				local icon_x = get_widget_icon_x(widget)

				if preview_option and preview_option.icon then
					content.value_icon = preview_option.icon
					apply_preview_icon_color(widget.style.icon, widget.style.list_header, preview_option.icon_colour)
					if widget.style.icon then
						widget.style.icon.visible = true
						if icon_x then
							widget.style.icon.offset[1] = icon_x
						end
					end
					if widget.style.text and widget.style.text.icon_offset then
						widget.style.text.offset[1] = widget.style.text.icon_offset[1]
					end
				else
					content.value_icon = nil
					if widget.style.icon then
						widget.style.icon.visible = false
					end
					if widget.style.text and widget.style.text.default_offset then
						widget.style.text.offset[1] = widget.style.text.default_offset[1]
					end
				end

				local num_visible = content.num_visible_options or 1
				local start_index = content.start_index or 1
				local end_index = math.min(start_index + num_visible - 1, #options)
				local grow_down = content.grow_downwards
				local option_index = 1

				for j = start_index, end_index do
					local actual_i = j
					if not grow_down then
						actual_i = end_index - j + start_index
					end

					local option = options[actual_i]
					local icon_id = "option_icon_" .. option_index
					local text_id = "option_text_" .. option_index
					local icon_style = widget.style[icon_id]
					local text_style = widget.style[text_id]

					if option and option.icon then
						content[icon_id] = option.icon
						apply_option_icon_color(icon_style, text_style, option.icon_colour)
						if icon_style then
							icon_style.visible = true
							icon_style.offset[2] = text_style.offset[2]
							if icon_x then
								icon_style.offset[1] = icon_x
							end
						end
						if text_style and text_style.icon_offset then
							text_style.offset[1] = text_style.icon_offset[1]
						end
					else
						content[icon_id] = nil
						if icon_style then
							icon_style.visible = false
						end
						if text_style and text_style.default_offset then
							text_style.offset[1] = text_style.default_offset[1]
						end
					end

					option_index = option_index + 1
				end
			end
		end
	end
end
