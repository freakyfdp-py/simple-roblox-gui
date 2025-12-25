local mod = {}

local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isVisible = true
local toggleKey = Enum.KeyCode.RightShift
local accentColor = Color3.fromRGB(110, 40, 180)

local currentSettings = {}

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

function mod.init(titleText)
    local sg = Instance.new("ScreenGui", playerGui)
    sg.Name = titleText
    sg.ResetOnSpawn = false

    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 550, 0, 400)
    main.Position = UDim2.new(0.5, -275, 0.5, -200)
    main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    main.BorderSizePixel = 0
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    local titleBar = Instance.new("Frame", main)
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    titleBar.BorderSizePixel = 0
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

    makeDraggable(main, titleBar)

    local title = Instance.new("TextLabel", titleBar)
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.Text = titleText
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1

    local sidebar = Instance.new("Frame", main)
    sidebar.Size = UDim2.new(0, 150, 1, -70)
    sidebar.Position = UDim2.new(0, 10, 0, 55)
    sidebar.BackgroundTransparency = 1
    Instance.new("UIListLayout", sidebar).Padding = UDim.new(0, 8)

    local container = Instance.new("Frame", main)
    container.Size = UDim2.new(1, -180, 1, -70)
    container.Position = UDim2.new(0, 170, 0, 55)
    container.BackgroundTransparency = 1

    local menu = { sidebar = sidebar, container = container }

    function menu:addTab(name)
        local tabBtn = Instance.new("TextButton", self.sidebar)
        tabBtn.Size = UDim2.new(1, 0, 0, 40)
        tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        tabBtn.Text = name
        tabBtn.TextColor3 = Color3.new(1, 1, 1)
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.TextSize = 16
        Instance.new("UICorner", tabBtn)

        local page = Instance.new("ScrollingFrame", self.container)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.Visible = false
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 4
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.CanvasPosition = Vector2.new(0, 0)

        local layout = Instance.new("UIListLayout", page)
        layout.Padding = UDim.new(0, 12)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.VerticalAlignment = Enum.VerticalAlignment.Top

        tabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(self.container:GetChildren()) do
                if v:IsA("ScrollingFrame") then
                    v.Visible = false
                end
            end
            page.Visible = true
        end)

        local tab = {}
        local order = 0

        function tab:addSection(text)
            order += 1
            local label = Instance.new("TextLabel", page)
            label.Size = UDim2.new(1, -20, 0, 30)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.Text = text:upper()
            label.TextColor3 = Color3.fromRGB(160, 160, 170)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.BackgroundTransparency = 1
            label.LayoutOrder = order
        end

        function tab:addSlider(text, min, max, default, callback)
            order += 1

            local frame = Instance.new("Frame", page)
            frame.Size = UDim2.new(1, -20, 0, 72)
            frame.Position = UDim2.new(0, 10, 0, 0)
            frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            frame.LayoutOrder = order
            Instance.new("UICorner", frame)

            local label = Instance.new("TextLabel", frame)
            label.Size = UDim2.new(1, -20, 0, 24)
            label.Position = UDim2.new(0, 10, 0, 8)
            label.Text = text .. ": " .. default
            label.TextColor3 = Color3.new(1, 1, 1)
            label.Font = Enum.Font.GothamMedium
            label.TextSize = 15
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.BackgroundTransparency = 1

            local bar = Instance.new("Frame", frame)
            bar.Size = UDim2.new(1, -20, 0, 12)
            bar.Position = UDim2.new(0, 10, 0.65, 0)
            bar.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
            Instance.new("UICorner", bar)

            local fill = Instance.new("Frame", bar)
            fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = accentColor
            fill.BorderSizePixel = 0
            Instance.new("UICorner", fill)

            currentSettings[text] = default
            local dragging = false

            local function setFromX(x)
                local p = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local v = math.floor(min + (max - min) * p)
                fill.Size = UDim2.new(p, 0, 1, 0)
                label.Text = text .. ": " .. v
                currentSettings[text] = v
                callback(v)
            end

            bar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    setFromX(i.Position.X)
                end
            end)

            UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromX(i.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            function tab:updateSlider(target, val)
                if target == text then
                    local p = math.clamp((val - min) / (max - min), 0, 1)
                    fill.Size = UDim2.new(p, 0, 1, 0)
                    label.Text = text .. ": " .. val
                    currentSettings[text] = val
                    callback(val)
                end
            end
        end

        function tab:addButton(text, callback)
            order += 1
            local btn = Instance.new("TextButton", page)
            btn.Size = UDim2.new(1, -20, 0, 42)
            btn.Position = UDim2.new(0, 10, 0, 0)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            btn.Text = text
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 15
            btn.LayoutOrder = order
            Instance.new("UICorner", btn)
            btn.MouseButton1Click:Connect(callback)
        end

        function tab:addInput(placeholder, callback)
            order += 1
            local box = Instance.new("TextBox", page)
            box.Size = UDim2.new(1, -20, 0, 42)
            box.Position = UDim2.new(0, 10, 0, 0)
            box.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            box.PlaceholderText = placeholder
            box.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
            box.Text = ""
            box.TextColor3 = Color3.new(1, 1, 1)
            box.Font = Enum.Font.GothamMedium
            box.TextSize = 15
            box.LayoutOrder = order
            Instance.new("UICorner", box)
            box.FocusLost:Connect(function(e)
                if e then callback(box.Text) end
            end)
            return box
        end

        return tab
    end

    UserInputService.InputBegan:Connect(function(i, gpe)
        if not gpe and i.KeyCode == toggleKey then
            isVisible = not isVisible
            main.Visible = isVisible
        end
    end)

    return menu, currentSettings
end

return mod
