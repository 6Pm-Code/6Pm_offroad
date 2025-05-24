

local cache = {
    vehicles = {},
    lastSync = {},
    syncInterval = 1000 
}

local function ValidateVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    local model = GetEntityModel(vehicle)
    return model and model > 0
end

CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        
        for vehicle, lastTime in pairs(cache.lastSync) do
            if currentTime - lastTime >= cache.syncInterval then
                if ValidateVehicle(vehicle) then
                    TriggerClientEvent('6Pm_offroad:sync', -1, {
                        vehicle = vehicle
                    })
                    cache.lastSync[vehicle] = currentTime
                else
                    cache.lastSync[vehicle] = nil
                    cache.vehicles[vehicle] = nil
                end
            end
        end
        
        Wait(1000)
    end
end)

RegisterServerEvent('6Pm_offroad:register')
AddEventHandler('6Pm_offroad:register', function(vehicleNet)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNet)
    if ValidateVehicle(vehicle) then
        cache.vehicles[vehicle] = true
        cache.lastSync[vehicle] = GetGameTimer()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    cache.vehicles = {}
    cache.lastSync = {}
end)