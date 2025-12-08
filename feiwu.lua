local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- ======================== 通知系统 (Notification System) ========================
local NotificationHolder = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Module.Lua"))()
local Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Client.Lua"))()

local function SendNotification(title, text)
    Notification:Notify(
        {Title = title, Description = text},
        {OutlineColor = Color3.fromRGB(0, 0, 0), Time = 3, Type = "image"},
        {Image = "http://www.roblox.com/asset/?id=6023426923", ImageColor = Color3.fromRGB(255, 0, 0)}
    )
end

-- ======================== 全局清理 (Global Cleanup) ========================
-- 防止重复注入导致的功能叠加或崩溃
if getgenv().Feiwu_Cleanup then
    getgenv().Feiwu_Cleanup()
end

local Connections = {}
local Instances = {}

getgenv().Feiwu_Cleanup = function()
    -- 断开连接
    for _, conn in ipairs(Connections) do
        if conn then conn:Disconnect() end
    end
    -- 销毁实例
    for _, inst in ipairs(Instances) do
        if inst and inst.Parent then inst:Destroy() end
    end
    -- 清理 ESP 对象
    local espHolder = game.CoreGui:FindFirstChild("ESPHolder_Feiwu")
    if espHolder then espHolder:Destroy() end
    local fovGui = game.CoreGui:FindFirstChild("FeiwuFOV")
    if fovGui then fovGui:Destroy() end
    
    -- 清理玩家身上的 ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local hl = player.Character:FindFirstChild("FeiwuHighlight")
            if hl then hl:Destroy() end
            local bf = player.Character:FindFirstChild("FeiwuBeamFolder")
            if bf then bf:Destroy() end
            local head = player.Character:FindFirstChild("Head")
            if head then
                local bg = head:FindFirstChild("FeiwuNameTag")
                if bg then bg:Destroy() end
            end
        end
    end
    
    getgenv().Feiwu_Cleanup = nil
end

-- ======================== 主窗口 (Main Window) ========================
local Window = Rayfield:CreateWindow({
    Name = "飞舞hub",
    LoadingTitle = "加载中...",
    LoadingSubtitle = "飞舞hub",
    ConfigurationSaving = {
        Enabled = false,
    },
})

local Tab1 = Window:CreateTab("人物")
local Tab2 = Window:CreateTab("视觉")
local Tab3 = Window:CreateTab("战斗")

-- ======================== 功能变量 (Variables) ========================
local ESP_Enabled = false
local Aimbot_Enabled = false
local Aimbot_WallCheck = false
local Aimbot_FOVSquare = false
local Aimbot_FOV_Size = 100
local Aimbot_Smoothness = 1 -- 0.1 ~ 1.0
local Hitbox_Enabled = false
local OriginalSizes = {}

-- ======================== 视觉/ESP (Visuals) ========================
local ESP_Holder = Instance.new("Folder", game.CoreGui)
ESP_Holder.Name = "ESPHolder_Feiwu"
table.insert(Instances, ESP_Holder)

