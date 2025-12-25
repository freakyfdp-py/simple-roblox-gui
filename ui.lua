local mod = {}

local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isVisible = true
local toggleKey = Enum.KeyCode.RightShift
local accentColor = Color3.fromRGB(110, 40, 180)
local configFileName = "ShadowHub_Settings.json"

-- Table to store current settings for saving
local settingsTable = {}

-- Save settings to the executor's workspace folder
local function saveSettings()
    if writefile then
        writefile(configFileName, HttpService:JSONEncode(settingsTable))
    end
end

-- Load settings from the executor's workspace folder
local function loadSettings()
    if isfile and isfile(configFileName) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(configFileName))
        end)
        if success then 
            settingsTable = data 
            return data
        end
    end
    return {}
end

-- Dragging logic focused on the Title Bar
local function makeDraggable(frame, dragHandle)
    local dragging, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
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

function mod.init(titleText)
    loadSettings()
    
    local sg = Instance.new("ScreenGui", playerGui)
    sg.Name = titleText
    sg.ResetOnSpawn = false
    
    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 550, 0, 400) -- Increased size
    main.Position = UDim2.new(0.5, -275, 0.5, -200)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    main.BorderSizePixel = 0
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    -- Improved Title Bar
    local titleBar = Instance.new("Frame", main)
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundTransparency = 1
    makeDraggable(main, titleBar)

    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Size = UDim2.new(1, -20, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.Text = titleText
    titleLabel.TextColor3 = Color3.new(1,1,1)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    
    local sidebar = Instance.new("Frame", main)
    sidebar.Size = UDim2.new(0, 150, 1, -70)
    sidebar.Position = UDim2.new(0, 10, 0, 55)
    sidebar.BackgroundTransparency = 1
    local sList = Instance.new("UIListLayout", sidebar)
    sList.Padding = UDim.new(0, 8)
    
    local container = Instance.new("Frame", main)
    container.Size = UDim2.new(1, -180, 1, -70)
    container.Position = UDim2.new(0, 170, 0, 55)
    container.BackgroundTransparency = 1

    local menu = {sidebar = sidebar, container = container}

    function menu:addTab(name)
        local tabBtn = Instance.new("TextButton", self.sidebar)
        tabBtn.Size = UDim2.new(1, 0, 0, 40)
        tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        tabBtn.Text = name
        tabBtn.TextColor3 = Color3.new(1,1,1)
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.TextSize = 16
        Instance.new("UICorner", tabBtn)
        
        local page = Instance.new("ScrollingFrame", self.container)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.ScrollBarThickness = 2
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.CanvasSize = UDim2.new(0,0,0,0)
        local layout = Instance.new("UIListLayout", page)
        layout.Padding = UDim.new(0, 12)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        tabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(self.container:GetChildren()) do
                if v:IsA("ScrollingFrame") then v.Visible = false end
            end
            page.Visible = true
        end)

        local tabObj = {}

        function tabObj:addSection(text)
            local label = Instance.new("TextLabel", page)
            label.Size = UDim2.new(1, -10, 0, 30)
            label.Text = "  " .. text:upper()
            label.TextColor3 = Color3.fromRGB(160, 160, 170)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
        end

        function tabObj:addButton(text, callback)
            local btn = Instance.new("TextButton", page)
            btn.Size = UDim2.new(1, -10, 0, 42)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            btn.Text = text
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 15
            Instance.new("UICorner", btn)
            btn.MouseButton1Click:Connect(callback)
        end

        function tabObj:addSlider(text, min, max, default, callback)
            -- CONFIG AUTO-LOAD
            local savedVal = settingsTable[text] or default
            
            local frame = Instance.new("Frame", page)
            frame.Size = UDim2.new(1, -10, 0, 60)
            frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            Instance.new("UICorner", frame)
            
            local label = Instance.new("TextLabel", frame)
            label.Size = UDim2.new(1, -10, 0, 25)
            label.Position = UDim2.new(0, 10, 0, 8)
            label.Text = text .. ": " .. savedVal
            label.TextColor3 = Color3.new(1,1,1)
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Font = Enum.Font.GothamMedium
            label.TextSize = 15
            
            local bar = Instance.new("Frame", frame)
            bar.Size = UDim2.new(0.9, 0, 0, 6)
            bar.Position = UDim2.new(0.05, 0, 0.75, 0)
            bar.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            Instance.new("UICorner", bar)
            
            local fill = Instance.new("Frame", bar)
            fill.Size = UDim2.new((savedVal - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = accentColor
            fill.BorderSizePixel = 0
            Instance.new("UICorner", fill)
            
            -- Trigger initial callback
            task.spawn(function() callback(savedVal) end)

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local connection
                    connection = UserInputService.InputChanged:Connect(function(m)
                        if m.UserInputType == Enum.UserInputType.MouseMovement then
                            local percent = math.clamp((m.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                            fill.Size = UDim2.new(percent, 0, 1, 0)
                            local val = math.floor(min + (max - min) * percent)
                            label.Text = text .. ": " .. val
                            
                            -- CONFIG AUTO-SAVE
                            settingsTable[text] = val
                            saveSettings()
                            callback(val)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(e)
                        if e.UserInputType == Enum.UserInputType.MouseButton1 and connection then 
                            connection:Disconnect() 
                        end
                    end)
                end
            end)
        end

        function tabObj:addInput(placeholder, callback)
            local box = Instance.new("TextBox", page)
            box.Size = UDim2.new(1, -10, 0, 42)
            box.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            box.PlaceholderText = placeholder
            box.Text = ""
            box.TextColor3 = Color3.new(1,1,1)
            box.Font = Enum.Font.GothamMedium
            box.TextSize = 15
            Instance.new("UICorner", box)
            box.FocusLost:Connect(function(enter) if enter then callback(box.Text) end end)
        end

        function tabObj:addDropdown(text, options, callback)
            local expanded = false
            local frame = Instance.new("Frame", page)
            frame.Size = UDim2.new(1, -10, 0, 42)
            frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            frame.ClipsDescendants = true
            Instance.new("UICorner", frame)
            
            local btn = Instance.new("TextButton", frame)
            btn.Size = UDim2.new(1, 0, 0, 42)
            btn.BackgroundTransparency = 1
            btn.Text = "  " .. text .. " ▼"
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 15
            btn.TextXAlignment = Enum.TextXAlignment.Left
            
            btn.MouseButton1Click:Connect(function()
                expanded = not expanded
                frame.Size = expanded and UDim2.new(1, -10, 0, (#options * 35) + 50) or UDim2.new(1, -10, 0, 42)
            end)
            
            for i, optName in pairs(options) do
                local opt = Instance.new("TextButton", frame)
                opt.Size = UDim2.new(1, 0, 0, 35)
                opt.Position = UDim2.new(0, 0, 0, (i * 35) + 10)
                opt.BackgroundTransparency = 1
                opt.Text = optName
                opt.TextColor3 = Color3.new(0.8, 0.8, 0.8)
                opt.Font = Enum.Font.Gotham
                opt.TextSize = 14
                opt.MouseButton1Click:Connect(function()
                    btn.Text = "  " .. text .. ": " .. optName
                    callback(optName)
                    expanded = false
                    frame.Size = UDim2.new(1, -10, 0, 42)
                end)
            end
        end

        return tabObj
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then
            isVisible = not isVisible
            main.Visible = isVisible
        end
    end)

    return menu
end

return mod
