------------------------------------------------------------
-- set up the SortMenu's choices prior to Actor initialization
-- sick_wheel_mt is a metatable with global scope defined in ./Scripts/Consensual-sick_wheel.lua
local sort_wheel = setmetatable({}, sick_wheel_mt)

local wheel_options = LoadActor("./SortMenuRows.lua", sort_wheel)

-- the logic that handles navigating the SortMenu
-- (scrolling through choices, choosing one, canceling)
-- is complex enough to be in its own file
local sortmenu_input    = LoadActor("./InputHandlers/SortMenu_InputHandler.lua", {sort_wheel, wheel_options})

-- input handlers for TestInput and Leaderboards are similarly complex
local testinput_input   = LoadActor("./InputHandlers/TestInput_InputHandler.lua")
local leaderboard_input = LoadActor("./InputHandlers/Leaderboard_InputHandler.lua")

-- logic for song search is also in its own file
local SongSearchSettings = LoadActor("../SongSearch/SongSearchSettings.lua")

------------------------------------------------------------
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
local sortmenu_dimensions = { w=210, h=160 }
local wheel_item_mt = LoadActor("WheelItemMT.lua", {sortmenu_dimensions})

-- initialize the SortMenu to be be focused on the 2nd element, SortBy-Group in the "Common" folder
local wheel_index = 2

------------------------------------------------------------
-- function for toggling a SortMenu folder open/closed
local ToggleFolder = function()
	local focus = sort_wheel:get_actor_item_at_focus_pos()
	local folder_name

	-- find the folder in `wheel_options` array and flip its `open` flag
	for i, folder in ipairs(wheel_options) do
		if folder.name == focus.toggle_folder then
			folder.open = not folder.open
			folder_name = folder.name
			break
		end
	end

	-- after toggling a folder open/closed, AssessAvailableChoicesCommand will
	-- build a fresh 1-dimensional array of rows to present the user:
	--   if the user closed a folder, there will be fewer elements in the array than before
	--   if the user opened a folder, there will be more than before.
	-- this means the index of elements in the array will change!  unless we manually handle
	-- the wheel's new focus after a toggle, the SortMenu will appear to "jump" somewhere
	-- else in the list after toggling.
	-- so, pass folder_name to AssessAvailableChoices so we can search for the new index of the
	-- folder we just toggled and set the wheel's focus to that
	SCREENMAN:GetTopScreen():GetChild("Overlay"):playcommand("AssessAvailableChoices", {folder_name=folder_name})
end

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
		-- simple array of rows in the SortMenu's wheel
		local filtered_wheel_options = {}

		-- build the array of rows
		for i, folder in ipairs(wheel_options) do
			-- some folders' `children` table are dynamically constructed at SSM screen init,
			-- which could result in a folder having 0 children.  e.g. AddPlaylists() could
			-- return an empty table.  only add a row for this folder if it has children
			if #folder.children > 0 then
				table.insert(filtered_wheel_options, {"ToggleFolder", folder.name, ToggleFolder})
			end

			-- a folder's `open` attribute is toggled in SortMenu_InputHandler
			if (folder.open) then
				for _, row in ipairs(folder.children) do
					local condition = row[2]

					if condition==nil                                       -- no condition specified, always add this row
					or (type(condition)=="function" and condition()==true)  -- condition is a function, evaluate it now
					or (type(condition)=="boolean"  and condition==true)    -- condition is a boolean, evaluated at screen init
					then
						table.insert(filtered_wheel_options,  row[1])
					end
				end
			end
		end

		-- when a folder toggle occurs, indexes in `filtered_wheel_options` will change
		-- as there will be more/fewer items than prior to the toggle. find the new index
		-- of the folder that was toggled and pass it as the 2nd arg to set_info_set()
		if params and params.folder_name then
			wheel_index = sort_wheel:get_index_at_focus_pos()

			for i, folder in ipairs(wheel_options) do
				if folder.name == params.folder_name then
					if folder.open then
						self:queuecommand("OpenFolder")
					else
						self:queuecommand("CloseFolder")
					end
					break
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

		sort_wheel:set_info_set(filtered_wheel_options, wheel_index)
	end,

	-- slightly darken the entire screen
	Def.Quad {
		InitCommand=function(self) self:FullScreen():diffuse(Color.Black):diffusealpha(0.8) end
	},
	-- OptionsList Header Quad
	Def.Quad {
		InitCommand=function(self) self:Center():zoomto(sortmenu_dimensions.w+2,22):xy(_screen.cx, _screen.cy-92) end
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
		InitCommand=function(self) self:Center():zoomto(sortmenu_dimensions.w+2, sortmenu_dimensions.h+2) end
	},
	-- BG of the sortmenu box
	Def.Quad {
		InitCommand=function(self) self:Center():zoomto(sortmenu_dimensions.w, sortmenu_dimensions.h):diffuse(Color.Black) end
	},
	-- top mask
	Def.Quad {
		InitCommand=function(self) self:Center():zoomto(sortmenu_dimensions.w, _screen.h/2):y(40):MaskSource() end
	},
	-- bottom mask
	Def.Quad {
		InitCommand=function(self) self:zoomto(sortmenu_dimensions.w, _screen.h/2):xy(_screen.cx,_screen.cy+200):MaskSource() end
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
	sort_wheel:create_actors( "Sort Menu", 7, wheel_item_mt, _screen.cx, _screen.cy ),

	LoadActor(THEME:GetPathG("", "EditMenu Right.png"))..{
		Name="arrow_cursor",
		InitCommand=function(self) self:zoom(0.4):xy(_screen.cx-96, _screen.cy+5) end,
		BumpCommand=function(self) self:finishtweening():smooth(0.075):x(_screen.cx-101):smooth(0.075):x(_screen.cx-96) end,
		ShowCursorCommand=function(self) self:visible(true)  end,
		HideCursorCommand=function(self) self:visible(false) end,
	}
}
t[#t+1] = LoadActor( THEME:GetPathS("ScreenSelectMaster", "change") )..{ Name="change_sound", IsAction=true, SupportPan=false }
t[#t+1] = LoadActor( THEME:GetPathS("common", "start") )..{ Name="start_sound", IsAction=true, SupportPan=false }
return t
