local sortmenu_dimensions = ...
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
					subself:finishtweening():accelerate(0.175):diffuse(0.35,0.35,0.35,1)
				end,
				LoseFocusCommand=function(subself)
					subself:finishtweening():decelerate(0.175):diffuse(0.2,0.2,0.2,1)
				end
			}

			-- folder icon
			af[#af+1] = Def.ActorFrame{
				Name="folder icon AF",
				InitCommand=function(subself)
					subself:visible(false):zoom(0.075):xy(-86, 7)
					self.folder_icon = subself
				end,
				ShowFolderCommand=function(subself)
					subself:visible(true)
				end,
				HideFolderCommand=function(subself)
					subself:visible(false)
				end,

				-- back of folder
				LoadActor(THEME:GetPathB("ScreenSelectMusicCasual", "overlay/img/folderBack.png"))..{
					Name="folder back",
					OnCommand=function(subself)
						subself:y(-10)
					end,
					GainFocusCommand=function(subself)
						subself:diffuse(color("#c47215"))
					end,
					LoseFocusCommand=function(subself)
						subself:diffuse(color("#4e4f54"))
					end
				},

				-- front of folder
				LoadActor(THEME:GetPathB("ScreenSelectMusicCasual", "overlay/img/folderFront.png"))..{
					Name="folder front",
					InitCommand=function(subself) subself:vertalign(bottom) end,
					OnCommand=function(subself) subself:y(64) end,
					GainFocusCommand=function(subself)
						subself:diffusetopedge(color("#eebc54")):diffusebottomedge(color("#7c5505")):decelerate(0.33):rotationx(50)
					end,
					LoseFocusCommand=function(subself)
						subself:diffusebottomedge(color("#3d3e43")):diffusetopedge(color("#8d8e93")):decelerate(0.15):rotationx(0)
					end,
				}
			}

			af[#af+1] = Def.ActorFrame{
				Name="text container AF",
				InitCommand=function(subself)
					self.text_container = subself
				end,
				GainFocusCommand=function(subself)
					subself:diffuse( GetCurrentColor() )
				end,
				LoseFocusCommand=function(subself)
					subself:glow(color("1,1,1,0")):zoom(0.5):diffuse(color("#888888")):glow(color("1,1,1,0"))
				end,

				-- top text
				Def.BitmapText{
					Name="top text",
					Font="Common Normal",
					InitCommand=function(subself)
						self.top_text = subself
						subself:zoom(1.15):y(-15):diffusealpha(0)
					end,
					OnCommand=function(subself)
						subself:sleep(0.13):linear(0.05):diffusealpha(1)
					end
				},

				-- bottom text
				Def.BitmapText{
					Name="bottom text",
					Font="Common Bold",
					InitCommand=function(subself)
						self.bottom_text = subself
						subself:zoom(0.85):y(10):diffusealpha(0):maxwidth(405)
					end,
					OnCommand=function(subself)
						subself:sleep(0.1):linear(0.15):diffusealpha(1)
					end,
					ShowFolderCommand=function(subself)
						subself:horizalign(left):x(-sortmenu_dimensions.w + 70)
					end,
					HideFolderCommand=function(subself)
						subself:horizalign(center):x(0)
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
				if (self.top_text:GetText() ~= "") then
					self.text_container:zoom(0.6)
				end
				self.container:playcommand('GainFocus')
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
		-- `info` is an individual tuple from filtered_wheel_options like
		--    {'SortBy','Title'} or {'TakeABreather', 'LoadNewSongs'} or {'ToggleFolder','CategoryStyles'}
		set = function(self, info)
			if not info then self.bottom_text:settext("") return end
			self.info = info
			self.kind = info[1]


			if self.kind == "SortBy" then
				self.sort_by = info[2]

			elseif self.kind == "ChangeMode" or self.kind == "ChangeStyle" then
				self.change = info[2]

			elseif self.kind == "ToggleFolder" then
				self.toggle_folder = info[2]
				
			else
				self.new_overlay = info[2]
			end

			local toptext    = self.kind ~= "" and THEME:GetString("ScreenSelectMusic", self.kind) or ""
			local bottomtext =  string.match(self.kind, "Playlist") and info[2] or THEME:GetString(self.kind == "ChangeMode" and "ScreenSelectPlayMode" or "ScreenSelectMusic", info[2])

			self.top_text:settext(toptext)
			self.bottom_text:settext(bottomtext)
		end
	}
}
