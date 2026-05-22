local mod = get_mod("Alfs_DMF_Extensions")

mod.default_tab = Localize("loc_settings_menu_group_other_settings") or mod:localize("default_tab") or "Other"

mod.settings_widgets = {}

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
		{
			setting_id = "reload_mods_keybind",
			type = "keybind",
			default_value = {
				"r",
				"left shift",
				"left ctrl",
			},
			keybind_trigger = "pressed",
			keybind_type = "function_call",
			function_name = "reload_all_mods",
			keybind_global = true,
		},
		{
			setting_id = "enable_dropdown_icons",
			type = "checkbox",
			default_value = true,
			tooltip = "enable_dropdown_icons_tooltip",
		},
		{
			setting_id = "enable_font_support",
			type = "checkbox",
			default_value = true,
			tooltip = "enable_font_support_tooltip",
		},
		{
			setting_id = "enable_scrollable_dropdown",
			type = "checkbox",
			default_value = true,
			tooltip = "enable_scrollable_dropdown_tooltip",
		},
		{
			setting_id = "enable_tab_reset",
			type = "checkbox",
			default_value = true,
			tooltip = "enable_tab_reset_tooltip",
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
