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

-- General script consts.
local slowRefreshPeriod = 0.5
local fastRefreshPeriod = 0.12
local halfPosSeg = 11

-- Mirrors original car state, but with slower refresh rate. Also a good place to convert units and do other preprocessing.
local slow = {}
local delaySlow = slowRefreshPeriod
local delayFast = fastRefreshPeriod

function updateSlow(dt)
	delaySlow = delaySlow + dt
	if delaySlow > slowRefreshPeriod then
		delaySlow = 0

		slow.brakeBiasMigration = ac.getCarPhysics(car.index).scriptControllerInputs[1] * 100 + 1
		slow.brakeBiasActual = math.round(100 * ac.getCarPhysics(car.index).scriptControllerInputs[0], 1)
		slow.differentialEntry = ac.getCarPhysics(car.index).scriptControllerInputs[3] / 9 + 1
		slow.differentialMid = ac.getCarPhysics(car.index).scriptControllerInputs[4] / 9 + 1
		slow.differentialHispd = ac.getCarPhysics(car.index).scriptControllerInputs[5] / 9 + 1

		slow.racePosition = car.racePosition
		slow.bestLapTimeMs = car.bestLapTimeMs
		slow.previousLapTimeMs = car.previousLapTimeMs
		slow.lapCount = car.lapCount + 1
		slow.currentEngineBrakeSetting = car.currentEngineBrakeSetting
		slow.mgukRecovery = car.mgukRecovery * 10
		slow.compoundIndex = car.compoundIndex
		slow.mgukDelivery = car.mgukDelivery
		slow.mgukDeliveryName = string.upper(ac.getMGUKDeliveryName(car.index))
		slow.kersCharge = math.round(car.kersCharge * 100, 0)
		slow.mguhMode = car.mguhChargingBatteries and "BATT" or "ENG"
		slow.isInPitlane = car.isInPitlane
		slow.fuel = car.fuel
		slow.fuelPerLap = car.fuelPerLap
		slow.speedKmh = math.floor(car.speedKmh)
		slow.currentTime = string.format("%02d:%02d:%02d", sim.timeHours, sim.timeMinutes, sim.timeSeconds)
		slow.sessionLapCount = ac.getSession(ac.getSim().currentSessionIndex).laps
				and ac.getSession(ac.getSim().currentSessionIndex).laps
			or "--"
	end

	delayFast = delayFast + dt
	if delayFast > fastRefreshPeriod then
		delayFast = 0
		slow.lapTimeMs = car.lapTimeMs
		slow.gear = car.gear
		slow.performanceMeter = math.clamp(car.performanceMeter, -99, 99)
		slow.wheels = car.wheels
	end
end

--- Returns an RGBM value based on the tyre's core temperature

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

--- Draws whether DRS is enabled and/or active
function drawDRS(x, y, size)
	ui.pushDWriteFont("Default;Weight=Black")

	local connected, drsAvailable

	local drsZone = car.drsAvailable
	local drsActive = car.drsActive
	local drsColour = rgbm(0, 0, 0, 1)
	local drsTextColour = rgbm(0, 0, 0, 1)

	if RareData then
		connected = RareData.connected()
		drsAvailable = RareData.drsAvailable(car.index)
	end

	-- Set DRS box color
	-- if connected and ac.getSim().raceSessionType == 3 then

	if connected and drsAvailable and ac.getSim().raceSessionType == 3 then
		if drsZone then
			drsColour = rgbm(0.4, 0.4, 0.4, 1)
		else
			drsTextColour = rgbm(0.4, 0.4, 0.4, 1)
		end
	else
		if drsZone and not drsActive then
			drsColour = rgbm(0.4, 0.4, 0.4, 1)
		end
	end

	if drsActive == true then
		drsColour = rgbm(0, 1, 0, 0.75)
	end

	display.rect({
		pos = vec2(230.5, 615),
		size = vec2(183.5, 81),
		color = drsColour,
	})

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

