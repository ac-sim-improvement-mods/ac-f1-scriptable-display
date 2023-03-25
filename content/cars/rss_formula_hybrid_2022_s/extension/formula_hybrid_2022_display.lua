local RareData = require("rare/connection")
require("src/display_helper")

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

-- Display setup
local backgroundColor = rgbm(0, 0, 0, 1)
local displaySize = vec2(1020, 1024) -- Size of the display in pixels
local borderColor = rgbm(0.29, 0.29, 0.29, 1)
local borderWidth = 5
local displayRotationAngle = 90 -- Optional display rotation: use it if display is not horizontal on the texture
local displayRotationPivot = vec2(86, 86) -- Pivot relative to display space

-- General script consts.
local slowRefreshPeriod = 0.5
local fastRefreshPeriod = 0.12
local halfPosSeg = 11

-- Mirrors original car state, but with slower refresh rate. Also a good place to convert units and do other preprocessing.
local slow = {}
local delaySlow = slowRefreshPeriod
local delayFast = fastRefreshPeriod

local function updateSlow(dt)
	delaySlow = delaySlow + dt
	if delaySlow > slowRefreshPeriod then
		delaySlow = 0

		slow.racePosition = car.racePosition
		slow.bestLapTimeMs = car.bestLapTimeMs
		slow.fuel = car.fuel
		slow.fuelPerLap = car.fuelPerLap
		slow.speedKmh = math.floor(car.speedKmh)
	end

	delayFast = delayFast + dt
	if delayFast > fastRefreshPeriod then
		delayFast = 0
		slow.lapTimeMs = car.lapTimeMs
		slow.performanceMeter = car.performanceMeter
		slow.wheels = car.wheels
	end
end

--- Draws the Mode A display
local function displayWarmup(dt)
	drawRacePosition(13, 305, 70, ui.Alignment.Start)
	drawDelta(140, 305, 70)
	drawDRS(0, 602, 70, RareData)

	drawSpeed(338, 305, 75, ui.Alignment.Center)
	drawLapCount(813, 305, 70)
	drawCurrentLapTime(626, 305, 70)

	drawBrakeBiasActual(47, 573, 65, ui.Alignment.Start)
	drawEngineBrake(209, 573, 65, ui.Alignment.Start)
	drawMGUKRecovery(39, 573, 65, ui.Alignment.End)

	drawLastLapTime(626, 390, 70)
	drawGear(338, 470, 225)
	drawBestLapTime(140, 390, 70)

	drawEntryDiff(503, 573, 65)
	drawMidDiff(619, 573, 65)
	drawHispdDiff(744, 573, 65)

	-- display.rect({
	-- 	pos = vec2(612, 615),
	-- 	size = vec2(363, 81),
	-- 	color = rgbm(0, 1, 1, 1),
	-- })

	-- display.rect({
	-- 	pos = vec2(612, 701),
	-- 	size = vec2(363, 81),
	-- 	color = rgbm(0, 1, 1, 1),
	-- })

	-- display.rect({
	-- 	pos = vec2(293, 701),
	-- 	size = vec2(121, 81),
	-- 	color = rgbm(0, 1, 1, 0.3),
	-- })

	drawBrakes(47, 789, 0, 36, 149, 37)
	drawTyreCompound(48, 725, 55, ui.Alignment.Start)
	drawCurrentTime(48, 805, 39, ui.Alignment.Start)

	drawTyreTC(309, 788, 302, 118, 104, 111)
	drawTyreCoreTemp(184, 669, 302, 118, 55, rgbm(0, 0, 0, 1))
	drawTyrePressure(76, 668, 512, 118, 45)

	drawMGUKDelivery(338, 649, 50, ui.Alignment.Center)
	drawBatteryRemaining(338, 726, 55, ui.Alignment.Center)
	drawMguh(338, 803, 55, ui.Alignment.Center)

	drawFuelRemaining(620, 647, 55, ui.Alignment.End)
	drawLastLapFuelUse(620, 725, 55, ui.Alignment.End)
	drawFuelPerLap(620, 805, 55, ui.Alignment.End)

	ui.beginRotation()
	drawErsBar((1 - car.kersLoad), 738, 513, 486, 35, 180, rgbm(0, 0.79, 0.17, 1), rgbm(1, 0, 0, 1))
	ui.endRotation(180, vec2(17, 243))

	ui.beginRotation()
	drawErsBar(car.kersCharge, -235, 513, 486, 35, 180, rgbm(0, 0.9, 1, 1))
	ui.endRotation(180, vec2(17, 243))

	drawDisplayBorders(borderColor, borderWidth, false)
	drawOverlayText()

	drawInPit()
