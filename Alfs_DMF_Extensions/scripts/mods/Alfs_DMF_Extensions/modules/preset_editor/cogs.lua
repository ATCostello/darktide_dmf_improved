local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")

local Core = mod._preset_core
local Constants = mod._preset_constants
local Styles = mod._preset_panel_styles

local Cogs = mod._preset_cogs or {}
mod._preset_cogs = Cogs

local function cog_pass_template(size)
	return {
		{
			pass_type = "hotspot",
			content_id = "hotspot",
			content = { use_is_focused = true },
		},
		{
			pass_type = "texture",
			style_id = "icon",
			value = Constants.COG_MATERIAL,
			style = {
				color = Styles.copy_color(Constants.COLORS.normal),
				offset = { 0, 0, 2 },
				size = size,
			},
			change_function = function(content, style)
				local hotspot = content.hotspot
				local highlighted = hotspot and (hotspot.is_hover or hotspot.is_focused)

				Styles.set_color(style.color, highlighted and Constants.COLORS.hover or Constants.COLORS.normal)
			end,
		},
	}
end

local function add_global_cog_definitions(definitions)
	if definitions._alfs_global_preset_cog then
		return
	end

	definitions._alfs_global_preset_cog = true

	local size = { Constants.COG_SIZE, Constants.COG_SIZE }

	definitions.scenegraph_definition[Constants.GLOBAL_COG_ID] = {
		parent = "title_divider",
		horizontal_alignment = "left",
		vertical_alignment = "bottom",
		size = size,
		position = { 340, -35, 2 },
	}

	definitions.widget_definitions[Constants.GLOBAL_COG_ID] = UIWidget.create_definition(
		cog_pass_template(size),
		Constants.GLOBAL_COG_ID,
		{
			visible = true,
			tooltip_text = mod:localize("preset_editor_global_tooltip"),
		},
		size
	)
end

local function add_mod_cog_definitions(definitions)
	if definitions.scenegraph_definition[Constants.MOD_COG_ID] then
		return
	end

	local size = { Constants.COG_SIZE, Constants.COG_SIZE }

	definitions.scenegraph_definition[Constants.MOD_COG_ID] = {
		parent = "panel",
		horizontal_alignment = "left",
		vertical_alignment = "top",
		size = size,
		position = { 0, Constants.COG_Y, 4 },
	}

	definitions.widget_definitions[Constants.MOD_COG_ID] = UIWidget.create_definition(
		cog_pass_template(size),
		Constants.MOD_COG_ID,
		{
			visible = false,
			tooltip_text = mod:localize("preset_editor_tooltip"),
		},
		size
	)
end

local function is_options_header(self)
	local class_table = getmetatable(self)

	return class_table and class_table.__class_name == "ViewElementOptionsHeader"
end

local function mod_cog_content(self)
	local widget = self and self._widgets_by_name and self._widgets_by_name[Constants.MOD_COG_ID]

	return widget and widget.content or nil
end

local function sync_mod_cog(self)
	local content = mod_cog_content(self)

	if not content then
		return nil, nil
	end

	local category_entry = self._category_entry
	local mod_name = category_entry and category_entry.mod_name
	local visible = Core.presets_enabled()
		and mod_name ~= nil
		and not category_entry.is_toggle_mods_category
		and get_mod(mod_name) ~= nil

	content.visible = visible
	content.tooltip_text = mod:localize("preset_editor_tooltip")

	local hotspot = content.hotspot

	if hotspot then
		hotspot.use_is_focused = true
	end

	return content, category_entry
end

local function handle_global_preset_cog(view)
	if not view or view.view_name ~= "dmf_options_view" or view._popup_id then
		return
	end

	local widget = view._widgets_by_name and view._widgets_by_name[Constants.GLOBAL_COG_ID]
	local content = widget and widget.content

	if content then
		content.visible = Core.presets_enabled()
	end

	if not content or not content.visible then
		return
	end

	local hotspot = content.hotspot

	if hotspot and hotspot.on_pressed then
		hotspot.on_pressed = nil
		mod.open_global_preset_editor(view)
	end
end

mod._handle_global_preset_cog = handle_global_preset_cog

mod._prepare_global_preset_cog = function(definitions, settings)
	if
		settings
		and settings.name == "dmf_options_view"
		and type(definitions) == "table"
		and type(definitions.scenegraph_definition) == "table"
		and type(definitions.widget_definitions) == "table"
	then
		add_global_cog_definitions(definitions)
	end
end

