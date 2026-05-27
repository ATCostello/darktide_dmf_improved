local mod = get_mod("Alfs_DMF_Extensions")

mod._required_icon_packages = mod._required_icon_packages or {}
local _loaded_package_ids = {}
PACKAGE_REF = "AlfsDMFExtensions"

local function _package_is_available(package_name)
	local application = Application

	if not application or not application.can_get_resource then
		return false
	end

	local ok, exists = pcall(function()
		return application.can_get_resource("package", package_name)
	end)

	return ok and exists or false
end

local function _package_is_loaded(package_name)
	local managers = Managers
	local package_manager = managers and managers.package

	if not package_manager or not package_manager.has_loaded then
		return false
	end

	local ok, is_loaded = pcall(package_manager.has_loaded, package_manager, package_name)

	return ok and is_loaded or false
end

local function _load_package_list(package_list)
	local managers = Managers
	local package_manager = managers and managers.package

	if not package_manager then
		return
	end

	for _, pkg in ipairs(package_list) do
		if _package_is_available(pkg) and not _requested_icon_packages[pkg] then
			if _package_is_loaded(pkg) then
				_requested_icon_packages[pkg] = true
			else
				local ok = pcall(function()
					package_manager:load(pkg, PACKAGE_REF, nil, true)
				end)

				if ok then
					_requested_icon_packages[pkg] = true
				end
			end
		end
	end
end

local function _all_packages_loaded(package_list)
	for _, pkg in ipairs(package_list) do
		if _package_is_available(pkg) and not _package_is_loaded(pkg) then
			return false
		end
	end

	return true
end

mod._ensure_icon_packages_loaded = function()
	local managers = Managers
	local package_manager = managers and managers.package

	if not package_manager then
		return false
	end

	_load_package_list(mod._required_icon_packages)

	return _all_packages_loaded(mod._required_icon_packages)
end
