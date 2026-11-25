local mod = get_mod("Alfs_DMF_Extensions")
mod.version = "2.0.9"
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
		ru = "Пресеты...",
		["zh-cn"] = "预设...",
		["zh-tw"] = "預設...",
	},
	preset_editor_tooltip = {
		en = "Save, load, export, and import presets for this mod.",
		ru = "Сохранение, загрузка, экспорт и импорт пресетов этого мода.",
		["zh-cn"] = "保存、加载、导出和导入此模组的预设。",
		["zh-tw"] = "儲存、載入、匯出和匯入此模組的預設。",
	},
	preset_editor_title = {
		en = "Preset Editor",
		ru = "Редактор пресетов",
		["zh-cn"] = "预设编辑器",
		["zh-tw"] = "預設編輯器",
	},
	preset_editor_description = {
		en = "Saved presets for %s.",
		ru = "Сохранённые пресеты для %s.",
		["zh-cn"] = "%s 的已保存预设。",
		["zh-tw"] = "%s 的已儲存預設。",
	},
	preset_editor_all_mods = {
		en = "All Mod Options",
		ru = "Все настройки модов",
		["zh-cn"] = "所有模组选项",
		["zh-tw"] = "所有模組選項",
	},
	preset_editor_global_title = {
		en = "Global Presets",
		ru = "Глобальные пресеты",
		["zh-cn"] = "全局预设",
		["zh-tw"] = "全域預設",
	},
	preset_editor_global_description = {
		en = "Saved presets for all mod options.",
		ru = "Сохранённые пресеты для всех настроек модов.",
		["zh-cn"] = "所有模组选项的已保存预设。",
		["zh-tw"] = "所有模組選項的已儲存預設。",
	},
	preset_editor_global_tooltip = {
		en = "Save, load, export, and import presets for all mods.",
		ru = "Сохранение, загрузка, экспорт и импорт пресетов для всех модов.",
		["zh-cn"] = "保存、加载、导出和导入所有模组的预设。",
		["zh-tw"] = "儲存、載入、匯出和匯入所有模組的預設。",
	},
	preset_editor_presets = {
		en = "Presets",
		ru = "Пресеты",
		["zh-cn"] = "预设",
		["zh-tw"] = "預設",
	},
	preset_editor_no_presets = {
		en = "No saved presets yet.",
		ru = "Сохранённых пресетов пока нет.",
		["zh-cn"] = "尚无已保存的预设。",
		["zh-tw"] = "尚無已儲存的預設。",
	},
	preset_editor_selected = {
		en = "Selected preset: %s",
		ru = "Выбранный пресет: %s",
		["zh-cn"] = "已选预设：%s",
		["zh-tw"] = "已選預設：%s",
	},
	preset_editor_apply = {
		en = "Apply selected preset",
		ru = "Применить выбранный пресет",
		["zh-cn"] = "应用所选预设",
		["zh-tw"] = "套用所選預設",
	},
	preset_editor_save = {
		en = "Save current settings",
		ru = "Сохранить текущие настройки",
		["zh-cn"] = "保存当前设置",
		["zh-tw"] = "儲存目前設定",
	},
	preset_editor_import = {
		en = "Import preset JSON",
		ru = "Импорт JSON пресета",
		["zh-cn"] = "导入预设 JSON",
		["zh-tw"] = "匯入預設 JSON",
	},
	preset_editor_export = {
		en = "Export selected preset",
		ru = "Экспортировать выбранный пресет",
		["zh-cn"] = "导出所选预设",
		["zh-tw"] = "匯出所選預設",
	},
	preset_editor_export_current = {
		en = "Export current settings",
		ru = "Экспортировать текущие настройки",
		["zh-cn"] = "导出当前设置",
		["zh-tw"] = "匯出目前設定",
	},
	preset_editor_delete = {
		en = "Delete selected preset",
		ru = "Удалить выбранный пресет",
		["zh-cn"] = "删除所选预设",
		["zh-tw"] = "刪除所選預設",
	},
	preset_editor_assign = {
		en = "Assign to characters",
		ru = "Назначить персонажам",
		["zh-cn"] = "分配给角色",
		["zh-tw"] = "分配給角色",
	},
	preset_editor_character_hint = {
		en = "Auto-apply '%s' when these characters are selected.",
		ru = "Автоматически применять '%s' при выборе этих персонажей.",
		["zh-cn"] = "选择这些角色时自动应用“%s”。",
		["zh-tw"] = "選擇這些角色時自動套用「%s」。",
	},
	preset_editor_back = {
		en = "Back",
		ru = "Назад",
		["zh-cn"] = "返回",
		["zh-tw"] = "返回",
	},
	preset_editor_close = {
		en = "Close",
		ru = "Закрыть",
		["zh-cn"] = "关闭",
		["zh-tw"] = "關閉",
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
