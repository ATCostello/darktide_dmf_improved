local mod = get_mod("Alfs_DMF_Extensions")

mod.default_tab = "Default"
mod.settings_widgets = {}

-- GENERAL SETTINGS
table.insert(mod.settings_widgets, {
	setting_id = "general_settings",
	type = "group",
	sub_widgets = {
		{
			setting_id = "mod_name_pizazz_toggle",
			type = "checkbox",
			default_value = true,
			tooltip = "mod_name_pizazz_tooltip",
		},
		{
			setting_id = "enable_scroll_position_saving",
			type = "checkbox",
			default_value = true,
			tooltip = "enable_scroll_position_saving_tooltip",
		},
		{
			setting_id = "enable_mod_tabs",
			type = "checkbox",
			default_value = true,
			tooltip = "enable_mod_tabs_tooltip",
		},
		{
			setting_id = "enable_generalised_mod_tabs",
			type = "checkbox",
			default_value = true,
			tooltip = "enable_generalised_mod_tabs_tooltip",
		},
		{
			setting_id = "enable_RGB_widget",
			type = "checkbox",
			default_value = true,
			tooltip = "enable_RGB_widget_tooltip",
		},
	},
})

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = mod.settings_widgets,
	},
}
