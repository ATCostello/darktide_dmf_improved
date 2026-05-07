local mod = get_mod("dmf_settings_improved")
mod.version = "1.5.08"
mod:info("DMF Settings Improved is installed, using version: " .. tostring(mod.version))

local next = next

local colours = {
	title = "200,140,20",
	subtitle = "226,199,126",
	text = "169,191,153",
}

-- base localisations
mod.localisation = {
	mod_name = {
		en = "DMF Settings Improved",
	},
	mod_name_pizazz = {
		en = "{#color("
			.. colours.title
			.. ")} {#color(255,0,0)}E{#color(248,0,14)}n{#color(240,0,29)}e{#color(233,0,43)}m{#color(225,0,57)}i{#color(218,0,71)}e{#color(210,0,86)}s {#color(203,0,100)}I{#color(195,0,114)}m{#color(188,0,129)}p{#color(180,0,143)}r{#color(173,0,157)}o{#color(165,0,171)}v{#color(158,0,186)}e{#color(150,0,200)}d{#reset()}",
	},
	mod_name_boring = {
		en = "DMF Settings Improved",
	},
	mod_description = {
		en = "{#color("
			.. colours.text
			.. ")}"
			.. "Healthbars, debuffs, outlines, markers, special attack alerts and more, to improve the enemies throughout Darktide."
			.. "{#reset()}\n\n"
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
	mod_name_pizazz_toggle = {
		en = "Enable Name Pizazz",
	},
	mod_name_pizazz_tooltip = {
		en = "Toggles the rainbow colours effect on the mod name text. Requires a reload.\nIf enabled, you will get a small euphoric experience everytime you scroll through the mod menu, \nIf disabled - you will be a John Darktide and have no rainbow sprinkles (but I'll love you anyway).",
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
