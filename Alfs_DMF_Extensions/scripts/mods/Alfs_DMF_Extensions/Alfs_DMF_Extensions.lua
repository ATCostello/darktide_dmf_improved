local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")

mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/Alfs_DMF_Extensions_localization")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/load_dmf")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/save_scroll_position")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/mod_tabs")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/rgb_widget")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/dropdown_icons")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/font_type_support")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/scrollable_dropdown")
mod:io_dofile("Alfs_DMF_Extensions/scripts/mods/Alfs_DMF_Extensions/modules/mod_reload_keybind")

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

	-- ensure pivot nodes have explicit position so world_position is computed
	if
		defs.scenegraph_definition.settings_grid_start and not defs.scenegraph_definition.settings_grid_start.position
	then
		defs.scenegraph_definition.settings_grid_start.position = { 0, 0, 0 }
	end
	if
		defs.scenegraph_definition.settings_grid_content_pivot
		and not defs.scenegraph_definition.settings_grid_content_pivot.position
	then
		defs.scenegraph_definition.settings_grid_content_pivot.position = { 0, 0, 0 }
	end

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

	if mod:get("enable_scroll_position_saving") then
		mod._saveScrollPosition(self)
	end

	mod._addModTabs(self, dt, t, input_service)

	if mod:get("enable_RGB_widget") then
		mod._addRgbSliders(self)
	end
	if mod:get("enable_RGB_widget") then
		mod._updateRGBSliders(self, input_service, dt, t)
	end

	mod._addDropdownIcons(self, dt, t, input_service)
	mod._addFontSupport(self, dt, t, input_service)
	mod._addScrollableDropdown(self, dt, t, input_service)

	mod.last_category = mod.current_category
end)
