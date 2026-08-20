local mod = get_mod("Alfs_DMF_Extensions")
mod.version = "2.0.2"
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

	result = "{#color(" .. colours.title .. ")} " .. result .. "{#reset()}"
	return result
end

--local name = mod.gradientText("Alf's DMF Extensions", { 255, 255, 0 }, { 255, 0, 255 }, true)
--Clipboard.put(name)
--mod:echo(name)

local mod_name = {
	en = "Alf's DMF Extensions",
	ru = "Расширения DMF от Альфа",
}

mod.localisation = {
	mod_name = {
		en = mod_name["en"],
		ru = mod_name["ru"],
	},
	mod_name_pizazz = {
		en = mod.gradientText(mod_name["en"], { 255, 255, 0 }, { 255, 0, 255 }, true),
		ru = mod.gradientText(mod_name["ru"], { 255, 255, 0 }, { 255, 0, 255 }, true),
	},
	mod_name_boring = {
		en = mod_name["en"],
		ru = mod_name["ru"],
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
		ru = "{#color("
			.. colours.text
			.. ")}"
			.. "Расширения для меню настроек Darktide Mod Framework, которые будут полезны пользователям и создателям модов. Все реализовано как опциональные, встроенные расширения — не обязательные изменения."
			.. "{#reset()}\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Автор: "
			.. "{#color("
			.. colours.text
			.. ")}Alfthebigheaded\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}Версия: {#color("
			.. colours.text
			.. ")}"
			.. mod.version
			.. "{#reset()}",
	},
	general_settings = {
		en = "{#color(" .. colours.title .. ")}General Settings{#reset()}",
		ru = "{#color(" .. colours.title .. ")}Основные настройки{#reset()}",
	},
	mod_name_pizazz_toggle = {
		en = "Name Pizazz",
		ru = "Красочное название",
	},
	mod_name_pizazz_tooltip = {
		en = "Toggles the rainbow colours effect on the mod name text. Requires a reload.\nIf enabled, you will get a small euphoric experience everytime you scroll through the mod menu, \nIf disabled - you will be a John Darktide and have no rainbow sprinkles (but I'll love you anyway).",
		ru = "Включает радужную расцветку текста названия мода. Требуется перезагрузка.\nЕсли включено, вы получите небольшой эйфорический опыт каждый раз, когда листаете меню модов.\nЕсли выключено — вы будете Джоном Дарктайдом без радужной посыпки (но я всё равно буду вас любить).",
	},
	enable_scroll_position_saving = {
		en = "Scroll Position Saving",
		ru = "Сохранение позиции прокрутки",
	},
	enable_scroll_position_saving_tooltip = {
		en = "Toggles saving of scroll position within the mod settings menu, so you can return to the last position you were at when you reopen the menu.",
		ru = "Включает сохранение позиции прокрутки внутри меню настроек модов, чтобы при повторном открытии меню вы возвращались к последнему месту.",
	},
	enable_mod_tabs = {
		en = "Mod Tabs",
		ru = "Вкладки модов",
	},
	enable_mod_tabs_tooltip = {
		en = "Toggles mod tabs being created at all, which let mod authors add custom tabs to the mod settings menu for easier navigation and grouping. If this setting is disabled, no mod tabs will be shown at all.",
		ru = "Включает создание вкладок модов. Они позволяют авторам добавлять собственные вкладки в меню настроек для удобной навигации и группировки. Если эта настройка отключена, вкладки модов вообще не будут отображаться.",
	},
	enable_generalised_mod_tabs = {
		en = "Generalised Mod Tabs",
		ru = "Обобщённые вкладки модов",
	},
	enable_generalised_mod_tabs_tooltip = {
		en = "Toggles generalised mod tab creation for mods that do not explicitly have tab support. \n\n{#color("
			.. colours.subtitle
			.. ")}These are automatically created using the mod's existing settings structure, and may be innacurate.{#reset()} \n\nIf this setting is disabled, only mods that have specifically added tab support for 'Alf's DMF Extensions' will have tabs.",
		ru = "Включает создание обобщённых вкладок для модов, у которых нет явной поддержки вкладок.\n\n{#color("
			.. colours.subtitle
			.. ")}Они автоматически создаются на основе существующей структуры настроек мода и могут быть неточными.{#reset()}\n\nЕсли эта настройка отключена, вкладки будут только у модов, которые специально добавили поддержку вкладок для 'Alf's DMF Extensions'.",
	},
	enable_RGB_widget = {
		en = "Color Widget Replacement",
	},
	enable_RGB_widget_tooltip = {
		en = "Controls how color settings are displayed.\n\n{#color(169,191,153)}ARGB Sliders{#reset()} - Replaces individual R/G/B/A sliders with a combined RGB widget.\n{#color(169,191,153)}Color Widget{#reset()} - Replaces DMF's native color picker with the extension's RGB slider widget.\n{#color(169,191,153)}Disabled{#reset()} - No color widget replacement.",
	},
	rgb_replacement_argb_sliders = {
		en = "ARGB Sliders",
	},
	rgb_replacement_color_widget = {
		en = "Color Widget",
	},
	rgb_replacement_disabled = {
		en = "Disabled",
	},
	reload_mods_keybind = {
		en = "Reload Mods Keybind",
		ru = "Клавиша перезагрузки модов",
	},
	reload_mods_keybind_tooltip = {
		en = "Keybind to trigger a full mod reload (Ctrl+Shift+R in developer mode by default).",
		ru = "Клавиша для полной перезагрузки модов (по умолчанию Ctrl+Shift+R в режиме разработчика).",
	},
	icon_dropdown_test = {
		en = "Icon Dropdown Test",
		ru = "Тест выпадающего списка с иконками",
	},
	icon_dropdown_test_tooltip = {
		en = "A test dropdown with icon support. Options with an 'icon' field defined show an icon to the left of the text.",
		ru = "Тестовый выпадающий список с поддержкой иконок. Опции, у которых определено поле 'icon', показывают иконку слева от текста.",
	},
	enable_dropdown_icons = {
		en = "Dropdown Icons",
		ru = "Иконки в выпадающих списках",
	},
	enable_dropdown_icons_tooltip = {
		en = "Toggles icon support for DMF settings dropdowns. These need to be implemented by the mod author.",
		ru = "Включает поддержку иконок в выпадающих списках настроек DMF. Их должны реализовать авторы модов.",
	},
	enable_font_support = {
		en = "Display Font Type",
		ru = "Тип отображаемого шрифта",
	},
	enable_font_support_tooltip = {
		en = "Toggles displaying the font type for DMF settings. These need to be implemented by the mod author and can be included with the {#font} tag.",
		ru = "Включает отображение типа шрифта для настроек DMF. Их должны реализовать авторы модов, используя тег {#font}.",
	},
	enable_scrollable_dropdown = {
		en = "Mouse-Scrollable Dropdowns",
		ru = "Прокручиваемые выпадающие списки",
	},
	enable_scrollable_dropdown_tooltip = {
		en = "Toggles allowing the use of your mouse to scroll through the dropdown menus in DMF.",
		ru = "Включает возможность прокручивать выпадающие меню в DMF с помощью мыши.",
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
		ru = "Прочее",
	},
	enable_reload_mods_rebind = {
		en = "Rebind DMF Reload?",
		ru = "Переназначить перезагрузку DMF?",
	},
	enable_reload_mods_rebind_tooltip = {
		en = "Toggle rebinding the default DMF Reload keybind (Ctrl+Shift+R in developer mode by default).",
		ru = "Включает переназначение стандартной клавиши перезагрузки DMF (по умолчанию Ctrl+Shift+R в режиме разработчика).",
	},
	gen_tabs_toggle_on = {
		en = "{#color(180,255,180)}Tabs Enabled{#reset()}",
		ru = "{#color(180,255,180)}Вкладки включены{#reset()}",
	},
	gen_tabs_toggle_off = {
		en = "{#color(255,180,180)}Tabs Disabled{#reset()}",
		ru = "{#color(255,180,180)}Вкладки отключены{#reset()}",
	},
	gen_tabs_toggle_tooltip = {
		en = "Toggle generalized tabs for this mod. When OFF, all settings are shown without tab filtering.",
		ru = "Включение обобщённых вкладок для этого мода. При выключении все настройки показываются без фильтрации по вкладкам.",
	},
	enable_tab_reset = {
		en = "Per-Tab Reset to Defaults",
		ru = "Сброс настроек по вкладкам",
	},
	enable_tab_reset_tooltip = {
		en = "Adds a hotkey entry to reset only the currently selected tab's settings to their defaults, rather than resetting all settings in the mod.",
		ru = "Добавляет пункт в горячие клавиши для сброса настроек только текущей выбранной вкладки, а не всех настроек мода.",
	},
	reset_tab_to_default = {
		en = "Reset tab to default settings",
		ru = "Сбросить вкладку к настройкам по умолчанию",
	},
	reset_tab_to_default_description = {
		en = "This will reset the currently selected tab to their mod defaults",
		ru = "Это сбросит текущую выбранную вкладку к настройкам мода по умолчанию",
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
