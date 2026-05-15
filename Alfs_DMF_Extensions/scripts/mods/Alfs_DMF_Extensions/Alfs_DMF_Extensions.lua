local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")

mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/Alfs_DMF_Extensions_localization")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/load_dmf")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/save_scroll_position")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/mod_tabs")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/rgb_widget")

mod.last_category = nil
mod.current_category = nil

-- add definitions to the dmf_options_view
mod:hook(CLASS.BaseView, "init", function(func, self, settings, context)
	func(self, settings, context)

	if self.view_name ~= "dmf_options_view" then
		return
	end

	local defs = self._definitions
	defs.scenegraph_definition = defs.scenegraph_definition or {}

	defs.scenegraph_definition.mod_tab_area = {
		parent = "settings_grid_content_pivot",
		horizontal_alignment = "left",
		vertical_alignment = "top",
		size = { 900, 60 },
		position = { 0, 45, 800 },
	}

	defs.scenegraph_definition.mod_tab_content = {
		parent = "mod_tab_area",
		horizontal_alignment = "left",
		vertical_alignment = "center",
		size = { 900, 60 },
		position = { 0, 0, 801 },
	}

	defs.scenegraph_definition.mod_tab_scrollbar = {
		parent = "mod_tab_area",
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		size = { 900, 8 },
		position = { 0, -10, 802 },
	}

	--defs.scenegraph_definition.settings_grid_background.size[1] = 1920
	defs.scenegraph_definition.settings_grid_background.size[2] = 1012
	defs.scenegraph_definition.settings_grid_background.position[2] = 16
	defs.scenegraph_definition.settings_scrollbar.size[2] = 1012
	defs.scenegraph_definition.settings_grid_mask.size[2] = 2000
	defs.scenegraph_definition.settings_grid_mask.position[2] = -10

	-- rebuild the live scenegraph
	self._ui_scenegraph = UIScenegraph.init_scenegraph(defs.scenegraph_definition)
end)

-- clear category on exit
mod:hook_safe(CLASS.BaseView, "on_exit", function(self)
	mod.last_category = nil
end)

mod:hook_safe(CLASS.BaseView, "update", function(self, dt, t, input_service)
	if self.view_name ~= "dmf_options_view" then
		return
	end

	mod.current_category = self._selected_category

	self.dmf = mod.dmf
	dbg_self = self

	if mod:get("enable_scroll_position_saving") then
		mod._saveScrollPosition(self)
	end

	if mod:get("enable_mod_tabs") then
		mod._addModTabs(self)
	end

	if mod:get("enable_RGB_widget") then
		mod._addRgbSliders(self)
	end

	mod.last_category = mod.current_category
end)
