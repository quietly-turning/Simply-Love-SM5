-- This handles user input while in the Leaderboard overlay.
local function input(event)
	if not (event and event.PlayerNumber and event.button) then
		return false
	end
	-- Don't handle input for a non-joined player.
	if not GAMESTATE:IsSideJoined(event.PlayerNumber) then
		return false
	end

	SOUND:StopMusic()

	local screen   = SCREENMAN:GetTopScreen()
	local overlay  = screen:GetChild("Overlay")

	-- Broadcast event data using MESSAGEMAN for the Leaderboard overlay to listen for.
	if event.type ~= "InputEventType_Repeat" then
		MESSAGEMAN:Broadcast("LeaderboardInputEvent", event)
	end

	-- Pressing Start or Back (typically Esc on a keyboard) will queue "DirectInputToEngine"
	-- but only if the event.type is not a Release.
	-- As soon as the Leaderboard is activated via the SortMenu, the player is likely still holding Start
	-- and will soon release it to start testing their input, which would inadvertently close the Leaderboard.
	if (event.GameButton == "Start" or event.GameButton == "Back") and event.type ~= "InputEventType_Release" then
		overlay:queuecommand("DirectInputToEngine")
	end

	return false
end

return input