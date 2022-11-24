local connection = {}

local RAREDATA = ac.connect({
    ac.StructItem.key('RAREDATA'),
    connected = ac.StructItem.boolean(),
    scriptVersionId = ac.StructItem.int16(),
    drsEnabled = ac.StructItem.boolean(),
    drsAvailable = ac.StructItem.array(ac.StructItem.boolean(),32),
    carAhead = ac.StructItem.array(ac.StructItem.int16(),32),
    carAheadDelta = ac.StructItem.array(ac.StructItem.float(),32),
},false,ac.SharedNamespace.Shared)

local RAREDATAAIDefaults = ac.connect({
    ac.StructItem.key('RAREDATAAIDefaults'),
    aiLevelDefault = ac.StructItem.array(ac.StructItem.float(),32),
    aiAggressionDefault = ac.StructItem.array(ac.StructItem.float(),32),
},false,ac.SharedNamespace.Shared)

--- Stores race control data
--- @param rc race_control
function connection.storeRaceControlData(rc)
    RAREDATA.connected = true
    RAREDATA.scriptVersionId = SCRIPT_VERSION_CODE
    RAREDATA.drsEnabled = rc.drsEnabled
end

--- Stores driver data
--- @param driver Driver
function connection.storeDriverData(driver)
    RAREDATA.drsAvailable[driver.index] = driver.drsAvailable
    RAREDATA.carAhead[driver.index] = driver.carAhead
    RAREDATA.carAheadDelta[driver.index] = driver.carAheadDelta
end

--- Stores default AI level and aggression
--- @param driver Driver
function connection.storeDefaultAIData(driver)
    RAREDATAAIDefaults.aiLevelDefault[driver.index] = driver.car.aiLevel
    RAREDATAAIDefaults.aiAggressionDefault[driver.index] = driver.car.aiAggression
end

--- Returns boolean if connected to RARE
---@return connected boolean
function connection.connected()
    return RAREDATA.connected
end

--- Returns script version ID
---@return scriptVersionId string
function connection.scriptVersionId()
    return RAREDATA.scriptVersionId
end

--- Returns boolean DRS Enabled state
---@return drsEnabled boolean
function connection.drsEnabled()
    return RAREDATA.drsEnabled
end

--- Returns DRS Available state for a specific car index
---@param carIndex number
---@return drsAvailable boolean
function connection.drsAvailable(carIndex)
    return RAREDATA.drsAvailable[carIndex]
end

--- Returns car ahead on track car index for a specific car index
---@param carIndex number
---@return carAhead number
function connection.carAhead(carIndex)
    return RAREDATA.carAhead[carIndex]
end

--- Returns car ahead on track car delta in seconds for a specific car index
---@param carIndex number
---@return carAheadDelta number
function connection.carAheadDelta(carIndex)
    return RAREDATA.carAheadDelta[carIndex]
end

--- Returns default AI level for a specific car index
---@param carIndex number
---@return aiLevelDefault number
function connection.aiLevelDefault(carIndex)
    return RAREDATAAIDefaults.aiLevelDefault[carIndex]
end

--- Returns default AI aggression for a specific car index
---@param carIndex number
---@return aiAggressionDefault number
function connection.aiAggressionDefault(carIndex)
    return RAREDATAAIDefaults.aiAggressionDefault[carIndex]
end

return connection