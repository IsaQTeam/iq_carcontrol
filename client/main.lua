-- Variables
local displayActive = false
local currentVehicle = nil

RegisterCommand("carcontrol", function()
    if not IsPedInAnyVehicle(PlayerPedId(), false) then
        return TriggerEvent("chat:addMessage", {
            color = {255, 0, 0},
            multiline = true,
            args = {"Vehicle Control", "You are not in a vehicle."}
        })
    end
    
    toggleDisplay()
end, false)

RegisterKeyMapping('carcontrol', 'Toggle Car Control Menu', 'keyboard', 'F5')

-- NUI callback functions
RegisterNUICallback('close', function(data, cb)
    toggleDisplay(false)
    cb('ok')
end)

RegisterNUICallback('toggleDoor', function(data, cb)
    local doorIndex = tonumber(data.doorIndex)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if DoesEntityExist(vehicle) then
        if GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0.0 then
            SetVehicleDoorShut(vehicle, doorIndex, false)
        else
            SetVehicleDoorOpen(vehicle, doorIndex, false, false)
        end
    end
    
    cb('ok')
end)

RegisterNUICallback('toggleEngine', function(data, cb)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if DoesEntityExist(vehicle) then
        local engineRunning = GetIsVehicleEngineRunning(vehicle)
        SetVehicleEngineOn(vehicle, not engineRunning, false, true)
    end
    
    cb('ok')
end)

RegisterNUICallback('toggleLock', function(data, cb)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if DoesEntityExist(vehicle) then
        local lockStatus = GetVehicleDoorLockStatus(vehicle)
        
        if lockStatus == 1 or lockStatus == 0 then -- unlocked
            SetVehicleDoorsLocked(vehicle, 2) -- locked
            PlayVehicleDoorCloseSound(vehicle, 1)
            TriggerEvent("chat:addMessage", {
                color = {255, 255, 0},
                multiline = true,
                args = {"Vehicle Control", "Vehicle locked."}
            })
        else
            SetVehicleDoorsLocked(vehicle, 1) -- unlocked
            PlayVehicleDoorOpenSound(vehicle, 0)
            TriggerEvent("chat:addMessage", {
                color = {0, 255, 0},
                multiline = true,
                args = {"Vehicle Control", "Vehicle unlocked."}
            })
        end
    end
    
    cb('ok')
end)

RegisterNUICallback('changeSeat', function(data, cb)
    local seatIndex = tonumber(data.seatIndex)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if DoesEntityExist(vehicle) then
        if IsVehicleSeatFree(vehicle, seatIndex) then
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, seatIndex)
        end
    end
    
    cb('ok')
end)

-- Helper functions
function toggleDisplay(forceState)
    displayActive = forceState ~= nil and forceState or not displayActive
    SetNuiFocus(displayActive, displayActive)
    
    if displayActive then
        currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        SendNUIMessage({
            type = "showUI",
            vehicle = {
                doors = {
                    {id = 0, name = "Driver Door", open = GetVehicleDoorAngleRatio(currentVehicle, 0) > 0},
                    {id = 1, name = "Passenger Door", open = GetVehicleDoorAngleRatio(currentVehicle, 1) > 0},
                    {id = 2, name = "Rear Left Door", open = GetVehicleDoorAngleRatio(currentVehicle, 2) > 0},
                    {id = 3, name = "Rear Right Door", open = GetVehicleDoorAngleRatio(currentVehicle, 3) > 0},
                    {id = 4, name = "Hood", open = GetVehicleDoorAngleRatio(currentVehicle, 4) > 0},
                    {id = 5, name = "Trunk", open = GetVehicleDoorAngleRatio(currentVehicle, 5) > 0}
                },
                engine = GetIsVehicleEngineRunning(currentVehicle),
                locked = GetVehicleDoorLockStatus(currentVehicle) ~= 1
            }
        })
        -- send initial time and weather update
        do
            local hour = GetClockHours()
            local minutes = GetClockMinutes()
            local ampm = "AM"
            if hour >= 12 then
                ampm = "PM"
                if hour > 12 then hour = hour - 12 end
            end
            if hour == 0 then hour = 12 end
            local timeString = string.format("%d:%02d %s", hour, minutes, ampm)
            local isDay = GetClockHours() >= 6 and GetClockHours() < 18
            local weather = GetPrevWeatherTypeHashName()
            local weatherName = "Unknown"
            if weather == GetHashKey("CLEAR") then
                weatherName = "Clear"
            elseif weather == GetHashKey("EXTRASUNNY") then
                weatherName = "Extra Sunny"
            elseif weather == GetHashKey("CLOUDS") then
                weatherName = "Cloudy"
            elseif weather == GetHashKey("OVERCAST") then
                weatherName = "Overcast"
            elseif weather == GetHashKey("RAIN") then
                weatherName = "Rain"
            elseif weather == GetHashKey("CLEARING") then
                weatherName = "Clearing"
            elseif weather == GetHashKey("THUNDER") then
                weatherName = "Thunder"
            elseif weather == GetHashKey("SMOG") then
                weatherName = "Smog"
            elseif weather == GetHashKey("FOGGY") then
                weatherName = "Foggy"
            elseif weather == GetHashKey("XMAS") then
                weatherName = "Snowy"
            elseif weather == GetHashKey("SNOWLIGHT") then
                weatherName = "Light Snow"
            elseif weather == GetHashKey("BLIZZARD") then
                weatherName = "Blizzard"
            end
            SendNUIMessage({
                type = "updateInfo",
                time = timeString,
                weather = weatherName,
                isDay = isDay
            })
        end
    else
        SendNUIMessage({
            type = "hideUI"
        })
    end