--- Draws the tyre tc
function drawTyrePC(x, y, gapX, gapY, sizeX, sizeY)
	ui.pushDWriteFont("Default;Weight=Black")
	local compound = slow.compoundIndex

	local wheel0 = slow.wheels[0]
	local optimum0 = compoundIdealPressures[compound][0]
	local wheel1 = slow.wheels[1]
	local optimum1 = compoundIdealPressures[compound][1]
	local wheel2 = slow.wheels[2]
	local optimum2 = compoundIdealPressures[compound][2]
	local wheel3 = slow.wheels[3]
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

function drawFlag()
	if ac.getSim().raceFlagType == ac.FlagType.Caution then
		display.rect({
			pos = vec2(791.5, 615),
			size = vec2(183.5, 81),
			color = rgbm(1, 1, 0, 1),
		})
	end
end

function drawOvertake()
	if car.kersButtonPressed then
		ui.pushDWriteFont("Default;Weight=Black")

		display.rect({
			pos = vec2(608, 615),
			size = vec2(183.5, 81),
			color = rgbm(1, 0, 1, 0.7),
		})
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
function drawTyrePressure(x, y, gapX, gapY, size, color)
	local compound = slow.compoundIndex
	local optimum0 = compoundIdealPressures[compound][0]
	local optimum1 = compoundIdealPressures[compound][1]
	local optimum2 = compoundIdealPressures[compound][2]
	local optimum3 = compoundIdealPressures[compound][3]

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
end

--- Draws the tyre tc
function drawTyreTC(x, y, gapX, gapY, sizeX, sizeY)
	ui.pushDWriteFont("Default;Weight=Black")

	local brightness = 0.75
	local size = vec2(sizeX, sizeY)

	local wheel0 = slow.wheels[0]
	local optimum0 = wheel0.tyreOptimumTemperature
	local wheel1 = slow.wheels[1]
	local optimum1 = wheel1.tyreOptimumTemperature
	local wheel2 = slow.wheels[2]
	local optimum2 = wheel2.tyreOptimumTemperature
	local wheel3 = slow.wheels[3]
	local optimum3 = wheel3.tyreOptimumTemperature

	local optimumWindow = 10

	display.rect({
		pos = vec2(x, y),
		size = size,
		color = tempBasedColor(
			wheel0.tyreCoreTemperature,
			optimum0 - optimumWindow - 10,
			optimum0 - optimumWindow,
			optimum0,
			optimum0 + optimumWindow,
			brightness
		),
	})

	display.rect({
		pos = vec2(x + gapX, y),
		size = size,
		color = tempBasedColor(
			wheel1.tyreCoreTemperature,
			optimum1 - optimumWindow - 10,
			optimum1 - optimumWindow,
			optimum1,
			optimum1 + optimumWindow,
			brightness
		),
	})

	display.rect({
		pos = vec2(x, y + gapY),
		size = size,
		color = tempBasedColor(
			wheel2.tyreCoreTemperature,
			optimum2 - optimumWindow - 10,
			optimum2 - optimumWindow,
			optimum2,
			optimum2 + optimumWindow,
			brightness
		),
	})

	display.rect({
		pos = vec2(x + gapX, y + gapY),
		size = size,
		color = tempBasedColor(
			wheel3.tyreCoreTemperature,
			optimum3 - optimumWindow - 10,
			optimum3 - optimumWindow,
			optimum3,
			optimum3 + optimumWindow,
			brightness
		),
	})

	ui.popDWriteFont()
end

--- Draws the current lap time
function drawCurrentLapTime(x, y, size, alignment)
	local textColor = rgbm(1, 1, 1, 0.7)

	if not car.isLapValid then
		textColor = rgbm(0.95, 0, 0, 0.8)
	end

	drawText({
		string = ac.lapTimeToString(slow.lapTimeMs),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
		color = textColor,
	})
end

--- Draws the best lap time
function drawBestLapTime(x, y, size, alignment)
	drawText({
		string = ac.lapTimeToString(slow.bestLapTimeMs),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
		color = rgbm(0.72, 0, 0.89, 1),
		margin = vec2(400, 350),
	})
end

