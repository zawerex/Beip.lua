local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()
local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local Window = Library:CreateWindow{
    Title = "Rivals X",
    SubTitle = "Cheat Menu",
    TabWidth = 160,
    Size = UDim2.fromOffset(830, 525),
    Resize = true,
    MinSize = Vector2.new(470, 380),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
}

local Tabs = {
    Legit = Window:CreateTab{
        Title = "Legit",
        Icon = "target"
    },
    Rage = Window:CreateTab{
        Title = "Rage",
        Icon = "flame"
    },
    Visuals = Window:CreateTab{
        Title = "Visuals",
        Icon = "eye"
    },
    Player = Window:CreateTab{
        Title = "Player",
        Icon = "user"
    },
    Exploits = Window:CreateTab{
        Title = "Exploits",
        Icon = "zap"
    },
    Settings = Window:CreateTab{
        Title = "Settings",
        Icon = "settings"
    }
}

local Options = Library.Options

-- Инициализация сервисов
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local camera = Workspace.CurrentCamera
local players = Players
local utility = require(ReplicatedStorage.Modules.Utility)
local LocalPlayer = players.LocalPlayer

-- Конфигурация
local Config = {
    HitPart = 'Head',
    TeamCheck = true,
    FOVColor = Color3.fromRGB(255, 255, 255),
    SilentAimFOVRadius = 100,
    AimbotFOVRadius = 100,
    FlySpeed = 50,
    AimbotSmoothing = 0,
    SkeletonESPColor = Color3.new(0.403922, 0.349020, 0.701961),
    TracerOrigin = 'Bottom Screen',
    RapidFireStrength = 99999999,
    WalkSpeed = 16,
    JumpPower = 50,
    SilentAimHitchance = 100,
    ProjectileSpeed = 1000,
    ChamsColor = Color3.new(1, 0, 0),
}

local ESPSettings = {
    BoxEnabled = true,
    BoxColor = Color3.new(0.403922, 0.349020, 0.701961),
}

-- Состояния
local State = {
    ESPDistance = 325,
    SilentAimEnabled = false,
    SilentAimFOVEnabled = false,
    SilentAim360FOV = false,
    Aimbot360FOV = false,
    WallbangEnabled = false,
    Wallbang360FOV = false,
    ESPCustomEnabled = false,
    NameESPEnabled = false,
    DistanceESPEnabled = false,
    SkeletonESPEnabled = false,
    HealthESPEnabled = false,
    TracerESPEnabled = false,
    FlyEnabled = false,
    NoclipEnabled = false,
    InfiniteJumpEnabled = false,
    AimbotEnabled = false,
    AimbotFOVEnabled = false,
    AimbotLocking = false,
    NoRecoilEnabled = false,
    NoSpreadEnabled = false,
    RapidFireEnabled = false,
    RagebotEnabled = false,
    SilentAimFOVCircle = nil,
    AimbotFOVCircle = nil,
    OriginalGravity = nil,
    FlyConnection = nil,
    WalkSpeedEnabled = false,
    JumpPowerEnabled = false,
    OriginalCameraCFrame = nil,
    OriginalPlayerCFrame = nil,
    WallbangedPlayer = nil,
    IsRagebotShooting = false,
    PredictionEnabled = false,
    ChamsEnabled = false,
    TriggerbotEnabled = false,
    IsTriggerbotShooting = false,
}

local Caches = {
    ESPCache = {},
    SkeletonCache = {},
    HealthCache = {},
    TracerCache = {},
    ChamsCache = {},
}

-- Хук функции
local clientItemModule = require(game:GetService("Players").LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
local inputFunc = clientItemModule.Input
local old; old = hookfunction(inputFunc, function(...)
    local args = {...}
    if type(args[1]) == "table" then
        if State.NoRecoilEnabled then
            args[1].Info.ShootRecoil = 0
        end
        if State.NoSpreadEnabled then
            args[1].Info.ShootSpread = 0
        end
        if State.RapidFireEnabled then
            args[1].Info.ProjectileSpeed = Config.RapidFireStrength
            args[1].Info.ShootCooldown = 0
            args[1].Info.QuickShotCooldown = 0
        end
    end
    return old(...)
end)

-- Функции (остаются такими же как в исходном коде)
local function get_players()
    local entities = {}
    for _, child in Workspace:GetChildren() do
        if child:FindFirstChildOfClass("Humanoid") then
            table.insert(entities, child)
        elseif child.Name == "HurtEffect" then
            for _, hurt_player in child:GetChildren() do
                if hurt_player.ClassName ~= "Highlight" then
                    table.insert(entities, hurt_player)
                end
            end
        end
    end
    return entities
end

local function predict_position(target, part)
    if not State.PredictionEnabled or not target or not target:FindFirstChild(part) or not target:FindFirstChild("HumanoidRootPart") then
        return target and target[part].Position
    end
    local velocity = target.HumanoidRootPart.Velocity
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - target[part].Position).Magnitude
    local travel_time = distance / Config.ProjectileSpeed
    return target[part].Position + (velocity * travel_time)
end

local function get_closest_player(fovRadius, isAimbot)
    local closest, closest_distance = nil, fovRadius
    local character = players.LocalPlayer.Character
    local team = LocalPlayer.Team

    if character == nil then
        return nil
    end

    for _, player in get_players() do
        local actualPlayer = players:GetPlayerFromCharacter(player) or player
        local shouldSkip = false

        if actualPlayer == players.LocalPlayer then
            shouldSkip = true
        end

        if not shouldSkip and (not player:FindFirstChild("HumanoidRootPart") or not player:FindFirstChild(Config.HitPart)) then
            shouldSkip = true
        end

        if not shouldSkip and Config.TeamCheck and team and actualPlayer.Team == team then
            shouldSkip = true
        end

        if not shouldSkip then
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - player.HumanoidRootPart.Position).Magnitude
            if distance > State.ESPDistance then
                shouldSkip = true
            end
        end

        local position, on_screen
        if isAimbot and State.PredictionEnabled then
            local predicted_pos = predict_position(player, Config.HitPart)
            position, on_screen = camera:WorldToViewportPoint(predicted_pos)
        else
            position, on_screen = camera:WorldToViewportPoint(player[Config.HitPart].Position)
        end

        if not shouldSkip and on_screen == false then
            shouldSkip = true
        end

        if not shouldSkip then
            local center = UserInputService:GetMouseLocation()
            local distance = (center - Vector2.new(position.X, position.Y)).Magnitude
            if (isAimbot and State.Aimbot360FOV) or (not isAimbot and State.SilentAim360FOV) or (not isAimbot and State.Wallbang360FOV) then
                closest = player
                closest_distance = distance
            elseif distance <= closest_distance then
                closest = player
                closest_distance = distance
            end
        end
    end
    return closest
end

