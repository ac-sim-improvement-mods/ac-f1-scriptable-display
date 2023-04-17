require("src/utils")

local RareData = try(function()
	return require("rare/connection")
end, function()
	ac.log("[ERROR] No RARE connection file found")
end)

local compoundIdealPressures = {}

for compound = 0, 4 do
	local wheels = {}

	for wheel = 0, 3 do
		wheels[wheel] = getIdealPressure(compound, wheel)
	end

	compoundIdealPressures[compound] = wheels
end

function displayPopup(text, value, color)
	ui.pushDWriteFont("Default;Weight=Bold")

	-- -- Black master background
	display.rect({
		pos = vec2(0, 0),
		size = vec2(1024, 1024),
		color = rgbm(0, 0, 0, 1),
	})

	-- Color background
	display.rect({ pos = vec2(0, 0), size = vec2(1024, 1024), color = color })

	-- Black inner background
	display.rect({
		pos = vec2(22, 520),
		size = vec2(978, 484),
		color = rgbm(0, 0, 0, 1),
	})

	drawText({
		string = text,
		fontSize = 75,
		xPos = 0,
		yPos = 207,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		margin = vec2(1020, 550),
		color = rgbm(0, 0, 0, 1),
	})

	ui.beginScale()
	local fontSize = 170
	local fontScale = 1
	ac.log(ui.measureDWriteText(value, fontSize).x)

	if ui.measureDWriteText(value, fontSize).x > 480 then
		fontScale = 0.8
	end

	fontSize = fontSize * fontScale

	drawText({
		string = value,
		fontSize = fontSize,
		xPos = 0,
		yPos = 477,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		margin = vec2(1024, 550),
		color = rgbm(1, 1, 1, 1),
	})
	ui.endScale(2)

	ui.popDWriteFont()

	-- drawGridLines()
end

local rpmColors = {
	red = rgbm(1, 0, 0, 1),
	yellow = rgbm(0.79, 0.78, 0, 1),
	purple = rgbm(0.75, 0, 0.75, 1),
}

function drawLaunch(rpm, targetRpm, farColor, closeColor, optimumColor)
	local blackColor = rgbm(0, 0, 0, 1)
	local rpmColor = blackColor
	local rpmText = "RPM LOW"
	local rpmChunk = 250

	if rpm >= targetRpm + rpmChunk * 3 then
		rpmColor = farColor
		rpmText = "RPM HIGH"
	elseif rpm >= targetRpm + rpmChunk and rpm < targetRpm + rpmChunk * 3 then
		rpmColor = closeColor
		rpmText = "RPM HIGH"
	elseif rpm >= targetRpm - rpmChunk and rpm < targetRpm + rpmChunk then
		rpmColor = optimumColor
		rpmText = "RPM GOOD"
	elseif rpm >= targetRpm - rpmChunk * 3 and rpm < targetRpm - rpmChunk then
		rpmColor = closeColor
		rpmText = "RPM LOW"
	elseif rpm >= targetRpm - rpmChunk * 5 and rpm < targetRpm - rpmChunk * 3 then
		rpmColor = farColor
		rpmText = "RPM LOW"
	end

	display.rect({ pos = vec2(0, 440), size = vec2(1024, 81), color = rpmColor })
	display.rect({ pos = vec2(2, 0), size = vec2(50, 1024), color = rpmColor })
	display.rect({ pos = vec2(971, 0), size = vec2(50, 1024), color = rpmColor })
	display.rect({ pos = vec2(0, 871), size = vec2(1024, 1024), color = rpmColor })
	display.rect({
		pos = vec2(52, 881),
		size = vec2(919, 133),
		color = rgbm(0, 0, 0, 1),
	})

	ui.pushDWriteFont("Default;Weight=Black")

	drawText({
		string = rpmText,
		fontSize = 125,
		xPos = 157,
		yPos = 665,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		margin = vec2(700, 547),
		color = rgbm(0.95, 0.95, 0.95, 1),
	})

	ui.popDWriteFont()
