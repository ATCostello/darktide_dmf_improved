local mod = get_mod("Alfs_DMF_Extensions")

local function copy_color(color)
	if not color then
		return nil
	end
	return { color[1], color[2], color[3], color[4] }
end

local function apply_preview_icon_color(icon_style, text_style, icon_colour)
	if icon_style then
		if icon_colour then
			icon_style.color = copy_color(icon_colour)
		elseif text_style and text_style.text_color then
			icon_style.color = copy_color(text_style.text_color)
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
	if not category then return end

	local widgets = self._settings_category_widgets and self._settings_category_widgets[category]
	if not widgets then return end

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

				if preview_option and preview_option.icon then
					content.value_icon = preview_option.icon
					apply_preview_icon_color(widget.style.icon, widget.style.list_header, preview_option.icon_colour)
					if widget.style.icon then
						widget.style.icon.visible = true
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
