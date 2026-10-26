-- Prison Life Script (Mobile Fixed)
-- Parent ke PlayerGui biar pasti muncul

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

print("[PrisonLife] Mulai load...")

-- Settings
local Settings = {
    Aimbot = false,
    SilentAim = false,      -- default off dulu biar lebih aman
    AutoShoot = false,
    Noclip = false,
    Speed = false,
    Jump = false,
    Invisible = false,
    ESP = true,
    Fly = false,
    GodMode = false,

    WalkSpeed = 55,
    JumpPower = 90,
    AimbotFOV = 180,
    AimbotSmooth = 0.2,
    TeamCheck = true,
    FlySpeed = 55,
}

local Holding = false
local Target = nil
local BodyVelocity, BodyGyro = nil, nil
local Flying = false
local OriginalTransparency = {}
local OriginalCanCollide = {}
local ESPObjects = {}
local FlyHoldingUp, FlyHoldingDown = false, false

-- ==================== GUI (PlayerGui) ====================
local function CreateGUI()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    -- Hapus lama
    if pg:FindFirstChild("PrisonLifeMobile") then
        pg.PrisonLifeMobile:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PrisonLifeMobile"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = pg

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 185, 0, 410)
    Main.Position = UDim2.new(0, 12, 0.5, -205)
    Main.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Title.Text = "Prison Life Mobile"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.Parent = Main
    Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

    local function MakeToggle(name, key, y)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 26)
        btn.Position = UDim2.new(0.05, 0, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.Text = name .. (Settings[key] and ": ON" or ": OFF")
        btn.TextColor3 = Settings[key] and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Parent = Main
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            Settings[key] = not Settings[key]
            btn.Text = name .. (Settings[key] and ": ON" or ": OFF")
            btn.TextColor3 = Settings[key] and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
        end)
    end

    MakeToggle("Aimbot", "Aimbot", 38)
    MakeToggle("Silent Aim", "SilentAim", 68)
    MakeToggle("Auto Shoot", "AutoShoot", 98)
    MakeToggle("Noclip", "Noclip", 128)
    MakeToggle("Speed", "Speed", 158)
    MakeToggle("Jump Tinggi", "Jump", 188)
    MakeToggle("Invisible", "Invisible", 218)
    MakeToggle("ESP", "ESP", 248)
    MakeToggle("Fly", "Fly", 278)
    MakeToggle("God Mode", "GodMode", 308)

    -- Tombol Fly
    local FlyUp = Instance.new("TextButton")
    FlyUp.Size = UDim2.new(0, 55, 0, 55)
    FlyUp.Position = UDim2.new(1, -70, 0.5, -65)
    FlyUp.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    FlyUp.Text = "↑"
    FlyUp.TextColor3 = Color3.fromRGB(255, 255, 255)
    FlyUp.Font = Enum.Font.GothamBold
    FlyUp.TextSize = 22
    FlyUp.Visible = false
    FlyUp.Parent = ScreenGui
    Instance.new("UICorner", FlyUp).CornerRadius = UDim.new(0, 12)

    local FlyDown = Instance.new("TextButton")
    FlyDown.Size = UDim2.new(0, 55, 0, 55)
    FlyDown.Position = UDim2.new(1, -70, 0.5, 5)
    FlyDown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    FlyDown.Text = "↓"
    FlyDown.TextColor3 = Color3.fromRGB(255, 255, 255)
    FlyDown.Font = Enum.Font.GothamBold
    FlyDown.TextSize = 22
    FlyDown.Visible = false
    FlyDown.Parent = ScreenGui
    Instance.new("UICorner", FlyDown).CornerRadius = UDim.new(0, 12)

    FlyUp.MouseButton1Down:Connect(function() FlyHoldingUp = true end)
    FlyUp.MouseButton1Up:Connect(function() FlyHoldingUp = false end)
    FlyDown.MouseButton1Down:Connect(function() FlyHoldingDown = true end)
    FlyDown.MouseButton1Up:Connect(function() FlyHoldingDown = false end)

    getgenv().FlyUpBtn = FlyUp
    getgenv().FlyDownBtn = FlyDown

    print("[PrisonLife] GUI berhasil dibuat di PlayerGui")
end

CreateGUI()

-- ==================== TARGET ====================
local function GetClosest()
    local closest, dist = nil, Settings.AimbotFOV
    for _, plr in pairs(Players:GetPlayers()) do
        if plr \~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if not (Settings.TeamCheck and plr.Team == LocalPlayer.Team) then
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local d = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                        if d < dist then
                            closest = plr
                            dist = d
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- ==================== ESP ====================
local function ClearESP(plr)
    if ESPObjects[plr] then
        for _, v in pairs(ESPObjects[plr]) do
            pcall(function() v:Destroy() end)
        end
        ESPObjects[plr] = nil
    end
end

local function CreateESP(plr)
    if plr == LocalPlayer then return end
    ClearESP(plr)

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 50, 50)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.6
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    local bill = Instance.new("BillboardGui")
    bill.Size = UDim2.new(0, 120, 0, 35)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.4
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Parent = bill

    ESPObjects[plr] = {hl = highlight, bill = bill, label = label}