end

local function displayRace(dt)
	drawRacePosition(13, 305, 70, ui.Alignment.Start)
	drawDelta(140, 305, 70)
	drawGapDelta(555, 305, 70)
	drawDRS(0, 540, 80, RareData)
	drawLapCount(770, 305, 70)

	drawGear(338, 470, 225)
	drawSpeed(338, 305, 75, ui.Alignment.Center)

	drawBrakeBiasActual(49, 580, 75, ui.Alignment.Start)
	drawEngineBrake(49, 690, 75, ui.Alignment.Start)
	drawMGUKRecovery(49, 800, 75, ui.Alignment.Start)

	drawTyreTC(309, 788, 302, 118, 104, 111)
	drawTyreCoreTemp(184, 669, 302, 118, 55, rgbm(0, 0, 0, 1))

	drawMGUKDelivery(338, 649, 50, ui.Alignment.Center)
	drawBatteryRemaining(338, 726, 55, ui.Alignment.Center)
	drawMguh(338, 803, 55, ui.Alignment.Center)

	drawFuelRemaining(620, 580, 75, ui.Alignment.End)
	drawLastLapFuelUse(620, 690, 75, ui.Alignment.End)
	drawTargetLapFuelUse(620, 800, 75, ui.Alignment.End)

	ui.beginRotation()
	drawErsBar((1 - car.kersLoad), 738, 513, 486, 35, 180, rgbm(0, 0.79, 0.17, 1), rgbm(1, 0, 0, 1))
	ui.endRotation(180, vec2(17, 243))

	ui.beginRotation()
	drawErsBar(car.kersCharge, -235, 513, 486, 35, 180, rgbm(0, 0.9, 1, 1))
	ui.endRotation(180, vec2(17, 243))

	drawDisplayBorders(borderColor, borderWidth, true)
	drawOverlayText(true)

	drawInPit()

	-- drawSplash()
end

local function displayLapEnd(dt)
	-- display.rect({
	-- 	pos = vec2(0, 0),
	-- 	size = vec2(1124, 1124),
	-- 	color = rgbm(0, 0, 0, 1),
	-- })

	drawRacePosition(13, 305, 65, ui.Alignment.Start)

	drawDelta(-50, 465, 95)
	drawLastLapTime(645, 465, 95)
	drawGear(338, 470, 225)
	drawLapCount(813, 305, 65)
	drawTargetMinusLastFuelUse(345, 730, 125, ui.Alignment.Center)
end

local function displayBrakeBias(dt)
	displayPopup("BRK BIAS", string.format("%.1f", car.brakeBias * 100), rgbm(1, 1, 1, 1))
end

local function displayMgukDelivery(dt)
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

	displayPopup("SOC", mgukDeliveryName, rgbm(1, 0, 1, 0.7))
end

local function displayMgukRecovery(dt)
	displayPopup("TORQ", car.mgukRecovery * 10, rgbm(0, 1, 0.5, 0.7))
end

local function displayMguhMode(dt)
	local mguhMode = ""

	if car.mguhChargingBatteries then
		mguhMode = "BATT"
	else
		mguhMode = "ENG"
	end

	displayPopup("MGU-H", mguhMode, rgbm(1, 0.1, 0.1, 0.5))
end

