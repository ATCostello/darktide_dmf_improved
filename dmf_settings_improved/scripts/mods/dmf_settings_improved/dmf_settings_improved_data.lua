local mod = get_mod("dmf_settings_improved")

mod.default_tab = "Default"
mod.settings_widgets = {}

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = mod.settings_widgets,
	},
}
