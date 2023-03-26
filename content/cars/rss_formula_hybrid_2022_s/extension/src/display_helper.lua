require("src/ty_lt_acd")

local compoundIdealPressures = {}

for compound = 0, 4 do
	local wheels = {}

	for wheel = 0, 3 do
		wheels[wheel] = getIdealPressure(compound, wheel)
	end

	compoundIdealPressures[compound] = wheels
end

-- User settings (stored between sessions)
local stored = ac.storage({
	activeDisplay = 1, -- Index of active display (starting with 1)

	-- Display settings:
	launchGate = 5000,
	launchGateOn = true,

	-- Lap time popup:
	lapTimePopup = 8,
	lapTimePopupOn = true,
})

--- Returns an RGBM value based on the tyre's core temperature
local function tempBasedColor(input, coldTemp, coolTemp, optimumTemp, hotTemp, brightness)
	local inputFloor = math.floor(input)
	local red = math.min(math.max(0, (inputFloor - optimumTemp) / (hotTemp - optimumTemp)), 1)
	local green = math.min(math.max(0, (inputFloor - coldTemp) / (coolTemp - coldTemp)), 1)
		* math.min(math.max(0, 1 - (inputFloor - optimumTemp) / (hotTemp - optimumTemp)), 1)
	local blue = math.min(math.max(0, 1 - (inputFloor - coldTemp) / (coolTemp - coldTemp)), 1)

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

function displayPopup(text, value, color)
	ui.pushDWriteFont("Default;Weight=Bold")

	-- Black master background
	display.rect({
		pos = vec2(0, 0),
		size = vec2(1024, 1024),
		color = rgbm(0, 0, 0, 1),
	})

	-- Color background
	display.rect({ pos = vec2(10, 0), size = vec2(1024, 1024), color = color })

	-- Black inner background
	display.rect({
		pos = vec2(20, 520),
		size = vec2(990, 492),
		color = rgbm(0, 0, 0, 1),
	})

	drawText({
		string = text,
		fontSize = 75,
		xPos = 0,
		yPos = 205,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		margin = vec2(1020, 550),
		color = rgbm(0, 0, 0, 1),
	})

	ui.beginScale()
	drawText({
		string = value,
		fontSize = 140,
		xPos = 0,
		yPos = 470,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		margin = vec2(1025, 550),
		color = rgbm(1, 1, 1, 1),
	})
	ui.endScale(2)

	ui.popDWriteFont()

	-- drawGridLines()
end

function drawLaunch()
	local rpmColor = rgbm(0, 0, 0, 1)
	local rpmText = "RPM LOW"

	if car.rpm > 0 then
		rpmColor = rgbm(1, 0, 0, 1)
		rpmText = "RPM HIGH"
	elseif car.rpm >= 9300 and car.rpm < 10000 then
		rpmColor = rgbm(0.79, 0.78, 0, 1)
		rpmText = "RPM HIGH"
	elseif car.rpm >= 8900 and car.rpm < 9300 then
		rpmColor = rgbm(0.9, 0, 1, 1)
		rpmText = "RPM GOOD"
	elseif car.rpm >= 8000 and car.rpm < 8800 then
		rpmColor = rgbm(0.79, 0.78, 0, 1)
		rpmText = "RPM LOW"
	elseif car.rpm >= 7000 and car.rpm < 8000 then
		rpmColor = rgbm(1, 0, 0, 1)
		rpmText = "RPM LOW"
	end

	display.rect({
		pos = vec2(0, 0),
		size = vec2(350, 1024),
		color = rgb.colors.black,
	})

	display.rect({
		pos = vec2(670, 0),
		size = vec2(1024, 1024),
		color = rgb.colors.black,
	})

	display.rect({ pos = vec2(0, 440), size = vec2(1024, 50), color = rpmColor })
	display.rect({ pos = vec2(0, 0), size = vec2(50, 1024), color = rpmColor })
	display.rect({ pos = vec2(954, 0), size = vec2(1024, 1024), color = rpmColor })
	display.rect({ pos = vec2(0, 850), size = vec2(1024, 1024), color = rpmColor })
	display.rect({
		pos = vec2(50, 870),
		size = vec2(905, 135),
		color = rgbm(0, 0, 0, 1),
	})

	ui.pushDWriteFont("Default;Weight=Black")

	drawText({
		string = rpmText,
		fontSize = 125,
		xPos = 170,
		yPos = 645,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		margin = vec2(700, 550),
		color = rgbm(0.95, 0.95, 0.95, 1),
	})

	ui.popDWriteFont()

	drawGear(337, 438, 180)
	drawBrakeBiasActual(-100, 405, 65)
end

function drawSplash()
	drawDisplayBackground(vec2(1024, 1024), rgb.colors.black)
	local xSize = 2017
	local ySize = 359
	local x = -500
	local y = 525

	local badgeImage = ac.getFolder(ac.FolderID.ContentCars)
		.. "\\"
		.. ac.getCarID(car.index)
		.. "\\extension\\"
		.. "rss.png"

	ui.beginScale()

	ui.drawImage(badgeImage, vec2(x, y), vec2(x + xSize, y + ySize), rgbm(1, 1, 1, 1), vec2(0, 0), vec2(1, 1), true)

	ui.endScale(0.3)
end