local oldRaycast = utility.Raycast
utility.Raycast = function(...)
    local arguments = {...}
    if (State.SilentAimEnabled or (State.WallbangEnabled and State.Wallbang360FOV)) and #arguments > 0 and arguments[4] == 999 then
        if Config.SilentAimHitchance < 100 and math.random(1, 100) > Config.SilentAimHitchance then
            return oldRaycast(table.unpack(arguments))
        end
        local closest = get_closest_player(Config.SilentAimFOVRadius, false)
        if closest then
            local target_pos = predict_position(closest, Config.HitPart) or closest[Config.HitPart].Position
            arguments[3] = target_pos
        end
    end
    return oldRaycast(table.unpack(arguments))
end

local function UpdateFOVCircle()
    if not State.SilentAimFOVCircle then
        State.SilentAimFOVCircle = CreateFOVCircle("SilentAim")
    end
    if not State.AimbotFOVCircle then
        State.AimbotFOVCircle = CreateFOVCircle("Aimbot")
    end

    State.SilentAimFOVCircle.Position = UserInputService:GetMouseLocation()
    State.SilentAimFOVCircle.Radius = Config.SilentAimFOVRadius
    State.SilentAimFOVCircle.Thickness = 2 * (100 / Config.SilentAimFOVRadius)
    State.SilentAimFOVCircle.Visible = State.SilentAimFOVEnabled and not State.SilentAim360FOV

    State.AimbotFOVCircle.Position = UserInputService:GetMouseLocation()
    State.AimbotFOVCircle.Radius = Config.AimbotFOVRadius
    State.AimbotFOVCircle.Thickness = 2 * (100 / Config.AimbotFOVRadius)
    State.AimbotFOVCircle.Visible = State.AimbotFOVEnabled and not State.Aimbot360FOV
end

local function CreateFOVCircle(fovType)
    local circle = Drawing.new('Circle')
    local baseRadius = fovType == "SilentAim" and Config.SilentAimFOVRadius or Config.AimbotFOVRadius
    circle.Thickness = 2 * (100 / baseRadius)
    circle.Color = Config.FOVColor
    circle.Filled = false
    circle.Transparency = 1
    circle.Visible = false
    circle.ZIndex = 1
    circle.Radius = baseRadius
    circle.Position = UserInputService:GetMouseLocation()
    return circle
end

