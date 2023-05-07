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

function displayPopup(font, fontSize, label, value, color, fontColor)
	ui.pushDWriteFont(font)

	if not fontColor then
		fontColor = rgbm(0, 0, 0, 1)
	end

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
		string = label,
		fontSize = 75,
		xPos = 0,
		yPos = 207,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		margin = vec2(1020, 550),
		color = fontColor,
	})

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

	ui.popDWriteFont()

	-- drawGridLines()
end

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

local rssLogoPng = ui.decodeImage(io.loadFromZip(ac.findFile("src/assets.zip"), "rss_white.png"))
local gsiLogoPng = ui.decodeImage(io.loadFromZip(ac.findFile("src/assets.zip"), "gsi_white.png"))
local rexLogoPng = ui.decodeImage(io.loadFromZip(ac.findFile("src/assets.zip"), "rexing_white.png"))

function drawSplash()
	drawDisplayBackground(vec2(1024, 1024), rgb.colors.black)
	ui.setCursorX(-45)
	ui.setCursorY(660)

	ui.beginScale()
	ui.image(rssLogoPng, vec2(1080, 173), true)
	ui.endScale(0.65)

	ui.setCursorX(365)
	ui.setCursorY(550)

	ui.beginScale()
	ui.image(rexLogoPng, vec2(292, 51), true)
	ui.endScale(1)
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
function drawTyrePressure(sdata, font, x, y, gapX, gapY, size, color)
	ui.pushDWriteFont(font)
	local compound = sdata.compoundIndex

	local optimum0 = 25
	local optimum1 = 25
	local optimum2 = 23
	local optimum3 = 23

	try(function()
		optimum0 = compoundIdealPressures[compound][0] * 10
		optimum1 = compoundIdealPressures[compound][1] * 10
		optimum2 = compoundIdealPressures[compound][2] * 10
		optimum3 = compoundIdealPressures[compound][3] * 10
	end)

	drawText({
		fontSize = size,
		string = string.format("%.0f", sdata.wheels[0].tyrePressure * 10 - optimum0),
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%.0f", sdata.wheels[1].tyrePressure * 10 - optimum1),
		xPos = x + gapX,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%.0f", sdata.wheels[2].tyrePressure * 10 - optimum2),
		xPos = x,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%.0f", sdata.wheels[3].tyrePressure * 10 - optimum3),
		xPos = x + gapX,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	ui.popDWriteFont()
end

--- Draws the tyre tc
function drawTyreCoreTempGraphic(sdata, x, y, gapX, gapY, sizeX, sizeY, coolColor, optimumColor, hotColor)
	ui.pushDWriteFont("Default;Weight=Black")

	local brightness = 1

	local wheel0 = sdata.wheels[0]
	local optimum0 = wheel0.tyreOptimumTemperature
	local wheel1 = sdata.wheels[1]
	local optimum1 = wheel1.tyreOptimumTemperature
	local wheel2 = sdata.wheels[2]
	local optimum2 = wheel2.tyreOptimumTemperature
	local wheel3 = sdata.wheels[3]
	local optimum3 = wheel3.tyreOptimumTemperature

	local optimumWindow = 30

	ui.drawRectFilled(
		vec2(x, y),
		vec2(x + sizeX, y + sizeY),
		optimumValueLerp(
			wheel0.tyreCoreTemperature,
			optimum0 - optimumWindow,
			optimum0,
			optimum0 + optimumWindow,
			coolColor,
			coolColor,
			optimumColor,
			hotColor
		),
		0,
		ui.CornerFlags.All
	)

	ui.drawRectFilled(
		vec2(x + gapX, y),
		vec2(x + gapX + sizeX, y + sizeY),
		optimumValueLerp(
			wheel1.tyreCoreTemperature,
			optimum1 - optimumWindow,
			optimum1,
			optimum1 + optimumWindow,
			coolColor,
			coolColor,
			optimumColor,
			hotColor
		),
		0,
		ui.CornerFlags.All
	)

	ui.drawRectFilled(
		vec2(x, y + gapY),
		vec2(x + sizeX, y + gapY + sizeY),
		optimumValueLerp(
			wheel2.tyreCoreTemperature,
			optimum2 - optimumWindow,
			optimum2,
			optimum2 + optimumWindow,
			coolColor,
			coolColor,
			optimumColor,
			hotColor
		),
		0,
		ui.CornerFlags.All
	)

	ui.drawRectFilled(
		vec2(x + gapX, y + gapY),
		vec2(x + gapX + sizeX, y + gapY + sizeY),
		optimumValueLerp(
			wheel3.tyreCoreTemperature,
			optimum3 - optimumWindow,
			optimum3,
			optimum3 + optimumWindow,
			coolColor,
			coolColor,
			optimumColor,
			hotColor
		),
		0,
		ui.CornerFlags.All
	)

	ui.popDWriteFont()
end

--- Draws the 4 tyres core temperature
function drawTyreCoreTemp(sdata, font, x, y, gapX, gapY, size, color)
	ui.pushDWriteFont(font)
	local wheel0 = sdata.wheels[0]
	local tempDelta0 = math.round(wheel0.tyreCoreTemperature - wheel0.tyreOptimumTemperature)
	local wheel1 = sdata.wheels[1]
	local tempDelta1 = math.round(wheel1.tyreCoreTemperature - wheel1.tyreOptimumTemperature)
	local wheel2 = sdata.wheels[2]
	local tempDelta2 = math.round(wheel2.tyreCoreTemperature - wheel2.tyreOptimumTemperature)
	local wheel3 = sdata.wheels[3]
	local tempDelta3 = math.round(wheel3.tyreCoreTemperature - wheel3.tyreOptimumTemperature)

	drawText({
		fontSize = size,
		string = string.format("% .0f", tempDelta0),
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("% .0f", tempDelta1),
		xPos = x + gapX,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("% .0f", tempDelta2),
		xPos = x,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("% .0f", tempDelta3),
		xPos = x + gapX,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	ui.popDWriteFont()
end

local gearsSynced = {}

--- Draws the current gear
function drawGear(sdata, x, y, size)
	ui.pushDWriteFont("Default;Weight=SemiBold")
	local gear = sdata.gear
	local gearXPos = x
	local gearYPos = y

	if not gearsSynced[gear] then
		if car.poweredWheelsSpeed > 50 and car.rpm >= 10750 then
			gearsSynced[gear] = true
		end
	end

	if gear == -1 then
		gear = "R"
		gearXPos = gearXPos - 5
	elseif gear == 0 then
		gear = "N"
	end

	local color = (sdata.isInPitlane and car.clutch ~= 0) and rgbm(0, 0, 0, 1) or rgbm(1, 1, 1, 0.7)

	if ac.getSim().isInMainMenu and sdata.isInPitlane then
		color = rgbm(0, 0, 0, 1)
	end

	drawText({
		string = gear,
		fontSize = size,
		xPos = gearXPos,
		yPos = gearYPos,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})
	ui.popDWriteFont()
end

function drawGearSync(syncedColor)
	local synced = true
	ui.pushDWriteFont("Default;Weight=SemiBold")

	local xPos = 255
	local yPos = 455

	-- drawText({
	-- 	string = "GEAR",
	-- 	fontSize = 50,
	-- 	xPos = xPos - 250,
	-- 	yPos = yPos - 145,
	-- 	xAlign = ui.Alignment.Center,
	-- 	yAlign = ui.Alignment.Center,
	-- 	color = rgbm(1, 1, 1, 0.7),
	-- })

	-- drawText({
	-- 	string = "SYNC",
	-- 	fontSize = 50,
	-- 	xPos = xPos + 415,
	-- 	yPos = yPos - 145,
	-- 	xAlign = ui.Alignment.Center,
	-- 	yAlign = ui.Alignment.Center,
	-- 	color = rgbm(1, 1, 1, 0.7),
	-- })

	for gear = 1, 8 do
		local textColor = rgbm(1, 1, 1, 0.7)
		local boxColor = rgbm(1, 0, 0, 1)

		if gearsSynced[gear] then
			textColor = rgbm(0, 0, 0, 1)
			boxColor = syncedColor
		end

		display.rect({

			pos = vec2(xPos, yPos),
			size = vec2(60, 60),
			color = boxColor,
		})

		if not gearsSynced[gear] then
			synced = false

			display.rect({

				pos = vec2(xPos + 2, yPos + 2),
				size = vec2(56, 56),
				color = rgbm(0, 0, 0, 1),
			})
		end

		drawText({
			string = gear,
			fontSize = 50,
			xPos = xPos - 145,
			yPos = yPos - 145,
			xAlign = ui.Alignment.Center,
			yAlign = ui.Alignment.Center,
			color = textColor,
		})

		xPos = xPos + 60 + 5
	end

	ui.popDWriteFont()

	return synced
end

function drawAntistall()
	display.rect({
		pos = vec2(0, 585),
		size = vec2(1020, 150),
		color = rgbm(0, 0, 0, 1),
	})

	display.rect({
		pos = vec2(0, 575),
		size = vec2(1020, 10),
		color = rgbm(0.3, 0.3, 0.3, 1),
	})

	display.rect({
		pos = vec2(0, 725),
		size = vec2(1020, 10),
		color = rgbm(0.3, 0.3, 0.3, 1),
	})

	ui.pushDWriteFont("Default;Weight=SemiBold")
	drawText({
		string = "ANTI-STALL",
		fontSize = 150,
		xPos = 0,
		yPos = 370,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		margin = vec2(1024, 550),
		color = rgbm(1, 0, 0, 1),
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

function drawBrakes(sdata, x, y, xGap, yGap, xSize, ySize, coolColor, optimumColor, hotColor)
	ui.pushDWriteFont("Default;Weight=Black")
	local lowBrakeTemp = 250
	local optimumBrakeTemp = 400
	local highBrakeTemp = 1200

	display.rect({
		pos = vec2(x, y),
		size = vec2(xSize, ySize),
		color = optimumValueLerp(
			sdata.wheels[0].discTemperature,
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
			sdata.wheels[2].discTemperature,
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
		xPos = x - 111,
		yPos = y - 158,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.black,
	})

	drawText({
		string = "REAR BRK",
		fontSize = 25,
		xPos = x - 111,
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
