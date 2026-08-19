local mod = get_mod("Alfs_DMF_Extensions")

-- The new DMF natively handles _check_reload with hook_origin in dmf_options.lua
-- and provides its own reload_mods keybind with request_mod_reload.
-- We keep reload_all_mods for backward compatibility with the mod's own keybind.

mod.reload_all_mods = function()
	local dmf_mod = mod.dmf or get_mod("DMF")
	if not dmf_mod then
		return
	end
	if not dmf_mod:get("developer_mode") then
		return
	end
	if Managers and Managers.mod then
		Managers.mod._reload_requested = true
	end
end