local function UpdateFly()
    if not State.FlyEnabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        if State.FlyConnection then
            State.FlyConnection:Disconnect()
            State.FlyConnection = nil
        end
        if State.OriginalGravity then
            Workspace.Gravity = State.OriginalGravity
            State.OriginalGravity = nil
        end
        return
    end

    if not State.FlyConnection then
        State.OriginalGravity = Workspace.Gravity
        Workspace.Gravity = 0

        local rootPart = LocalPlayer.Character.HumanoidRootPart
        local humanoid = LocalPlayer.Character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.PlatformStand = true
        end

        State.FlyConnection = RunService.RenderStepped:Connect(function(deltaTime)
            local moveDirection = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + (camera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - (camera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - (camera.CFrame.RightVector * Vector3.new(1, 0, 1)).Unit
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + (camera.CFrame.RightVector * Vector3.new(1, 0, 1)).Unit
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end

            if moveDirection.Magnitude > 0 then
                rootPart.Velocity = moveDirection.Unit * Config.FlySpeed
            else
                rootPart.Velocity = Vector3.new(0, 0, 0)
            end
        end)
    end
end

local function UpdateNoclip()
    if not State.NoclipEnabled or not LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA('BasePart') then
                part.CanCollide = true
            end
        end
        return
    end

    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA('BasePart') then
            part.CanCollide = false
        end
    end
end

local function UpdateInfiniteJump()
    if not State.InfiniteJumpEnabled then
        if State.FlyConnection then
            State.FlyConnection:Disconnect()
            State.FlyConnection = nil
        end
        return
    end

    if not State.FlyConnection then
        State.FlyConnection = RunService.RenderStepped:Connect(function()
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid')
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end
end

local function UpdateAimbot()
    if not State.AimbotEnabled or not State.AimbotLocking or not LocalPlayer.Character then
        return
    end

    local closest = get_closest_player(Config.AimbotFOVRadius, true)
    if closest and closest:FindFirstChild('Head') then
        local target_pos = predict_position(closest, 'Head') or closest.Head.Position
        local headPos, onScreen = camera:WorldToViewportPoint(target_pos)
        if onScreen then
            local mousePos = UserInputService:GetMouseLocation()
            local delta = Vector2.new(headPos.X, headPos.Y) - mousePos
            local smoothingFactor = ((25 - Config.AimbotSmoothing) / 50) ^ 2
            local smoothedDelta = delta * smoothingFactor
            mousemoverel(smoothedDelta.X, smoothedDelta.Y)
        end
    end
end

local function UpdateTriggerbot()
    if not State.TriggerbotEnabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        if State.IsTriggerbotShooting then
            mouse1release()
            State.IsTriggerbotShooting = false
        end
        return
    end

    local closest = get_closest_player(Config.AimbotFOVRadius, false)
    if closest and closest:FindFirstChild('HumanoidRootPart') and closest:FindFirstChild(Config.HitPart) then
        local mousePos = UserInputService:GetMouseLocation()
        local hitPart = closest[Config.HitPart]
        local isVisible = is_target_visible(closest, Config.HitPart)

        local cursorOverHitPart = false
        local screenPos, onScreen = camera:WorldToViewportPoint(hitPart.Position)
        if onScreen then
            local hitPartSize = hitPart.Size.Magnitude * 10
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if distance < hitPartSize then
                cursorOverHitPart = true
            end
        end

        if cursorOverHitPart and isVisible then
            if not State.IsTriggerbotShooting then
                mouse1press()
                State.IsTriggerbotShooting = true
            end
        else
            if State.IsTriggerbotShooting then
                mouse1release()
                State.IsTriggerbotShooting = false
            end
        end
    else
        if State.IsTriggerbotShooting then
            mouse1release()
            State.IsTriggerbotShooting = false
        end
    end
end

local function UpdateMovement()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('Humanoid') then
        return
    end

    local humanoid = LocalPlayer.Character.Humanoid
    if State.WalkSpeedEnabled then
        humanoid.WalkSpeed = Config.WalkSpeed
    end
    if State.JumpPowerEnabled then
        humanoid.JumpPower = Config.JumpPower
    end
    if not State.WalkSpeedEnabled then
        humanoid.WalkSpeed = 16
    end
    if not State.JumpPowerEnabled then
        humanoid.JumpPower = 50
    end
end

local function UpdateCameraFreeze()
    if State.Wallbang360FOV and State.OriginalCameraCFrame then
        camera.CFrame = State.OriginalCameraCFrame
    end
end

local function HandleWallbangTeleport()
    if not State.WallbangEnabled or not State.Wallbang360FOV or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        return
    end

    local closest = get_closest_player(Config.SilentAimFOVRadius, false)
    if closest and closest:FindFirstChild('HumanoidRootPart') and closest:FindFirstChild(Config.HitPart) then
        State.WallbangedPlayer = Players:GetPlayerFromCharacter(closest) or closest
        local targetRoot = closest.HumanoidRootPart
        local forwardDirection = targetRoot.CFrame.LookVector
        local teleportPos = targetRoot.Position + (forwardDirection * 10)
        
        teleportPos = Vector3.new(teleportPos.X, targetRoot.Position.Y, teleportPos.Z)
        
        local rayOrigin = targetRoot.Position
        local rayDirection = forwardDirection * 10
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, closest}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        if raycastResult then
            local hitDistance = (raycastResult.Position - rayOrigin).Magnitude
            if hitDistance < 10 then
                teleportPos = rayOrigin + (forwardDirection * (hitDistance - 1))
                teleportPos = Vector3.new(teleportPos.X, targetRoot.Position.Y, teleportPos.Z)
            end
        end
        
        local targetPos = targetRoot.Position
        local lookDirection = (targetPos - teleportPos).Unit
        local flatLookDirection = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
        local newCFrame = CFrame.new(teleportPos) * CFrame.new(Vector3.new(0, 0, 0), flatLookDirection)
        
        LocalPlayer.Character.HumanoidRootPart.CFrame = newCFrame
        
        local humanoid = LocalPlayer.Character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.AutoRotate = false
        end
        
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    else
        State.WallbangedPlayer = nil
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.AutoRotate = true
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

local function UpdateRagebot()
    if not State.RagebotEnabled or not LocalPlayer.Character then
        if State.IsRagebotShooting then
            mouse1release()
            State.IsRagebotShooting = false
        end
        return
    end

    local closest = get_closest_player(Config.SilentAimFOVRadius, false)
    if closest and closest:FindFirstChild(Config.HitPart) then
        local _, onScreen = camera:WorldToViewportPoint(closest[Config.HitPart].Position)
        local isVisible = is_target_visible(closest, Config.HitPart)
        
        if onScreen and isVisible then
            State.SilentAimEnabled = true
            if not State.IsRagebotShooting then
                mouse1press()
                State.IsRagebotShooting = true
            end
        else
            if State.IsRagebotShooting then
                mouse1release()
                State.IsRagebotShooting = false
            end
        end
    else
        if State.IsRagebotShooting then
            mouse1release()
            State.IsRagebotShooting = false
        end
    end
end

-- ESP функции
local function CreateESP(player)
    local esp = {
        Box = Drawing.new('Square'),
        Name = Drawing.new('Text'),
        Distance = Drawing.new('Text'),
    }

    esp.Box.Thickness = 2
    esp.Box.Color = ESPSettings.BoxColor
    esp.Box.Filled = false
    esp.Box.Visible = false

    esp.Name.Size = 16
    esp.Name.Color = Color3.new(1, 1, 1)
    esp.Name.Outline = true
    esp.Name.Center = true
    esp.Name.Visible = false

    esp.Distance.Size = 16
    esp.Distance.Color = Color3.new(1, 1, 1)
    esp.Distance.Outline = true
    esp.Distance.Center = true
    esp.Distance.Visible = false

    return esp
end

local function CreateSkeleton(player)
    local skeleton = {
        HeadToNeck = Drawing.new('Line'),
        NeckToUpperTorso = Drawing.new('Line'),
        UpperTorsoToLowerTorso = Drawing.new('Line'),
        UpperTorsoToLeftUpperArm = Drawing.new('Line'),
        LeftUpperArmToLeftLowerArm = Drawing.new('Line'),
        LeftLowerArmToLeftHand = Drawing.new('Line'),
        UpperTorsoToRightUpperArm = Drawing.new('Line'),
        RightUpperArmToRightLowerArm = Drawing.new('Line'),
        RightLowerArmToRightHand = Drawing.new('Line'),
        LowerTorsoToLeftUpperLeg = Drawing.new('Line'),
        LeftUpperLegToLeftLowerLeg = Drawing.new('Line'),
        LeftLowerLegToLeftFoot = Drawing.new('Line'),
        LowerTorsoToRightUpperLeg = Drawing.new('Line'),
        RightUpperLegToRightLowerLeg = Drawing.new('Line'),
        RightLowerLegToRightFoot = Drawing.new('Line'),
    }

    for _, line in pairs(skeleton) do
        line.Thickness = 2
        line.Color = Config.SkeletonESPColor
        line.Visible = false
    end

    return skeleton
end

local function CreateHealthESP(player)
    local health = {
        BarBackground = Drawing.new('Square'),
        Bar = Drawing.new('Square'),
        Text = Drawing.new('Text'),
    }

    health.BarBackground.Size = Vector2.new(50, 5)
    health.BarBackground.Color = Color3.new(0, 0, 0)
    health.BarBackground.Filled = true
    health.BarBackground.Transparency = 0.5
    health.BarBackground.Visible = false

    health.Bar.Size = Vector2.new(50, 5)
    health.Bar.Color = Color3.new(0, 1, 0)
    health.Bar.Filled = true
    health.Bar.Visible = false

    health.Text.Size = 12
    health.Text.Color = Color3.new(1, 1, 1)
    health.Text.Outline = true
    health.Text.Center = true
    health.Text.Visible = false

    return health
end

local function CreateTracer(player)
    local tracer = Drawing.new('Line')
    tracer.Thickness = 2
    tracer.Color = Color3.new(0.403922, 0.349020, 0.701961)
    tracer.Visible = false
    return tracer
end

local function CreateChams(player)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Config.ChamsColor
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = player.Character
    highlight.Adornee = player.Character
    return highlight
end

local function ClearESP(player)
    if Caches.ESPCache[player] then
        Caches.ESPCache[player].Box:Remove()
        Caches.ESPCache[player].Name:Remove()
        Caches.ESPCache[player].Distance:Remove()
        Caches.ESPCache[player] = nil
    end
end

local function ClearSkeleton(player)
    if Caches.SkeletonCache[player] then
        for _, line in pairs(Caches.SkeletonCache[player]) do
            line:Remove()
        end
        Caches.SkeletonCache[player] = nil
    end
end

local function ClearHealthESP(player)
    if Caches.HealthCache[player] then
        Caches.HealthCache[player].BarBackground:Remove()
        Caches.HealthCache[player].Bar:Remove()
        Caches.HealthCache[player].Text:Remove()
        Caches.HealthCache[player] = nil
    end
end

local function ClearTracer(player)
    if Caches.TracerCache[player] then
        Caches.TracerCache[player]:Remove()
        Caches.TracerCache[player] = nil
    end
end

local function ClearChams(player)
    if Caches.ChamsCache[player] then
        Caches.ChamsCache[player]:Destroy()
        Caches.ChamsCache[player] = nil
    end
end

local function UpdateESP()
    if not (State.ESPCustomEnabled or State.NameESPEnabled or State.DistanceESPEnabled) then
        for player, _ in pairs(Caches.ESPCache) do
            ClearESP(player)
        end
        return
    end

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        for player, _ in pairs(Caches.ESPCache) do
            ClearESP(player)
        end
        return
    end

    local localRoot = LocalPlayer.Character.HumanoidRootPart
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if not player.Character or not player.Character:FindFirstChild('HumanoidRootPart') or not player.Character:FindFirstChild('Humanoid') then
            ClearESP(player)
            continue
        end

        local character = player.Character
        local humanoid = character.Humanoid
        if humanoid.Health <= 0 then
            ClearESP(player)
            continue
        end

        local targetRoot = character.HumanoidRootPart
        local distance = (localRoot.Position - targetRoot.Position).Magnitude
        if distance > State.ESPDistance then
            ClearESP(player)
            continue
        end

        if Config.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            ClearESP(player)
            continue
        end

        if State.Wallbang360FOV and player == State.WallbangedPlayer then
            ClearESP(player)
            continue
        end

        if not Caches.ESPCache[player] then
            Caches.ESPCache[player] = CreateESP(player)
        end

        local esp = Caches.ESPCache[player]
        local rootPos, onScreen = camera:WorldToViewportPoint(targetRoot.Position)
        if onScreen then
            local head = character:FindFirstChild("Head")
            local topPos = head and camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0)) or camera:WorldToViewportPoint(targetRoot.Position + Vector3.new(0, 3, 0))
            local bottomPos = camera:WorldToViewportPoint(targetRoot.Position - Vector3.new(0, 3, 0))
            local height = math.abs(topPos.Y - bottomPos.Y)
            local width = height * 0.5
            local centerPos = Vector2.new(rootPos.X, (topPos.Y + bottomPos.Y) / 2)
            esp.Box.Size = Vector2.new(width, height)
            esp.Box.Position = centerPos - Vector2.new(width / 2, height / 2)
            esp.Box.Visible = ESPSettings.BoxEnabled and State.ESPCustomEnabled
            esp.Name.Text = player.Name
            esp.Name.Position = Vector2.new(rootPos.X, topPos.Y - 20)
            esp.Name.Visible = State.NameESPEnabled
            esp.Distance.Text = tostring(math.floor(distance)) .. " studs"
            esp.Distance.Position = Vector2.new(rootPos.X, bottomPos.Y + 5)
            esp.Distance.Visible = State.DistanceESPEnabled
        else
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
        end
    end