end

-- Update time every minute
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        local hour = GetClockHours()
        local minutes = GetClockMinutes()
        local ampm = "AM"
        if hour >= 12 then
            ampm = "PM"
            if hour > 12 then hour = hour - 12 end
        end
        if hour == 0 then hour = 12 end
        local timeString = string.format("%d:%02d %s", hour, minutes, ampm)
        local isDay = GetClockHours() >= 6 and GetClockHours() < 18 -- Re-check hour for isDay here
        SendNUIMessage({ type = "updateInfo", time = timeString, isDay = isDay })
    end
end)

-- Update weather every 10 seconds
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000)
        local weatherHash = GetPrevWeatherTypeHashName()
        local weatherName = "unknown"
        if weatherHash == GetHashKey("CLEAR") then weatherName = "clear"
        elseif weatherHash == GetHashKey("EXTRASUNNY") then weatherName = "extra-sunny"
        elseif weatherHash == GetHashKey("CLOUDS") then weatherName = "cloudy"
        elseif weatherHash == GetHashKey("OVERCAST") then weatherName = "overcast"
        elseif weatherHash == GetHashKey("RAIN") then weatherName = "rain"
        elseif weatherHash == GetHashKey("CLEARING") then weatherName = "clearing"
        elseif weatherHash == GetHashKey("THUNDER") then weatherName = "thunder"
        elseif weatherHash == GetHashKey("SMOG") then weatherName = "smog"
        elseif weatherHash == GetHashKey("FOGGY") then weatherName = "foggy"
        elseif weatherHash == GetHashKey("XMAS") then weatherName = "snowy"
        elseif weatherHash == GetHashKey("SNOWLIGHT") then weatherName = "light-snow"
        elseif weatherHash == GetHashKey("BLIZZARD") then weatherName = "blizzard"
        end
        local hour = GetClockHours()
        local isDay = hour >= 6 and hour < 18
        SendNUIMessage({ type = "updateInfo", weather = weatherName, isDay = isDay })
    end
end)

-- Vehicle status checks
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        if displayActive and DoesEntityExist(currentVehicle) then
            SendNUIMessage({
                type = "updateVehicle",
                vehicle = {
                    doors = {
                        {id = 0, name = "Driver Door", open = GetVehicleDoorAngleRatio(currentVehicle, 0) > 0},
                        {id = 1, name = "Passenger Door", open = GetVehicleDoorAngleRatio(currentVehicle, 1) > 0},
                        {id = 2, name = "Rear Left Door", open = GetVehicleDoorAngleRatio(currentVehicle, 2) > 0},
                        {id = 3, name = "Rear Right Door", open = GetVehicleDoorAngleRatio(currentVehicle, 3) > 0},
                        {id = 4, name = "Hood", open = GetVehicleDoorAngleRatio(currentVehicle, 4) > 0},
                        {id = 5, name = "Trunk", open = GetVehicleDoorAngleRatio(currentVehicle, 5) > 0}
                    },
                    engine = GetIsVehicleEngineRunning(currentVehicle),
                    locked = GetVehicleDoorLockStatus(currentVehicle) ~= 1
                }
            })
        end
    end
end)

-- Export functions for other resources to use
exports('toggleEngine', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if DoesEntityExist(vehicle) then
        local engineRunning = GetIsVehicleEngineRunning(vehicle)
        SetVehicleEngineOn(vehicle, not engineRunning, false, true)
    end
end)

exports('toggleLock', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if DoesEntityExist(vehicle) then
        local lockStatus = GetVehicleDoorLockStatus(vehicle)
        
        if lockStatus == 1 or lockStatus == 0 then -- unlocked
            SetVehicleDoorsLocked(vehicle, 2) -- locked
            PlayVehicleDoorCloseSound(vehicle, 1)
        else
            SetVehicleDoorsLocked(vehicle, 1) -- unlocked
            PlayVehicleDoorOpenSound(vehicle, 0)
        end
    end
end)

exports('toggleHood', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if DoesEntityExist(vehicle) then
        if GetVehicleDoorAngleRatio(vehicle, 4) > 0.0 then
            SetVehicleDoorShut(vehicle, 4, false)
        else
            SetVehicleDoorOpen(vehicle, 4, false, false)
        end
    end
end)

exports('toggleTrunk', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if DoesEntityExist(vehicle) then
        if GetVehicleDoorAngleRatio(vehicle, 5) > 0.0 then
            SetVehicleDoorShut(vehicle, 5, false)
        else
            SetVehicleDoorOpen(vehicle, 5, false, false)
        end
    end
end)

exports('switchSeat', function(seatName)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    
    if DoesEntityExist(vehicle) then
        local seatIndex = -1
        
        if seatName == 'driver' then
            seatIndex = -1
        elseif seatName == 'passenger' then
            seatIndex = 0
        end
        
        if seatIndex ~= -1 and IsVehicleSeatFree(vehicle, seatIndex) then
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, seatIndex)
        end
    end
end) 