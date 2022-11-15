--- Returns an RGBM value based on the tyre's core temperature
local function tempBasedColor(input, bgCop1, bgCop2, grCop1, grCop2, brightness)
    return rgbm(
        math.min(math.max(0, (math.floor(input)-grCop1) / (grCop2-grCop1)) ,1),
        math.min(math.max(0, (math.floor(input)-bgCop1) / (bgCop2-bgCop1)) ,1) * math.min(math.max(0, 1-(math.floor(input)-grCop1) / (grCop2-grCop1)) ,1),
        math.min(math.max(0, 1-(math.floor(input)-bgCop1) / (bgCop2-bgCop1)), 1),
        brightness
    )
end

--- Override function to add clarity and default values for drawing text
function drawText(textdraw)
    if not textdraw.margin then
        textdraw.margin = vec2(350, 350)
    end
    if not textdraw.color then
        textdraw.color = rgbm(0.95, 0.95, 0.95, 1)
    end
    if not textdraw.fontSize then
        textdraw.fontSize = 70
    end

    ui.setCursorX(textdraw.xPos)
    ui.setCursorY(textdraw.yPos)
    ui.dwriteTextAligned(textdraw.string, textdraw.fontSize, textdraw.xAlign, textdraw.yAlign, textdraw.margin, false, textdraw.color)
end

--- Draws whether DRS is enabled and/or active
function drawDRS(x,y,size,RareData)
    ui.pushDWriteFont("Default;Weight=Black")

    local connected = RareData.connected()
    local drsEnabled = RareData.drsEnabled()
    local drsAvailable = RareData.drsAvailable(car.index)
    local drsZone = car.drsAvailable
    local drsActive = car.drsActive

    local drsColour = rgbm(0, 0, 0, 1)
    -- Set DRS box color
    if connected and ac.getSim().raceSessionType == 3 then

        if drsAvailable and drsEnabled then
            if drsZone then
                drsColour = rgbm(0.79, 0.78, 0, 1)
            else
                drsColour = rgbm(0.09, 0.09, 0.09, 1)
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
            drsColour = rgbm(0, 0.09, 0.09, 1)
        end
    end

    display.rect {
        pos = vec2(x-10, y), 
        size = vec2(320, 105),
        color = rgbm(0.09,0.09,0.09,1)
    }
    
    display.rect {
        pos = vec2(x, y), 
        size = vec2(300, 105),
        color = rgbm(drsColour)
    }

    drawText{
        string = "DRS",
        fontSize = size,
        xPos = x-125,
        yPos = y-115,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
        color = rgbm(0, 0, 0, 1)
    }

    ui.popDWriteFont()
end

--- Draws the tyre tc
function drawTyreTC(x,y,gapX,gapY,sizeX,sizeY)
    ui.pushDWriteFont("Default;Weight=Black")

    local wheel0 = car.wheels[0]
    local optimum0 = wheel0.tyreOptimumTemperature
    local wheel1 = car.wheels[1]
    local optimum1 = wheel1.tyreOptimumTemperature
    local wheel2 = car.wheels[2]
    local optimum2 = wheel2.tyreOptimumTemperature
    local wheel3 = car.wheels[3]
    local optimum3 = wheel3.tyreOptimumTemperature


    display.rect{ 
        pos = vec2(x, y),  
        size = vec2(sizeX, sizeY),
        color = tempBasedColor(wheel0.tyreCoreTemperature,optimum0-20,optimum0-15,optimum0,optimum0+15,1)
    }

    display.rect{ 
        pos = vec2(x+gapX, y),  
        size = vec2(sizeX, sizeY),
        color = tempBasedColor(wheel1.tyreCoreTemperature,optimum1-20,optimum1-15,optimum1,optimum1+15,1)
    }

    display.rect{ 
        pos = vec2(x, y+gapY),  
        size = vec2(sizeX, sizeY),
        color = tempBasedColor(wheel2.tyreCoreTemperature,optimum2-20,optimum2-15,optimum2,optimum2+15,1)
    }

    display.rect{
        pos = vec2(x+gapX, y+gapY),
        size = vec2(sizeX, sizeY),
        color = tempBasedColor(wheel3.tyreCoreTemperature,optimum3-20,optimum3-15,optimum3,optimum3+15,1)
    }

    ui.popDWriteFont()
