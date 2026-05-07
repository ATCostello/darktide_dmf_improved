local mod = get_mod("dmf_settings_improved")

local UIWidget = require("scripts/managers/ui/ui_widget")
local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")

mod:io_dofile("dmf_settings_improved/scripts/mods/dmf_settings_improved/dmf_settings_improved_localization")
mod:io_dofile("dmf_settings_improved/scripts/mods/dmf_settings_improved/modules/load_dmf")
mod:io_dofile("dmf_settings_improved/scripts/mods/dmf_settings_improved/modules/save_scroll_position")
mod:io_dofile("dmf_settings_improved/scripts/mods/dmf_settings_improved/modules/mod_tabs")

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
		parent = "settings_grid_background",
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
		position = { 0, -10, 203 },
	}

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

	mod._saveScrollPosition(self)

	mod._addModTabs(self)

	mod.last_category = mod.current_category
end)