local function position_mod_cog(self)
	local content = mod_cog_content(self)

	if not content or not content.visible then
		return
	end

	local title_width = self:_scenegraph_size("title") or 0
	local cog_x = title_width + Constants.COG_GAP
	local cog_y = Constants.COG_Y

	if self._has_pin then
		local pin_position = type(self.scenegraph_position) == "function" and self:scenegraph_position("pin") or nil
		local pin_x = pin_position and pin_position[1] or (title_width + Constants.COG_GAP)
		local pin_y = pin_position and pin_position[2] or (Constants.COG_Y - (Constants.PIN_SIZE - Constants.COG_SIZE) * 0.5)

		cog_x = pin_x + Constants.PIN_SIZE + Constants.COG_GAP
		cog_y = pin_y + (Constants.PIN_SIZE - Constants.COG_SIZE) * 0.5
	end

	if self._alfs_cog_x == cog_x and self._alfs_cog_y == cog_y then
		return
	end

	self._alfs_cog_x = cog_x
	self._alfs_cog_y = cog_y
	self:_set_scenegraph_position(Constants.MOD_COG_ID, cog_x, cog_y)
	self:_force_update_scenegraph()
end

local function position_cog_tooltip(self)
	local tooltip = self._widgets_by_name and self._widgets_by_name.tooltip
	local cog_widget = self._widgets_by_name and self._widgets_by_name[Constants.MOD_COG_ID]

	if not tooltip or not cog_widget then
		return
	end

	local tooltip_width = self:_scenegraph_size("tooltip") or 0
	local cog_position = self:scenegraph_position(Constants.MOD_COG_ID) or { 0, 0, 0 }
	local widget_x = cog_position[1] + (cog_widget.offset and cog_widget.offset[1] or 0)
	local widget_y = cog_position[2] + (cog_widget.offset and cog_widget.offset[2] or 0)

	tooltip.offset[1] = widget_x + (Constants.COG_SIZE - tooltip_width) * 0.5
	tooltip.offset[2] = widget_y + Constants.COG_SIZE + Constants.COG_GAP
end

mod._install_preset_cog_hooks = function()
	if mod._preset_cog_hooks_installed or type(mod.hook) ~= "function" or type(mod.hook_safe) ~= "function" then
		return
	end

	local classes = rawget(_G, "CLASSES") or rawget(_G, "CLASS")

	if type(classes) ~= "table" then
		return
	end

	local view_element_base = classes.ViewElementBase

	if type(view_element_base) ~= "table" then
		return
	end

	mod._preset_cog_hooks_installed = true

	mod:hook(view_element_base, "init", function(func, self, parent, draw_layer, start_scale, definitions, ...)
		if is_options_header(self) and type(definitions) == "table" then
			add_mod_cog_definitions(definitions)
		end

		return func(self, parent, draw_layer, start_scale, definitions, ...)
	end)

	mod:hook_safe(view_element_base, "update", function(self, ...)
		if not is_options_header(self) then
			return
		end

		local content, category_entry = sync_mod_cog(self)
		local hotspot = content and content.hotspot

		position_mod_cog(self)

		if hotspot and content.visible and hotspot.on_pressed and self._parent then
			hotspot.on_pressed = nil
			mod.open_preset_editor(self._parent, category_entry and category_entry.mod_name)
		end
	end)

	local header_class = classes.ViewElementOptionsHeader

	if type(header_class) ~= "table" then
		return
	end

	if type(header_class._position_tooltip) == "function" then
		mod:hook(header_class, "_position_tooltip", function(func, self, hovered_widget)
			if hovered_widget and hovered_widget == self._widgets_by_name[Constants.MOD_COG_ID] then
				position_cog_tooltip(self)
				return
			end

			func(self, hovered_widget)
		end)
	end

	if type(header_class._update_text_layout) == "function" then
		mod:hook_safe(header_class, "_update_text_layout", function(self)
			position_mod_cog(self)
		end)
	end

	if type(header_class._update_tooltip) == "function" then
		mod:hook_safe(header_class, "_update_tooltip", function(self)
			local content = mod_cog_content(self)

			if not content or not content.visible then
				local tooltip = self._widgets_by_name and self._widgets_by_name.tooltip

				if tooltip and self._hovered_tooltip_widget == self._widgets_by_name[Constants.MOD_COG_ID] then
					tooltip.content.visible = false
					self._hovered_tooltip_widget = nil
				end

				return
			end

			local hotspot = content.hotspot

			if not hotspot or not (hotspot.is_hover or hotspot.is_focused) then
				return
			end

			local tooltip = self._widgets_by_name.tooltip
			local tooltip_text = content.tooltip_text or mod:localize("preset_editor_tooltip")

			if
				self._hovered_tooltip_widget ~= self._widgets_by_name[Constants.MOD_COG_ID]
				or tooltip.content.text ~= tooltip_text
				or tooltip.content.mod_name_text ~= ""
			then
				self._hovered_tooltip_widget = self._widgets_by_name[Constants.MOD_COG_ID]
				self._tooltip_layout_dirty = true
			end

			tooltip.content.visible = true
			tooltip.content.text = tooltip_text
			tooltip.content.mod_name_text = ""
			self:_position_tooltip(self._widgets_by_name[Constants.MOD_COG_ID])
		end)
	end
end
