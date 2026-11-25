local mod = get_mod("Alfs_DMF_Extensions")

local STATE_SETTING = "settings_profile_importer_state"

local pending_profiles = {}
local prompt_open = false

local function get_dmf()
	return mod.dmf or get_mod("DMF")
end

local function flush_settings()
	local dmf = get_dmf()

	if dmf and type(dmf.save_unsaved_settings_to_file) == "function" then
		dmf.save_unsaved_settings_to_file()
	end
end

local function get_state()
	local state = mod:get(STATE_SETTING)

	if type(state) ~= "table" then
		state = {}
	end

	return state
end

local function save_state(state)
	mod:set(STATE_SETTING, state)
	flush_settings()
end

local function profile_key(profile_mod)
	if type(profile_mod.get_name) == "function" then
		return profile_mod:get_name()
	end

	return tostring(profile_mod)
end

local function profile_version(profile_mod)
	if type(profile_mod.get_metadata) == "function" then
		return tostring(profile_mod:get_metadata("version") or "0.0.0")
	end

	return "0.0.0"
end

local function profile_name(profile_mod)
	if type(profile_mod.get_readable_name) == "function" then
		local name = profile_mod:get_readable_name()

		if name then
			return name
		end
	end

	return profile_key(profile_mod)
end

local function parse_version(version)
	local parts = {}

	for number in tostring(version or ""):gmatch("%d+") do
		parts[#parts + 1] = tonumber(number) or 0
	end

	return parts
end

local function compare_versions(left, right)
	local left_parts = parse_version(left)
	local right_parts = parse_version(right)

	for i = 1, math.max(#left_parts, #right_parts) do
		local left_part = left_parts[i] or 0
		local right_part = right_parts[i] or 0

		if left_part > right_part then
			return 1
		elseif left_part < right_part then
			return -1
		end
	end

	return 0
end

local function mark_ignored(profile_mod)
	local state = get_state()
	local key = profile_key(profile_mod)
	local entry = type(state[key]) == "table" and state[key] or {}

	entry.ignored = true
	state[key] = entry
	save_state(state)
end

local function import_profile(profile_mod)
	local mods = mod.decode_global_profile_settings and mod.decode_global_profile_settings(profile_mod.global_profile_settings) or nil

	if not mods or not mod.apply_global_profile_settings or not mod.apply_global_profile_settings(mods) then
		mod._show_preset_message(
			nil,
			mod:localize("settings_profile_import_failed_title"),
			mod:localize("settings_profile_import_failed_description", profile_name(profile_mod))
		)
		return false
	end

	local previous_in_progress = profile_mod._profile_import_in_progress

	profile_mod._profile_import_in_progress = true
	profile_mod:set("has_been_imported", true)
	profile_mod._profile_import_in_progress = previous_in_progress

	local state = get_state()
	local key = profile_key(profile_mod)

	state[key] = {
		version = profile_version(profile_mod),
		ignored = false,
	}
	save_state(state)

	mod._show_preset_message(
		nil,
		mod:localize("settings_profile_imported_title"),
		mod:localize("settings_profile_imported_description", profile_name(profile_mod))
	)

	return true
end

local function show_next_prompt()
	if prompt_open or #pending_profiles == 0 then
		return
	end

	local event_manager = Managers and Managers.event

	if not event_manager or type(event_manager.trigger) ~= "function" then
		return
	end

	local entry = table.remove(pending_profiles, 1)
	local profile_mod = entry.profile_mod
	local description = entry.updated
		and mod:localize("settings_profile_updated_description", profile_name(profile_mod), entry.previous_version, entry.version)
		or mod:localize("settings_profile_new_description", profile_name(profile_mod), entry.version)

	prompt_open = true

	event_manager:trigger("event_show_ui_popup", {
		title_text_unlocalized = mod:localize("settings_profile_title"),
		description_text_unlocalized = description,
		type = "default",
		options = {
			{
				text = mod:localize("settings_profile_accept"),
				no_localization = true,
				close_on_pressed = true,
				callback = function()
					prompt_open = false
					import_profile(profile_mod)
					show_next_prompt()
				end,
			},
			{
				text = mod:localize("settings_profile_later"),
				no_localization = true,
				template_type = "terminal_button_small",
				close_on_pressed = true,
				callback = function()
					prompt_open = false
					show_next_prompt()
				end,
			},
			{
				text = mod:localize("settings_profile_ignore"),
				no_localization = true,
				template_type = "terminal_button_small",
				close_on_pressed = true,
				callback = function()
					prompt_open = false
					mark_ignored(profile_mod)
					show_next_prompt()
				end,
			},
		},
	}, function() end)
end

local function scan_profile_settings()
	local dmf = get_dmf()

	if not dmf or type(dmf.mods) ~= "table" then
		return
	end

	local state = get_state()

	for _, profile_mod in pairs(dmf.mods) do
		if type(profile_mod) == "table" and profile_mod ~= mod and profile_mod.global_profile_settings ~= nil then
			local key = profile_key(profile_mod)
			local stored = type(state[key]) == "table" and state[key] or {}
			local version = profile_version(profile_mod)
			local imported = profile_mod:get("has_been_imported") == true
			local updated = imported and stored.version ~= nil and compare_versions(version, stored.version) > 0

			if not stored.ignored and (not imported or updated) then
				pending_profiles[#pending_profiles + 1] = {
					profile_mod = profile_mod,
					version = version,
					previous_version = stored.version or "0.0.0",
					updated = updated,
				}
			end
		end
	end
end

mod.import_profile_settings = function(profile_mod)
	if type(profile_mod) ~= "table" then
		return false
	end

	return import_profile(profile_mod)
end

mod.set_profile_import_state = function(profile_mod, imported)
	if type(profile_mod) ~= "table" then
		return
	end

	local state = get_state()
	local key = profile_key(profile_mod)

	if imported then
		state[key] = {
			version = profile_version(profile_mod),
			ignored = false,
		}
	else
		state[key] = {
			version = nil,
			ignored = false,
		}
	end

	save_state(state)
end

mod._scan_settings_profiles = function()
	scan_profile_settings()
end

mod._try_show_pending_profile_prompts = function()
	show_next_prompt()
end

mod.on_all_mods_loaded = function()
	scan_profile_settings()
	show_next_prompt()
end
