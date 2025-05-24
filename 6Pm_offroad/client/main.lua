
local cache = {
    ped = nil,
    vehicle = nil,
    lastTerrain = {},
    lastUpdate = 0,
    updateInterval = 100,
    isSliding = false
}

local terrainTypes = {
    GRASS = { traction = 0.6, slip = 0.4 },
    SAND = { traction = 0.3, slip = 0.7 },
    MUD = { traction = 0.2, slip = 0.8 },
    SNOW = { traction = 0.8, slip = 0.2 },
    ROCK = { traction = 1.0, slip = 0.0 }
}

local originalHandling = {}

CreateThread(function()
    while true do
        cache.ped = PlayerPedId()
        if IsPedInAnyVehicle(cache.ped, false) then
            cache.vehicle = GetVehiclePedIsIn(cache.ped, false)
        else
            cache.vehicle = nil
        end
        Wait(1000)
    end
end)

local function CacheVehicleHandling(vehicle)
    if not originalHandling[vehicle] then
        originalHandling[vehicle] = {
            traction = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax'),
            brake = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce')
        }
    end
end

local function GetTerrainType(coords)
    return IsPointOnRoad(coords.x, coords.y, coords.z, 0.0) and 'ROAD' or 'GRASS'
end

local function ApplySliding(vehicle, slipFactor, speed)
    if slipFactor <= 0 or speed < 5.0 then return end
    
    if not cache.isSliding and math.random() > 0.97 then
        cache.isSliding = true
        local force = (math.random() - 0.5) * slipFactor * 0.3
        ApplyForceToEntity(vehicle, 1, force, 0.0, 0.0, 0.0, 0.0, 0.0, 0, false, false, true, false, true)
    else
        cache.isSliding = false
    end
end

local function ApplyTerrainPhysics(vehicle, terrain)
    local terrainData = terrainTypes[terrain]
    
    if terrain == 'ROAD' then
        if cache.lastTerrain[vehicle] ~= 'ROAD' then
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax', originalHandling[vehicle].traction)
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce', originalHandling[vehicle].brake)
            cache.lastTerrain[vehicle] = 'ROAD'
        end
        return
    end

    if terrainData and cache.lastTerrain[vehicle] ~= terrain then
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax', originalHandling[vehicle].traction * terrainData.traction)
        cache.lastTerrain[vehicle] = terrain
    end
end

CreateThread(function()
    while true do
        if cache.vehicle then
            local currentTime = GetGameTimer()
            
            if currentTime - cache.lastUpdate >= cache.updateInterval then
                local speed = GetEntitySpeed(cache.vehicle)
                
                if speed > 0.1 then
                    local coords = GetEntityCoords(cache.ped)
                    local terrain = GetTerrainType(coords)
                    
                    if not originalHandling[cache.vehicle] then
                        CacheVehicleHandling(cache.vehicle)
                    end
                    
                    ApplyTerrainPhysics(cache.vehicle, terrain)
                    
                    if terrain ~= 'ROAD' then
                        ApplySliding(cache.vehicle, terrainTypes[terrain].slip, speed)
                    end
                end
                
                cache.lastUpdate = currentTime
            end
            
            Wait(0)
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent('6Pm_offroad:sync')
AddEventHandler('6Pm_offroad:sync', function(data)
    if data and data.vehicle and originalHandling[data.vehicle] then
        ApplyTerrainPhysics(data.vehicle, GetTerrainType(GetEntityCoords(data.vehicle)))
    end
end)