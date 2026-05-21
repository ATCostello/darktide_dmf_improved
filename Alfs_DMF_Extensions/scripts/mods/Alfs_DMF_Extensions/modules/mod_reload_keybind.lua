local mod = get_mod("Alfs_DMF_Extensions")

mod.reload_all_mods = function()
	if Managers and Managers.mod then
		Managers.mod._reload_requested = true
	end
end

if CLASS and CLASS.ModManager then
	mod:hook(CLASS.ModManager, "_check_reload", function(func, self)
		return false
	end)
end
