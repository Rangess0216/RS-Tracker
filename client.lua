local lib = exports.ox_lib
ESX = exports["es_extended"]:getSharedObject()

local missionActive = false
local missionVehicle = nil
local missionPed = nil
local missionBlip = nil
local canCollectReward = false
local pedAggroTriggered = false 

function ShowNotify(title, msg, type)
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({title = title, description = msg, type = type})
    else
        ESX.ShowNotification(msg)
    end
end

CreateThread(function()
    local model = GetHashKey(Config.PedModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local ped = CreatePed(4, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z, Config.PedCoords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'talk_npc',
            icon = 'fa-solid fa-comments',
            label = 'Porozmawiaj',
            onSelect = function()
                if canCollectReward then
                   TriggerServerEvent('rs-tracker:payout')
                   canCollectReward = false
                   missionActive = false
                   ShowNotify('Sukces', 'Masz tu swoją dolę. Znikaj.', 'success')
                elseif not missionActive then
                    SetNuiFocus(true, true)
                    SendNUIMessage({type = "open"})
                else
                    ShowNotify('Info', 'Masz już aktywne zadanie!', 'error')
                end
            end
        }
    })
end)

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('startMission', function(data, cb)
    SetNuiFocus(false, false)
    StartMissionLogic()
    cb('ok')
end)

