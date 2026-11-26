local mod = get_mod("Alfs_DMF_Extensions")

local Archetypes = require("scripts/settings/archetype/archetypes")
local ProfileUtils = require("scripts/utilities/profile_utils")

local Utils = mod._preset_utils
local Core = mod._preset_core

local function connection_is_initialized()
	local connection_manager = Managers and Managers.connection

	return connection_manager ~= nil and type(connection_manager.is_initialized) == "function" and connection_manager:is_initialized() == true
end

local Characters = mod._preset_characters or {}
mod._preset_characters = Characters

local AUTO_APPLY_DELAY = 0.25
local AUTO_APPLY_MIN_UPDATES = 3

local auto_apply_state = {
	character_id = nil,
	queued_character_id = nil,
	queued_update_count = 0,
	queued_at_t = nil,
	last_update_t = nil,
	scopes = {},
}

Characters.get_local_player = function()
	local player_manager = Managers and Managers.player

	if not player_manager then
		return nil
	end

	if type(player_manager.local_player_safe) == "function" then
		return player_manager:local_player_safe(1)
	end

	if not connection_is_initialized() or type(player_manager.local_player) ~= "function" then
		return nil
	end

	return player_manager:local_player(1)
end

Characters.get_local_player_profile = function()
	local local_player = Characters.get_local_player()

	if local_player and type(local_player.profile) == "function" then
		return local_player:profile()
	end

	return nil
end

Characters.get_current_character_id = function()
	local local_player = Characters.get_local_player()

	if local_player and type(local_player.character_id) == "function" then
		local character_id = local_player:character_id()

		if character_id then
			return character_id
		end
	end

	local player_manager = Managers and Managers.player

	if connection_is_initialized() and player_manager and type(player_manager.local_player_backend_profile) == "function" then
		local profile = player_manager:local_player_backend_profile()

		if type(profile) == "table" then
			return profile.character_id
		end
	end

	return nil
end

Characters.profile_display_name = function(profile)
	if type(profile) ~= "table" then
		return nil
	end

	return profile.name or profile.character_name or profile.character_id
end

Characters.get_archetype = function(profile)
	local archetype = type(profile) == "table" and profile.archetype or nil

	if type(archetype) == "string" then
		return type(Archetypes) == "table" and Archetypes[archetype] or nil
	end

	return type(archetype) == "table" and archetype or nil
end

Characters.archetype_display_name = function(archetype)
	if not archetype then
		return ""
	end

	local name = archetype.archetype_name or archetype.name

	if not name then
		return ""
	end

	if type(Localize) == "function" then
		return Localize(name) or tostring(name)
	end

	return tostring(name)
end

Characters.get_active_options_view = function()
	local ui = Managers and Managers.ui

	if not ui or type(ui.view_instance) ~= "function" then
		return nil
	end

	return ui:view_instance("dmf_options_view")
end

Characters.get_assigned_preset = function(scope, character_id)
	if not character_id then
		return nil, nil
	end

	for _, name in ipairs(Core.get_preset_names(scope)) do
		local preset = Core.get_scope_preset(scope, name)
		local characters = preset and preset.characters

		if type(characters) == "table" and characters[character_id] then
			return name, preset
		end
	end

	return nil, nil
end

