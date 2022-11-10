--- Connects to the F1 Regs app
--- Example of a variable call for drsAvailable
--- local drsAvailable = F1RegsData.drsAvailable
local F1RegsData = ac.connect({
    ac.StructItem.key('F1RegsData'),
    connected = ac.StructItem.boolean(),
    scriptVersionId = ac.StructItem.int16(),
    drsEnabled = ac.StructItem.boolean(),
    drsAvailable = ac.StructItem.array(ac.StructItem.boolean(),32),
    carAhead = ac.StructItem.array(ac.StructItem.int16(),32),
    carAheadDelta = ac.StructItem.array(ac.StructItem.float(),32),
},false,ac.SharedNamespace.Shared)

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
local function drawText(textdraw)
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
local function drawDRS(x,y,size)
    local connected = F1RegsData.connected
    local drsAvailable = F1RegsData.drsAvailable[car.index]
    local drsZone = car.drsAvailable
    local drsActive = car.drsActive

    local drsColour = rgbm(0, 0, 0, 1)
    -- Set DRS box color
    if connected and ac.getSim().raceSessionType == 3 then
        if drsAvailable then
            
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
            drsColour = rgbm(0.09, 0.09, 0.09, 1)
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
end

--- Draws the tyre tc
local function drawTyreTC(x,y,gapX,gapY,sizeX,sizeY)
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
end

--- Draws the Rexwing Display 1
local function drawRexingDisplay1()
    display.rect{
        pos = vec2(0, 0),  
        size = vec2(1024, 1024),
        color = rgbm(0,0,0,1)
    }
end

local floor = math.floor

--- Converts lap time from ms to MM SS MS
local function lapTimeToString(lapTimeMs)
    local time = lapTimeMs
    return string.format(
                "%02d:%02d:%02d",
                floor((time / (1000 * 60))) % 60,
                floor((time / 1000)) % 60,
                floor((time % 1000) / 10)
            )
end

--- Draws the current lap time
local function drawCurrentLapTime(x,y,size)
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
local function drawBestLapTime(x,y,size)
    drawText{
        string = "BEST",
        fontSize = size-55,
        xPos = x - 40,
        yPos = y-55,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        color = textColor
    }

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
local function drawLastLapTime(x,y,size)
    local textColor = rgbm(0.95, 0.95, 0.95, 1)

    if not car.isLastLapValid then
        textColor = rgbm(0.95, 0, 0, 0.8)
    end

    drawText{
        string = "LAST",
        fontSize = size-55,
        xPos = x-20,
        yPos = y-55,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        color = textColor
    }

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
local function drawCurrentTime(x,y,size)
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
local function drawLapCount(x,y,size)
    drawText{
        string = car.lapCount+1,
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
    }
end

--- Draws the speed of the car in KMH
local function drawSpeed(x,y,size)
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
local function drawRPM()
    drawText{
        string = string.format("%0d", car.rpm),
        xPos = 110,
        yPos = 310,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }
end

--- Draws the brake bias %
local function drawBrakeBias(x,y,size)
    drawText{
        string = "BB",
        fontSize = size-50,
        xPos = x-5,
        yPos = y-45,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
        }

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
local function drawFuelRemaining(x,y,size)
    drawText{
        string = "FUEL",
        fontSize = size-55,
        xPos = x,
        yPos = y-75,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }

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
local function drawLastLapFuelUse(x,y,size)
    drawText{
        string = "LAST LAP",
        fontSize = size-55,
        xPos = x+240,
        yPos = y-70,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
    }

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
local function getCarPerformanceColor()
    if car.performanceMeter < 0 then
        return rgbm(0, 0.79, 0.17, 1)
    elseif car.performanceMeter > 0 then
        return rgbm(0.83, 0, 0, 1)
    else
        return rgbm(0.95, 0.95, 0.95, 1)
    end
end

--- Draws the delta text
local function drawDelta(x,y,size)
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
local function drawTyreCoreTemp(x,y,gapX,gapY,size)
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
end