function drawDisplayBorders(borderColor, borderWidth, showLess)
	-- Top display
	display.rect({
		pos = vec2(0, 525),
		size = vec2(1020, borderWidth),
		color = borderColor,
	})

	-- Below MGUK Delivery
	display.rect({
		pos = vec2(415, 862),
		size = vec2(194, borderWidth),
		color = borderColor,
	})

	-- Below battery level
	display.rect({
		pos = vec2(415, 941),
		size = vec2(194, borderWidth),
		color = borderColor,
	})

	-- Lower center cluster left
	display.rect({
		pos = vec2(414, 785),
		size = vec2(borderWidth, 235),
		color = borderColor,
	})

	-- Lower center cluster right
	display.rect({
		pos = vec2(607, 785),
		size = vec2(borderWidth, 235),
		color = borderColor,
	})

	-- Bottom controls bar
	display.rect({
		pos = vec2(360, 782),
		size = vec2(310, borderWidth),
		color = borderColor,
	})

	-- Bottom display
	display.rect({
		pos = vec2(360, 1016),
		size = vec2(310, borderWidth),
		color = borderColor,
	})

	-- Left ERS
	display.rect({
		pos = vec2(975, 525),
		size = vec2(borderWidth, 495),
		color = borderColor,
	})

	-- Left ERS
	display.rect({
		pos = vec2(42, 525),
		size = vec2(borderWidth, 495),
		color = borderColor,
	})

	-- Left Display
	display.rect({
		pos = vec2(2, 525),
		size = vec2(borderWidth, 495),
		color = borderColor,
	})

	-- Right display
	display.rect({
		pos = vec2(1015, 525),
		size = vec2(borderWidth, 495),
		color = borderColor,
	})

	-- Bottom display
	display.rect({
		pos = vec2(0, 1016),
		size = vec2(1021, borderWidth),
		color = borderColor,
	})

	if showLess then
		return
	end

	-- Bottom display
	display.rect({
		pos = vec2(0, 1016),
		size = vec2(1021, borderWidth),
		color = borderColor,
	})

	-- Below Lap times
	display.rect({
		pos = vec2(47, 610),
		size = vec2(367, borderWidth),
		color = borderColor,
	})

	-- Below Lap times
	display.rect({
		pos = vec2(612, 610),
		size = vec2(367, borderWidth),
		color = borderColor,
	})

	-- Below info popups
	display.rect({
		pos = vec2(47, 696),
		size = vec2(367, borderWidth),
		color = borderColor,
	})

	-- Below info popups
	display.rect({
		pos = vec2(612, 696),
		size = vec2(367, borderWidth),
		color = borderColor,
	})

	-- Bottom controls bar
	display.rect({
		pos = vec2(47, 782),
		size = vec2(929, borderWidth),
		color = borderColor,
	})

	-- Left GEAR
	display.rect({
		pos = vec2(414, 525),
		size = vec2(borderWidth, 495),
		color = borderColor,
	})

	-- Right GEAR
	display.rect({
		pos = vec2(607, 525),
		size = vec2(borderWidth, 495),
		color = borderColor,
	})

	-- Bottom display
	display.rect({
		pos = vec2(0, 1016),
		size = vec2(1021, borderWidth),
		color = borderColor,
	})

	-- Left tyres
	display.rect({
		pos = vec2(197, 785),
		size = vec2(borderWidth, 235),
		color = borderColor,
	})

	-- Right tyres
	display.rect({
		pos = vec2(817, 785),
		size = vec2(borderWidth, 235),
		color = borderColor,
	})

	-- Middle left tyres
	display.rect({
		pos = vec2(202, 900),
		size = vec2(212, borderWidth),
		color = borderColor,
	})

	-- Middle right tyres
	display.rect({
		pos = vec2(609, 900),
		size = vec2(208, borderWidth),
		color = borderColor,
	})

	-- Below brakes
	display.rect({
		pos = vec2(47, 862),
		size = vec2(150, borderWidth),
		color = borderColor,
	})

	-- Below tyre compound
	display.rect({
		pos = vec2(47, 941),
		size = vec2(150, borderWidth),
		color = borderColor,
	})

	-- Below fuel level
	display.rect({
		pos = vec2(822, 862),
		size = vec2(153, borderWidth),
		color = borderColor,
	})

	-- Below fuel use
	display.rect({
		pos = vec2(822, 941),
		size = vec2(153, borderWidth),
		color = borderColor,
	})
end

--- Draws whether DRS is enabled and/or active
function drawDRS(x, y, size, RareData)
	ui.pushDWriteFont("Default;Weight=Default")

	local connected = RareData.connected()
	local drsEnabled = RareData.drsEnabled()
	local drsAvailable = RareData.drsAvailable(car.index)
	local drsZone = car.drsAvailable
	local drsActive = car.drsActive

	local drsColour = rgbm(0.79, 0.78, 0, 1)
	local drsTextColour = rgbm(0, 0, 0, 1)
	-- Set DRS box color
	if connected and ac.getSim().raceSessionType == 3 then
		if drsAvailable and drsEnabled then
			if drsZone then
				drsColour = rgbm(0.79, 0.78, 0, 1)
			else
				drsColour = rgbm(0.03, 0.03, 0.03, 1)
				drsTextColour = rgbm(0.79, 0.78, 0, 1)
			end

			if drsActive == true then
				drsColour = rgbm(0, 0.79, 0.17, 1)
			end
		end
	else
		if drsZone then
			drsColour = rgbm(0.79, 0.78, 0, 1)
			if drsActive == true then
				drsColour = rgbm(0, 0.79, 0.17, 1)
			end
		else
			drsColour = rgbm(0.79, 0.78, 0, 1)
		end
	end

	drawText({
		string = "DRS",
		fontSize = size,
		xPos = x - 77,
		yPos = y - 140,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = drsTextColour,
	})

	ui.popDWriteFont()
