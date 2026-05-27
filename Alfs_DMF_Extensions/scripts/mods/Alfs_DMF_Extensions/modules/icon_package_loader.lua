local mod = get_mod("Alfs_DMF_Extensions")

mod._required_icon_packages = mod._required_icon_packages or {}

mod._required_icon_packages = {
	-- Core menu and profile surfaces, broad UI atlas coverage
	"packages/ui/views/main_menu_view/main_menu_view",
	"packages/ui/views/main_menu_background_view/main_menu_background_view",
	"packages/ui/views/character_appearance_view/character_appearance_view",
	"packages/ui/views/class_selection_view/class_selection_view",
	"packages/ui/views/options_view/options_view",
	"packages/ui/views/news_view/news_view",
	"packages/ui/views/system_view/system_view",
	"packages/ui/views/loading_view/loading_screen_background",
	"packages/ui/views/loading_view/loading_view",
	"packages/ui/views/player_character_options_view/player_character_options_view",
	"packages/ui/views/social_menu_view/social_menu_view",
	"packages/ui/views/social_menu_roster_view/social_menu_roster_view",
	"packages/ui/views/group_finder_view/group_finder_view",
	"packages/ui/views/lobby_view/lobby_view",
	"packages/ui/views/report_player_view/report_player_view",
	"packages/ui/views/video_view/video_view",
	"packages/ui/views/splash_view/splash_view",
	"packages/ui/ui_signin_assets",

	-- Inventory, weapon, and generic item icon sources
	"packages/ui/views/inventory_view/inventory_view",
	"packages/ui/views/inventory_background_view/inventory_background_view",
	"packages/ui/views/inventory_weapons_view/inventory_weapons_view",
	"packages/ui/views/inventory_weapon_details_view/inventory_weapon_details_view",
	"packages/ui/views/inventory_weapon_marks_view/inventory_weapon_marks_view",
	"packages/ui/views/inventory_weapon_cosmetics_view/inventory_weapon_cosmetics_view",
	"packages/ui/views/inventory_cosmetics_view/inventory_cosmetics_view",
	"packages/ui/views/cosmetics_inspect_view/cosmetics_inspect_view",
	"packages/ui/views/store_item_detail_view/store_item_detail_view",
	"packages/ui/hud/player_weapon/player_weapon",
	"packages/ui/hud/wield_info/wield_info",
	"packages/ui/hud/weapon_counter/weapon_counter",

	-- Mastery, talent, crafting, and generic item-type placeholders
	"packages/ui/views/masteries_overview_view/masteries_overview_view",
	"packages/ui/views/mastery_view/mastery_view",
	"packages/ui/views/talent_builder_view/talent_builder_view",
	"packages/ui/views/crafting_view/crafting_view",
	"packages/ui/views/crafting_mechanicus_upgrade_expertise_view/crafting_mechanicus_upgrade_expertise_view",
	"packages/ui/views/crafting_mechanicus_replace_trait_view/crafting_mechanicus_replace_trait_view",
	"packages/ui/views/crafting_mechanicus_replace_perk_view/crafting_mechanicus_replace_perk_view",
	"packages/ui/views/crafting_mechanicus_upgrade_item_view/crafting_mechanicus_upgrade_item_view",
	"packages/ui/views/crafting_mechanicus_barter_items_view/crafting_mechanicus_barter_items_view",
	"packages/ui/views/crafting_mechanicus_modify_view/crafting_mechanicus_modify_view",

	-- Vendors, store, currencies, cosmetics, and appearance-related icons
	"packages/ui/views/credits_goods_vendor_view/credits_goods_vendor_view",
	"packages/ui/views/credits_vendor_view/credits_vendor_view",
	"packages/ui/views/credits_vendor_background_view/credits_vendor_background_view",
	"packages/ui/views/marks_goods_vendor_view/marks_goods_vendor_view",
	"packages/ui/views/marks_vendor_view/marks_vendor_view",
	"packages/ui/views/store_view/store_view",
	"packages/ui/views/cosmetics_vendor_view/cosmetics_vendor_view",
	"packages/ui/views/cosmetics_vendor_background_view/cosmetics_vendor_background_view",
	"packages/ui/views/barber_vendor_background_view/barber_vendor_background_view",
	"packages/ui/views/broker_stimm_builder_view/broker_stimm_builder_view",
	"packages/ui/views/live_events_view/live_events_view",
	"packages/ui/views/penance_overview_view/penance_overview_view",
	"packages/ui/material_sets/circumstances",

	-- Mission, contracts, havoc, and player-journey icon families
	"packages/ui/views/mission_intro_view/mission_intro_view",
	"packages/ui/views/mission_board_view/mission_board_view",
	"packages/ui/views/mission_voting_view/mission_voting_view",
	"packages/ui/views/contracts_view/contracts_view",
	"packages/ui/views/contracts_background_view/contracts_background_view",
	"packages/ui/views/scanner_display_view/scanner_display_view",
	"packages/ui/views/havoc_reward_presentation_view/havoc_reward_presentation_view",
	"packages/ui/views/havoc_play_view/havoc_play_view",
	"packages/ui/views/havoc_background_view/havoc_background_view",
	"packages/ui/views/expedition_play_view/expedition_play_view",
	"packages/ui/views/expedition_background_view/expedition_background_view",
	"packages/ui/views/expedition_view/expedition_view",
	"packages/ui/views/horde_play_view/horde_play_view",
	"packages/ui/views/training_grounds_options_view/training_grounds_options_view",
	"packages/ui/views/training_grounds_view/training_grounds_view",
	"packages/ui/views/end_player_view/end_player_view",

	-- HUD packages that commonly carry ability, buff, frame, and flat icon materials
	"packages/ui/hud/team_player_panel/team_player_panel",
	"packages/ui/hud/crosshair/crosshair",
	"packages/ui/hud/tactical_overlay/tactical_overlay",
	"packages/ui/hud/mission_objective_feed/mission_objective_feed",
	"packages/ui/hud/mission_objective_popup/mission_objective_popup",
	"packages/ui/hud/objective_progress_bar/objective_progress_bar",
	"packages/ui/hud/onboarding_popup/onboarding_popup",
	"packages/ui/hud/area_notification_popup/area_notification_popup",
	"packages/ui/hud/mission_speaker_popup/mission_speaker_popup",
	"packages/ui/hud/world_markers/world_markers",
	"packages/ui/hud/interaction/interaction",
	"packages/ui/hud/emote_wheel/emote_wheel",
	"packages/ui/hud/boss_health/boss_health",
	"packages/ui/hud/player_ability/player_ability",
	"packages/ui/hud/damage_indicator/damage_indicator",
	"packages/ui/hud/blocking/blocking",
	"packages/ui/hud/dodge_counter/dodge_counter",
	"packages/ui/hud/overcharge/overcharge",
	"packages/ui/hud/smart_tagging/smart_tagging",
	"packages/ui/hud/prologue_tutorial_step_tracker/prologue_tutorial_step_tracker",
	"packages/ui/hud/prologue_tutorial_info_box/prologue_tutorial_info_box",
	"packages/ui/hud/player_buffs/player_buffs",

	-- Inventory and itemization levels, often pull extra material dependencies
	"content/levels/ui/inventory/inventory",
	"content/levels/ui/inventory_weapon_view/inventory_weapon_view",
	"content/levels/ui/crafting_view_itemization/crafting_view_itemization",
	"content/levels/ui/crafting_view_sacrifice/world",
	"content/levels/ui/store/store",
	"content/levels/ui/credits_vendor/credits_vendor",
	"content/levels/ui/vendor_cosmetics_preview_gear/vendor_cosmetics_preview_gear",
	"content/levels/ui/vendor_cosmetics_preview_weapon/vendor_cosmetics_preview_weapon",
	"content/levels/ui/credits_cosmetics_vendor/credits_cosmetics_vendor",

	-- Mission and event levels, useful for mission-type and event currency icons
	"content/levels/ui/mission_intro/mission_intro",
	"content/levels/ui/mission_board_player_journey/mission_board_player_journey",
	"content/levels/ui/contracts_view/contracts_view",
	"content/levels/ui/havoc/havoc",
	"content/levels/ui/penances/world",
	"content/levels/ui/training_grounds/training_grounds",

	-- Barber and appearance levels, useful for hair/appearance icon families
	"content/levels/ui/barber/barber",
	"content/levels/ui/barber_character_appearance/barber_character_appearance",
	"content/levels/ui/barber_character_mindwipe/barber_character_mindwipe",
	"content/levels/ui/character_create/character_create",
	"content/levels/ui/cartel_selection/cartel_selection",

	-- Expedition player-journey level, used by mission_types_pj icon families
	"content/levels/ui/expedition/world",
}

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

local loaded_packages = {}

local function _load_package_list(package_list)
	local managers = Managers
	local package_manager = managers and managers.package

	if not package_manager then
		return
	end

	for _, pkg in ipairs(package_list) do
		if _package_is_available(pkg) and not mod._required_icon_packages[pkg] then
			if _package_is_loaded(pkg) then
				mod._required_icon_packages[pkg] = true
			else
				local ok = pcall(function()
					package_manager:load(pkg, PACKAGE_REF, nil, true)
				end)

				if ok then
					mod._required_icon_packages[pkg] = true
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

	dbg_1 = mod._required_icon_packages
	_load_package_list(mod._required_icon_packages)

	return _all_packages_loaded(mod._required_icon_packages)
end
