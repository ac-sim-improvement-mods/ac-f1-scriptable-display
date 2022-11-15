
require 'src/display_helper'
local RareData = require 'src/connection'

--- Draws the Mode A display
local function modeMainDisplay(dt)
    ui.pushDWriteFont("Default")

    -- drawCurrentLapTime(650,655,70)
    -- drawCurrentTime(20,670,50)
    -- drawRPM()
    -- drawInPit()

    drawRexingDisplay1()
    drawSpeed(445,305,70)
    drawErsBar(750,739,475,65)
    drawDisplayMode(-70,310,70)
    drawRacePosition(-10,310,70)
    drawLapCount(700,305,70)
    drawDelta(-25,420,80)
    drawMguh(30,540,70)
    drawMGUKRecovery(100,540,70)
    drawGapDelta(-65,680,60)
    drawLapsRemaining(45,680,60)
    drawFuelRemaining(620,675,70)
    drawLastLapFuelUse(590,675,70)

    drawCustomBorders()

    drawBestLapTime(65,790,80)
    drawLastLapTime(640,790,80)

    drawBrakeBias(590,420,80)
    drawBmig(685,420,80)
    drawEngineBrake(240,800,60)

    drawText{
        string = "LAP",
        fontSize = 50,
        xPos = 410,
        yPos = 385,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
        color = rgbm(1, 1, 1, 1),
        margin = vec2(600,200)
    }

    ui.pushDWriteFont("Default;Weight=Black")

    drawBrakes(670,650,0,50,275,45)
    drawDRS(360,420,80)
    drawTyreTC(360,535,215,125,85,85)
    drawTyreCoreTemp(225,405,215,125,80)
    drawMGUKDelivery(335,620,32)
    ui.popDWriteFont()

    drawGear(335,455,180)
    drawBatteryRemaining(240,710,60)


end

--- Draws the Mode C display
local function modeBrakeBias(dt)
    ui.pushDWriteFont("Default;Weight=Bold")
    display.rect {
            pos = vec2(0, 0), 
            size = vec2(1124, 1124),
            color = rgbm(0.95, 0.95, 0.95, 1)
        }

    drawText{
        string = "BB",
        fontSize = 75,
        xPos = 20,
        yPos = 220,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        margin = vec2(350, 550),
        color = rgbm(0, 0, 0, 1)
    }

    ui.beginScale()
    drawText{
        string = string.format("%.1f", car.brakeBias*100),
        fontSize = 200,
        xPos = 10,
        yPos = 480,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        margin = vec2(1000, 550),
        color = rgbm(0, 0, 0, 1)
    }
    ui.endScale(2)

    ui.popDWriteFont()
end

--- Draws the Mode D display
local function modeMgukDelivery(dt)
    ui.pushDWriteFont("Default;Weight=Bold")
    local mgukDelivery = ac.getMGUKDeliveryName(car.index)

    display.rect {
            pos = vec2(0, 0), 
            size = vec2(1124, 1124),
            color = rgbm(0, 0, 0, 1)
        }

    drawText{
        string = "MGU-K D",
        fontSize = 75,
        xPos = 20,
        yPos = 220,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        margin = vec2(350, 550),
        color = rgbm(0.95, 0.95, 0.95, 1)
    }

    ui.beginScale()
    drawText{
        string = string.upper(mgukDelivery),
        fontSize = 90,
        xPos = 10,
        yPos = 500,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        margin = vec2(1000, 550),
        color = rgbm(0.95, 0.95, 0.95, 1)
    }
    ui.endScale(2)

    ui.popDWriteFont()
end

--- Draws the Mode E display
local function modeMgukRecovery(dt)
    ui.pushDWriteFont("Default;Weight=Bold")
    local mgukRecovery = car.mgukRecovery * 10

    display.rect {
            pos = vec2(0, 0), 
            size = vec2(1124, 1124),
            color = rgbm(0.2, 0.7, 0.2, 1)
        }

    drawText{
        string = "MGU-K R",
        fontSize = 75,
        xPos = 20,
        yPos = 220,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        margin = vec2(350, 550),
        color = rgbm(0.95, 0.95, 0.95, 1)
    }

    ui.beginScale()
    drawText{
        string = mgukRecovery,
        fontSize = 200,
        xPos = 10,
        yPos = 480,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        margin = vec2(1000, 550),
        color = rgbm(0.95, 0.95, 0.95, 1)
    }
    ui.endScale(2)

    ui.popDWriteFont()
end

--- Draws the Mode E display
local function modeMguhMode(dt)
    ui.pushDWriteFont("Default;Weight=Bold")
    local mguhMode = ""

    if car.mguhChargingBatteries then
        mguhMode = "BATTERY"
    else
        mguhMode = "ENGINE"
    end

    display.rect {
            pos = vec2(0, 0), 
            size = vec2(1124, 1124),
            color = rgbm(0.7, 0, 0.8, 1)
        }

    drawText{
        string = "MGU-H",
        fontSize = 75,
        xPos = 20,
        yPos = 220,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        margin = vec2(350, 550),
        color = rgbm(0.95, 0.95, 0.95, 1)
    }

    ui.beginScale()
    drawText{
        string = mguhMode,
        fontSize = 100,
        xPos = 280,
        yPos = 500,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        margin = vec2(450, 550),
        color = rgbm(0.95, 0.95, 0.95, 1)
    }
    ui.endScale(2)

    ui.popDWriteFont()
