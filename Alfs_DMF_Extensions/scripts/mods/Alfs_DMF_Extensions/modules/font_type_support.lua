local mod = get_mod("Alfs_DMF_Extensions")
local UIFontSettings = require("scripts/managers/ui/ui_font_settings")

local FONT_TAG_PATTERN = "{#font%(([^)]+)%)}"

local function stripFontTag(text)
	return text and string.gsub(text, FONT_TAG_PATTERN, "") or text
end

local function extractFontName(text)
	return string.match(text, FONT_TAG_PATTERN)
end

local _settings_by_font_type = nil

local function ensureSettingsByFontTypeCache()
	if _settings_by_font_type then
		return
	end
	_settings_by_font_type = {}
	for name, settings in pairs(UIFontSettings) do
		if type(settings) == "table" and settings.font_type then
			if not _settings_by_font_type[settings.font_type] then
				_settings_by_font_type[settings.font_type] = settings
			end
		end
	end
end

local function lookupFontSettings(font_name)
	local settings = UIFontSettings[font_name]
	if settings then
		return settings
	end
	ensureSettingsByFontTypeCache()
	return _settings_by_font_type[font_name]
end

local function applyFontToStyle(text_style, font_name)
	local font_settings = lookupFontSettings(font_name)
	text_style.font_type = font_settings and font_settings.font_type or font_name
end

local CONTENT_STYLE_MAP = {
	{ content_key = "text", style_key = "list_header" },
	{ content_key = "value_text", style_key = "text" },
}

mod._addFontSupport = function(self, dt, t, input_service)
	local category = mod.current_category
	if not category then
		return
	end

	local widgets = self._settings_category_widgets and self._settings_category_widgets[category]
	if not widgets then
		return
	end

	for i = 1, #widgets do
		local row = widgets[i]
		local widget = row.widget
		if not widget then
			return
		end

		local content = widget.content
		local style = widget.style
		local widget_type = widget.type

		for _, mapping in ipairs(CONTENT_STYLE_MAP) do
			local text = content[mapping.content_key]
			if text and type(text) == "string" then
				local font_name = extractFontName(text)
				if font_name then
					local text_style = style[mapping.style_key]
					if text_style then
						applyFontToStyle(text_style, font_name)
						content[mapping.content_key] = stripFontTag(text)
					end
				end
			end
		end

		if widget_type == "dropdown" then
			local num_visible = content.num_visible_options or 1
			for idx = 1, num_visible do
				local content_key = "option_text_" .. idx
				local style_key = "option_text_" .. idx
				local text = content[content_key]
				if text and type(text) == "string" then
					local font_name = extractFontName(text)
					if font_name then
						local text_style = style[style_key]
						if text_style then
							applyFontToStyle(text_style, font_name)
							content[content_key] = stripFontTag(text)
						end
					end
				end
			end
		end
	end
end