end

local splashImage = ui.decodeImage(io.loadFromZip(ac.findFile("src/assets.zip"), "rss_white.png"))
function drawSplash()
	drawDisplayBackground(vec2(1024, 1024), rgb.colors.black)
	ui.setCursorX(-45)
	ui.setCursorY(630)

	ui.beginScale()
	ui.image(splashImage, vec2(1080, 173), true)
	ui.endScale(0.7)
end

--- Draws whether DRS is enabled and/or active
function drawDRS(x, y, size, color)
	ui.pushDWriteFont("Default;Weight=Black")

	local connected, drsAvailable

	local drsZone = car.drsAvailable
	local drsActive = car.drsActive
	local drsColour = rgbm(0, 0, 0, 1)
	local drsTextColour = rgbm(0, 0, 0, 1)
	local drsGray = rgbm(0.3, 0.3, 0.3, 1)

	if RareData then
		connected = RareData.connected()
		drsAvailable = RareData.drsAvailable(car.index)
	end

	-- Set DRS box color
	-- if connected and ac.getSim().raceSessionType == 3 then

	if connected and drsAvailable and ac.getSim().raceSessionType == 3 then
		if drsZone then
			drsColour = drsGray
		else
			drsTextColour = drsGray
		end
	else
		if drsZone and not drsActive then
			drsColour = drsGray
		end
	end

	if drsActive then
		drsColour = color
	end

	ui.drawRectFilled(vec2(233, 616), vec2(409, 701), drsColour)

	drawText({
		string = "DRS",
		fontSize = size,
		xPos = x + 145,
		yPos = y - 125,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = drsTextColour,
	})

	ui.popDWriteFont()
end

function drawFlag()
	local sim = ac.getSim()
	local flagColor = rgbm.colors.transparent

	if sim.raceFlagType == ac.FlagType.Caution then
		flagColor = rgbm(1, 1, 0, 1)
	elseif sim.raceFlagType == ac.FlagType.FasterCar then
		flagColor = rgbm(0, 0, 1, 1)
	elseif sim.raceFlagType == ac.FlagType.OneLapLeft then
		flagColor = rgbm(1, 1, 1, 1)
	end

	display.rect({
		pos = vec2(56, 616),
		size = vec2(177, 85),
		color = flagColor,
	})
end

function drawOvertake(color)
	if car.kersButtonPressed then
		ui.pushDWriteFont("Default;Weight=Black")

		ui.drawRectFilled(vec2(614, 616), vec2(789, 701), color)

		drawText({
			string = "OT",
			fontSize = 80,
			xPos = 520,
			yPos = 478,
			xAlign = ui.Alignment.Center,
			yAlign = ui.Alignment.Center,
			color = rgbm.colors.black,
		})

		ui.popDWriteFont()
	end
end

