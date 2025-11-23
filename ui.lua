local Library = {}
local Players = game:GetService("Players")

local LocalPlayer = nil
repeat
    LocalPlayer = Players.LocalPlayer
    task.wait(0.1) 
until LocalPlayer ~= nil

local PlayerGui = LocalPlayer.PlayerGui 
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService") 
local task = task

local function cleanName(text)
    local s = tostring(text or "")
    local cleaned = {}
    for i = 1, #s do
        local char = s:sub(i, i)
        if char ~= " " and char ~= "\t" and char ~= "\n" and char ~= "\r" then
            table.insert(cleaned, char)
        end
    end
    return table.concat(cleaned)
end

local function safeFormat(formatString, ...)
    local arg1 = select(1, ...)
    if type(arg1) == "number" then
        return tostring(math.floor(arg1 + 0.5))
    end
    return tostring(arg1)
end

local THEME = {
    Background = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(80, 150, 255),
    Header = Color3.fromRGB(40, 40, 40),
    Text = Color3.fromRGB(220, 220, 220),
    ControlBg = Color3.fromRGB(45, 45, 45),
    ControlHover = Color3.fromRGB(60, 60, 60),
    ToastBg = Color3.fromRGB(20, 20, 20),
    WindowSize = Vector2.new(700, 550), 
    HeaderHeight = 30,
    Padding = 8,
    ControlHeight = 22,
    CornerRadius = UDim.new(0, 5),
    SectionColumnCount = 2,
    SectionContentPadding = 8,
    ControlPadding = 2,
    SectionHeaderHeight = 15,
}

local function CreateBaseFrame(parent, name, size, position, color, radius)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position or UDim2.fromScale(0, 0)
    frame.BackgroundColor3 = color or THEME.Background
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or THEME.CornerRadius
    corner.Parent = frame
    
    frame.Parent = parent
    return frame
end

local function CreateButton(parent, text, size, position, color, radius)
    local button = Instance.new("TextButton")
    button.Name = cleanName(text)
    button.Text = text
    button.Size = size
    button.Position = position or UDim2.fromScale(0, 0)
    button.BackgroundColor3 = color or THEME.ControlBg
    button.TextColor3 = THEME.Text
    button.Font = Enum.Font.SourceSans
    button.TextSize = 14
    button.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or THEME.CornerRadius
    corner.Parent = button

    local defaultColor = color or THEME.ControlBg

    button.MouseEnter:Connect(function() button.BackgroundColor3 = THEME.ControlHover end)
    button.MouseLeave:Connect(function() button.BackgroundColor3 = defaultColor end)

    button.Parent = parent
    return button
end

local function BaseComponent(Parent, Options)
    local self = {}
    self.Options = Options or {}
    self.Children = {}
    self.Parent = Parent
    self.Instance = nil 
    
    function self:AddChild(component)
        table.insert(self.Children, component)
        return component
    end
    
    return self
end