end

local function UpdateSkeletonESP()
    if not State.SkeletonESPEnabled then
        for player, _ in pairs(Caches.SkeletonCache) do
            ClearSkeleton(player)
        end
        return
    end

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        for player, _ in pairs(Caches.SkeletonCache) do
            ClearSkeleton(player)
        end
        return
    end

    local localRoot = LocalPlayer.Character.HumanoidRootPart
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if not player.Character or not player.Character:FindFirstChild('HumanoidRootPart') or not player.Character:FindFirstChild('Humanoid') then
            ClearSkeleton(player)
            continue
        end

        local character = player.Character
        local humanoid = character.Humanoid
        if humanoid.Health <= 0 then
            ClearSkeleton(player)
            continue
        end

        local targetRoot = character.HumanoidRootPart
        local distance = (localRoot.Position - targetRoot.Position).Magnitude
        if distance > State.ESPDistance then
            ClearSkeleton(player)
            continue
        end

        if Config.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            ClearSkeleton(player)
            continue
        end

        if State.Wallbang360FOV and player == State.WallbangedPlayer then
            ClearSkeleton(player)
            continue
        end

        if not Caches.SkeletonCache[player] then
            Caches.SkeletonCache[player] = CreateSkeleton(player)
        end

        local skeleton = Caches.SkeletonCache[player]
        local parts = {
            Head = character:FindFirstChild("Head"),
            Neck = character:FindFirstChild("Neck") or character:FindFirstChild("Head"),
            UpperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
            LowerTorso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("HumanoidRootPart"),
            LeftUpperArm = character:FindFirstChild("LeftUpperArm"),
            LeftLowerArm = character:FindFirstChild("LeftLowerArm"),
            LeftHand = character:FindFirstChild("LeftHand"),
            RightUpperArm = character:FindFirstChild("RightUpperArm"),
            RightLowerArm = character:FindFirstChild("RightLowerArm"),
            RightHand = character:FindFirstChild("RightHand"),
            LeftUpperLeg = character:FindFirstChild("LeftUpperLeg"),
            LeftLowerLeg = character:FindFirstChild("LeftLowerLeg"),
            LeftFoot = character:FindFirstChild("LeftFoot"),
            RightUpperLeg = character:FindFirstChild("RightUpperLeg"),
            RightLowerLeg = character:FindFirstChild("RightLowerLeg"),
            RightFoot = character:FindFirstChild("RightFoot"),
        }

        if not (parts.Head and parts.UpperTorso and parts.LowerTorso and parts.LeftUpperArm and parts.LeftLowerArm and parts.LeftHand and parts.RightUpperArm and parts.RightLowerArm and parts.RightHand and parts.LeftUpperLeg and parts.LeftLowerLeg and parts.LeftFoot and parts.RightUpperLeg and parts.RightLowerLeg and parts.RightFoot) then
            ClearSkeleton(player)
            continue
        end

        local headPos, headOnScreen = camera:WorldToViewportPoint(parts.Head.Position)
        local neckPos, neckOnScreen = camera:WorldToViewportPoint(parts.Neck.Position)
        local upperTorsoPos, upperTorsoOnScreen = camera:WorldToViewportPoint(parts.UpperTorso.Position)
        local lowerTorsoPos, lowerTorsoOnScreen = camera:WorldToViewportPoint(parts.LowerTorso.Position)
        local leftUpperArmPos, leftUpperArmOnScreen = camera:WorldToViewportPoint(parts.LeftUpperArm.Position)
        local leftLowerArmPos, leftLowerArmOnScreen = camera:WorldToViewportPoint(parts.LeftLowerArm.Position)
        local leftHandPos, leftHandOnScreen = camera:WorldToViewportPoint(parts.LeftHand.Position)
        local rightUpperArmPos, rightUpperArmOnScreen = camera:WorldToViewportPoint(parts.RightUpperArm.Position)
        local rightLowerArmPos, rightLowerArmOnScreen = camera:WorldToViewportPoint(parts.RightLowerArm.Position)
        local rightHandPos, rightHandOnScreen = camera:WorldToViewportPoint(parts.RightHand.Position)
        local leftUpperLegPos, leftUpperLegOnScreen = camera:WorldToViewportPoint(parts.LeftUpperLeg.Position)
        local leftLowerLegPos, leftLowerLegOnScreen = camera:WorldToViewportPoint(parts.LeftLowerLeg.Position)
        local leftFootPos, leftFootOnScreen = camera:WorldToViewportPoint(parts.LeftFoot.Position)
        local rightUpperLegPos, rightUpperLegOnScreen = camera:WorldToViewportPoint(parts.RightUpperLeg.Position)
        local rightLowerLegPos, rightLowerLegOnScreen = camera:WorldToViewportPoint(parts.RightLowerLeg.Position)
        local rightFootPos, rightFootOnScreen = camera:WorldToViewportPoint(parts.RightFoot.Position)

        if headOnScreen and neckOnScreen then
            skeleton.HeadToNeck.From = Vector2.new(headPos.X, headPos.Y)
            skeleton.HeadToNeck.To = Vector2.new(neckPos.X, neckPos.Y)
            skeleton.HeadToNeck.Visible = true
        else
            skeleton.HeadToNeck.Visible = false
        end

        if neckOnScreen and upperTorsoOnScreen then
            skeleton.NeckToUpperTorso.From = Vector2.new(neckPos.X, neckPos.Y)
            skeleton.NeckToUpperTorso.To = Vector2.new(upperTorsoPos.X, upperTorsoPos.Y)
            skeleton.NeckToUpperTorso.Visible = true
        else
            skeleton.NeckToUpperTorso.Visible = false
        end

        if upperTorsoOnScreen and lowerTorsoOnScreen then
            skeleton.UpperTorsoToLowerTorso.From = Vector2.new(upperTorsoPos.X, upperTorsoPos.Y)
            skeleton.UpperTorsoToLowerTorso.To = Vector2.new(lowerTorsoPos.X, lowerTorsoPos.Y)
            skeleton.UpperTorsoToLowerTorso.Visible = true
        else
            skeleton.UpperTorsoToLowerTorso.Visible = false
        end

        if upperTorsoOnScreen and leftUpperArmOnScreen then
            skeleton.UpperTorsoToLeftUpperArm.From = Vector2.new(upperTorsoPos.X, upperTorsoPos.Y)
            skeleton.UpperTorsoToLeftUpperArm.To = Vector2.new(leftUpperArmPos.X, leftUpperArmPos.Y)
            skeleton.UpperTorsoToLeftUpperArm.Visible = true
        else
            skeleton.UpperTorsoToLeftUpperArm.Visible = false
        end

        if leftUpperArmOnScreen and leftLowerArmOnScreen then
            skeleton.LeftUpperArmToLeftLowerArm.From = Vector2.new(leftUpperArmPos.X, leftUpperArmPos.Y)
            skeleton.LeftUpperArmToLeftLowerArm.To = Vector2.new(leftLowerArmPos.X, leftLowerArmPos.Y)
            skeleton.LeftUpperArmToLeftLowerArm.Visible = true
        else
            skeleton.LeftUpperArmToLeftLowerArm.Visible = false
        end

        if leftLowerArmOnScreen and leftHandOnScreen then
            skeleton.LeftLowerArmToLeftHand.From = Vector2.new(leftLowerArmPos.X, leftLowerArmPos.Y)
            skeleton.LeftLowerArmToLeftHand.To = Vector2.new(leftHandPos.X, leftHandPos.Y)
            skeleton.LeftLowerArmToLeftHand.Visible = true
        else
            skeleton.LeftLowerArmToLeftHand.Visible = false
        end

        if upperTorsoOnScreen and rightUpperArmOnScreen then
            skeleton.UpperTorsoToRightUpperArm.From = Vector2.new(upperTorsoPos.X, upperTorsoPos.Y)
            skeleton.UpperTorsoToRightUpperArm.To = Vector2.new(rightUpperArmPos.X, rightUpperArmPos.Y)
            skeleton.UpperTorsoToRightUpperArm.Visible = true
        else
            skeleton.UpperTorsoToRightUpperArm.Visible = false
        end

        if rightUpperArmOnScreen and rightLowerArmOnScreen then
            skeleton.RightUpperArmToRightLowerArm.From = Vector2.new(rightUpperArmPos.X, rightUpperArmPos.Y)
            skeleton.RightUpperArmToRightLowerArm.To = Vector2.new(rightLowerArmPos.X, rightLowerArmPos.Y)
            skeleton.RightUpperArmToRightLowerArm.Visible = true
        else
            skeleton.RightUpperArmToRightLowerArm.Visible = false
        end

        if rightLowerArmOnScreen and rightHandOnScreen then
            skeleton.RightLowerArmToRightHand.From = Vector2.new(rightLowerArmPos.X, rightLowerArmPos.Y)
            skeleton.RightLowerArmToRightHand.To = Vector2.new(rightHandPos.X, rightHandPos.Y)
            skeleton.RightLowerArmToRightHand.Visible = true
        else
            skeleton.RightLowerArmToRightHand.Visible = false
        end

        if lowerTorsoOnScreen and leftUpperLegOnScreen then
            skeleton.LowerTorsoToLeftUpperLeg.From = Vector2.new(lowerTorsoPos.X, lowerTorsoPos.Y)
            skeleton.LowerTorsoToLeftUpperLeg.To = Vector2.new(leftUpperLegPos.X, leftUpperLegPos.Y)
            skeleton.LowerTorsoToLeftUpperLeg.Visible = true
        else
            skeleton.LowerTorsoToLeftUpperLeg.Visible = false
        end

        if leftUpperLegOnScreen and leftLowerLegOnScreen then
            skeleton.LeftUpperLegToLeftLowerLeg.From = Vector2.new(leftUpperLegPos.X, leftUpperLegPos.Y)
            skeleton.LeftUpperLegToLeftLowerLeg.To = Vector2.new(leftLowerLegPos.X, leftLowerLegPos.Y)
            skeleton.LeftUpperLegToLeftLowerLeg.Visible = true
        else
            skeleton.LeftUpperLegToLeftLowerLeg.Visible = false
        end

        if leftLowerLegOnScreen and leftFootOnScreen then
            skeleton.LeftLowerLegToLeftFoot.From = Vector2.new(leftLowerLegPos.X, leftLowerLegPos.Y)
            skeleton.LeftLowerLegToLeftFoot.To = Vector2.new(leftFootPos.X, leftFootPos.Y)
            skeleton.LeftLowerLegToLeftFoot.Visible = true
        else
            skeleton.LeftLowerLegToLeftFoot.Visible = false
        end

        if lowerTorsoOnScreen and rightUpperLegOnScreen then
            skeleton.LowerTorsoToRightUpperLeg.From = Vector2.new(lowerTorsoPos.X, lowerTorsoPos.Y)
            skeleton.LowerTorsoToRightUpperLeg.To = Vector2.new(rightUpperLegPos.X, rightUpperLegPos.Y)
            skeleton.LowerTorsoToRightUpperLeg.Visible = true
        else
            skeleton.LowerTorsoToRightUpperLeg.Visible = false
        end

        if rightUpperLegOnScreen and rightLowerLegOnScreen then
            skeleton.RightUpperLegToRightLowerLeg.From = Vector2.new(rightUpperLegPos.X, rightUpperLegPos.Y)
            skeleton.RightUpperLegToRightLowerLeg.To = Vector2.new(rightLowerLegPos.X, rightLowerLegPos.Y)
            skeleton.RightUpperLegToRightLowerLeg.Visible = true
        else
            skeleton.RightUpperLegToRightLowerLeg.Visible = false
        end

        if rightLowerLegOnScreen and rightFootOnScreen then
            skeleton.RightLowerLegToRightFoot.From = Vector2.new(rightLowerLegPos.X, rightLowerLegPos.Y)
            skeleton.RightLowerLegToRightFoot.To = Vector2.new(rightFootPos.X, rightFootPos.Y)
            skeleton.RightLowerLegToRightFoot.Visible = true
        else
            skeleton.RightLowerLegToRightFoot.Visible = false
        end
    end
