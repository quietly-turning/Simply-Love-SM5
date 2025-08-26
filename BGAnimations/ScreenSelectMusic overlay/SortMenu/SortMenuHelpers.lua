local AddFavorites = function()
    for player in ivalues(GAMESTATE:GetHumanPlayers()) do
        local path = getFavoritesPath(player)
        if FILEMAN:DoesFileExist(path) then
            return {{"MixTape", "Preferred"}}
        end
    end
    return nil
end


-- Only display the View Downloads option if we're connected to
-- GrooveStats and Auto-Downloads are enabled.
local DownloadsExist = function()
    return SL.GrooveStats.IsConnected and ThemePrefs.Get("AutoDownloadUnlocks")
end



local AddPlayerSortOptions = function()
    local player_sort_options = {}
    for player in ivalues(GAMESTATE:GetHumanPlayers()) do
        if PROFILEMAN:IsPersistentProfile(player) then
            table.insert(player_sort_options, {"SortBy", "Top" .. ToEnumShortString(player) .. "Grades"})
        end
    end
    return player_sort_options
end



local AddPlaylists = function()

	-- First add the machine playlists
	local player_sort_options = {}
	-- Get the name of every file in the Other/Playlists directory
	local files = FILEMAN:GetDirListing(THEME:GetCurrentThemeDirectory().."Other/Playlists/")
	-- Add each file to the wheel options
	for i=1, #files do
		local file = files[i]
		if file:match("%.txt$") then
			local playlist = file:gsub("%.txt$", "")
			table.insert(player_sort_options, {{"MachinePlaylist", playlist}})
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
				table.insert(player_sort_options, {{"PersonalPlaylist", playlist}})
			end
		end
	end

	-- Favorites are basically a playlist so include those too
	for player in ivalues(GAMESTATE:GetHumanPlayers()) do
		local path = getFavoritesPath(player)
		if FILEMAN:DoesFileExist(path) then
			table.insert(player_sort_options, {{"MixTape", "Preferred"}})
			break
		end
	end
	return player_sort_options
end


local GetChangeableStyles = function(style)
	local available_styles = {}
	-- Allow players to switch from single to double and from double to single
	-- but only present these options if Joint Double or Joint Premium is enabled
	-- and we're not in "AutoSetStyle" mode (all styles presented simultaneously like PIU does)

	if THEME:GetMetric("Common", "AutoSetStyle") == false
	and not (PREFSMAN:GetPreference("Premium") == "Premium_Off"
	and GAMESTATE:GetCoinMode() == "CoinMode_Pay") then
		if style == "single" then
			table.insert(available_styles, {"ChangeStyle", "Double"})
			if ThemePrefs.Get("AllowDanceSolo") then
				table.insert(available_styles, {"ChangeStyle", "Solo"})
			end
		elseif style == "double" then
			table.insert(available_styles, {"ChangeStyle", "Single"})
			if ThemePrefs.Get("AllowDanceSolo") then
				table.insert(available_styles, {"ChangeStyle", "Solo"})
			end
		elseif style == "solo" then
			table.insert(available_styles, {"ChangeStyle", "Single"})
			table.insert(available_styles, {"ChangeStyle", "Double"})
		-- Couple doesn't have enough content for people to be able to switch into it
		-- However, if for some reason you end up in couples mode, you should be able to
		-- escape
		elseif style == "couple" then
			table.insert(available_styles, {"ChangeStyle", "Versus"})
		-- Routine is not ready for use yet, but it might be soon.
		-- This can be uncommented at that time to allow switching from versus into routine.
		-- elseif style == "versus" then
		-- 	table.insert(available_styles, {"ChangeStyle", "Routine"})
		end
		return available_styles
	end
end

return {
  AddFavorites,
  DownloadsExist,
  AddPlayerSortOptions,
  AddPlaylists,
  GetChangeableStyles
}