local activeSpaceCam = nil

---@param data? table
---@return table spaceCam
function CreateFreeCam(data)
    if activeSpaceCam then activeSpaceCam.Function.Destroy(0) end

    data = data or {}

    local playerPed = PlayerPedId()
    local pedCoords = GetEntityCoords(playerPed)
    local pedHeading = GetEntityHeading(playerPed)

    local self = {
        cam = nil,
        active = false,
        pos = data.pos or (pedCoords + vector3(0.0, 0.0, 0.5)),
        rot = vector3(-10.0, 0.0, (pedHeading + 180.0)),
        speed = 0.02,
        minSpeed = 0.005,
        maxSpeed = 1.0,
        sensitivity = 3.5,
        fov = 50.0,
        Function = {},
    }

    self.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(self.cam, self.pos.x, self.pos.y, self.pos.z)
    SetCamRot(self.cam, self.rot.x, self.rot.y, self.rot.z, 2)
    SetCamFov(self.cam, self.fov)
    SetCamActive(self.cam, true)
    RenderScriptCams(true, false, 0, true, false)
    SetFocusPosAndVel(self.pos.x, self.pos.y, self.pos.z, 0.0, 0.0, 0.0)

    self.active = true
    activeSpaceCam = self

    CreateThread(function()
        while self.active do
            local dt = GetFrameTime()

            DisableAllControlActions(0)

            local isLooking = IsDisabledControlPressed(0, 25)

            if isLooking then
                local deltaX, deltaY

                local cursorX = GetDisabledControlNormal(0, 239)
                local cursorY = GetDisabledControlNormal(0, 240)

                if self.lastCursorX then
                    deltaX = cursorX - self.lastCursorX
                    deltaY = cursorY - self.lastCursorY
                end

                self.lastCursorX = cursorX
                self.lastCursorY = cursorY

                if deltaX and (math.abs(deltaX) > 0.0001 or math.abs(deltaY) > 0.0001) then
                    local sens = self.alwaysLook and self.sensitivity or (self.sensitivity * 60.0)
                    local pitch = self.rot.x - (deltaY * sens)
                    local yaw = self.rot.z - (deltaX * sens)

                    pitch = math.max(-89.0, math.min(89.0, pitch))

                    self.rot = vector3(pitch, 0.0, yaw)
                    SetCamRot(self.cam, self.rot.x, self.rot.y, self.rot.z, 2)
                end
            else
                self.lastCursorX = nil
                self.lastCursorY = nil
            end

            local radZ = math.rad(self.rot.z)
            local radX = math.rad(self.rot.x)
            local cosX = math.cos(radX)

            local forward = vector3(-math.sin(radZ) * cosX, math.cos(radZ) * cosX, math.sin(radX))
            local right = vector3(math.cos(radZ), math.sin(radZ), 0.0)

            local moveDir = vector3(0.0, 0.0, 0.0)

            if IsDisabledControlPressed(0, 32) then moveDir = moveDir + forward end                -- W
            if IsDisabledControlPressed(0, 33) then moveDir = moveDir - forward end                -- S
            if IsDisabledControlPressed(0, 35) then moveDir = moveDir + right end                  -- D
            if IsDisabledControlPressed(0, 34) then moveDir = moveDir - right end                  -- A
            if IsDisabledControlPressed(0, 21) then moveDir = moveDir + vector3(0.0, 0.0, 0.1) end -- Shift
            if IsDisabledControlPressed(0, 36) then moveDir = moveDir - vector3(0.0, 0.0, 0.1) end -- Ctrl

            local len = #moveDir
            if len > 0.001 then
                moveDir = moveDir / len
                local newPos = self.pos + (moveDir * self.speed * dt * 60.0)

                self.pos = newPos
                SetCamCoord(self.cam, self.pos.x, self.pos.y, self.pos.z)
                SetFocusPosAndVel(self.pos.x, self.pos.y, self.pos.z, 0.0, 0.0, 0.0)
            end

            Wait(0)
        end
    end)

    self.Function.Destroy = function()
        if not self.active then return end
        self.active = false
        activeSpaceCam = nil

        RenderScriptCams(false, true, 0, true, false)
        DestroyCam(self.cam, false)

        ClearFocus()
    end

    return self
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() and activeSpaceCam then
        activeSpaceCam.Function.Destroy(0)
    end
end)
