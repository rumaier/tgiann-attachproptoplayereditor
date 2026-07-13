--Example: /prop prop_sandwich_01 18905 mp_player_inteat@burger mp_player_int_eat_burger 2

-- RegisterCommand('prop', function(_, args)
--     local model = joaat(args[1] or "prop_cs_burger_01")
--     if not HasModelLoaded(model) then
--         RequestModel(model)
--         while not HasModelLoaded(model) do Wait(1) end
--     end
--     local playerPed = PlayerPedId()
--     local playerCoords = GetEntityCoords(playerPed)
--     local object = CreateObject(model, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
--     local boneArg = args[2]
--     local boneToNumber = tonumber(boneArg)
--     local bone = (boneArg and boneToNumber) and GetPedBoneIndex(playerPed, boneToNumber) or boneArg and GetEntityBoneIndexByName(playerPed, boneArg) or 18905
--     local rotationOrder = tonumber(args[5]) or 2
--     local objectPositionData = Start(object, bone, args[3], args[4], rotationOrder)
--     print(objectPositionData[1])
--     print(objectPositionData[2])
-- end, false)

local function loadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
    end
end

RegisterCommand('proptool', function(_, args)
    local model = joaat(args[1])
    local coords = GetEntityCoords(cache.ped)
    local bone = GetPedBoneIndex(cache.ped, tonumber(args[2]) and tonumber(args[2]) or 18905)
    local entity = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    loadModel(model)
    local data = Start(entity, bone, args[3], args[4], 2)
    lib.setClipboard(data[1])
end, false)

local commandProperties = {
    help = 'Debug tool for attaching props to the player',
    params = {
        { name = 'model',    type = 'string', help = 'The model of the prop to attach to the player' },
        { name = 'boneId',   type = 'number', help = 'The bone ID to attach the prop to' },
        { name = 'animDict', type = 'string', help = 'The animation dictionary to use for the player' },
        { name = 'animName', type = 'string', help = 'The animation name to use for the player' }
    }
}

SetTimeout(1000, function()
    local hints = {}
    for _, param in ipairs(commandProperties.params) do
        table.insert(hints, { 
            name = param.name,
            help = param.type
                and (param.help and ('%s (type: %s)'):format(param.help, param.type) or ('(type: %s)'):format(param.type))
                or param.help,
        })
    end
    TriggerEvent('chat:addSuggestion', '/proptool', commandProperties.help, hints)
end)


