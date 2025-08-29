local sort_wheel, wheel_options = unpack(...)

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
				info[3](event.PlayerNumber)
			end

			if focus.kind == "PersonalPlaylist" then
				SM(focus.new_overlay)
				local profileDir = PROFILEMAN:GetProfileDir(ProfileSlot[PlayerNumber:Reverse()[event.PlayerNumber] + 1])
				SONGMAN:SetPreferredSongs(profileDir .."Playlists/" .. focus.new_overlay .. ".txt", true);
				if SONGMAN:GetPreferredSortSongs() then
					overlay:queuecommand("DirectInputToEngine")
					screen:GetMusicWheel():ChangeSort("SortOrder_Preferred")
				end

			elseif focus.kind == "MachinePlaylist" then
				local path = THEME:GetPathO("", "Playlists/" .. focus.new_overlay .. ".txt")
				SONGMAN:SetPreferredSongs(path, true);
				if SONGMAN:GetPreferredSortSongs() then
					overlay:queuecommand("DirectInputToEngine")
					screen:GetMusicWheel():ChangeSort("SortOrder_Preferred")
				end


			-- the player has selected a choice that transfers them out of
			-- the SortMenu modal dialog to a different modal dialog
			elseif focus.new_overlay then

				if focus.new_overlay == "Preferred" then
					-- Only allow sorting by favorites if there are favorites available
					if (#SL[ToEnumShortString(event.PlayerNumber)].Favorites > 0) then
						-- The 2nd argument, isAbsolute, is ITGmania 0.6.0 specific. It
						-- allows absolute paths to be used for the favorites file which is
						-- how it works to load from the profile directory.
						SONGMAN:SetPreferredSongs(getFavoritesPath(event.PlayerNumber), --[[isAbsolute=]]true);
						if SONGMAN:GetPreferredSortSongs() then
							overlay:queuecommand("DirectInputToEngine")
							screen:GetMusicWheel():ChangeSort("SortOrder_Preferred")
						else
							SM(ToEnumShortString(event.PlayerNumber).." has no favorites!")
						end
					else
						SM("No Favorites Available")
					end
				end
			end

		elseif event.GameButton == "Back" or event.GameButton == "Select" then
			overlay:queuecommand("DirectInputToEngine")
		end
	end
	return false
end

return input