end

RunService.RenderStepped:Connect(function()
    Target = GetClosest()

    -- ESP update
    if Settings.ESP then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr \~= LocalPlayer then
                if not ESPObjects[plr] then CreateESP(plr) end
                local data = ESPObjects[plr]
                if data and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.Humanoid.Health > 0 then
                    data.hl.Adornee = plr.Character
                    data.hl.Parent = plr.Character
                    data.bill.Adornee = plr.Character.HumanoidRootPart
                    data.bill.Parent = plr.Character.HumanoidRootPart
                    data.label.Text = plr.Name .. " | " .. math.floor(plr.Character.Humanoid.Health)
                    data.hl.FillColor = (Settings.TeamCheck and plr.Team == LocalPlayer.Team) and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
                else
                    if data then
                        data.hl.Adornee = nil
                        data.bill.Adornee = nil
                    end
                end
            end
        end
    else
        for _, data in pairs(ESPObjects) do
            if data.hl then data.hl.Adornee = nil end
            if data.bill then data.bill.Adornee = nil end
        end
    end

    -- Aimbot sederhana
    if Settings.Aimbot and Holding and Target and Target.Character and Target.Character:FindFirstChild("Head") then
        pcall(function()
            local pos = Camera:WorldToViewportPoint(Target.Character.Head.Position)
            mousemoverel((pos.X - Mouse.X) * Settings.AimbotSmooth, (pos.Y - Mouse.Y) * Settings.AimbotSmooth)
        end)
    end

    -- Fly
    if Settings.Fly then
        if not Flying then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                BodyVelocity = Instance.new("BodyVelocity")
                BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                BodyVelocity.Velocity = Vector3.zero
                BodyVelocity.Parent = root

                BodyGyro = Instance.new("BodyGyro")
                BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                BodyGyro.P = 3000
                BodyGyro.Parent = root

                char.Humanoid.PlatformStand = true
                Flying = true
                if getgenv().FlyUpBtn then getgenv().FlyUpBtn.Visible = true end
                if getgenv().FlyDownBtn then getgenv().FlyDownBtn.Visible = true end
            end
        end

        if BodyVelocity and BodyGyro and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local dir = Vector3.zero
            local cam = Camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
            if FlyHoldingUp or UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if FlyHoldingDown or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir + Vector3.new(0,-1,0) end

            BodyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * Settings.FlySpeed or Vector3.zero
            BodyGyro.CFrame = cam
        end
    else
        if Flying then
            if BodyVelocity then BodyVelocity:Destroy() end
            if BodyGyro then BodyGyro:Destroy() end
            BodyVelocity, BodyGyro = nil, nil
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.PlatformStand = false
            end
            Flying = false
            if getgenv().FlyUpBtn then getgenv().FlyUpBtn.Visible = false end
            if getgenv().FlyDownBtn then getgenv().FlyDownBtn.Visible = false end
        end
    end
end)

-- Character loop
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    local hum = char.Humanoid
    local root = char:FindFirstChild("HumanoidRootPart")

    hum.WalkSpeed = Settings.Speed and Settings.WalkSpeed or 16
    hum.JumpPower = Settings.Jump and Settings.JumpPower or 50

    if Settings.GodMode then
        hum.Health = hum.MaxHealth
    end

    -- Noclip
    if root then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if Settings.Noclip then
                    if OriginalCanCollide[part] == nil then OriginalCanCollide[part] = part.CanCollide end
                    part.CanCollide = false
                else
                    if OriginalCanCollide[part] \~= nil then
                        part.CanCollide = OriginalCanCollide[part]
                        OriginalCanCollide[part] = nil
                    end
                end
            end
        end
    end

    -- Invisible
    if Settings.Invisible then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then
                if OriginalTransparency[v] == nil then OriginalTransparency[v] = v.Transparency end
                v.Transparency = 1
            end
        end
    else
        for v, t in pairs(OriginalTransparency) do
            if v and v.Parent then v.Transparency = t end
        end
        OriginalTransparency = {}
    end
end)

-- Input
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
        Holding = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
        Holding = false
    end
end)

-- Auto Shoot
task.spawn(function()
    while true do
        task.wait(0.1)
        if Settings.AutoShoot and Holding and Target then
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
    end
end)

-- Silent Aim (opsional, bisa error di beberapa executor)
pcall(function()
    local mt = getrawmetatable(game)
    local old = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if Settings.SilentAim and Target and Target.Character and Target.Character:FindFirstChild("Head") then
            if self == Mouse then
                if key == "Hit" then return Target.Character.Head.CFrame end
                if key == "Target" then return Target.Character.Head end
            end
        end
        return old(self, key)
    end)
end)

-- Init
for _, plr in pairs(Players:GetPlayers()) do
    if plr \~= LocalPlayer then pcall(CreateESP, plr) end
end

Players.PlayerAdded:Connect(function(plr)
    task.wait(1)
    pcall(CreateESP, plr)
end)
Players.PlayerRemoving:Connect(ClearESP)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    OriginalTransparency = {}
    OriginalCanCollide = {}
end)

print("[PrisonLife] Script siap. Cek GUI di kiri layar.")
