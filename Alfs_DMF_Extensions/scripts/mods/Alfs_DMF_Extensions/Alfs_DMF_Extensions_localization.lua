local mod = get_mod("Alfs_DMF_Extensions")
mod.version = "1.2.0"
mod:info("Alfs DMF Extensions is installed, using version: " .. tostring(mod.version))

local next = next

local colours = {
	title = "200,140,20",
	subtitle = "226,199,126",
	text = "169,191,153",
}

local function lerp(a, b, t)
	return a + (b - a) * t
end

mod.gradientText = function(text, startColor, endColor, colorSpaces)
	local result = ""
	local length = #text
	local visibleIndex = 0

	-- Count visible characters
	for i = 1, length do
		local char = text:sub(i, i)
		if colorSpaces or char ~= " " then
			visibleIndex = visibleIndex + 1
		end
	end

	local currentIndex = 0

	for i = 1, length do
		local char = text:sub(i, i)

		if not colorSpaces and char == " " then
			result = result .. char
		else
			currentIndex = currentIndex + 1
			local t = (visibleIndex <= 1) and 0 or (currentIndex - 1) / (visibleIndex - 1)

			local r = math.floor(lerp(startColor[1], endColor[1], t))
			local g = math.floor(lerp(startColor[2], endColor[2], t))
			local b = math.floor(lerp(startColor[3], endColor[3], t))

			result = result .. string.format("{#color(%d,%d,%d)}%s", r, g, b, char)
		end
	end

	result = result .. "{#reset()}"
	return result
end

--local name = mod.gradientText("Alf's DMF Extensions", { 255, 255, 0 }, { 255, 0, 255 }, true)
--Clipboard.put(name)
--mod:echo(name)

mod.localisation = {
	mod_name = {
		en = "Alf's DMF Extensions",
	},
	mod_name_pizazz = {
		en = "{#color("
			.. colours.title
			.. ")} {#color(255,255,0)}A{#color(255,241,13)}l{#color(255,228,26)}f{#color(255,214,40)}'{#color(255,201,53)}s{#color(255,187,67)} {#color(255,174,80)}D{#color(255,161,93)}M{#color(255,147,107)}F{#color(255,134,120)} {#color(255,120,134)}E{#color(255,107,147)}x{#color(255,93,161)}t{#color(255,80,174)}e{#color(255,67,187)}n{#color(255,53,201)}s{#color(255,40,214)}i{#color(255,26,228)}o{#color(255,13,241)}n{#color(255,0,255)}s{#reset()}",
	},
	mod_name_boring = {
		en = "Alf's DMF Extensions",
	},
	mod_description = {
		en = "{#color("
			.. colours.text
			.. ")}"
			.. "Extensions to the Darktide Mod Framework settings menu, that will benefit users and mod creators in various ways. All designed to be optional, integrated extensions - not mandatory changes."
			.. "{#reset()}\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Author: "
			.. "{#color("
			.. colours.text
			.. ")}Alfthebigheaded\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Version: {#color("
			.. colours.text
			.. ")}"
			.. mod.version
			.. "{#reset()}",
	},
	general_settings = {
		en = "{#color(" .. colours.title .. ")}General Settings{#reset()}",
	},
	mod_name_pizazz_toggle = {
		en = "Name Pizazz",
	},
	mod_name_pizazz_tooltip = {
		en = "Toggles the rainbow colours effect on the mod name text. Requires a reload.\nIf enabled, you will get a small euphoric experience everytime you scroll through the mod menu, \nIf disabled - you will be a John Darktide and have no rainbow sprinkles (but I'll love you anyway).",
	},
	enable_scroll_position_saving = {
		en = "Scroll Position Saving",
	},
	enable_scroll_position_saving_tooltip = {
		en = "Toggles saving of scroll position within the mod settings menu, so you can return to the last position you were at when you reopen the menu.",
	},
	enable_mod_tabs = {
		en = "Mod Tabs",
	},
	enable_mod_tabs_tooltip = {
		en = "Toggles mod tabs being created at all, which let mod authors add custom tabs to the mod settings menu for easier navigation and grouping. If this setting is disabled, no mod tabs will be shown at all.",
	},
	enable_generalised_mod_tabs = {
		en = "Generalised Mod Tabs",
	},
	enable_generalised_mod_tabs_tooltip = {
		en = "Toggles generalised mod tab creation for mods that do not explicitly have tab support. \n\n{#color("
			.. colours.subtitle
			.. ")}These are automatically created using the mod's existing settings structure, and may be innacurate.{#reset()} \n\nIf this setting is disabled, only mods that have specifically added tab support for 'Alf's DMF Extensions' will have tabs.",
	},
	enable_RGB_widget = {
		en = "Custom RGB Widget",
	},
	enable_RGB_widget_tooltip = {
		en = "Toggles a customised RGB widget which will replace default RGB sliders for mods that have support/have made their RGB sliders compatible.",
	},
	reload_mods_keybind = {
		en = "Reload Mods Keybind",
	},
	reload_mods_keybind_tooltip = {
		en = "Keybind to trigger a full mod reload (Ctrl+Shift+R in developer mode by default).",
	},
	icon_dropdown_test = {
		en = "Icon Dropdown Test",
	},
	icon_dropdown_test_tooltip = {
		en = "A test dropdown with icon support. Options with an 'icon' field defined show an icon to the left of the text.",
	},
	enable_dropdown_icons = {
		en = "Dropdown Icons",
	},
	enable_dropdown_icons_tooltip = {
		en = "Toggles icon support for DMF settings dropdowns. These need to be implemented by the mod author.",
	},
	enable_font_support = {
		en = "Display Font Type",
	},
	enable_font_support_tooltip = {
		en = "Toggles displaying the font type for DMF settings. These need to be implemented by the mod author and can be included with the {#font} tag.",
	},
	enable_scrollable_dropdown = {
		en = "Mouse-Scrollable Dropdowns",
	},
	enable_scrollable_dropdown_tooltip = {
		en = "Toggles allowing the use of your mouse to scroll through the dropdown menus in DMF.",
	},
	tab_arrow_left = {
		en = "<",
	},
	tab_arrow_right = {
		en = ">",
	},
	tab_title_truncated = {
		en = "..",
	},
	default_tab = {
		en = "Other",
	},
	enable_reload_mods_rebind = {
		en = "Rebind DMF Reload?",
	},
	enable_reload_mods_rebind_tooltip = {
		en = "Toggle rebinding the default DMF Reload keybind (Ctrl+Shift+R in developer mode by default).",
	},
	gen_tabs_toggle_on = {
		en = "{#color(180,255,180)}Tabs Enabled{#reset()}",
	},
	gen_tabs_toggle_off = {
		en = "{#color(255,180,180)}Tabs Disabled{#reset()}",
	},
	gen_tabs_toggle_tooltip = {
		en = "Toggle generalized tabs for this mod. When OFF, all settings are shown without tab filtering.",
	},
	enable_tab_reset = {
		en = "Per-Tab Reset to Defaults",
	},
	enable_tab_reset_tooltip = {
		en = "Adds a hotkey entry to reset only the currently selected tab's settings to their defaults, rather than resetting all settings in the mod.",
	},
	reset_tab_to_default = {
		en = "Reset tab to default settings",
	},
	reset_tab_to_default_description = {
		en = "This will reset the currently selected tab to their mod defaults",
	},
}

