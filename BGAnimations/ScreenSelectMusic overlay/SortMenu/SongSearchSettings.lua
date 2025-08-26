local GetBpmTier = function(bpm)
	return math.floor((bpm + 0.5) / 10) * 10
end

local FilterTable = function(arr, func)
	local new_index = 1
	local size_orig = #arr
	for v in ivalues(arr) do
		if func(v) then
			arr[new_index] = v
			new_index = new_index + 1
		end
	end
	for i = new_index, size_orig do arr[i] = nil end
end

return {
  -- TODO: localize this Question string
	Question="'pack/song' format will search for songs in specific packs\n'[###]' format will search for BPMs/Difficulties",
	InitialAnswer="",
	MaxInputLength=30,
	OnOK=function(input)
		if #input == 0 then return end

		-- Lowercase the input text for comparison
		local searchText = input:lower()

		-- First extract out the "numbers".
		-- Anything <= 35 is considered a difficulty, otherwise it's a bpm.
		local difficulty = nil
		local bpmTier = nil

		for match in searchText:gmatch("%[(%d+)]") do
			local value = tonumber(match)
			if value <= 35 then
				difficulty = value
			else
				-- Determine the "tier".
				bpmTier = GetBpmTier(value)
			end
		end

		-- Remove the parsed atoms, and then strip leading/trailing whitespace.
		searchText = searchText:gsub("%[%d+]", ""):gsub("^%s*(.-)%s*$", "%1")

		-- The we separate out the pack and song into their own search terms.
		local packName = nil
		local songName = nil

		local forwardSlashIdx = searchText:find('/')
		if not forwardSlashIdx then
			songName = searchText
		else
			packName = searchText:sub(1, forwardSlashIdx - 1)
			songName = searchText:sub(forwardSlashIdx + 1)
		end

		-- Normalize empty strings to nil.
		if packName and #packName == 0 then packName = nil end
		if songName and #songName == 0 then songName = nil end

		-- If we have no search criteria, then return early.
		if not (packName or songName or difficulty or bpmTier) then return end

		-- Start with the complete song list.
		local candidates = SONGMAN:GetAllSongs()
		local stepsType = GAMESTATE:GetCurrentStyle():GetStepsType()

		-- Only add valid candidates if there are steps in the current mode.
		FilterTable(candidates, function(song) return song:HasStepsType(stepsType) end)

		if songName then
			FilterTable(candidates, function(song)
				return (song:GetDisplayFullTitle():lower():find(songName) ~= nil or
						song:GetTranslitFullTitle():lower():find(songName) ~= nil)
			end)
		end

		if packName then
			FilterTable(candidates, function(song) return song:GetGroupName():lower():find(packName) end)
		end

		if difficulty then
			FilterTable(candidates, function(song)
				local allSteps = song:GetStepsByStepsType(stepsType)
				for steps in ivalues(allSteps) do
					-- Don't consider edits.
					if steps:GetDifficulty() ~= "Difficulty_Edit" then
						if steps:GetMeter() == difficulty then
							return true
						end
					end
				end
				return false
			end)
		end

		if bpmTier then
			FilterTable(candidates, function(song)
				-- NOTE(teejusb): Not handling split bpms now, sorry.
				local bpms = song:GetDisplayBpms()
				if bpms[2]-bpms[1] == 0 then
					-- If only one BPM, then check to see if it's in the same tier.
					return bpmTier == GetBpmTier(bpms[1])
				else
					-- Otherwise check and see if the bpm is in the span of the tier.
					local lowTier = GetBpmTier(bpms[1])
					local highTier = GetBpmTier(bpms[2])
					return lowTier <= bpmTier and bpmTier <= highTier
				end
			end)
		end

		-- Even if we don't have any results, we want to show that to the player.
		MESSAGEMAN:Broadcast("DisplaySearchResults", {searchText=input, candidates=candidates})
	end,
}