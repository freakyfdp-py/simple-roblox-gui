local UILib = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local function new(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        o[k] = v
    end
    return o
end

local function tween(o, p, t)
    if not o or not p then return end
    local ok, tk = pcall(function()
        return TweenService:Create(o, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
    end)
    if ok and tk then
        pcall(function() tk:Play() end)
    end
end

local function waitForChildTimed(parent, name, timeout)
    if not parent then return nil end
    local child = parent:FindFirstChild(name)
    if child then return child end
    local waited = 0
    while waited < (timeout or 5) do
        child = parent:FindFirstChild(name)
        if child then return child end
        task.wait(0.05)
        waited = waited + 0.05
    end
    return parent:FindFirstChild(name)
end

function UILib.init(title)
    local Window = {}
    local parentGui
    local localPlayer = Players.LocalPlayer
    if localPlayer and localPlayer:FindFirstChild("PlayerGui") then
        parentGui = localPlayer:FindFirstChild("PlayerGui")
    else
        parentGui = game:GetService("CoreGui")
    end

    local sg = new("ScreenGui", { Parent = parentGui, ResetOnSpawn = false, IgnoreGuiInset = true })
    local main = new("Frame", {
        Parent = sg,
        Size = UDim2.new(0, 550, 0, 380),
        Position = UDim2.new(0.5, -275, 0.5, -190),
        BackgroundColor3 = Color3.fromRGB(28, 28, 28),
        BorderSizePixel = 0,
        Active = true
    })

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

    local top = new("TextLabel", {
        Parent = main,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = tostring(title or ""),
        TextSize = 18,
        TextColor3 = Color3.new(1, 1, 1)
    })

    local tabbar = new("Frame", {
        Parent = main,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = Color3.fromRGB(32, 32, 32),
        BorderSizePixel = 0
    })

    local tablist = new("UIListLayout", {
        Parent = tabbar,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local pages = new("Frame", {
        Parent = main,
        Position = UDim2.new(0, 0, 0, 75),
        Size = UDim2.new(1, 0, 1, -75),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0
    })

    Window.Instance = main
    Window.Tabs = {}
    Window.Active = nil

    function Window:addTab(name)
        local Tab = {}
        local btn = new("TextButton", {
            Parent = tabbar,
            Size = UDim2.new(0, 120, 1, 0),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            Text = name,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 14
        })

        local page = new("ScrollingFrame", {
            Parent = pages,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ScrollBarThickness = 4,
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })

        local pageLayout = new("UIListLayout", { Parent = page, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
        new("UIPadding", { Parent = page, PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 10) })

        btn.MouseButton1Click:Connect(function()
            if Window.Active then Window.Active.page.Visible = false end
            page.Visible = true
            Window.Active = { page = page, btn = btn }
        end)

        function Tab:addSection(secName)
            local Sec = {}

            local holder = new("Frame", {
                Parent = page,
                Size = UDim2.new(1, -20, 0, 50),
                BackgroundColor3 = Color3.fromRGB(32, 32, 32),
                BorderSizePixel = 0
            })

            local titleLbl = new("TextLabel", {
                Parent = holder,
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = Color3.fromRGB(45, 45, 45),
                BorderSizePixel = 0,
                Font = Enum.Font.GothamSemibold,
                TextColor3 = Color3.new(1, 1, 1),
                Text = secName,
                TextSize = 14
            })

            local body = new("Frame", {
                Parent = holder,
                Position = UDim2.new(0, 0, 0, 28),
                Size = UDim2.new(1, 0, 1, -28),
                BackgroundTransparency = 1
            })

            local lay = new("UIListLayout", {
                Parent = body,
                Padding = UDim.new(0, 7),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            local function resize()
                task.defer(function()
                    holder.Size = UDim2.new(1, -20, 0, lay.AbsoluteContentSize.Y + 35)
                    page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 20)
                end)
            end
            lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
            pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
            resize()

            function Sec:addCheck(cfg)
                local b = new("TextButton", {
                    Parent = body,
                    Size = UDim2.new(1, -10, 0, 28),
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    BorderSizePixel = 0,
                    Font = Enum.Font.Gotham,
                    Text = cfg.Text or "",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 14
                })

                local state = cfg.Default and true or false
                local ind = new("Frame", {
                    Parent = b,
                    Size = UDim2.new(0, 22, 0, 22),
                    Position = UDim2.new(1, -26, 0.5, -11),
                    BackgroundColor3 = state and Color3.fromRGB(0, 255, 80) or Color3.fromRGB(80, 80, 80),
                    BorderSizePixel = 0
                })

                b.MouseButton1Click:Connect(function()
                    state = not state
                    tween(ind, { BackgroundColor3 = state and Color3.fromRGB(0, 255, 80) or Color3.fromRGB(80, 80, 80) }, 0.15)
                    pcall(function() if cfg.Callback then cfg.Callback(state) end end)
                end)
            end

            function Sec:addDropdown(cfg)
                local frame = new("Frame", {
                    Parent = body,
                    Size = UDim2.new(1, -10, 0, 28),
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    BorderSizePixel = 0
                })

                local lbl = new("TextLabel", {
                    Parent = frame,
                    Size = UDim2.new(1, -25, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = cfg.Text or "",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 14
                })

                local btn = new("TextButton", {
                    Parent = frame,
                    Size = UDim2.new(0, 22, 0, 22),
                    Position = UDim2.new(1, -24, 0.5, -11),
                    BackgroundColor3 = Color3.fromRGB(70, 70, 70),
                    Text = "▼",
                    TextColor3 = Color3.new(1, 1, 1),
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    BorderSizePixel = 0
                })

                local drop = new("Frame", {
                    Parent = frame,
                    Position = UDim2.new(0, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundColor3 = Color3.fromRGB(45, 45, 45),
                    BorderSizePixel = 0,
                    ClipsDescendants = true
                })

                local dropLayout = new("UIListLayout", { Parent = drop, SortOrder = Enum.SortOrder.LayoutOrder })

                local open = false

                btn.MouseButton1Click:Connect(function()
                    open = not open
                    tween(drop, { Size = UDim2.new(1, 0, 0, open and (#(cfg.List or {}) * 24) or 0) }, 0.2)
                end)

                for _, item in ipairs(cfg.List or {}) do
                    local op = new("TextButton", {
                        Parent = drop,
                        Size = UDim2.new(1, 0, 0, 24),
                        BackgroundColor3 = Color3.fromRGB(55, 55, 55),
                        BorderSizePixel = 0,
                        Font = Enum.Font.Gotham,
                        Text = item,
                        TextColor3 = Color3.new(1, 1, 1),
                        TextSize = 14
                    })
                    op.MouseButton1Click:Connect(function()
                        open = false
                        tween(drop, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                        pcall(function() if cfg.Callback then cfg.Callback(item) end end)
                    end)
                end
            end

            function Sec:addInput(cfg)
                local box = new("TextBox", {
                    Parent = body,
                    Size = UDim2.new(1, -10, 0, 28),
                    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                    BorderSizePixel = 0,
                    Text = cfg.Default or "",
                    PlaceholderText = cfg.Placeholder or "",
                    Font = Enum.Font.Gotham,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 14
                })

                box.FocusLost:Connect(function()
                    pcall(function() if cfg.Callback then cfg.Callback(box.Text) end end)
                end)
            end

            function Sec:addColorPicker(cfg)
                local b = new("TextButton", {
                    Parent = body,
                    Size = UDim2.new(1, -10, 0, 28),
                    BackgroundColor3 = cfg.Default or Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Text = cfg.Text or "",
                    Font = Enum.Font.Gotham,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 14
                })

                b.MouseButton1Click:Connect(function()
                    pcall(function() if cfg.Callback then cfg.Callback(cfg.Default, cfg.DefaultAlpha) end end)
                end)
            end

            return Sec
        end

        Window.Tabs[name] = { page = page, btn = btn }
        if not Window.Active then
            page.Visible = true
            Window.Active = { page = page, btn = btn }
        end
        return Tab
    end

    function Window:Toast(msg, dur)
        local t = new("TextLabel", {
            Parent = main,
            Size = UDim2.new(0, 320, 0, 32),
            Position = UDim2.new(0.5, -160, 0, -40),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            Text = tostring(msg or ""),
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            BorderSizePixel = 0
        })
        tween(t, { Position = UDim2.new(0.5, -160, 0, 5) }, 0.25)
        task.delay(math.max(0.5, dur or 2), function()
            tween(t, { Position = UDim2.new(0.5, -160, 0, -40) }, 0.25)
            task.wait(0.25)
            pcall(function() t:Destroy() end)
        end)
    end

    return Window
end

return UILib
