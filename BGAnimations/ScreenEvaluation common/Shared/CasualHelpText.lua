if SL.Global.GameMode ~= "Casual" then return end

return LoadFont(THEME:GetCurLanguage() == "ja" and "Common Normal" or "Common Bold")..{
	Text=THEME:GetString("ScreenEvaluation", "PressStartToContinue"),
	InitCommand=function(self)
		self:xy(_screen.cx, _screen.cy + 170):zoom(THEME:GetCurLanguage() == "ja" and 1.25 or 0.55)
			:diffusealpha(0):shadowlength(0.5)
	end,
	OnCommand=function(self)
		self:sleep(3):diffusealpha(1)
			:diffuseshift():effectperiod(3)
			:effectcolor1(1,1,1,0):effectcolor2(1,1,1,1)
	end
}