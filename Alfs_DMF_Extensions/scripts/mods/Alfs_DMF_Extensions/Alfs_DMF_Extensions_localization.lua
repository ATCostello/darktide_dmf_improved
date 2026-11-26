local mod = get_mod("Alfs_DMF_Extensions")
mod.version = "3.0.0"
mod:info("Alfs DMF Extensions is installed, using version: " .. tostring(mod.version))

local next = next
local InputUtils = require("scripts/managers/input/input_utils")

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

	result = "{#color(" .. colours.title .. ")} " .. result .. "{#reset()}"
	return result
end

--local name = mod.gradientText("Alf's DMF Extensions", { 255, 255, 0 }, { 255, 0, 255 }, true)
--Clipboard.put(name)
--mod:echo(name)

mod._available_aliases = {
	"character_create_randomize",
	"hotkey_item_favorite",
	"hotkey_help",
	"hotkey_inventory",
	"hotkey_loadout",
	"hotkey_menu_special_1",
	"hotkey_menu_special_2",
	"hotkey_toggle_item_tooltip",
	"accept_invite_notification",
	"hotkey_item_inspect",
	"hotkey_item_discard",
	"hotkey_start_game",
	"group_finder_group_inspect",
	"next_hint",
	"cycle_list_secondary",
	"notification_option_a",
	"notification_option_b",
	"talent_unequip",
}

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
	enable_presets = {
		en = "Enable Presets",
		ru = "Включить пресеты",
		["zh-cn"] = "启用预设",
		["zh-tw"] = "啟用預設",
	},
	enable_presets_tooltip = {
		en = "Shows the preset cog buttons beside each mod name and beside MOD OPTIONS. Disable this to hide every preset control.",
		ru = "Показывает кнопки пресетов рядом с каждым названием мода и рядом с MOD OPTIONS. Отключите, чтобы скрыть все элементы управления пресетами.",
		["zh-cn"] = "在每个模组名称旁边和 MOD OPTIONS 旁边显示预设按钮。禁用后可隐藏所有预设控件。",
		["zh-tw"] = "在每個模組名稱旁邊與 MOD OPTIONS 旁邊顯示預設按鈕。停用後可隱藏所有預設控制項。",
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
	preset_editor_button = {
		en = "Presets...",
		ru = "Presets...",
		["zh-cn"] = "Presets...",
		["zh-tw"] = "Presets...",
	},
	preset_editor_tooltip = {
		en = "Save, load, export, and import presets for this mod.",
		ru = "Save, load, export, and import presets for this mod.",
		["zh-cn"] = "Save, load, export, and import presets for this mod.",
		["zh-tw"] = "Save, load, export, and import presets for this mod.",
	},
	preset_editor_title = {
		en = "Preset Editor",
		ru = "Preset Editor",
		["zh-cn"] = "Preset Editor",
		["zh-tw"] = "Preset Editor",
	},
	preset_editor_description = {
		en = "Saved presets for %s.",
		ru = "Saved presets for %s.",
		["zh-cn"] = "Saved presets for %s.",
		["zh-tw"] = "Saved presets for %s.",
	},
	preset_editor_all_mods = {
		en = "All Mod Options",
		ru = "All Mod Options",
		["zh-cn"] = "All Mod Options",
		["zh-tw"] = "All Mod Options",
	},
	preset_editor_global_title = {
		en = "Global Presets",
		ru = "Global Presets",
		["zh-cn"] = "Global Presets",
		["zh-tw"] = "Global Presets",
	},
	preset_editor_global_description = {
		en = "Saved presets for all mod options.",
		ru = "Saved presets for all mod options.",
		["zh-cn"] = "Saved presets for all mod options.",
		["zh-tw"] = "Saved presets for all mod options.",
	},
	preset_editor_global_tooltip = {
		en = "Save, load, export, and import presets for all mods.",
		ru = "Save, load, export, and import presets for all mods.",
		["zh-cn"] = "Save, load, export, and import presets for all mods.",
		["zh-tw"] = "Save, load, export, and import presets for all mods.",
	},
	preset_editor_presets = {
		en = "Presets",
		ru = "Presets",
		["zh-cn"] = "Presets",
		["zh-tw"] = "Presets",
	},
	preset_editor_no_presets = {
		en = "++ RECORDS NOT FOUND ++",
		ru = "++ RECORDS NOT FOUND ++",
		["zh-cn"] = "++ RECORDS NOT FOUND ++",
		["zh-tw"] = "++ RECORDS NOT FOUND ++",
	},
	preset_editor_selected = {
		en = "++ ACTIVE RECORD: %s ++",
		ru = "++ ACTIVE RECORD: %s ++",
		["zh-cn"] = "++ ACTIVE RECORD: %s ++",
		["zh-tw"] = "++ ACTIVE RECORD: %s ++",
	},
	preset_editor_select_preset_hint = {
		en = "++ NO PRESET SELECTED ++",
		ru = "++ NO PRESET SELECTED ++",
		["zh-cn"] = "++ NO PRESET SELECTED ++",
		["zh-tw"] = "++ NO PRESET SELECTED ++",
	},
	preset_editor_apply = {
		en = "Apply selected preset",
		ru = "Apply selected preset",
		["zh-cn"] = "Apply selected preset",
		["zh-tw"] = "Apply selected preset",
	},
	preset_editor_save = {
		en = "Save current settings",
		ru = "Save current settings",
		["zh-cn"] = "Save current settings",
		["zh-tw"] = "Save current settings",
	},
	preset_editor_import = {
		en = "Import preset",
		ru = "Import preset",
		["zh-cn"] = "Import preset",
		["zh-tw"] = "Import preset",
	},
	preset_editor_export = {
		en = "Export selected preset",
		ru = "Export selected preset",
		["zh-cn"] = "Export selected preset",
		["zh-tw"] = "Export selected preset",
	},
	preset_editor_export_current = {
		en = "Export current settings",
		ru = "Export current settings",
		["zh-cn"] = "Export current settings",
		["zh-tw"] = "Export current settings",
	},
	preset_editor_delete = {
		en = "Delete selected preset",
		ru = "Delete selected preset",
		["zh-cn"] = "Delete selected preset",
		["zh-tw"] = "Delete selected preset",
	},
	preset_editor_assign = {
		en = "Assign to characters",
		ru = "Assign to characters",
		["zh-cn"] = "Assign to characters",
		["zh-tw"] = "Assign to characters",
	},
	preset_editor_character_hint = {
		en = "++ AUTO-APPLY %s ON CHARACTER SELECT ++",
		ru = "++ AUTO-APPLY %s ON CHARACTER SELECT ++",
		["zh-cn"] = "++ AUTO-APPLY %s ON CHARACTER SELECT ++",
		["zh-tw"] = "++ AUTO-APPLY %s ON CHARACTER SELECT ++",
	},
	preset_editor_back = {
		en = "Back",
		ru = "Back",
		["zh-cn"] = "Back",
		["zh-tw"] = "Back",
	},
	preset_editor_close = {
		en = "Close",
		ru = "Close",
		["zh-cn"] = "Close",
		["zh-tw"] = "Close",
	},
	preset_editor_preset_tooltip = {
		en = "Inspect preset '%s'",
		ru = "Inspect preset '%s'",
		["zh-cn"] = "Inspect preset '%s'",
		["zh-tw"] = "Inspect preset '%s'",
	},
	preset_editor_apply_tooltip = {
		en = "Apply the selected preset.",
		ru = "Apply the selected preset.",
		["zh-cn"] = "Apply the selected preset.",
		["zh-tw"] = "Apply the selected preset.",
	},
	preset_editor_export_tooltip = {
		en = "Copy the selected preset's string to the clipboard.",
		ru = "Copy the selected preset's string to the clipboard.",
		["zh-cn"] = "Copy the selected preset's string to the clipboard.",
		["zh-tw"] = "Copy the selected preset's string to the clipboard.",
	},
	preset_editor_assign_tooltip = {
		en = "Choose characters that should automatically use this preset.",
		ru = "Choose characters that should automatically use this preset.",
		["zh-cn"] = "Choose characters that should automatically use this preset.",
		["zh-tw"] = "Choose characters that should automatically use this preset.",
	},
	preset_editor_delete_tooltip = {
		en = "Delete the selected preset permanently.",
		ru = "Delete the selected preset permanently.",
		["zh-cn"] = "Delete the selected preset permanently.",
		["zh-tw"] = "Delete the selected preset permanently.",
	},
	preset_editor_save_tooltip = {
		en = "Save current settings as a new preset.",
		ru = "Save current settings as a new preset.",
		["zh-cn"] = "Save current settings as a new preset.",
		["zh-tw"] = "Save current settings as a new preset.",
	},
	preset_editor_import_tooltip = {
		en = "Paste a preset string to import it.",
		ru = "Paste a preset string to import it.",
		["zh-cn"] = "Paste a preset string to import it.",
		["zh-tw"] = "Paste a preset string to import it.",
	},
	preset_editor_export_current_tooltip = {
		en = "Copy the current settings string to the clipboard.",
		ru = "Copy the current settings string to the clipboard.",
		["zh-cn"] = "Copy the current settings string to the clipboard.",
		["zh-tw"] = "Copy the current settings string to the clipboard.",
	},
	preset_editor_close_tooltip = {
		en = "Close the preset editor.",
		ru = "Close the preset editor.",
		["zh-cn"] = "Close the preset editor.",
		["zh-tw"] = "Close the preset editor.",
	},
	preset_editor_back_tooltip = {
		en = "Return to the preset actions.",
		ru = "Return to the preset actions.",
		["zh-cn"] = "Return to the preset actions.",
		["zh-tw"] = "Return to the preset actions.",
	},
	preset_editor_select_scope_title = {
		en = "Select Preset",
		ru = "Select Preset",
		["zh-cn"] = "Select Preset",
		["zh-tw"] = "Select Preset",
	},
	preset_editor_select_scope_description = {
		en = "Choose which mod's presets to edit.",
		ru = "Choose which mod's presets to edit.",
		["zh-cn"] = "Choose which mod's presets to edit.",
		["zh-tw"] = "Choose which mod's presets to edit.",
	},
	preset_editor_scope_tooltip = {
		en = "Click to choose a different mod, or select all mod options.",
		ru = "Click to choose a different mod, or select all mod options.",
		["zh-cn"] = "Click to choose a different mod, or select all mod options.",
		["zh-tw"] = "Click to choose a different mod, or select all mod options.",
	},
	preset_editor_character_tooltip = {
		en = "Toggle automatic preset assignment for '%s'.",
		ru = "Toggle automatic preset assignment for '%s'.",
		["zh-cn"] = "Toggle automatic preset assignment for '%s'.",
		["zh-tw"] = "Toggle automatic preset assignment for '%s'.",
	},
	preset_editor_auto_apply_start = {
		en = "Applying saved presets for %s...",
		ru = "Applying saved presets for %s...",
		["zh-cn"] = "Applying saved presets for %s...",
		["zh-tw"] = "Applying saved presets for %s...",
	},
	preset_editor_copied_title = {
		en = "Copied to Clipboard",
		ru = "Copied to Clipboard",
		["zh-cn"] = "Copied to Clipboard",
		["zh-tw"] = "Copied to Clipboard",
	},
	preset_editor_copied_description = {
		en = "The settings string has been copied to your clipboard.",
		ru = "The settings string has been copied to your clipboard.",
		["zh-cn"] = "The settings string has been copied to your clipboard.",
		["zh-tw"] = "The settings string has been copied to your clipboard.",
	},
	preset_editor_copy_failed_title = {
		en = "Clipboard Unavailable",
		ru = "Clipboard Unavailable",
		["zh-cn"] = "Clipboard Unavailable",
		["zh-tw"] = "Clipboard Unavailable",
	},
	preset_editor_copy_failed_description = {
		en = "The game could not access the clipboard.",
		ru = "The game could not access the clipboard.",
		["zh-cn"] = "The game could not access the clipboard.",
		["zh-tw"] = "The game could not access the clipboard.",
	},
	preset_editor_applied = {
		en = "Applied '%s'.",
		ru = "Applied '%s'.",
		["zh-cn"] = "Applied '%s'.",
		["zh-tw"] = "Applied '%s'.",
	},
	preset_editor_applied_global = {
		en = "Applied global preset '%s'.",
		ru = "Applied global preset '%s'.",
		["zh-cn"] = "Applied global preset '%s'.",
		["zh-tw"] = "Applied global preset '%s'.",
	},
	preset_editor_apply_any_confirm = {
		en = "Apply '%s' to %s? All current settings will be overwritten. A backup will be made of your current settings.",
		ru = "Apply '%s' to %s? All current settings will be overwritten. A backup will be made of your current settings.",
		["zh-cn"] = "Apply '%s' to %s? All current settings will be overwritten. A backup will be made of your current settings.",
		["zh-tw"] = "Apply '%s' to %s? All current settings will be overwritten. A backup will be made of your current settings.",
	},
	preset_editor_apply_confirm = {
		en = "Apply '%s' to %s? All current settings for this mod will be overwritten. A backup will be made of your current settings.",
		ru = "Apply '%s' to %s? All current settings for this mod will be overwritten. A backup will be made of your current settings.",
		["zh-cn"] = "Apply '%s' to %s? All current settings for this mod will be overwritten. A backup will be made of your current settings.",
		["zh-tw"] = "Apply '%s' to %s? All current settings for this mod will be overwritten. A backup will be made of your current settings.",
	},
	preset_editor_apply_global_confirm = {
		en = "Apply '%s' to %s? All current settings for every mod will be overwritten. A backup will be made of your current settings.",
		ru = "Apply '%s' to %s? All current settings for every mod will be overwritten. A backup will be made of your current settings.",
		["zh-cn"] = "Apply '%s' to %s? All current settings for every mod will be overwritten. A backup will be made of your current settings.",
		["zh-tw"] = "Apply '%s' to %s? All current settings for every mod will be overwritten. A backup will be made of your current settings.",
	},
	preset_editor_apply_global_title = {
		en = "Apply Global Preset",
		ru = "Apply Global Preset",
		["zh-cn"] = "Apply Global Preset",
		["zh-tw"] = "Apply Global Preset",
	},
	preset_editor_apply_option = {
		en = "Apply '%s'",
		ru = "Apply '%s'",
		["zh-cn"] = "Apply '%s'",
		["zh-tw"] = "Apply '%s'",
	},
	preset_editor_apply_title = {
		en = "Apply Preset",
		ru = "Apply Preset",
		["zh-cn"] = "Apply Preset",
		["zh-tw"] = "Apply Preset",
	},
	preset_editor_backup_prefix = {
		en = "BACKUP ",
		ru = "BACKUP ",
		["zh-cn"] = "BACKUP ",
		["zh-tw"] = "BACKUP ",
	},
	preset_editor_confirm_title = {
		en = "Confirm",
		ru = "Confirm",
		["zh-cn"] = "Confirm",
		["zh-tw"] = "Confirm",
	},
	preset_editor_copy_to_clipboard = {
		en = "Copy to clipboard",
		ru = "Copy to clipboard",
		["zh-cn"] = "Copy to clipboard",
		["zh-tw"] = "Copy to clipboard",
	},
	preset_editor_current_settings = {
		en = "Current Settings",
		ru = "Current Settings",
		["zh-cn"] = "Current Settings",
		["zh-tw"] = "Current Settings",
	},
	preset_editor_delete_confirm = {
		en = "Delete preset '%s'?",
		ru = "Delete preset '%s'?",
		["zh-cn"] = "Delete preset '%s'?",
		["zh-tw"] = "Delete preset '%s'?",
	},
	preset_editor_delete_global_confirm = {
		en = "Delete global preset '%s'?",
		ru = "Delete global preset '%s'?",
		["zh-cn"] = "Delete global preset '%s'?",
		["zh-tw"] = "Delete global preset '%s'?",
	},
	preset_editor_delete_option = {
		en = "Delete '%s'",
		ru = "Delete '%s'",
		["zh-cn"] = "Delete '%s'",
		["zh-tw"] = "Delete '%s'",
	},
	preset_editor_delete_title = {
		en = "Delete Preset",
		ru = "Delete Preset",
		["zh-cn"] = "Delete Preset",
		["zh-tw"] = "Delete Preset",
	},
	preset_editor_enter_name = {
		en = "Enter a preset name.",
		ru = "Enter a preset name.",
		["zh-cn"] = "Enter a preset name.",
		["zh-tw"] = "Enter a preset name.",
	},
	preset_editor_error_title = {
		en = "Preset Error",
		ru = "Preset Error",
		["zh-cn"] = "Preset Error",
		["zh-tw"] = "Preset Error",
	},
	preset_editor_export_current_json_option = {
		en = "Export current settings JSON",
		ru = "Export current settings JSON",
		["zh-cn"] = "Export current settings JSON",
		["zh-tw"] = "Export current settings JSON",
	},
	preset_editor_export_global_json_title = {
		en = "Export Global Preset JSON",
		ru = "Export Global Preset JSON",
		["zh-cn"] = "Export Global Preset JSON",
		["zh-tw"] = "Export Global Preset JSON",
	},
	preset_editor_export_json_title = {
		en = "Export Preset JSON",
		ru = "Export Preset JSON",
		["zh-cn"] = "Export Preset JSON",
		["zh-tw"] = "Export Preset JSON",
	},
	preset_editor_export_nothing = {
		en = "No settings could be exported.",
		ru = "No settings could be exported.",
		["zh-cn"] = "No settings could be exported.",
		["zh-tw"] = "No settings could be exported.",
	},
	preset_editor_export_option = {
		en = "Export '%s' JSON",
		ru = "Export '%s' JSON",
		["zh-cn"] = "Export '%s' JSON",
		["zh-tw"] = "Export '%s' JSON",
	},
	preset_editor_global_json_title = {
		en = "Global Preset JSON",
		ru = "Global Preset JSON",
		["zh-cn"] = "Global Preset JSON",
		["zh-tw"] = "Global Preset JSON",
	},
	preset_editor_global_name_title = {
		en = "Global preset name",
		ru = "Global preset name",
		["zh-cn"] = "Global preset name",
		["zh-tw"] = "Global preset name",
	},
	preset_editor_global_not_found = {
		en = "Global preset '%s' could not be found.",
		ru = "Global preset '%s' could not be found.",
		["zh-cn"] = "Global preset '%s' could not be found.",
		["zh-tw"] = "Global preset '%s' could not be found.",
	},
	preset_editor_import_button = {
		en = "Import",
		ru = "Import",
		["zh-cn"] = "Import",
		["zh-tw"] = "Import",
	},
	preset_editor_import_confirm = {
		en = "Import '%s' into %s? All current settings for this mod will be overwritten.",
		ru = "Import '%s' into %s? All current settings for this mod will be overwritten.",
		["zh-cn"] = "Import '%s' into %s? All current settings for this mod will be overwritten.",
		["zh-tw"] = "Import '%s' into %s? All current settings for this mod will be overwritten.",
	},
	preset_editor_import_failed_title = {
		en = "Import Failed",
		ru = "Import Failed",
		["zh-cn"] = "Import Failed",
		["zh-tw"] = "Import Failed",
	},
	preset_editor_import_global_confirm = {
		en = "Import '%s' for %s? All current settings for every mod will be overwritten.",
		ru = "Import '%s' for %s? All current settings for every mod will be overwritten.",
		["zh-cn"] = "Import '%s' for %s? All current settings for every mod will be overwritten.",
		["zh-tw"] = "Import '%s' for %s? All current settings for every mod will be overwritten.",
	},
	preset_editor_import_global_json_description = {
		en = "Paste a global preset JSON string, then press Import.",
		ru = "Paste a global preset JSON string, then press Import.",
		["zh-cn"] = "Paste a global preset JSON string, then press Import.",
		["zh-tw"] = "Paste a global preset JSON string, then press Import.",
	},
	preset_editor_import_global_json_option = {
		en = "Import global preset JSON",
		ru = "Import global preset JSON",
		["zh-cn"] = "Import global preset JSON",
		["zh-tw"] = "Import global preset JSON",
	},
	preset_editor_import_global_json_title = {
		en = "Import Global Preset JSON",
		ru = "Import Global Preset JSON",
		["zh-cn"] = "Import Global Preset JSON",
		["zh-tw"] = "Import Global Preset JSON",
	},
	preset_editor_import_global_title = {
		en = "Import Global Preset",
		ru = "Import Global Preset",
		["zh-cn"] = "Import Global Preset",
		["zh-tw"] = "Import Global Preset",
	},
	preset_editor_import_json_description = {
		en = "Paste a preset JSON string, then press Import.",
		ru = "Paste a preset JSON string, then press Import.",
		["zh-cn"] = "Paste a preset JSON string, then press Import.",
		["zh-tw"] = "Paste a preset JSON string, then press Import.",
	},
	preset_editor_import_json_option = {
		en = "Import preset JSON",
		ru = "Import preset JSON",
		["zh-cn"] = "Import preset JSON",
		["zh-tw"] = "Import preset JSON",
	},
	preset_editor_import_json_title = {
		en = "Import Preset JSON",
		ru = "Import Preset JSON",
		["zh-cn"] = "Import Preset JSON",
		["zh-tw"] = "Import Preset JSON",
	},
	preset_editor_import_title = {
		en = "Import Preset",
		ru = "Import Preset",
		["zh-cn"] = "Import Preset",
		["zh-tw"] = "Import Preset",
	},
	preset_editor_imported_global_name = {
		en = "Imported Global Preset",
		ru = "Imported Global Preset",
		["zh-cn"] = "Imported Global Preset",
		["zh-tw"] = "Imported Global Preset",
	},
	preset_editor_imported_name = {
		en = "Imported Preset",
		ru = "Imported Preset",
		["zh-cn"] = "Imported Preset",
		["zh-tw"] = "Imported Preset",
	},
	preset_editor_invalid_global_string = {
		en = "This is not an Alfs DMF Extensions global preset string.",
		ru = "This is not an Alfs DMF Extensions global preset string.",
		["zh-cn"] = "This is not an Alfs DMF Extensions global preset string.",
		["zh-tw"] = "This is not an Alfs DMF Extensions global preset string.",
	},
	preset_editor_invalid_json = {
		en = "[Preset Editor] Invalid preset JSON",
		ru = "[Preset Editor] Invalid preset JSON",
		["zh-cn"] = "[Preset Editor] Invalid preset JSON",
		["zh-tw"] = "[Preset Editor] Invalid preset JSON",
	},
	preset_editor_invalid_preset_string = {
		en = "This is not an Alfs DMF Extensions preset string.",
		ru = "This is not an Alfs DMF Extensions preset string.",
		["zh-cn"] = "This is not an Alfs DMF Extensions preset string.",
		["zh-tw"] = "This is not an Alfs DMF Extensions preset string.",
	},
	preset_editor_json_unreadable = {
		en = "The JSON string could not be read.",
		ru = "The JSON string could not be read.",
		["zh-cn"] = "The JSON string could not be read.",
		["zh-tw"] = "The JSON string could not be read.",
	},
	preset_editor_level_prefix = {
		en = "Lv ",
		ru = "Lv ",
		["zh-cn"] = "Lv ",
		["zh-tw"] = "Lv ",
	},
	preset_editor_no_mod_settings = {
		en = "The preset does not contain any mod settings.",
		ru = "The preset does not contain any mod settings.",
		["zh-cn"] = "The preset does not contain any mod settings.",
		["zh-tw"] = "The preset does not contain any mod settings.",
	},
	preset_editor_no_preset_settings = {
		en = "The preset does not contain any settings.",
		ru = "The preset does not contain any settings.",
		["zh-cn"] = "The preset does not contain any settings.",
		["zh-tw"] = "The preset does not contain any settings.",
	},
	preset_editor_no_save_settings = {
		en = "This mod has no settings that can be saved as a preset.",
		ru = "This mod has no settings that can be saved as a preset.",
		["zh-cn"] = "This mod has no settings that can be saved as a preset.",
		["zh-tw"] = "This mod has no settings that can be saved as a preset.",
	},
	preset_editor_no_settings_to_save = {
		en = "No mod settings could be saved.",
		ru = "No mod settings could be saved.",
		["zh-cn"] = "No mod settings could be saved.",
		["zh-tw"] = "No mod settings could be saved.",
	},
	preset_editor_not_found = {
		en = "Preset '%s' could not be found.",
		ru = "Preset '%s' could not be found.",
		["zh-cn"] = "Preset '%s' could not be found.",
		["zh-tw"] = "Preset '%s' could not be found.",
	},
	preset_editor_overwrite = {
		en = "Overwrite the existing preset '%s'?",
		ru = "Overwrite the existing preset '%s'?",
		["zh-cn"] = "Overwrite the existing preset '%s'?",
		["zh-tw"] = "Overwrite the existing preset '%s'?",
	},
	preset_editor_overwrite_global = {
		en = "Overwrite the existing global preset '%s'?",
		ru = "Overwrite the existing global preset '%s'?",
		["zh-cn"] = "Overwrite the existing global preset '%s'?",
		["zh-tw"] = "Overwrite the existing global preset '%s'?",
	},
	preset_editor_overwrite_title = {
		en = "Overwrite Preset",
		ru = "Overwrite Preset",
		["zh-cn"] = "Overwrite Preset",
		["zh-tw"] = "Overwrite Preset",
	},
	preset_editor_preset_json_title = {
		en = "Preset JSON",
		ru = "Preset JSON",
		["zh-cn"] = "Preset JSON",
		["zh-tw"] = "Preset JSON",
	},
	preset_editor_preset_name_title = {
		en = "Preset name",
		ru = "Preset name",
		["zh-cn"] = "Preset name",
		["zh-tw"] = "Preset name",
	},
	preset_editor_save_button = {
		en = "Save",
		ru = "Save",
		["zh-cn"] = "Save",
		["zh-tw"] = "Save",
	},
	preset_editor_save_current_global_option = {
		en = "Save current settings as global preset",
		ru = "Save current settings as global preset",
		["zh-cn"] = "Save current settings as global preset",
		["zh-tw"] = "Save current settings as global preset",
	},
	preset_editor_save_current_option = {
		en = "Save current settings as preset",
		ru = "Save current settings as preset",
		["zh-cn"] = "Save current settings as preset",
		["zh-tw"] = "Save current settings as preset",
	},
	preset_editor_save_description = {
		en = "Enter a name for the new preset.",
		ru = "Enter a name for the new preset.",
		["zh-cn"] = "Enter a name for the new preset.",
		["zh-tw"] = "Enter a name for the new preset.",
	},
	preset_editor_save_failed_title = {
		en = "Save Failed",
		ru = "Save Failed",
		["zh-cn"] = "Save Failed",
		["zh-tw"] = "Save Failed",
	},
	preset_editor_save_global_description = {
		en = "Enter a name for the new %s preset.",
		ru = "Enter a name for the new %s preset.",
		["zh-cn"] = "Enter a name for the new %s preset.",
		["zh-tw"] = "Enter a name for the new %s preset.",
	},
	preset_editor_save_global_title = {
		en = "Save Global Preset",
		ru = "Save Global Preset",
		["zh-cn"] = "Save Global Preset",
		["zh-tw"] = "Save Global Preset",
	},
	preset_editor_save_title = {
		en = "Save Preset",
		ru = "Save Preset",
		["zh-cn"] = "Save Preset",
		["zh-tw"] = "Save Preset",
	},
	preset_editor_saved = {
		en = "Saved '%s'.",
		ru = "Saved '%s'.",
		["zh-cn"] = "Saved '%s'.",
		["zh-tw"] = "Saved '%s'.",
	},
	preset_editor_saved_global = {
		en = "Saved global preset '%s'.",
		ru = "Saved global preset '%s'.",
		["zh-cn"] = "Saved global preset '%s'.",
		["zh-tw"] = "Saved global preset '%s'.",
	},
	preset_editor_saved_title = {
		en = "Preset Saved",
		ru = "Preset Saved",
		["zh-cn"] = "Preset Saved",
		["zh-tw"] = "Preset Saved",
	},
	preset_editor_share_description = {
		en = "Share this string with another player for %s.",
		ru = "Share this string with another player for %s.",
		["zh-cn"] = "Share this string with another player for %s.",
		["zh-tw"] = "Share this string with another player for %s.",
	},
	preset_editor_target_mod_missing = {
		en = "The target mod could not be found.",
		ru = "The target mod could not be found.",
		["zh-cn"] = "The target mod could not be found.",
		["zh-tw"] = "The target mod could not be found.",
	},
	preset_editor_wrong_mod = {
		en = "That preset is for '%s', not '%s'.",
		ru = "That preset is for '%s', not '%s'.",
		["zh-cn"] = "That preset is for '%s', not '%s'.",
		["zh-tw"] = "That preset is for '%s', not '%s'.",
	},
	preset_editor_export_failed_title = {
		en = "Export Failed",
		ru = "Export Failed",
		["zh-cn"] = "Export Failed",
		["zh-tw"] = "Export Failed",
	},
	preset_editor_no_export_mods = {
		en = "No mod settings could be exported.",
		ru = "No mod settings could be exported.",
		["zh-cn"] = "No mod settings could be exported.",
		["zh-tw"] = "No mod settings could be exported.",
	},
	preset_editor_applied_title = {
		en = "Preset Applied",
		ru = "Preset Applied",
		["zh-cn"] = "Preset Applied",
		["zh-tw"] = "Preset Applied",
	},
	preset_editor_global_unreadable = {
		en = "The global preset could not be read.",
		ru = "The global preset could not be read.",
		["zh-cn"] = "The global preset could not be read.",
		["zh-tw"] = "The global preset could not be read.",
	},
	settings_profile_title = {
		en = "Settings Profile Available",
		ru = "Доступен профиль настроек",
		["zh-cn"] = "发现设置配置",
		["zh-tw"] = "發現設定設定檔",
	},
	settings_profile_new_description = {
		en = "A settings profile from {#color("
			.. colours.title
			.. ")}'%s'{#reset()} (version {#color("
			.. colours.title
			.. ")}%s{#reset()}) was found. \nApply its settings now?",
		ru = "Найден профиль настроек '%s' версии %s. Применить его глобальные настройки сейчас?",
		["zh-cn"] = "发现来自“%s”的设置配置（版本 %s）。是否立即应用其全局设置？",
		["zh-tw"] = "發現來自「%s」的設定設定檔（版本 %s）。是否立即套用其全域設定？",
	},
	settings_profile_updated_description = {
		en = "The settings profile {#color("
			.. colours.title
			.. ")}'%s'{#reset()} was updated from version {#color("
			.. colours.title
			.. ")}%s{#reset()} to version {#color("
			.. colours.title
			.. ")}%s{#reset()}. \nReapply its settings?",
		ru = "Профиль настроек '%s' обновлён с версии %s до версии %s. Повторно применить его глобальные настройки?",
		["zh-cn"] = "设置配置“%s”已从版本 %s 更新到版本 %s。是否重新应用其全局设置？",
		["zh-tw"] = "設定設定檔「%s」已從版本 %s 更新到版本 %s。是否重新套用其全域設定？",
	},
	settings_profile_accept = {
		en = "Accept",
		ru = "Принять",
		["zh-cn"] = "接受",
		["zh-tw"] = "接受",
	},
	settings_profile_later = {
		en = "Not right now",
		ru = "Не сейчас",
		["zh-cn"] = "暂不",
		["zh-tw"] = "暫不",
	},
	settings_profile_ignore = {
		en = "Ignore",
		ru = "Игнорировать",
		["zh-cn"] = "忽略",
		["zh-tw"] = "忽略",
	},
	settings_profile_accept_tooltip = {
		en = "Apply this settings profile. Settings changed by the profile will be overwritten.",
		ru = "Применить этот профиль настроек сейчас. Настройки, изменённые профилем, будут перезаписаны.",
		["zh-cn"] = "立即应用此设置配置。配置中更改的设置将被覆盖。",
		["zh-tw"] = "立即套用此設定設定檔。設定檔中變更的設定將被覆蓋。",
	},
	settings_profile_later_tooltip = {
		en = "Skip for now. You will be asked again the next time the game loads.",
		ru = "Пропустить этот профиль сейчас. Вы увидите запрос снова при следующей загрузке игры.",
		["zh-cn"] = "暂时跳过此配置。下次加载游戏时会再次询问。",
		["zh-tw"] = "暫時略過此設定檔。下次載入遊戲時會再次詢問。",
	},
	settings_profile_ignore_tooltip = {
		en = "Never show this profile version again. If a newer profile version is installed, you will be asked again.",
		ru = "Больше не показывать эту версию профиля. Новая версия профиля всё равно запросит подтверждение.",
		["zh-cn"] = "不再显示此配置版本。更新版本仍会再次询问。",
		["zh-tw"] = "不再顯示此設定檔版本。更新版本仍會再次詢問。",
	},
	settings_profile_imported_title = {
		en = "Settings Profile Imported",
		ru = "Профиль настроек импортирован",
		["zh-cn"] = "设置配置已导入",
		["zh-tw"] = "設定設定檔已匯入",
	},
	settings_profile_imported_description = {
		en = "Applied the global settings from '%s'.",
		ru = "Применены глобальные настройки из '%s'.",
		["zh-cn"] = "已应用来自“%s”的全局设置。",
		["zh-tw"] = "已套用來自「%s」的全域設定。",
	},
	settings_profile_import_failed_title = {
		en = "Settings Profile Import Failed",
		ru = "Не удалось импортировать профиль настроек",
		["zh-cn"] = "设置配置导入失败",
		["zh-tw"] = "設定設定檔匯入失敗",
	},
	settings_profile_import_failed_description = {
		en = "The settings profile from '%s' could not be read.",
		ru = "Не удалось прочитать профиль настроек '%s'.",
		["zh-cn"] = "无法读取来自“%s”的设置配置。",
		["zh-tw"] = "無法讀取來自「%s」的設定設定檔。",
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
	legend_settings = {
		en = "{#color(" .. colours.title .. ")}Keybind Settings{#reset()}",
		ru = "{#color(" .. colours.title .. ")}Настройки привязок клавиш{#reset()}",
		["zh-cn"] = "{#color(" .. colours.title .. ")}快捷键设置{#reset()}",
		["zh-tw"] = "{#color(" .. colours.title .. ")}快捷鍵設定{#reset()}",
	},
	keybind_reset_tab = {
		en = "Reset tab keybind",
	},
	keybind_reset_tab_tooltip = {
		en = "Choose a hotkey to use as the 'reset tab to default settings' keybind.",
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

		-- adjust tooltip text opacity
		if string.find(key, "_tooltip") then
			for language, text in next, values do
				local rgb = { 144, 155, 136 }

				if rgb ~= nil then
					-- Strip any colour tags applied by a previous pass, otherwise every
					-- call wraps the already-wrapped string again and grows it forever.
					local clean = string.gsub(text, "{#.-}", "")
					local text = apply_color_to_text(clean, rgb[1], rgb[2], rgb[3])

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

for _, action in ipairs(mod._available_aliases) do
	local alias_key = Managers.ui:get_input_alias_key(action, "View")
	local input_text = InputUtils.input_text_for_current_input_device("View", alias_key)
	mod.localisation[action] = { en = input_text }
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