--- Draws the 4 tyres core temperature
function drawTyrePressure(slow, font, x, y, gapX, gapY, size, color)
	ui.pushDWriteFont(font)
	local compound = slow.compoundIndex

	local optimum0 = 25
	local optimum1 = 25
	local optimum2 = 23
	local optimum3 = 23

	try(function()
		optimum0 = compoundIdealPressures[compound][0]
		optimum1 = compoundIdealPressures[compound][1]
		optimum2 = compoundIdealPressures[compound][2]
		optimum3 = compoundIdealPressures[compound][3]
	end)

	drawText({
		fontSize = size,
		string = string.format("%+.1f", slow.wheels[0].tyrePressure - optimum0),
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%+.1f", slow.wheels[1].tyrePressure - optimum1),
		xPos = x + gapX,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%+.1f", slow.wheels[2].tyrePressure - optimum2),
		xPos = x,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%+.1f", slow.wheels[3].tyrePressure - optimum3),
		xPos = x + gapX,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	ui.popDWriteFont()
end

--- Draws the tyre tc
function drawTyreCoreTempGraphic(slow, x, y, gapX, gapY, sizeX, sizeY, coolColor, optimumColor, hotColor)
	ui.pushDWriteFont("Default;Weight=Black")

	local brightness = 1

	local wheel0 = slow.wheels[0]
	local optimum0 = wheel0.tyreOptimumTemperature
	local wheel1 = slow.wheels[1]
	local optimum1 = wheel1.tyreOptimumTemperature
	local wheel2 = slow.wheels[2]
	local optimum2 = wheel2.tyreOptimumTemperature
	local wheel3 = slow.wheels[3]
	local optimum3 = wheel3.tyreOptimumTemperature

	local optimumWindow = 10

	ui.drawRectFilled(
		vec2(x, y),
		vec2(x + sizeX, y + sizeY),
		optimumValueLerp(
			wheel0.tyreCoreTemperature,
			optimum0 - optimumWindow - 10,
			optimum0,
			optimum0 + optimumWindow + 10,
			coolColor,
			coolColor,
			optimumColor,
			hotColor
		),
		10,
		ui.CornerFlags.All
	)

	ui.drawRectFilled(
		vec2(x + gapX, y),
		vec2(x + gapX + sizeX, y + sizeY),
		optimumValueLerp(
			wheel1.tyreCoreTemperature,
			optimum1 - optimumWindow - 10,
			optimum1,
			optimum1 + optimumWindow + 10,
			coolColor,
			coolColor,
			optimumColor,
			hotColor
		),
		10,
		ui.CornerFlags.All
	)

	ui.drawRectFilled(
		vec2(x, y + gapY),
		vec2(x + sizeX, y + gapY + sizeY),
		optimumValueLerp(
			wheel2.tyreCoreTemperature,
			optimum2 - optimumWindow - 10,
			optimum2,
			optimum2 + optimumWindow + 10,
			coolColor,
			coolColor,
			optimumColor,
			hotColor
		),
		10,
		ui.CornerFlags.All
	)

	ui.drawRectFilled(
		vec2(x + gapX, y + gapY),
		vec2(x + gapX + sizeX, y + gapY + sizeY),
		optimumValueLerp(
			wheel3.tyreCoreTemperature,
			optimum3 - optimumWindow - 10,
			optimum3,
			optimum3 + optimumWindow + 10,
			coolColor,
			coolColor,
			optimumColor,
			hotColor
		),
		10,
		ui.CornerFlags.All
	)

	ui.popDWriteFont()
end

--- Draws the 4 tyres core temperature
function drawTyreCoreTemp(slow, font, x, y, gapX, gapY, size, color)
	ui.pushDWriteFont(font)
	local wheel0 = slow.wheels[0]
	local tempDelta0 = math.round(wheel0.tyreCoreTemperature - wheel0.tyreOptimumTemperature)
	local wheel1 = slow.wheels[1]
	local tempDelta1 = math.round(wheel1.tyreCoreTemperature - wheel1.tyreOptimumTemperature)
	local wheel2 = slow.wheels[2]
	local tempDelta2 = math.round(wheel2.tyreCoreTemperature - wheel2.tyreOptimumTemperature)
	local wheel3 = slow.wheels[3]
	local tempDelta3 = math.round(wheel3.tyreCoreTemperature - wheel3.tyreOptimumTemperature)

	drawText({
		fontSize = size,
		string = string.format(tempDelta0 == 0 and "%.0f" or "%+.0f", tempDelta0),
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format(tempDelta1 == 0 and "%.0f" or "%+.0f", tempDelta1),
		xPos = x + gapX,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format(tempDelta2 == 0 and "%.0f" or "%+.0f", tempDelta2),
		xPos = x,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format(tempDelta3 == 0 and "%.0f" or "%+.0f", tempDelta3),
		xPos = x + gapX,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	ui.popDWriteFont()
end

--- Draws the current gear
function drawGear(slow, x, y, size)
	ui.pushDWriteFont("Default;Weight=SemiBold")
	local gear = slow.gear
	local gearXPos = x
	local gearYPos = y

	if gear == -1 then
		gear = "R"
		gearXPos = gearXPos - 5
	elseif gear == 0 then
		gear = "N"
	end

	drawText({
		string = gear,
		fontSize = size,
		xPos = gearXPos,
		yPos = gearYPos,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = slow.isInPitlane and rgbm(0, 0, 0, 1) or rgbm(1, 1, 1, 0.7),
	})
	ui.popDWriteFont()
end

--- Draws when the driver is in the pit lane
function drawInPit(color)
	ui.pushDWriteFont("Default")
	display.rect({
		pos = vec2(0, 450),
		size = vec2(1020, 71),
		color = color,
	})

	display.rect({
		pos = vec2(414, 526),
		size = vec2(194, 265),
		color = color,
	})

	display.rect({
		pos = vec2(0, 521),
		size = vec2(52, 498),
		color = color,
	})

	display.rect({
		pos = vec2(971, 521),
		size = vec2(52, 498),
		color = color,
	})

	if car.speedLimiterInAction == false or car.manualPitsSpeedLimiterEnabled == true then
		drawText({
			string = "PIT LIMITER",
			fontSize = 80,
			xPos = 0,
			yPos = 307,
			xAlign = ui.Alignment.Center,
			yAlign = ui.Alignment.Center,
			color = rgb.colors.black,
			margin = vec2(1018, 350),
		})
	end

	ui.popDWriteFont()
end

function drawErsBar(value, x, y, sizeX, sizeY, rotation, color1, color2)
	ui.beginRotation()

	-- Back green bar
	display.horizontalBar({
		pos = vec2(x, y),
		size = vec2(sizeX, sizeY),
		color = rgbm(1, 1, 1, 1),
		delta = 0,
		activeColor = rgbm.colors.black,
		inactiveColor = rgbm.colors.transparent,
		total = 1,
		active = 1,
	})

	-- Back green bar
	display.horizontalBar({
		pos = vec2(x, y),
		size = vec2(sizeX, sizeY),
		color = rgbm(1, 1, 1, 1),
		delta = 0,
		activeColor = color1,
		inactiveColor = rgbm.colors.transparent,
		total = 100,
		active = value * 100,
	})

	ui.endRotation(rotation)
end

function drawBrakes(slow, x, y, xGap, yGap, xSize, ySize, coolColor, optimumColor, hotColor)
	ui.pushDWriteFont("Default;Weight=Black")
	local lowBrakeTemp = 300
	local optimumBrakeTemp = 300
	local highBrakeTemp = 300

	display.rect({
		pos = vec2(x, y),
		size = vec2(xSize, ySize),
		color = optimumValueLerp(
			slow.wheels[0].discTemperature,
			lowBrakeTemp,
			optimumBrakeTemp,
			highBrakeTemp,
			coolColor,
			coolColor,
			optimumColor,
			hotColor
		),
	})

	display.rect({
		pos = vec2(x + xGap, y + yGap),
		size = vec2(xSize, ySize),
		color = optimumValueLerp(
			slow.wheels[2].discTemperature,
			lowBrakeTemp,
			optimumBrakeTemp,
			highBrakeTemp,
			coolColor,
			coolColor,
			optimumColor,
			hotColor
		),
	})

	drawText({
		string = "FRNT BRK",
		fontSize = 25,
		xPos = x - 103,
		yPos = y - 158,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.black,
	})

	drawText({
		string = "REAR BRK",
		fontSize = 25,
		xPos = x - 103,
		yPos = y - 123,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.black,
	})

	ui.popDWriteFont()
end

--- Draws the background
function drawDisplayBackground(size, color)
	display.rect({
		pos = vec2(0, 0),
		size = size,
		color = color,
	})
end

--- Draws grid
function drawGridLines()
	-- x 2-1020
	-- y 440-1022
	local borderColor = rgbm(0, 1, 1, 0.9)
	local xOrigin = 2
	local yOrigin = 440
	local xSize = 1017
	local ySize = 582
	local count = 100
	local lineSize = 1

	for i = 0, count do
		display.rect({
			pos = vec2(xOrigin + (i * xSize / count), yOrigin),
			size = vec2(lineSize, ySize),
			color = i == count / 2 and rgbm(1, 0, 0, 1) or borderColor,
		})
	end

	for i = 1, count do
		display.rect({
			pos = vec2(xOrigin, yOrigin + (i * ySize / count)),
			size = vec2(xSize, lineSize),
			color = i == count / 2 and rgbm(1, 0, 0, 1) or borderColor,
		})
	end

	-- -- Center line
	-- display.rect({
	-- 	pos = vec2(510 - 0.5, 440),
	-- 	size = vec2(1, 582),
	-- 	color = rgbm(1, 0, 0, 1),
	-- })

	-- -- Center line
	-- display.rect({
	-- 	pos = vec2(0, 731 - 0.5),
	-- 	size = vec2(1022, 1),
	-- 	color = rgbm(1, 0, 0, 1),
	-- })
end

function drawAlignments()
	local xStart = 22
	local yStart = 520
	local xSize = 977
	local ySize = 483
	local count = 10
	local seg = xSize / count
	local segX = ySize / count
	local color = rgbm(1, 1, 1, 1)

	display.rect({
		pos = vec2(xStart, yStart),
		size = vec2(xSize, 3),
		color = rgbm(1, 0, 1, 0.3),
	})

	display.rect({
		pos = vec2(xStart, yStart),
		size = vec2(3, ySize),
		color = rgbm(1, 0, 1, 0.3),
	})

	display.rect({
		pos = vec2(xStart, yStart),
		size = vec2(3, 3),
		color = rgbm(1, 0, 1, 1),
	})

	for i = 1, count do
		display.rect({
			pos = vec2(xStart + (i * seg), yStart),
			size = vec2(1, ySize),
			color = color,
		})
	end

	for i = 1, count do
		display.rect({
			pos = vec2(xStart, yStart + (i * segX)),
			size = vec2(xSize, 1),
			color = color,
		})
	end
end

function drawZones()
	display.rect({
		pos = vec2(419, 530),
		size = vec2(184, 252),
		color = rgbm(1, 0, 1, 0.5),
	})

	display.rect({
		pos = vec2(205, 787),
		size = vec2(105, 113),
		color = rgbm(1, 0, 0.5, 0.2),
	})

	display.rect({
		pos = vec2(205, 905),
		size = vec2(105, 113),
		color = rgbm(1, 0, 0.5, 0.2),
	})

	-- display.rect({
	-- 	pos = vec2(47, 701),
	-- 	size = vec2(184, 315),
	-- 	color = rgbm(1, 0, 0.5, 0.2),
	-- })

	-- display.rect({
	-- 	pos = vec2(47, 806),
	-- 	size = vec2(184, 105),
	-- 	color = rgbm(1, 0, 0.75, 0.5),
	-- })

	-- display.rect({
	-- 	pos = vec2(47, 701),
	-- 	size = vec2(184, 105),
	-- 	color = rgbm(1, 0, 1, 0.5),
	-- })

	-- display.rect({
	-- 	pos = vec2(791, 701),
	-- 	size = vec2(184, 315),
	-- 	color = rgbm(1, 0, 0.5, 0.2),
	-- })

	-- display.rect({
	-- 	pos = vec2(791, 806),
	-- 	size = vec2(184, 105),
	-- 	color = rgbm(1, 0, 0.75, 0.5),
	-- })

	-- display.rect({
	-- 	pos = vec2(791, 701),
	-- 	size = vec2(184, 105),
	-- 	color = rgbm(1, 0, 1, 0.5),
	-- })
end
