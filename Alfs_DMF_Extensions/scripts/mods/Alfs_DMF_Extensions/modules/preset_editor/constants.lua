local mod = get_mod("Alfs_DMF_Extensions")

local Constants = mod._preset_constants or {}
mod._preset_constants = Constants

Constants.PRESET_SETTING = "preset_editor_presets"
Constants.PRESETS_SETTING = "enable_presets"
Constants.PRESET_FORMAT = "alfs_dmf_extensions_preset_v1"
Constants.GLOBAL_PRESET_SETTING = "preset_editor_global_presets"
Constants.GLOBAL_PRESET_FORMAT = "alfs_dmf_extensions_global_preset_v1"

Constants.MOD_COG_ID = "preset_mod_cog"
Constants.GLOBAL_COG_ID = "global_preset_cog"
Constants.COG_SIZE = 32
Constants.COG_GAP = 6
Constants.COG_Y = 14
Constants.PIN_COG_Y_OFFSET = 4
Constants.GLOBAL_COG_Y = -30
Constants.PIN_SIZE = 44
Constants.COG_MATERIAL = "content/ui/materials/backgrounds/scanner/scanner_map_greek_14"

Constants.PRESET_PANEL_VIEW = "alfs_preset_editor_panel_view"
Constants.PRESET_PANEL_PATH = "Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/preset_editor/panel/view"
Constants.PRESET_PANEL_BLUR = 1.1

Constants.COG_NORMAL_COLOR = { 255, 226, 199, 126 }
Constants.COG_HOVER_COLOR = Color.ui_brown_super_light and Color.ui_brown_super_light(255, true)
	or Color.terminal_text_header_selected(nil, true)

Constants.COLORS = {
	normal = Constants.COG_NORMAL_COLOR,
	hover = Constants.COG_HOVER_COLOR,
	background = Color.terminal_background(nil, true),
	background_hover = Color.terminal_background_gradient(nil, true),
	background_selected = Color.terminal_background_gradient_selected(nil, true),
	frame = Color.terminal_corner(nil, true),
	frame_hover = Color.terminal_corner_hover(nil, true),
	frame_selected = Color.terminal_frame_selected(nil, true),
}
