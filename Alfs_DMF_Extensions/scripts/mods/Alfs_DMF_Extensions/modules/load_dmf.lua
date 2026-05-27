local mod = get_mod("Alfs_DMF_Extensions")

local dmf = get_mod("DMF")
mod.dmf = dmf

local original_initialize_mod_data = dmf.initialize_mod_data

dmf.initialize_mod_data = function(mod_instance, mod_data)
	local result = original_initialize_mod_data(mod_instance, mod_data)

	if mod_data and mod_data.required_icon_packages then
		local packages = mod._required_icon_packages
		for _, pkg in ipairs(mod_data.required_icon_packages) do
			if type(pkg) == "string" then
				packages[#packages + 1] = pkg
			end
		end
	end

	return result
end

local original_initialize = dmf.initialize_mod_options

dmf.initialize_mod_options = function(passed_mod, options)
	local result = original_initialize(passed_mod, options)

	if options and options.required_icon_packages then
		local packages = mod._required_icon_packages
		for _, pkg in ipairs(options.required_icon_packages) do
			if type(pkg) == "string" then
				packages[#packages + 1] = pkg
			end
		end
	end

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

	local raw_tab_overrides = {}

	local function collect_overrides(widgets)
		for _, w in ipairs(widgets) do
			if w.tab_overrides then
				raw_tab_overrides[w.setting_id] = w.tab_overrides
			end
			if w.sub_widgets then
				collect_overrides(w.sub_widgets)
			end
		end
	end
	collect_overrides(options.widgets)

	for _, initialized in ipairs(initialized_widgets) do
		local raw = raw_lookup[initialized.setting_id]

		if raw then
			initialized.tab = raw.tab
		end

		local overrides = raw_tab_overrides[initialized.setting_id]
		if overrides then
			initialized.tab_overrides = overrides
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
				setting_id_lookup[mod.compound_key(category_name, widget.setting_id)] = widget.setting_id
			end

			if widget.title then
				setting_id_lookup[mod.compound_key(category_name, widget.title)] = widget.setting_id
			end

			if widget.type == "group" and widget.title and widget.depth then
				group_depth_lookup[mod.compound_key(category_name, widget.title)] = widget.depth
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
			local depth_key = template.display_name and mod.compound_key(template.category, template.display_name)
			local depth = depth_key and group_depth_lookup[depth_key]

			if depth == 0 then
				template.tab = template.display_name
				template._auto_tab = true
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
				tostring(group_depth_lookup[mod.compound_key(template.category, template.display_name)])
			)
		end

		local setting_id_key = template.setting_id and mod.compound_key(template.category, template.setting_id)
		local display_name_key = template.display_name and mod.compound_key(template.category, template.display_name)
		local resolved_id = setting_id_lookup[setting_id_key] or setting_id_lookup[display_name_key]

		if resolved_id then
			template.setting_id = resolved_id
		end
	end

	for _, template in ipairs(settings) do
		if template.widget_type == "group_header" and template.indentation_level == nil and template.display_name then
			local depth_key = template.display_name and mod.compound_key(template.category, template.display_name)
			local depth = group_depth_lookup[depth_key]

			if depth ~= nil then
				template.indentation_level = depth
			end
		end
	end

	local cat_group_tabs = {}

	for _, mod_widgets in ipairs(dmf.options_widgets_data) do
		local header = mod_widgets[1]
		local cat_name = (header and (header.readable_mod_name or header.mod_name)) or ""

		cat_group_tabs[cat_name] = {}

		for _, w in ipairs(mod_widgets) do
			if w.type == "group" and w.tab then
				cat_group_tabs[cat_name][#cat_group_tabs[cat_name] + 1] = w.tab
			end
		end
	end

	local consumed = {}

	for _, template in ipairs(settings) do
		if
			template.widget_type == "group_header"
			and not template.tab
			and not template.group_name
			and template.category
			and template.indentation_level == 0
		then
			local tabs = cat_group_tabs[template.category]

			if tabs and #tabs > 0 then
				consumed[template.category] = (consumed[template.category] or 0) + 1
				local idx = consumed[template.category]

				if tabs[idx] then
					template.tab = tabs[idx]
					template._auto_tab = true
				end
			end
		end
	end

	return result
end

mod.on_all_mods_loaded = function()
	mod.dmf = get_mod("DMF")

	mod._genuine_explicit_tab_mods = {}

	for _, mod_widgets in ipairs(dmf.options_widgets_data) do
		local header = mod_widgets[1]
		local category_name = (header and (header.readable_mod_name or header.mod_name)) or ""

		for _, widget in ipairs(mod_widgets) do
			if widget.tab then
				mod._genuine_explicit_tab_mods[category_name] = true
				break
			end
		end
	end

	for _, mod_widgets in ipairs(dmf.options_widgets_data) do
		local header = mod_widgets[1]
		local mod_name = (header and header.mod_name) or "unknown"
		local category_name = (header and (header.readable_mod_name or header.mod_name)) or ""

		local has_explicit_tabs = mod._genuine_explicit_tab_mods[category_name] or false

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
		else
			for _, widget in ipairs(mod_widgets) do
				if not widget.tab and widget.type ~= "group" and widget.parent_index then
					local pi = widget.parent_index
					while pi do
						local parent = mod_widgets[pi]
						if parent then
							if parent.tab then
								widget.tab = parent.tab
								break
							elseif parent.type == "group" and parent.depth == 0 and parent.title then
								widget.tab = parent.title
								break
							end
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

	mod.tab_overrides_lookup = mod.tab_overrides_lookup or {}

	for _, mod_widgets in ipairs(dmf.options_widgets_data) do
		local header = mod_widgets[1]
		local category_name = (header and (header.readable_mod_name or header.mod_name)) or ""

		for _, widget in ipairs(mod_widgets) do
			if widget.tab and widget.tab_overrides then
				mod.tab_overrides_lookup[category_name .. "|" .. widget.tab] = widget.tab_overrides
			end
		end
	end

	for _, mod_widgets in ipairs(dmf.options_widgets_data) do
		local header = mod_widgets[1]
		local mod_name = header and header.mod_name
		if mod_name then
			local mod_instance = get_mod(mod_name)
			if mod_instance and mod_instance.required_icon_packages then
				local packages = mod._required_icon_packages
				for _, pkg in ipairs(mod_instance.required_icon_packages) do
					if type(pkg) == "string" then
						packages[#packages + 1] = pkg
					end
				end
			end
		end
	end

	mod._ensure_icon_packages_loaded()
end
