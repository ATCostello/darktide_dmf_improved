local mod = get_mod("Alfs_DMF_Extensions")

mod._required_icon_packages = mod._required_icon_packages or {}
local _loaded_package_ids = {}
mod._icon_packages_ready = false
mod._icon_package_load_version = 0

function mod._ensure_icon_packages_loaded()
	local packages = mod._required_icon_packages

	if not packages or not next(packages) then
		mod._icon_packages_ready = true
		return
	end

	local package_manager = Managers.package
	if not package_manager then
		return
	end

	for pkg, _ in pairs(packages) do
		--if not package_manager:has_loaded(pkg) and not package_manager:is_loading(pkg) then
		local id = package_manager:load(pkg, "Alfs_DMF_Extensions", nil, true)
		if id then
			_loaded_package_ids[pkg] = id
			mod:echo("Loaded icon package: " .. pkg)
		end
		--end
	end

	mod._check_icon_packages_ready()
end

mod._check_icon_packages_ready = function()
	local packages = mod._required_icon_packages
	if not packages or not next(packages) then
		mod._icon_packages_ready = true
		return true
	end

	local package_manager = Managers.package
	if not package_manager then
		return false
	end

	for pkg, _ in pairs(packages) do
		if not package_manager:has_loaded(pkg) then
			mod._icon_packages_ready = false
			return false
		end
	end

	if not mod._icon_packages_ready then
		mod._icon_package_load_version = mod._icon_package_load_version + 1
	end

	mod._icon_packages_ready = true
	return true
end

function mod._release_icon_packages()
	local package_manager = Managers.package
	if not package_manager then
		return
	end

	for pkg, id in pairs(_loaded_package_ids) do
		if package_manager:has_loaded_id(id) then
			package_manager:release(id)
			mod:echo("Released icon package: " .. pkg)
		end
	end
	_loaded_package_ids = {}
	mod._icon_packages_ready = false
end

mod._are_icons_ready = function()
	return mod._icon_packages_ready
end

mod._get_icon_package_version = function()
	return mod._icon_package_load_version
end
