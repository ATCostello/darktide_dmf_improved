local mod = get_mod("Alfs_DMF_Extensions")

local UIWidget = require("scripts/managers/ui/ui_widget")

local blueprints = {}

local settings_grid_width = 850
local widget_height = 190

local BAR_WIDTH = 320
local BAR_HEIGHT = 28

local PREVIEW_HEIGHT = 40

-- ############################################################
-- Helpers
-- ############################################################

local function clamp(v)
	return math.clamp(math.floor(v or 0), 0, 255)
end

local function get_value(entry)
	if not entry or not entry.get_function then
		return 255
	end

	local value = entry.get_function(entry)

	return clamp(value)
end

local function set_value(entry, value)
	value = clamp(value)

	if entry.on_activated then
		entry.on_activated(value, entry)
	end

	if entry.changed_callback then
		entry.changed_callback(value)
	end
end

-- ############################################################
-- Slider Pass Builder
-- ############################################################

local function create_slider(name, y, color, label)
	return {
		{
			pass_type = "hotspot",
			content_id = name .. "_hotspot",
			style_id = name .. "_hotspot_style",
		},
		{
			pass_type = "rect",
			style_id = name .. "_bg",
		},
		{
			pass_type = "rect",
			style_id = name .. "_fill",
		},
		{
			pass_type = "text",
			value_id = name .. "_label",
			style_id = name .. "_label_style",
		},
		{
			pass_type = "text",
			value_id = name .. "_value",
			style_id = name .. "_value_style",
		},
	}, {
		[name .. "_hotspot_style"] = {
			offset = { 0, y, 0 },
			size = { BAR_WIDTH, BAR_HEIGHT },
		},
		[name .. "_label"] = label,
		[name .. "_value"] = "0",
	}, {
		[name .. "_bg"] = {
			color = { 255, 30, 30, 30 },
			offset = { 0, y, 0 },
			size = { BAR_WIDTH, BAR_HEIGHT },
		},

		[name .. "_fill"] = {
			color = color,
			offset = { 0, y, 1 },
			size = { 0, BAR_HEIGHT },
		},

		[name .. "_label_style"] = {
			font_type = "proxima_nova_bold",
			horizontal_alignment = "left",
			vertical_alignment = "center",
			font_size = 24,
			text_color = { 255, 255, 255, 255 },
			offset = { -40, y - 2, 2 },
		},

		[name .. "_value_style"] = {
			font_type = "proxima_nova_bold",
			horizontal_alignment = "left",
			vertical_alignment = "center",
			font_size = 24,
			text_color = { 255, 255, 255, 255 },
			offset = { BAR_WIDTH + 12, y - 2, 2 },
		},
	}
end

-- ############################################################
-- Build Passes
-- ############################################################

local passes = {}
local content = {}
local style = {}

local sliders = {
	{
		name = "r",
		y = 0,
		color = { 255, 255, 60, 60 },
		label = "R",
	},
	{
		name = "g",
		y = 50,
		color = { 255, 60, 255, 60 },
		label = "G",
	},
	{
		name = "b",
		y = 100,
		color = { 255, 60, 140, 255 },
		label = "B",
	},
}

for _, slider in ipairs(sliders) do
	local p, c, s = create_slider(slider.name, slider.y, slider.color, slider.label)

	for _, pass in ipairs(p) do
		table.insert(passes, pass)
	end

	for k, v in pairs(c) do
		content[k] = v
	end

	for k, v in pairs(s) do
		style[k] = v
	end
end

table.insert(passes, {
	pass_type = "rect",
	style_id = "preview_style",
})

style.preview_style = {
	color = { 255, 255, 255, 255 },
	offset = { 0, 150, 0 },
	size = { BAR_WIDTH, PREVIEW_HEIGHT },
}

-- ############################################################
-- Blueprint
-- ############################################################

blueprints = {
	rgb_widget = {
		size = {
			settings_grid_width,
			widget_height,
		},

		pass_template = passes,
		content = content,
		style = style,

		init = function(parent, widget, entry)
			local content = widget.content

			content.entry = entry
		end,

		update = function(parent, widget, input_service, dt, t)
			local content = widget.content
			local style = widget.style

			local r = get_value(content.r_entry)
			local g = get_value(content.g_entry)
			local b = get_value(content.b_entry)

			content.r_value = tostring(r)
			content.g_value = tostring(g)
			content.b_value = tostring(b)

			style.r_fill.size[1] = (r / 255) * BAR_WIDTH
			style.g_fill.size[1] = (g / 255) * BAR_WIDTH
			style.b_fill.size[1] = (b / 255) * BAR_WIDTH

			style.preview_style.color = {
				255,
				r,
				g,
				b,
			}

			local cursor = input_service:get("cursor")

			local function handle_drag(hotspot, entry, bar_style)
				if not hotspot or not hotspot.is_held or not cursor then
					return
				end

				local scenegraph_id = widget.scenegraph_id
				local position = parent:_scenegraph_world_position(scenegraph_id)

				local widget_x = position[1]
				local bar_x = widget_x + bar_style.offset[1]

				local local_x = math.clamp(cursor[1] - bar_x, 0, BAR_WIDTH)

				local value = math.floor((local_x / BAR_WIDTH) * 255)

				set_value(entry, value)
			end

			handle_drag(content.r_hotspot, content.r_entry, style.r_bg)
			handle_drag(content.g_hotspot, content.g_entry, style.g_bg)
			handle_drag(content.b_hotspot, content.b_entry, style.b_bg)

			return true
		end,
	},
}

return blueprints