end

local function UpdateHealthESP()
    if not State.HealthESPEnabled then
        for player, _ in pairs(Caches.HealthCache) do
            ClearHealthESP(player)
        end
        return
    end

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        for player, _ in pairs(Caches.HealthCache) do
            ClearHealthESP(player)
        end
        return
    end

    local localRoot = LocalPlayer.Character.HumanoidRootPart
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if not player.Character or not player.Character:FindFirstChild('HumanoidRootPart') or not player.Character:FindFirstChild('Humanoid') then
            ClearHealthESP(player)
            continue
        end

        local character = player.Character
        local humanoid = character.Humanoid
        if humanoid.Health <= 0 then
            ClearHealthESP(player)
            continue
        end

        local targetRoot = character.HumanoidRootPart
        local distance = (localRoot.Position - targetRoot.Position).Magnitude
        if distance > State.ESPDistance then
            ClearHealthESP(player)
            continue
        end

        if Config.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            ClearHealthESP(player)
            continue
        end

        if State.Wallbang360FOV and player == State.WallbangedPlayer then
            ClearHealthESP(player)
            continue
        end

        if not Caches.HealthCache[player] then
            Caches.HealthCache[player] = CreateHealthESP(player)
        end

        local health = Caches.HealthCache[player]
        local headPos, onScreen = camera:WorldToViewportPoint(targetRoot.Position - Vector3.new(0, 3, 0))
        if onScreen then
            local healthPercentage = humanoid.Health / humanoid.MaxHealth
            health.BarBackground.Position = Vector2.new(headPos.X - 25, headPos.Y - 30)
            health.BarBackground.Visible = true
            health.Bar.Size = Vector2.new(50 * healthPercentage, 5)
            health.Bar.Position = Vector2.new(headPos.X - 25, headPos.Y - 30)
            health.Bar.Color = Color3.new(1 - healthPercentage, healthPercentage, 0)
            health.Bar.Visible = true
            health.Text.Text = tostring(math.floor(healthPercentage * 100)) .. "%"
            health.Text.Position = Vector2.new(headPos.X, headPos.Y - 45)
            health.Text.Visible = true
        else
            health.BarBackground.Visible = false
            health.Bar.Visible = false
            health.Text.Visible = false
        end
    end
