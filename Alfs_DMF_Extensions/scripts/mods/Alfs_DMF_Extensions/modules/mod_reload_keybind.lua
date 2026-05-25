local mod = get_mod("Alfs_DMF_Extensions")

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

if CLASS and CLASS.ModManager then
	mod:hook(CLASS.ModManager, "_check_reload", function(func, self)
		return false
	end)
end