end

--- Draws the tyre tc
function drawTyrePC(x, y, gapX, gapY, sizeX, sizeY)
	ui.pushDWriteFont("Default;Weight=Black")
	local compound = car.compoundIndex

	local wheel0 = car.wheels[0]
	local optimum0 = compoundIdealPressures[compound][0]
	local wheel1 = car.wheels[1]
	local optimum1 = compoundIdealPressures[compound][1]
	local wheel2 = car.wheels[2]
	local optimum2 = compoundIdealPressures[compound][2]
	local wheel3 = car.wheels[3]
	local optimum3 = compoundIdealPressures[compound][3]

	display.rect({
		pos = vec2(x, y),
		size = vec2(sizeX, sizeY),
		color = tempBasedColor(wheel0.tyrePressure, optimum0 - 2, optimum0 - 1, optimum0, optimum0 + 1, 1),
	})

	display.rect({
		pos = vec2(x + gapX, y),
		size = vec2(sizeX, sizeY),
		color = tempBasedColor(wheel1.tyrePressure, optimum1 - 2, optimum1 - 1, optimum1, optimum1 + 1, 1),
	})

	display.rect({
		pos = vec2(x, y + gapY),
		size = vec2(sizeX, sizeY),
		color = tempBasedColor(wheel2.tyrePressure, optimum2 - 2, optimum2 - 1, optimum2, optimum2 + 1, 1),
	})

	display.rect({
		pos = vec2(x + gapX, y + gapY),
		size = vec2(sizeX, sizeY),
		color = tempBasedColor(wheel3.tyrePressure, optimum3 - 2, optimum3 - 1, optimum3, optimum3 + 1, 1),
	})

	ui.popDWriteFont()
end

function drawOvertake(x, y, sizeX, sizeY)
	display.rect({
		pos = vec2(x, y),
		size = vec2(sizeX, sizeY),
		color = rgbm(1, 0, 1, 1),
	})
end

function drawValue(value, xPos, yPos, xSize, ySize, color) end

--- Draws the 4 tyres core temperature
function drawTyrePressure(x, y, gapX, gapY, size, color)
	local compound = car.compoundIndex
	local optimum0 = compoundIdealPressures[compound][0]
	local optimum1 = compoundIdealPressures[compound][1]
	local optimum2 = compoundIdealPressures[compound][2]
	local optimum3 = compoundIdealPressures[compound][3]

	drawText({
		fontSize = size,
		string = string.format("%+.1f", car.wheels[0].tyrePressure - optimum0),
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%+.1f", car.wheels[1].tyrePressure - optimum1),
		xPos = x + gapX,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%+.1f", car.wheels[2].tyrePressure - optimum2),
		xPos = x,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%+.1f", car.wheels[3].tyrePressure - optimum3),
		xPos = x + gapX,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})
end