end

local function UpdateTracerESP()
    if not State.TracerESPEnabled then
        for player, _ in pairs(Caches.TracerCache) do
            ClearTracer(player)
        end
        return
    end

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        for player, _ in pairs(Caches.TracerCache) do
            ClearTracer(player)
        end
        return
    end

    local localRoot = LocalPlayer.Character.HumanoidRootPart
    local screenSize = camera.ViewportSize
    local tracerFrom
    if Config.TracerOrigin == 'Bottom Screen' then
        tracerFrom = Vector2.new(screenSize.X / 2, screenSize.Y)
    elseif Config.TracerOrigin == 'Cursor' then
        tracerFrom = UserInputService:GetMouseLocation()
    elseif Config.TracerOrigin == 'Top Screen' then
        tracerFrom = Vector2.new(screenSize.X / 2, 0)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if not player.Character or not player.Character:FindFirstChild('HumanoidRootPart') or not player.Character:FindFirstChild('Humanoid') then
            ClearTracer(player)
            continue
        end

        local character = player.Character
        local humanoid = character.Humanoid
        if humanoid.Health <= 0 then
            ClearTracer(player)
            continue
        end

        local targetHead = character:FindFirstChild("Head") or character.HumanoidRootPart
        local distance = (localRoot.Position - targetHead.Position).Magnitude
        if distance > State.ESPDistance then
            ClearTracer(player)
            continue
        end

        if Config.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            ClearTracer(player)
            continue
        end

        if State.Wallbang360FOV and player == State.WallbangedPlayer then
            ClearTracer(player)
            continue
        end

        if not Caches.TracerCache[player] then
            Caches.TracerCache[player] = CreateTracer(player)
        end

        local tracer = Caches.TracerCache[player]
        local headPos, onScreen = camera:WorldToViewportPoint(targetHead.Position)
        tracer.From = tracerFrom
        tracer.To = Vector2.new(headPos.X, headPos.Y)
        tracer.Visible = onScreen
    end
end

local function UpdateChams()
    if not State.ChamsEnabled then
        for player, _ in pairs(Caches.ChamsCache) do
            ClearChams(player)
        end
        return
    end

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        for player, _ in pairs(Caches.ChamsCache) do
            ClearChams(player)
        end
        return
    end

    local localRoot = LocalPlayer.Character.HumanoidRootPart
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if not player.Character or not player.Character:FindFirstChild('HumanoidRootPart') or not player.Character:FindFirstChild('Humanoid') then
            ClearChams(player)
            continue
        end

        local character = player.Character
        local humanoid = character.Humanoid
        if humanoid.Health <= 0 then
            ClearChams(player)
            continue
        end

        local targetRoot = character.HumanoidRootPart
        local distance = (localRoot.Position - targetRoot.Position).Magnitude
        if distance > State.ESPDistance then
            ClearChams(player)
            continue
        end

        if Config.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            ClearChams(player)
            continue
        end

        if State.Wallbang360FOV and player == State.WallbangedPlayer then
            ClearChams(player)
            continue
        end

        if not Caches.ChamsCache[player] then
            Caches.ChamsCache[player] = CreateChams(player)
        end
    end
end
    local rayOrigin = camera.CFrame.Position
    local rayDirection = (target[hitPart].Position - rayOrigin).Unit * 1000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if raycastResult then
        local hitInstance = raycastResult.Instance
        return hitInstance and hitInstance:IsDescendantOf(target)
    end
    return false
end

-- GUI Элементы для Legit Tab
Tabs.Legit:CreateSection("Aimbot")

local AimbotToggle = Tabs.Legit:CreateToggle("AimbotToggle", {
    Title = "Enable Aimbot",
    Default = false
})

AimbotToggle:OnChanged(function()
    State.AimbotEnabled = Options.AimbotToggle.Value
    if not State.AimbotEnabled then
        State.AimbotLocking = false
    end
end)

local AimbotFOVToggle = Tabs.Legit:CreateToggle("AimbotFOVToggle", {
    Title = "Show FOV Circle",
    Default = false
})

AimbotFOVToggle:OnChanged(function()
    State.AimbotFOVEnabled = Options.AimbotFOVToggle.Value
end)

local Aimbot360FOVToggle = Tabs.Legit:CreateToggle("Aimbot360FOVToggle", {
    Title = "360 FOV",
    Default = false
})

Aimbot360FOVToggle:OnChanged(function()
    State.Aimbot360FOV = Options.Aimbot360FOVToggle.Value
end)

