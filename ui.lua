local UILib = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local function tween(obj, props, dur)
    TweenService:Create(obj, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

function UILib.init(title)
    local Window = {}

    local ScreenGui = create("ScreenGui", { Parent = game.CoreGui })
    local Main = create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.new(0, 500, 0, 330),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0
    })

    local Title = create("TextLabel", {
        Parent = Main,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
        Text = tostring(title),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Color3.new(1, 1, 1)
    })

    local TabHolder = create("Frame", {
        Parent = Main,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0
    })

    local TabList = create("UIListLayout", {
        Parent = TabHolder,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local PageHolder = create("Frame", {
        Parent = Main,
        Size = UDim2.new(1, 0, 1, -70),
        Position = UDim2.new(0, 0, 0, 70),
        BackgroundColor3 = Color3.fromRGB(15, 15, 15),
        BorderSizePixel = 0
    })

    Window.Instance = Main
    Window.Tabs = {}

    function Window:addTab(name)
        local Tab = {}

        local Button = create("TextButton", {
            Parent = TabHolder,
            Size = UDim2.new(0, 100, 1, 0),
            BackgroundColor3 = Color3.fromRGB(35, 35, 35),
            BorderSizePixel = 0,
            Text = tostring(name),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Color3.new(1, 1, 1)
        })

        local Page = create("Frame", {
            Parent = PageHolder,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(15, 15, 15),
            BorderSizePixel = 0,
            Visible = false
        })

        local List = create("UIListLayout", {
            Parent = Page,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        Button.MouseButton1Click:Connect(function()
            for _, tab in pairs(Window.Tabs) do
                tab.Page.Visible = false
            end
            Page.Visible = true
        end)

        function Tab:addSection(title)
            local Section = {}

            local Holder = create("Frame", {
                Parent = Page,
                Size = UDim2.new(1, -20, 0, 100),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0
            })

            local Title = create("TextLabel", {
                Parent = Holder,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                BorderSizePixel = 0,
                Text = tostring(title),
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                TextColor3 = Color3.new(1, 1, 1)
            })

            local Elements = create("Frame", {
                Parent = Holder,
                Position = UDim2.new(0, 0, 0, 30),
                Size = UDim2.new(1, 0, 1, -30),
                BackgroundTransparency = 1
            })

            local Layout = create("UIListLayout", {
                Parent = Elements,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            function Section:addCheck(cfg)
                local Btn = create("TextButton", {
                    Parent = Elements,
                    Size = UDim2.new(1, -10, 0, 25),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    BorderSizePixel = 0,
                    Text = tostring(cfg.Text),
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Color3.new(1, 1, 1)
                })

                local state = cfg.Default
                Btn.MouseButton1Click:Connect(function()
                    state = not state
                    cfg.Callback(state)
                end)
            end

            function Section:addDropdown(cfg)
                local Btn = create("TextButton", {
                    Parent = Elements,
                    Size = UDim2.new(1, -10, 0, 25),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    BorderSizePixel = 0,
                    Text = tostring(cfg.Text),
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Color3.new(1, 1, 1)
                })

                Btn.MouseButton1Click:Connect(function()
                    cfg.Callback(cfg.List[1])
                end)
            end

            function Section:addInput(cfg)
                local Box = create("TextBox", {
                    Parent = Elements,
                    Size = UDim2.new(1, -10, 0, 25),
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    BorderSizePixel = 0,
                    Text = tostring(cfg.Default),
                    PlaceholderText = tostring(cfg.Placeholder),
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Color3.new(1, 1, 1)
                })

                Box.FocusLost:Connect(function()
                    cfg.Callback(Box.Text)
                end)
            end

            function Section:addColorPicker(cfg)
                local Btn = create("TextButton", {
                    Parent = Elements,
                    Size = UDim2.new(1, -10, 0, 25),
                    BackgroundColor3 = cfg.Default,
                    BorderSizePixel = 0,
                    Text = tostring(cfg.Text),
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = Color3.new(1, 1, 1)
                })

                Btn.MouseButton1Click:Connect(function()
                    cfg.Callback(cfg.Default, cfg.DefaultAlpha)
                end)
            end

            return Section
        end

        Window.Tabs[name] = { Button = Button, Page = Page }
        return Tab
    end

    function Window:Toast(msg, dur)
        local Toast = create("TextLabel", {
            Parent = Main,
            Size = UDim2.new(0, 300, 0, 30),
            Position = UDim2.new(0.5, -150, 0, -40),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            Text = tostring(msg),
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            BorderSizePixel = 0
        })

        tween(Toast, { Position = UDim2.new(0.5, -150, 0, 10) }, 0.3)
        task.wait(dur)
        tween(Toast, { Position = UDim2.new(0.5, -150, 0, -40) }, 0.3)
        task.wait(0.3)
        Toast:Destroy()
    end

    return Window
end

return UILib
