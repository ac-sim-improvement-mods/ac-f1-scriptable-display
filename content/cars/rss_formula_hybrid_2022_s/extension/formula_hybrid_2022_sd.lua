require("src/formula_display")
local overlay = require("src/overlay")
-- User settings (stored between sessions)
local stored = ac.storage({
	activeDisplay = 1, -- Index of active display (starting with 1)
	lapDeltaOption = true,

	-- Display settings:
	launchGate = 5000,
	launchGateOn = true,

	-- Lap time popup:
	lapTimePopup = 8,
	lapTimePopupOn = true,
})

--region Display Constants

-- Display setup
local backgroundColor = rgbm(0, 0, 0, 1)
local displaySize = vec2(1020, 1024) -- Size of the display in pixels
local borderColor = rgbm(0.4, 0.4, 0.4, 1)
local borderWidth = 5
local centerText = 335
local displayFontName = "Default"
local displayFont = ui.DWriteFont(displayFontName)
local displayFontBold = ui.DWriteFont(displayFontName):weight(ui.DWriteFont.Weight.Bold)
local displayFontBlack = ui.DWriteFont(displayFontName):weight(ui.DWriteFont.Weight.Black)

--endregion

--region Data Collection and Formatting

-- General script consts.
local slowRefreshPeriod = 0.5
local fastRefreshPeriod = 0.12
local fastestRefreshPeriod = 0.05
local halfPosSeg = 11

-- Mirrors original car state, but with slower refresh rate. Also a good place to convert units and do other preprocessing.
local slow = {}
local delaySlow = slowRefreshPeriod
local delayFast = fastRefreshPeriod
local delayFastest = fastestRefreshPeriod

local mgukDeliveryShortNames = {
	"NODLY",
	"CHRGE",
	"LOW",
	"BALCD",
	"HIGH",
	"ATTCK",
}

function updateSlow2(dt)
	delaySlow = delaySlow + dt
	if delaySlow > slowRefreshPeriod then
		delaySlow = 0

		slow.position = getLeaderboardPosition(car.index)
		slow.carAheadIndex = getCarAheadIndex(car.index)
		ac.debug("position", slow.position)
		ac.debug("ahead", slow.carAheadIndex)
		slow.brakeBiasMigration = ac.getCarPhysics(car.index).scriptControllerInputs[1] * 100 + 1
		slow.brakeBiasActual =
			string.format("%.1f", math.round(100 * ac.getCarPhysics(car.index).scriptControllerInputs[0], 1))
		slow.differentialEntry = math.round(ac.getCarPhysics(car.index).scriptControllerInputs[3] / 9) + 1
		slow.differentialMid = math.round(ac.getCarPhysics(car.index).scriptControllerInputs[4] / 9) + 1
		slow.differentialHispd = math.round(ac.getCarPhysics(car.index).scriptControllerInputs[5] / 9) + 1

		slow.racePosition = "P" .. car.racePosition
		-- slow.gapToCarAhead = car.racePosition > 1 and ac.getGapBetweenCars(car.index, ) or "-:---"
		-- ac.debug("pos", car.racePosition)
		slow.bestLapTimeMs = ac.lapTimeToString(car.bestLapTimeMs)
		slow.previousLapTimeMs = ac.lapTimeToString(car.previousLapTimeMs)
		slow.lapCount = car.lapCount + 1
		slow.currentEngineBrakeSetting = car.currentEngineBrakeSetting
		slow.mgukRecovery = car.mgukRecovery * 10
		slow.compoundIndex = car.compoundIndex
		slow.compoundName = ac.getTyresName(car.index, car.compoundIndex)
		slow.mgukDelivery = car.mgukDelivery
		slow.mgukDeliveryName = car.mgukDelivery .. " " .. mgukDeliveryShortNames[car.mgukDelivery + 1]
		slow.batteryCharge = math.round(car.kersCharge * 100, 0)
		slow.kersCharge = car.kersCharge
		slow.kersLoad = 1 - car.kersLoad
		slow.mguhMode = car.mguhChargingBatteries and "BATT" or "ENG"
		slow.isInPitlane = car.isInPitlane
		slow.fuel = math.round(car.fuel)
		slow.fuelPerLap = string.format("%.2f", car.fuelPerLap)
		slow.speedKmh = math.floor(car.speedKmh)
		slow.currentTime = string.format("%02d:%02d:%02d", sim.timeHours, sim.timeMinutes, sim.timeSeconds)
		slow.sessionLapCount = ac.getSession(ac.getSim().currentSessionIndex).laps
				and ac.getSession(ac.getSim().currentSessionIndex).laps ~= 0
				and (slow.lapCount .. "/" .. ac.getSession(ac.getSim().currentSessionIndex).laps)
			or slow.lapCount
	end

	delayFast = delayFast + dt
	if delayFast > fastRefreshPeriod then
		delayFast = 0
		slow.lapTimeMs = ac.lapTimeToString(car.lapTimeMs)
		slow.gear = car.gear
		slow.performanceMeter = string.format("%+.3f", math.clamp(car.performanceMeter, -99.999, 99.999))
		slow.wheels = car.wheels
	end

	delayFastest = delayFastest + dt
	if delayFastest > fastestRefreshPeriod then
		delayFastest = 0
		slow.poweredWheelsSpeed = math.round(car.poweredWheelsSpeed)
	end