local AimbotFOVSlider = Tabs.Legit:CreateSlider("AimbotFOVSlider", {
    Title = "FOV Size",
    Description = "Aimbot field of view size",
    Default = Config.AimbotFOVRadius,
    Min = 50,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        Config.AimbotFOVRadius = Value
    end
})

local AimbotSmoothingSlider = Tabs.Legit:CreateSlider("AimbotSmoothingSlider", {
    Title = "Smoothing",
    Description = "Aimbot smoothing factor",
    Default = Config.AimbotSmoothing,
    Min = 0,
    Max = 25,
    Rounding = 0,
    Callback = function(Value)
        Config.AimbotSmoothing = Value
    end
})

Tabs.Legit:CreateSection("Other Legit Features")

local PredictionToggle = Tabs.Legit:CreateToggle("PredictionToggle", {
    Title = "Enable Prediction",
    Default = false
})

PredictionToggle:OnChanged(function()
    State.PredictionEnabled = Options.PredictionToggle.Value
end)

local TriggerbotToggle = Tabs.Legit:CreateToggle("TriggerbotToggle", {
    Title = "Enable Triggerbot",
    Default = false
})

TriggerbotToggle:OnChanged(function()
    State.TriggerbotEnabled = Options.TriggerbotToggle.Value
    if not State.TriggerbotEnabled and State.IsTriggerbotShooting then
        mouse1release()
        State.IsTriggerbotShooting = false
    end
end)

-- GUI Элементы для Rage Tab
Tabs.Rage:CreateSection("Silent Aim")

local SilentAimToggle = Tabs.Rage:CreateToggle("SilentAimToggle", {
    Title = "Enable Silent Aim",
    Default = false
})

SilentAimToggle:OnChanged(function()
    State.SilentAimEnabled = Options.SilentAimToggle.Value
end)

local SilentAimFOVToggle = Tabs.Rage:CreateToggle("SilentAimFOVToggle", {
    Title = "Show FOV Circle",
    Default = false
})

SilentAimFOVToggle:OnChanged(function()
    State.SilentAimFOVEnabled = Options.SilentAimFOVToggle.Value
end)

local SilentAim360FOVToggle = Tabs.Rage:CreateToggle("SilentAim360FOVToggle", {
    Title = "360 FOV",
    Default = false
})

SilentAim360FOVToggle:OnChanged(function()
    State.SilentAim360FOV = Options.SilentAim360FOVToggle.Value
end)

local SilentAimFOVSlider = Tabs.Rage:CreateSlider("SilentAimFOVSlider", {
    Title = "FOV Size",
    Description = "Silent aim field of view size",
    Default = Config.SilentAimFOVRadius,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        Config.SilentAimFOVRadius = Value
    end
})

local SilentAimHitchanceSlider = Tabs.Rage:CreateSlider("SilentAimHitchanceSlider", {
    Title = "Hitchance",
    Description = "Silent aim hitchance percentage",
    Default = Config.SilentAimHitchance,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%",
    Callback = function(Value)
        Config.SilentAimHitchance = Value
    end
})

Tabs.Rage:CreateSection("Rage Features")

local HitPartDropdown = Tabs.Rage:CreateDropdown("HitPartDropdown", {
    Title = "Hit Part",
    Description = "Select target hit part",
    Values = {"Head", "UpperTorso", "LowerTorso"},
    Multi = false,
    Default = Config.HitPart,
})

HitPartDropdown:OnChanged(function(Value)
    Config.HitPart = Value
end)

local WallbangToggle = Tabs.Rage:CreateToggle("WallbangToggle", {
    Title = "Enable Wallbang",
    Default = false
})

WallbangToggle:OnChanged(function()
    State.WallbangEnabled = Options.WallbangToggle.Value
    if not State.WallbangEnabled then
        State.Wallbang360FOV = false
        State.OriginalCameraCFrame = nil
        State.OriginalPlayerCFrame = nil
        State.WallbangedPlayer = nil
    end
end)

local RagebotToggle = Tabs.Rage:CreateToggle("RagebotToggle", {
    Title = "Enable Ragebot",
    Default = false
})

RagebotToggle:OnChanged(function()
    State.RagebotEnabled = Options.RagebotToggle.Value
    if not State.RagebotEnabled and State.IsRagebotShooting then
        mouse1release()
        State.IsRagebotShooting = false
    end
end)

-- GUI Элементы для Visuals Tab
Tabs.Visuals:CreateSection("ESP Settings")

local ESPCustomToggle = Tabs.Visuals:CreateToggle("ESPCustomToggle", {
    Title = "Box ESP",
    Default = false
})

ESPCustomToggle:OnChanged(function()
    State.ESPCustomEnabled = Options.ESPCustomToggle.Value
end)

local NameESPToggle = Tabs.Visuals:CreateToggle("NameESPToggle", {
    Title = "Name ESP",
    Default = false
})

NameESPToggle:OnChanged(function()
    State.NameESPEnabled = Options.NameESPToggle.Value
end)

local DistanceESPToggle = Tabs.Visuals:CreateToggle("DistanceESPToggle", {
    Title = "Distance ESP",
    Default = false
})

DistanceESPToggle:OnChanged(function()
    State.DistanceESPEnabled = Options.DistanceESPToggle.Value
end)

local SkeletonESPToggle = Tabs.Visuals:CreateToggle("SkeletonESPToggle", {
    Title = "Skeleton ESP",
    Default = false
})

SkeletonESPToggle:OnChanged(function()
    State.SkeletonESPEnabled = Options.SkeletonESPToggle.Value
end)

local HealthESPToggle = Tabs.Visuals:CreateToggle("HealthESPToggle", {
    Title = "Health ESP",
    Default = false
})

HealthESPToggle:OnChanged(function()
    State.HealthESPEnabled = Options.HealthESPToggle.Value
end)

local TracerESPToggle = Tabs.Visuals:CreateToggle("TracerESPToggle", {
    Title = "Tracer ESP",
    Default = false
})

TracerESPToggle:OnChanged(function()
    State.TracerESPEnabled = Options.TracerESPToggle.Value
end)

local ChamsToggle = Tabs.Visuals:CreateToggle("ChamsToggle", {
    Title = "Chams",
    Default = false
})

ChamsToggle:OnChanged(function()
    State.ChamsEnabled = Options.ChamsToggle.Value
end)

Tabs.Visuals:CreateSection("Visual Settings")

local TracerOriginDropdown = Tabs.Visuals:CreateDropdown("TracerOriginDropdown", {
    Title = "Tracer Origin",
    Description = "Select tracer line origin",
    Values = {"Bottom Screen", "Cursor", "Top Screen"},
    Multi = false,
    Default = Config.TracerOrigin,
})

TracerOriginDropdown:OnChanged(function(Value)
    Config.TracerOrigin = Value
end)

local ESPTeamCheckToggle = Tabs.Visuals:CreateToggle("ESPTeamCheckToggle", {
    Title = "Team Check",
    Default = Config.TeamCheck
})

ESPTeamCheckToggle:OnChanged(function()
    Config.TeamCheck = Options.ESPTeamCheckToggle.Value
end)

