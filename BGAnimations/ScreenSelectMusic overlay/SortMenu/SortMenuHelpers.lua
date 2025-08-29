local sort_wheel = ...

------------------------------------------------------------
-- first, helper functions that take the player out of the SortMenu and either
-- show them a different overlay (like TestInput) or take them to a different
-- screen altogether (like ShowDownloads)

local function ShowSongSearch()
	SCREENMAN:GetTopScreen():GetChild("Overlay"):queuecommand("DirectInputToEngineForSongSearch")
end

local function ShowTestInput()
	SCREENMAN:GetTopScreen():GetChild("Overlay"):queuecommand("DirectInputToTestInput")
end

local function ShowLeaderboard()
	SCREENMAN:GetTopScreen():GetChild("Overlay"):queuecommand("DirectInputToLeaderboard")
end

local function ShowDownloads()
	local overlay = SCREENMAN:GetTopScreen():GetChild("Overlay")
	-- Make sure we cancel the request if it's active before trying to switch screens.
	-- This prevents the "Stale ActorFrame" error.
	overlay:GetChild("PaneDisplayMaster"):GetChild("GetScoresRequester"):playcommand("Cancel")
	overlay:playcommand("DirectInputToEngine")
	SCREENMAN:SetNewScreen("ScreenViewDownloads")
end

local function ShowPracticeMode()
	local screen = SCREENMAN:GetTopScreen()
	screen:SetNextScreenName("ScreenPractice")
	screen:StartTransitioningScreen("SM_GoToNextScreen")
end

local function ShowSelectProfile()
	local screen = SCREENMAN:GetTopScreen()
	SL.Global.FastProfileSwitchInProgress = true
	-- If a memory card is inserted we can't be on that profile's songs when switching profiles
	-- as the profile is temporarily unloaded when finishing the screen.
	if MEMCARDMAN:GetCardState(PLAYER_1) ~= 'MemoryCardState_none' or MEMCARDMAN:GetCardState(PLAYER_2) ~= 'MemoryCardState_none' then
		screen:GetMusicWheel():SetOpenSection("");
	end
	-- Make sure we save any currently active profiles before potentially switching
	-- to different ones.
	GAMESTATE:SaveProfiles()
	PROFILEMAN:SaveMachineProfile()
	screen:GetChild("Overlay"):queuecommand("DirectInputToEngineForSelectProfile")
end

local function ShowSetSummary()
	local screen = SCREENMAN:GetTopScreen()
	screen:SetNextScreenName("ScreenEvaluationSummarySet")
	screen:StartTransitioningScreen("SM_GoToNextScreen")
end

local function ShowLoadNewSongs()
	local overlay = SCREENMAN:GetTopScreen():GetChild("Overlay")
	-- Make sure we cancel the request if it's active before trying to switch screens.
	-- This prevents the "Stale ActorFrame" error.
	overlay:GetChild("PaneDisplayMaster"):GetChild("GetScoresRequester"):playcommand("Cancel")
	overlay:playcommand("DirectInputToEngine")
	SCREENMAN:SetNewScreen("ScreenReloadSongsSSM")
end


------------------------------------------------------------
-- next, a collection of helper functions that *change* something
-- about ITGmania gamestate (like ChangeStyle) or ScreenSelectMusic
-- (like ChangeMode) or its MusicWheel (like ChangeSort)

-- the player wants to change the MusicWheel's song sort, for example from "Group" to "BPM"
local function ChangeSort()
	local focus = sort_wheel:get_actor_item_at_focus_pos()
	MESSAGEMAN:Broadcast('Sort', { order = focus.sort_by })
	MESSAGEMAN:Broadcast('ResetHeaderText')
	SCREENMAN:GetTopScreen():GetChild("Overlay"):queuecommand("DirectInputToEngine")
end