--- Draws the tyre tc
function drawTyreTC(x, y, gapX, gapY, sizeX, sizeY)
	ui.pushDWriteFont("Default;Weight=Black")

	local wheel0 = car.wheels[0]
	local optimum0 = wheel0.tyreOptimumTemperature
	local wheel1 = car.wheels[1]
	local optimum1 = wheel1.tyreOptimumTemperature
	local wheel2 = car.wheels[2]
	local optimum2 = wheel2.tyreOptimumTemperature
	local wheel3 = car.wheels[3]
	local optimum3 = wheel3.tyreOptimumTemperature

	display.rect({
		pos = vec2(x, y),
		size = vec2(sizeX, sizeY),
		color = tempBasedColor(wheel0.tyreCoreTemperature, 70, optimum0 - 15, optimum0, optimum0 + 15, 1),
	})

	display.rect({
		pos = vec2(x + gapX, y),
		size = vec2(sizeX, sizeY),
		color = tempBasedColor(wheel1.tyreCoreTemperature, 70, optimum1 - 15, optimum1, optimum1 + 15, 1),
	})

	display.rect({
		pos = vec2(x, y + gapY),
		size = vec2(sizeX, sizeY),
		color = tempBasedColor(wheel2.tyreCoreTemperature, 70, optimum2 - 15, optimum2, optimum2 + 15, 1),
	})

	display.rect({
		pos = vec2(x + gapX, y + gapY),
		size = vec2(sizeX, sizeY),
		color = tempBasedColor(wheel3.tyreCoreTemperature, 70, optimum3 - 15, optimum3, optimum3 + 15, 1),
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
	-- x 3-1020
	-- y 438-1020
	local borderColor = rgbm(1, 1, 1, 0.9)
	local lineSize = 1
	local lineGap = 24.178
	local xOrigin = 3
	local yOrigin = 440

	-- -- Quadrant
	-- display.rect({
	-- 	pos = vec2(3, 438),
	-- 	size = vec2(508.5, 291),
	-- 	color = rgbm(1, 1, 0, 1),
	-- })

	for line = 0, 24 do
		if line == 12 then
			borderColor = rgbm(1, 0, 0, 0.4)
		else
			borderColor = rgbm(0, 1, 1, 1)
		end
		display.rect({
			pos = vec2(0, yOrigin + lineGap * line),
			size = vec2(1024, lineSize),
			color = borderColor,
		})
	end

	for line = 0, 42 do
		if line == 21 then
			borderColor = rgbm(1, 0, 0, 0.4)
		else
			borderColor = rgbm(0, 1, 1, 1)
		end
		display.rect({
			pos = vec2(xOrigin + lineGap * line, 0),
			size = vec2(lineSize, 1024),
			color = borderColor,
		})
	end

	-- display.rect({
	-- 	pos = vec2(xOrigin + 50 * 1, 0),
	-- 	size = vec2(lineSize, 1024),
	-- 	color = borderColor,
	-- })

	-- display.rect({
	-- 	pos = vec2(xOrigin + 50 * 1, 0),
	-- 	size = vec2(lineSize, 1024),
	-- 	color = borderColor,
	-- })
	-- display.rect({
	-- 	pos = vec2(xOrigin + 50 * 1, 0),
	-- 	size = vec2(lineSize, 1024),
	-- 	color = borderColor,
	-- })
	-- display.rect({
	-- 	pos = vec2(xOrigin + 50 * 1, 0),
	-- 	size = vec2(lineSize, 1024),
	-- 	color = borderColor,
	-- })
	-- display.rect({
	-- 	pos = vec2(xOrigin + 50 * 1, 0),
	-- 	size = vec2(lineSize, 1024),
	-- 	color = borderColor,
	-- })
	-- display.rect({
	-- 	pos = vec2(xOrigin + 50 * 1, 0),
	-- 	size = vec2(lineSize, 1024),
	-- 	color = borderColor,
	-- })
	-- display.rect({
	-- 	pos = vec2(857, 0),
	-- 	size = vec2(lineSize, 1024),
	-- 	color = borderColor,
	-- })
	-- display.rect({
	-- 	pos = vec2(907, 0),
	-- 	size = vec2(lineSize, 1024),
	-- 	color = borderColor,
	-- })
	-- display.rect({
	-- 	pos = vec2(957, 0),
	-- 	size = vec2(lineSize, 1024),
	-- 	color = borderColor,
	-- })
	-- display.rect({
	-- 	pos = vec2(1007, 0),
	-- 	size = vec2(lineSize, 1024),
	-- 	color = borderColor,
	-- })
end

local floor = math.floor

--- Converts lap time from ms to MM SS MS
function lapTimeToString(lapTimeMs)
	local time = lapTimeMs
	return string.format(
		"%02d:%02d:%02d",
		floor((time / (1000 * 60))) % 60,
		floor((time / 1000)) % 60,
		floor((time % 1000) / 10)
	)
end

--- Draws the current lap time
function drawCurrentLapTime(x, y, size)
	local textColor = rgbm(1, 1, 1, 0.7)

	if not car.isLapValid then
		textColor = rgbm(0.95, 0, 0, 0.8)
	end

	drawText({
		string = lapTimeToString(car.lapTimeMs),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = textColor,
	})
end

--- Draws the best lap time
function drawBestLapTime(x, y, size)
	drawText({
		string = lapTimeToString(car.bestLapTimeMs),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = rgbm(0.72, 0, 0.89, 1),
		margin = vec2(400, 350),
	})
end

function drawDisplayOverlay(size, color)
	display.rect({
		pos = vec2(0, 0),
		size = size,
		color = color,
	})
end

--- Draws the last lap time
function drawLastLapTime(x, y, size)
	local textColor = rgbm(1, 1, 1, 0.7)

	if not car.isLastLapValid then
		textColor = rgbm(0.95, 0, 0, 0.8)
	end

	drawText({
		string = lapTimeToString(car.previousLapTimeMs),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = textColor,
	})
end

--- Draws the current in game time
function drawCurrentTime(x, y, size, alignment)
	drawText({
		string = string.format("%02d:%02d:%02d", sim.timeHours, sim.timeMinutes, sim.timeSeconds),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
		color = rgbm(0.79, 0.78, 0, 1),
	})
end

--- Draws the lap count
function drawLapCount(x, y, size, alignment)
	drawText({
		string = car.lapCount + 1,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

--- Draws the speed of the car in KMH
function drawSpeed(x, y, size, alignment)
	drawText({
		string = string.format("%0d", car.poweredWheelsSpeed),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

--- Draws the RPM
function drawRPM(x, y, size)
	drawText({
		string = string.format("%0d", car.rpm),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = rgbm(0.7, 0, 0, 1),
	})
end

--- Draws the brake bias %
function drawBrakeBias(x, y, size)
	drawText({
		string = string.format("%.1f", car.brakeBias * 100),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.End,
		yAlign = ui.Alignment.Center,
		color = rgbm(1, 0.5, 0, 0.9),
	})
end

--- Draws the remaining fuel in liters
function drawFuelRemaining(x, y, size, alignment)
	drawText({
		string = string.format("%.0f", car.fuel),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

local fuelremaining = car.fuel
local currentLap = 1
local fueluse = 0

--- Draws the remaining fuel in liters
function drawLastLapFuelUse(x, y, size, alignment)
	if currentLap ~= car.lapCount then
		currentLap = car.lapCount
		fueluse = fuelremaining - car.fuel
		fuelremaining = car.fuel
	end

	drawText({
		string = string.format("%.2f", fueluse),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

--- Draws the remaining fuel in liters
function drawTargetLapFuelUse(x, y, size, alignment)
	local sessionLaps = ac.getSession(sim.currentSessionIndex).laps
	local targetFuelUse = 140 / sessionLaps

	if sessionLaps == 0 then
		targetFuelUse = 0
	end

	if currentLap ~= car.lapCount then
		currentLap = car.lapCount
		fueluse = fuelremaining - car.fuel
		fuelremaining = car.fuel
	end

	drawText({
		string = string.format("%.2f", targetFuelUse),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

--- Draws the remaining fuel in liters
function drawFuelPerLap(x, y, size, alignment)
	drawText({
		string = string.format("%.2f", car.fuelPerLap),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

function drawTargetMinusLastFuelUse(x, y, size, alignment)
	local sessionLaps = ac.getSession(sim.currentSessionIndex).laps
	local targetFuelUse = 140 / sessionLaps
	if currentLap ~= car.lapCount then
		currentLap = car.lapCount
		fueluse = fuelremaining - car.fuel
		fuelremaining = car.fuel
	end

	if sessionLaps == 0 then
		targetFuelUse = 0
	end

	local fuelUseDelta = targetFuelUse - fueluse
	local fueluseColor = rgbm(1, 0, 0, 1)
	local fuelUseSign = ""

	if fuelUseDelta >= 0 then
		fueluseColor = rgbm(0, 1, 0, 1)
		fuelUseSign = "+"
	end

	drawText({
		string = string.format(fuelUseSign .. "%.2f", fuelUseDelta),
		fontSize = size,
		xPos = x,
		yPos = y,
		color = fueluseColor,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})

	display.rect({
		pos = vec2(0, 800),
		size = vec2(305, 225),
		color = fueluseColor,
	})

	display.rect({
		pos = vec2(724, 800),
		size = vec2(305, 225),
		color = fueluseColor,
	})
end

--- Returns a color based on the cars performance meter
function getCarPerformanceColor()
	if car.performanceMeter < 0 then
		return rgbm(0, 0.79, 0.17, 1)
	elseif car.performanceMeter > 0 then
		return rgbm(0.83, 0, 0, 1)
	else
		return rgbm(0.95, 0.95, 0.95, 1)
	end
end

--- Draws the delta text
function drawDelta(x, y, size, alignment)
	local performanceMeter = car.performanceMeter
	drawText({
		fontSize = size,
		string = string.format(performanceMeter > 0 and "+%.3f" or "%.3f", car.performanceMeter),
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
		color = getCarPerformanceColor(),
	})
end

--- Draws the 4 tyres core temperature
function drawTyreCoreTemp(x, y, gapX, gapY, size, color)
	ui.pushDWriteFont("Default;Weight=Black")

	drawText({
		fontSize = size,
		string = string.format("%.0f", car.wheels[0].tyreCoreTemperature),
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%.0f", car.wheels[1].tyreCoreTemperature),
		xPos = x + gapX,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%.0f", car.wheels[2].tyreCoreTemperature),
		xPos = x,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	drawText({
		fontSize = size,
		string = string.format("%.0f", car.wheels[3].tyreCoreTemperature),
		xPos = x + gapX,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	ui.popDWriteFont()
end

--- Draws the 4 tyres core temperature
function drawTyreSurfaceTemp(x, y, gapX, gapY, size, color, fontWeight)
	ui.pushDWriteFont(fontWeight)

	local wheel0SurfaceTemp = (
		car.wheels[0].tyreInsideTemperature
		+ car.wheels[0].tyreMiddleTemperature
		+ car.wheels[0].tyreOutsideTemperature
	) / 3

	drawText({
		fontSize = size,
		string = string.format("%.0f", wheel0SurfaceTemp),
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	local wheel1SurfaceTemp = (
		car.wheels[1].tyreInsideTemperature
		+ car.wheels[1].tyreMiddleTemperature
		+ car.wheels[1].tyreOutsideTemperature
	) / 3
	drawText({
		fontSize = size,
		string = string.format("%.0f", wheel1SurfaceTemp),
		xPos = x + gapX,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	local wheel2SurfaceTemp = (
		car.wheels[2].tyreInsideTemperature
		+ car.wheels[2].tyreMiddleTemperature
		+ car.wheels[2].tyreOutsideTemperature
	) / 3
	drawText({
		fontSize = size,
		string = string.format("%.0f", wheel2SurfaceTemp),
		xPos = x,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	local wheel3SurfaceTemp = (
		car.wheels[3].tyreInsideTemperature
		+ car.wheels[3].tyreMiddleTemperature
		+ car.wheels[3].tyreOutsideTemperature
	) / 3
	drawText({
		fontSize = size,
		string = string.format("%.0f", wheel3SurfaceTemp),
		xPos = x + gapX,
		yPos = y + gapY,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = color,
	})

	ui.popDWriteFont()
end

--- Draws the MGUK Recovery value
function drawMGUKRecovery(x, y, size, alignment)
	drawText({
		string = car.mgukRecovery * 10,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

--- Draws the MGUK Delivery value
function drawMGUKDelivery(x, y, size, alignment)
	ui.pushDWriteFont("Default;Weight=Bold")

	local mgukDeliveryName = string.upper(ac.getMGUKDeliveryName(car.index))

	if mgukDeliveryName == "NO DEPLOY" then
		mgukDeliveryName = "NODLY"
	elseif mgukDeliveryName == "BUILD" then
		mgukDeliveryName = "CHRGE"
	elseif mgukDeliveryName == "BALANCED" then
		mgukDeliveryName = "BALCD"
	elseif mgukDeliveryName == "ATTACK" then
		mgukDeliveryName = "ATTCK"
	end

	local textSize = ui.measureDWriteText(mgukDeliveryName, size).x

	drawText({
		string = mgukDeliveryName,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})

	ui.popDWriteFont()
end

--- Draws the current gear
function drawGear(x, y, size)
	local gear = car.gear
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
	})
end

--- Draws when the driver is in the pit lane
function drawInPit()
	ui.pushDWriteFont("Default;Weight=Bold")
	if car.isInPitlane then
		display.rect({
			pos = vec2(197, 783),
			size = vec2(624, 255),
			color = rgbm(0.79, 0.78, 0, 1),
		})

		drawText({
			string = "PIT",
			fontSize = 100,
			xPos = 330,
			yPos = 680,
			xAlign = ui.Alignment.Center,
			yAlign = ui.Alignment.Center,
			color = rgb.colors.black,
		})

		drawText({
			string = ac.getTyresName(car.index, car.compoundIndex),
			fontSize = 55,
			xPos = 265,
			yPos = 802,
			xAlign = ui.Alignment.Start,
			yAlign = ui.Alignment.Center,
			color = rgb.colors.black,
		})

		if car.speedLimiterInAction == false or car.manualPitsSpeedLimiterEnabled == true then
			drawText({
				string = "LIM",
				fontSize = 55,
				xPos = 107,
				yPos = 802,
				xAlign = ui.Alignment.End,
				yAlign = ui.Alignment.Center,
				margin = vec2(650, 350),
				color = rgb.colors.black,
			})
		end
	end

	ui.popDWriteFont()
end

function drawOverlayText(less)
	local fontSize = 20
	ui.pushDWriteFont("Default;Weight=Black")

	drawText({
		string = "🔋",
		fontSize = fontSize + 20,
		xPos = 417,
		yPos = 728,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	ui.beginRotation()
	if car.kersCharging then
		drawText({
			string = "🗲",
			fontSize = fontSize + 25,
			xPos = 557,
			yPos = 725,
			xAlign = ui.Alignment.Start,
			yAlign = ui.Alignment.Center,
		})
	end
	ui.endRotation(120)

	drawText({
		string = "°C",
		fontSize = fontSize + 5,
		xPos = 382,
		yPos = 710,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.black,
	})

	drawText({
		string = "°C",
		fontSize = fontSize + 5,
		xPos = 382,
		yPos = 825,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.black,
	})

	drawText({
		string = "°C",
		fontSize = fontSize + 5,
		xPos = 615,
		yPos = 710,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.black,
	})

	drawText({
		string = "°C",
		fontSize = fontSize + 5,
		xPos = 615,
		yPos = 825,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.black,
	})

	if less then
		drawText({
			string = "BIAS",
			fontSize = fontSize + 5,
			xPos = 55,
			yPos = 535,
			xAlign = ui.Alignment.Start,
			yAlign = ui.Alignment.Center,
		})

		drawText({
			string = "EB",
			fontSize = fontSize + 5,
			xPos = 55,
			yPos = 645,
			xAlign = ui.Alignment.Start,
			yAlign = ui.Alignment.Center,
		})

		drawText({
			string = "TORQ",
			fontSize = fontSize + 5,
			xPos = 55,
			yPos = 755,
			xAlign = ui.Alignment.Start,
			yAlign = ui.Alignment.Center,
		})

		drawText({
			string = "FUEL",
			fontSize = fontSize + 5,
			xPos = 615,
			yPos = 535,
			xAlign = ui.Alignment.End,
			yAlign = ui.Alignment.Center,
		})

		drawText({
			string = "LL",
			fontSize = fontSize + 5,
			xPos = 615,
			yPos = 645,
			xAlign = ui.Alignment.End,
			yAlign = ui.Alignment.Center,
		})

		drawText({
			string = "FTAR",
			fontSize = fontSize + 5,
			xPos = 615,
			yPos = 755,
			xAlign = ui.Alignment.End,
			yAlign = ui.Alignment.Center,
		})

		ui.popDWriteFont()
		return
	end

	ui.popDWriteFont()

	drawText({
		string = "PSI",
		fontSize = fontSize,
		xPos = 275,
		yPos = 710,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.white,
	})

	drawText({
		string = "PSI",
		fontSize = fontSize,
		xPos = 275,
		yPos = 825,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.white,
	})

	drawText({
		string = "PSI",
		fontSize = fontSize,
		xPos = 720,
		yPos = 710,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.white,
	})

	drawText({
		string = "PSI",
		fontSize = fontSize,
		xPos = 720,
		yPos = 825,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.white,
	})

	ui.pushDWriteFont("Default;Weight=Black")

	drawText({
		string = "FUEL",
		fontSize = fontSize,
		xPos = 825,
		yPos = 625,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "LL",
		fontSize = fontSize,
		xPos = 825,
		yPos = 705,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "FPL",
		fontSize = fontSize,
		xPos = 825,
		yPos = 783,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "BIAS",
		fontSize = fontSize,
		xPos = 83,
		yPos = 538,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "EB",
		fontSize = fontSize,
		xPos = 215,
		yPos = 538,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "TORQ",
		fontSize = fontSize,
		xPos = 325,
		yPos = 538,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "ENTRY",
		fontSize = fontSize,
		xPos = 360,
		yPos = 538,
		xAlign = ui.Alignment.End,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "MID",
		fontSize = fontSize,
		xPos = 465,
		yPos = 538,
		xAlign = ui.Alignment.End,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "EXIT",
		fontSize = fontSize,
		xPos = 590,
		yPos = 538,
		xAlign = ui.Alignment.End,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "BEST",
		fontSize = fontSize + 5,
		xPos = 52,
		yPos = 415,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "LAST",
		fontSize = fontSize + 5,
		xPos = 905,
		yPos = 415,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	ui.popDWriteFont()
end

function drawOverlayBorders()
	local borderColor = rgbm(0.09, 0.09, 0.09, 1)

	-- Top border
	display.rect({
		pos = vec2(10, 525),
		size = vec2(1024, 10),
		color = borderColor,
	})

	-- -- Center Line
	-- display.rect{
	--     pos = vec2(512,535),
	--     size = vec2(10,450),
	--     color = bordercolor
	-- }

	-- Horizontal Border 2
	display.rect({
		pos = vec2(20, 640),
		size = vec2(330, 10),
		color = borderColor,
	})

	-- Horizontal Border 2
	display.rect({
		pos = vec2(670, 640),
		size = vec2(275, 10),
		color = borderColor,
	})

	-- Horizontal Border 3
	display.rect({
		pos = vec2(20, 745),
		size = vec2(330, 10),
		color = borderColor,
	})

	-- Horizontal Border 3
	display.rect({
		pos = vec2(670, 745),
		size = vec2(275, 10),
		color = borderColor,
	})

	-- Horizontal Border 4
	display.rect({
		pos = vec2(20, 890),
		size = vec2(390, 10),
		color = borderColor,
	})

	-- Horizontal Border 4
	display.rect({
		pos = vec2(610, 890),
		size = vec2(335, 10),
		color = borderColor,
	})

	-- Gear box
	display.rect({
		pos = vec2(410, 755),
		size = vec2(200, 255),
		color = borderColor,
	})

	display.rect({
		pos = vec2(350, 535),
		size = vec2(320, 220),
		color = borderColor,
	})

	display.rect({
		pos = vec2(360, 535),
		size = vec2(300, 210),
		color = rgbm(0, 0, 0, 1),
	})

	display.rect({
		pos = vec2(420, 755),
		size = vec2(180, 80),
		color = rgbm(0, 0, 0, 1),
	})

	display.rect({
		pos = vec2(420, 845),
		size = vec2(180, 80),
		color = rgbm(0, 0, 0, 1),
	})

	display.rect({
		pos = vec2(420, 935),
		size = vec2(180, 75),
		color = rgbm(0, 0, 0, 1),
	})

	display.rect({
		pos = vec2(10, 410),
		size = vec2(215, 120),
		color = borderColor,
	})

	display.rect({
		pos = vec2(350, 440),
		size = vec2(320, 95),
		color = borderColor,
	})

	display.rect({
		pos = vec2(360, 440),
		size = vec2(300, 85),
		color = rgbm(0, 0, 0, 1),
	})
end

local deltaLast = 0
local deltaColorLast = rgbm(0, 1, 0, 1)

function drawGapDelta(x, y, size)
	local delta = "-.-"
	local color = rgbm(1, 1, 1, 1)

	if car.racePosition ~= 1 then
		for i = 1, ac.getSim().carsCount - 1 do
			local comparedCar = ac.getCar(i)
			if comparedCar.racePosition == car.racePosition - 1 then
				local lapDelta = 0
				if comparedCar.splinePosition < car.splinePosition then
					lapDelta = (comparedCar.lapCount + (1 - comparedCar.splinePosition))
						- (car.lapCount + (1 - car.splinePosition))
				else
					lapDelta = (comparedCar.lapCount + (1 - comparedCar.splinePosition))
						- (car.lapCount + (1 - car.splinePosition))
				end

				if lapDelta >= 1 then
					delta = "+" .. math.round(lapDelta, 0) .. " L"
					color = rgbm(1, 0, 0, 1)
				else
					delta = -math.clamp(math.round(ac.getGapBetweenCars(car.index, i), 3), 0, 999)

					if math.abs(deltaLast - delta) > 0.001 then
						if delta > deltaLast then
							color = rgbm(0, 1, 0, 1)
						else
							color = rgbm(1, 0, 0, 1)
						end

						deltaColorLast = color
					else
						color = deltaColorLast
					end

					deltaLast = delta
				end
			end
		end
	end

	if delta == 999 then
		delta = "---"
	end

	drawText({
		string = tostring(delta),
		fontSize = size,
		xPos = x + 95,
		yPos = y,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
		color = color,
	})
end

local raceCfg = ac.INIConfig.load(ac.getFolder(ac.FolderID.Cfg) .. "/race.ini", ac.INIFormat.Default)

function drawLapsRemaining(x, y, size)
	local lapCount = 0
	ac.debug("race", car.lapCount)

	if ac.getSim().isOnlineRace then
		lapCount = raceCfg:get("RACE", "RACE_LAPS", 0)
	else
		lapCount = ac.getSession(sim.currentSessionIndex).laps
	end

	ac.debug("lapCount", car.sessionLapCount)

	local text = lapCount - car.lapCount + (math.round(1 - car.splinePosition, 2))

	if ac.getSim().raceSessionType ~= 3 then
		text = "---"
	end

	drawText({
		string = text,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.End,
		yAlign = ui.Alignment.Center,
	})
end

function drawValue(value, xPos, yPos, xAlign, yAlign, font, fontSize, color)
	ui.pushDWriteFont(font)

	drawText({
		string = value,
		fontSize = fontSize,
		xPos = xPos,
		yPos = yPos,
		xAlign = xAlign,
		yAlign = yAlign,
		color = color,
	})

	ui.popDWriteFont()
end

function drawBatteryRemaining(x, y, size, alignment)
	drawText({
		string = math.round(car.kersCharge * 100, 0),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

function drawErsBar(value, x, y, sizeX, sizeY, rotation, color1, color2)
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

	-- Back red bad
	display.horizontalBar({
		pos = vec2(x, y),
		size = vec2(sizeX / 4, sizeY),
		color = rgbm(1, 1, 1, 1),
		delta = 0,
		activeColor = color2,
		inactiveColor = rgbm.colors.transparent,
		total = 100,
		active = value * 400,
	})

	-- Hatching
	display.horizontalBar({
		pos = vec2(x, y),
		size = vec2(sizeX, sizeY),
		color = rgbm(1, 1, 1, 1),
		delta = 16,
		activeColor = rgbm(0.29, 0.29, 0.29, 1),
		inactiveColor = rgbm.colors.transparent,
		total = 25,
		active = 25,
	})

	display.horizontalBar({
		pos = vec2(x, y + 5),
		size = vec2(sizeX, sizeY - 10),
		color = rgbm(1, 1, 1, 1),
		delta = 0,
		activeColor = color1,
		inactiveColor = rgbm.colors.transparent,
		total = 100,
		active = value * 100,
	})

	-- Front red bar
	display.horizontalBar({
		pos = vec2(x, y + 5),
		size = vec2(sizeX / 4, sizeY - 10),
		color = rgbm(1, 1, 1, 1),
		delta = 0,
		activeColor = color2,
		inactiveColor = rgbm.colors.transparent,
		total = 100,
		active = value * 400,
	})
end

function drawBmig(x, y, size)
	drawText({
		string = string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[1] * 100 + 1),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})
end

function drawBrakeBiasActual(x, y, size, alignment)
	drawText({
		string = string.format("%.1f", math.round(100 * ac.getCarPhysics(car.index).scriptControllerInputs[0], 1)),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
		color = rgbm(1, 0.5, 0, 0.9),
	})
end

function drawEntryDiff(x, y, size)
	drawText({
		string = string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[3] / 9 + 1),

		---midDiff / 5 + 1 - 9
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
	})
end

function drawMidDiff(x, y, size)
	drawText({
		string = string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[4] / 9 + 1),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
	})
end

function drawHispdDiff(x, y, size)
	drawText({
		string = string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[5] / 9 + 1),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
	})
end

function drawMguh(x, y, size, alignment)
	local mguhMode = ""

	if car.mguhChargingBatteries then
		mguhMode = "BATT"
	else
		mguhMode = "ENG"
	end

	drawText({
		string = mguhMode,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

function drawTyreCompound(x, y, size, alignment)
	local compound = ac.getTyresName(car.index, car.compoundIndex)
	drawText({
		string = compound,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

function drawDisplayMode(x, y, size, text, alignment)
	ui.pushDWriteFont("Default;Weight=Bold")
	drawText({
		string = "MODE:" .. text,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

function drawRacePosition(x, y, size, alignment)
	drawText({
		string = "P" .. car.racePosition,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

function drawBrakes(x, y, xGap, yGap, xSize, ySize)
	ui.pushDWriteFont("Default;Weight=Black")

	display.rect({
		pos = vec2(x, y),
		size = vec2(xSize, ySize),
		color = tempBasedColor(car.wheels[0].discTemperature, 300, 400, 800, 1200, 1),
	})

	display.rect({
		pos = vec2(x + xGap, y + yGap),
		size = vec2(xSize, ySize),
		color = tempBasedColor(car.wheels[2].discTemperature, 300, 400, 800, 1200, 1),
	})

	drawText({
		string = "BRAKES",
		fontSize = 36,
		xPos = x - 100,
		yPos = y - 139,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
		color = rgb.colors.black,
	})

	ui.popDWriteFont()
end

function drawEngineBrake(x, y, size, alignment)
	drawText({
		string = car.currentEngineBrakeSetting,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end
