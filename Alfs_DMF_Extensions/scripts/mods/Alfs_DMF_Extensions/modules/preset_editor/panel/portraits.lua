local mod = get_mod("Alfs_DMF_Extensions")

local UISettings = require("scripts/settings/ui/ui_settings")

local Styles = mod._preset_panel_styles

local Portraits = mod._preset_panel_portraits or {}
mod._preset_panel_portraits = Portraits

Portraits.MATERIAL = UISettings and UISettings.portrait_frame_default_material
	or "content/ui/materials/base/ui_portrait_frame_base"
Portraits.DEFAULT_TEXTURE = UISettings and UISettings.portrait_frame_default_texture or nil
Portraits.NO_RENDER = "content/ui/materials/base/ui_portrait_frame_base_no_render"

local function invalidate_portrait_material(widget)
	for _, pass in ipairs(widget and widget.passes or {}) do
		if pass.style_id == "character_portrait" and pass.data then
			pass.data.material_value = nil
		end
	end
end

Portraits.frame_item = function(profile)
	if type(profile) ~= "table" then
		return nil
	end

	local loadout = profile.loadout

	return type(loadout) == "table" and loadout.slot_portrait_frame or nil
end

Portraits.frame_material = function(profile)
	local frame_item = Portraits.frame_item(profile)
	local material = type(frame_item) == "table" and frame_item.icon_material or nil

	if type(material) == "string" and material ~= "" then
		return material
	end

	return Portraits.MATERIAL
end

Portraits.set_frame_from_item = function(widget, item)
	local style = widget and widget.style and widget.style.character_portrait
	local material_values = style and style.material_values
	local icon_material = type(item) == "table" and item.icon_material or nil

	if type(icon_material) == "string" and icon_material ~= "" then
		if material_values then
			material_values.portrait_frame_texture = nil
		end

		if widget and widget.content then
			widget.content.character_portrait = icon_material
		end
	else
		if widget and widget.content then
			widget.content.character_portrait = Portraits.MATERIAL
		end

		if material_values then
			local icon = type(item) == "table" and item.icon or nil

			if type(icon) == "string" and icon ~= "" then
				material_values.portrait_frame_texture = icon
			elseif Portraits.DEFAULT_TEXTURE then
				material_values.portrait_frame_texture = Portraits.DEFAULT_TEXTURE
			else
				material_values.portrait_frame_texture = nil
			end
		end
	end

	if widget then
		widget.dirty = true
	end
end

Portraits.set_frame = function(widget, profile)
	Portraits.set_frame_from_item(widget, Portraits.frame_item(profile))
end

local function profile_is_valid(profile)
	if type(profile) ~= "table" then
		return false
	end

	local unit = profile.unit

	if
		type(unit) == "userdata"
		and type(Unit) == "table"
		and type(Unit.alive) == "function"
		and not Unit.alive(unit)
	then
		return false
	end

	return true
end

Portraits.clear = function(widget)
	local style = widget and widget.style and widget.style.character_portrait
	local material_values = style and style.material_values

	if not material_values then
		return
	end

	if widget._preset_portrait_target ~= nil then
		widget._preset_portrait_target = nil
		invalidate_portrait_material(widget)
	end

	material_values.use_placeholder_texture = 1
	material_values.rows = nil
	material_values.columns = nil
	material_values.grid_index = nil
	material_values.texture_icon = nil
	material_values.portrait_frame_texture = nil

	if widget.content then
		widget.content.character_portrait = Portraits.NO_RENDER
	end

	widget.dirty = true
end

Portraits.set = function(widget, grid_index, rows, columns, render_target, profile)
	local style = widget and widget.style and widget.style.character_portrait
	local material_values = style and style.material_values

	if not material_values then
		return
	end

	if widget._preset_portrait_target ~= render_target then
		widget._preset_portrait_target = render_target
		invalidate_portrait_material(widget)
	end

	material_values.use_placeholder_texture = 0
	material_values.rows = rows
	material_values.columns = columns
	material_values.grid_index = math.max(0, (grid_index or 1) - 1)
	material_values.texture_icon = render_target
	Portraits.set_frame(widget, profile)

	widget.dirty = true
end

Portraits.load = function(parent, widget, element)
	local content = widget and widget.content
	local profile = element and element.profile or content and content.profile
	local ui = Managers and Managers.ui

	if not content or content.icon_load_id or not profile_is_valid(profile) then
		return
	end

	if not ui or type(ui.load_profile_portrait) ~= "function" then
		return
	end

	local render_context = parent and parent.package_scope and { package_scope = parent.package_scope } or nil

	content.icon_load_id = ui:load_profile_portrait(
		profile,
		function(grid_index, rows, columns, render_target)
			if content.profile == profile then
				Portraits.set(widget, grid_index, rows, columns, render_target, profile)
			end
		end,
		render_context,
		function()
			if content.profile == profile then
				Portraits.clear(widget)
			end
		end
	)

	local frame_item = Portraits.frame_item(profile)

	if frame_item and type(ui.load_item_icon) == "function" then
		content.frame_load_id = ui:load_item_icon(frame_item, function(item)
			if content.profile == profile then
				Portraits.set_frame_from_item(widget, item)
			end
		end)
	end
end

Portraits.unload = function(parent, widget)
	local content = widget and widget.content
	local ui = Managers and Managers.ui
	local load_id = content and content.icon_load_id

	if load_id and ui and type(ui.unload_profile_portrait) == "function" then
		ui:unload_profile_portrait(load_id)
	end

	local frame_load_id = content and content.frame_load_id

	if frame_load_id and ui and type(ui.unload_item_icon) == "function" then
		ui:unload_item_icon(frame_load_id)
	end

	if content then
		content.icon_load_id = nil
		content.frame_load_id = nil
	end

	Portraits.clear(widget)
end

Portraits.pass = function(size, offset)
	return {
		pass_type = "texture",
		style_id = "character_portrait",
		value = Portraits.MATERIAL,
		value_id = "character_portrait",
		style = {
			theme_exempt = true,
			horizontal_alignment = "left",
			vertical_alignment = "center",
			size = size or { 40, 46 },
			offset = offset or { 10, 0, 3 },
			material_values = {
				use_placeholder_texture = 1,
				rows = nil,
				columns = nil,
				grid_index = nil,
				texture_icon = nil,
				portrait_frame_texture = nil,
			},
		},
	}
end

Portraits.color = Styles and Styles.COLORS or nil