end

--- Draws the Mode G display
local function modeEngineBrake(dt)
    ui.pushDWriteFont("Default;Weight=Bold")
    local engineBrakeMode = car.currentEngineBrakeSetting

    display.rect {
            pos = vec2(0, 0), 
            size = vec2(1124, 1124),
            color = rgbm(0.2, 0.2, 0.2, 1)
        }

    drawText{
        string = "Engine Brake",
        fontSize = 75,
        xPos = 20,
        yPos = 220,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        margin = vec2(500, 550),
        color = rgbm(0.95, 0.95, 0.95, 1)
    }

    ui.beginScale()
    drawText{
        string = engineBrakeMode,
        fontSize = 200,
        xPos = 300,
        yPos = 500,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        margin = vec2(400, 550),
        color = rgbm(0.95, 0.95, 0.95, 1)
    }
    ui.endScale(2)

    ui.popDWriteFont()
end

--- Draws the Mode H display
local function modeBrakeMigration(dt)
    ui.pushDWriteFont("Default;Weight=Bold")
    local bmig = ac.getCarPhysics(car.index).scriptControllerInputs[1]

    display.rect {
            pos = vec2(0, 0), 
            size = vec2(1124, 1124),
            color = rgbm(0, 0, 0, 1)
        }

    drawText{
        string = "BMIG",
        fontSize = 75,
        xPos = 20,
        yPos = 220,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        margin = vec2(500, 550),
        color = rgbm(0.95, 0.95, 0.95, 1)
    }

    ui.beginScale()
    drawText{
        string = bmig+1,
        fontSize = 200,
        xPos = 300,
        yPos = 500,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        margin = vec2(400, 550),
        color = rgbm(0.95, 0.95, 0.95, 1)
    }
    ui.endScale(2)

    ui.popDWriteFont()
end

local listOfModes = {modeMainDisplay, modeBrakeBias, modeMgukDelivery, modeMgukRecovery, modeMguhMode, modeEngineBrake, modeBrakeMigration}
local tempModeCount = 6
local currentMode = tonumber(ac.loadDisplayValue("displayMode", 1)) or 1
local lastBrakeBias = car.brakeBias
local lastMgukDelivery = car.mgukDelivery
local lastMgukRecovery = car.mgukRecovery
local lastMguhMode = car.mguhChargingBatteries
local lastEngineBrake = car.currentEngineBrakeSetting
local lastBmig = ac.getCarPhysics(car.index).scriptControllerInputs[1]
local lastExtraCState = false
local tempMode = 1
local timer = 0
local timerReset = 50

--- Switches to a temporary display if the conditions are met
local function setDisplayMode()
    local _currentMode = currentMode
    -- Save the last main display
    if car.extraC ~= lastExtraCState then
        _currentMode = _currentMode + 1
        if _currentMode > #listOfModes - tempModeCount then
            _currentMode = 1
        end
        ac.saveDisplayValue("displayMode", _currentMode)
        currentMode = _currentMode
    end

    lastExtraCState = car.extraC

    -- If either brake bias or mguk delivery is not the same from the last script update, then start a timer
    -- If the driver changes bb or mgukd, reset the timer
    -- This also takes care of showing both displays if both bb and mgukd are changed
    if lastBrakeBias ~= car.brakeBias then
        lastBrakeBias = car.brakeBias
        timer = timerReset
        tempMode = 2
        return tempMode
    elseif lastMgukDelivery ~= car.mgukDelivery then
        lastMgukDelivery = car.mgukDelivery
        timer = timerReset
        tempMode = 3
        return tempMode
    elseif lastMgukRecovery ~= car.mgukRecovery then
        lastMgukRecovery = car.mgukRecovery
        timer = timerReset
        tempMode = 4
        return tempMode
    elseif lastMguhMode ~= car.mguhChargingBatteries then
        lastMguhMode = car.mguhChargingBatteries
        timer = timerReset
        tempMode = 5
        return tempMode
    elseif lastEngineBrake ~= car.currentEngineBrakeSetting then
        lastEngineBrake = car.currentEngineBrakeSetting
        timer = timerReset
        tempMode = 6
        return tempMode
    elseif lastBmig ~= ac.getCarPhysics(car.index).scriptControllerInputs[1] then
        lastBmig = ac.getCarPhysics(car.index).scriptControllerInputs[1]
        timer = timerReset
        tempMode = 7
        return tempMode
    else
        if timer > 0 then
            timer = timer - 1
            return tempMode
        else -- Once the timer has ended, return the last main display 
            return _currentMode
        end
    end
end

function script.update(dt)   
    local displayMode = setDisplayMode()

    listOfModes[displayMode](dt)
end