end

--endregion

--region Main Displays

--Draws the Mode A display
local function displayWarmup(dt)
	drawText2(displayFont, slow.racePosition, 70, 13, 305, ui.Alignment.Start)
	drawText2(displayFont, slow.performanceMeter, 70, 45, 305, ui.Alignment.End)

	drawText2(displayFont, slow.poweredWheelsSpeed, 70, centerText, 305, ui.Alignment.Center)
	drawText2(displayFont, slow.lapCount, 70, 655, 305, ui.Alignment.End)
	drawText2(displayFont, slow.lapTimeMs, 70, 625, 305, ui.Alignment.Start)

	drawText2(displayFont, slow.brakeBiasActual, 60, -68, 573, ui.Alignment.Center, rgbm(1, 0.5, 0, 0.9))
	drawText2(displayFont, slow.currentEngineBrakeSetting, 60, 55, 573, ui.Alignment.Center)
	drawText2(displayFont, slow.mgukRecovery, 60, 178, 573, ui.Alignment.Center)

	drawText2(displayFont, slow.previousLapTimeMs, 70, 625, 390, ui.Alignment.Start)
	drawText2(displayFont, slow.bestLapTimeMs, 70, 45, 390, ui.Alignment.End)

	drawText2(displayFont, slow.differentialEntry, 60, 494, 573, ui.Alignment.Center)
	drawText2(displayFont, slow.differentialMid, 60, 616, 573, ui.Alignment.Center)
	drawText2(displayFont, slow.differentialHispd, 60, 739, 573, ui.Alignment.Center)

	drawText2(displayFont, slow.compoundName, 55, 52, 647, ui.Alignment.Start)
	drawText2(displayFont, slow.currentTime, 39, 50, 805, ui.Alignment.Start)

	drawBrakes(47, 869, 0, 38, 153, 38)
	drawTyreTC(310, 788, 298, 117, 104.5, 112)
	drawTyreCoreTemp(186, 667, 298, 118, 55, rgbm(0, 0, 0, 1))
	drawTyrePressure(80, 667, 509, 118, 45)

	drawText2(displayFontBlack, slow.mgukDeliveryName, 40, centerText, 649, ui.Alignment.Center)
	drawText2(displayFont, slow.batteryCharge, 65, centerText + 33, 726, ui.Alignment.Center)
	drawText2(displayFont, slow.mguhMode, 40, centerText + 33, 810, ui.Alignment.Center)

	drawText2(displayFont, slow.fuel, 55, 620, 647, ui.Alignment.End)
	drawText2(displayFont, slow.fuelPerLap, 55, 620, 725, ui.Alignment.End)
	drawText2(displayFont, slow.fuelPerLap, 55, 620, 805, ui.Alignment.End)

	drawErsBar(slow.kersLoad, 736, 512.5, 490, 35, 180, rgbm(0, 0.79, 0.17, 1), rgbm(1, 0, 0, 1))
	drawErsBar(slow.kersCharge, -237, 512.5, 490, 35, 180, rgbm(0, 0.85, 1, 1))

	if car.isInPitlane then
		-- drawInPit()
	else
		drawDRS(0, 602, 70)
		drawOvertake()
	end

	drawFlag()
	drawGear(centerText, 470, 225)

	overlay.drawWarmupBorders(borderColor, borderWidth)
	overlay.drawWarmupText()
end

local function displayRace(dt)
	drawText2(displayFont, slow.racePosition, 70, 13, 305, ui.Alignment.Start)
	drawText2(displayFont, slow.sessionLapCount, 70, 655, 305, ui.Alignment.End)

	drawText2(displayFont, slow.poweredWheelsSpeed, 70, centerText, 305, ui.Alignment.Center)

	drawBrakeBiasActual(49, 590, 65, ui.Alignment.Start)
	drawLastDelta(49, 695, 65, ui.Alignment.Start)
	drawGapDelta(49, 800, 65, ui.Alignment.Start)
	drawText2(displayFont, slow.brakeBiasActual, 65, 49, 590, ui.Alignment.Start, rgbm(1, 0.5, 0, 0.9))
	drawText2(displayFont, slow.compoundName, 65, 49, 695, ui.Alignment.Start)
	drawText2(displayFont, slow.gapToCarAhead, 65, 49, 800, ui.Alignment.Start)

	drawTyreTC(310, 788, 298, 117, 104.5, 112)
	drawTyreCoreTemp(186, 667, 298, 118, 55, rgbm(0, 0, 0, 1))

	drawText2(displayFontBlack, slow.mgukDeliveryName, 40, centerText, 649, ui.Alignment.Center)
	drawText2(displayFont, slow.batteryCharge, 65, centerText + 33, 726, ui.Alignment.Center)
	drawText2(displayFont, slow.mguhMode, 40, centerText + 33, 810, ui.Alignment.Center)

	drawText2(displayFont, slow.fuel, 65, 620, 590, ui.Alignment.End)
	drawText2(displayFont, slow.fuelPerLap, 65, 620, 695, ui.Alignment.End)
	drawText2(displayFont, slow.fuelPerLap, 65, 620, 800, ui.Alignment.End)

	drawErsBar((1 - car.kersLoad), 736, 512.5, 490, 35, 180, rgbm(0, 0.79, 0.17, 1), rgbm(1, 0, 0, 1))
	drawErsBar(car.kersCharge, -237, 512.5, 490, 35, 180, rgbm(0, 0.85, 1, 1))

	if car.isInPitlane then
		drawInPit()
	else
		drawDRS(0, 602, 70)
		drawOvertake()
	end

	drawFlag()
	drawGear(centerText, 470, 225)

	overlay.drawRaceBorders(borderColor, borderWidth)
	overlay.drawRaceText()

	-- drawSplash()
