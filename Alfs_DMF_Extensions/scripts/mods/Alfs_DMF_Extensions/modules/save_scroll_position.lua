local mod = get_mod("Alfs_DMF_Extensions")

local scroll_settings = {}

mod._saveScrollPosition = function(self)
	local grid = self._navigation_grids
	if not (grid and grid[2] and grid[2]._scrollbar_widget) then
		return
	end

	local scrollbar_widget = grid[2]._scrollbar_widget
	local category = mod.current_category

	if not scroll_settings[category] then
		scroll_settings[category] = {
			last_scroll_amount = 0,
		}
	end

	local saved = scroll_settings[category]
	local last_scroll_amount = saved.last_scroll_amount

	if mod.last_category ~= category or mod.last_category == nil then
		if last_scroll_amount then
			scrollbar_widget.content.scroll_value = last_scroll_amount
			scrollbar_widget.content.value = last_scroll_amount
		end
		return
	end

	local current_scroll = grid[2]._scroll_progress
	if current_scroll and last_scroll_amount ~= current_scroll then
		saved.last_scroll_amount = current_scroll
	end
end
