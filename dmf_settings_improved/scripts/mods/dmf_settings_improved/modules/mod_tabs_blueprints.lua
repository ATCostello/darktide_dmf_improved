local mod = get_mod("dmf_settings_improved")

local _view_settings = mod.dmf:io_dofile("dmf/scripts/mods/dmf/modules/ui/options/dmf_options_view_settings")

local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local CheckboxPassTemplates = require("scripts/ui/pass_templates/checkbox_pass_templates")
local DropdownPassTemplates = require("scripts/ui/pass_templates/dropdown_pass_templates")
local InputUtils = require("scripts/managers/input/input_utils")
local KeybindPassTemplates = require("scripts/ui/pass_templates/keybind_pass_templates")
local SliderPassTemplates = require("scripts/ui/pass_templates/slider_pass_templates")
local UIFonts = require("scripts/managers/ui/ui_fonts")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIRenderer = require("scripts/managers/ui/ui_renderer")

local grid_size = _view_settings.grid_size
local grid_width = grid_size[1]

local settings_grid_width = 1000
local settings_value_width = 500
local settings_value_height = 64

local group_header_height = 80

local DEFAULT_NUM_DECIMALS = 0

local _dropdown_deadzone = 0.25 -- 250ms delay before opening keybind popups
local _last_dropdown_pressed = -1

local value_font_style = table.clone(UIFontSettings.list_button)
value_font_style.offset = {
	settings_grid_width - settings_value_width + 25,
	0,
	8,
}

local description_font_style = table.clone(UIFontSettings.list_button)
description_font_style.offset = {
	25,
	0,
	3,
}

local header_font_style = table.clone(UIFontSettings.header_2)
header_font_style.text_vertical_alignment = "bottom"

local blueprints = {
	spacing_vertical = {
		size = {
			grid_width,
			20,
		},
	},
	mod_tab_button = {
		size = {
			grid_width,
			settings_value_height,
		},
		pass_template = ButtonPassTemplates.terminal_tab_menu_with_divider_button,
		init = function(parent, widget, entry, callback_name, changed_callback_name)
			local content = widget.content
			local hotspot = content.hotspot

			hotspot.pressed_callback = function()
				local is_disabled = entry.disabled or false

				if is_disabled then
					return
				end

				callback(parent, callback_name, widget, entry)()
			end

			local display_name = entry.display_name
			content.text = display_name
			content.entry = entry
		end,
	},
}

return blueprints
