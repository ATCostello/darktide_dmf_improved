local mod = get_mod("Alfs_DMF_Extensions")
local dmf = get_mod("DMF")

mod.custom_step_sizes = {}
mod.custom_tab_data = {}

local function collect_from_widgets(calling_mod, widgets, parent_tab, localize, category_name)
	category_name = category_name or "unknown"
	for _, widget in ipairs(widgets or {}) do
		local widget_tab = widget.tab or parent_tab
		if widget.setting_id then
			local compound = mod.compound_key(category_name, widget.setting_id)
			if widget.step_size_value ~= nil then
				mod.custom_step_sizes[compound] = widget.step_size_value
			end
			if widget_tab then
				mod.custom_tab_data[compound] = widget_tab
				if localize and not widget.title then
					local title = calling_mod:localize(widget.setting_id)
					mod.custom_tab_data[mod.compound_key(category_name, title)] = widget_tab
				end
			end
		end
		if widget.title and widget_tab then
			mod.custom_tab_data[mod.compound_key(category_name, widget.title)] = widget_tab
		end
		if widget.sub_widgets then
			collect_from_widgets(calling_mod, widget.sub_widgets, widget_tab, localize, category_name)
		end
	end
end

local orig_initialize_mod_options = dmf.initialize_mod_options
dmf.initialize_mod_options = function(calling_mod, options)
	local result = orig_initialize_mod_options(calling_mod, options)
	-- Inject tab field back into DMF's processed widget data so
	-- existing tab resolution functions can find it by w.tab
	local mod_data = dmf.options_widgets_data[#dmf.options_widgets_data]
	if mod_data then
		local header = mod_data[1]
		local cat_name = (header and (header.readable_mod_name or header.mod_name)) or "unknown"

		if options and options.widgets then
			collect_from_widgets(calling_mod, options.widgets, nil, options.localize ~= false, cat_name)
		end

		for _, w in ipairs(mod_data) do
			local compound = mod.compound_key(cat_name, w.setting_id)
			if w.setting_id and mod.custom_tab_data[compound] then
				w.tab = mod.custom_tab_data[compound]
			end
		end
	end
	return result
end

local orig_create_settings = dmf.create_mod_options_settings
dmf.create_mod_options_settings = function(self, options_templates)
	local result = orig_create_settings(self, options_templates)

	local settings = result and result.settings
	if settings then
		for _, template in ipairs(settings) do
			local cat = template.category or "unknown"
			local step_key = template.setting_id and mod.compound_key(cat, template.setting_id)
			local step = step_key and mod.custom_step_sizes[step_key]
			if step ~= nil and template.max_value and template.min_value then
				local value_range = template.max_value - template.min_value
				template.step_size = step
				template.normalized_step_size = value_range > 0 and step / value_range or 0
				template.explode_function = function(normalized_value)
					local exploded_value = template.min_value + normalized_value * value_range
					exploded_value = math.round(exploded_value / step) * step
					return exploded_value
				end
			end

			if template.widget_type == "group_header" and not template.tab then
				local compound = template.setting_id and mod.compound_key(cat, template.setting_id)
				local tab = compound and mod.custom_tab_data[compound]
				if not tab and template.display_name then
					local dn_key = mod.compound_key(cat, template.display_name)
					tab = mod.custom_tab_data[dn_key]
					if not tab then
						for _, mod_widgets in ipairs(dmf.options_widgets_data or {}) do
							local header = mod_widgets[1]
							local cat_name = header and (header.readable_mod_name or header.mod_name) or ""
							if cat_name == cat then
								for _, w in ipairs(mod_widgets) do
									if w.title == template.display_name and w.setting_id then
										tab = mod.custom_tab_data[mod.compound_key(cat_name, w.setting_id)]
										break
									end
								end
								break
							end
						end
					end
				end
				if tab then
					template.tab = tab
				end
			end
		end
	end

	return result
end
