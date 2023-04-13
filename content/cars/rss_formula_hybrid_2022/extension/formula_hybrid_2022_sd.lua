-- Initial code idea developed from Ilja's scriptable display example

require("src/formula_display")

-- User settings (stored between sessions)
local stored = ac.storage({
	activeDisplay = 1, -- Index of active display (starting with 1)
	splashShown = false,
})

stored.splashShown = false

--region Display Constants

-- Display setup
local displayColors = {
	lightGreen = rgbm(0.3, 1, 0.6, 0.7),
	activeGreen = rgbm(0, 0.6, 0.2, 1),
	lightBlue = rgbm(0.2, 0.9, 1, 1),
	offWhite = rgbm(1, 1, 1, 0.7),
	red = rgbm(1, 0, 0, 0.8),
	warningYellow = rgbm(1, 1, 0, 1),
}

local backgroundColor = rgbm(0, 0, 0, 1)
local displaySize = vec2(1020, 1024) -- Size of the display in pixels
local centerText = 335
local displayFontName = "Default"
local displayFont = ui.DWriteFont(displayFontName)
local displayFontBold = ui.DWriteFont(displayFontName):weight(ui.DWriteFont.Weight.Bold)
local displayFontBlack = ui.DWriteFont(displayFontName):weight(ui.DWriteFont.Weight.Black)
local displayFontSemiBold = ui.DWriteFont(displayFontName):weight(ui.DWriteFont.Weight.SemiBold)

--endregion

--region Data Collection and Formatting

-- General script consts.
local slowRefreshPeriod = 0.5
local fastRefreshPeriod = 0.12
local fastestRefreshPeriod = 0.05

-- Mirrors original car state, but with slower refresh rate. Also a good place to convert units and do other preprocessing.
local sdata = {}
local delaySlow = slowRefreshPeriod
local delayFast = fastRefreshPeriod
local delayFastest = fastestRefreshPeriod

local mgukDeliveryShortNames = {
	"NODLY",
	"CHRGE",
	"LOW",
	"BALCD",
	"HIGH",
	ac.getSim().raceSessionType == 3 and "ATTCK" or "QUAL",
}

