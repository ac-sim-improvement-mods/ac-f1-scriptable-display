
local RareData = require 'rare/connection'
require 'src/display_helper'

local function drawLaunch()
    ui.pushDWriteFont("Default;Weight=Bold")
    local rpmColor = rgbm(0,0,0,1)
    local rpmText = "RPM LOW"

    if car.rpm > 10000 then
        rpmColor = rgbm(1,0,0,1)
        rpmText = "RPM HIGH"
    elseif car.rpm >= 9300 and car.rpm < 10000 then
        rpmColor = rgbm(0.79, 0.78, 0, 1)
        rpmText = "RPM HIGH"
    elseif car.rpm >= 8900 and car.rpm < 9300 then
        rpmColor = rgbm(0.9,0,1,1)
        rpmText = "RPM GOOD"
    elseif car.rpm >= 8000 and car.rpm < 8800 then
        rpmColor = rgbm(0.79, 0.78, 0, 1)
        rpmText = "RPM LOW"
    elseif car.rpm >= 7000 and car.rpm < 8000 then
        rpmColor = rgbm(1,0,0,1)
        rpmText = "RPM LOW"
    end

    display.rect{
        pos = vec2(0, 0),  
        size = vec2(350, 1024),
        color = rgb.colors.black
    }

    display.rect{
        pos = vec2(670, 0),  
        size = vec2(1024, 1024),
        color = rgb.colors.black
    }



    display.rect{
        pos = vec2(0, 0),  
        size = vec2(1024, 525),
        color = rpmColor
    }

    display.rect{
        pos = vec2(0, 0),  
        size = vec2(70, 1024),
        color = rpmColor
    }

    display.rect{
        pos = vec2(954, 0),  
        size = vec2(1024, 1024),
        color = rpmColor
    }

    display.rect{
        pos = vec2(0, 850),  
        size = vec2(1024, 1024),
        color = rpmColor
    }

    drawText{
        string = rpmText,
        fontSize = 125,
        xPos = 170,
        yPos = 655,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        margin = vec2(700, 550),
        color = rgbm(0.95, 0.95, 0.95, 1)
    }

    ui.popDWriteFont()
end

--- Draws the Mode A display
local function modeMainDisplay(dt)
    ui.pushDWriteFont("Default")

    drawDisplayBackground()
    drawOverlayBorders()

    drawOverlayText()
    drawDisplayMode(-70,310,70)
    drawRacePosition(-10,310,70)
    drawDRS(360,420,80,RareData)
    drawSpeed(445,305,70)
    drawLapCount(575,310,60)

    drawDelta(-10,420,80)
    drawBmig(695,425,70)


    drawMguh(30,540,50)
    drawMGUKRecovery(95,540,50)


    drawGapDelta(-65,675,60)
    drawLapsRemaining(45,675,60)
    drawFuelRemaining(620,675,60)
    drawLastLapFuelUse(585,675,60)

    drawBestLapTime(85,790,75)
    drawLastLapTime(645,790,75)

    drawBatteryRemaining(240,710,60)
    drawEngineBrake(240,800,60)

    drawErsBar(750,739,475,65)

    if not ac.getSim().isSessionStarted then
        drawDisplayBackground()
        drawLaunch()
    end

    drawBrakes(670,650,0,50,275,45)
    drawBrakeBias(585,425,70)
    drawGear(335,455,180)
    drawTyreTC(360,535,215,125,85,85)
    drawTyreCoreTemp(225,405,215,125,80)
    drawMGUKDelivery(335,620,32)


    drawInPit()

    ui.popDWriteFont()
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

local lastEntryDiff = ac.getCarPhysics(car.index).scriptControllerInputs[3]
local lastMidDiff =  ac.getCarPhysics(car.index).scriptControllerInputs[4]
local lastHispdDiff =  ac.getCarPhysics(car.index).scriptControllerInputs[5]
local lastDiffMode = ac.getCarPhysics(car.index).scriptControllerInputs[6] or 0

