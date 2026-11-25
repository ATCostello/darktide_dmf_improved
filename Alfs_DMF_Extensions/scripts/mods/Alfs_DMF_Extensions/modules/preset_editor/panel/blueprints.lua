local mod = get_mod("Alfs_DMF_Extensions")

local Styles = mod._preset_panel_styles
local Portraits = mod._preset_panel_portraits

local Blueprints = mod._preset_panel_blueprints or {}
mod._preset_panel_blueprints = Blueprints

local function init_hotspot_widget(parent, widget, element, callback_name)
	local content = widget and widget.content

	if not content then
		return
	end

	content.hotspot = content.hotspot or {}
	content.hotspot.pressed_callback = callback_name and callback(parent, callback_name, widget, element) or nil
	content.element = element
	content.text = element and element.text or ""
	content.original_text = content.text
	content.tooltip_text = element and element.tooltip or ""
end

local character_toggle_template = {}

for _, pass in ipairs(Styles.button_passes("left", 20, { 94, 0, 3 })) do
	if pass.style_id ~= "text" then
		character_toggle_template[#character_toggle_template + 1] = pass
	end
end

character_toggle_template[#character_toggle_template + 1] = Portraits.pass({ 40, 46 }, { 10, 0, 3 })
character_toggle_template[#character_toggle_template + 1] = {
	pass_type = "text",
	value_id = "assignment_text",
	style_id = "assignment_text",
	style = Styles.make_text_style(20, { 60, 2, 3 }, Styles.COLORS.normal, "center"),
}
character_toggle_template[#character_toggle_template + 1] = {
	pass_type = "text",
	value_id = "character_name",
	style_id = "character_name",
	style = Styles.make_text_style(20, { 94, 2, 3 }, Styles.COLORS.text),
}
character_toggle_template[#character_toggle_template + 1] = {
	pass_type = "text",
	value_id = "character_archetype_title",
	style_id = "character_archetype_title",
	style = Styles.make_text_style(17, { 400, 2, 3 }, Styles.COLORS.muted),
}

Blueprints.preset_entry = {
	size = { 400, 42 },
	pass_template = Styles.button_passes("left", 20, { 94, 0, 3 }),
	init = function(parent, widget, element, callback_name)
		init_hotspot_widget(parent, widget, element, callback_name)

		local content = widget and widget.content

		if content then
			content.name = element and element.name or nil
			content.hotspot.is_selected = parent and parent._selected_name == content.name or false
		end
	end,
}

Blueprints.action_button = {
	size = { 640, 40 },
	pass_template = Styles.button_passes("center", 20),
	init = init_hotspot_widget,
}

Blueprints.character_toggle = {
	size = { 640, 52 },
	pass_template = character_toggle_template,
	init = function(parent, widget, element, callback_name)
		init_hotspot_widget(parent, widget, element, callback_name)

		local content = widget and widget.content

		if not content then
			return
		end

		content.profile = element and element.profile or nil
		content.character_portrait = Portraits.frame_material(content.profile)
		content.assignment_text = element and element.assigned and "\226\156\147" or ""
		content.character_name = element and element.name or ""
		content.character_archetype_title = element and element.archetype_name or ""
	end,
	load_icon = Portraits.load,
	unload_icon = Portraits.unload,
	destroy = Portraits.unload,
}

Blueprints.info = {
	size = { 640, 32 },
	pass_template = Styles.info_passes(18, { 10, 0, 2 }),
	init = function(_, widget, element)
		local content = widget and widget.content

		if content then
			content.text = element and element.text or ""
		end
	end,
}

return Blueprints