--- Draws the last lap time
function drawLastLapTime(x, y, size, alignment)
	local textColor = rgbm(1, 1, 1, 0.7)

	if not car.isLastLapValid then
		textColor = rgbm(0.95, 0, 0, 0.8)
	end

	drawText({
		string = ac.lapTimeToString(slow.previousLapTimeMs),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
		color = textColor,
	})
end

--- Draws the current in game time
function drawCurrentTime(x, y, size, alignment)
	drawText({
		string = slow.currentTime,
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
		string = slow.lapCount,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

--- Draws the lap count
function drawSessionLapCount(x, y, size, alignment)
	drawText({
		string = slow.lapCount + 1 .. "/" .. slow.sessionLapCount,
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

--- Draws the remaining fuel in liters
function drawFuelRemaining(x, y, size, alignment)
	drawText({
		string = string.format("%.0f", slow.fuel or 0),
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
		fueluse = fuelremaining - slow.fuel
		fuelremaining = slow.fuel
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
	local targetFuelUse = 140 / slow.sessionLapCount

	if slow.sessionLapCount == 0 then
		targetFuelUse = 0
	end

	if currentLap ~= slow.lapCount then
		currentLap = slow.lapCount
		fueluse = fuelremaining - slow.fuel
		fuelremaining = slow.fuel
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
		string = string.format("%.2f", slow.fuelPerLap),
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
		fueluse = fuelremaining - slow.fuel
		fuelremaining = slow.fuel
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
	if slow.performanceMeter < 0 then
		return rgbm(0, 0.79, 0.17, 1)
	elseif slow.performanceMeter > 0 then
		return rgbm(0.83, 0, 0, 1)
	else
		return rgbm(1, 1, 1, 0.7)
	end
end

--- Draws the delta text
function drawBestDelta(x, y, size, alignment)
	local performanceMeter = math.clamp(car.performanceMeter, -99, 99)
	drawText({
		fontSize = size,
		string = string.format("%+.3f", performanceMeter),
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
		color = getCarPerformanceColor(),
	})
end

--- Draws the delta text
function drawLastDelta(x, y, size, alignment)
	local estimatedLapTimeMs = slow.bestLapTimeMs + (slow.performanceMeter * 1000)
	local delta = estimatedLapTimeMs - slow.previousLapTimeMs
	drawText({
		fontSize = size,
		string = string.format(delta == 0 and "%.3f" or "%+.3f", delta / 1000),
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

local lastPrevLap = 0
local prevLap = 0
local lastLap = 0

--- Draws the delta text
function drawLastLapDelta(x, y, size, alignment)
	if lastLap ~= car.lapCount then
		lastPrevLap = prevLap
		prevLap = slow.previousLapTimeMs
	end
	local delta = prevLap - lastPrevLap
	drawText({
		fontSize = size,
		string = string.format("%+.3f", delta / 1000),
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

--- Draws the 4 tyres core temperature
function drawTyreCoreTemp(x, y, gapX, gapY, size, color)
	ui.pushDWriteFont("Default;Weight=Bold")

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

--- Draws the 4 tyres core temperature
function drawTyreSurfaceTemp(x, y, gapX, gapY, size, color, fontWeight)
	ui.pushDWriteFont(fontWeight)

	local wheel0SurfaceTemp = (
		slow.wheels[0].tyreInsideTemperature
		+ slow.wheels[0].tyreMiddleTemperature
		+ slow.wheels[0].tyreOutsideTemperature
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
		slow.wheels[1].tyreInsideTemperature
		+ slow.wheels[1].tyreMiddleTemperature
		+ slow.wheels[1].tyreOutsideTemperature
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
		slow.wheels[2].tyreInsideTemperature
		+ slow.wheels[2].tyreMiddleTemperature
		+ slow.wheels[2].tyreOutsideTemperature
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
		slow.wheels[3].tyreInsideTemperature
		+ slow.wheels[3].tyreMiddleTemperature
		+ slow.wheels[3].tyreOutsideTemperature
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
		string = slow.mgukRecovery,
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

	local mgukDeliveryName = slow.mgukDeliveryName

	if mgukDeliveryName == "NO DEPLOY" then
		mgukDeliveryName = "NODLY"
	elseif mgukDeliveryName == "BUILD" then
		mgukDeliveryName = "CHRGE"
	elseif mgukDeliveryName == "BALANCED" then
		mgukDeliveryName = "BALCD"
	elseif mgukDeliveryName == "ATTACK" then
		mgukDeliveryName = "ATTCK"
	end

	drawText({
		string = slow.mgukDelivery .. " " .. mgukDeliveryName,
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
function drawInPit()
	local yellowColor = rgbm(0.65, 0.65, 0.1, 1)
	ui.pushDWriteFont("Default")
	display.rect({
		pos = vec2(0, 450),
		size = vec2(1020, 80),
		color = yellowColor,
	})

	display.rect({
		pos = vec2(419, 530),
		size = vec2(184, 250),
		color = yellowColor,
	})

	display.rect({
		pos = vec2(0, 530),
		size = vec2(45, 490),
		color = yellowColor,
	})

	display.rect({
		pos = vec2(975, 530),
		size = vec2(45, 490),
		color = yellowColor,
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

function drawGapDelta(x, y, size, alignment)
	local delta = "-.---"
	local color = rgbm(1, 1, 1, 0.7)

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
				else
					delta = -math.clamp(math.round(ac.getGapBetweenCars(car.index, i), 3), 0, 999)
				end
			end
		end
	end

	if delta == 999 or delta == -999 then
		delta = "-.---"
	end

	drawText({
		string = tostring(delta),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
		color = color,
	})
end

function drawValue(value, xPos, yPos, fontSize, xAlign, color)
	drawText({
		string = value,
		fontSize = fontSize,
		xPos = xPos,
		yPos = yPos,
		xAlign = xAlign,
		yAlign = ui.Alignment.Center,
		color = color,
	})
end

function drawBatteryRemaining(x, y, size, alignment)
	drawText({
		string = slow.kersCharge,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

function drawErsBar(value, x, y, sizeX, sizeY, rotation, color1, color2)
	ui.beginRotation()

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

	ui.endRotation(rotation, vec2(17, 243))
end

function drawBmig(x, y, size)
	drawText({
		string = string.format("%.0f", slow.brakeBiasMigration),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})
end

function drawBrakeBiasActual(x, y, size, alignment)
	drawText({
		string = string.format("%.1f", slow.brakeBiasActual),
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
		string = string.format("%.0f", slow.differentialEntry),

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
		string = string.format("%.0f", slow.differentialMid),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
	})
end

function drawHispdDiff(x, y, size)
	drawText({
		string = string.format("%.0f", slow.differentialHispd),
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = ui.Alignment.Center,
		yAlign = ui.Alignment.Center,
	})
end

function drawMguh(x, y, size, alignment)
	drawText({
		string = slow.mguhMode,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
end

function drawTyreCompound(x, y, size, alignment)
	ui.pushDWriteFont("Default;Weight=Bold")

	local compound = ac.getTyresName(car.index, slow.compoundIndex)
	drawText({
		string = compound,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
	ui.popDWriteFont()
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
	ui.popDWriteFont()
end

function drawRacePosition(x, y, size, alignment)
	drawText({
		string = "P" .. slow.racePosition,
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
		color = tempBasedColor(slow.wheels[0].discTemperature, 300, 400, 800, 1200, 1),
	})

	display.rect({
		pos = vec2(x + xGap, y + yGap),
		size = vec2(xSize, ySize),
		color = tempBasedColor(slow.wheels[2].discTemperature, 300, 400, 800, 1200, 1),
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
		string = slow.currentEngineBrakeSetting,
		fontSize = size,
		xPos = x,
		yPos = y,
		xAlign = alignment,
		yAlign = ui.Alignment.Center,
	})
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
	local xStart = 608
	local yStart = 701
	local xSize = 367
	local ySize = 80
	local count = 6
	local seg = xSize / count
	local segX = ySize / count

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
			color = rgbm(1, 1, 1, 0.3),
		})
	end

	for i = 1, count do
		display.rect({
			pos = vec2(xStart, yStart + (i * segX)),
			size = vec2(xSize, 1),
			color = rgbm(1, 1, 1, 0.3),
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
