local function MinimizeChart(ChartString)
	local function MinimizeMeasure(measure)
		local minimal = false
		-- We can potentially minimize the chart to get the most compressed
		-- form of the actual chart data.
		-- NOTE(teejusb): This can be more compressed than the data actually
		-- generated by StepMania. This is okay because the charts would still
		-- be considered equivalent.
		-- E.g. 0000                      0000
		--      0000  -- minimized to -->
		--      0000
		--      0000
		--      StepMania will always generate the former since quarter notes are
		--      the smallest quantization.
		while not minimal and #measure % 2 == 0 do
			-- If every other line is all 0s, we can minimize the measure.
			local allZeroes = true
			for i=2, #measure, 2 do
				-- Check if the row is NOT all zeroes (thus we can't minimize).
				if measure[i] ~= string.rep('0', measure[i]:len()) then
					allZeroes = false
					break
				end
			end

			if allZeroes then
				-- To remove every other element while keeping the
				-- indices valid, we iterate from [2, len(t)/2 + 1].
				-- See the example below (where len(t) == 6).

				-- index: 1 2 3 4 5 6  -> remove index 2
				-- value: a b a b a b

				-- index: 1 2 3 4 5    -> remove index 3
				-- value: a a b a b

				-- index: 1 2 3 4      -> remove index 4
				-- value: a a a b

				-- index: 1 2 3
				-- value: a a a
				for i=2, #measure/2+1 do
					table.remove(measure, i)
				end
			else
				minimal = true
			end
		end
	end

	local finalChartData = {}
	local curMeasure = {}
	for line in ChartString:gmatch('[^\n]+') do
		-- If we hit a comma, that denotes the end of a measure.
		-- Try to minimize it, and then add it to the final chart data with
		-- the delimiter.
		-- Note: Semi-colons are already stripped out by the MsdFileParser.
		if line == ',' then
			MinimizeMeasure(curMeasure)

			for row in ivalues(curMeasure) do
				table.insert(finalChartData, row)
			end
			table.insert(finalChartData, ',')
			-- Just keep removing the first element to clear the table.
			-- This way we don't need to wait for the GC to cleanup the unused values.
			for i=1, #curMeasure do
				table.remove(curMeasure, 1)
			end
		else
			table.insert(curMeasure, line)
		end
	end

	-- Add the final measure.
	if #curMeasure > 0 then
		MinimizeMeasure(curMeasure)

		for row in ivalues(curMeasure) do
			table.insert(finalChartData, row)
		end
	end

	return table.concat(finalChartData, '\n')
end

local function NormalizeFloatDigits(param)
	-- V1, Deprecated.
	-- 3.95 usually uses three digits after the decimal point while
	-- SM5 uses 6. We normalize everything here to 6. If for some reason
	-- there are more than 6, we just remove the trailing ones.
	-- local function NormalizeDecimal(decimal)
	-- 	local int, frac = decimal:match('(.+)%.(.+)')
	-- 	if frac ~= nil then
	-- 		local zero = '0'
	-- 		if frac:len() <= 6 then
	-- 			frac = frac .. zero:rep(6 - frac:len())
	-- 		else
	-- 			frac = frac:sub(1, 6 - frac:len() - 1)
	-- 		end
	-- 		return int .. '.' .. frac
	-- 	end
	-- 	return decimal
	-- end

	-- V2, uses string.format to round all the decimals to 3 decimal places.
	local function NormalizeDecimal(decimal)
		-- Remove any control characters from the string to prevent conversion failures.
		decimal = decimal:gsub("%c", "")
		return string.format("%.3f", tonumber(decimal))
	end
	local paramParts = {}
	for beat_bpm in param:gmatch('[^,]+') do
		local beat, bpm = beat_bpm:match('(.+)=(.+)')
		table.insert(paramParts, NormalizeDecimal(beat) .. '=' .. NormalizeDecimal(bpm))
	end
	return table.concat(paramParts, ',')
end

-- We generate the hash for the CurrentSong by calculating the SHA256 of the
-- chartData + BPM string. We add the BPM string to ensure that the chart played
-- is actually accurate.
--
-- stepsType is usually either 'dance-single' or 'dance-double'
-- difficulty is usually one of {'Beginner', 'Easy', 'Medium', 'Hard', 'Challenge'}
function GenerateHash(steps, stepsType, difficulty)

	local msdFile = ParseMsdFile(steps)

	if #msdFile == 0 then return ''	end

	local bpms = ''
	local sscSteps = ''
	local sscDifficulty = ''
	local allNotes = {}

	for value in ivalues(msdFile) do
		if value[1] == 'BPMS' then
			bpms = NormalizeFloatDigits(value[2])
		elseif value[1] == 'STEPSTYPE' then sscSteps = value[2]
		elseif value[1] == 'DIFFICULTY' then sscDifficulty = value[2]
		elseif value[1] == 'NOTES' then
			--SSC files don't have 7 fields in notes so it would normally fail to generate hashes
			--We can make a temporary table mimicking what it would look like in a .SM file
			if string.find(SONGMAN:GetSongFromSteps(steps):GetSongFilePath(),".ssc$") then
				local sscTable = {}
				sscTable[2] = sscSteps
				sscTable[4] = sscDifficulty
				sscTable[7] = value[2]
				for i = 1,4 do table.insert(sscTable,i) end --filler so #notes >= 7
				sscTable['bpms'] = bpms
				table.insert(allNotes,sscTable)
			else
				value['bpms'] = bpms
				table.insert(allNotes, value)
			end
		end
	end

	if bpms == '' then return '' end

	for notes in ivalues(allNotes) do
		-- StepMania considers NOTES sections with greater than 7 sections valid.
		-- https://github.com/stepmania/stepmania/blob/master/src/NotesLoaderSM.cpp#L1072-L1079
		if #notes >= 7 and notes[2] == stepsType and difficulty == ToEnumShortString(OldStyleStringToDifficulty(notes[4])) then
			local minimizedChart = MinimizeChart(notes[7])
			local chartDataAndBpm = minimizedChart .. notes['bpms']
			local hash = sha256(chartDataAndBpm)
			-- Trace('Style: ' .. notes[2] .. '\tDifficulty: ' .. notes[4] .. '\tHash: ' .. hash)
			return hash
		end
	end

	return ''
end