end

--- Draws the Rexwing Display 1
function drawDisplayBackground()
    display.rect{
        pos = vec2(0, 0),  
        size = vec2(1024, 1024),
        color = rgbm(0,0,0,1)
    }
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
function drawCurrentLapTime(x,y,size)
    local textColor = rgbm(0.95, 0.95, 0.95, 1)

    if not car.isLapValid then
        textColor = rgbm(0.95, 0, 0, 0.8)
    end

    drawText{
        string = lapTimeToString(car.lapTimeMs),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        color = textColor
    }
end

--- Draws the best lap time
function drawBestLapTime(x,y,size)
    drawText{
        string = lapTimeToString(car.bestLapTimeMs),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        color = rgbm(0.72, 0, 0.89, 1),
        margin = vec2(400,350)
    }
end

--- Draws the last lap time
function drawLastLapTime(x,y,size)
    local textColor = rgbm(0.95, 0.95, 0.95, 1)

    if not car.isLastLapValid then
        textColor = rgbm(0.95, 0, 0, 0.8)
    end

    drawText{
        string = lapTimeToString(car.previousLapTimeMs),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        color = textColor
    }
end

--- Draws the current in game time
function drawCurrentTime(x,y,size)
    drawText{
        string = string.format("%02d:%02d:%02d", sim.timeHours, sim.timeMinutes, sim.timeSeconds),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        color = rgbm(0.79, 0.78, 0, 1)
    }
end

--- Draws the lap count
function drawLapCount(x,y,size)
    drawText{
        string = car.lapCount+1,
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }
end

--- Draws the speed of the car in KMH
function drawSpeed(x,y,size)
    drawText{
        string = string.format("%0d", car.poweredWheelsSpeed),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }
end

--- Draws the RPM
function drawRPM()
    drawText{
        string = string.format("%0d", car.rpm),
        xPos = 110,
        yPos = 310,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }
end

--- Draws the brake bias %
function drawBrakeBias(x,y,size)
    drawText{
        string = string.format("%.1f", car.brakeBias*100),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
        color = rgbm(1,0.5,0,0.9)
    }
end

--- Draws the remaining fuel in liters
function drawFuelRemaining(x,y,size)
   drawText{
        string = string.format("%.1f", car.fuel),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }
end

local fuelremaining = car.fuel
local currentLap = 1
local fueluse = 0

--- Draws the remaining fuel in liters
function drawLastLapFuelUse(x,y,size)
    if currentLap ~= car.lapCount then
        currentLap = car.lapCount
        fueluse = fuelremaining - car.fuel
        fuelremaining = car.fuel
    end

   drawText{
        string = string.format("%.1f", fueluse),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }
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
function drawDelta(x,y,size)
    drawText{
        fontSize = size,
        string = string.format("%.3f", car.performanceMeter),
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
        color = getCarPerformanceColor()
    }
end