--- Draws the MGUK Recovery value
local function drawMGUKRecovery(x,y,size)
    drawText{
        string = "RECOVERY",
        fontSize = size-45,
        xPos = x,
        yPos = y-50,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
    }

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
local function drawMGUKDelivery(x,y,size)
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
end

--- Draws the current gear
local function drawGear(x,y,size)
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
local function drawInPit()
    if car.isInPitlane == true then
        display.rect {
            pos = vec2(80, 780), 
            size = vec2(860, 230),
            color = rgbm(0.79, 0.78, 0, 1)
        }

        drawText{
            string = "PIT",
            fontSize = 190,
            xPos = 300,
            yPos = 680,
            xAlign = ui.Alignment.End,
            yAlign = ui.Alignment.Center,
            color = rgbm(0.09, 0.09, 0.09, 1)
        }

        drawText{
            string = ac.getTyresLongName(car.index, car.compoundIndex),
            fontSize = 60,
            xPos = 90,
            yPos = 800,
            xAlign = ui.Alignment.Center,
            yAlign = ui.Alignment.Center,
            color = rgbm(0.09, 0.09, 0.09, 1)
        }

        if  car.speedLimiterInAction == true or car.manualPitsSpeedLimiterEnabled == true then
            drawText{
                string = "Limiter Active",
                fontSize = 60,
                xPos = 410,
                yPos = 800,
                xAlign = ui.Alignment.Center,
                yAlign = ui.Alignment.Center,
                margin = vec2(650, 350),
                color = rgbm(0.09, 0.09, 0.09, 1)
            }
        end
    end
end

local function drawCustomBorders()
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

local function drawGapDelta(x,y,size)
    drawText{
        string = "BEHIND",
        fontSize = size-100,
        xPos = x-25,
        yPos = y-80,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
    }


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
                    delta = math.clamp(math.round(ac.getGapBetweenCars(car.index, i),3),0,999)



                    if delta < deltaLast then
                        color = rgbm(0,1,0,1)
                    else
                        color = rgbm(1,0,0,1)
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

local function drawLapsRemaining(x,y,size)
    drawText{
        string = "  LAPS LEFT",
        fontSize = size-35,
        xPos = x+120,
        yPos = y-80,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        }

    drawText{
        string = ac.getSession(sim.currentSessionIndex).laps - car.lapCount + (math.round(1-car.splinePosition,2)),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
        }
end

local function drawBatteryRemaining(x,y,size)
    drawText{
        string = "BATT",
        fontSize = size-35,
        xPos = x+40,
        yPos = y-20,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        }

    drawText{
        string = math.round(car.kersCharge*100,0),
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
        }
end

local function drawErsBar(x,y,sizeX,sizeY)
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

local function drawBmig(x,y,size)
    drawText{
        string = "BMIG",
        fontSize = size-50,
        xPos = x,
        yPos = y-45,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        }

    drawText{
        string = ac.getCarPhysics(car.index).scriptControllerInputs[1]+1,
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        }
end

local function drawMguh(x,y,size)
    local mguhMode = ""

    if car.mguhChargingBatteries then
        mguhMode = "BATT"
    else
        mguhMode = "ENG"
    end

    drawText{
        string = "MGU-H",
        fontSize = size-40,
        xPos = x,
        yPos = y-50,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        }

    drawText{
        string = mguhMode,
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        }
end

local function drawDisplayMode(x,y,size)
    drawText{
        string = "RACE",
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        }
end

local function drawRacePosition(x,y,size)
    drawText{
        string = "P"..car.racePosition,
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }
end

local function drawBrakes(x,y,xGap,yGap,xSize,ySize)
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

    ac.debug('temp',car.wheels[2].discTemperature)

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
end

local function drawEngineBrake(x,y,size)
    drawText{
        string = "EB",
        fontSize = size-30,
        xPos = x+30,
        yPos = y-20,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        }

    drawText{
        string = car.currentEngineBrakeSetting,
        fontSize = size,
        xPos = x,
        yPos = y,
        xAlign = ui.Alignment.End,
        yAlign = ui.Alignment.Center,
    }
end

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

