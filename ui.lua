local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local InputService = game:GetService('UserInputService')
local CoreGui = game:GetService('CoreGui')
local LocalPlayer = game:GetService('Players').LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)

local ScreenGui = Instance.new('ScreenGui')
ProtectGui(ScreenGui)
ScreenGui.Name = "AuraUI_ScreenGui"
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

local AuraUI = {
    Registry = {};
    OpenedFrames = {};
    CurrentWindow = nil;

    FontColor = Color3.fromRGB(30, 30, 30);
    AccentColor = Color3.fromRGB(0, 180, 200);
    MainColor = Color3.fromRGB(245, 245, 250);
    OutlineColor = Color3.fromRGB(200, 200, 200);
    ShadowColor = Color3.new(0, 0, 0);
    Transparency = 0.2;

    WINDOW_SIZE = UDim2.new(0, 600, 0, 400);
    TAB_BAR_WIDTH = 150;
    FONT = Enum.Font.GothamSemibold;
    FONT_SIZE = 14;
    CORNER_RADIUS = 12;
}

function AuraUI:Create(Class, Properties)
    local Element = Instance.new(Class)
    for Key, Value in pairs(Properties) do
        Element[Key] = Value
    end
    return Element
end

local function ApplyGlassStyle(Frame, CornerRadius, Transparency, Color)
    Frame.BackgroundColor3 = Color or AuraUI.MainColor
    Frame.BackgroundTransparency = Transparency or AuraUI.Transparency
    
    local Corner = AuraUI:Create('UICorner', {
        CornerRadius = UDim.new(0, CornerRadius or AuraUI.CORNER_RADIUS),
        Parent = Frame
    })

    local Stroke = AuraUI:Create('UIStroke', {
        Thickness = 1,
        Color = AuraUI.OutlineColor,
        Transparency = 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = Frame
    })

    local Gradient = AuraUI:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color or AuraUI.MainColor),
            ColorSequenceKeypoint.new(1, (Color or AuraUI.MainColor) * Color3.new(0.95, 0.95, 0.95))
        }),
        Rotation = 90,
        Transparency = NumberSequence.new(0),
        Parent = Frame
    })

    return Frame, Corner, Stroke
end

