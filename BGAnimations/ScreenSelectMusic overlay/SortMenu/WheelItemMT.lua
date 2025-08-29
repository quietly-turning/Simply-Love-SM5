local sortmenu_dimensions = unpack(...)
local row_height = 36

-- the metatable for an item in the sort_wheel
return {
	__index = {
		create_actors = function(self, name)
			self.name=name

			local af = Def.ActorFrame{
				Name=name,

				InitCommand=function(subself)
					self.container = subself
					subself:MaskDest()
					subself:diffusealpha(0)
				end,
			}

			-- background
			af[#af+1] = Def.Quad{
				Name="background",
				InitCommand=function(subself)
					self.bg = subself
					subself:vertalign(top):setsize(sortmenu_dimensions.w, row_height-2)
					subself:y(-12):diffuse(0.15,0.15,0.15,1)
				end,
				ShowFolderCommand=function(subself)
					subself:diffusealpha(1)
				end,
				HideFolderCommand=function(subself)
					subself:diffusealpha(0)
				end,
				GainFocusCommand=function(subself)
					subself:finishtweening():accelerate(0.1):diffuse(0.35,0.35,0.35,1)
				end,
				LoseFocusCommand=function(subself)
					subself:finishtweening():decelerate(0.1):diffuse(0.2,0.2,0.2,1)
				end
			}

			af[#af+1] = Def.ActorFrame{
				Name="text container AF",
				InitCommand=function(subself)
					self.text_container = subself
					subself:x(-100):zoom(0.5)
				end,

				-- folder icon
				LoadActor("./folder-solid.png")..{
					Name="folder icon",
					InitCommand=function(subself)
						self.folder_icon = subself
						subself:visible(false):vertalign(top)
						subself:zoom(0.4):xy(28, -16)
					end,
					ShowFolderCommand=function(subself)
						subself:visible(true)
					end,
					HideFolderCommand=function(subself)
						subself:visible(false)
					end,
					GainFocusCommand=function(subself)
						subself:diffuse(1,1,1,1)
					end,
					LoseFocusCommand=function(subself)
						subself:diffuse(0.6,0.6,0.6,1)
					end,
					OpenFolderCommand=function(subself)
						subself:diffuse(GetCurrentColor())
					end,
					CloseFolderCommand=function(subself)
						subself:diffuse(0.6,0.6,0.6,1)
					end
				},

				-- top text
				Def.BitmapText{
					Name="top text",
					Font="Common Normal",
					InitCommand=function(subself)
						self.top_text = subself
						subself:zoom(1.15):xy(32,-15):diffusealpha(0)
						subself:horizalign(left)
					end,
					OnCommand=function(subself)
						subself:sleep(0.13):linear(0.05):diffusealpha(1)
					end,
					GainFocusCommand=function(subself)
						subself:diffuse(1,1,1,1)
					end,
					LoseFocusCommand=function(subself)
						subself:diffuse(0.6,0.6,0.6,1)
					end,
				},

				-- bottom text
				Def.BitmapText{
					Name="bottom text",
					Font="Common Bold",
					InitCommand=function(subself)
						self.bottom_text = subself
						subself:zoom(0.8):y(10):diffusealpha(0):maxwidth(405)
						subself:horizalign(left)
					end,
					OnCommand=function(subself)
						subself:sleep(0.1):linear(0.15):diffusealpha(1)
					end,
					ShowFolderCommand=function(subself)
						subself:x(64)
					end,
					HideFolderCommand=function(subself)
						subself:x(32)
					end,
					GainFocusCommand=function(subself)
						subself:diffuse(1,1,1,1)
					end,
					LoseFocusCommand=function(subself)
						subself:diffuse(0.6,0.6,0.6,1)
					end,
				}
			}

			return af
		end,

		transform = function(self, item_index, num_items, has_focus)
			self.container:finishtweening()

			-- if this is a group folder
			if self.top_text:GetText() == "" then
				self.container:queuecommand("ShowFolder")
			else
				self.container:queuecommand("HideFolder")
			end

			if has_focus then
				self.container:playcommand('GainFocus')

				-- if a folder row has focus
				if self.top_text:GetText() == "" then
					SCREENMAN:GetTopScreen():GetChild("Overlay"):playcommand("HideCursor")
				else
					SCREENMAN:GetTopScreen():GetChild("Overlay"):playcommand("ShowCursor")
				end
			else
				self.container:playcommand('LoseFocus')
			end

			self.container:y(row_height * (item_index - math.ceil(num_items/2)))

			if item_index <= 1 or  item_index >= num_items then
				self.container:diffusealpha(0)
			else
				self.container:diffusealpha(1)
			end
		end,


		-- `self` is one particular instance of the metatable returned by WheelItemMT
		-- `info` is an individual info table from filtered_wheel_options like
		--    {'SortBy','Title', ChangeSort} or {'TakeABreather', 'LoadNewSongs', ShowLoadNewSongs} or {'ToggleFolder','CategoryStyles', ToggleFolder}
		set = function(self, info)
			if not info then self.bottom_text:settext("") return end
			self.info = info

			-- for convenience, store some data relevant to this row's action in
			-- the ActorFrame for this row
			if info[1] == "SortBy" then
				self.sort_by = info[2]         -- SortMenuHelpers.lua ChangeSort() uses this

			elseif info[1] == "ChangeMode" or info[1] == "ChangeStyle" then
				self.change = info[2]          -- SortMenuHelpers.lua ChangeMode() uses this

			elseif info[1] == "ToggleFolder" then
				self.toggle_folder = info[2]   -- SortMenu's default.lua ToggleFolder() uses this
			end

			-- localize the top and bottom text for this row
			local toptext = THEME:GetString("ScreenSelectMusic", info[1])
			local bottomtext

			-- this row's bottom_text is the name of the playlist file retrieved from disk
			if (info[1] == "Playlist") then bottomtext = info[2]
			-- localize this row's bottom_text from ScreenSelectPlayMode (e.g. "Casual")
			elseif (info[1] == "ChangeMode") then bottomtext = THEME:GetString("ScreenSelectPlayMode", info[2])
			-- localize this row's bottom_text from ScreenSelectMusic
			else bottomtext = THEME:GetString("ScreenSelectMusic", info[2])
			end

			self.top_text:settext(toptext)
			self.bottom_text:settext(bottomtext)
		end
	}
}
