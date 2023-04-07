function getIdealPressure(compound, wheel)
	local config = ac.INIConfig.carData(car.index, "tyres.ini")

	local compoundHeader = ""
	if compound ~= 0 then
		compoundHeader = "_" .. compound
	end
	if wheel <= 1 then
		return config:get("FRONT" .. compoundHeader, "PRESSURE_IDEAL", 0)
	else
		return config:get("REAR" .. compoundHeader, "PRESSURE_IDEAL", 0)
	end
end

function tempBasedColor(input, coldTemp, coolTemp, optimumTemp, hotTemp, brightness)
	local inputFloor = math.floor(input)
	local deltaOptimum = hotTemp - optimumTemp
	local deltaCool = coolTemp - coldTemp

	local red = math.max(0, (inputFloor - optimumTemp) / deltaOptimum)
	local green = math.max(0, (inputFloor - coldTemp) / deltaCool)
		* math.max(0, 1 - (inputFloor - optimumTemp) / deltaOptimum)
	local blue = math.max(0, 1 - (inputFloor - coldTemp) / deltaCool)

	return rgbm(red, green, blue, brightness)
end

--- Override function to add clarity and default values for drawing text
function drawText(textdraw)
	if not textdraw.margin then
		textdraw.margin = vec2(350, 350)
	end
	if not textdraw.color then
		textdraw.color = rgbm(1, 1, 1, 0.7)
	end
	if not textdraw.fontSize then
		textdraw.fontSize = 70
	end

	ui.setCursorX(textdraw.xPos)
	ui.setCursorY(textdraw.yPos)
	ui.dwriteTextAligned(
		textdraw.string,
		textdraw.fontSize,
		textdraw.xAlign,
		textdraw.yAlign,
		textdraw.margin,
		false,
		textdraw.color
	)
end

function drawText2(font, string, fontSize, xPos, yPos, xAlign, color, margin)
	ui.pushDWriteFont(font)
	if not margin then
		margin = vec2(350, 350)
	end
	if not color then
		color = rgbm(1, 1, 1, 0.7)
	end
	if not fontSize then
		fontSize = 70
	end

	ui.setCursorX(xPos)
	ui.setCursorY(yPos)
	ui.dwriteTextAligned(string, fontSize, xAlign, ui.Alignment.Center, margin, false, color)
	ui.popDWriteFont()
end

--- Converts lap time from ms to MM SS MS
function lapTimeToString(lapTimeMs)
	local floor = math.floor
	local time = lapTimeMs
	return string.format(
		"%02d:%02d:%02d",
		floor((time / (1000 * 60))) % 60,
		floor((time / 1000)) % 60,
		floor((time % 1000) / 10)
	)
end

function getLeaderboard()
	local sim = ac.getSim()
	local leaderboard = {}
	for i = 0, sim.carsCount - 1 do
		local car = ac.getCar(i)
		leaderboard[i + 1] = car
		ac.log(leaderboard[i + 1].index)
	end

	ac.debug("ses", sim.raceSessionType)
	if sim.raceSessionType == 3 then
		table.sort(leaderboard, function(a, b)
			ac.debug(a.index, a.splinePosition + a.lapCount)
			return (a.splinePosition + a.lapCount) > (b.splinePosition + b.lapCount)
		end)
	else
		table.sort(leaderboard, function(a, b)
			return a.bestLapTimeMs > b.bestLapTimeMs
		end)
	end

	return leaderboard
end

function getLeaderboardPosition(carIndex)
	local leaderboard = getLeaderboard()
	for position = 1, #leaderboard do
		if carIndex == leaderboard[position].index then
			return position
		end
	end
end

function getCarAheadIndex(carIndex)
	local leaderboard = getLeaderboard()
	for position = 1, #leaderboard do
		if carIndex == leaderboard[position].index then
			if position ~= 1 then
				return leaderboard[position - 1].index
			end
		end
	end
end
