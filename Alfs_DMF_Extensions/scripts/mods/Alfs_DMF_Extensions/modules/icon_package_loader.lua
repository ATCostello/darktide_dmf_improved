local mod = get_mod("Alfs_DMF_Extensions")

mod._required_icon_packages = mod._required_icon_packages or {}
local _loaded_package_ids = {}

function mod._ensure_icon_packages_loaded()
	local packages = mod._required_icon_packages
	if not packages or not next(packages) then
		return
	end

	local package_manager = Managers.package
	if not package_manager then
		return
	end

	for pkg, _ in pairs(packages) do
		if not package_manager:has_loaded(pkg) and not package_manager:is_loading(pkg) then
			local id = package_manager:load(pkg, "Alfs_DMF_Extensions_icons", nil, false, true)
			if id then
				_loaded_package_ids[pkg] = id
			end
		end
	end
end

function mod._release_icon_packages()
	local package_manager = Managers.package
	if not package_manager then
		return
	end

	for pkg, id in pairs(_loaded_package_ids) do
		if package_manager:has_loaded_id(id) then
			package_manager:release(id)
		end
	end
	_loaded_package_ids = {}
end