end

--endregion

--region Popup Displays

local function displayLapEnd(dt)
	drawOvertake()
	drawFlag()
	drawDRS(0, 602, 70)
	drawRacePosition(13, 305, 90, ui.Alignment.Start)
	drawLastLapDelta(148, 305, 70, ui.Alignment.Start)
	drawLastLapTime(623, 305, 70, ui.Alignment.Start)
	drawSpeed(centerText, 305, 75, ui.Alignment.Center)
	drawGear(centerText, 470, 225)
	drawLapCount(655, 305, 90, ui.Alignment.End)
	drawTargetMinusLastFuelUse(325, 720, 125, ui.Alignment.Center)
end

local function displayBrakeBias(dt)
	displayPopup("BRK BIAS", string.format("%.1f", car.brakeBias * 100), rgbm(1, 1, 1, 1))
end

local function displayMgukDelivery(dt)
	local mgukDelivery = mgukDeliveryShortNames[car.mgukDelivery + 1]

	displayPopup("SOC", mgukDelivery, rgbm(1, 0, 1, 0.7))
end

local function displayMgukRecovery(dt)
	displayPopup("TORQ", car.mgukRecovery * 10, rgbm(0, 1, 0.5, 0.7))
end

local function displayMguhMode(dt)
	displayPopup("MGU-H", car.mguhChargingBatteries and "BATT" or "ENG", rgbm(1, 0.1, 0.1, 0.5))
end

local function displayEngineBrake(dt)
	displayPopup("ENG BRK", car.currentEngineBrakeSetting, rgbm(1, 1, 1, 0.45))
end

local function displayBmig(dt)
	displayPopup(
		"BRK MIG",
		string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[1] * 100 + 1),
		rgbm(0, 0.4, 1, 1)
	)
end

--region Differential
local lastEntryDiff = ac.getCarPhysics(car.index).scriptControllerInputs[3]
local lastMidDiff = ac.getCarPhysics(car.index).scriptControllerInputs[4]
local lastHispdDiff = ac.getCarPhysics(car.index).scriptControllerInputs[5]
local lastDiffMode = ac.getCarPhysics(car.index).scriptControllerInputs[6] or 0

local diffColor = rgbm(1, 0.5, 0, 1)

local function displayDiffMode(dt)
	local diffTitle, diffValue

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

	displayPopup("DIFF " .. diffTitle, diffValue, diffColor)
end

local function displayDiffEntry(dt)
	displayPopup(
		"DIFF ENTRY",
		string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[3] / 9 + 1),
		diffColor
	)
end

local function displayDiffMid(dt)
	displayPopup(
		"DIFF MID",
		string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[4] / 9 + 1),
		diffColor
	)
end

local function displayDiffHispd(dt)
	displayPopup(
		"DIFF HISPD",
		string.format("%.0f", ac.getCarPhysics(car.index).scriptControllerInputs[5] / 9 + 1),
		diffColor
	)
end

--endregion

--endregion

--region Display Switching

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
local function getDisplayMode()
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
		if car.isInPitlane then
			-- if timer > os.preciseClock() then
			if timer > os.clock() then
				return tempMode
			else -- Once the timer has ended, return the last main display
				return _currentMode
			end
		end
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

--endregion

local skipFrames = 0

function script.update(dt)
	local skipThisFrame = skipFrames > 0
	skipFrames = skipThisFrame and skipFrames - 1 or 2

	if skipThisFrame then
		ac.skipFrame()
		return
	end

	dt = dt * 3

	updateSlow(dt)
	updateSlow2(dt)
	drawDisplayBackground(displaySize, backgroundColor)
	displays[getDisplayMode()](dt)
	overlay.drawDisplayOverlay(displaySize, rgbm(0.1, 0.1, 0.1, 0.25))
	-- drawGridLines()
	-- drawAlignments()
	-- drawZones()
end
