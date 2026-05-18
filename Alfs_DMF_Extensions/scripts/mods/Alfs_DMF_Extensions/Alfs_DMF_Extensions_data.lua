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
		{
			setting_id = "reload_mods_keybind",
			type = "keybind",
			default_value = { "f5" },
			keybind_trigger = "pressed",
			keybind_type = "function_call",
			function_name = "reload_all_mods",
			keybind_global = true,
		},
		{
			setting_id = "icon_dropdown_test",
			type = "dropdown",
			default_value = "opt_a",
			options = {
				{ text = "Option A (no icon)", value = "opt_a" },
				{
					text = "{#font(header_1)}Option with Aquila{#reset()}",
					value = "opt_b",
					icon = "content/ui/materials/icons/generic/aquila",
				},
				{
					text = "Option with Exclamation",
					value = "opt_c",
					icon = "content/ui/materials/icons/generic/exclamation_mark",
				},
				{
					text = "Red-tinted Aquila",
					value = "opt_d",
					icon = "content/ui/materials/icons/generic/aquila",
					icon_colour = { 255, 255, 0, 0 },
				},
			},
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