function AuraUI:Window(Name)
    if AuraUI.CurrentWindow then
        warn("AuraUI: Only one main window is supported.")
        return AuraUI.CurrentWindow
    end

    local Window = AuraUI:Create('Frame', {
        Name = Name or "AuraUI_Window",
        Size = AuraUI.WINDOW_SIZE,
        Position = UDim2.new(0.5, -AuraUI.WINDOW_SIZE.Offset.X / 2, 0.5, -AuraUI.WINDOW_SIZE.Offset.Y / 2),
        Parent = ScreenGui,
        Draggable = true,
        ClipsDescendants = true,
    })
    AuraUI.CurrentWindow = Window

    ApplyGlassStyle(Window, AuraUI.CORNER_RADIUS, AuraUI.Transparency, AuraUI.MainColor)

    local TabBar = AuraUI:Create('Frame', {
        Name = "TabBar",
        Size = UDim2.new(0, AuraUI.TAB_BAR_WIDTH, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = Window,
    })
    ApplyGlassStyle(TabBar, AuraUI.CORNER_RADIUS - 5, AuraUI.Transparency + 0.1, AuraUI.MainColor * Color3.new(0.95, 0.95, 0.95))

    local TabListLayout = AuraUI:Create('UIListLayout', {
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabBar,
    })
    AuraUI:Create('UIPadding', {
        PaddingTop = UDim.new(0, 15),
        PaddingBottom = UDim.new(0, 15),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = TabBar,
    })

    local ContentArea = AuraUI:Create('Frame', {
        Name = "ContentArea",
        Size = UDim2.new(1, -AuraUI.TAB_BAR_WIDTH, 1, 0),
        Position = UDim2.new(0, AuraUI.TAB_BAR_WIDTH, 0, 0),
        BackgroundColor3 = AuraUI.MainColor,
        BackgroundTransparency = 1,
        Parent = Window,
    })

    Window.Tabs = {}
    Window.CurrentTab = nil

    function Window:CreateTab(Name, Icon)
        local TabButton = AuraUI:Create('TextButton', {
            Name = "Tab_" .. Name:gsub(" ", "_"),
            Text = Name,
            Font = AuraUI.FONT,
            TextSize = AuraUI.FONT_SIZE,
            TextColor3 = AuraUI.FontColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            Parent = TabBar,
            LayoutOrder = #Window.Tabs + 1
        })
        
        local AccentBar = AuraUI:Create('Frame', {
            Name = "AccentBar",
            Size = UDim2.new(0, 3, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = AuraUI.AccentColor,
            BackgroundTransparency = 1,
            Parent = TabButton
        })
        ApplyGlassStyle(AccentBar, 2, 0.5, AuraUI.AccentColor)

        local TabFrame = AuraUI:Create('ScrollingFrame', {
            Name = "TabContent_" .. Name:gsub(" ", "_"),
            Size = UDim2.new(1, -15, 1, -15),
            Position = UDim2.new(0, 15, 0, 15),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarImageColor3 = AuraUI.AccentColor,
            ScrollBarThickness = 6,
            BackgroundTransparency = 1,
            Parent = ContentArea,
            Visible = false
        })

        local ContentLayout = AuraUI:Create('UIListLayout', {
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TabFrame,
        })
        
        local Tab = {
            Button = TabButton;
            Frame = TabFrame;
            Layout = ContentLayout;
            Elements = {};
        }

        function TabButton.MouseButton1Click()
            if Window.CurrentTab == Tab then return end
            
            if Window.CurrentTab then
                TweenService:Create(Window.CurrentTab.Button.AccentBar, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
                Window.CurrentTab.Button.TextColor3 = AuraUI.FontColor
                Window.CurrentTab.Frame.Visible = false
            end

            TweenService:Create(AccentBar, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            TabButton.TextColor3 = AuraUI.AccentColor
            TabFrame.Visible = true
            Window.CurrentTab = Tab

            RunService.Heartbeat:Wait()
            TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y)
        end
        
        if #Window.Tabs == 0 then
            TabButton.MouseButton1Click()
        end
        
        function Tab:Label(Text)
            local LabelFrame = AuraUI:Create('Frame', {
                Name = "LabelFrame",
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Parent = TabFrame
            })

            local Label = AuraUI:Create('TextLabel', {
                Name = "Label",
                Text = Text,
                Font = AuraUI.FONT,
                TextSize = AuraUI.FONT_SIZE + 2,
                TextColor3 = AuraUI.FontColor * Color3.new(0.8, 0.8, 0.8),
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = LabelFrame
            })
            
            local LabelElement = {
                Label = Label;
            }

            function LabelElement:SetText(NewText)
                Label.Text = NewText
                RunService.Heartbeat:Wait()
                TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y)
            end

            table.insert(Tab.Elements, LabelFrame)
            return LabelElement
        end
        
        function Tab:Divider()
            local DividerFrame = AuraUI:Create('Frame', {
                Name = "DividerFrame",
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Parent = TabFrame
            })
            
            local Line = AuraUI:Create('Frame', {
                Name = "Line",
                Size = UDim2.new(1, -20, 0, 1),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = AuraUI.OutlineColor,
                BackgroundTransparency = AuraUI.Transparency + 0.5,
                Parent = DividerFrame
            })

            table.insert(Tab.Elements, DividerFrame)
        end

        function Tab:Toggle(Name, Default)
            local ToggleElement = {
                Value = Default or false,
                CallbackFunc = function() end,
            }
            Toggles[Name] = ToggleElement

            local ToggleFrame = AuraUI:Create('Frame', {
                Name = "Toggle_" .. Name:gsub(" ", "_"),
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Parent = TabFrame
            })

            local Label = AuraUI:Create('TextLabel', {
                Name = "Label",
                Text = Name,
                Font = AuraUI.FONT,
                TextSize = AuraUI.FONT_SIZE,
                TextColor3 = AuraUI.FontColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -40, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ToggleFrame
            })

            local IndicatorSize = 20
            local Indicator = AuraUI:Create('TextButton', {
                Name = "Indicator",
                Size = UDim2.new(0, IndicatorSize * 2, 0, IndicatorSize),
                Position = UDim2.new(1, -IndicatorSize * 2, 0.5, -IndicatorSize / 2),
                BackgroundTransparency = 0,
                Text = "",
                Parent = ToggleFrame,
                
            })
            ApplyGlassStyle(Indicator, IndicatorSize / 2, AuraUI.Transparency + 0.1, AuraUI.OutlineColor)

            local ToggleCircle = AuraUI:Create('Frame', {
                Name = "Circle",
                Size = UDim2.new(0, IndicatorSize * 0.8, 0, IndicatorSize * 0.8),
                Position = UDim2.new(0, IndicatorSize * 0.1, 0.5, -IndicatorSize * 0.4),
                BackgroundColor3 = AuraUI.FontColor,
                Parent = Indicator,
            })
            AuraUI:Create('UICorner', {CornerRadius = UDim.new(1, 0), Parent = ToggleCircle})

            local function UpdateVisuals(IsActive)
                local IndicatorColor = IsActive and AuraUI.AccentColor or AuraUI.OutlineColor
                local Position = IsActive and UDim2.new(1, -IndicatorSize * 0.1 - ToggleCircle.Size.Offset.X, 0.5, -IndicatorSize * 0.4)
                                          or UDim2.new(0, IndicatorSize * 0.1, 0.5, -IndicatorSize * 0.4)

                TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = IndicatorColor}):Play()
                TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = Position}):Play()
                ToggleCircle.BackgroundColor3 = IsActive and Color3.new(1, 1, 1) or AuraUI.FontColor
                
                local Grad = Indicator:FindFirstChildOfClass("UIGradient")
                if Grad then
                   Grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, IndicatorColor),
                        ColorSequenceKeypoint.new(1, IndicatorColor * Color3.new(0.9, 0.9, 0.9))
                    })
                end
            end
            
            function ToggleElement:SetValue(NewState)
                if NewState ~= self.Value then
                    self.Value = NewState
                    UpdateVisuals(NewState)
                    self.CallbackFunc(NewState)
                end
            end

            function ToggleElement:OnChanged(Func)
                self.CallbackFunc = Func
            end

            Indicator.MouseButton1Click:Connect(function()
                ToggleElement:SetValue(not ToggleElement.Value)
            end)

            UpdateVisuals(ToggleElement.Value)
            table.insert(Tab.Elements, ToggleFrame)
            
            return ToggleElement
        end

        function Tab:Button(Name, Callback)
            local Button = AuraUI:Create('TextButton', {
                Name = "Button_" .. Name:gsub(" ", "_"),
                Text = Name,
                Font = AuraUI.FONT,
                TextSize = AuraUI.FONT_SIZE,
                TextColor3 = Color3.new(1, 1, 1),
                Size = UDim2.new(1, 0, 0, 35),
                Parent = TabFrame,
            })
            ApplyGlassStyle(Button, 8, 0, AuraUI.AccentColor)

            Button.MouseEnter:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
            end)
            Button.MouseLeave:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
            end)
            
            Button.MouseButton1Click:Connect(Callback or function() end)

            table.insert(Tab.Elements, Button)
            
            local ButtonElement = {
                Button = Button
            }
            return ButtonElement
        end
        
        function Tab:Slider(Name, Min, Max, Default, Step)
            local SliderElement = {
                Value = Default or Min,
                CallbackFunc = function() end,
            }
            Options[Name] = SliderElement
            Min, Max, Step = Min or 0, Max or 100, Step or 1

            local SliderFrame = AuraUI:Create('Frame', {
                Name = "Slider_" .. Name:gsub(" ", "_"),
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundTransparency = 1,
                Parent = TabFrame
            })

            local Label = AuraUI:Create('TextLabel', {
                Name = "Label",
                Text = string.format("%s: %.2f", Name, SliderElement.Value),
                Font = AuraUI.FONT,
                TextSize = AuraUI.FONT_SIZE,
                TextColor3 = AuraUI.FontColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0.5, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SliderFrame
            })

            local Track = AuraUI:Create('Frame', {
                Name = "Track",
                Size = UDim2.new(1, 0, 0, 8),
                Position = UDim2.new(0, 0, 0.6, 0),
                BackgroundColor3 = AuraUI.OutlineColor,
                BackgroundTransparency = AuraUI.Transparency + 0.2,
                Parent = SliderFrame,
            })
            ApplyGlassStyle(Track, 4, AuraUI.Transparency + 0.2, AuraUI.OutlineColor)
            
            local Fill = AuraUI:Create('Frame', {
                Name = "Fill",
                Size = UDim2.new(0, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = AuraUI.AccentColor,
                Parent = Track,
            })
            AuraUI:Create('UICorner', {CornerRadius = UDim.new(1, 0), Parent = Fill})
            
            local Knob = AuraUI:Create('Frame', {
                Name = "Knob",
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(0, -8, 0.5, -8),
                BackgroundColor3 = AuraUI.AccentColor,
                Parent = Track,
                ZIndex = 2
            })
            AuraUI:Create('UICorner', {CornerRadius = UDim.new(1, 0), Parent = Knob})
            
            local IsDragging = false
            
            local function UpdateVisuals(Value)
                local FillRatio = (Value - Min) / (Max - Min)
                local TrackWidth = Track.AbsoluteSize.X
                local KnobOffset = FillRatio * TrackWidth
                
                Fill.Size = UDim2.new(0, KnobOffset, 1, 0)
                Knob.Position = UDim2.new(0, KnobOffset - 8, 0.5, -8)
                Label.Text = string.format("%s: %.2f", Name, Value)
            end

            local function UpdateSlider(Input)
                local TrackPos = Track.AbsolutePosition.X
                local TrackWidth = Track.AbsoluteSize.X
                local MouseX = Input.Position.X
                
                local Ratio = math.min(1, math.max(0, (MouseX - TrackPos) / TrackWidth))
                local Value = Min + Ratio * (Max - Min)
                
                if Step > 0 then
                    Value = math.floor((Value / Step) + 0.5) * Step
                end
                Value = math.min(Max, math.max(Min, Value))
                
                if Value ~= SliderElement.Value then
                    SliderElement.Value = Value
                    UpdateVisuals(Value)
                    SliderElement.CallbackFunc(Value)
                end
            end
            
            function SliderElement:SetValue(NewValue)
                local ClampedValue = math.min(Max, math.max(Min, NewValue))
                
                if Step > 0 then
                    ClampedValue = math.floor((ClampedValue / Step) + 0.5) * Step
                end
                
                if ClampedValue ~= self.Value then
                    self.Value = ClampedValue
                    UpdateVisuals(ClampedValue)
                    self.CallbackFunc(ClampedValue)
                end
            end

            function SliderElement:OnChanged(Func)
                self.CallbackFunc = Func
            end

            Track.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    IsDragging = true
                    UpdateSlider(Input)
                end
            end)

            Knob.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    IsDragging = true
                    Knob.ZIndex = 3
                end
            end)

            InputService.InputChanged:Connect(function(Input)
                if IsDragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(Input)
                end
            end)

            InputService.InputEnded:Connect(function(Input)
                if IsDragging and (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                    IsDragging = false
                    Knob.ZIndex = 2
                end
            end)
            
            UpdateVisuals(SliderElement.Value)

            table.insert(Tab.Elements, SliderFrame)
            
            return SliderElement
        end

        Window.Tabs[Name] = Tab
        return Tab
    end

    local ModalElement = AuraUI:Create('TextButton', {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0),
        Visible = true,
        Text = '',
        Modal = false,
        Parent = ScreenGui,
    })
    
    local isVisible = true
    
    InputService.InputBegan:Connect(function(Input, Processed)
        if Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            isVisible = not isVisible
            Window.Visible = isVisible
            ModalElement.Modal = isVisible

            InputService.MouseIconEnabled = isVisible
        end
    end)
    
    Window.Position = UDim2.new(0.5, -Window.Size.Offset.X / 2, 0.5, -Window.Size.Offset.Y / 2)

    return Window
end

getgenv().AuraUI = AuraUI