local function displayEngineBrake(dt)
	displayPopup("ENG BRK", car.currentEngineBrakeSetting, rgbm(1, 1, 1, 0.25))
end

local function displayBmig(dt)
	displayPopup(
		"BRK MIG",
		string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[1] * 100 + 1),
		rgbm(0, 0.4, 1, 1)
	)
end

local lastEntryDiff = ac.getCarPhysics(car.index).scriptControllerInputs[3]
local lastMidDiff = ac.getCarPhysics(car.index).scriptControllerInputs[4]
local lastHispdDiff = ac.getCarPhysics(car.index).scriptControllerInputs[5]
local lastDiffMode = ac.getCarPhysics(car.index).scriptControllerInputs[6] or 0

local function displayDiffMode(dt)
	local diffTitle = ""
	local diffValue = ""

	if lastDiffMode == 0 then
		diffTitle = "ENTRY"
		diffValue = string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[3] / 9 + 1)
	elseif lastDiffMode == 1 then
		diffTitle = "MID"
		diffValue = string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[4] / 9 + 1)
	else
		diffTitle = "HISPD"
		diffValue = string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[5] / 9 + 1)
	end

	displayPopup("DIFF " .. diffTitle, diffValue, rgbm(0.9, 0.3, 0, 0.91))
end

local function displayDiffEntry(dt)
	displayPopup(
		"DIFF ENTRY",
		string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[3] / 9 + 1),
		rgbm(0.9, 0.3, 0, 0.91)
	)
end

local function displayDiffMid(dt)
	displayPopup(
		"DIFF MID",
		string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[4] / 9 + 1),
		rgbm(0.9, 0.3, 0, 0.91)
	)
end

local function displayDiffHispd(dt)
	displayPopup(
		"DIFF HISPD",
		string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[5] / 9 + 1),
		rgbm(0.9, 0.3, 0, 0.91)
	)
end

local displays = {
	displayRace,
	displayWarmup,
	displayBrakeBias,
	displayMgukDelivery,
	displayMgukRecovery,
	displayMguhMode,
	displayEngineBrake,
	displayBmig,
	displayDiffMode,
	displayDiffEntry,
	displayDiffMid,
	displayDiffHispd,
	displayLapEnd,
}

local mainDisplayCount = 2
local currentMode = stored.activeDisplay

local lastBrakeBias = car.brakeBias
local lastMgukDelivery = car.mgukDelivery
local lastMgukRecovery = car.mgukRecovery
local lastMguhMode = car.mguhChargingBatteries
local lastEngineBrake = car.currentEngineBrakeSetting
local lastBmig = ac.getCarPhysics(car.index).scriptControllerInputs[1]
local lastLap = car.lapCount

local lastExtraFState = car.extraF

local tempMode = 1
local timer = 0

local function addTime(seconds)
	if not seconds then
		seconds = 0.5
	end
	timer = os.clock() + seconds
	-- timer = os.preciseClock() + seconds
end

local function resetLastStates()
	lastExtraFState = car.extraF
	lastBrakeBias = car.brakeBias
	lastMgukRecovery = car.mgukRecovery
	lastMguhMode = car.mguhChargingBatteries
	lastEngineBrake = car.currentEngineBrakeSetting
	lastEngineBrake = car.currentEngineBrakeSetting
	lastBmig = ac.getCarPhysics(car.index).scriptControllerInputs[1]
	lastDiffMode = ac.getCarPhysics(car.index).scriptControllerInputs[6]
	lastEntryDiff = ac.getCarPhysics(car.index).scriptControllerInputs[3]
	lastMidDiff = ac.getCarPhysics(car.index).scriptControllerInputs[4]
	lastHispdDiff = ac.getCarPhysics(car.index).scriptControllerInputs[5]
	lastLap = car.lapCount
end

