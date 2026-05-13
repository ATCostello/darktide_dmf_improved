local mod = get_mod("Alfs_DMF_Extensions")

local UIWidgetGrid = require("scripts/ui/widget_logic/ui_widget_grid")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local view_settings = mod.dmf:io_dofile("dmf/scripts/mods/dmf/modules/ui/options/dmf_options_view_settings")

local _rgb_blueprints =
	mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/rgb_widget_blueprints")

mod.inject_rgb_widgets = function(self, category)
	local widgets = self._settings_category_widgets and self._settings_category_widgets[category]

	if not widgets or not self._options_templates then
		return
	end

	for _, template in ipairs(self._options_templates.settings or {}) do
		if template.category == category then
			local display_name = template.display_name
			local setting_id = template.setting_id
			local setting_type = template.widget_type

			-- Replace this group_header widget content with the RGB widgets from our blueprint
			-- expected content is in the following format, with the commonality being the setting_id group is "xx_colour", and the sub_widgets are "xx_colour_R", "xx_colour_G", "xx_colour_B"
			--[[
                {
                    setting_id = "main_font_colour",
                    type = "group",
                    tab = "General",
                    sub_widgets = {
                        {
                            setting_id = "main_font_colour_R",
                            type = "numeric",
                            default_value = 255,
                            range = {
                                0,
                                255,
                            },
                            tooltip = "main_font_colour_tooltip",
                        },
                        {
                            setting_id = "main_font_colour_G",
                            type = "numeric",
                            default_value = 255,
                            range = {
                                0,
                                255,
                            },
                            tooltip = "main_font_colour_tooltip",
                        },
                        {
                            setting_id = "main_font_colour_B",
                            type = "numeric",
                            default_value = 255,
                            range = {
                                0,
                                255,
                            },
                            tooltip = "main_font_colour_tooltip",
                        },
                    },
                },
                ]]
			if setting_type == "group_header" and (setting_id and string.find(setting_id, "_colour")) then
				-- now need to check the following three widgets are either "colour_r", "colour_g", "colour_b" OR check the next 4 for "colour_A", "colour_R", "colour_G", "colour_B"
				-- Then replace the RGB/ARGB widgets with our custom one, using the same values passed through

				--mod:echo("Injecting RGB widgets for: " .. display_name)
			end
		end
	end
end

-- ############################################################
-- Update
-- ############################################################

mod._addRgbSliders = function(self, dt, t, input_service)
	if mod.current_category ~= mod.last_category then
		mod.last_category = mod.current_category

		mod.inject_rgb_widgets(self, mod.current_category)
	end
end