--- Draws the 4 tyres core temperature
function drawTyreCoreTemp(x,y,gapX,gapY,size)
    ui.pushDWriteFont("Default;Weight=Black")

    local textSize0 = ui.measureDWriteText(string.format("%.0f", car.wheels[0].tyreCoreTemperature),size).x
    drawText{
        fontSize = size * 70/textSize0,
        string = string.format("%.0f", car.wheels[0].tyreCoreTemperature),
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        color = rgbm(0,0,0,1)
    }

    local textSize1 = ui.measureDWriteText(string.format("%.0f", car.wheels[1].tyreCoreTemperature),size).x
    drawText{
        fontSize = size * 70/textSize1,
        string = string.format("%.0f", car.wheels[1].tyreCoreTemperature),
        xPos = x+gapX,
        yPos = y,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        color = rgbm(0,0,0,1)
    }

    local textSize2 = ui.measureDWriteText(string.format("%.0f", car.wheels[2].tyreCoreTemperature),size).x
    drawText{
        fontSize = size * 70/textSize2,
        string = string.format("%.0f", car.wheels[2].tyreCoreTemperature),
        xPos = x,
        yPos = y+gapY,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        color = rgbm(0,0,0,1)
    }

    local textSize3 = ui.measureDWriteText(string.format("%.0f", car.wheels[3].tyreCoreTemperature),size).x
    drawText{
        fontSize = size * 70/textSize3,
        string = string.format("%.0f", car.wheels[3].tyreCoreTemperature),
        xPos = x+gapX,
        yPos = y+gapY,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        color = rgbm(0,0,0,1)
    }

    ui.popDWriteFont()
end

--- Draws the MGUK Recovery value
function drawMGUKRecovery(x,y,size)
    drawText{
        string = car.mgukRecovery*10,
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
    }
end

--- Draws the MGUK Delivery value
function drawMGUKDelivery(x,y,size)
    ui.pushDWriteFont("Default;Weight=Black")

    local mgukDelivery = string.upper(ac.getMGUKDeliveryName(car.index))

    if mgukDelivery == "NO DEPLOY" then
        mgukDelivery = "CHARG"
    elseif mgukDelivery == "BALANCED"  then
        mgukDelivery = "BALCD"
    end

    local textSize = ui.measureDWriteText(mgukDelivery,size).x
    
    drawText{
        string = mgukDelivery,
        fontSize = size * 160/textSize,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
    }
    ui.popDWriteFont()
end

--- Draws the current gear
function drawGear(x,y,size)
    local gear = car.gear
    local gearXPos = x
    local gearYPos = y

    if gear == -1 then
        gear = "R"
        gearXPos = gearXPos - 5
    elseif gear == 0 then
        gear = "N"
    end

    drawText{
        string = gear,
        fontSize = size,
        xPos = gearXPos,
        yPos = gearYPos,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
    }
end

--- Draws when the driver is in the pit lane
function drawInPit()
    ui.pushDWriteFont("Default;Weight=Bold")
    if car.isInPitlane == true then
        display.rect {
            pos = vec2(20, 755), 
            size = vec2(925, 255),
            color = rgbm(0.79, 0.78, 0, 1)
        }

        drawText{
            string = "PIT",
            fontSize = 190,
            xPos = 330,
            yPos = 680,
            xAlign = ui.Alignment.Center,
            yAlign = ui.Alignment.Center,
            color = rgb.colors.black
        }

        drawText{
            string = ac.getTyresLongName(car.index, car.compoundIndex),
            fontSize = 55,
            xPos = 40,
            yPos = 790,
            xAlign = ui.Alignment.Start,
            yAlign = ui.Alignment.Center,
            color = rgb.colors.black
        }

        if  car.speedLimiterInAction == false or car.manualPitsSpeedLimiterEnabled == true then
            drawText{
                string = "LIMITER",
                fontSize = 55,
                xPos = 275,
                yPos = 790,
                xAlign = ui.Alignment.End,
                yAlign = ui.Alignment.Center,
                margin = vec2(650, 350),
                color = rgb.colors.black
            }
        end
    end

    ui.popDWriteFont()
end