local function updateData(dt)
	delaySlow = delaySlow + dt
	if delaySlow > slowRefreshPeriod then
		delaySlow = 0

		sdata.position = getLeaderboardPosition(car.index)
		sdata.racePosition = "P" .. car.racePosition

		sdata.bestLapTimeMs = ac.lapTimeToString(car.bestLapTimeMs)
		sdata.previousLapTimeMs = ac.lapTimeToString(car.previousLapTimeMs)
		sdata.previousLapValidColor = car.isLastLapValid and displayColors.offWhite or displayColors.red
		sdata.sessionLaps = ac.getSession(ac.getSim().currentSessionIndex).laps
				and ac.getSession(ac.getSim().currentSessionIndex).laps
			or "--"
		sdata.lapCount = sdata.sessionLaps == 0 and tostring(car.lapCount + 1)
			or tostring(car.lapCount + 1) .. "/" .. sdata.sessionLaps
		sdata.currentEngineBrakeSetting = car.currentEngineBrakeSetting
		sdata.mgukRecovery = car.mgukRecovery
		sdata.compoundIndex = car.compoundIndex
		sdata.compoundName = ac.getTyresName(car.index, car.compoundIndex)
		sdata.mgukDelivery = car.mgukDelivery
		sdata.mgukDeliveryName = mgukDeliveryShortNames[car.mgukDelivery + 1]
		sdata.batteryCharge = math.round(car.kersCharge * 100, 0)
		sdata.kersCharge = car.kersCharge
		sdata.kersLoad = 1 - car.kersLoad
		sdata.mguhMode = car.mguhChargingBatteries and "BATT" or "ENG"
		sdata.isInPitlane = car.isInPitlane
		sdata.fuel = string.format("%.1f", car.fuel)
		sdata.fuelPerLap = string.format("%.2f", car.fuelPerLap)
		sdata.speedKmh = math.floor(car.speedKmh)
		sdata.currentTime = string.format("%02d:%02d", sim.timeHours, sim.timeMinutes)
		sdata.targetFuelUse = sdata.sessionLaps == 0 and sdata.fuelPerLap or 140 / sdata.sessionLaps

		if sdata.batteryCharge >= 65 then
			sdata.batteryChargeColor = displayColors.activeGreen
		elseif sdata.batteryCharge > 35 then
			sdata.batteryChargeColor = displayColors.warningYellow
		else
			sdata.batteryChargeColor = displayColors.red
		end
	end

	delayFast = delayFast + dt
	if delayFast > fastRefreshPeriod then
		delayFast = 0
		sdata.lapTimeMs = ac.lapTimeToString(car.lapTimeMs)
		sdata.gear = car.gear
		sdata.performanceMeter = string.format("%.2f", math.clamp(car.performanceMeter, -99.99, 99.99))
		sdata.carAheadIndex = getCarAheadIndex(car.index)
		sdata.gapToCarAhead = car.racePosition > 1
				and string.format("%.2f", ac.getGapBetweenCars(car.index, sdata.carAheadIndex))
			or "-:---"

		if not ac.getSim().isSessionStarted then
			sdata.gapToCarAhead = "-:---"
		end

		sdata.estimatedLapTimeMs = car.bestLapTimeMs + (car.performanceMeter * 1000)
		sdata.performanceMeterLastLap =
			math.clamp((sdata.estimatedLapTimeMs - car.previousLapTimeMs) / 1000, -99.99, 99.99)
		sdata.performanceMeterLastLap = sdata.performanceMeterLastLap == 0 and "-:---"
			or string.format("%.2f", sdata.performanceMeterLastLap)

		if car.performanceMeter < 0 then
			sdata.performanceColor = displayColors.activeGreen
		elseif car.performanceMeter > 0 then
			sdata.performanceColor = displayColors.red
		else
			sdata.performanceColor = displayColors.offWhite
		end

		sdata.wheels = car.wheels
		sdata.brakeBiasActual =
			string.format("%.1f", math.round(100 * ac.getCarPhysics(car.index).scriptControllerInputs[0], 1))
	end

	delayFastest = delayFastest + dt
	if delayFastest > fastestRefreshPeriod then
		delayFastest = 0
		sdata.poweredWheelsSpeed = math.round(car.poweredWheelsSpeed)
	end

	sdata.brakeBiasMigration = string.format("%0.f", ac.getCarPhysics(car.index).scriptControllerInputs[1] * 100 + 1)
	sdata.differentialEntry = math.round(ac.getCarPhysics(car.index).scriptControllerInputs[3] / 9) + 1
	sdata.differentialMid = math.round(ac.getCarPhysics(car.index).scriptControllerInputs[4] / 9) + 1
	sdata.differentialHispd = math.round(ac.getCarPhysics(car.index).scriptControllerInputs[5] / 9) + 1
	sdata.differentialMode = ac.getCarPhysics(car.index).scriptControllerInputs[6]
end

--endregion

--region Main Displays

local mgukColor = {
	NODLY = rgbm(1, 1, 1, 0.7),
	CHRGE = rgbm(0, 0.6, 0.2, 1),
	LOW = rgbm(0, 0.6, 0.2, 1),
	BALCD = rgbm(0, 0.6, 0.2, 1),
	HIGH = rgbm(0, 0.6, 0.2, 1),
	ATTCK = rgbm(1, 0, 1, 1),
	QUAL = rgbm(1, 0, 1, 1),
}

local function drawTopInfoBar()
	drawValue(displayFont, sdata.racePosition, 75, 13, 300, ui.Alignment.Start)
	drawValue(displayFont, sdata.poweredWheelsSpeed, 75, centerText, 300, ui.Alignment.Center)
	drawValue(displayFont, sdata.lapCount, 75, 655, 300, ui.Alignment.End)
end

