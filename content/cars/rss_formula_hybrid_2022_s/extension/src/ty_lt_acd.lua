function getIdealPressure(compound, wheel)
    local config = ac.INIConfig.carData(car.index, 'tyres.ini')

    local compoundHeader = ""
    if compound ~= 0 then compoundHeader = "_" .. compound end
    if wheel <= 1 then
        return config:get("FRONT" .. compoundHeader, "PRESSURE_IDEAL", 0)
    else
        return config:get("REAR" .. compoundHeader, "PRESSURE_IDEAL", 0)
    end
end
