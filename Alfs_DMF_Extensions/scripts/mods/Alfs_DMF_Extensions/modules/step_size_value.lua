local mod = get_mod("Alfs_DMF_Extensions")
local dmf = get_mod("DMF")

local custom_step_sizes = {}

local orig_initialize = dmf.initialize_mod_options
dmf.initialize_mod_options = function(passed_mod, options)
	local result = orig_initialize(passed_mod, options)

	if options and options.widgets then
		local function collect(widgets)
			for _, widget in ipairs(widgets) do
				if widget.setting_id and widget.step_size_value ~= nil then
					custom_step_sizes[widget.setting_id] = widget.step_size_value
				end
				if widget.sub_widgets then
					collect(widget.sub_widgets)
				end
			end
		end
		collect(options.widgets)
	end

	return result
end

local orig_create = dmf.create_mod_options_settings
dmf.create_mod_options_settings = function(self, options_templates)
	local result = orig_create(self, options_templates)

	local settings = result and result.settings
	if settings then
		for _, template in ipairs(settings) do
			local step = template.setting_id and custom_step_sizes[template.setting_id]
			if step ~= nil and template.max_value and template.min_value then
				local value_range = template.max_value - template.min_value
				template.step_size = step
				template.normalized_step_size = step / value_range
				template.explode_function = function(normalized_value)
					local exploded_value = template.min_value + normalized_value * value_range
					exploded_value = math.round(exploded_value / step) * step
					return exploded_value
				end
			end
		end
	end

	return result
end
