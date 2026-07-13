local usingGizmo = false
local mode = "Translate"
local extraZ = 1000.0
local spawnedProp, pedBoneIndex = 0, 0
local lastCoord = nil
local position, rotation = vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0)
local freecam = nil
local rotOrder = 2

local function toggleNuiFrame(bool)
    usingGizmo = bool
    SetNuiFocus(bool, bool)
    SetNuiFocusKeepInput(bool)
end

local function finish()
    if freecam then
        freecam.Function.Destroy(0)
        freecam = nil
    end
    if DoesEntityExist(spawnedProp) then DeleteEntity(spawnedProp) end
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    ClearPedTasks(playerPed)
    if lastCoord then
        SetEntityCoords(playerPed, lastCoord.x, lastCoord.y, lastCoord.z, false, false, false, true)
        lastCoord = nil
    end
end

local function taskPlayAnim(ped, dict, anim, flag)
    CreateThread(function()
        while usingGizmo do
            if not IsEntityPlayingAnim(ped, dict, anim, 1) then
                while not HasAnimDictLoaded(dict) do
                    RequestAnimDict(dict)
                    Wait(10)
                end
                TaskPlayAnim(ped, dict, anim, 5.0, 5.0, -1, (flag or 15), 0, false, false, false)
                RemoveAnimDict(dict)
            end
            Wait(1000)
        end
    end)
end

local function instructionButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

local function instructionButtonCreate(scaleform, key, text, number)
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(number)
    PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(0, key, true))
    instructionButtonMessage(text)
    PopScaleformMovieFunctionVoid()
end

local function instructionButtonsCreate(scaleform, keys, text, number)
    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(number)
    for i = 1, #keys do
        PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(0, keys[i], true))
    end
    instructionButtonMessage(text)
    PopScaleformMovieFunctionVoid()
end

local function createInstructionScaleform()
    local scaleform = RequestScaleformMovie("instructional_buttons")
    while not HasScaleformMovieLoaded(scaleform) do Wait(10) end

    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    instructionButtonCreate(scaleform, 200, "Done Editing", 1)
    instructionButtonCreate(scaleform, 45, mode == "Translate" and "Rotate Mode" or "Translate Mode", 2)
    instructionButtonsCreate(scaleform, { 32, 34, 33, 35 }, "Move", 3)
    instructionButtonCreate(scaleform, 21, "Up", 4)
    instructionButtonCreate(scaleform, 36, "Down", 5)
    instructionButtonCreate(scaleform, 25, "Look", 6)

    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end

function Start(handle, boneIndex, dict, anim, rotationOrder)
    spawnedProp = handle
    pedBoneIndex = boneIndex
    rotOrder = rotationOrder or 2

    local playerPed = PlayerPedId()
    lastCoord = GetEntityCoords(playerPed)

    FreezeEntityPosition(playerPed, true)
    SetEntityCoords(playerPed, 0.0, 0.0, extraZ - 1, false, false, false, true)
    SetEntityHeading(playerPed, 0.0)
    SetEntityRotation(playerPed, 0.0, 0.0, 0.0, 2, true)
    position, rotation = vector3(0.0, 0.0, 0.0), vector3(0.0, 0.0, 0.0)
    AttachEntityToEntity(spawnedProp, playerPed, pedBoneIndex,
        position.x, position.y, position.z,
        rotation.x, rotation.y, rotation.z,
        true, true, false, true, rotOrder, true)

    Wait(0)
    local propPos = GetEntityCoords(spawnedProp)
    freecam = CreateFreeCam({
        pos = vector3(propPos.x, propPos.y + 1.5, propPos.z + 0.3),
    })

    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = spawnedProp,
            position = vector3(0.0, 0.0, extraZ),
            rotation = vector3(0.0, 0.0, 0.0),
            rotationOrder = rotOrder,
        }
    })
    toggleNuiFrame(true)

    if dict and anim then taskPlayAnim(playerPed, dict, anim) end

    while usingGizmo do
        DrawScaleformMovieFullscreen(createInstructionScaleform(), 255, 255, 255, 255, 0)
        SendNUIMessage({
            action = 'setCameraPosition',
            data = {
                position = GetFinalRenderedCamCoord(),
                rotation = GetFinalRenderedCamRot(2)
            }
        })
        DisableIdleCamera(true)
        Wait(0)
    end

    finish()
    return {
        ("AttachEntityToEntity(entity, PlayerPedId(), %s, %s, %s, %s, %s, %s, %s, true, true, false, true, %s, true)"):format(
            pedBoneIndex,
            extraZ - position.z, position.y, position.x,
            rotation.x, rotation.y, rotation.z, rotOrder),
        ("%s, %s, %s, %s, %s, %s"):format(
            extraZ - position.z, position.y, position.x,
            rotation.x, rotation.y, rotation.z)
    }
end

RegisterNUICallback('moveEntity', function(data, cb)
    local entity = data.handle
    position = vector3(data.position.x, data.position.y, data.position.z)
    rotation = vector3(data.rotation.x, data.rotation.y, data.rotation.z)
    AttachEntityToEntity(entity, PlayerPedId(), pedBoneIndex,
        extraZ - position.z, position.y, position.x,
        rotation.x, rotation.y, rotation.z,
        true, true, false, true, rotOrder, true)
    cb('ok')
end)

RegisterNUICallback('finishEdit', function(_, cb)
    toggleNuiFrame(false)
    SendNUIMessage({
        action = 'setGizmoEntity',
        data = {
            handle = nil,
        }
    })
    cb('ok')
end)

RegisterNUICallback('swapMode', function(data, cb)
    mode = data.mode
    cb('ok')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    finish()
end)
