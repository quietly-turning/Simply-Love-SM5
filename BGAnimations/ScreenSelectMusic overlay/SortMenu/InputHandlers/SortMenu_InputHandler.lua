local sort_wheel = ...

-- this handles user input while in the SortMenu
local input = function(event)
	if not (event and event.PlayerNumber and event.button) then
		return false
	end

	local screen   = SCREENMAN:GetTopScreen()
	local overlay  = screen:GetChild("Overlay")
	local sortmenu = overlay:GetChild("SortMenu")

	SOUND:StopMusic()

	if event.type ~= "InputEventType_Release" then
		if event.GameButton == "MenuRight" or event.GameButton == "MenuDown" then
			sort_wheel:scroll_by_amount(1)
			sortmenu:GetChild("change_sound"):play()
			sortmenu:GetChild("arrow_cursor"):playcommand("Bump")

		elseif event.GameButton == "MenuLeft" or event.GameButton == "MenuUp" then
			sort_wheel:scroll_by_amount(-1)
			sortmenu:GetChild("change_sound"):play()
			sortmenu:GetChild("arrow_cursor"):playcommand("Bump")

		elseif event.GameButton == "Start" then
			sortmenu:GetChild("start_sound"):play()
			local focus = sort_wheel:get_actor_item_at_focus_pos()
			local info  = sort_wheel:get_info_at_focus_pos()

			-- info[1] is a string of top_text like "Sort By", "Change Mode To", or "Feeling Salty?"
			-- info[2] is a string of bottom_text like "Group", "Casual", or "Test Input"
			-- info[3] is a function to be called if the user chooses this row
			if (info[3]) then
				-- some row actions (e.g. add song to player favorites) need a PlayerNumber, so pass that
				-- to all action functions.  most will ignore it, and that's fine.
				info[3](event.PlayerNumber, info)
			end

		elseif event.GameButton == "Back" or event.GameButton == "Select" then
			overlay:queuecommand("DirectInputToEngine")
		end
	end
	return false
end

return input
