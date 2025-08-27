-- "MT" is my personal means of denoting that this thing (the file, the variable, whatever)
-- has something to do with a Lua metatable.
--
-- metatables in Lua are a useful construct when designing reusable components.
-- For example, I'm using them here to define a generic definition of any choice within the SortMenu.
-- The file WheelItemMT.lua contains a metatable definition; the "MT" is my own personal convention
-- in Simply Love.
--
-- Unfortunately, many online tutorials and guides on Lua metatables are
-- *incredibly* obtuse and unhelpful for non-computer-science people (like me).
-- https://lua.org/pil/13.html is just frustratingly scant.
--
-- http://phrogz.net/lua/LearningLua_ValuesAndMetatables.html is less bad than most.
-- I do get immediately lost in the criss-crossing diagrams, and I'll continue to
-- argue that naming things foo, bar, and baz "because we want to teach an idea, not a skill"
-- results in programming tutorials so abstract they don't seem applicable to this world,
-- but its prose was approachable enough for wastes-of-space like me, so I guess I'll
-- recommend it until I find a more helpful one.
--                                      -quietly
local sortmenu = { w=210, h=160 }
local wheel_item_mt = LoadActor("WheelItemMT.lua", sortmenu)

------------------------------------------------------------

local style = GAMESTATE:GetCurrentStyle():GetName():gsub("8", "")
local AddFavorites, DownloadsExist, AddPlayerSortOptions, AddPlaylists, GetChangeableStyles = unpack(LoadActor("./SortMenuHelpers.lua"))

-- `wheel_options` is the master table that defines the SortMenu's choices
-- The structure is as follows:
-- The top level table contains the options that will be displayed in the SortMenu.
-- For instance: { {"SortBy", "Group"} } adds the SortBy (toptext) Group (bottomtext) option to the SortMenu.

-- If a second element is present, this means we're either providing a condition determining whether or not the option is displayed.
-- or we're creating a submenu.
-- If the second element is a table, it's a submenu, if it equates to a boolean, it's a condition.

-- Conditions:
-- These determine whether or not the option will be displayed.
-- For instance: { {"SortBy", "Group"}, GAMESTATE:IsCourseMode() } will only display the Group option in CourseMode.
-- You can use any Lua expression that equates to a boolean value here.
-- Alternatively, you may provide a function that returns a boolean value for more complex and timely conditions.

-- Submenus:
-- We can create categories within the SortMenu by providing a table as the second element
-- The first element becomes the top and bottomtext for the category.
-- The second element's table contains that options will show under this category.
-- It follows the same structure as the top level table.
local wheel_options = {
	{
		name="CategoryCommon",
		open=true,
		children={
			{ {"SortBy", "Group"} },
			{ {"SortBy", "Title"} },
			{ {"SortBy", "Recent"} },
			-- Casual players often accidentally choose ITG mode and an experienced player in the area may notice this
			-- and offer to switch them back to Casual mode using this option in the SortMenu.
			{ {"ChangeMode", "Casual"}, SL.Global.Stages.PlayedThisGame == 0 },
			{ {"ImLovinIt",  "AddFavorite"}, function() return GAMESTATE:GetCurrentSong() ~= nil end} ,
			AddFavorites(),
			{ {"GrooveStats", "Leaderboard"}, function() return GAMESTATE:GetCurrentSong() ~= nil end },
		}
	},

	{
		name="CategorySorts",
		open=false,
		children={
			{ {"SortBy", "Group"}  },
			{ {"SortBy", "Title"}  },
			{ {"SortBy", "Artist"} },
			{ {"SortBy", "Genre"}  },
			{ {"SortBy", "BPM"}    },
			{ {"SortBy", "Length"} },
			{ {"SortBy", "Meter"}  },
			{ {"SortBy", "Popularity"} },
			{ {"SortBy", "Recent"} },
			{ {"SortBy", "TopGrades"} },
			{ {"SortBy", "PopularityP1"}, function() return PROFILEMAN:IsPersistentProfile(PLAYER_1) end },
			{ {"SortBy", "RecentP1"},     function() return PROFILEMAN:IsPersistentProfile(PLAYER_1) end },
			{ {"SortBy", "TopP1Grades"},  function() return PROFILEMAN:IsPersistentProfile(PLAYER_1) end },
			{ {"SortBy", "PopularityP2"}, function() return PROFILEMAN:IsPersistentProfile(PLAYER_2) end },
			{ {"SortBy", "RecentP2"},     function() return PROFILEMAN:IsPersistentProfile(PLAYER_2) end },
			{ {"SortBy", "TopP2Grades"},  function() return PROFILEMAN:IsPersistentProfile(PLAYER_2) end },
		}
	},

	{
		name="CategoryAdvanced",
		open=false,
		children={
			{ {"FeelingSalty",     "TestInput" },    GAMESTATE:IsEventMode() },
			{ {"HardTime",         "PracticeMode"},  function() return GAMESTATE:IsEventMode() and GAMESTATE:GetCurrentSong() ~= nil and ThemePrefs.Get("KeyboardFeatures") end },
			{ {"TakeABreather",    "LoadNewSongs"} },
			{ {"NeedMoreRam",      "ViewDownloads"}, DownloadsExist },
			{ {"WhereforeArtThou", "SongSearch"},    not GAMESTATE:IsCourseMode() and ThemePrefs.Get("KeyboardFeatures") },
			{ {"NextPlease",       "SwitchProfile"}, ThemePrefs.Get("AllowScreenSelectProfile") },
			{ {"SetSummaryText",   "SetSummary"},    SL.Global.Stages.PlayedThisGame > 0 },
		}
	},

	{
		name="CategoryStyles",
		open=false,
		children=GetChangeableStyles(style),
	},

	{
		name="CategoryPlaylists",
		open=false,
		children=AddPlaylists(),
	},
}