-- Group localisations so they can be managed easier.
local localisations_to_add = {}

-- debuff names and groups localisations
table.insert(localisations_to_add, {})

-- add localisations to main map
for i = 1, #localisations_to_add do
	if localisations_to_add[i] then
		for key, value in next, localisations_to_add[i] do
			if key and value then
				mod.localisation[key] = value
			end
		end
	end
end

local apply_color_to_text = function(text, r, g, b)
	return "{#color(" .. r .. "," .. g .. "," .. b .. ")}" .. text .. "{#reset()}"
end

local apply_colours = function()
	for key, values in next, mod.localisation do
		-- apply rgb colours
		if
			string.find(key, "colour")
			and not string.find(key, "colour_R")
			and not string.find(key, "colour_G")
			and not string.find(key, "colour_B")
		then
			local r = mod:get(key .. "_R")
			local g = mod:get(key .. "_G")
			local b = mod:get(key .. "_B")

			if r ~= nil and g ~= nil and b ~= nil then
				for language, text in next, values do
					local clean = string.gsub(text, "{#.-}", "")
					clean = string.gsub(clean, "{#reset%(%)%}", "")
					text = apply_color_to_text(clean, r, g, b)

					mod.localisation[key][language] = text
				end
			end
		end

		-- apply border colours
		if key == "Gold" or key == "Silver" or key == "Steel" or key == "Tarnished" then
			for language, text in next, values do
				local argb = mod.lookup_border_color(key)

				if argb ~= nil then
					local temp = apply_color_to_text(key, argb[2], argb[3], argb[4])

					if mod.localisation[temp] == nil then
						mod.localisation[temp] = {}
						mod.localisation[temp][language] = temp
					else
						mod.localisation[temp][language] = temp
					end
				end
			end
		end

		-- adjust tooltip text opacity
		if string.find(key, "_tooltip") then
			for language, text in next, values do
				local rgb = { 144, 155, 136 }

				if rgb ~= nil then
					local text = apply_color_to_text(text, rgb[1], rgb[2], rgb[3])

					if mod.localisation[key] == nil then
						mod.localisation[key] = {}
						mod.localisation[key][language] = text
					else
						mod.localisation[key][language] = text
					end
				end
			end
		end
	end

	return mod.localisation
end

mod.toggle_pizazz = function()
	for key, values in next, mod.localisation do
		if key == "mod_name" then
			for language, text in next, values do
				if mod:get("mod_name_pizazz_toggle") then
					mod.localisation[key][language] = mod.localisation["mod_name_pizazz"][language]
				else
					mod.localisation[key][language] = mod.localisation["mod_name_boring"][language]
				end
			end
		end
	end
end

mod.toggle_pizazz()

apply_colours()

mod.apply_colours = function()
	apply_colours()
	return mod.localisation
end

return mod.localisation