function StartMissionLogic()
    missionActive = true
    pedAggroTriggered = false
    ShowNotify('Misja', 'Pojazd zaznaczony na GPS. Właściciel jest w środku!', 'info')

    local carModel = GetHashKey(Config.VehicleModel)
    RequestModel(carModel)
    while not HasModelLoaded(carModel) do Wait(0) end

    if DoesEntityExist(missionVehicle) then DeleteVehicle(missionVehicle) end
    
    missionVehicle = CreateVehicle(carModel, Config.VehicleSpawn.x, Config.VehicleSpawn.y, Config.VehicleSpawn.z, Config.VehicleSpawn.w, true, false)
    
    SetVehicleEngineOn(missionVehicle, false, true, true)
    SetVehicleDoorsLocked(missionVehicle, 1) 
    SetVehicleNeedsToBeHotwired(missionVehicle, true)
    
    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(missionVehicle), true)
    SetEntityAsMissionEntity(missionVehicle, true, true)

    local pedModel = GetHashKey('g_m_y_mexgang_01')
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(0) end
    
    local hostilePed = CreatePedInsideVehicle(missionVehicle, 4, pedModel, -1, true, true)
    GiveWeaponToPed(hostilePed, GetHashKey("WEAPON_KNIFE"), 1, false, true)
    
    SetPedCombatAttributes(hostilePed, 46, true) 
    SetPedFleeAttributes(hostilePed, 0, 0)       
    SetPedCombatAbility(hostilePed, 100)
    
    SetVehicleEngineOn(missionVehicle, false, true, true)

    missionBlip = AddBlipForEntity(missionVehicle)
    SetBlipSprite(missionBlip, 225)
    SetBlipColour(missionBlip, 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Cel kradzieży")
    EndTextCommandSetBlipName(missionBlip)

    CreateThread(function()
        while missionActive do
            Wait(0)
            local plyPed = PlayerPedId()
            
            if DoesEntityExist(missionVehicle) then
                local dist = #(GetEntityCoords(plyPed) - GetEntityCoords(missionVehicle))
                local isPlayerInside = IsPedInVehicle(plyPed, missionVehicle, false)
                local isEngineRunning = GetIsVehicleEngineRunning(missionVehicle)

                if isPlayerInside and not isEngineRunning then
                    DisableControlAction(0, 71, true)
                    DisableControlAction(0, 72, true)
                end

                if not isPlayerInside then
                    SetVehicleEngineOn(missionVehicle, false, true, true)
                end

                if dist < 10.0 and not pedAggroTriggered and not IsPedDeadOrDying(hostilePed) then
                    pedAggroTriggered = true
                    TaskLeaveVehicle(hostilePed, missionVehicle, 256)
                    
                    SetTimeout(1000, function()
                        if not IsPedDeadOrDying(hostilePed) then
                            TaskCombatPed(hostilePed, plyPed, 0, 16)
                            PlayAmbientSpeech1(hostilePed, "GENERIC_CURSE_MED", "SPEECH_PARAMS_FORCE")
                        end
                    end)
                end
                
                if pedAggroTriggered and not IsPedInVehicle(hostilePed, missionVehicle, false) and not IsPedDeadOrDying(hostilePed) then
                    if not IsPedInCombat(hostilePed, plyPed) then 
                         TaskCombatPed(hostilePed, plyPed, 0, 16)
                    end
                end

                local isPlayerInSeat = (GetPedInVehicleSeat(missionVehicle, -1) == plyPed)

                if isEngineRunning and isPlayerInSeat then
                    local netId = VehToNet(missionVehicle)
                    TriggerServerEvent('rs-tracker:alertPolice', netId)
                    StartChasePhase()
                    break
                end
            else
                break
            end
        end
    end)
end

function StartChasePhase()
    if missionBlip then RemoveBlip(missionBlip) end

    ShowNotify('ALARM!', 'Namierza Cię policja! Masz '..Config.ChaseTime..'s na zgubienie GPS!', 'error')
    
    local plyId = PlayerId()
    SetPlayerWantedLevel(plyId, 3, false)
    SetPlayerWantedLevelNow(plyId, false)

    CreateThread(function()
        local timer = Config.ChaseTime
        while timer > 0 and missionActive do
            Wait(1000)
            timer = timer - 1
            if timer % 30 == 0 then
                 ShowNotify('Czas', 'GPS aktywny jeszcze: '..timer..'s', 'info')
            end
        end
        
        if missionActive then
            ShowNotify('GPS Złamany', 'Zawieź wóz do dziupli.', 'success')
            SetPlayerWantedLevel(plyId, 0, false)
            
            SetNewWaypoint(Config.DeliveryPoint.x, Config.DeliveryPoint.y)
            missionBlip = AddBlipForCoord(Config.DeliveryPoint)
            SetBlipSprite(missionBlip, 1)
            SetBlipColour(missionBlip, 2)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Dziupla")
            EndTextCommandSetBlipName(missionBlip)
        end
    end)

    CreateThread(function()
        while missionActive do
            Wait(0)
            local plyPed = PlayerPedId()
            local coords = GetEntityCoords(plyPed)
            local dist = #(coords - Config.DeliveryPoint)

            if dist < 10.0 and IsPedInVehicle(plyPed, missionVehicle, false) then
                ESX.ShowHelpNotification("Naciśnij ~INPUT_PICKUP~ aby oddać pojazd")
                
                if IsControlJustReleased(0, 38) then
                    TaskLeaveVehicle(plyPed, missionVehicle, 0)
                    Wait(2000)
                    DeleteVehicle(missionVehicle)
                    if missionBlip then RemoveBlip(missionBlip) end
                    
                    ShowNotify('Sukces', 'Wróć do zleceniodawcy po nagrodę.', 'success')
                    canCollectReward = true
                    missionActive = false 
                    break
                end
            end
        end
    end)
end

RegisterNetEvent('rs-tracker:setPoliceBlip')
AddEventHandler('rs-tracker:setPoliceBlip', function(targetNetId)
    ShowNotify('DISPATCH', 'Kradziony pojazd! GPS aktywny przez '..Config.ChaseTime..'s.', 'warning')
    
    local vehicle = NetToVeh(targetNetId)
    local attempts = 0
    while not DoesEntityExist(vehicle) and attempts < 10 do
        Wait(500)
        vehicle = NetToVeh(targetNetId)
        attempts = attempts + 1
    end

    if DoesEntityExist(vehicle) then
        local blip = AddBlipForEntity(vehicle)
        SetBlipSprite(blip, 161)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 1.0)
        SetBlipFlashes(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Kradziony Pojazd (GPS)")
        EndTextCommandSetBlipName(blip)

        SetTimeout(Config.ChaseTime * 1000, function()
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
                ShowNotify('DISPATCH', 'Sygnał GPS utracony.', 'info')
            end
        end)
    end
end)