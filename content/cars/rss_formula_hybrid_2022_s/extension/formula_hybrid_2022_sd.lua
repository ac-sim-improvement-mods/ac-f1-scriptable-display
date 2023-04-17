---@diagnostic disable: undefined-global
-- Initial code idea developed from Ilja's scriptable display example

require("src/formula_display")

local ext_config = ac.INIConfig.load(
	ac.getFolder(ac.FolderID.ContentCars) .. "\\" .. ac.getCarID(0) .. "\\extension\\ext_config.ini",
	ac.INIFormat.ExtendedIncludes
)

local targetLaunchRPM = ext_config:get("SCRIPTABLE_DISPLAY_CONFIG", "TARGET_LAUNCH_RPM", 0.5)
local popupScreenTime = ext_config:get("SCRIPTABLE_DISPLAY_CONFIG", "POPUP_TIME", 0.5)
local initializationScreenTime = ext_config:get("SCRIPTABLE_DISPLAY_CONFIG", "INITIALIZE_TIME", 2)
local brightnessNight = ext_config:get("SCRIPTABLE_DISPLAY_CONFIG", "BRIGHTNESS_NIGHT", 3)
local brightnessNightNotFPV = ext_config:get("SCRIPTABLE_DISPLAY_CONFIG", "BRIGHTNESS_NIGHT_NOT_FPV", 4)
local brightnessDay = ext_config:get("SCRIPTABLE_DISPLAY_CONFIG", "BRIGHTNESS_DAY", 4)
local brightnessDayNotFPV = ext_config:get("SCRIPTABLE_DISPLAY_CONFIG", "BRIGHTNESS_DAY_NOT_FPV", 0.5)

local stored = ac.storage({
	activeDisplay = 1, -- Index of active display (starting with 1)
	splashShown = false,
	initialized = false,
})

stored.splashShown = false
stored.initialized = false

--region Display Constants