function Library.init(Title)
    local Window = BaseComponent(Library, {Text = Title})
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LibGUI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui

    local W = THEME.WindowSize
    local WindowFrame = CreateBaseFrame(ScreenGui, cleanName(Title) .. "Window", UDim2.new(0, W.X, 0, W.Y), UDim2.new(0.5, -W.X/2, 0.5, -W.Y/2), THEME.Background)
    WindowFrame.Active = true 
    Window.Instance = WindowFrame

    local Header = CreateBaseFrame(WindowFrame, "Header", UDim2.new(1, 0, 0, THEME.HeaderHeight), nil, THEME.Header)
    Header.Active = true
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = Title
    TitleLabel.Size = UDim2.new(1, -10, 1, 0)
    TitleLabel.Position = UDim2.new(0, 5, 0, 0)
    TitleLabel.TextColor3 = THEME.Text
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 18
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local ContentFrame = CreateBaseFrame(WindowFrame, "Content", UDim2.new(1, 0, 1, -THEME.HeaderHeight), UDim2.new(0, 0, 0, THEME.HeaderHeight), THEME.Background)
    ContentFrame.BackgroundTransparency = 1
    Window.ContentFrame = ContentFrame
    
    local TabBar = CreateBaseFrame(ContentFrame, "TabBar", UDim2.new(0.15, 0, 1, 0), UDim2.fromScale(0, 0), THEME.Header)
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.FillDirection = Enum.FillDirection.Vertical
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, THEME.Padding)
    TabListLayout.Parent = TabBar

    local PageContainer = CreateBaseFrame(ContentFrame, "PageContainer", UDim2.new(0.85, 0, 1, 0), UDim2.fromScale(0.15, 0), THEME.Background)
    PageContainer.BackgroundTransparency = 1
    Window.PageContainer = PageContainer
    
    local currentDropdownList = nil
    Window.CloseDropdown = function()
        if currentDropdownList then
            currentDropdownList.Visible = false 
            currentDropdownList.Position = UDim2.new(0, -9999, 0, -9999)
            currentDropdownList = nil
        end
    end

    local Dragging = false
    local DragOffset = Vector2.zero
    
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragOffset = Vector2.new(input.Position.X, input.Position.Y) - WindowFrame.AbsolutePosition
            Header.LayoutOrder = 1 
        end
    end)
    
    Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if Dragging then
            local mouse = Players.LocalPlayer:GetMouse()
            WindowFrame.Position = UDim2.fromOffset(mouse.X - DragOffset.X, mouse.Y - DragOffset.Y)
        end
    end)

    Window.addTab = function(Name)
        local Tab = BaseComponent(Window, {Text = Name})
        
        Tab.ColumnHeights = {[0] = 0, [1] = 0}
        local W = THEME.WindowSize 
        Tab.MaxColumnHeight = W.Y - THEME.HeaderHeight - THEME.Padding * 2

        local TabButton = CreateButton(TabBar, Name, UDim2.new(1, 0, 0, 30), nil, THEME.Header)
        TabButton.TextXAlignment = Enum.TextXAlignment.Center
        Tab.Instance = TabButton
        
        local PageScroll = Instance.new("ScrollingFrame")
        PageScroll.Name = Name .. "PageScroll"
        PageScroll.Size = UDim2.new(1, 0, 1, 0)
        PageScroll.CanvasSize = UDim2.new(0, 0, 0, 0) 
        PageScroll.BackgroundTransparency = 1
        PageScroll.ScrollBarThickness = 6
        PageScroll.Visible = false
        PageScroll.Parent = PageContainer
        Tab.PageScroll = PageScroll
        
        local PageFrame = CreateBaseFrame(PageScroll, Name .. "Page", UDim2.new(1, 0, 0, 0), nil, THEME.Background) 
        PageFrame.BackgroundTransparency = 1
        
        local ListLayout = Instance.new("UIListLayout")
        ListLayout.FillDirection = Enum.FillDirection.Vertical
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = PageFrame
        
        local SectionGridLayout = Instance.new("UIGridLayout")
        SectionGridLayout.Name = "SectionLayout"
        SectionGridLayout.CellPadding = UDim2.new(0, THEME.Padding/2, 0, THEME.Padding)
        SectionGridLayout.StartCorner = Enum.StartCorner.TopLeft
        SectionGridLayout.FillDirection = Enum.FillDirection.Horizontal
        SectionGridLayout.FillDirectionMaxCells = THEME.SectionColumnCount
        SectionGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        local CellScale = 1 / THEME.SectionColumnCount
        SectionGridLayout.CellSize = UDim2.new(CellScale, -THEME.Padding, 0, 1) 
        SectionGridLayout.Parent = PageFrame

        function Tab:Select()
            Window.CloseDropdown() 
            for _, childTab in ipairs(Window.Children) do
                if type(childTab) == "table" and childTab.PageScroll and childTab.Instance then 
                    childTab.PageScroll.Visible = false
                    childTab.Instance.BackgroundColor3 = THEME.Header
                end
            end
            Tab.PageScroll.Visible = true
            Tab.Instance.BackgroundColor3 = THEME.Accent
        end
        
        TabButton.MouseButton1Click:Connect(function() Tab:Select() end)

        Tab.addSection = function(SectionName, Side)
            local Section = BaseComponent(Tab, {Text = SectionName, Side = Side})
            
            local function calculateSectionHeight(controlCount)
                local totalContentHeight = THEME.SectionHeaderHeight + (controlCount * THEME.ControlHeight) + ((controlCount > 0 and controlCount - 1 or 0) * THEME.ControlPadding)
                return totalContentHeight + (2 * THEME.SectionContentPadding)
            end

            local controlCount = 0
            local columnKey = 0
            local columnLayoutOrder = 0
            
            if Side == "Right" then
                columnKey = 1
                columnLayoutOrder = 1
            else
                local assumedSectionHeight = calculateSectionHeight(1)
                local newLeftHeight = Tab.ColumnHeights[0] + assumedSectionHeight
                if newLeftHeight > Tab.MaxColumnHeight * 0.9 and Tab.ColumnHeights[1] < Tab.ColumnHeights[0] then
                    columnKey = 1
                    columnLayoutOrder = 1
                end
            end
            
            local SectionContainer = CreateBaseFrame(PageFrame, SectionName .. "SectionContainer", UDim2.new(1, 0, 0, 0), UDim2.fromScale(0, 0), THEME.Background)
            SectionContainer.BackgroundTransparency = 1
            SectionContainer.LayoutOrder = columnLayoutOrder
            
            local SectionFrame = CreateBaseFrame(SectionContainer, SectionName .. "Frame", UDim2.new(1, 0, 0, 100), nil, THEME.ControlBg)
            Section.Instance = SectionFrame
            
            local ControlContainer = CreateBaseFrame(SectionFrame, "ControlContainer", UDim2.new(1, -THEME.SectionContentPadding * 2, 1, -THEME.SectionContentPadding * 2), UDim2.new(0, THEME.SectionContentPadding, 0, THEME.SectionContentPadding), THEME.ControlBg)
            ControlContainer.BackgroundTransparency = 1
            
            local ControlLayout = Instance.new("UIListLayout")
            ControlLayout.FillDirection = Enum.FillDirection.Vertical
            ControlLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ControlLayout.Padding = UDim.new(0, THEME.ControlPadding) 
            ControlLayout.Parent = ControlContainer
            
            local TitleFrame = Instance.new("Frame")
            TitleFrame.Size = UDim2.new(1, 0, 0, THEME.SectionHeaderHeight)
            TitleFrame.BackgroundTransparency = 1
            TitleFrame.Parent = ControlContainer
            
            local SectionTitle = Instance.new("TextLabel")
            SectionTitle.Text = SectionName
            SectionTitle.Size = UDim2.new(1, 0, 1, 0)
            SectionTitle.TextColor3 = THEME.Accent
            SectionTitle.BackgroundTransparency = 1
            SectionTitle.Font = Enum.Font.SourceSansBold
            SectionTitle.TextSize = 14
            SectionTitle.Parent = TitleFrame
            
            Section.UIContainer = ControlContainer 

            local function CreateControlContainer(Type, Options)
                local Control = BaseComponent(Section, Options)
                local nameBase = Options.Text or ""
                local Container = CreateBaseFrame(ControlContainer, Type .. cleanName(nameBase), UDim2.new(1, 0, 0, THEME.ControlHeight), nil, THEME.ControlBg)
                Container.Name = Type .. "_" .. cleanName(nameBase)
                Container.BackgroundTransparency = 0
                Control.Instance = Container
                
                local TextLabel = Instance.new("TextLabel")
                TextLabel.Text = Options.Text or Type
                TextLabel.Size = UDim2.new(0.5, -5, 1, 0)
                TextLabel.Position = UDim2.new(0, THEME.Padding, 0, 0)
                TextLabel.TextColor3 = THEME.Text
                TextLabel.BackgroundTransparency = 1
                TextLabel.Font = Enum.Font.SourceSans
                TextLabel.TextSize = 13
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.Parent = Container
                
                Control.Label = TextLabel
                
                controlCount = controlCount + 1
                local newHeight = calculateSectionHeight(controlCount)
                SectionFrame.Size = UDim2.new(1, 0, 0, newHeight)
                Tab.ColumnHeights[columnKey] = Tab.ColumnHeights[columnKey] + THEME.ControlHeight + THEME.ControlPadding
                local maxColHeight = math.max(Tab.ColumnHeights[0], Tab.ColumnHeights[1]) + (THEME.SectionHeaderHeight + THEME.SectionContentPadding * 2) + THEME.Padding
                SectionGridLayout.CellSize = UDim2.new(CellScale, -THEME.Padding, 0, maxColHeight)

                return Control, Container
            end

            function Section.addCheck(Options)
                local Control, Container = CreateControlContainer("Check", Options)
                local IsChecked = Options.Default or false
                
                local CheckBox = CreateButton(Container, IsChecked and "✓" or "", UDim2.new(0, 20, 0, 18), UDim2.new(1, -25, 0.5, -9), THEME.Background, UDim.new(0, 3))
                CheckBox.TextSize = 16
                CheckBox.TextXAlignment = Enum.TextXAlignment.Center
                CheckBox.BorderColor3 = THEME.Accent
                CheckBox.BorderSizePixel = 1
                
                local function UpdateVisual()
                    CheckBox.BackgroundColor3 = IsChecked and THEME.Accent or THEME.Background
                    CheckBox.Text = IsChecked and "✓" or ""
                end
                
                UpdateVisual()

                CheckBox.MouseButton1Click:Connect(function()
                    IsChecked = not IsChecked
                    UpdateVisual()
                    if Options.Callback then Options.Callback(IsChecked) end
                end)
                
                return Control
            end

            function Section.addSlider(Options)
                local Control, Container = CreateControlContainer("Slider", Options)
                local Min = Options.Minimum or 0
                local Max = Options.Maximum or 100
                local Value = Options.Default or Min
                
                local SliderBar = CreateBaseFrame(Container, "SliderBar", UDim2.new(0.4, 0, 0, 4), UDim2.new(0.5, 0, 0.5, -2), THEME.Background)
                local Fill = CreateBaseFrame(SliderBar, "Fill", UDim2.new((Value - Min) / (Max - Min), 0, 1, 0), nil, THEME.Accent, UDim.new(0, 0))
                local Handle = CreateBaseFrame(SliderBar, "Handle", UDim2.new(0, 10, 0, 10), UDim2.fromScale(0, 0.5), THEME.Accent)
                Handle.Position = UDim2.new((Value - Min) / (Max - Min), -5, 0.5, -5)
                Handle.ZIndex = 2
                Handle.Active = true
                
                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Size = UDim2.new(0.15, 0, 1, 0)
                ValueLabel.Position = UDim2.new(0.8, 0, 0, 0)
                ValueLabel.TextColor3 = THEME.Accent
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Font = Enum.Font.SourceSans
                ValueLabel.TextSize = 13
                ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                ValueLabel.Parent = Container

                local function UpdateValue(newValue)
                    Value = math.min(Max, math.max(Min, newValue))
                    local ratio = (Value - Min) / (Max - Min)
                    Fill.Size = UDim2.new(ratio, 0, 1, 0)
                    Handle.Position = UDim2.new(ratio, -5, 0.5, -5)
                    ValueLabel.Text = safeFormat("%.0f%s", Value, Options.Postfix or "")
                    if Options.Callback then Options.Callback(Value) end
                end

                local dragging = false
                Handle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        Handle.ZIndex = 3
                    end
                end)

                Handle.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                        Handle.ZIndex = 2
                    end
                end)

                Container.MouseMoved:Connect(function(x, y)
                    if dragging then
                        local xPos = math.min(math.max(x - SliderBar.AbsolutePosition.X, 0), SliderBar.AbsoluteSize.X)
                        local ratio = xPos / SliderBar.AbsoluteSize.X
                        local newValue = Min + ratio * (Max - Min)
                        UpdateValue(newValue)
                    end
                end)
                
                UpdateValue(Value) 
                
                Control.SliderBar = SliderBar
                Control.ValueLabel = ValueLabel
                
                return Control
            end
            
            return Tab:AddChild(Section)
        end
        
        Window:AddChild(Tab)
        
        if #Window.Children == 1 then
            task.defer(function()
                Window.Children[1]:Select()
            end)
        end
        
        return Tab
    end

    local ToastQueue = {} 
    local ToastTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local ToastVisible = false

    function Library:Toast(Message, Duration)
        table.insert(ToastQueue, {Message = Message, Duration = Duration or 3}) 
        
        if ToastVisible then return end
        
        local function ShowNextToast()
            if #ToastQueue == 0 then
                ToastVisible = false
                return
            end
            
            ToastVisible = true
            local ToastData = table.remove(ToastQueue, 1)
            
            local ToastFrame = CreateBaseFrame(PlayerGui, "Toast", UDim2.new(0, 300, 0, 50), UDim2.new(0.5, -150, 1, 60), THEME.ToastBg, UDim.new(0, 8))
            ToastFrame.ClipsDescendants = true
            ToastFrame.BackgroundTransparency = 0.2
            ToastFrame.BorderSizePixel = 1
            ToastFrame.BorderColor3 = THEME.Accent
            ToastFrame.ZIndex = 6 

            
            local ToastLabel = Instance.new("TextLabel")
            ToastLabel.Text = ToastData.Message
            ToastLabel.Size = UDim2.new(1, -20, 1, -20)
            ToastLabel.Position = UDim2.new(0, 10, 0, 10)
            ToastLabel.TextColor3 = THEME.Text
            ToastLabel.BackgroundTransparency = 1
            ToastLabel.TextSize = 14
            ToastLabel.Font = Enum.Font.SourceSans
            ToastLabel.Parent = ToastFrame
            
            local StartPos = UDim2.new(0.5, -150, 1, 60)
            local EndPos = UDim2.new(0.5, -150, 1, -60) 
            
            local TweenIn = TweenService:Create(ToastFrame, ToastTweenInfo, {Position = EndPos})
            TweenIn:Play()
            TweenIn.Completed:Wait()
            
            task.wait(ToastData.Duration)
            
            local TweenOut = TweenService:Create(ToastFrame, ToastTweenInfo, {Position = StartPos, BackgroundTransparency = 1})
            TweenOut:Play()
            TweenOut.Completed:Wait()
            
            ToastFrame:Destroy()
            ShowNextToast()
        end
        
        if not ToastVisible then
            ShowNextToast()
        end
    end

    return Window
end

return Library