------------------------------------------------------------
-- set up the SortMenu's choices prior to Actor initialization
-- sick_wheel_mt is a metatable with global scope defined in ./Scripts/Consensual-sick_wheel.lua
local sort_wheel = setmetatable({}, sick_wheel_mt)

-- the logic that handles navigating the SortMenu
-- (scrolling through choices, choosing one, canceling)
-- is large enough they get their own files
local sortmenu_input    = LoadActor("SortMenu_InputHandler.lua", {sort_wheel, wheel_options})
local testinput_input   = LoadActor("TestInput_InputHandler.lua")
local leaderboard_input = LoadActor("Leaderboard_InputHandler.lua")

-- logic for song search is also in its own file
local SongSearchSettings = LoadActor("SongSearchSettings.lua")

------------------------------------------------------------
-- General purpose function to redirect input back to the engine.
-- "self" here should refer to the SortMenu ActorFrame.
local DirectInputToEngine = function(self)
	local screen = SCREENMAN:GetTopScreen()
	local overlay = self:GetParent()

	screen:RemoveInputCallback(sortmenu_input)
	screen:RemoveInputCallback(testinput_input)
	screen:RemoveInputCallback(leaderboard_input)

	for player in ivalues(PlayerNumber) do
		SCREENMAN:set_input_redirected(player, false)
	end
	self:playcommand("HideSortMenu")
	overlay:playcommand("HideTestInput")
	overlay:playcommand("HideLeaderboard")
end

------------------------------------------------------------

