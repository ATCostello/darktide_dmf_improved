return {
    packages = {},
    run = function ()fassert(rawget(_G, "new_mod"), "`dmf_settings_improved` encountered an error loading the Darktide Mod Framework.")new_mod("dmf_settings_improved", {
        mod_data = "dmf_settings_improved/scripts/mods/dmf_settings_improved/dmf_settings_improved_data",
        mod_localization = "dmf_settings_improved/scripts/mods/dmf_settings_improved/dmf_settings_improved_localization",
        mod_script = "dmf_settings_improved/scripts/mods/dmf_settings_improved/dmf_settings_improved",
    })end,
}
