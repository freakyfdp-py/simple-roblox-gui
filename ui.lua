local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local TweenService = game:GetService('TweenService');
local CoreGui = game:GetService('CoreGui');
local RenderStepped = game:GetService('RunService').RenderStepped;
local LocalPlayer = game:GetService('Players').LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(28, 28, 28);
    BackgroundColor = Color3.fromRGB(20, 20, 20);
    AccentColor = Color3.fromRGB(0, 85, 255);
    OutlineColor = Color3.fromRGB(50, 50, 50);

    Black = Color3.new(0, 0, 0);

    OpenedFrames = {};
    CurrentWindow = nil;
    
    WINDOW_SIZE = UDim2.new(0, 500, 0, 350);
    TAB_BAR_WIDTH = 130;
    FONT = Enum.Font.GothamSemibold;
    FONT_SIZE = 14;
    CORNER_RADIUS = 6;
};

function Library:Create(Class, Properties)
    local Element = Instance.new(Class);
    for Key, Value in pairs(Properties) do
        Element[Key] = Value;
    end
    return Element;
end;

function Library:Style(Frame, CornerRadius, Color, Outline, Transparency)
    Frame.BackgroundColor3 = Color or Library.MainColor;
    Frame.BackgroundTransparency = Transparency or 0;
    
    if CornerRadius then
        Library:Create('UICorner', {
            CornerRadius = UDim.new(0, CornerRadius),
            Parent = Frame
        });
    end

    if Outline then
        Library:Create('UIStroke', {
            Thickness = 1;
            Color = Library.OutlineColor;
            Transparency = 0.5;
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            Parent = Frame
        });
    end
    
    return Frame;
end;

