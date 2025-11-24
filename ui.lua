local UILib = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Utility function for creating instances
local function new(class, props)
    local o = Instance.new(class)
    for k,v in pairs(props or {}) do o[k] = v end
    return o
end

-- Utility function for tweening properties
local function tween(o, p, t)
    if not o or not p then return end
    local ok, tk = pcall(function()
        return TweenService:Create(o, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
    end)
    if ok and tk then
        pcall(function() tk:Play() end)
    end
end

function UILib.init(title)
    local Window = {}
    local parentGui = Players.LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

    local sg = new("ScreenGui", { Parent = parentGui, ResetOnSpawn = false, IgnoreGuiInset = true })
    local main = new("Frame", {
        Parent = sg,
        Size = UDim2.new(0, 700, 0, 420),
        Position = UDim2.new(0.5, -350, 0.5, -210),
        BackgroundColor3 = Color3.fromRGB(28, 28, 28),
        BorderSizePixel = 0,
        Active = true
    })

    -- UI DRAGGING LOGIC (Kept as is)
    local dragging, dragStart, startPos
    main.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
        end
    end)
    main.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Header (Kept as is)
    new("TextLabel", {
        Parent = main,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = tostring(title or ""),
        TextSize = 18,
        TextColor3 = Color3.new(1, 1, 1)
    })

    -- Left vertical tab list (Kept as is)
    local tabbar = new("Frame", {
        Parent = main,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 140, 1, -40),
        BackgroundColor3 = Color3.fromRGB(32, 32, 32),
        BorderSizePixel = 0
    })
    new("UIListLayout", { Parent = tabbar, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
    new("UIPadding", { Parent = tabbar, PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

    -- Pages container (Kept as is)
    local pages = new("ScrollingFrame", {
        Parent = main,
        Position = UDim2.new(0, 140, 0, 40),
        Size = UDim2.new(1, -140, 1, -40),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 6
    })

    -- Container for toasts (Kept as is)
    local toastContainer = new("Frame", {
        Parent = sg,
        Size = UDim2.new(0, 0, 0, 0), 
        BackgroundTransparency = 1,
        LayoutOrder = Enum.SortOrder.LayoutOrder,
        Position = UDim2.new(1, 0, 1, 0), 
        AnchorPoint = Vector2.new(1, 1)
    })
    new("UIListLayout", { 
        Parent = toastContainer, 
        FillDirection = Enum.FillDirection.Vertical, 
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10)
    })
    new("UIPadding", {
        Parent = toastContainer,
        PaddingRight = UDim.new(0, 15),
        PaddingBottom = UDim.new(0, 15)
    })

    Window.Tabs = {}
    Window.Active = nil

    -- addTab function (Kept as is)
    function Window:addTab(name)
        local Tab = {}
        local btn = new("TextButton", {
            Parent = tabbar,
            Size = UDim2.new(1, -20, 0, 34),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            Text = name,
            TextSize = 14,
            TextColor3 = Color3.new(1, 1, 1)
        })

        btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = Color3.fromRGB(55,55,55) }, 0.15) end)
        btn.MouseLeave:Connect(function()
            if Window.Active and Window.Active.btn == btn then
                btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            else
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            end
        end)

        local page = new("Frame", { Parent = pages, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false })

        -- Horizontal container for sections (Kept as is)
        local leftColumn = new("Frame", { Parent = page, Size = UDim2.new(0.5, -5, 1, 0), BackgroundTransparency = 1 })
        local rightColumn = new("Frame", { Parent = page, Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 10, 0, 0), BackgroundTransparency = 1 })

        btn.MouseButton1Click:Connect(function()
            if Window.Active then
                Window.Active.page.Visible = false
                Window.Active.btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            end
            page.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            Window.Active = { page = page, btn = btn }
        end)

        -- addSection function (Kept as is)
        function Tab:addSection(secName, column)
            local parentColumn
            if column == "left" then parentColumn = leftColumn
            elseif column == "right" then parentColumn = rightColumn
            else
                -- Auto alternate if not specified
                local leftCount = #leftColumn:GetChildren()
                local rightCount = #rightColumn:GetChildren()
                parentColumn = (leftCount <= rightCount) and leftColumn or rightColumn
            end

            local Sec = {}
            local holder = new("Frame", { Parent = parentColumn, Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Color3.fromRGB(32,32,32), BorderSizePixel = 0 })
            new("TextLabel", { Parent = holder, Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Color3.fromRGB(45,45,45), BorderSizePixel = 0, Font = Enum.Font.GothamBold, Text = secName, TextSize = 14, TextColor3 = Color3.new(1,1,1) })

            local body = new("Frame", { Parent = holder, Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 1, -28), BackgroundTransparency = 1 })
            local lay = new("UIListLayout", { Parent = body, Padding = UDim.new(0, 7) })

            lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                task.defer(function()
                    holder.Size = UDim2.new(1, 0, 0, lay.AbsoluteContentSize.Y + 35)
                end)
            end)

            -- addCheck function (Kept as is)
            function Sec:addCheck(cfg)
                local b = new("TextButton", { Parent = body, Size = UDim2.new(1, -10, 0, 28), BackgroundColor3 = Color3.fromRGB(50,50,50), Font = Enum.Font.Gotham, Text = cfg.Text or "", TextSize = 14, TextColor3 = Color3.new(1,1,1), BorderSizePixel = 0 })
                local state = cfg.Default and true or false
                local ind = new("Frame", { Parent = b, Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -26, 0.5, -11), BackgroundColor3 = state and Color3.fromRGB(0,255,80) or Color3.fromRGB(80,80,80), BorderSizePixel = 0 })
                b.MouseButton1Click:Connect(function()
                    state = not state
                    tween(ind, { BackgroundColor3 = state and Color3.fromRGB(0,255,80) or Color3.fromRGB(80,80,80) }, 0.15)
                    if cfg.Callback then cfg.Callback(state) end
                end)
            end

            -- FINAL FIX: Dropdown logic (Parenting, Relative Positioning, and Scrolling Offset)
            function Sec:addDropdown(cfg)
                local listItems = cfg.List or {}
                local currentSelection = listItems[1] or ""
                
                local frame = new("Frame", { Parent = body, Size = UDim2.new(1, -10, 0, 28), BackgroundColor3 = Color3.fromRGB(50,50,50), BorderSizePixel = 0 })
                local lbl = new("TextLabel", { 
                    Parent = frame, 
                    Size = UDim2.new(1, -25, 1, 0), 
                    BackgroundTransparency = 1, 
                    Font = Enum.Font.Gotham, 
                    Text = currentSelection, 
                    TextColor3 = Color3.new(1,1,1), 
                    TextSize = 14 
                })
                local btn = new("TextButton", { Parent = frame, Size = UDim2.new(0,22,0,22), Position = UDim2.new(1,-24,0.5,-11), BackgroundColor3 = Color3.fromRGB(70,70,70), Text = "▼", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0 })
            
                -- Parent to the main window ('main') so it moves with the draggable window
                local drop = new("Frame", { 
                    Parent = main, 
                    Size = UDim2.new(0, 0, 0, 0), 
                    BackgroundColor3 = Color3.fromRGB(45,45,45), 
                    BorderSizePixel = 0, 
                    ClipsDescendants = true, 
                    ZIndex = 10 
                })
                new("UIListLayout", { Parent = drop, SortOrder = Enum.SortOrder.LayoutOrder })
            
                local open = false
                btn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        local dropWidth = frame.AbsoluteSize.X
                        local itemHeight = 24
                        local height = (#listItems * itemHeight)
                        local screenHeight = workspace.CurrentCamera.ViewportSize.Y
                        
                        -- 1. Get position of the button frame relative to the main window's content area (pages)
                        local relativePos = frame.AbsolutePosition - pages.AbsolutePosition
                        
                        -- 2. Calculate the final position relative to the main window (main)
                        -- The dropdown must align with the main window's X-offset (140) + the page frame's X-offset (relativePos.X)
                        -- And the main window's Y-offset (40) + the page frame's Y-offset (relativePos.Y) + button height
                        
                        local xOffset = 140 + relativePos.X
                        local yOffset = 40 + relativePos.Y + frame.AbsoluteSize.Y
                        
                        drop.Position = UDim2.new(0, xOffset, 0, yOffset)
                        
                        -- 3. Check for screen boundary collision (requires AbsolutePosition of the dropdown)
                        local dropAbsY = main.AbsolutePosition.Y + yOffset
                        if dropAbsY + height > screenHeight then
                            -- Calculate new Y offset to place it ABOVE the button
                            yOffset = 40 + relativePos.Y - height
                            drop.Position = UDim2.new(0, xOffset, 0, yOffset)
                        end
                        
                        drop.Size = UDim2.new(0, dropWidth, 0, 0)
                        tween(drop, { Size = UDim2.new(0, dropWidth, 0, height) }, 0.2)
                    else
                        tween(drop, { Size = UDim2.new(0, frame.AbsoluteSize.X, 0, 0) }, 0.2)
                    end
                end)
            
                for _, item in ipairs(listItems) do
                    local op = new("TextButton", { Parent = drop, Size = UDim2.new(1,0,0,24), BackgroundColor3 = Color3.fromRGB(55,55,55), BorderSizePixel = 0, Font = Enum.Font.Gotham, Text = item, TextColor3 = Color3.new(1,1,1), TextSize = 14, ZIndex = 11 })
                    op.MouseButton1Click:Connect(function()
                        currentSelection = item
                        lbl.Text = item 

                        open = false
                        tween(drop, { Size = UDim2.new(0, frame.AbsoluteSize.X, 0, 0) }, 0.2)
                        if cfg.Callback then cfg.Callback(item) end
                    end)
                end
            end

            -- addInput function (Kept as is)
            function Sec:addInput(cfg)
                local box = new("TextBox", { Parent = body, Size = UDim2.new(1, -10, 0, 28), BackgroundColor3 = Color3.fromRGB(50,50,50), BorderSizePixel = 0, Text = cfg.Default or "", PlaceholderText = cfg.Placeholder or "", Font = Enum.Font.Gotham, TextColor3 = Color3.new(1,1,1), TextSize = 14 })
                box.FocusLost:Connect(function() if cfg.Callback then cfg.Callback(box.Text) end end)
            end

            -- addColorPicker function (Kept as is)
            function Sec:addColorPicker(cfg)
                local b = new("TextButton", { Parent = body, Size = UDim2.new(1, -10, 0, 28), BackgroundColor3 = cfg.Default or Color3.fromRGB(255,255,255), BorderSizePixel = 0, Text = cfg.Text or "", Font = Enum.Font.Gotham, TextColor3 = Color3.new(1,1,1), TextSize = 14 })
                b.MouseButton1Click:Connect(function() if cfg.Callback then cfg.Callback(cfg.Default, cfg.DefaultAlpha) end end)
            end

            return Sec
        end

        Window.Tabs[name] = { page = page, btn = btn }

        if not Window.Active then
            page.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            Window.Active = { page = page, btn = btn }
        end

        return Tab
    end

    -- Toast function (Kept as is)
    function Window:Toast(msg, dur)
        local t = new("TextLabel", { 
            Parent = toastContainer, 
            Size = UDim2.new(0, 320, 0, 32), 
            Position = UDim2.new(0, 320, 0, 0), 
            BackgroundColor3 = Color3.fromRGB(40, 40, 40), 
            Text = tostring(msg or ""), 
            TextColor3 = Color3.new(1,1,1), 
            Font = Enum.Font.GothamBold, 
            TextSize = 14, 
            BorderSizePixel = 0 
        })
        
        tween(t, { Position = UDim2.new(0, 0, 0, 0) }, 0.25) 

        task.delay(math.max(0.5, dur or 2), function()
            tween(t, { Position = UDim2.new(0, 320, 0, 0) }, 0.25) 
            task.wait(0.25)
            pcall(function() t:Destroy() end)
        end)
    end

    Window.Instance = main
    return Window
end

return UILib
