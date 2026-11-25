local mod = get_mod("Alfs_DMF_Extensions")

local Styles = mod._preset_panel_styles

local Portraits = mod._preset_panel_portraits or {}
mod._preset_panel_portraits = Portraits

Portraits.MATERIAL = "content/ui/materials/base/ui_portrait_frame_base"
Portraits.NO_RENDER = "content/ui/materials/base/ui_portrait_frame_base_no_render"

Portraits.frame_material = function(profile)
	if type(profile) ~= "table" then
		return Portraits.MATERIAL
	end

	local loadout = profile.loadout
	local frame_item = loadout and loadout.slot_portrait_frame
	local material = type(frame_item) == "table" and frame_item.icon_material or nil

	if type(material) == "string" and material ~= "" then
		return material
	end

	return Portraits.MATERIAL
end

local function profile_is_valid(profile)
	if type(profile) ~= "table" then
		return false
	end

	local unit = profile.unit

	if unit and type(Unit) == "table" and type(Unit.alive) == "function" and not Unit.alive(unit) then
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

	material_values.use_placeholder_texture = 1
	material_values.rows = nil
	material_values.columns = nil
	material_values.grid_index = nil
	material_values.texture_icon = nil
	material_values.portrait_frame_texture = nil

	if widget.content then
		widget.content.character_portrait = Portraits.NO_RENDER
	end
end

Portraits.set = function(widget, grid_index, rows, columns, render_target, profile)
	local style = widget and widget.style and widget.style.character_portrait
	local material_values = style and style.material_values

	if not material_values then
		return
	end

	material_values.use_placeholder_texture = 0
	material_values.rows = rows
	material_values.columns = columns
	material_values.grid_index = math.max(0, (grid_index or 1) - 1)
	material_values.texture_icon = render_target
	material_values.portrait_frame_texture = Portraits.frame_material(profile)

	if widget.content then
		widget.content.character_portrait = Portraits.frame_material(profile)
	end
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

	content.icon_load_id = ui:load_profile_portrait(profile, function(grid_index, rows, columns, render_target)
		Portraits.set(widget, grid_index, rows, columns, render_target, profile)
	end, nil, function()
		Portraits.clear(widget)
	end)
end

Portraits.unload = function(parent, widget)
	local content = widget and widget.content
	local ui = Managers and Managers.ui
	local load_id = content and content.icon_load_id

	if load_id and ui and type(ui.unload_profile_portrait) == "function" then
		ui:unload_profile_portrait(load_id)
	end

	if content then
		content.icon_load_id = nil
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
