-- TES GUI SAJA
print("=== TES MULAI ===")

local success, err = pcall(function()
    local player = game:GetService("Players").LocalPlayer
    local pg = player:WaitForChild("PlayerGui")

    -- Hapus yang lama
    if pg:FindFirstChild("TesGUI") then
        pg.TesGUI:Destroy()
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "TesGUI"
    screen.ResetOnSpawn = false
    screen.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 100)
    frame.Position = UDim2.new(0.5, -100, 0.5, -50)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Parent = screen

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "GUI BERHASIL MUNCUL"
    label.TextColor3 = Color3.fromRGB(0, 255, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame

    print("=== GUI BERHASIL DIBUAT ===")
end)

if not success then
    print("=== ERROR ===")
    print(err)
end
