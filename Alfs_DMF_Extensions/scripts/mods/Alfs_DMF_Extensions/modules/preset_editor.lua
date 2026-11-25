local mod = get_mod("Alfs_DMF_Extensions")

mod._preset_panel_registered = false
mod._preset_popup_state_hook_target = nil
mod._preset_panel_stale_view_hook_installed = false
mod._preset_cog_hooks_installed = false
mod._character_hook_target = nil
mod._profile_cache_hook_target = nil

mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/utils/preset_utils")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/constants")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/core")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/popups")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/characters")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/panel/styles")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/panel/portraits")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/panel/blueprints")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/panel/definitions")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/panel/dropdown")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/panel/view")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/view")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/cogs")