Characters.get_auto_scopes = function()
	local scopes = { Core.make_global_scope() }

	for mod_name, presets in pairs(Core.get_preset_store()) do
		local resolved_name = Utils.resolve_mod_name(mod_name)

		if resolved_name and get_mod(resolved_name) and type(presets) == "table" then
			scopes[#scopes + 1] = Core.make_mod_scope(resolved_name)
		end
	end

	return scopes
end

Characters.display_name_for_character = function(character_id)
	if not character_id then
		return ""
	end

	for _, profile in ipairs(mod._preset_character_profiles or {}) do
		if type(profile) == "table" and profile.character_id == character_id then
			return Characters.profile_display_name(profile) or character_id
		end
	end

	local profile = Characters.get_local_player_profile()

	if type(profile) == "table" and profile.character_id == character_id then
		return Characters.profile_display_name(profile) or character_id
	end

	return character_id
end

Characters.has_auto_work = function(character_id)
	for _, scope in ipairs(Characters.get_auto_scopes()) do
		local key = Core.scope_key(scope)
		local state = auto_apply_state.scopes[key] or {}
		local name = Characters.get_assigned_preset(scope, character_id)

		if name or state.snapshot then
			return true
		end
	end

	return false
end

Characters.queue_auto_sync = function(character_id)
	if not character_id then
		return
	end

	if character_id == auto_apply_state.character_id then
		auto_apply_state.queued_character_id = nil
		auto_apply_state.queued_update_count = 0
		auto_apply_state.queued_at_t = nil
		return
	end

	if character_id == auto_apply_state.queued_character_id then
		return
	end

	auto_apply_state.queued_character_id = character_id
	auto_apply_state.queued_update_count = 0
	auto_apply_state.queued_at_t = nil

	if Characters.has_auto_work(character_id) then
		Utils.notify(
			mod:localize("preset_editor_auto_apply_start", Characters.display_name_for_character(character_id))
		)
	end
end

Characters.update_auto_sync = function(t)
	local character_id = auto_apply_state.queued_character_id

	if not character_id then
		return
	end

	auto_apply_state.queued_update_count = auto_apply_state.queued_update_count + 1

	if t ~= nil and (auto_apply_state.queued_at_t == nil or t < auto_apply_state.queued_at_t) then
		auto_apply_state.queued_at_t = t
	end

	if auto_apply_state.queued_update_count < AUTO_APPLY_MIN_UPDATES then
		return
	end

	if t ~= nil and auto_apply_state.queued_at_t ~= nil then
		if t - auto_apply_state.queued_at_t < AUTO_APPLY_DELAY then
			return
		end
	elseif auto_apply_state.queued_update_count < AUTO_APPLY_MIN_UPDATES + 2 then
		return
	end

	auto_apply_state.queued_character_id = nil
	auto_apply_state.queued_update_count = 0
	auto_apply_state.queued_at_t = nil
	Characters.sync_auto_presets(character_id)
end

Characters.sync_auto_presets = function(character_id)
	if not character_id or character_id == auto_apply_state.character_id then
		return
	end

	auto_apply_state.queued_character_id = nil
	auto_apply_state.queued_update_count = 0
	auto_apply_state.queued_at_t = nil
	Core.set_silent(true)

	for _, scope in ipairs(Characters.get_auto_scopes()) do
		local key = Core.scope_key(scope)
		local state = auto_apply_state.scopes[key] or {}
		local name, preset = Characters.get_assigned_preset(scope, character_id)
		local preset_settings = Core.get_preset_settings(scope, preset)

		if name and preset_settings then
			if not state.snapshot then
				state.snapshot = Core.scope_capture_settings(scope)
			end

			Core.apply_scope_settings(scope, preset_settings, nil, nil, false, true)
			state.applied_name = name
		elseif state.snapshot then
			Core.apply_scope_settings(scope, state.snapshot, nil, nil, false, true)
			state.snapshot = nil
			state.applied_name = nil
		else
			state.applied_name = nil
		end

		auto_apply_state.scopes[key] = state
	end

	auto_apply_state.character_id = character_id
	Core.flush_settings()
	Core.set_silent(false)

	local view = Characters.get_active_options_view()

	if view then
		Core.refresh_options_view(view)
	end
end

mod._sync_auto_presets = function(character_id)
	Characters.sync_auto_presets(character_id)
end

mod._queue_auto_presets = function(character_id)
	Characters.queue_auto_sync(character_id)
end

mod._update_auto_presets = function(t)
	if t ~= nil and t == auto_apply_state.last_update_t then
		return
	end

	auto_apply_state.last_update_t = t
	Characters.update_auto_sync(t)
end

mod._sync_auto_presets_with_current_player = function()
	Characters.queue_auto_sync(Characters.get_current_character_id())
end

Characters.install_hooks = function()
	local classes = rawget(_G, "CLASSES") or rawget(_G, "CLASS")

	if type(classes) ~= "table" or type(mod.hook_safe) ~= "function" then
		return
	end

	local human_player = classes.HumanPlayer

	if
		type(human_player) == "table"
		and type(human_player.set_profile) == "function"
		and mod._character_hook_target ~= human_player
	then
		mod:hook_safe(human_player, "set_profile", function(self, profile)
			if self.viewport_name ~= "player1" then
				return
			end

			local character_id = profile and type(profile) == "table" and profile.character_id or nil

			if not character_id and type(self.character_id) == "function" then
				character_id = self:character_id()
			end

			Characters.queue_auto_sync(character_id)
		end)

		mod._character_hook_target = human_player
	end

	local state_main_menu = classes.StateMainMenu

	if
		type(state_main_menu) == "table"
		and type(state_main_menu._set_profiles) == "function"
		and mod._profile_cache_hook_target ~= state_main_menu
	then
		mod:hook_safe(state_main_menu, "_set_profiles", function(_, profiles)
			if type(profiles) == "table" then
				mod._preset_character_profiles = profiles
			end
		end)

		mod._profile_cache_hook_target = state_main_menu
	end
end

mod._install_character_hooks = Characters.install_hooks

local function profile_level(profile)
	local level = type(profile) == "table" and profile.current_level or nil

	return level and ("Lv " .. tostring(level)) or ""
end

local function profile_title(profile)
	if type(ProfileUtils) ~= "table" or type(ProfileUtils.character_title_no_color) ~= "function" then
		return ""
	end

	return ProfileUtils.character_title_no_color(profile) or ""
end

Characters.build_profile_list = function(profiles_list)
	local result = {}
	local seen = {}
	local current_id = Characters.get_current_character_id()

	if type(profiles_list) == "table" then
		for _, profile in ipairs(profiles_list) do
			local id = type(profile) == "table" and profile.character_id or nil

			if id and not seen[id] then
				local archetype = Characters.get_archetype(profile)

				seen[id] = true
				result[#result + 1] = {
					id = id,
					name = Characters.profile_display_name(profile) or id,
					archetype_name = Characters.archetype_display_name(archetype),
					profile = profile,
					level = profile_level(profile),
					title = profile_title(profile),
				}
			end
		end
	end

	if current_id and not seen[current_id] then
		local profile = Characters.get_local_player_profile()
		local archetype = Characters.get_archetype(profile)

		result[#result + 1] = {
			id = current_id,
			name = Characters.profile_display_name(profile) or current_id,
			archetype_name = Characters.archetype_display_name(archetype),
			profile = profile,
			level = profile_level(profile),
			title = profile_title(profile),
		}
	end

	table.sort(result, function(left, right)
		return tostring(left.name) < tostring(right.name)
	end)

	return result
end

Characters.get_profiles = function(callback)
	if type(callback) ~= "function" then
		return
	end

	local profiles = mod._preset_character_profiles
	local called = false

	local function finish(result)
		if called then
			return
		end

		called = true
		callback(result or {})
	end

	if type(profiles) == "table" then
		finish(Characters.build_profile_list(profiles))
		return
	end

	local data_service = Managers and Managers.data_service
	local profiles_service = data_service and data_service.profiles

	if profiles_service and type(profiles_service.fetch_all_profiles) == "function" then
		local promise = profiles_service:fetch_all_profiles()

		if promise and type(promise.next) == "function" then
			promise:next(function(data)
				mod._preset_character_profiles = type(data) == "table" and data.profiles or {}
				finish(Characters.build_profile_list(mod._preset_character_profiles))
			end)

			return
		end
	end

	finish(Characters.build_profile_list({}))
end

mod._preset_panel_get_characters = function(callback)
	Characters.get_profiles(callback)
end

mod._preset_panel_is_character_assigned = function(scope, name, character_id)
	local preset = Core.get_scope_preset(scope, name)
	local characters = preset and preset.characters

	return type(characters) == "table" and characters[character_id] == true
end

mod._preset_panel_toggle_character = function(scope, name, character_id, character_name)
	if not character_id then
		return
	end

	local presets = Core.get_scope_presets(scope)
	local preset = presets[name]

	if type(preset) ~= "table" then
		return
	end

	preset.characters = type(preset.characters) == "table" and preset.characters or {}
	preset.character_names = type(preset.character_names) == "table" and preset.character_names or {}

	local assigned

	if preset.characters[character_id] then
		preset.characters[character_id] = nil
		preset.character_names[character_id] = nil
		assigned = false
	else
		preset.characters[character_id] = true
		preset.character_names[character_id] = character_name or character_id
		assigned = true
	end

	Core.save_scope_presets(scope, presets)

	return assigned
end