local function displayShared(image)
	drawTopInfoBar()

	drawErsBar(sdata.kersCharge, -218, 749, 495, 45, 180, displayColors.lightBlue)
	drawErsBar(sdata.kersLoad, 746, 749, 495, 45, 180, displayColors.lightGreen)

	ui.drawRectFilled(vec2(414, 796), vec2(608, 866), mgukColor[sdata.mgukDeliveryName])
	drawValue(
		displayFontBold,
		sdata.mgukDelivery .. " " .. sdata.mgukDeliveryName,
		43,
		centerText,
		654,
		ui.Alignment.Center,
		car.mgukDelivery == 0 and rgbm(0, 0, 0, 1) or rgbm(1, 1, 1, 1)
	)
	drawValue(
		displayFontSemiBold,
		sdata.batteryCharge,
		65,
		centerText + 33,
		733,
		ui.Alignment.Center,
		sdata.batteryChargeColor
	)
	drawValue(displayFontSemiBold, sdata.mguhMode, 50, centerText + 33, 817, ui.Alignment.Center)

	ui.setCursorY(441)
	ui.setCursorX(2)
	ui.image(image, vec2(1017, 582), true)

	drawTyreTC(sdata, 285, 823, 412, 91, 40, 80)
	drawTyreCoreTemp(sdata, displayFontSemiBold, 189, 683, 289, 95, 38, rgbm(1, 1, 1, 0.7))

	if car.isInPitlane then
		drawInPit()
	else
		drawDRS(0, 602, 70)
	end

	drawOvertake()
	drawFlag()
	drawGear(sdata, centerText + 1, 470, 250)
end

--Draws the Mode A display
local function displayWarmup(dt)
	drawValue(displayFont, sdata.brakeBiasActual, 55, -55, 579, ui.Alignment.Center, rgbm(1, 0.5, 0, 0.9))
	drawValue(displayFont, sdata.currentEngineBrakeSetting, 55, 56, 579, ui.Alignment.Center)
	drawValue(displayFont, sdata.mgukRecovery, 55, 165, 579, ui.Alignment.Center)

	drawValue(displayFont, sdata.previousLapTimeMs, 70, 610, 385, ui.Alignment.End, sdata.previousLapValidColor)
	drawValue(displayFont, sdata.performanceMeter, 70, 610, 479, ui.Alignment.End, sdata.performanceColor)
	drawValue(displayFont, sdata.bestLapTimeMs, 70, 610, 562, ui.Alignment.End, rgbm(1, 0, 1, 0.7))

	drawValue(displayFont, sdata.differentialEntry, 55, -51, 402, ui.Alignment.Center)
	drawValue(displayFont, sdata.differentialMid, 55, 56, 402, ui.Alignment.Center)
	drawValue(displayFont, sdata.differentialHispd, 55, 165, 402, ui.Alignment.Center)

	drawValue(displayFont, sdata.compoundName, 52, -152, 662, ui.Alignment.End)
	drawValue(displayFont, sdata.currentTime, 52, 65, 805, ui.Alignment.Start, rgbm(1, 1, 0, 1))

	drawBrakes(sdata, 57, 872, 0, 36, 142, 36)
	drawTyrePressure(sdata, displayFontSemiBold, 67, 683, 534, 95, 38)

	drawValue(displayFont, sdata.fuel, 52, 613, 662, ui.Alignment.End)
	drawValue(displayFont, sdata.fuelPerLap, 52, 613, 737, ui.Alignment.End)
	drawValue(displayFont, sdata.fuelPerLap, 52, 613, 814, ui.Alignment.End)

	displayShared("src/display_warmup.png")
end

local function displayRace(dt)
	drawValue(displayFont, sdata.brakeBiasActual, 65, 58, 590, ui.Alignment.Start, rgbm(1, 0.5, 0, 0.9))
	drawValue(displayFont, sdata.performanceMeterLastLap, 65, 58, 695, ui.Alignment.Start)
	drawValue(displayFont, sdata.gapToCarAhead, 65, 58, 800, ui.Alignment.Start)

	drawValue(displayFont, sdata.fuel, 65, 613, 590, ui.Alignment.End)
	drawValue(displayFont, sdata.fuelPerLap, 65, 613, 695, ui.Alignment.End)
	drawValue(displayFont, sdata.targetFuelUse, 65, 613, 800, ui.Alignment.End)

	displayShared("src/display_race.png")
end

--endregion

--region Popup Displays

local initializeBlink = 0
local function displaySplash(dt)
	drawSplash()

	if initializeBlink <= 2 then
		drawValue(
			displayFont,
			"Establishing Connection...",
			30,
			centerText,
			800,
			ui.Alignment.Center,
			displayColors.offWhite
		)
		initializeBlink = initializeBlink + 1
	else
		initializeBlink = 0
	end
