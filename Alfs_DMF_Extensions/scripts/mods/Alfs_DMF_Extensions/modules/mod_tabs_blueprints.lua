local mod = get_mod("Alfs_DMF_Extensions")

local _view_settings = mod.dmf:io_dofile("dmf/scripts/mods/dmf/modules/ui/options/dmf_options_view_settings")

local ButtonPassTemplates = require("scripts/ui/pass_templates/button_pass_templates")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local ColorUtilities = require("scripts/utilities/ui/colors")

local grid_size = _view_settings.grid_size
local grid_width = grid_size[1]

local settings_grid_width = 1000
local settings_value_height = 48

local COLORS = {
	normal = Color.terminal_text_header(nil, true),
	hover = Color.terminal_text_header_selected(nil, true),
	selected = Color.terminal_text_header_selected(nil, true),

	background = Color.terminal_background(nil, true),
	background_hover = Color.terminal_background_gradient(nil, true),
	background_selected = Color.terminal_background_gradient_selected(nil, true),

	frame = Color.terminal_corner(nil, true),
	frame_hover = Color.terminal_corner_hover(nil, true),
	frame_selected = Color.terminal_frame_selected(nil, true),

	divider = Color.terminal_frame(nil, true),
}

local tab_font_style = table.clone(UIFontSettings.button_primary)

tab_font_style.font_size = 22
tab_font_style.text_horizontal_alignment = "center"
tab_font_style.text_vertical_alignment = "center"

tab_font_style.default_color = COLORS.normal
tab_font_style.hover_color = COLORS.hover
tab_font_style.disabled_color = {
	120,
	100,
	100,
	100,
}

tab_font_style.offset = {
	0,
	0,
	5,
}

tab_font_style.drop_shadow = true

local function is_selected(widget)
	local content = widget.content

	return content.selected == true
end

local blueprints = {
	spacing_vertical = {
		size = {
			grid_width,
			20,
		},
	},

	mod_tab_button = {
		size = {
			250,
			settings_value_height,
		},

		pass_template = {

			{
				pass_type = "hotspot",
				content_id = "hotspot",
				content = {},
			},

			-- hover glow
			{
				pass_type = "texture",
				style_id = "highlight",

				value = "content/ui/materials/frames/hover",

				style = {
					hdr = true,
					scale_to_material = true,

					color = COLORS.frame,

					offset = {
						0,
						0,
						1,
					},

					size_addition = {
						0,
						0,
					},
				},

				change_function = function(content, style)
					local hotspot = content.hotspot

					local progress = math.max(hotspot.anim_hover_progress or 0, hotspot.anim_select_progress or 0)

					style.color[1] = 255 * progress
				end,
			},

			-- selected backing
			{
				pass_type = "texture",
				style_id = "selected_background",

				value = "content/ui/materials/buttons/background_selected",

				style = {
					color = COLORS.background_selected,

					offset = {
						0,
						0,
						2,
					},

					size_addition = {
						0,
						0,
					},
				},

				change_function = function(content, style)
					local mod_reference = content.mod_reference

					local selected = mod_reference
						and mod_reference.selected_tabs[content.selected_tab_key] == content.tab_name

					style.color[1] = selected and 255 or 0
				end,
			},

			-- dark base
			{
				pass_type = "rect",

				style_id = "background",

				style = {
					color = {
						120,
						0,
						0,
						0,
					},

					offset = {
						0,
						0,
						0,
					},

					size = {
						250,
						settings_value_height,
					},
				},
			},

			-- soft green overlay
			{
				pass_type = "rect",

				style_id = "overlay",

				style = {
					color = {
						30,
						120,
						170,
						120,
					},

					offset = {
						0,
						0,
						3,
					},

					size_addition = {
						0,
						0,
					},
				},

				change_function = function(content, style)
					local hotspot = content.hotspot

					local mod_reference = content.mod_reference

					local selected = mod_reference
						and mod_reference.selected_tabs[content.selected_tab_key] == content.tab_name

					if selected then
						style.color[1] = 70
					elseif hotspot.is_hover then
						style.color[1] = 45
					else
						style.color[1] = 20
					end
				end,
			},

			-- border
			{
				pass_type = "texture",
				style_id = "frame",

				value = "content/ui/materials/frames/frame_tile_1px",

				style = {
					scale_to_material = true,

					color = COLORS.frame,

					offset = {
						0,
						0,
						4,
					},
				},

				change_function = function(content, style)
					local hotspot = content.hotspot

					local mod_reference = content.mod_reference

					local selected = mod_reference
						and mod_reference.selected_tabs[content.selected_tab_key] == content.tab_name

					if selected then
						style.color = COLORS.frame_selected
					elseif hotspot.is_hover then
						style.color = COLORS.frame_hover
					else
						style.color = COLORS.frame
					end
				end,
			},

			-- main text
			{
				pass_type = "text",
				style_id = "text",
				value_id = "text",

				style = {
					font_type = "proxima_nova_bold",
					font_size = 22,

					text_horizontal_alignment = "center",
					text_vertical_alignment = "center",

					text_color = COLORS.normal,

					offset = {
						0,
						0,
						6,
					},

					drop_shadow = true,
				},

				change_function = function(content, style)
					local hotspot = content.hotspot
					local mod_reference = content.mod_reference
					local overrides = content.tab_overrides or {}

					local selected = mod_reference
						and mod_reference.selected_tabs[content.selected_tab_key] == content.tab_name

					local c
					if selected then
						c = overrides.font_color_selected or COLORS.selected
					elseif hotspot.is_hover then
						c = overrides.font_color_hover or COLORS.hover
					else
						c = overrides.font_color or COLORS.normal
					end
					style.text_color[1] = c[1]
					style.text_color[2] = c[2]
					style.text_color[3] = c[3]
					style.text_color[4] = c[4]

					if overrides.font_size then
						style.font_size = overrides.font_size
					end
				end,
			},
		},

		size_function = function(parent, config)
			local overrides = config.tab_overrides or {}
			local w = overrides.button_width or 250
			local h = overrides.button_height or settings_value_height
			return { w, h }
		end,

		init = function(parent, widget, entry, callback_name, changed_callback_name)
			local content = widget.content
			local hotspot = content.hotspot

			content.text = entry.display_name
			content.entry = entry
			content.selected = false
			content.tab_overrides = entry.tab_overrides or {}

			if content.tab_overrides.font_size then
				local text_style = widget.style.text
				if text_style then
					text_style.font_size = content.tab_overrides.font_size
				end
			end

			hotspot.pressed_callback = function()
				if entry.disabled then
					return
				end

				content.selected = true

				if entry.on_pressed then
					entry.on_pressed()
				end
			end
		end,
	},
}

return blueprints
