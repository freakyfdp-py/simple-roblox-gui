local mod = {}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isVisible = true
local toggleKey = Enum.KeyCode.RightShift
local accentColor = Color3.fromRGB(110, 40, 180) 
local isDarkMode = true

-- Helper: Draggable logic
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

function mod.init(title)
    local sg = Instance.new("ScreenGui", playerGui)
    sg.Name = title
    sg.ResetOnSpawn = false
    
    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 500, 0, 350)
    main.Position = UDim2.new(0.5, -250, 0.5, -175)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    main.BorderSizePixel = 0
    makeDraggable(main)
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    
    -- Theme Panel (Slides from left)
    local themePanel = Instance.new("Frame", main)
    themePanel.Size = UDim2.new(0, 0, 1, -20)
    themePanel.Position = UDim2.new(0, 5, 0, 10)
    themePanel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    themePanel.BorderSizePixel = 0
    themePanel.ClipsDescendants = true
    themePanel.ZIndex = 5
    Instance.new("UICorner", themePanel)
    
    local themeLayout = Instance.new("UIListLayout", themePanel)
    themeLayout.Padding = UDim.new(0, 10)
    themeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    -- Theme Toggle (+) Button
    local themeBtn = Instance.new("TextButton", main)
    themeBtn.Size = UDim2.new(0, 25, 0, 25)
    themeBtn.Position = UDim2.new(0, 10, 0, 8)
    themeBtn.BackgroundColor3 = accentColor
    themeBtn.Text = "+"
    themeBtn.TextColor3 = Color3.new(1,1,1)
    themeBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", themeBtn).CornerRadius = UDim.new(1, 0)

    -- Sidebar and Content Area
    local sidebar = Instance.new("Frame", main)
    sidebar.Size = UDim2.new(0, 130, 1, -50)
    sidebar.Position = UDim2.new(0, 10, 0, 45)
    sidebar.BackgroundTransparency = 1
    Instance.new("UIListLayout", sidebar).Padding = UDim.new(0, 6)
    
    local container = Instance.new("Frame", main)
    container.Size = UDim2.new(1, -160, 1, -50)
    container.Position = UDim2.new(0, 150, 0, 45)
    container.BackgroundTransparency = 1

    local uiState = {main = main, sidebar = sidebar, container = container, sg = sg}

    -- Animation for Theme Panel
    local themeOpen = false
    themeBtn.MouseButton1Click:Connect(function()
        themeOpen = not themeOpen
        local targetSize = themeOpen and UDim2.new(0, 140, 1, -20) or UDim2.new(0, 0, 1, -20)
        TweenService:Create(themePanel, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Size = targetSize}):Play()
        themeBtn.Text = themeOpen and "-" or "+"
    end)

    -- Theme Panel Content
    mod.addSection(themePanel, "Theme Config")
    mod.addButton(themePanel, "Dark/Light Mode", function()
        isDarkMode = not isDarkMode
        local bgColor = isDarkMode and Color3.fromRGB(20, 20, 25) or Color3.fromRGB(240, 240, 245)
        local pColor = isDarkMode and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(220, 220, 225)
        main.BackgroundColor3 = bgColor
        themePanel.BackgroundColor3 = pColor
    end)
    
    local presets = {Color3.fromRGB(110, 40, 180), Color3.fromRGB(255, 60, 60), Color3.fromRGB(60, 180, 255), Color3.fromRGB(60, 255, 120)}
    for _, color in pairs(presets) do
        local cBtn = Instance.new("TextButton", themePanel)
        cBtn.Size = UDim2.new(0, 30, 0, 30)
        cBtn.BackgroundColor3 = color
        cBtn.Text = ""
        Instance.new("UICorner", cBtn).CornerRadius = UDim.new(1, 0)
        cBtn.MouseButton1Click:Connect(function()
            accentColor = color
            themeBtn.BackgroundColor3 = color
            -- Update existing UI elements here if needed
        end)
    end

    -- Settings Tab
    local settings = mod.addTab(uiState, "Settings")
    mod.addButton(settings, "Destroy Menu", function() sg:Destroy() end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then
            isVisible = not isVisible
            main.Visible = isVisible
        end
    end)

    return uiState
end

-- Function definitions for Tab, Section, Slider, etc.
function mod.addTab(ui, name)
    local tabBtn = Instance.new("TextButton", ui.sidebar)
    tabBtn.Size = UDim2.new(1, 0, 0, 32)
    tabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.new(1,1,1)
    tabBtn.Font = Enum.Font.Gotham
    Instance.new("UICorner", tabBtn)
    
    local page = Instance.new("ScrollingFrame", ui.container)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = (name == "Settings")
    page.ScrollBarThickness = 0
    Instance.new("UIListLayout", page).Padding = UDim.new(0, 10)
    
    tabBtn.MouseButton1Click:Connect(function()
        for _, v in pairs(ui.container:GetChildren()) do
            if v:IsA("ScrollingFrame") then v.Visible = false end
        end
        page.Visible = true
    end)
    return page
end

function mod.addSection(parent, text)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Text = "  " .. text:upper()
    label.TextColor3 = Color3.fromRGB(150, 150, 160)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
end

function mod.addButton(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

function mod.addSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Instance.new("UICorner", frame)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.new(1,1,1)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    
    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(0.9, 0, 0, 4)
    bar.Position = UDim2.new(0.05, 0, 0.7, 0)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = accentColor
    fill.BorderSizePixel = 0
    
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection = UserInputService.InputChanged:Connect(function(m)
                if m.UserInputType == Enum.UserInputType.MouseMovement then
                    local percent = math.clamp((m.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    local val = math.floor(min + (max - min) * percent)
                    label.Text = text .. ": " .. val
                    callback(val)
                end
            end)
            UserInputService.InputEnded:Connect(function(e)
                if e.UserInputType == Enum.UserInputType.MouseButton1 then connection:Disconnect() end
            end)
        end
    end)
end

function mod.addInput(parent, placeholder, callback)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(1, -10, 0, 35)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    box.PlaceholderText = placeholder
    box.Text = ""
    box.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", box)
    box.FocusLost:Connect(function(enter) if enter then callback(box.Text) end end)
end

function mod.addDropdown(parent, text, options, callback)
    local expanded = false
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame.ClipsDescendants = true
    Instance.new("UICorner", frame)
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. text .. " ▼"
    btn.TextColor3 = Color3.new(1,1,1)
    
    btn.MouseButton1Click:Connect(function()
        expanded = not expanded
        frame.Size = expanded and UDim2.new(1, -10, 0, (#options * 30) + 40) or UDim2.new(1, -10, 0, 35)
    end)
    
    for i, optName in pairs(options) do
        local opt = Instance.new("TextButton", frame)
        opt.Size = UDim2.new(1, 0, 0, 30)
        opt.Position = UDim2.new(0, 0, 0, (i * 30) + 5)
        opt.BackgroundTransparency = 1
        opt.Text = optName
        opt.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        opt.MouseButton1Click:Connect(function()
            btn.Text = "  " .. text .. ": " .. optName
            callback(optName)
            expanded = false
            frame.Size = UDim2.new(1, -10, 0, 35)
        end)
    end
end

return mod