end

local function displayLaunch(dt)
	displayShared("src/display_race.png")
	drawLaunch(car.rpm)
	drawValue(displayFont, sdata.brakeBiasActual, 65, 56, 590, ui.Alignment.Start, rgbm(1, 0.5, 0, 0.9))
end

local function displayBrakeBias(dt)
	displayPopup("BRK BIAS", string.format("%.1f", car.brakeBias * 100), rgbm(1, 0.5, 0, 0.9))
end

local function displayMgukDelivery(dt)
	local mgukDelivery = mgukDeliveryShortNames[car.mgukDelivery + 1]

	displayPopup("SOC", mgukDelivery, rgbm(1, 1, 1, 0.7))
end

local function displayMgukRecovery(dt)
	displayPopup("TORQ", car.mgukRecovery, rgbm(0, 1, 0.5, 0.7))
end

local function displayMguhMode(dt)
	displayPopup("MGU-H", car.mguhChargingBatteries and "BATT" or "ENG", rgbm(1, 0.15, 0.1, 0.5))
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
local lastEntryDiff = sdata.differentialEntry
local lastMidDiff = sdata.differentialMid
local lastHispdDiff = sdata.differentialHispd
local lastDiffMode = sdata.differentialMode

local function displayDiff(dt)
	local diffTitle, diffValue

	if lastDiffMode == 0 then
		diffTitle = "ENTRY"
		diffValue = sdata.differentialEntry
	elseif lastDiffMode == 1 then
		diffTitle = "MID"
		diffValue = sdata.differentialMid
	else
		diffTitle = "HISPD"
		diffValue = sdata.differentialHispd
	end

	displayPopup("DIFF " .. diffTitle, diffValue, rgbm(1, 0.2, 1, 1))
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
	displayDiff,
	displaySplash,
	displayLaunch,
}

local mainDisplayCount = 2
local currentMode = stored.activeDisplay

local lastBrakeBias = car.brakeBias
local lastMgukDelivery = car.mgukDelivery
local lastMgukRecovery = car.mgukRecovery
local lastMguhMode = car.mguhChargingBatteries
local lastEngineBrake = car.currentEngineBrakeSetting
local lastBmig = sdata.brakeBiasMigration
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
	lastBmig = sdata.brakeBiasMigration
	lastEntryDiff = sdata.differentialEntry
	lastMidDiff = sdata.differentialMid
	lastHispdDiff = sdata.differentialHispd
	lastDiffMode = sdata.differentialMode
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
	if not stored.splashShown and ac.getSim().isFocusedOnInterior then
		stored.splashShown = true
		addTime(3)
		tempMode = 10
	elseif not stored.splashShown then
		drawDisplayBackground(displaySize, backgroundColor)
	elseif car.clutch == 0 and car.speedKmh < 1 and not ac.getSim().isInMainMenu then
		addTime()
		tempMode = 11
		return tempMode
	elseif lastBrakeBias ~= car.brakeBias then
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
	elseif lastBmig ~= sdata.brakeBiasMigration then
		lastBmig = sdata.brakeBiasMigration
		addTime()
		tempMode = 8
		return tempMode
	elseif lastDiffMode ~= sdata.differentialMode then
		lastDiffMode = sdata.differentialMode
		addTime()
		tempMode = 9
		return tempMode
	elseif lastEntryDiff ~= sdata.differentialEntry then
		lastEntryDiff = sdata.differentialEntry
		addTime()
		tempMode = 9
		return tempMode
	elseif lastMidDiff ~= sdata.differentialMid then
		lastMidDiff = sdata.differentialMid
		addTime()
		tempMode = 9
		return tempMode
	elseif lastHispdDiff ~= sdata.differentialHispd then
		lastHispdDiff = sdata.differentialHispd
		addTime()
		tempMode = 9
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

	updateData(dt)
	drawDisplayBackground(displaySize, backgroundColor)
	displays[getDisplayMode() or 1](dt)
	drawDisplayBackground(displaySize, rgbm(0, 0, 0, 0.2))

	-- drawGridLines()
	-- drawAlignments()
	-- drawZones()
end
