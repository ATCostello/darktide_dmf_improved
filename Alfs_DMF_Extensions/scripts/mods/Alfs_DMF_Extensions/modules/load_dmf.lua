local mod = get_mod("Alfs_DMF_Extensions")

local dmf = get_mod("DMF")
mod.dmf = dmf

-- ###########################################################################
-- initialize_mod_options hook
-- ###########################################################################

local original_initialize = dmf.initialize_mod_options

dmf.initialize_mod_options = function(passed_mod, options)
	local result = original_initialize(passed_mod, options)

	if not (options and options.widgets) then
		return result
	end

	local initialized_widgets = dmf.options_widgets_data[#dmf.options_widgets_data]

	if not initialized_widgets then
		return result
	end

	local raw_lookup = {}

	local function collect_widgets(widgets)
		for _, widget in ipairs(widgets) do
			if widget.setting_id then
				raw_lookup[widget.setting_id] = widget
			end

			if widget.sub_widgets then
				collect_widgets(widget.sub_widgets)
			end
		end
	end

	collect_widgets(options.widgets)

	for _, initialized in ipairs(initialized_widgets) do
		local raw = raw_lookup[initialized.setting_id]

		if raw then
			initialized.tab = raw.tab
		end
	end

	return result
end

-- ###########################################################################
-- create_mod_options_settings hook
-- ###########################################################################

local original_create = dmf.create_mod_options_settings

dmf.create_mod_options_settings = function(self, options_templates)
	local result = original_create(self, options_templates)

	local settings = result.settings

	if not settings then
		return result
	end

	local tab_lookup = {}
	local setting_id_lookup = {}

	for _, mod_widgets in ipairs(dmf.options_widgets_data) do
		for _, widget in ipairs(mod_widgets) do
			if widget.tab then
				if widget.setting_id then
					tab_lookup[widget.setting_id] = widget.tab
				end

				if widget.title then
					tab_lookup[widget.title] = widget.tab
				end
			end

			if widget.setting_id then
				setting_id_lookup[widget.setting_id] = widget.setting_id
			end

			if widget.title then
				setting_id_lookup[widget.title] = widget.setting_id
			end
		end
	end

	for _, template in ipairs(settings) do
		local tab = tab_lookup[template.setting_id] or tab_lookup[template.display_name]

		if tab then
			template.tab = tab
		end

		local setting_id = setting_id_lookup[template.setting_id] or setting_id_lookup[template.display_name]

		if setting_id then
			template.setting_id = setting_id
		end
	end

	return result
end

-- ###########################################################################
-- all mods loaded
-- ###########################################################################

mod.on_all_mods_loaded = function()
	mod.dmf = get_mod("DMF")
end
