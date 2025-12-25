local mod = {}

local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isVisible = true
local toggleKey = Enum.KeyCode.RightShift
local accentColor = Color3.fromRGB(110, 40, 180) 

local function makeDraggable(frame)
    local dragging, dragStart, startPos
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
    
    local sidebar = Instance.new("Frame", main)
    sidebar.Size = UDim2.new(0, 130, 1, -50)
    sidebar.Position = UDim2.new(0, 10, 0, 45)
    sidebar.BackgroundTransparency = 1
    Instance.new("UIListLayout", sidebar).Padding = UDim.new(0, 6)
    
    local container = Instance.new("Frame", main)
    container.Size = UDim2.new(1, -160, 1, -50)
    container.Position = UDim2.new(0, 150, 0, 45)
    container.BackgroundTransparency = 1

    local menu = {sidebar = sidebar, container = container}

    function menu:addTab(name)
        local tabBtn = Instance.new("TextButton", self.sidebar)
        tabBtn.Size = UDim2.new(1, 0, 0, 32)
        tabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        tabBtn.Text = name
        tabBtn.TextColor3 = Color3.new(1,1,1)
        tabBtn.Font = Enum.Font.Gotham
        Instance.new("UICorner", tabBtn)
        
        local page = Instance.new("ScrollingFrame", self.container)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.ScrollBarThickness = 0
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.CanvasSize = UDim2.new(0,0,0,0)
        local layout = Instance.new("UIListLayout", page)
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        tabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(self.container:GetChildren()) do
                if v:IsA("ScrollingFrame") then v.Visible = false end
            end
            page.Visible = true
        end)

        -- Proxy table to hold custom methods
        local tabObj = {}

        function tabObj:addSection(text)
            local label = Instance.new("TextLabel", page)
            label.Size = UDim2.new(1, -10, 0, 25)
            label.Text = "  " .. text:upper()
            label.TextColor3 = Color3.fromRGB(150, 150, 160)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 10
            label.BackgroundTransparency = 1
            label.TextXAlignment = Enum.TextXAlignment.Left
        end

        function tabObj:addButton(text, callback)
            local btn = Instance.new("TextButton", page)
            btn.Size = UDim2.new(1, -10, 0, 35)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.Text = text
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.Gotham
            Instance.new("UICorner", btn)
            btn.MouseButton1Click:Connect(callback)
        end

        function tabObj:addSlider(text, min, max, default, callback)
            local frame = Instance.new("Frame", page)
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
                    local connection
                    connection = UserInputService.InputChanged:Connect(function(m)
                        if m.UserInputType == Enum.UserInputType.MouseMovement then
                            local percent = math.clamp((m.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                            fill.Size = UDim2.new(percent, 0, 1, 0)
                            local val = math.floor(min + (max - min) * percent)
                            label.Text = text .. ": " .. val
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
            box.Size = UDim2.new(1, -10, 0, 35)
            box.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            box.PlaceholderText = placeholder
            box.Text = ""
            box.TextColor3 = Color3.new(1,1,1)
            box.Font = Enum.Font.Gotham
            Instance.new("UICorner", box)
            box.FocusLost:Connect(function(enter) if enter then callback(box.Text) end end)
        end

        function tabObj:addDropdown(text, options, callback)
            local expanded = false
            local frame = Instance.new("Frame", page)
            frame.Size = UDim2.new(1, -10, 0, 35)
            frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            frame.ClipsDescendants = true
            Instance.new("UICorner", frame)
            
            local btn = Instance.new("TextButton", frame)
            btn.Size = UDim2.new(1, 0, 0, 35)
            btn.BackgroundTransparency = 1
            btn.Text = "  " .. text .. " ▼"
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.Gotham
            
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
                opt.Font = Enum.Font.Gotham
                opt.MouseButton1Click:Connect(function()
                    btn.Text = "  " .. text .. ": " .. optName
                    callback(optName)
                    expanded = false
                    frame.Size = UDim2.new(1, -10, 0, 35)
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