-- GUI Элементы для Player Tab
Tabs.Player:CreateSection("Movement")

local FlyToggle = Tabs.Player:CreateToggle("FlyToggle", {
    Title = "Enable Fly",
    Default = false
})

FlyToggle:OnChanged(function()
    State.FlyEnabled = Options.FlyToggle.Value
    -- Здесь должна быть функция UpdateFly()
end)

local FlySpeedSlider = Tabs.Player:CreateSlider("FlySpeedSlider", {
    Title = "Fly Speed",
    Description = "Flight movement speed",
    Default = Config.FlySpeed,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        Config.FlySpeed = Value
    end
})

local NoclipToggle = Tabs.Player:CreateToggle("NoclipToggle", {
    Title = "Enable Noclip",
    Default = false
})

NoclipToggle:OnChanged(function()
    State.NoclipEnabled = Options.NoclipToggle.Value
    -- Здесь должна быть функция UpdateNoclip()
end)

local InfiniteJumpToggle = Tabs.Player:CreateToggle("InfiniteJumpToggle", {
    Title = "Enable Infinite Jump",
    Default = false
})

InfiniteJumpToggle:OnChanged(function()
    State.InfiniteJumpEnabled = Options.InfiniteJumpToggle.Value
    -- Здесь должна быть функция UpdateInfiniteJump()
end)

-- GUI Элементы для Exploits Tab
Tabs.Exploits:CreateSection("Weapon Modifications")

local NoRecoilToggle = Tabs.Exploits:CreateToggle("NoRecoilToggle", {
    Title = "No Recoil",
    Default = false
})

NoRecoilToggle:OnChanged(function()
    State.NoRecoilEnabled = Options.NoRecoilToggle.Value
end)

local NoSpreadToggle = Tabs.Exploits:CreateToggle("NoSpreadToggle", {
    Title = "No Spread",
    Default = false
})

NoSpreadToggle:OnChanged(function()
    State.NoSpreadEnabled = Options.NoSpreadToggle.Value
end)

local RapidFireToggle = Tabs.Exploits:CreateToggle("RapidFireToggle", {
    Title = "Rapid Fire",
    Default = false
})

RapidFireToggle:OnChanged(function()
    State.RapidFireEnabled = Options.RapidFireToggle.Value
end)

-- Обработчики событий
players.PlayerRemoving:Connect(function(player)
    SafeExecute(function()
        ClearESP(player)
        ClearSkeleton(player)
        ClearHealthESP(player)
        ClearTracer(player)
        ClearChams(player)
        if player == State.WallbangedPlayer then
            State.WallbangedPlayer = nil
        end
    end)
end)

players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        character.AncestryChanged:Connect(function()
            if not character:IsDescendantOf(Workspace) then
                SafeExecute(function()
                    ClearESP(player)
                    ClearSkeleton(player)
                    ClearHealthESP(player)
                    ClearTracer(player)
                    ClearChams(player)
                    if player == State.WallbangedPlayer then
                        State.WallbangedPlayer = nil
                    end
                end)
            end
        end)
        local humanoid = character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.Died:Connect(function()
                SafeExecute(function()
                    ClearESP(player)
                    ClearSkeleton(player)
                    ClearHealthESP(player)
                    ClearTracer(player)
                    ClearChams(player)
                    if player == State.WallbangedPlayer then
                        State.WallbangedPlayer = nil
                    end
                end)
            end)
        end
    end)
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild('Humanoid', 20)
    if not humanoid then
        warn("Humanoid not found in character after waiting")
        return
    end

    if State.WalkSpeedEnabled or State.JumpPowerEnabled then
        UpdateMovement()
    end
    if State.FlyEnabled then
        UpdateFly()
    end
    if State.NoclipEnabled then
        UpdateNoclip()
    end
    if State.InfiniteJumpEnabled then
        UpdateInfiniteJump()
    end
end)

if LocalPlayer.Character then
    local humanoid = LocalPlayer.Character:FindFirstChild('Humanoid')
    if humanoid then
        if State.WalkSpeedEnabled or State.JumpPowerEnabled then
            UpdateMovement()
        end
        if State.FlyEnabled then
            UpdateFly()
        end
        if State.NoclipEnabled then
            UpdateNoclip()
        end
        if State.InfiniteJumpEnabled then
            UpdateInfiniteJump()
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 and State.AimbotEnabled then
        State.AimbotLocking = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and State.WallbangEnabled then
        State.Wallbang360FOV = true
        State.OriginalCameraCFrame = camera.CFrame
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
            State.OriginalPlayerCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        end
        SafeExecute(HandleWallbangTeleport)
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        State.AimbotLocking = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and State.WallbangEnabled then
        State.Wallbang360FOV = false
        State.OriginalCameraCFrame = nil
        if State.OriginalPlayerCFrame and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
            LocalPlayer.Character.HumanoidRootPart.CFrame = State.OriginalPlayerCFrame
            State.OriginalPlayerCFrame = nil
        end
        State.WallbangedPlayer = nil
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.AutoRotate = true
        end
    end
end)

-- GUI Элементы для Settings Tab
Tabs.Settings:CreateSection("Configuration")

local UnloadButton = Tabs.Settings:CreateButton({
    Title = "Unload Script",
    Description = "Completely unload the cheat",
    Callback = function()
        Library:Unload()
    end
})

Tabs.Settings:CreateSection("Menu Settings")

local MenuKeybind = Tabs.Settings:CreateKeybind("MenuKeybind", {
    Title = "Menu Keybind",
    Mode = "Toggle",
    Default = "RightControl",
    Callback = function(Value)
        -- Keybind callback
    end,
    ChangedCallback = function(New)
        -- Keybind changed callback
    end
})

-- Уведомление о загрузке
Library:Notify{
    Title = "Rivals X",
    Content = "Cheat successfully loaded!",
    Duration = 5
}

-- Подключение менеджеров
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
InterfaceManager:SetFolder("RivalsX")
SaveManager:SetFolder("RivalsX")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()

-- Основной цикл обновления
local function SafeExecute(func)
    local success, errorMessage = pcall(func)
    if not success then
        warn("Error in SafeExecute: " .. tostring(errorMessage))
    end
end

RunService.RenderStepped:Connect(function()

local function SafeExecute(func)
    local success, errorMessage = pcall(func)
    if not success then
        warn("Error in SafeExecute: " .. tostring(errorMessage))
    end
end

RunService.RenderStepped:Connect(function()
    SafeExecute(UpdateFOVCircle)
    SafeExecute(UpdateNoclip)
    SafeExecute(UpdateESP)
    SafeExecute(UpdateSkeletonESP)
    SafeExecute(UpdateHealthESP)
    SafeExecute(UpdateTracerESP)
    SafeExecute(UpdateChams)
    SafeExecute(UpdateAimbot)
    SafeExecute(UpdateTriggerbot)
    SafeExecute(UpdateCameraFreeze)
    SafeExecute(HandleWallbangTeleport)
    SafeExecute(UpdateRagebot)
    SafeExecute(UpdateMovement)
end)