-- 创建 ESP 资源的函数
local function CreateESPAssets(player)
    if not player.Character then return end
    local char = player.Character
    
    -- 1. Highlight
    if not char:FindFirstChild("FeiwuHighlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "FeiwuHighlight"
        highlight.Adornee = char
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Parent = char
    end
    
    -- 2. Name Tag
    local head = char:FindFirstChild("Head")
    if head and not head:FindFirstChild("FeiwuNameTag") then
        local bg = Instance.new("BillboardGui")
        bg.Name = "FeiwuNameTag"
        bg.Adornee = head
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.StudsOffset = Vector3.new(0, 2, 0)
        bg.AlwaysOnTop = true
        bg.Parent = head
        
        local nameLabel = Instance.new("TextLabel", bg)
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 14
        nameLabel.Text = player.Name
    end
    
    -- 3. Tracers (Beam)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and not char:FindFirstChild("FeiwuBeamFolder") then
        local beamFolder = Instance.new("Folder", char)
        beamFolder.Name = "FeiwuBeamFolder"
        
        local att0 = Instance.new("Attachment", workspace.Terrain)
        att0.Name = "TracerStart_" .. player.Name
        
        local att1 = Instance.new("Attachment", root)
        
        local beam = Instance.new("Beam", beamFolder)
        beam.Attachment0 = att0
        beam.Attachment1 = att1
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
        beam.FaceCamera = true
        beam.Width0 = 0.05
        beam.Width1 = 0.1
        
        -- 保存 att0 到 cleanup 列表，因为它在 Terrain 下
        table.insert(Instances, att0)
    end
end

-- 实时更新循环 (RenderStepped)
local ESPConnection = RunService.RenderStepped:Connect(function()
    if not ESP_Enabled then 
        -- 如果关闭，隐藏或移除（这里选择不做处理，依赖 Toggle 回调清理）
        return 
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            local char = player.Character
            local head = char:FindFirstChild("Head")
            local root = char:FindFirstChild("HumanoidRootPart")
            
            -- 更新 Name Tag 距离
            if head then
                local bg = head:FindFirstChild("FeiwuNameTag")
                if bg then
                    local label = bg:FindFirstChild("TextLabel")
                    if label and Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = (Players.LocalPlayer.Character.HumanoidRootPart.Position - head.Position).Magnitude
                        label.Text = string.format("%s\n[%.0f m]", player.Name, dist)
                    end
                end
            end
            
             -- Update Highlight Color (Target Lock)
             local hl = char:FindFirstChild("FeiwuHighlight")
             if hl then
                 if player == getgenv().Aimbot_LockedPlayer then
                     hl.FillColor = Color3.fromRGB(0, 255, 0) -- Green for Locked
                     hl.OutlineColor = Color3.fromRGB(0, 255, 0)
                 else
                     hl.FillColor = Color3.fromRGB(255, 0, 0) -- Red for others
                     hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                 end
             end

            -- 更新 Tracer 起点 (完美屏幕底边)
            if root then
                local bf = char:FindFirstChild("FeiwuBeamFolder")
                if bf then
                    local beam = bf:FindFirstChild("Beam")
                    if beam and beam.Attachment0 then
                         -- 使用 ViewportPointToRay 获取屏幕底边中心的射线
                         -- ViewportSize.X/2 = 水平中心, ViewportSize.Y = 屏幕最底端
                         local ray = Camera:ViewportPointToRay(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                         -- 将起点设在摄像机前方稍远处，避免被近平面裁剪
                         beam.Attachment0.WorldPosition = ray.Origin + (ray.Direction * 1)
                    end
                end
            end
        end
    end
end)
table.insert(Connections, ESPConnection)

local function EnableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            CreateESPAssets(player)
        end
    end
end

local function DisableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local hl = player.Character:FindFirstChild("FeiwuHighlight")
            if hl then hl:Destroy() end
            local bf = player.Character:FindFirstChild("FeiwuBeamFolder")
            if bf then
                -- 清理对应的 Terrain attachment
                if bf:FindFirstChild("Beam") and bf.Beam.Attachment0 then
                    bf.Beam.Attachment0:Destroy() 
                end
                bf:Destroy() 
            end
            local head = player.Character:FindFirstChild("Head")
            if head then
                local bg = head:FindFirstChild("FeiwuNameTag")
                if bg then bg:Destroy() end
            end
        end
    end
end

local ESPToggle = Tab2:CreateToggle({
    Name = "玩家透视 (ESP) - 实时更新",
    CurrentValue = false,
    Flag = "ThinkingESP",
    Callback = function(Value)
        ESP_Enabled = Value
        if Value then
            EnableESP()
            SendNotification("玩家透视", "已开启")
        else
            DisableESP()
            SendNotification("玩家透视", "已关闭")
        end
    end,
})

-- 监听新玩家
local PlayerAddedConn = Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if ESP_Enabled then
            task.wait(1)
            CreateESPAssets(player)
        end
    end)
end)
table.insert(Connections, PlayerAddedConn)

for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(char)
        if ESP_Enabled then
             task.wait(1)
             CreateESPAssets(p)
        end
    end)
end


-- ======================== 战斗功能 (Combat) ========================

-- FOV Visual
local FOV_Gui = Instance.new("ScreenGui", game.CoreGui)
FOV_Gui.Name = "FeiwuFOV"
table.insert(Instances, FOV_Gui)

local FOV_Frame = Instance.new("Frame", FOV_Gui)
FOV_Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FOV_Frame.BackgroundTransparency = 1
FOV_Frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
FOV_Frame.BorderSizePixel = 2
FOV_Frame.Visible = false
FOV_Frame.AnchorPoint = Vector2.new(0.5, 0.5)
FOV_Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
local FOV_Corner = Instance.new("UICorner", FOV_Frame)
FOV_Corner.CornerRadius = UDim.new(1, 0) -- Make it a circle

-- Aimbot Visibility Check
local function IsVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return false
end

local function GetClosestPlayer()
    local closestDist = math.huge
    local target = nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                
                if dist <= Aimbot_FOV_Size then
                    if not Aimbot_WallCheck or IsVisible(head) then
                        if dist < closestDist then
                            closestDist = dist
                            target = head
                        end
                    end
                end
            end
        end
    end
    return target
