local mod = get_mod("Alfs_DMF_Extensions")

mod._addScrollableDropdown = function(self, dt, t, input_service)
	if not self._close_selected_setting then
		return
	end

	local widget = self._selected_settings_widget

	if not widget or widget.type ~= "dropdown" then
		return
	end

	local content = widget.content

	if not content then
		return
	end

	local hotspot = content.scrollbar_hotspot

	if hotspot and (hotspot.is_hover or content.drag_active) and input_service:get("left_hold") then
		self._close_selected_setting = false
	end
end