function drawOverlayText()
    local fontSize = 30

    drawText{
        string = "MGU-H",
        fontSize = fontSize,
        xPos = 30,
        yPos = 495,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "RECOVERY",
        fontSize = fontSize,
        xPos = -10,
        yPos = 495,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "BEHIND",
        fontSize = fontSize,
        xPos = 30,
        yPos = 600,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "LAPS LEFT",
        fontSize = fontSize,
        xPos = 50,
        yPos = 600,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "BEST",
        fontSize = fontSize,
        xPos = 30,
        yPos = 745,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "LAP",
        fontSize = 45,
        xPos = 665,
        yPos = 310,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "BMIG",
        fontSize = fontSize,
        xPos = 680,
        yPos = 380,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "BB",
        fontSize = fontSize,
        xPos = 580,
        yPos = 380,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "FUEL",
        fontSize = fontSize,
        xPos = 620,
        yPos = 600,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "LAST LAP",
        fontSize = fontSize,
        xPos = 580,
        yPos = 600,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "LAST",
        fontSize = fontSize,
        xPos = 620,
        yPos = 745,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "BATT",
        fontSize = fontSize,
        xPos = 425,
        yPos = 690,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }

    drawText{
        string = "EB",
        fontSize = fontSize,
        xPos = 425,
        yPos = 780,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }

end

function drawOverlayBorders()
    local borderColor = rgbm(0.09,0.09,0.09,1)

    -- Top border   
    display.rect{
        pos = vec2(10,525),
        size = vec2(1024,10),
        color = borderColor
    }

    -- Left border
    display.rect{
        pos = vec2(10,535),
        size = vec2(10,475),
        color = borderColor
    }

    -- Right border
    display.rect{
        pos = vec2(945,535),
        size = vec2(10,475),
        color = borderColor
    }

    -- Bottom border   
    display.rect{
        pos = vec2(10,1010),
        size = vec2(1024,10),
        color = borderColor
    }

    -- -- Center Line
    -- display.rect{
    --     pos = vec2(512,535),
    --     size = vec2(10,450),
    --     color = bordercolor
    -- }


    -- Horizontal Border 2   
    display.rect{
        pos = vec2(20,640),
        size = vec2(330,10),
        color = borderColor
    }

    -- Horizontal Border 2   
    display.rect{
        pos = vec2(670,640),
        size = vec2(275,10),
        color = borderColor
    }


    -- Horizontal Border 3   
    display.rect{
        pos = vec2(20,745),
        size = vec2(330,10),
        color = borderColor
    }

    -- Horizontal Border 3   
    display.rect{
        pos = vec2(670,745),
        size = vec2(275,10),
        color = borderColor
    }

    -- Horizontal Border 4
    display.rect{
        pos = vec2(20,890),
        size = vec2(390,10),
        color = borderColor
    }

    -- Horizontal Border 4
    display.rect{
        pos = vec2(610,890),
        size = vec2(335,10),
        color = borderColor
    }


    -- Gear box
    display.rect{ 
        pos = vec2(410,755),
        size = vec2(200,255),
        color = borderColor
    }

    display.rect{ 
        pos = vec2(350,535),
        size = vec2(320,220),
        color = borderColor
    }

    display.rect{ 
        pos = vec2(360,535),
        size = vec2(300,210),
        color = rgbm(0,0,0,1)
    }

    display.rect{ 
        pos = vec2(420,755),
        size = vec2(180,80),
        color = rgbm(0,0,0,1)
    }

    display.rect{ 
        pos = vec2(420,845),
        size = vec2(180,80),
        color = rgbm(0,0,0,1)
    }

    display.rect{ 
        pos = vec2(420,935),
        size = vec2(180,75),
        color = rgbm(0,0,0,1)
    }
end

local deltaLast = 0
local deltaColorLast = rgbm(0,1,0,1)