-- Display setup
local displayColors = {
	lightGreen = rgbm(0.5, 1, 0.5, 1),
	activeGreen = rgbm(0, 0.6, 0.2, 1),
	lightBlue = rgbm(0.2, 0.9, 1, 1),
	coolBlue = rgbm(0, 0.1, 1, 1),
	offWhite = rgbm(1, 1, 1, 0.7),
	red = rgbm(1, 0, 0, 1),
	warningYellow = rgbm(1, 1, 0.3, 1),
	bestPurple = rgbm(1, 0, 1, 1),
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

local backLightNight = vec3(brightnessNight, brightnessNight, brightnessNight)
local backLightNightNotFPV = vec3(brightnessNightNotFPV, brightnessNightNotFPV, brightnessNightNotFPV)
local backLightDay = vec3(brightnessDay, brightnessDay, brightnessDay)
local backLightDayNotFPV = vec3(brightnessDayNotFPV, brightnessDayNotFPV, brightnessDayNotFPV)
local backLight = backLightDay
local backLightMesh = ac.findNodes("carsRoot:yes"):findMeshes("GEO_INT_Display")
backLightMesh:setMaterialProperty("ksEmissive", backLight)

local function updateDisplayBrightness(sim)
	local brightnessUpdated = false
	local isNightTime = ac.getSunAngle() >= 90
	local isFPVorF7 = sim.cameraMode == 0 or sim.cameraMode == 6

	if isFPVorF7 and isNightTime and backLight ~= backLightNight then
		brightnessUpdated = true
		backLight = backLightNight
		-- ac.log("DISPLAY_BACKLIGHT-NIGHT")
	elseif not isFPVorF7 and isNightTime and backLight ~= backLightNightNotFPV then
		brightnessUpdated = true
		backLight = backLightNightNotFPV
	elseif isFPVorF7 and not isNightTime and backLight ~= brightnessDay then
		brightnessUpdated = true
		backLight = backLightDay
		-- ac.log("DISPLAY_BACKLIGHT=DAY")
	elseif not isFPVorF7 and not isNightTime and backLight ~= backLightDayNotFPV then
		brightnessUpdated = true
		backLight = backLightDayNotFPV
	end

	if brightnessUpdated then
		backLightMesh:setMaterialProperty("ksEmissive", backLight)
	end
end

--region Data Collection and Formatting

-- General script consts.
local slowRefreshPeriod = 0.5
local fastRefreshPeriod = 0.12
local fastestRefreshPeriod = 0.05

local noDataString = "-:--"
-- Mirrors original car state, but with slower refresh rate. Also a good place to convert units and do other preprocessing.
local sdata = {
	lastLapFuelUse = noDataString,
}
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

local fuel = {
	initial = car.fuel,
	remaining = car.fuel,
	lapCount = car.lapCount,
}

local function updateData(dt, sim)
	delaySlow = delaySlow + dt
	if delaySlow > slowRefreshPeriod then
		delaySlow = 0

		ac.log(ac.getSunAngle())

		-- Session data
		sdata.currentTime = string.format("%02d:%02d", sim.timeHours, sim.timeMinutes)
		sdata.sessionLaps = 0
		try(function()
			sdata.sessionLaps = ac.getSession(sim.currentSessionIndex).laps
					and ac.getSession(sim.currentSessionIndex).laps
				or "--"
		end)

		sdata.lapCount = sdata.sessionLaps == 0 and tostring(car.lapCount + 1)
			or tostring(car.lapCount + 1) .. "/" .. sdata.sessionLaps
		sdata.position = getLeaderboardPosition(car.index)
		sdata.racePosition = "P" .. car.racePosition
		sdata.bestLapTimeMs = ac.lapTimeToString(car.bestLapTimeMs)
		sdata.previousLapTimeMs = ac.lapTimeToString(car.previousLapTimeMs)
		sdata.previousLapValidColor = car.isLastLapValid and displayColors.offWhite or displayColors.red
		sdata.isInPitlane = car.isInPitlane

		-- Fuel calculation
		if sim.isInMainMenu then
			fuel.initial = car.fuel
			fuel.remaining = car.fuel
		end
		if fuel.lapCount ~= car.lapCount then
			fuel.lapCount = car.lapCount
			sdata.lastLapFuelUse = fuel.remaining - car.fuel
			fuel.remaining = car.fuel
		end
		sdata.fuelPerLap = car.fuelPerLap == 0 and noDataString or string.format("%.2f", car.fuelPerLap)
		sdata.targetFuelUse = sdata.sessionLaps == 0 and sdata.fuelPerLap
			or string.format("%.2f", fuel.initial / sdata.sessionLaps)
		sdata.lastLapFuelUse = sdata.lastLapFuelUse == noDataString and noDataString
			or string.format("%.2f", sdata.lastLapFuelUse)
		sdata.fuel = string.format("%.1f", car.fuel)

		sdata.compoundIndex = car.compoundIndex
		sdata.compoundName = ac.getTyresName(car.index, car.compoundIndex)
		sdata.currentEngineBrakeSetting = car.currentEngineBrakeSetting
		sdata.mgukRecovery = car.mgukRecovery
		sdata.mgukDelivery = car.mgukDelivery
		sdata.mgukDeliveryName = mgukDeliveryShortNames[car.mgukDelivery + 1]
		sdata.batteryCharge = math.round(car.kersCharge * 100, 0)
		sdata.kersCharge = car.kersCharge
		sdata.kersLoad = 1 - car.kersLoad
		sdata.mguhMode = car.mguhChargingBatteries and "BATT" or "ENG"
		sdata.batteryChargeColor = optimumValueLerp(
			sdata.batteryCharge,
			20,
			50,
			100,
			displayColors.red,
			displayColors.red,
			displayColors.warningYellow,
			displayColors.activeGreen
		)
	end

	delayFast = delayFast + dt
	if delayFast > fastRefreshPeriod then
		delayFast = 0
		sdata.lapTimeMs = ac.lapTimeToString(car.lapTimeMs)
		sdata.gear = car.gear
		sdata.carAheadIndex = getCarAheadIndex(car.index)
		sdata.gapToCarAhead = car.racePosition > 1
				and string.format("%.2f", math.clamp(ac.getGapBetweenCars(car.index, sdata.carAheadIndex), 0, 99.99))
			or noDataString

		if not sim.isSessionStarted then
			sdata.gapToCarAhead = noDataString
		end

		sdata.estimatedLapTimeMs = car.bestLapTimeMs + (car.performanceMeter * 1000)
		sdata.performanceMeterLastLap =
			math.clamp((sdata.estimatedLapTimeMs - car.previousLapTimeMs) / 1000, -99.99, 99.99)
		if sdata.performanceMeterLastLap < 0 then
			sdata.performanceLastLapColor = displayColors.activeGreen
		elseif sdata.performanceMeterLastLap > 0 then
			sdata.performanceLastLapColor = displayColors.red
		else
			sdata.performanceLastLapColor = displayColors.offWhite
		end
		sdata.performanceMeterLastLap = sdata.performanceMeterLastLap == 0 and noDataString
			or string.format("%.2f", sdata.performanceMeterLastLap)

		sdata.performanceMeter = string.format("%.2f", math.clamp(car.performanceMeter, -99.99, 99.99))
		sdata.performanceMeter = car.performanceMeter == 0 and noDataString or sdata.performanceMeter
		if car.performanceMeter < 0 then
			sdata.performanceColor = displayColors.activeGreen
		elseif car.performanceMeter > 0 then
			sdata.performanceColor = displayColors.red
		else
			sdata.performanceColor = displayColors.offWhite
		end

		sdata.wheels = car.wheels
	end

	delayFastest = delayFastest + dt
	if delayFastest > fastestRefreshPeriod then
		delayFastest = 0
		sdata.poweredWheelsSpeed = math.round(car.poweredWheelsSpeed)
		sdata.rpm = math.round(car.rpm)
	end

	sdata.brakeBiasActual = string.format(
		"%.1f",
		100
			* (
				ac.getCarPhysics(car.index).scriptControllerInputs[0] == 0 and car.brakeBias
				or ac.getCarPhysics(car.index).scriptControllerInputs[0]
			)
	)

	sdata.brakeBiasMigration = ac.getCarPhysics(car.index).scriptControllerInputs[1]
	sdata.differentialEntry = ac.getCarPhysics(car.index).scriptControllerInputs[3] == 0 and 1
		or ac.getCarPhysics(car.index).scriptControllerInputs[3]
	sdata.differentialMid = ac.getCarPhysics(car.index).scriptControllerInputs[4] == 0 and 4
		or ac.getCarPhysics(car.index).scriptControllerInputs[4]
	sdata.differentialHispd = ac.getCarPhysics(car.index).scriptControllerInputs[5] == 0 and 5
		or ac.getCarPhysics(car.index).scriptControllerInputs[5]
	sdata.differentialMode = ac.getCarPhysics(car.index).scriptControllerInputs[6]
end

--endregion

--region Main Displays

local mgukColor = {
	NODLY = displayColors.offWhite,
	CHRGE = displayColors.activeGreen,
	LOW = displayColors.activeGreen,
	BALCD = displayColors.activeGreen,
	HIGH = displayColors.activeGreen,
	ATTCK = displayColors.bestPurple,
	QUAL = displayColors.bestPurple,
}

local function drawTopInfoBar()
	drawValue(displayFont, sdata.racePosition, 75, 13, 305, ui.Alignment.Start)
	drawValue(displayFont, sdata.poweredWheelsSpeed, 75, centerText, 305, ui.Alignment.Center)
	drawValue(displayFont, sdata.lapCount, 75, 655, 305, ui.Alignment.End)
end

local function displayShared(image, drawExtra)
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

	if drawExtra then
		if car.isInPitlane then
			drawInPit(displayColors.warningYellow)
		else
			drawDRS(0, 602, 70, displayColors.activeGreen)
			drawOvertake(displayColors.bestPurple)
		end
		drawFlag()
		drawTyreCoreTempGraphic(
			sdata,
			285,
			823,
			412,
			91,
			40,
			80,
			displayColors.coolBlue,
			displayColors.activeGreen,
			displayColors.red
		)
		drawTyreCoreTemp(sdata, displayFontSemiBold, 189, 683, 289, 95, 38, rgbm(1, 1, 1, 0.7))
	end

	drawGear(sdata, centerText + 1, 470, 250)
end

local displayWarmUpImage = ui.decodeImage(io.loadFromZip(ac.findFile("src/assets.zip"), "display_warmup.png"))
local function displayWarmup(dt)
	drawValue(displayFont, sdata.brakeBiasActual, 55, -55, 579, ui.Alignment.Center, rgbm(1, 0.5, 0, 0.9))
	drawValue(displayFont, sdata.currentEngineBrakeSetting, 55, 56, 579, ui.Alignment.Center)
	drawValue(displayFont, sdata.mgukRecovery, 55, 165, 579, ui.Alignment.Center)

	drawValue(displayFont, sdata.previousLapTimeMs, 70, 610, 388, ui.Alignment.End, sdata.previousLapValidColor)
	drawValue(displayFont, sdata.performanceMeter, 70, 610, 479, ui.Alignment.End, sdata.performanceColor)
	drawValue(displayFont, sdata.bestLapTimeMs, 70, 610, 569, ui.Alignment.End, rgbm(1, 0, 1, 0.7))

	drawValue(displayFont, sdata.differentialEntry, 55, -51, 398, ui.Alignment.Center)
	drawValue(displayFont, sdata.differentialMid, 55, 56, 398, ui.Alignment.Center)
	drawValue(displayFont, sdata.differentialHispd, 55, 165, 398, ui.Alignment.Center)

	drawValue(displayFontSemiBold, sdata.compoundName, 52, -152, 662, ui.Alignment.End)
	drawValue(displayFont, sdata.currentTime, 52, 65, 805, ui.Alignment.Start, displayColors.warningYellow)

	drawBrakes(sdata, 57, 872, 0, 36, 142, 36, displayColors.coolBlue, displayColors.activeGreen, displayColors.red)
	drawTyrePressure(sdata, displayFontSemiBold, 67, 683, 534, 95, 38)

	drawValue(displayFont, sdata.fuel, 52, 613, 662, ui.Alignment.End)
	drawValue(displayFont, sdata.lastLapFuelUse, 52, 613, 737, ui.Alignment.End)
	drawValue(displayFont, sdata.fuelPerLap, 52, 613, 814, ui.Alignment.End)

	displayShared(displayWarmUpImage, true)
end

local displayRaceImage = ui.decodeImage(io.loadFromZip(ac.findFile("src/assets.zip"), "display_race.png"))
local function displayRace(dt)
	drawValue(displayFont, sdata.brakeBiasActual, 65, 58, 590, ui.Alignment.Start, rgbm(1, 0.5, 0, 0.9))
	drawValue(
		displayFont,
		sdata.performanceMeterLastLap,
		65,
		58,
		695,
		ui.Alignment.Start,
		sdata.performanceLastLapColor
	)
	drawValue(displayFont, sdata.gapToCarAhead, 65, 58, 800, ui.Alignment.Start)

	drawValue(displayFont, sdata.fuel, 65, 613, 590, ui.Alignment.End)
	drawValue(displayFont, sdata.lastLapFuelUse, 65, 613, 695, ui.Alignment.End)
	drawValue(displayFont, sdata.targetFuelUse, 65, 613, 800, ui.Alignment.End)

	displayShared(displayRaceImage, true)
end

local displayQualImage = ui.decodeImage(io.loadFromZip(ac.findFile("src/assets.zip"), "display_qual.png"))
local function displayQual(dt)
	drawValue(displayFont, sdata.brakeBiasActual, 65, 58, 680, ui.Alignment.Start, rgbm(1, 0.5, 0, 0.9))
	drawValue(displayFont, sdata.fuel, 65, 613, 680, ui.Alignment.End)

	drawValue(displayFont, sdata.bestLapTimeMs, 70, 610, 388, ui.Alignment.End, rgbm(1, 0, 1, 0.7))
	drawValue(displayFont, sdata.previousLapTimeMs, 70, 610, 569, ui.Alignment.End, sdata.previousLapValidColor)

	drawValue(displayFont, sdata.performanceMeter, 70, 50, 388, ui.Alignment.End, sdata.performanceColor)
	drawValue(displayFont, sdata.performanceMeterLastLap, 70, 50, 569, ui.Alignment.End, sdata.performanceLastLapColor)

	displayShared(displayQualImage, true)
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

local displayLaunchImage = ui.decodeImage(io.loadFromZip(ac.findFile("src/assets.zip"), "display_launch.png"))
local function displayLaunch(dt)
	displayShared(displayLaunchImage, false)
	drawLaunch(sdata.rpm, targetLaunchRPM, displayColors.red, displayColors.warningYellow, displayColors.bestPurple)
	drawValue(displayFont, sdata.rpm, 70, 50, 388, ui.Alignment.End, rgbm(1, 1, 1, 0.7))
	drawValue(displayFont, sdata.brakeBiasActual, 70, 610, 388, ui.Alignment.End, rgbm(1, 0.5, 0, 0.9))
end

local function displayBrakeBias(dt)
	displayPopup("BRK BIAS", string.format("%.1f", car.brakeBias * 100), rgbm(1, 0.5, 0, 0.9))
end

local function displayMgukDelivery(dt)
	local mgukDelivery = mgukDeliveryShortNames[car.mgukDelivery + 1]

	displayPopup("DEPLOY", mgukDelivery, rgbm(1, 1, 1, 0.7))
end

local function displayMgukRecovery(dt)
	displayPopup("TORQ", car.mgukRecovery, rgbm(0, 1, 0.5, 0.7))
end

local function displayMguhMode(dt)
	displayPopup("RECHARGE", car.mguhChargingBatteries and "ON" or "OFF", rgbm(1, 0.15, 0.1, 0.5))
end

local function displayEngineBrake(dt)
	displayPopup("ENGINE BRK", car.currentEngineBrakeSetting, rgbm(1, 1, 1, 0.45))
end

local function displayBmig(dt)
	displayPopup("BRK MIG", sdata.brakeBiasMigration, rgbm(0, 0.4, 1, 1))
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

local function displayEmpty(dt)
	drawDisplayBackground(displaySize, backgroundColor)
end

--endregion

--region Display Switching

local displays = {
	displayRace, -- 1
	displayWarmup, -- 2
	displayQual, --3
	displayBrakeBias, -- 3
	displayMgukDelivery, -- 4
	displayMgukRecovery, -- 5
	displayMguhMode, -- 6
	displayEngineBrake, -- 7
	displayBmig, -- 8
	displayDiff, -- 9
	displayLaunch, -- 10
	displaySplash, -- 11
	displayEmpty, -- 12
}

local mainDisplayCount = 3
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
		seconds = popupScreenTime
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
local function getDisplayMode(sim)
	if not stored.initialized then
		stored.initialized = true
		resetLastStates()
	end

	if sim.isInMainMenu then
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
	local showSplash = true
	if stored.splashShown == true then
		showSplash = false
	else
		if sim.raceSessionType == 3 and sim.isSessionStarted then
			showSplash = false
		end
	end

	if car.isAIControlled then
		if sim.raceSessionType == 3 then
			return 1
		elseif sim.raceSessionType == 2 or sim.raceSessionType == 4 then
			return 3
		elseif sim.raceSessionType == 1 then
			return 2
		else
			return _currentMode
		end
	elseif initializationScreenTime == 0 then
		stored.splashShown = true
		return _currentMode
	elseif showSplash and sim.isFocusedOnInterior then
		stored.splashShown = true
		addTime(initializationScreenTime)
		tempMode = 12
		return tempMode
	elseif showSplash then
		tempMode = 13
		return tempMode
	elseif car.clutch == 0 and car.speedKmh < 1 and not sim.isInMainMenu then
		addTime(0)
		tempMode = 11
		return tempMode
	elseif popupScreenTime == 0 then
		return _currentMode
	elseif lastBrakeBias ~= car.brakeBias then
		lastBrakeBias = car.brakeBias
		addTime()
		tempMode = 4
		return tempMode
	elseif lastMgukDelivery ~= car.mgukDelivery then
		lastMgukDelivery = car.mgukDelivery
		addTime()
		tempMode = 5
		return tempMode
	elseif lastMgukRecovery ~= car.mgukRecovery then
		lastMgukRecovery = car.mgukRecovery
		addTime()
		tempMode = 6
		return tempMode
	elseif lastMguhMode ~= car.mguhChargingBatteries then
		lastMguhMode = car.mguhChargingBatteries
		addTime()
		tempMode = 7
		return tempMode
	elseif lastEngineBrake ~= car.currentEngineBrakeSetting then
		lastEngineBrake = car.currentEngineBrakeSetting
		addTime()
		tempMode = 8
		return tempMode
	elseif lastBmig ~= sdata.brakeBiasMigration then
		lastBmig = sdata.brakeBiasMigration
		addTime()
		tempMode = 9
		return tempMode
	elseif lastDiffMode ~= sdata.differentialMode then
		lastDiffMode = sdata.differentialMode
		addTime()
		tempMode = 10
		return tempMode
	elseif lastEntryDiff ~= sdata.differentialEntry then
		lastEntryDiff = sdata.differentialEntry
		addTime()
		tempMode = 10
		return tempMode
	elseif lastMidDiff ~= sdata.differentialMid then
		lastMidDiff = sdata.differentialMid
		addTime()
		tempMode = 10
		return tempMode
	elseif lastHispdDiff ~= sdata.differentialHispd then
		lastHispdDiff = sdata.differentialHispd
		addTime()
		tempMode = 10
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

	local sim = ac.getSim()

	updateData(dt, sim)
	updateDisplayBrightness(sim)
	drawDisplayBackground(displaySize, backgroundColor)
	displays[getDisplayMode(sim)](dt)
	-- displays[3](dt)
	drawDisplayBackground(displaySize, rgbm(0, 0, 0, 0.2))

	-- drawGridLines()
	-- drawAlignments()
	-- drawZones()
end
