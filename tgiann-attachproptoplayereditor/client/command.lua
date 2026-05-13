--Example: /prop prop_sandwich_01 18905 mp_player_inteat@burger mp_player_int_eat_burger 2
RegisterCommand('prop', function(_, args)
    local model = joaat(args[1] or "prop_cs_burger_01")
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(1) end
    end
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local object = CreateObject(model, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
    local boneArg = args[2]
    local boneToNumber = tonumber(boneArg)
    local bone = (boneArg and boneToNumber) and GetPedBoneIndex(playerPed, boneToNumber) or boneArg and GetEntityBoneIndexByName(playerPed, boneArg) or 18905
    local rotationOrder = tonumber(args[5]) or 2
    local objectPositionData = Start(object, bone, args[3], args[4], rotationOrder)
    print(objectPositionData[1])
    print(objectPositionData[2])
end)