local t = Def.ActorFrame {
	Name="SortMenu",
	-- Always ensure player input is directed back to the engine when initializing SelectMusic.
	InitCommand=function(self) self:visible(false):queuecommand("DirectInputToEngine") end,
	-- Always ensure player input is directed back to the engine when leaving SelectMusic.
	OffCommand=function(self) self:playcommand("DirectInputToEngine") end,
	-- Figure out which choices to put in the SortWheel based on various current conditions.
	OnCommand=function(self) self:playcommand("AssessAvailableChoices") end,
	ShowSortMenuCommand=function(self) self:visible(true) end,
	HideSortMenuCommand=function(self) self:visible(false) end,

	DirectInputToSortMenuCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()
		screen:RemoveInputCallback(testinput_input)
		screen:RemoveInputCallback(leaderboard_input)
		screen:AddInputCallback(sortmenu_input)
		for player in ivalues(PlayerNumber) do
			SCREENMAN:set_input_redirected(player, true)
		end
		self:queuecommand("AssessAvailableChoices"):queuecommand("ShowSortMenu")
		overlay:playcommand("HideTestInput")
		overlay:playcommand("HideLeaderboard")
	end,
	DirectInputToTestInputCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()
		screen:RemoveInputCallback(sortmenu_input)
		screen:AddInputCallback(testinput_input)
		for player in ivalues(PlayerNumber) do
			SCREENMAN:set_input_redirected(player, true)
		end
		self:playcommand("HideSortMenu")

		overlay:playcommand("ShowTestInput")
	end,
	DirectInputToLeaderboardCommand=function(self)
		local screen = SCREENMAN:GetTopScreen()
		local overlay = self:GetParent()
		screen:RemoveInputCallback(sortmenu_input)
		screen:AddInputCallback(leaderboard_input)
		for player in ivalues(PlayerNumber) do
			SCREENMAN:set_input_redirected(player, true)
		end
		self:playcommand("HideSortMenu")

		overlay:playcommand("ShowLeaderboard")
	end,
	-- this returns input back to the engine and its ScreenSelectMusic
	DirectInputToEngineCommand=function(self)
		DirectInputToEngine(self)
	end,
	DirectInputToEngineForSongSearchCommand=function(self)
		DirectInputToEngine(self)

		-- Then add the ScreenTextEntry on top.
		SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
		SCREENMAN:GetTopScreen():Load(SongSearchSettings)
	end,
	DirectInputToEngineForSelectProfileCommand=function(self)
		DirectInputToEngine(self)

		-- Then add the ScreenSelectProfile on top.
		SCREENMAN:AddNewScreenToTop("ScreenSelectProfile")
	end,

	AssessAvailableChoicesCommand=function(self, params)

		local filtered_wheel_options = {}

		for i, folder in ipairs(wheel_options) do
			-- each row in a folder is conditionally evaluated at init, which can result
			-- in folders with 0 children. only add folder row if it has children
			if #folder.children > 0 then
				table.insert(filtered_wheel_options, {"", folder.name})
			end

			if (folder.open) then
				for _, row in ipairs(folder.children) do
					if row[2]==nil                                     -- no condition, always add this row
					or (type(row[2])=="function" and row[2]()==true)   -- condition is a function, evaluate it now
					or (type(row[2])=="boolean"  and row[2]==true)     -- condition is a boolean, evaluated at screen init
					then
						table.insert(filtered_wheel_options,  row[1])
					end
				end
			end
		end

		-- Override sick_wheel's default focus_pos, which is math.floor(num_items / 2)
		--
		-- keep in mind that num_items is the number of Actors in the wheel (here, 7)
		-- NOT the total number of things you can eventually scroll through (#wheel_options = 14)
		--
		-- so, math.floor(7/2) gives focus to the third item in the wheel, which looks weird
		-- in this particular usage.  Thus, set the focus to the wheel's current 4th Actor.
		sort_wheel.focus_pos = 4

		-- the second argument passed to set_info_set is the index of the item in wheel_options
		-- that we want to have focus when the wheel is displayed
		local wheel_index = 1
		for i, row in ipairs(filtered_wheel_options) do
			if params and row[2] == params.folder_name then
				wheel_index = i
				break
			end
		end

		sort_wheel:set_info_set(filtered_wheel_options, wheel_index)
	end,
	-- slightly darken the entire screen
	Def.Quad {
		InitCommand=function(self) self:FullScreen():diffuse(Color.Black):diffusealpha(0.8) end
	},
	-- OptionsList Header Quad
	Def.Quad {
		InitCommand=function(self) self:Center():zoomto(sortmenu.w+2,22):xy(_screen.cx, _screen.cy-92) end
	},
	-- "Options" text
	Def.BitmapText{
		Font="Common Bold",
		Text=ScreenString("Options"),
		InitCommand=function(self)
			self:xy(_screen.cx, _screen.cy-92):zoom(0.4)
				:diffuse( Color.Black )
		end
	},
	-- white border
	Def.Quad {
		InitCommand=function(self) self:Center():zoomto(sortmenu.w+2,sortmenu.h+2) end
	},
	-- BG of the sortmenu box
	Def.Quad {
		InitCommand=function(self) self:Center():zoomto(sortmenu.w,sortmenu.h):diffuse(Color.Black) end
	},
	-- top mask
	Def.Quad {
		InitCommand=function(self) self:Center():zoomto(sortmenu.w,_screen.h/2):y(40):MaskSource() end
	},
	-- bottom mask
	Def.Quad {
		InitCommand=function(self) self:zoomto(sortmenu.w,_screen.h/2):xy(_screen.cx,_screen.cy+200):MaskSource() end
	},
	-- "Press SELECT To Cancel" text
	Def.BitmapText{
		Font="Common Bold",
		Text=ScreenString("Cancel"),
		InitCommand=function(self)
			if PREFSMAN:GetPreference("ThreeKeyNavigation") then
				self:visible(false)
			else
				self:xy(_screen.cx, _screen.cy+100):zoom(0.3):diffuse(0.7,0.7,0.7,1)
			end
		end
	},
	-- this returns an ActorFrame ( see: ./Scripts/Consensual-sick_wheel.lua )
	sort_wheel:create_actors( "Sort Menu", 7, wheel_item_mt, _screen.cx, _screen.cy )
}
t[#t+1] = LoadActor( THEME:GetPathS("ScreenSelectMaster", "change") )..{ Name="change_sound", IsAction=true, SupportPan=false }
t[#t+1] = LoadActor( THEME:GetPathS("common", "start") )..{ Name="start_sound", IsAction=true, SupportPan=false }
return t