function Library:Window(Name)
    if Library.CurrentWindow then
        warn("Linoria: Only one main window is supported.");
        return Library.CurrentWindow;
    end

    local Window = {};
    local Outer = Library:Create('Frame', {
        Name = Name or "Linoria_Window";
        Size = Library.WINDOW_SIZE;
        Position = UDim2.new(0.5, -Library.WINDOW_SIZE.Offset.X / 2, 0.5, -Library.WINDOW_SIZE.Offset.Y / 2);
        Parent = ScreenGui;
        Draggable = true;
        ClipsDescendants = true;
    });
    Library.CurrentWindow = Outer;

    Library:Style(Outer, Library.CORNER_RADIUS, Library.BackgroundColor, true, 0);

    local Header = Library:Create('Frame', {
        Name = "Header";
        Size = UDim2.new(1, 0, 0, 30);
        Position = UDim2.new(0, 0, 0, 0);
        BackgroundColor3 = Library.MainColor;
        Parent = Outer;
    });
    Library:Style(Header, nil, Library.MainColor, true, 0); 
    
    local Title = Library:Create('TextLabel', {
        Name = "Title";
        Text = Name or "Linoria UI";
        Font = Library.FONT;
        TextSize = Library.FONT_SIZE + 2;
        TextColor3 = Library.FontColor;
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, 0);
        TextXAlignment = Enum.TextXAlignment.Center;
        Parent = Header;
    });

    local TabBar = Library:Create('Frame', {
        Name = "TabBar";
        Size = UDim2.new(0, Library.TAB_BAR_WIDTH, 1, -30);
        Position = UDim2.new(0, 0, 0, 30);
        BackgroundColor3 = Library.MainColor;
        Parent = Outer;
    });
    Library:Style(TabBar, nil, Library.MainColor, true, 0);

    local TabListLayout = Library:Create('UIListLayout', {
        HorizontalAlignment = Enum.HorizontalAlignment.Left;
        VerticalAlignment = Enum.VerticalAlignment.Top;
        Padding = UDim.new(0, 5);
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabBar;
    });
    Library:Create('UIPadding', {
        PaddingTop = UDim.new(0, 5);
        PaddingBottom = UDim.new(0, 5);
        PaddingLeft = UDim.new(0, 5);
        PaddingRight = UDim.new(0, 5);
        Parent = TabBar;
    });

    local ContentArea = Library:Create('Frame', {
        Name = "ContentArea";
        Size = UDim2.new(1, -Library.TAB_BAR_WIDTH, 1, -30);
        Position = UDim2.new(0, Library.TAB_BAR_WIDTH, 0, 30);
        BackgroundColor3 = Library.BackgroundColor;
        BackgroundTransparency = 0;
        Parent = Outer;
    });
    Library:Style(ContentArea, nil, Library.BackgroundColor, false, 0);

    Outer.Tabs = {};
    Outer.CurrentTab = nil;

    function Outer:CreateTab(Name, Icon)
        local TabButton = Library:Create('TextButton', {
            Name = "Tab_" .. Name:gsub(" ", "_");
            Text = Name;
            Font = Library.FONT;
            TextSize = Library.FONT_SIZE;
            TextColor3 = Library.FontColor;
            TextXAlignment = Enum.TextXAlignment.Left;
            BackgroundColor3 = Library.MainColor;
            BackgroundTransparency = 0;
            Size = UDim2.new(1, 0, 0, 25);
            Parent = TabBar;
            LayoutOrder = #Outer.Tabs + 1;
        });
        Library:Style(TabButton, Library.CORNER_RADIUS - 3, Library.MainColor, false, 0);
        
        local AccentBar = Library:Create('Frame', {
            Name = "AccentBar";
            Size = UDim2.new(0, 3, 1, 0);
            Position = UDim2.new(0, 0, 0, 0);
            BackgroundColor3 = Library.AccentColor;
            BackgroundTransparency = 1;
            Parent = TabButton;
        });

        local TabFrame = Library:Create('ScrollingFrame', {
            Name = "TabContent_" .. Name:gsub(" ", "_");
            Size = UDim2.new(1, -10, 1, -10);
            Position = UDim2.new(0, 5, 0, 5);
            CanvasSize = UDim2.new(0, 0, 0, 0);
            ScrollBarImageColor3 = Library.AccentColor;
            ScrollBarThickness = 6;
            BackgroundTransparency = 1;
            Parent = ContentArea;
            Visible = false;
        });

        local ContentLayout = Library:Create('UIListLayout', {
            HorizontalAlignment = Enum.HorizontalAlignment.Center;
            VerticalAlignment = Enum.VerticalAlignment.Top;
            Padding = UDim.new(0, 10);
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = TabFrame;
        });
        Library:Create('UIPadding', {
            PaddingTop = UDim.new(0, 5);
            PaddingBottom = UDim.new(0, 5);
            PaddingLeft = UDim.new(0, 5);
            PaddingRight = UDim.new(0, 5);
            Parent = TabFrame;
        });
        
        local Tab = {
            Button = TabButton;
            Frame = TabFrame;
            Layout = ContentLayout;
            Elements = {};
        };

        function TabButton.MouseButton1Click()
            if Outer.CurrentTab == Tab then return end;
            
            if Outer.CurrentTab then
                TweenService:Create(Outer.CurrentTab.Button.AccentBar, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play();
                Outer.CurrentTab.Button.TextColor3 = Library.FontColor;
                TweenService:Create(Outer.CurrentTab.Button, TweenInfo.new(0.2), {BackgroundColor3 = Library.MainColor}):Play();
                Outer.CurrentTab.Frame.Visible = false;
            end

            TweenService:Create(AccentBar, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play();
            TabButton.TextColor3 = Library.AccentColor;
            TweenService:Create(TabButton, TweenInfo.new(0.2), {BackgroundColor3 = Library.MainColor + Color3.new(0.1, 0.1, 0.1)}):Play();
            TabFrame.Visible = true;
            Outer.CurrentTab = Tab;

            RenderStepped:Wait();
            TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10);
        end;

        TabButton.MouseEnter:Connect(function()
            if Outer.CurrentTab ~= Tab then
                TweenService:Create(TabButton, TweenInfo.new(0.15), {BackgroundColor3 = Library.MainColor + Color3.new(0.05, 0.05, 0.05)}):Play();
            end
        end);
        
        TabButton.MouseLeave:Connect(function()
            if Outer.CurrentTab ~= Tab then
                TweenService:Create(TabButton, TweenInfo.new(0.15), {BackgroundColor3 = Library.MainColor}):Play();
            end
        end);
        
        if #Outer.Tabs == 0 then
            TabButton.MouseButton1Click();
        end;
        
        function Tab:Label(Text)
            local LabelFrame = Library:Create('Frame', {
                Name = "LabelFrame";
                Size = UDim2.new(1, 0, 0, 20);
                BackgroundTransparency = 1;
                Parent = TabFrame;
            });

            local Label = Library:Create('TextLabel', {
                Name = "Label";
                Text = Text;
                Font = Library.FONT;
                TextSize = Library.FONT_SIZE + 2;
                TextColor3 = Library.FontColor * Color3.new(0.8, 0.8, 0.8);
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                TextXAlignment = Enum.TextXAlignment.Left;
                Parent = LabelFrame;
            });
            
            local LabelElement = {
                Label = Label;
            };

            function LabelElement:SetText(NewText)
                Label.Text = NewText;
                RenderStepped:Wait();
                TabFrame.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10);
            end;

            table.insert(Tab.Elements, LabelFrame);
            return LabelElement;
        end;
        
        function Tab:Divider()
            local DividerFrame = Library:Create('Frame', {
                Name = "DividerFrame";
                Size = UDim2.new(1, 0, 0, 20);
                BackgroundTransparency = 1;
                Parent = TabFrame;
            });
            
            local Line = Library:Create('Frame', {
                Name = "Line";
                Size = UDim2.new(1, -10, 0, 1);
                Position = UDim2.new(0.5, 0, 0.5, 0);
                AnchorPoint = Vector2.new(0.5, 0.5);
                BackgroundColor3 = Library.OutlineColor;
                BackgroundTransparency = 0.5;
                Parent = DividerFrame;
            });

            table.insert(Tab.Elements, DividerFrame);
        end;

        function Tab:Toggle(Name, Default)
            local ToggleElement = {
                Value = Default or false;
                CallbackFunc = function() end;
            };
            Toggles[Name] = ToggleElement;

            local ToggleFrame = Library:Create('Frame', {
                Name = "Toggle_" .. Name:gsub(" ", "_");
                Size = UDim2.new(1, 0, 0, 30);
                BackgroundTransparency = 1;
                Parent = TabFrame;
            });

            local Label = Library:Create('TextLabel', {
                Name = "Label";
                Text = Name;
                Font = Library.FONT;
                TextSize = Library.FONT_SIZE;
                TextColor3 = Library.FontColor;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, -40, 1, 0);
                TextXAlignment = Enum.TextXAlignment.Left;
                Parent = ToggleFrame;
            });

            local IndicatorSize = 20;
            local Indicator = Library:Create('TextButton', {
                Name = "Indicator";
                Size = UDim2.new(0, IndicatorSize * 2, 0, IndicatorSize);
                Position = UDim2.new(1, -IndicatorSize * 2, 0.5, -IndicatorSize / 2);
                BackgroundColor3 = Library.OutlineColor;
                BackgroundTransparency = 0;
                Text = "";
                Parent = ToggleFrame;
            });
            Library:Style(Indicator, IndicatorSize / 2, Library.OutlineColor, true, 0);

            local ToggleCircle = Library:Create('Frame', {
                Name = "Circle";
                Size = UDim2.new(0, IndicatorSize * 0.8, 0, IndicatorSize * 0.8);
                Position = UDim2.new(0, IndicatorSize * 0.1, 0.5, -IndicatorSize * 0.4);
                BackgroundColor3 = Library.FontColor;
                Parent = Indicator;
            });
            Library:Create('UICorner', {CornerRadius = UDim.new(1, 0), Parent = ToggleCircle});

            local function UpdateVisuals(IsActive)
                local IndicatorColor = IsActive and Library.AccentColor or Library.OutlineColor;
                local Position = IsActive and UDim2.new(1, -IndicatorSize * 0.1 - ToggleCircle.Size.Offset.X, 0.5, -IndicatorSize * 0.4)
                                          or UDim2.new(0, IndicatorSize * 0.1, 0.5, -IndicatorSize * 0.4);

                TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = IndicatorColor}):Play();
                TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = Position}):Play();
                ToggleCircle.BackgroundColor3 = IsActive and Color3.new(1, 1, 1) or Library.FontColor;
            end;
            
            function ToggleElement:SetValue(NewState)
                if NewState ~= self.Value then
                    self.Value = NewState;
                    UpdateVisuals(NewState);
                    self.CallbackFunc(NewState);
                end
            end;

            function ToggleElement:OnChanged(Func)
                self.CallbackFunc = Func;
            end;

            Indicator.MouseButton1Click:Connect(function()
                ToggleElement:SetValue(not ToggleElement.Value);
            end);

            UpdateVisuals(ToggleElement.Value);
            table.insert(Tab.Elements, ToggleFrame);
            
            return ToggleElement;
        end;

        function Tab:Button(Name, Callback)
            local Button = Library:Create('TextButton', {
                Name = "Button_" .. Name:gsub(" ", "_");
                Text = Name;
                Font = Library.FONT;
                TextSize = Library.FONT_SIZE;
                TextColor3 = Color3.new(1, 1, 1);
                BackgroundColor3 = Library.AccentColor;
                Size = UDim2.new(1, 0, 0, 35);
                Parent = TabFrame;
            });
            Library:Style(Button, Library.CORNER_RADIUS - 2, Library.AccentColor, true, 0);

            Button.MouseEnter:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Library.AccentColor * Color3.new(0.8, 0.8, 0.8)}):Play();
            end);
            Button.MouseLeave:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Library.AccentColor}):Play();
            end);
            
            Button.MouseButton1Click:Connect(Callback or function() end);

            table.insert(Tab.Elements, Button);
            
            local ButtonElement = {
                Button = Button
            };
            return ButtonElement;
        end;
        
        function Tab:Slider(Name, Min, Max, Default, Step)
            local SliderElement = {
                Value = Default or Min;
                CallbackFunc = function() end;
            };
            Options[Name] = SliderElement;
            Min, Max, Step = Min or 0, Max or 100, Step or 1;

            local SliderFrame = Library:Create('Frame', {
                Name = "Slider_" .. Name:gsub(" ", "_");
                Size = UDim2.new(1, 0, 0, 50);
                BackgroundTransparency = 1;
                Parent = TabFrame;
            });

            local Label = Library:Create('TextLabel', {
                Name = "Label";
                Text = string.format("%s: %.2f", Name, SliderElement.Value);
                Font = Library.FONT;
                TextSize = Library.FONT_SIZE;
                TextColor3 = Library.FontColor;
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0.5, 0);
                TextXAlignment = Enum.TextXAlignment.Left;
                Parent = SliderFrame;
            });

            local Track = Library:Create('Frame', {
                Name = "Track";
                Size = UDim2.new(1, 0, 0, 8);
                Position = UDim2.new(0, 0, 0.6, 0);
                BackgroundColor3 = Library.OutlineColor;
                BackgroundTransparency = 0;
                Parent = SliderFrame;
            });
            Library:Style(Track, 4, Library.OutlineColor, true, 0);
            
            local Fill = Library:Create('Frame', {
                Name = "Fill";
                Size = UDim2.new(0, 0, 1, 0);
                Position = UDim2.new(0, 0, 0, 0);
                BackgroundColor3 = Library.AccentColor;
                Parent = Track;
            });
            Library:Create('UICorner', {CornerRadius = UDim.new(1, 0), Parent = Fill});
            
            local Knob = Library:Create('Frame', {
                Name = "Knob";
                Size = UDim2.new(0, 16, 0, 16);
                Position = UDim2.new(0, -8, 0.5, -8);
                BackgroundColor3 = Library.AccentColor;
                Parent = Track;
                ZIndex = 2;
            });
            Library:Create('UICorner', {CornerRadius = UDim.new(1, 0), Parent = Knob});
            
            local IsDragging = false;
            
            local function UpdateVisuals(Value)
                local FillRatio = (Value - Min) / (Max - Min);
                local TrackWidth = Track.AbsoluteSize.X;
                local KnobOffset = FillRatio * TrackWidth;
                
                Fill.Size = UDim2.new(0, KnobOffset, 1, 0);
                Knob.Position = UDim2.new(0, KnobOffset - 8, 0.5, -8);
                Label.Text = string.format("%s: %.2f", Name, Value);
            end;

            local function UpdateSlider(Input)
                local TrackPos = Track.AbsolutePosition.X;
                local TrackWidth = Track.AbsoluteSize.X;
                local MouseX = Input.Position.X;
                
                local Ratio = math.min(1, math.max(0, (MouseX - TrackPos) / TrackWidth));
                local Value = Min + Ratio * (Max - Min);
                
                if Step > 0 then
                    Value = math.floor((Value / Step) + 0.5) * Step;
                end;
                Value = math.min(Max, math.max(Min, Value));
                
                if Value ~= SliderElement.Value then
                    SliderElement.Value = Value;
                    UpdateVisuals(Value);
                    SliderElement.CallbackFunc(Value);
                end
            end;
            
            function SliderElement:SetValue(NewValue)
                local ClampedValue = math.min(Max, math.max(Min, NewValue));
                
                if Step > 0 then
                    ClampedValue = math.floor((ClampedValue / Step) + 0.5) * Step;
                end;
                
                if ClampedValue ~= self.Value then
                    self.Value = ClampedValue;
                    UpdateVisuals(ClampedValue);
                    self.CallbackFunc(ClampedValue);
                end
            end;

            function SliderElement:OnChanged(Func)
                self.CallbackFunc = Func;
            end;

            Track.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    IsDragging = true;
                    UpdateSlider(Input);
                end
            end);

            Knob.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    IsDragging = true;
                    Knob.ZIndex = 3;
                end
            end);

            InputService.InputChanged:Connect(function(Input)
                if IsDragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(Input);
                end
            end);

            InputService.InputEnded:Connect(function(Input)
                if IsDragging and (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
                    IsDragging = false;
                    Knob.ZIndex = 2;
                end
            end);
            
            UpdateVisuals(SliderElement.Value);

            table.insert(Tab.Elements, SliderFrame);
            
            return SliderElement;
        end;

        Outer.Tabs[Name] = Tab;
        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });

    InputService.InputBegan:Connect(function(Input, Processed)
        if Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            Outer.Visible = not Outer.Visible;
            ModalElement.Modal = Outer.Visible;

            local oIcon = Mouse.Icon;
            local State = InputService.MouseIconEnabled;

            if Outer.Visible then
                InputService.MouseIconEnabled = false;

                local Cursor = Drawing.new('Triangle');
                Cursor.Thickness = 1;
                Cursor.Filled = true;

                RenderStepped:Connect(function()
                    if not Outer.Visible then
                        Cursor.Visible = false;
                        return;
                    end
                    local mPos = workspace.CurrentCamera:WorldToViewportPoint(Mouse.Hit.p);

                    Cursor.Color = Library.AccentColor;
                    Cursor.PointA = Vector2.new(mPos.X, mPos.Y);
                    Cursor.PointB = Vector2.new(mPos.X, mPos.Y) + Vector2.new(6, 14);
                    Cursor.PointC = Vector2.new(mPos.X, mPos.Y) + Vector2.new(-6, 14);
                    Cursor.Visible = true;
                end);
            else
                InputService.MouseIconEnabled = true;
                local Cursor = Drawing.new('Triangle');
                Cursor.Visible = false;
            end
        end
    end);
    
    Outer.Position = UDim2.new(0.5, -Outer.Size.Offset.X / 2, 0.5, -Outer.Size.Offset.Y / 2);

    return Window;
end;

getgenv().Library = Library;
getgenv().Linoria = Library;