--- Draws the Mode H display
local function modeDiff(dt)
    ui.pushDWriteFont("Default;Weight=Bold")
    local diffText = ""

    if lastDiffMode == 0 then
        diffText = "ENTRY"
    elseif lastDiffMode == 1 then
        diffText = "MID"
    else
        diffText = "HISPD"
    end

    display.rect {
            pos = vec2(0, 0), 
            size = vec2(1124, 1124),
            color = rgbm(0, 0, 0, 1)
        }

    drawText{
        string = "DIFF",
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
        string = diffText,
        fontSize = 125,
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

local function modeDiffEntry(dt)
    ui.pushDWriteFont("Default;Weight=Bold")
    local entryDiff = math.round(ac.getCarPhysics(car.index).scriptControllerInputs[3]*100,0)

    display.rect {
            pos = vec2(0, 0), 
            size = vec2(1124, 1124),
            color = rgbm(0, 0, 0, 1)
        }

    drawText{
        string = "ENTRY",
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
        string = entryDiff,
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

local function modeDiffMid(dt)
    ui.pushDWriteFont("Default;Weight=Bold")
    local midDiff = math.round(ac.getCarPhysics(car.index).scriptControllerInputs[4]*100,0)

    display.rect {
            pos = vec2(0, 0), 
            size = vec2(1124, 1124),
            color = rgbm(0, 0, 0, 1)
        }

    drawText{
        string = "MID",
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
        string = midDiff,
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

local function modeDiffHispd(dt)
    ui.pushDWriteFont("Default;Weight=Bold")
    local hispdDiff = math.round(ac.getCarPhysics(car.index).scriptControllerInputs[5]*100,0)

    display.rect {
            pos = vec2(0, 0), 
            size = vec2(1124, 1124),
            color = rgbm(0, 0, 0, 1)
        }

    drawText{
        string = "HISPD",
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
        string = hispdDiff,
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

local listOfModes = {
    modeMainDisplay,
    modeBrakeBias,
    modeMgukDelivery,
    modeMgukRecovery,
    modeMguhMode,
    modeEngineBrake,
    modeBrakeMigration,
    modeDiff,
    modeDiffEntry,
    modeDiffMid,
    modeDiffHispd
}

local tempModeCount = 10
local currentMode = tonumber(ac.loadDisplayValue("displayMode", 1)) or 1

local lastBrakeBias = car.brakeBias
local lastMgukDelivery = car.mgukDelivery
local lastMgukRecovery = car.mgukRecovery
local lastMguhMode = car.mguhChargingBatteries
local lastEngineBrake = car.currentEngineBrakeSetting
local lastBmig = ac.getCarPhysics(car.index).scriptControllerInputs[1]

local lastExtraFState = car.extraF

local tempMode = 1
local timer = 0
local timerReset = 50

--- Switches to a temporary display if the conditions are met
local function setDisplayMode()
    local _currentMode = currentMode
    -- Save the last main display
    if car.extraF ~= lastExtraFState then
        _currentMode = _currentMode + 1
        if _currentMode > #listOfModes - tempModeCount then
            _currentMode = 1
        end
        ac.saveDisplayValue("displayMode", _currentMode)
        currentMode = _currentMode
    end

    lastExtraFState = car.extraF

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
    elseif lastDiffMode ~= ac.getCarPhysics(car.index).scriptControllerInputs[6] then
        lastDiffMode = ac.getCarPhysics(car.index).scriptControllerInputs[6]
        timer = timerReset
        tempMode = 8
        return tempMode
    elseif lastEntryDiff ~= ac.getCarPhysics(car.index).scriptControllerInputs[3] then
        lastEntryDiff = ac.getCarPhysics(car.index).scriptControllerInputs[3]
        timer = timerReset
        tempMode = 9
        return tempMode
    elseif lastMidDiff ~= ac.getCarPhysics(car.index).scriptControllerInputs[4] then
        lastMidDiff = ac.getCarPhysics(car.index).scriptControllerInputs[4]
        timer = timerReset
        tempMode = 10
        return tempMode
    elseif lastHispdDiff ~= ac.getCarPhysics(car.index).scriptControllerInputs[5] then
        lastHispdDiff = ac.getCarPhysics(car.index).scriptControllerInputs[5]
        timer = timerReset
        tempMode = 11
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