function drawGapDelta(x,y,size)
    local delta  = "-.-"
    local color = rgbm(1,1,1,1)
    
    if car.racePosition ~= 1 then
        for i=1, ac.getSim().carsCount-1 do
            local comparedCar = ac.getCar(i)
            if comparedCar.racePosition == car.racePosition - 1 then
                local lapDelta = 0
                if comparedCar.splinePosition < car.splinePosition then
                    lapDelta = (comparedCar.lapCount + (1-comparedCar.splinePosition)) - (car.lapCount + (1-car.splinePosition))
                else
                    lapDelta = (comparedCar.lapCount + (1-comparedCar.splinePosition)) - (car.lapCount + (1-car.splinePosition))
                end
                 
                if lapDelta >= 1 then
                    delta = "+"..math.round(lapDelta,0).." L"
                    color = rgbm(1,0,0,1)
                else
                    delta = -math.clamp(math.round(ac.getGapBetweenCars(car.index, i),3),0,999)

                    if math.abs(deltaLast-delta) > 0.001 then
                        if delta > deltaLast then
                            color = rgbm(0,1,0,1)
                        else
                            color = rgbm(1,0,0,1)
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
        delta = '---'
    end

    drawText{
    string = tostring(delta),
    fontSize = size,
    xPos = x+95,
    yPos = y,
    xAlign = ui.Alignment.Start,
    yAlign = ui.Alignment.Center,
    color = color
    }
end

function drawLapsRemaining(x,y,size)
    drawText{
        string = ac.getSession(sim.currentSessionIndex).laps - car.lapCount + (math.round(1-car.splinePosition,2)),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
        }
end

function drawBatteryRemaining(x,y,size)
    drawText{
        string = math.round(car.kersCharge*100,0),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
        }
end

function drawErsBar(x,y,sizeX,sizeY)
    ui.beginRotation()

    display.horizontalBar {
        pos = vec2(x, y), 
        size = vec2(sizeX, sizeY),
        color = rgbm(1, 1, 1, 1),
        delta = 0,
        activeColor = rgbm(0, 0.79, 0.17, 1),
        inactiveColor = rgbm.colors.transparent,
        total = 100,
        active = (1-car.kersLoad)*100
    }

    display.horizontalBar {
        pos = vec2(x, y), 
        size = vec2(sizeX, sizeY),
        color = rgbm(1, 1, 1, 1),
        delta = 20,
        activeColor = rgbm(0.09,0.09,0.09,1),
        inactiveColor = rgbm.colors.transparent,
        total = 20,
        active = 20
    }

    display.horizontalBar {
        pos = vec2(x, y+10), 
        size = vec2(sizeX, sizeY-20),
        color = rgbm(1, 1, 1, 1),
        delta = 0,
        activeColor = rgbm(0, 0.79, 0.17, 1),
        inactiveColor = rgbm.colors.transparent,
        total = 100,
        active = (1-car.kersLoad)*100
    }


    ui.endRotation(180, vec2(0,0))
end

function drawBmig(x,y,size)
    drawText{
        string = ac.getCarPhysics(car.index).scriptControllerInputs[1]+1,
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }
end

function drawMguh(x,y,size)
    local mguhMode = ""

    if car.mguhChargingBatteries then
        mguhMode = "BATT"
    else
        mguhMode = "ENG"
    end

    drawText{
        string = mguhMode,
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        }
end

function drawDisplayMode(x,y,size)
    drawText{
        string = "RACE",
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        }
end

function drawRacePosition(x,y,size)
    drawText{
        string = "P"..car.racePosition,
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }
end

function drawBrakes(x,y,xGap,yGap,xSize,ySize)
    ui.pushDWriteFont("Default;Weight=Black")

    display.rect{ 
        pos = vec2(x,y),
        size = vec2(xSize,ySize),
        color = tempBasedColor(car.wheels[0].discTemperature,300,400,800,1200,1)
    }

    display.rect{ 
        pos = vec2(x+xGap,y+yGap),
        size = vec2(xSize,ySize),
        color = tempBasedColor(car.wheels[2].discTemperature,300,400,800,1200,1)
    }

    drawText{
        string = "FRNT BRAKES",
        fontSize = 35,
        xPos = 635,
        yPos = 497,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        color = rgb.colors.black
    }

    drawText{
        string = "REAR BRAKES",
        fontSize = 35,
        xPos = 635,
        yPos = 548,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        color = rgb.colors.black
    }

    ui.popDWriteFont()
end

function drawEngineBrake(x,y,size)
    drawText{
        string = car.currentEngineBrakeSetting,
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }
end
