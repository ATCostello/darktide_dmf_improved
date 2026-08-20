local mod = get_mod("Alfs_DMF_Extensions")
mod.version = "2.0.4"
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

local function utf8_chars(s)
	local chars = {}
	for char in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
		table.insert(chars, char)
	end
	return chars
end

mod.gradientText = function(text, startColor, endColor, colorSpaces)
	local result = ""
	local chars = utf8_chars(text)
	local visibleIndex = 0

	for _, char in ipairs(chars) do
		if colorSpaces or char ~= " " then
			visibleIndex = visibleIndex + 1
		end
	end

	local currentIndex = 0

	for _, char in ipairs(chars) do
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

	result = "{#color(" .. colours.title .. ")}" .. result .. "{#reset()}"
	return result
end

--local name = mod.gradientText("Alf's DMF Extensions", { 255, 255, 0 }, { 255, 0, 255 }, true)
--Clipboard.put(name)
--mod:echo(name)

local mod_name = {
	en = "Alf's DMF Extensions",
	ru = "Расширения DMF от Альфа",
	["zh-cn"] = "Alf的DMF扩展",
	["zh-tw"] = "Alf的DMF擴展",
}

mod.localisation = {
	mod_name = {
		en = mod_name["en"],
		ru = mod_name["ru"],
		["zh-cn"] = mod_name["zh-cn"],
		["zh-tw"] = mod_name["zh-tw"],
	},
	mod_name_pizazz = {
		en = mod.gradientText(mod_name["en"], { 255, 255, 0 }, { 255, 0, 255 }, true),
		ru = mod.gradientText(mod_name["ru"], { 255, 255, 0 }, { 255, 0, 255 }, true),
		["zh-cn"] = mod.gradientText(mod_name["zh-cn"], { 255, 255, 0 }, { 255, 0, 255 }, true),
		["zh-tw"] = mod.gradientText(mod_name["zh-tw"], { 255, 255, 0 }, { 255, 0, 255 }, true),
	},
	mod_name_boring = {
		en = mod_name["en"],
		ru = mod_name["ru"],
		["zh-cn"] = mod_name["zh-cn"],
		["zh-tw"] = mod_name["zh-tw"],
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
		["zh-cn"] = "{#color("
			.. colours.text
			.. ")}"
			.. "Darktide Mod Framework 设置菜单的扩展功能，为用户和模组作者提供多种便利。所有扩展均为可选的集成扩展，而非强制性更改。"
			.. "{#reset()}\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}作者："
			.. "{#color("
			.. colours.text
			.. ")}Alfthebigheaded\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}版本：{#color("
			.. colours.text
			.. ")}"
			.. mod.version
			.. "{#reset()}",
		["zh-tw"] = "{#color("
			.. colours.text
			.. ")}"
			.. "Darktide Mod Framework 設定選單的擴充功能，為使用者和模組作者提供多種便利。所有擴充均為可選的整合式擴充，而非強制性更改。"
			.. "{#reset()}\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}作者："
			.. "{#color("
			.. colours.text
			.. ")}Alfthebigheaded\n"
			.. "{#color("
			.. colours.subtitle
			.. ")}版本：{#color("
			.. colours.text
			.. ")}"
			.. mod.version
			.. "{#reset()}",
	},
	general_settings = {
		en = "{#color(" .. colours.title .. ")}General Settings{#reset()}",
		ru = "{#color(" .. colours.title .. ")}Основные настройки{#reset()}",
		["zh-cn"] = "{#color(" .. colours.title .. ")}通用设置{#reset()}",
		["zh-tw"] = "{#color(" .. colours.title .. ")}一般設定{#reset()}",
	},
	mod_name_pizazz_toggle = {
		en = "Name Pizazz",
		ru = "Красочное название",
		["zh-cn"] = "名称特效",
		["zh-tw"] = "名稱特效",
	},
	mod_name_pizazz_tooltip = {
		en = "Toggles the rainbow colours effect on the mod name text. Requires a reload.\nIf enabled, you will get a small euphoric experience everytime you scroll through the mod menu, \nIf disabled - you will be a John Darktide and have no rainbow sprinkles (but I'll love you anyway).",
		ru = "Включает радужную расцветку текста названия мода. Требуется перезагрузка.\nЕсли включено, вы получите небольшой эйфорический опыт каждый раз, когда листаете меню модов.\nЕсли выключено — вы будете Джоном Дарктайдом без радужной посыпки (но я всё равно буду вас любить).",
		["zh-cn"] = "切换模组名称的彩虹颜色效果。需要重新加载。\n启用后，每次滚动模组菜单时你都会获得小小的愉悦体验。\n禁用后，你将失去彩虹点缀（但我仍然爱你）。",
		["zh-tw"] = "切換模組名稱的彩虹顏色效果。需要重新載入。\n啟用後，每次滾動模組選單時你都會獲得小小的愉悅體驗。\n停用後，你將成為一般的黑暗潮汐玩家，失去彩虹點綴（但我仍然愛你）。",
	},
	enable_scroll_position_saving = {
		en = "Scroll Position Saving",
		ru = "Сохранение позиции прокрутки",
		["zh-cn"] = "滚动位置保存",
		["zh-tw"] = "捲動位置保存",
	},
	enable_scroll_position_saving_tooltip = {
		en = "Toggles saving of scroll position within the mod settings menu, so you can return to the last position you were at when you reopen the menu.",
		ru = "Включает сохранение позиции прокрутки внутри меню настроек модов, чтобы при повторном открытии меню вы возвращались к последнему месту.",
		["zh-cn"] = "开启模组设置菜单中滚动位置的保存功能，重新打开菜单时可返回上次的位置。",
		["zh-tw"] = "開啟模組設定選單中捲動位置的保存功能，重新開啟選單時可返回上次的位置。",
	},
	enable_mod_tabs = {
		en = "Mod Tabs",
		ru = "Вкладки модов",
		["zh-cn"] = "模组标签页",
		["zh-tw"] = "模組分頁",
	},
	enable_mod_tabs_tooltip = {
		en = "Toggles mod tabs being created at all, which let mod authors add custom tabs to the mod settings menu for easier navigation and grouping. If this setting is disabled, no mod tabs will be shown at all.",
		ru = "Включает создание вкладок модов. Они позволяют авторам добавлять собственные вкладки в меню настроек для удобной навигации и группировки. Если эта настройка отключена, вкладки модов вообще не будут отображаться.",
		["zh-cn"] = "开启模组标签页功能，允许模组作者在设置菜单中添加自定义标签页以便于导航和分组。禁用此选项后，将不会显示任何模组标签页。",
		["zh-tw"] = "開啟模組分頁功能，允許模組作者在設定選單中添加自訂分頁以便於導覽和分組。停用此選項後，將不會顯示任何模組分頁。",
	},
	enable_generalised_mod_tabs = {
		en = "Generalised Mod Tabs",
		ru = "Обобщённые вкладки модов",
		["zh-cn"] = "通用模组标签页",
		["zh-tw"] = "通用模組分頁",
	},
	enable_generalised_mod_tabs_tooltip = {
		en = "Toggles generalised mod tab creation for mods that do not explicitly have tab support. \n\n{#color("
			.. colours.subtitle
			.. ")}These are automatically created using the mod's existing settings structure, and may be innacurate.{#reset()} \n\nIf this setting is disabled, only mods that have specifically added tab support for 'Alf's DMF Extensions' will have tabs.",
		ru = "Включает создание обобщённых вкладок для модов, у которых нет явной поддержки вкладок.\n\n{#color("
			.. colours.subtitle
			.. ")}Они автоматически создаются на основе существующей структуры настроек мода и могут быть неточными.{#reset()}\n\nЕсли эта настройка отключена, вкладки будут только у модов, которые специально добавили поддержку вкладок для 'Alf's DMF Extensions'.",
		["zh-cn"] = "为没有明确标签页支持的模组开启通用标签页创建。\n\n{#color("
			.. colours.subtitle
			.. ")}这些标签页基于模组现有的设置结构自动创建，可能不够准确。{#reset()}\n\n禁用此选项后，只有专门为 'Alf's DMF Extensions' 添加了标签页支持的模组才会显示标签页。",
		["zh-tw"] = "為沒有明確分頁支援的模組開啟通用分頁建立。\n\n{#color("
			.. colours.subtitle
			.. ")}這些分頁基於模組現有的設定結構自動建立，可能不夠準確。{#reset()}\n\n停用此選項後，只有專門為 'Alf's DMF Extensions' 添加了分頁支援的模組才會顯示分頁。",
	},
	enable_RGB_widget = {
		en = "Color Widget Replacement",
		ru = "Замена виджета цвета",
		["zh-cn"] = "颜色控件替换",
		["zh-tw"] = "顏色控件替換",
	},
	enable_RGB_widget_tooltip = {
		en = "Controls how color settings are displayed.\n\n{#color(169,191,153)}ARGB Sliders{#reset()} - Replaces individual R/G/B/A sliders with my own custom, combined RGB widget.\n{#color(169,191,153)}Color Widget{#reset()} - Replaces individual R/G/B/A sliders with DMF's new RGB widget.\n{#color(169,191,153)}Disabled{#reset()} - No color widget replacement, keep the sliders seperated..",
		ru = "Управляет отображением настроек цвета.\n\n{#color(169,191,153)}Ползунки ARGB{#reset()} - Заменяет отдельные ползунки R/G/B/A на собственный комбинированный RGB-виджет.\n{#color(169,191,153)}Виджет цвета{#reset()} - Заменяет отдельные ползунки R/G/B/A на новый RGB-виджет DMF.\n{#color(169,191,153)}Отключено{#reset()} - Без замены виджета цвета, ползунки остаются разделёнными.",
		["zh-cn"] = "控制颜色设置的显示方式。\n\n{#color(169,191,153)}ARGB滑块{#reset()} - 用自定义的组合RGB控件替换单独的R/G/B/A滑块。\n{#color(169,191,153)}颜色控件{#reset()} - 用DMF的新RGB控件替换单独的R/G/B/A滑块。\n{#color(169,191,153)}禁用{#reset()} - 不替换颜色控件，保持滑块分离。",
		["zh-tw"] = "控制顏色設定的顯示方式。\n\n{#color(169,191,153)}ARGB滑桿{#reset()} - 用自訂的組合RGB控件替換單獨的R/G/B/A滑桿。\n{#color(169,191,153)}顏色控件{#reset()} - 用DMF的新RGB控件替換單獨的R/G/B/A滑桿。\n{#color(169,191,153)}停用{#reset()} - 不替換顏色控件，保持滑桿分離。",
	},
	rgb_replacement_argb_sliders = {
		en = "Alf's Custom ARGB Widget",
		ru = "Пользовательский ARGB-виджет Alf",
		["zh-cn"] = "Alf的自定义ARGB控件",
		["zh-tw"] = "Alf的自訂ARGB控件",
	},
	rgb_replacement_color_widget = {
		en = "Native DMF Color Widget",
		ru = "Встроенный виджет цвета DMF",
		["zh-cn"] = "DMF原生颜色控件",
		["zh-tw"] = "DMF原生顏色控件",
	},
	rgb_replacement_disabled = {
		en = "Disabled",
		ru = "Отключено",
		["zh-cn"] = "禁用",
		["zh-tw"] = "停用",
	},
	reload_mods_keybind = {
		en = "Reload Mods Keybind",
		ru = "Клавиша перезагрузки модов",
		["zh-cn"] = "重载模组快捷键",
		["zh-tw"] = "重新載入模組快捷鍵",
	},
	reload_mods_keybind_tooltip = {
		en = "Keybind to trigger a full mod reload (Ctrl+Shift+R in developer mode by default).",
		ru = "Клавиша для полной перезагрузки модов (по умолчанию Ctrl+Shift+R в режиме разработчика).",
		["zh-cn"] = "触发完全重载模组的快捷键（默认为开发者模式下的 Ctrl+Shift+R）。",
		["zh-tw"] = "觸發完全重新載入模組的快捷鍵（預設為開發者模式下的 Ctrl+Shift+R）。",
	},
	icon_dropdown_test = {
		en = "Icon Dropdown Test",
		ru = "Тест выпадающего списка с иконками",
		["zh-cn"] = "图标下拉列表测试",
		["zh-tw"] = "圖示下拉選單測試",
	},
	icon_dropdown_test_tooltip = {
		en = "A test dropdown with icon support. Options with an 'icon' field defined show an icon to the left of the text.",
		ru = "Тестовый выпадающий список с поддержкой иконок. Опции, у которых определено поле 'icon', показывают иконку слева от текста.",
		["zh-cn"] = "支持图标的测试下拉列表。定义了 'icon' 字段的选项会在文本左侧显示图标。",
		["zh-tw"] = "支援圖示的測試下拉選單。定義了 'icon' 欄位的選項會在文字左側顯示圖示。",
	},
	enable_dropdown_icons = {
		en = "Dropdown Icons",
		ru = "Иконки в выпадающих списках",
		["zh-cn"] = "下拉列表图标",
		["zh-tw"] = "下拉選單圖示",
	},
	enable_dropdown_icons_tooltip = {
		en = "Toggles icon support for DMF settings dropdowns. These need to be implemented by the mod author, I'd suggest using DMF's new icon dropdown system instead, this is kept here for backwards compatibility. ",
		ru = "Включает поддержку иконок в выпадающих списках настроек DMF. Их должны реализовать авторы модов.",
		["zh-cn"] = "开启DMF设置下拉列表的图标支持。需要由模组作者实现，建议改用DMF新的图标下拉系统，此选项仅用于向后兼容。",
		["zh-tw"] = "開啟DMF設定下拉選單的圖示支援。需要由模組作者實作，建議改用DMF新的圖示下拉系統，此選項僅用於向後相容。",
	},
	enable_font_support = {
		en = "Display Font Type",
		ru = "Тип отображаемого шрифта",
		["zh-cn"] = "显示字体类型",
		["zh-tw"] = "顯示字體類型",
	},
	enable_font_support_tooltip = {
		en = "Toggles displaying the font type for DMF settings. These need to be implemented by the mod author and can be included with the {#font} tag.",
		ru = "Включает отображение типа шрифта для настроек DMF. Их должны реализовать авторы модов, используя тег {#font}.",
		["zh-cn"] = "开启DMF设置中字体类型的显示。需要由模组作者实现，可通过 {#font} 标签包含。",
		["zh-tw"] = "開啟DMF設定中字體類型的顯示。需要由模組作者實作，可透過 {#font} 標籤包含。",
	},
	enable_scrollable_dropdown = {
		en = "Mouse-Scrollable Dropdowns",
		ru = "Прокручиваемые выпадающие списки",
		["zh-cn"] = "鼠标滚轮下拉列表",
		["zh-tw"] = "滑鼠滾輪下拉選單",
	},
	enable_scrollable_dropdown_tooltip = {
		en = "Toggles allowing the use of your mouse to scroll through the dropdown menus in DMF.",
		ru = "Включает возможность прокручивать выпадающие меню в DMF с помощью мыши.",
		["zh-cn"] = "开启允许使用鼠标滚轮在DMF下拉菜单中滚动。",
		["zh-tw"] = "開啟允許使用滑鼠滾輪在DMF下拉選單中捲動。",
	},
	tab_arrow_left = {
		en = "<",
		ru = "<",
		["zh-cn"] = "<",
		["zh-tw"] = "<",
	},
	tab_arrow_right = {
		en = ">",
		ru = ">",
		["zh-cn"] = ">",
		["zh-tw"] = ">",
	},
	tab_title_truncated = {
		en = "..",
		ru = "..",
		["zh-cn"] = "..",
		["zh-tw"] = "..",
	},
	default_tab = {
		en = "Other",
		ru = "Прочее",
		["zh-cn"] = "其他",
		["zh-tw"] = "其他",
	},
	enable_reload_mods_rebind = {
		en = "Rebind DMF Reload?",
		ru = "Переназначить перезагрузку DMF?",
		["zh-cn"] = "重新绑定DMF重载？",
		["zh-tw"] = "重新綁定DMF重新載入？",
	},
	enable_reload_mods_rebind_tooltip = {
		en = "Toggle rebinding the default DMF Reload keybind (Ctrl+Shift+R in developer mode by default).",
		ru = "Включает переназначение стандартной клавиши перезагрузки DMF (по умолчанию Ctrl+Shift+R в режиме разработчика).",
		["zh-cn"] = "切换重新绑定默认的DMF重载快捷键（默认为开发者模式下的 Ctrl+Shift+R）。",
		["zh-tw"] = "切換重新綁定預設的DMF重新載入快捷鍵（預設為開發者模式下的 Ctrl+Shift+R）。",
	},
	gen_tabs_toggle_on = {
		en = "{#color(180,255,180)}Tabs Enabled{#reset()}",
		ru = "{#color(180,255,180)}Вкладки включены{#reset()}",
		["zh-cn"] = "{#color(180,255,180)}标签页已启用{#reset()}",
		["zh-tw"] = "{#color(180,255,180)}分頁已啟用{#reset()}",
	},
	gen_tabs_toggle_off = {
		en = "{#color(255,180,180)}Tabs Disabled{#reset()}",
		ru = "{#color(255,180,180)}Вкладки отключены{#reset()}",
		["zh-cn"] = "{#color(255,180,180)}标签页已禁用{#reset()}",
		["zh-tw"] = "{#color(255,180,180)}分頁已停用{#reset()}",
	},
	gen_tabs_toggle_tooltip = {
		en = "Toggle tabs for this mod.",
		ru = "Включение вкладок для этого мода.",
		["zh-cn"] = "切换此模组的标签页。",
		["zh-tw"] = "切換此模組的分頁。",
	},
	enable_tab_reset = {
		en = "Per-Tab Reset to Defaults",
		ru = "Сброс настроек по вкладкам",
		["zh-cn"] = "按标签页恢复默认设置",
		["zh-tw"] = "按分頁恢復預設設定",
	},
	enable_tab_reset_tooltip = {
		en = "Adds a hotkey entry to reset only the currently selected tab's settings to their defaults, rather than resetting all settings in the mod.",
		ru = "Добавляет пункт в горячие клавиши для сброса настроек только текущей выбранной вкладки, а не всех настроек мода.",
		["zh-cn"] = "添加一个快捷键，仅将当前选中标签页的设置恢复为默认值，而非重置模组的所有设置。",
		["zh-tw"] = "添加一個快捷鍵，僅將當前選中分頁的設定恢復為預設值，而非重置模組的所有設定。",
	},
	reset_tab_to_default = {
		en = "Reset tab to default settings",
		ru = "Сбросить вкладку к настройкам по умолчанию",
		["zh-cn"] = "将标签页恢复为默认设置",
		["zh-tw"] = "將分頁恢復為預設設定",
	},
	reset_tab_to_default_description = {
		en = "This will reset the currently selected tab to their mod defaults",
		ru = "Это сбросит текущую выбранную вкладку к настройкам мода по умолчанию",
		["zh-cn"] = "将当前选中的标签页恢复为模组默认设置",
		["zh-tw"] = "將當前選中的分頁恢復為模組預設設定",
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