-- a specific player wants to change the MusicWheel's sort to "SortOrder_Preferred"
-- which is english-localized in Simply-Love as their "favorites"
local function ChangeToPlayerFavoritesSort(pn)
	-- Only allow sorting by favorites if there are favorites available
	if (#SL[ToEnumShortString(pn)].Favorites <= 0) then
		SM( THEME:GetString("ScreenSelectMusic", "NoPlayerFavoritesAvailable"):format(ToEnumShortString(pn)) )
		return
	end

	-- set the MusicWheel's "preferred sort" to this player's favorites.txt
	SONGMAN:SetPreferredSongs(getFavoritesPath(pn), --[[isAbsolute=]]true)

	if SONGMAN:GetPreferredSortSongs() then
		local screen  = SCREENMAN:GetTopScreen()
		local overlay = screen:GetChild("Overlay")
		overlay:queuecommand("DirectInputToEngine")
		screen:GetMusicWheel():ChangeSort("SortOrder_Preferred")
	else
		SM( THEME:GetString("ScreenSelectMusic", "NoPlayerFavoritesAvailable"):format(ToEnumShortString(pn)) )
	end
end


-- the player wants to change modes, for example from ITG to Casual
local function ChangeMode()
	local screen   = SCREENMAN:GetTopScreen()
	local sortmenu = screen:GetChild("Overlay"):GetChild("SortMenu")
	local focus    = sort_wheel:get_actor_item_at_focus_pos()
	SL.Global.GameMode = focus.change

	for player in ivalues(GAMESTATE:GetHumanPlayers()) do
		ApplyMods(player)       -- global function from ./Scripts/SL-Helpers.lua
	end
	SetGameModePreferences()  -- global function from ./Scripts/SL-Helpers.lua
	THEME:ReloadMetrics()
	-- Broadcast that the SL GameMode has changed
	-- SSM's header will update its text and highscore names in the PaneDisplays will refresh
	MESSAGEMAN:Broadcast("SLGameModeChanged")
	-- Reload the SortMenu's available options and queue "DirectInputToEngine"
	-- to return input from Lua back to the engine and hide the SortMenu from view
	sortmenu:playcommand("AssessAvailableChoices"):queuecommand("DirectInputToEngine")
	-- the player is switching to casual mode which uses a different SelectMusic screen
	if focus.change == "Casual" then
		screen:SetNextScreenName("ScreenSelectMusicCasual")
		screen:StartTransitioningScreen("SM_GoToNextScreen")
	end
end

-- the player wants to change styles, for example from single to double
local function ChangeStyle()
	local screen  = SCREENMAN:GetTopScreen()
	local overlay = screen:GetChild("Overlay")
	-- If the MenuTimer is in effect, we need to make sure the current number of seconds
	-- remaining is preserved so we can reinstate it later. ShowPressStartForOptions
	-- will save the current number of seconds before transitioning to the next screen.
	if PREFSMAN:GetPreference("MenuTimer") then
		overlay:playcommand("ShowPressStartForOptions")
	end
	-- Get the style we want to change to
	local new_style = focus.change:lower()
	-- accommodate techno game
	if GAMESTATE:GetCurrentGame():GetName() == "techno" then new_style = new_style .. "8" end
	-- set it in the engine
	GAMESTATE:SetCurrentStyle(new_style)
	-- Make sure we cancel the request if it's active before trying to switch screens.
	-- This prevents the "Stale ActorFrame" error.
	overlay:GetChild("PaneDisplayMaster"):GetChild("GetScoresRequester"):playcommand("Cancel")
	-- finally, reload the screen
	screen:SetNextScreenName("ScreenReloadSSM")
	screen:StartTransitioningScreen("SM_GoToNextScreen")
end

-- a specific player wants to add the current song from the MusicWheel as a favorite to their profile
local function AddSongToFavorites(pn)
	addOrRemoveFavorite(pn)  -- global function from ./Scripts/SL-FavoritesHandler.lua

	local screen = SCREENMAN:GetTopScreen()
	local overlay    = screen:GetChild("Overlay")
	local musicwheel = screen:GetMusicWheel()

	-- Nudge the wheel a bit so that that the icon is correctly updated.
	overlay:queuecommand("DirectInputToEngine")
	musicwheel:Move(1)
	musicwheel:Move(-1)
	musicwheel:Move(0)
end

local function SortByPlayerPlaylist(pn, info)
	-- info[2] is the row's bottom_text, in this case the playlist name
	local playlist_name = info[2]
	local profileDir = PROFILEMAN:GetProfileDir(ProfileSlot[PlayerNumber:Reverse()[pn] + 1])

	-- set the MusicWheel's "preferred sort" to the chosen player-profile playlist
	SONGMAN:SetPreferredSongs(profileDir .."Playlists/" .. playlist_name .. ".txt", true);

	if SONGMAN:GetPreferredSortSongs() then
		local screen  = SCREENMAN:GetTopScreen()
		local overlay = screen:GetChild("Overlay")
		overlay:queuecommand("DirectInputToEngine")
		screen:GetMusicWheel():ChangeSort("SortOrder_Preferred")
	end
end

local function SortByMachinePlaylist(pn, info)
	-- info[2] is the row's bottom_text, in this case the playlist name
	local playlist_name = info[2]
	local path = THEME:GetPathO("", "Playlists/" .. playlist_name .. ".txt")

	-- set the MusicWheel's "preferred sort" to the chosen machine-profile playlist
	SONGMAN:SetPreferredSongs(path, true);

	if SONGMAN:GetPreferredSortSongs() then
		local screen  = SCREENMAN:GetTopScreen()
		local overlay = screen:GetChild("Overlay")
		overlay:queuecommand("DirectInputToEngine")
		screen:GetMusicWheel():ChangeSort("SortOrder_Preferred")
	end
end

-- Only display the View Downloads option if we're connected to
-- GrooveStats and Auto-Downloads are enabled.
local function DownloadsExist()
    return SL.GrooveStats.IsConnected and ThemePrefs.Get("AutoDownloadUnlocks")
end


------------------------------------------------------------
-- then, a collection of helper functions that return one or more
-- rows to display to the player in the SortMenu.
-- sometimes it's easier to define a hardcoded list of rows in SortMenuRows.lua
-- sometimes it's easier to write a function that conditionally returns a collection of rows.
-- a SortMenu "row" is structured like
--   {{ top_text, bottom_text, action_if_chosen }, optional_condition_to_be_visible }

-- returns one row for one player's favorites.txt
local function AddFavoritesRow(pn)
		local path = getFavoritesPath(pn)
		if FILEMAN:DoesFileExist(path) then
				return {"MixTape", "Preferred", function() ChangeToPlayerFavoritesSort(pn) end}
		end

    return nil
end

-- returns an array of rows for machine playlists, player playlists, and player favorites
local AddPlaylistsRows = function()
	local playlists = {}

	-- First add the machine playlists
	-- Get the name of every file in the Other/Playlists directory
	local files = FILEMAN:GetDirListing(THEME:GetCurrentThemeDirectory().."Other/Playlists/")
	-- Add each file to the wheel options
	for i=1, #files do
		local file = files[i]
		if file:match("%.txt$") then
			local playlist = file:gsub("%.txt$", "")
			table.insert(playlists, {{"MachinePlaylist", playlist, function(pn, info) SortByMachinePlaylist(pn, info) end}})
		end
	end

	-- Then add the personal playlists
	for player in ivalues(GAMESTATE:GetHumanPlayers()) do
		local playlistPath = PROFILEMAN:GetProfileDir(ProfileSlot[PlayerNumber:Reverse()[player] + 1]) .."/Playlists/";
		local playerPlaylists = FILEMAN:GetDirListing(playlistPath)
		for i=1, #playerPlaylists do
			local file = playerPlaylists[i]
			if file:match("%.txt$") then
				local playlist = file:gsub("%.txt$", "")
				table.insert(playlists, {{"PersonalPlaylist", playlist, function(pn, info) SortByPlayerPlaylist(pn, info) end}})
			end
		end
	end

	-- Favorites are basically a playlist so include those too
	for player in ivalues(GAMESTATE:GetHumanPlayers()) do
		table.insert(playlists, {AddFavoritesRow(player)})
	end
	return playlists
end

-- returns an array of rows for changing game-style, like from single to double.
-- the rows returned by this function will vary depending on current gamestate
local GetChangeableStylesRows = function()
	local style = GAMESTATE:GetCurrentStyle():GetName():gsub("8", "")
	local available_styles = {}

	-- Allow players to switch from single to double and from double to single (and etc.)
	-- but only present these options if Joint Double or Joint Premium is enabled
	-- and we're not in "AutoSetStyle" mode (all styles presented simultaneously like PIU does)
	if THEME:GetMetric("Common", "AutoSetStyle") == false
	and not (PREFSMAN:GetPreference("Premium") == "Premium_Off"
	and GAMESTATE:GetCoinMode() == "CoinMode_Pay") then

		if style == "single" then
			table.insert(available_styles, {"ChangeStyle", "Double", ChangeStyle})
			if ThemePrefs.Get("AllowDanceSolo") then
				table.insert(available_styles, {"ChangeStyle", "Solo", ChangeStyle})
			end

		elseif style == "double" then
			table.insert(available_styles, {"ChangeStyle", "Single", ChangeStyle})
			if ThemePrefs.Get("AllowDanceSolo") then
				table.insert(available_styles, {"ChangeStyle", "Solo", ChangeStyle})
			end

		elseif style == "solo" then
			table.insert(available_styles, {"ChangeStyle", "Single", ChangeStyle})
			table.insert(available_styles, {"ChangeStyle", "Double", ChangeStyle})

		-- Couple doesn't have enough content for people to be able to switch into it
		-- However, if for some reason you end up in couples mode, you should be able to
		-- escape
		elseif style == "couple" then
			table.insert(available_styles, {"ChangeStyle", "Versus", ChangeStyle})

		-- Routine is not ready for use yet, but it might be soon.
		-- This can be uncommented at that time to allow switching from versus into routine.
		-- elseif style == "versus" then
		-- 	table.insert(available_styles, {"ChangeStyle", "Routine", ChangeStyle})
		end
		return available_styles
	end
end

------------------------------------------------------------

return {
  ShowSongSearch,
  ShowTestInput,
  ShowLeaderboard,
  ShowDownloads,
  ShowPracticeMode,
  ShowSelectProfile,
  ShowSetSummary,
  ShowLoadNewSongs,
  ChangeSort,
  ChangeMode,
  ChangeStyle,
  AddSongToFavorites,
  AddFavoritesRow,
  AddPlaylistsRows,
  GetChangeableStylesRows,
  DownloadsExist
}