--- Switches to a temporary display if the conditions are met
local function setDisplayMode()
	if ac.getSim().isInMainMenu then
		resetLastStates()
	end
	-- Save the last main display
	local _currentMode = currentMode
	if car.extraF ~= lastExtraFState then
		_currentMode = _currentMode + 1
		if _currentMode > mainDisplayCount then
			_currentMode = 1
		end
		currentMode = _currentMode
		stored.activeDisplay = _currentMode
	end
	lastExtraFState = car.extraF

	-- If either brake bias or mguk delivery is not the same from the last script update, then start a timer
	-- If the driver changes bb or mgukd, reset the timer
	-- This also takes care of showing both displays if both bb and mgukd are changed
	if lastBrakeBias ~= car.brakeBias then
		lastBrakeBias = car.brakeBias
		addTime()
		tempMode = 3
		return tempMode
	elseif lastMgukDelivery ~= car.mgukDelivery then
		lastMgukDelivery = car.mgukDelivery
		addTime()
		tempMode = 4
		return tempMode
	elseif lastMgukRecovery ~= car.mgukRecovery then
		lastMgukRecovery = car.mgukRecovery
		addTime()
		tempMode = 5
		return tempMode
	elseif lastMguhMode ~= car.mguhChargingBatteries then
		lastMguhMode = car.mguhChargingBatteries
		addTime()
		tempMode = 6
		return tempMode
	elseif lastEngineBrake ~= car.currentEngineBrakeSetting then
		lastEngineBrake = car.currentEngineBrakeSetting
		addTime()
		tempMode = 7
		return tempMode
	elseif lastBmig ~= ac.getCarPhysics(car.index).scriptControllerInputs[1] then
		lastBmig = ac.getCarPhysics(car.index).scriptControllerInputs[1]
		addTime()
		tempMode = 8
		return tempMode
	elseif lastDiffMode ~= ac.getCarPhysics(car.index).scriptControllerInputs[6] then
		lastDiffMode = ac.getCarPhysics(car.index).scriptControllerInputs[6]
		addTime()
		tempMode = 9
		return tempMode
	elseif lastEntryDiff ~= ac.getCarPhysics(car.index).scriptControllerInputs[3] then
		lastEntryDiff = ac.getCarPhysics(car.index).scriptControllerInputs[3]
		addTime()
		tempMode = 10
		return tempMode
	elseif lastMidDiff ~= ac.getCarPhysics(car.index).scriptControllerInputs[4] then
		lastMidDiff = ac.getCarPhysics(car.index).scriptControllerInputs[4]
		addTime()
		tempMode = 11
		return tempMode
	elseif lastHispdDiff ~= ac.getCarPhysics(car.index).scriptControllerInputs[5] then
		lastHispdDiff = ac.getCarPhysics(car.index).scriptControllerInputs[5]
		addTime()
		tempMode = 12
		return tempMode
	elseif lastLap ~= car.lapCount then
		lastLap = car.lapCount
		addTime(3)
		tempMode = 13
		return tempMode
	else
		-- if timer > os.preciseClock() then
		if timer > os.clock() then
			return tempMode
		else -- Once the timer has ended, return the last main display
			return _currentMode
		end
	end
end

-- If above 0 and there is no user input going on, skip a frame
local skipFrames = 0

function script.update(dt)
	-- Skip two frames, draw on third
	local skipThisFrame = skipFrames > 0
	skipFrames = skipThisFrame and skipFrames - 1 or 2

	if skipThisFrame then
		-- Not only it helps with performance, but, more importantly, such display feels more display-ish without
		-- smoothest 60 FPS refresh rate
		ac.skipFrame()
		return
	end

	-- Multiplying by 3, becase two out of three frames are skipped
	dt = dt * 3

	updateSlow(dt)

	drawDisplayBackground(displaySize, backgroundColor)

	local displayMode = setDisplayMode()
	displays[displayMode](dt)

	-- display.rect({
	-- 	pos = vec2(0, 605),
	-- 	size = vec2(414, 80),
	-- 	color = rgbm(1, 0, 1, 1),
	-- })

	drawDisplayOverlay(displaySize, rgbm(0.1, 0.1, 0.1, 0.15))

	-- drawGridLines()
end