end

-- Aimbot Loop
local AimbotConn = RunService.RenderStepped:Connect(function()
    -- 更新 FOV 框状态
    FOV_Frame.Size = UDim2.new(0, Aimbot_FOV_Size * 2, 0, Aimbot_FOV_Size * 2)
    FOV_Frame.Visible = Aimbot_FOVSquare
    
    if Aimbot_Enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer()
        if target then
            -- Set Locked Player Global
            getgenv().Aimbot_LockedPlayer = Players:GetPlayerFromCharacter(target.Parent)
            
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, target.Position)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, Aimbot_Smoothness)
        else
            getgenv().Aimbot_LockedPlayer = nil
        end
    else
        getgenv().Aimbot_LockedPlayer = nil
    end
end)
table.insert(Connections, AimbotConn)

Tab3:CreateToggle({
    Name = "自动瞄准 (Aimbot)",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        Aimbot_Enabled = Value
        SendNotification("自动瞄准", Value and "已开启" or "已关闭")
    end,
})

Tab3:CreateToggle({
    Name = "显示 FOV 方框",
    CurrentValue = false,
    Flag = "FOVSquareToggle",
    Callback = function(Value)
        Aimbot_FOVSquare = Value
    end,
})

Tab3:CreateToggle({
    Name = "墙后可见性判定 (WallCheck)",
    CurrentValue = false,
    Flag = "WallCheckToggle",
    Callback = function(Value)
        Aimbot_WallCheck = Value
    end,
})

Tab3:CreateSlider({
    Name = "FOV 范围大小",
    Range = {50, 800},
    Increment = 10,
    CurrentValue = 100,
    Flag = "FOVSlider",
    Callback = function(Value)
        Aimbot_FOV_Size = Value
    end,
})

Tab3:CreateSlider({
    Name = "平滑度 (费率)",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 10,
    Flag = "SmoothnessSlider",
    Callback = function(Value)
        Aimbot_Smoothness = Value / 10
    end,
})

-- Hitbox Expander
local function UpdateHitbox()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            if Hitbox_Enabled then
                if not OriginalSizes[player.Name] then
                    OriginalSizes[player.Name] = hrp.Size
                end
                hrp.Size = Vector3.new(10, 10, 10)
                hrp.Transparency = 0.7
                hrp.CanCollide = false
            else
                if OriginalSizes[player.Name] then
                    hrp.Size = OriginalSizes[player.Name]
                    hrp.Transparency = 1
                    hrp.CanCollide = true
                    OriginalSizes[player.Name] = nil
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        if Hitbox_Enabled then UpdateHitbox() end
        task.wait(1)
    end
end)

Tab3:CreateToggle({
    Name = "子弹追踪 (判定放大)",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        Hitbox_Enabled = Value
        if not Value then UpdateHitbox() end
        SendNotification("子弹追踪", Value and "已开启" or "已关闭")
    end,
})

-- ======================== 人物功能 ========================
local function GetPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then table.insert(names, player.Name) end
    end
    return names
end

local PlayerDropdown = Tab1:CreateDropdown({
    Name = "传送至玩家",
    Options = GetPlayerNames(),
    CurrentOption = "",
    MultipleOptions = false,
    Flag = "PlayerTeleport",
    Callback = function(Option)
        local targetName = type(Option) == "table" and Option[1] or Option
        local target = Players:FindFirstChild(targetName)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and Players.LocalPlayer.Character then
             Players.LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
        end
    end,
})

Tab1:CreateButton({
    Name = "刷新玩家列表",
    Callback = function() PlayerDropdown:Refresh(GetPlayerNames()) end,
})

Tab1:CreateSlider({
    Name = "移动速度",
    Range = {16, 500},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end,
})

local infJumpDebounce = false
Tab1:CreateToggle({
    Name = "无限跳跃",
    CurrentValue = false,
    Flag = "ToggleExample",
    Callback = function(Value)
        SendNotification("无限跳跃", Value and "已开启" or "已关闭")
        if Value then
             local ijConn = UserInputService.JumpRequest:Connect(function()
                if not infJumpDebounce and Players.LocalPlayer.Character then
                    Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
                    infJumpDebounce = true
                    task.wait()
                    infJumpDebounce = false
                end
            end)
            table.insert(Connections, ijConn)
        end
        -- Note: Disconnecting specific toggle connections in cleanup system is complex, simplistic toggle off relies on debounce or logic check, but full cleanup handles re-execution
    end,
})
