local mod = get_mod("Alfs_DMF_Extensions")

local dmf = get_mod("DMF")
mod.dmf = dmf

local original_initialize = dmf.initialize_mod_options

dmf.initialize_mod_options = function(passed_mod, options)
	local result = original_initialize(passed_mod, options)

	if not (options and options.widgets) then
		return result
	end

	local initialized_widgets = dmf.options_widgets_data[#dmf.options_widgets_data]

	if not initialized_widgets then
		return result
	end

	local raw_lookup = {}

	local function collect_widgets(widgets)
		for _, widget in ipairs(widgets) do
			if widget.setting_id then
				raw_lookup[widget.setting_id] = widget
			end

			if widget.sub_widgets then
				collect_widgets(widget.sub_widgets)
			end
		end
	end

	collect_widgets(options.widgets)

	for _, initialized in ipairs(initialized_widgets) do
		local raw = raw_lookup[initialized.setting_id]

		if raw then
			initialized.tab = raw.tab
		end
	end

	return result
end

local original_create = dmf.create_mod_options_settings

dmf.create_mod_options_settings = function(self, options_templates)
	local result = original_create(self, options_templates)

	local settings = result.settings

	if not settings then
		return result
	end

	local tab_lookup = {}
	local setting_id_lookup = {}
	local category_mod_map = {}
	local group_depth_lookup = {}

	for _, mod_widgets in ipairs(dmf.options_widgets_data) do
		local header = mod_widgets[1]
		local mod_name = header and header.mod_name
		local category_name = (header and (header.readable_mod_name or header.mod_name)) or ""

		if mod_name then
			tab_lookup[mod_name] = tab_lookup[mod_name] or {}
			category_mod_map[category_name] = mod_name
		end

		for _, widget in ipairs(mod_widgets) do
			if mod_name then
				if widget.tab then
					if widget.setting_id then
						tab_lookup[mod_name][widget.setting_id] = widget.tab
					end

					if widget.title then
						tab_lookup[mod_name][widget.title] = widget.tab
					end
				end
			end

			if widget.setting_id then
				setting_id_lookup[widget.setting_id] = widget.setting_id
			end

			if widget.title then
				setting_id_lookup[widget.title] = widget.setting_id
			end

			if widget.type == "group" and widget.title and widget.depth then
				group_depth_lookup[widget.title] = widget.depth
			end
		end
	end

	for _, template in ipairs(settings) do
		local mod_name = category_mod_map[template.category]

		if mod_name then
			local mod_tabs = tab_lookup[mod_name]
			local tab = mod_tabs and (mod_tabs[template.setting_id] or mod_tabs[template.display_name])

			if tab then
				template.tab = tab
			end
		end

		if not template.tab and template.widget_type == "group_header" and template.display_name then
			local depth = group_depth_lookup[template.display_name]

			if depth == 0 then
				template.tab = template.display_name
			end
		end

		if template.category and string.find(template.category, "Markers") then
			mod:info(
				"[load_dmf] template: cat=%s, type=%s, display=%s, setting=%s, tab=%s, depth=%s",
				tostring(template.category),
				tostring(template.widget_type),
				tostring(template.display_name),
				tostring(template.setting_id),
				tostring(template.tab),
				tostring(group_depth_lookup[template.display_name])
			)
		end

		local setting_id = setting_id_lookup[template.setting_id] or setting_id_lookup[template.display_name]

		if setting_id then
			template.setting_id = setting_id
		end
	end

	return result
end

mod.on_all_mods_loaded = function()
	mod.dmf = get_mod("DMF")

	for _, mod_widgets in ipairs(dmf.options_widgets_data) do
		local header = mod_widgets[1]
		local mod_name = (header and header.mod_name) or "unknown"

		local has_explicit_tabs = false

		for _, widget in ipairs(mod_widgets) do
			if widget.tab then
				has_explicit_tabs = true

				break
			end
		end

		if not has_explicit_tabs then
			for _, widget in ipairs(mod_widgets) do
				if not widget.tab and widget.parent_index and widget.type ~= "group" then
					local pi = widget.parent_index

					while pi do
						local parent = mod_widgets[pi]

						if parent and parent.type == "group" and parent.depth == 0 and parent.title then
							widget.tab = parent.title
							break
						end

						pi = parent and parent.parent_index
					end
				end
			end

			for _, widget in ipairs(mod_widgets) do
				if not widget.tab and widget.type == "group" and widget.depth == 0 and widget.title then
					widget.tab = widget.title
				end
			end
		end
	end
end
