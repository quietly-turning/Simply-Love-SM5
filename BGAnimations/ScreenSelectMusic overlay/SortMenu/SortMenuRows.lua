local  ShowSongSearch, ShowTestInput, ShowLeaderboard, ShowDownloads, ShowPracticeMode, ShowSelectProfile, ShowSetSummary, ShowLoadNewSongs, ChangeSort, ChangeMode, ChangeStyle, AddSongToFavorites, AddFavoritesRow, AddPlaylistsRows, GetChangeableStylesRows, DownloadsExist = unpack(LoadActor("./SortMenuHelpers.lua", ...))

------------------------------------------------------------
-- `wheel_options` is the table that defines the SortMenu's choices
-- children row structure is:
--   { {top_text, bottom_text, action_if_chosen}, condition_to_be_visible }
--
-- top_text is a string
-- bottom_text is a string
-- action_if_chosen is a reference to a function
-- condition_to_be_visible can be either:
--    • statement that evaluates to a boolean,
--    • function that returns a boolean
--
-- top_text and bottom_text are required
-- action_if_chosen is optional
--    • it's preferred to define the action in this file
--    • however, some actions need the PlayerNumber from the input_event
--      and must be handled in SortMenu_InputHandler
-- condition_to_be_visible is optional, and handled as true if absent

local wheel_options = {
	{
		name="CategoryCommon",
		open=true,
		children={
			{ {"SortBy", "Group",  ChangeSort} },
			{ {"SortBy", "Title",  ChangeSort} },
			{ {"SortBy", "Recent", ChangeSort} },
			-- Casual players often accidentally choose ITG mode and an experienced player in the area may notice this
			-- and offer to switch them back to Casual mode using this option in the SortMenu.
			{ {"ChangeMode", "Casual",       ChangeMode},         SL.Global.Stages.PlayedThisGame == 0 },
			{ {"ImLovinIt",  "AddFavorite",  AddSongToFavorites}, function() return GAMESTATE:GetCurrentSong() ~= nil end },
			{ AddFavoritesRow(PLAYER_1),                          function() return GAMESTATE:IsHumanPlayer(PLAYER_1) end },
			{ AddFavoritesRow(PLAYER_2),                          function() return GAMESTATE:IsHumanPlayer(PLAYER_2) end },
			{ {"GrooveStats", "Leaderboard", ShowLeaderboard},    function() return GAMESTATE:GetCurrentSong() ~= nil end },
		}
	},

	{
		name="CategoryFindASong",
		open=false,
		children={
			{ { "WhereforeArtThou", "SongSearch", ShowSongSearch}, not GAMESTATE:IsCourseMode() and ThemePrefs.Get("KeyboardFeatures")},
			{ {"SortBy", "Group",        ChangeSort} },
			{ {"SortBy", "Title",        ChangeSort} },
			{ {"SortBy", "Artist",       ChangeSort} },
			{ {"SortBy", "Genre",        ChangeSort} },
			{ {"SortBy", "BPM",          ChangeSort} },
			{ {"SortBy", "Length",       ChangeSort} },
			{ {"SortBy", "Meter",        ChangeSort} },
			{ {"SortBy", "Popularity",   ChangeSort} },
			{ {"SortBy", "Recent",       ChangeSort} },
			{ {"SortBy", "TopGrades",    ChangeSort} },
			{ {"SortBy", "PopularityP1", ChangeSort}, function() return PROFILEMAN:IsPersistentProfile(PLAYER_1) end },
			{ {"SortBy", "RecentP1",     ChangeSort}, function() return PROFILEMAN:IsPersistentProfile(PLAYER_1) end },
			{ {"SortBy", "TopP1Grades",  ChangeSort}, function() return PROFILEMAN:IsPersistentProfile(PLAYER_1) end },
			{ {"SortBy", "PopularityP2", ChangeSort}, function() return PROFILEMAN:IsPersistentProfile(PLAYER_2) end },
			{ {"SortBy", "RecentP2",     ChangeSort}, function() return PROFILEMAN:IsPersistentProfile(PLAYER_2) end },
			{ {"SortBy", "TopP2Grades",  ChangeSort}, function() return PROFILEMAN:IsPersistentProfile(PLAYER_2) end },
		}
	},

	{
		name="CategoryAdvanced",
		open=false,
		children={
			{ {"FeelingSalty",   "TestInput",     ShowTestInput     }, GAMESTATE:IsEventMode() },
			{ {"HardTime",       "PracticeMode",  ShowPracticeMode  }, function() return GAMESTATE:IsEventMode() and GAMESTATE:GetCurrentSong() ~= nil and ThemePrefs.Get("KeyboardFeatures") end },
			{ {"TakeABreather",  "LoadNewSongs",  ShowLoadNewSongs  } },
			{ {"NeedMoreRam",    "ViewDownloads", ShowDownloads     }, DownloadsExist },
			{ {"NextPlease",     "SwitchProfile", ShowSelectProfile }, ThemePrefs.Get("AllowScreenSelectProfile") },
			{ {"SetSummaryText", "SetSummary",    ShowSetSummary    }, SL.Global.Stages.PlayedThisGame > 0 },
		}
	},

	{
		name="CategoryStyles",
		open=false,
		children=GetChangeableStylesRows(),
	},

	{
		name="CategoryPlaylists",
		open=false,
		children=AddPlaylistsRows(),
	},
}

return wheel_options