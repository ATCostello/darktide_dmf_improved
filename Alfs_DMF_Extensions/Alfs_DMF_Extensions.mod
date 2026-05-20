return {
    packages = {},
    run = function ()fassert(rawget(_G, "new_mod"), "`Alfs_DMF_Extensions` encountered an error loading the Darktide Mod Framework.")new_mod("Alfs_DMF_Extensions", {
        mod_data = "Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/Alfs_DMF_Extensions_data",
        mod_localization = "Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/Alfs_DMF_Extensions_localization",
        mod_script = "Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/Alfs_DMF_Extensions",
    })end,
	
	 load_after = {
		"dmf",
	},
  
}
