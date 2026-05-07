local mod = get_mod("dmf_settings_improved")

local scroll_settings = {}

mod._saveScrollPosition = function(self)
	local grid = self._navigation_grids
	if not (grid and grid[2] and grid[2]._scrollbar_widget) then
		return
	end

	local scrollbar_widget = grid[2]._scrollbar_widget

	-- set default status if not already initialised
	if not scroll_settings[mod.current_category] then
		scroll_settings[mod.current_category] = {
			last_scroll_amount = 0,
		}
	end

	-- grab the current mod's scroll amount
	local last_scroll_amount = scroll_settings[mod.current_category].last_scroll_amount

	--  Detect category switch, and set current scroll to saved amount
	if mod.last_category ~= mod.current_category or mod.last_category == nil then
		if last_scroll_amount then
			scrollbar_widget.content.scroll_value = last_scroll_amount
			scrollbar_widget.content.value = last_scroll_amount
		end
	end

	--  Save current scrolled amount
	if grid[2]._scroll_progress and last_scroll_amount ~= grid[2]._scroll_progress then
		scroll_settings[mod.current_category] = {
			last_scroll_amount = grid[2]._scroll_progress,
		}
	end
end
