local mod = get_mod("Alfs_DMF_Extensions")

mod.default_tab = Localize("loc_settings_menu_group_other_settings") or mod:localize("default_tab") or "Other"

mod.settings_widgets = {}

local rgb_widget_styles = {
	{

		icon = "content/ui/materials/icons/circumstances/havoc/havoc_mutator_heinous_rituals",
		icon_style = { size = { 48, 48 }, color = { 255, 255, 0, 0 }, default_color = { 255, 255, 0, 0 }, hover_color = { 255, 255, 0, 0 }, },
		text = "rgb_replacement_argb_sliders",
		value = "argb_sliders",
	},
	{
		text = "rgb_replacement_color_widget",
		value = "color_widget",
	},
	{
		text = "rgb_replacement_disabled",
		value = "disabled",
	},
}

local _get_keybind_list = function()
	local list = {}
	for _, action in ipairs(mod._available_aliases) do
		list[#list + 1] = { text = action, value = action }
	end
	return list
end

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
		--{
		--	setting_id = "enable_scroll_position_saving",
		--	type = "checkbox",
		--	default_value = true,
		--	tooltip = "enable_scroll_position_saving_tooltip",
		--},
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
			type = "dropdown",
			default_value = "argb_sliders",
			tooltip = "enable_RGB_widget_tooltip",
			options = rgb_widget_styles,
		},
		--{
		--	setting_id = "reload_mods_keybind",
		--	type = "keybind",
		--	default_value = {
		--		"r",
		--		"left shift",
		--		"left ctrl",
		--	},
		--	keybind_trigger = "pressed",
		--	keybind_type = "function_call",
		--	function_name = "reload_all_mods",
		--	keybind_global = true,
		--},
		--{
		--	setting_id = "enable_dropdown_icons",
		--	type = "checkbox",
		--	default_value = true,
		--	tooltip = "enable_dropdown_icons_tooltip",
		--},
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
		{
			setting_id = "keybind_reset_tab",
			type = "dropdown",
			default_value = "hotkey_menu_special_1",
			options = _get_keybind_list(),
			tooltip = "keybind_reset_tab_tooltip",
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
