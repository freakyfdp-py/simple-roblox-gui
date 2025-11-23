--[[
    UI Library ModuleScript - Dynamic Layout & ColorPicker
    
    This version implements:
    1. Full RGB/A Color Picker using four separate sliders (R, G, B, A).
    2. Dynamic Section Sizing: Sections now automatically size based on the number of controls they contain.
    3. Two-Column Overflow Logic: Sections are placed in the left column first, but if adding a new section would exceed the current page height, it's moved to the right column (`LayoutOrder = 1`).
    4. **FIXES:** - Resolved the nil value error during initial tab selection using task.defer.
        - **Critical Fix 1 (LocalPlayer):** Used a 'repeat until' loop for LocalPlayer check.
        - **Critical Fix 2 (PlayerGui):** Removed the redundant 'WaitForChild' on PlayerGui, as this often causes the *second* infinite yield in certain execution environments.
--]]

local Library = {}
local Players = game:GetService("Players")

-- *** FIX 1: Ensure LocalPlayer exists. This loop replaces WaitForChild. ***
local LocalPlayer = nil
repeat
    LocalPlayer = Players.LocalPlayer
    -- Use a small task.wait() to yield control and prevent high CPU usage
    task.wait(0.1) 
until LocalPlayer ~= nil
-- *** END FIX 1 ***

-- *** FIX 2: PlayerGui should be accessed directly after LocalPlayer is found. ***
-- Using :WaitForChild("PlayerGui") here often causes the second infinite yield.
local PlayerGui = LocalPlayer.PlayerGui 
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService") 
local task = task

-- --- THEME & CONSTANTS ---
local THEME = {
    -- Colors
    Background = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(80, 150, 255),
    Header = Color3.fromRGB(40, 40, 40),
    Text = Color3.fromRGB(220, 220, 220),
    ControlBg = Color3.fromRGB(45, 45, 45),
    ControlHover = Color3.fromRGB(60, 60, 60),
    ToastBg = Color3.fromRGB(20, 20, 20),
    
    -- Sizes
    WindowSize = Vector2.new(700, 550), 
    HeaderHeight = 30,
    Padding = 8,
    ControlHeight = 22,
    CornerRadius = UDim.new(0, 5),
    
    -- Layout
    SectionColumnCount = 2,
    SectionContentPadding = 8,
    ControlPadding = 2, -- Padding between controls (used in list layout)
    SectionHeaderHeight = 15, -- Height of the section title label
}

-- --- HELPER FUNCTIONS ---

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
    button.Name = text:gsub("%s", "")
    button.Text = text
    button.Size = size
    button.Position = position or UDim2.fromScale(0, 0)
    button.BackgroundColor3 = color or THEME.ControlBg
    button.TextColor3 = THEME.Text
    button.Font = Enum.Font.SourceSans
    button.TextSize = 14
    button.BorderSizePixel = 0
    
    -- UICorner is the required child instance
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or THEME.CornerRadius
    corner.Parent = button

    local defaultColor = color or THEME.ControlBg

    button.MouseEnter:Connect(function() button.BackgroundColor3 = THEME.ControlHover end)
    button.MouseLeave:Connect(function() button.BackgroundColor3 = defaultColor end)

    button.Parent = parent
    return button
end

-- --- 1. BASE COMPONENT CLASS (Internal) ---

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

-- --- 2. WINDOW (The Entry Point) ---

function Library.init(Title)
    local Window = BaseComponent(Library, {Text = Title})
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LibGUI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui

    -- Main Window Frame
    local W = THEME.WindowSize
    local WindowFrame = CreateBaseFrame(
        ScreenGui, Title:gsub("%s", "") .. "Window",
        UDim2.new(0, W.X, 0, W.Y), 
        UDim2.new(0.5, -W.X/2, 0.5, -W.Y/2),
        THEME.Background
    )
    WindowFrame.Active = true 
    Window.Instance = WindowFrame

    -- Header Bar (for dragging)
    local Header = CreateBaseFrame(WindowFrame, "Header", 
        UDim2.new(1, 0, 0, THEME.HeaderHeight), nil, THEME.Header)
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

    -- Content Area (Wrapper for TabBar and Pages)
    local ContentFrame = CreateBaseFrame(WindowFrame, "Content",
        UDim2.new(1, 0, 1, -THEME.HeaderHeight), 
        UDim2.new(0, 0, 0, THEME.HeaderHeight),
        THEME.Background
    )
    Window.ContentFrame = ContentFrame
    
    -- Tab Bar Area
    local TabBar = CreateBaseFrame(ContentFrame, "TabBar",
        UDim2.new(0.15, 0, 1, 0), UDim2.fromScale(0, 0), THEME.Header)
    
    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.FillDirection = Enum.FillDirection.Vertical
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, THEME.Padding)
    TabListLayout.Parent = TabBar

    -- Main Page Content Area (Wrapper for pages)
    local PageContainer = CreateBaseFrame(ContentFrame, "PageContainer",
        UDim2.new(0.85, 0, 1, 0), UDim2.fromScale(0.15, 0), THEME.Background)
    PageContainer.BackgroundTransparency = 1
    Window.PageContainer = PageContainer
    
    -- --- GLOBAL UTILITIES ---
    local currentDropdownList = nil -- Global reference to the currently open list frame
    
    -- Global function to close any currently open dropdown
    Window.CloseDropdown = function()
        if currentDropdownList then
            currentDropdownList.Visible = false 
            currentDropdownList.Position = UDim2.new(0, -9999, 0, -9999) -- Failsafe move
            currentDropdownList = nil
        end
    end
    -- End of Global Utilities

    -- Dragging Logic
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
            WindowFrame.Position = UDim2.fromOffset(
                mouse.X - DragOffset.X,
                mouse.Y - DragOffset.Y
            )
        end
    end)

    -- --- TAB METHOD ---
    
    Window.addTab = function(Name)
        local Tab = BaseComponent(Window, {Text = Name})
        
        -- Tracking for dynamic two-column layout
        Tab.ColumnHeights = {
            [0] = 0, -- Left column height
            [1] = 0  -- Right column height
        }
        
        -- Maximum height for a single column (ContentFrame Height - Padding)
        local W = THEME.WindowSize 
        Tab.MaxColumnHeight = W.Y - THEME.HeaderHeight - THEME.Padding * 2

        local TabButton = CreateButton(TabBar, Name, 
            UDim2.new(1, 0, 0, 30), nil, THEME.Header)
        TabButton.TextXAlignment = Enum.TextXAlignment.Center
        Tab.Instance = TabButton
        
        -- Page Scroll Frame 
        local PageScroll = Instance.new("ScrollingFrame")
        PageScroll.Name = Name .. "PageScroll"
        PageScroll.Size = UDim2.new(1, 0, 1, 0)
        PageScroll.CanvasSize = UDim2.new(0, 0, 0, 0) 
        PageScroll.BackgroundTransparency = 1
        PageScroll.ScrollBarThickness = 6
        PageScroll.Visible = false
        PageScroll.Parent = PageContainer
        Tab.PageScroll = PageScroll
        
        -- Page Frame (Container for Sections, inside the scroll frame)
        local PageFrame = CreateBaseFrame(PageScroll, Name .. "Page", 
            UDim2.new(1, 0, 0, 0), nil, THEME.Background) 
        PageFrame.BackgroundTransparency = 1
        
        -- Main layout for PageFrame (needed to hold the UIGridLayout which handles columns)
        local ListLayout = Instance.new("UIListLayout")
        ListLayout.FillDirection = Enum.FillDirection.Vertical
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = PageFrame
        
        -- This is the layout that controls the 2-column flow
        local SectionGridLayout = Instance.new("UIGridLayout")
        SectionGridLayout.Name = "SectionLayout"
        SectionGridLayout.CellPadding = UDim2.new(0, THEME.Padding/2, 0, THEME.Padding)
        SectionGridLayout.StartCorner = Enum.StartCorner.TopLeft
        SectionGridLayout.FillDirection = Enum.FillDirection.Horizontal
        SectionGridLayout.FillDirectionMaxCells = THEME.SectionColumnCount
        SectionGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local CellScale = 1 / THEME.SectionColumnCount
        -- Cell height is dynamic, initialized to a small value
        SectionGridLayout.CellSize = UDim2.new(CellScale, -THEME.Padding, 0, 1) 
        SectionGridLayout.Parent = PageFrame

        -- Selection Logic setup... 
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
        
        TabButton.MouseButton1Click:Connect(function()
            Tab:Select()
        end)

        -- --- SECTION METHOD ---
        
        Tab.addSection = function(SectionName, Side)
            local Section = BaseComponent(Tab, {Text = SectionName, Side = Side})
            
            -- Function to calculate section height based on control count (pre-insertion)
            local function calculateSectionHeight(controlCount)
                -- 15: Title height (SectionHeaderHeight)
                -- 2 * THEME.SectionContentPadding: Top/Bottom Inner Padding
                -- controlCount * THEME.ControlHeight: total control box height
                -- (controlCount > 0 and controlCount - 1 or 0) * THEME.ControlPadding: total padding between controls
                
                local totalContentHeight = 
                    THEME.SectionHeaderHeight + 
                    (controlCount * THEME.ControlHeight) + 
                    ((controlCount > 0 and controlCount - 1 or 0) * THEME.ControlPadding)

                return totalContentHeight + (2 * THEME.SectionContentPadding)
            end

            -- Section Controls Counter (incremented by Control Methods)
            local controlCount = 0
            
            -- Determine Section Placement (Left=0, Right=1)
            local columnKey = 0 -- Default to Left Column
            local columnLayoutOrder = 0 -- Default to Left Column (first in Grid)
            
            -- If Side is explicitly set, use it.
            if Side == "Right" then
                columnKey = 1
                columnLayoutOrder = 1
            else
                -- Check for automatic overflow placement
                local assumedSectionHeight = calculateSectionHeight(1) -- Start with height of 1 control
                local newLeftHeight = Tab.ColumnHeights[0] + assumedSectionHeight
                
                -- Check if Left column is already getting full and Right is emptier
                if newLeftHeight > Tab.MaxColumnHeight * 0.9 and Tab.ColumnHeights[1] < Tab.ColumnHeights[0] then
                    columnKey = 1
                    columnLayoutOrder = 1
                end
            end
            
            -- Section Container
            local SectionContainer = CreateBaseFrame(PageFrame, SectionName .. "SectionContainer",
                UDim2.new(1, 0, 0, 0), UDim2.fromScale(0, 0), THEME.Background)
            SectionContainer.BackgroundTransparency = 1
            SectionContainer.LayoutOrder = columnLayoutOrder -- Set to 0 (left) or 1 (right)
            
            -- The actual Section Frame (Background Box)
            local SectionFrame = CreateBaseFrame(SectionContainer, SectionName .. "Frame",
                UDim2.new(1, 0, 0, 100), nil, THEME.ControlBg) -- Initial height is dummy
            Section.Instance = SectionFrame
            
            -- Inner padding frame for controls
            local ControlContainer = CreateBaseFrame(SectionFrame, "ControlContainer",
                UDim2.new(1, -THEME.SectionContentPadding * 2, 1, -THEME.SectionContentPadding * 2), 
                UDim2.new(0, THEME.SectionContentPadding, 0, THEME.SectionContentPadding),
                THEME.ControlBg)
            ControlContainer.BackgroundTransparency = 1
            
            -- ListLayout for controls
            local ControlLayout = Instance.new("UIListLayout")
            ControlLayout.FillDirection = Enum.FillDirection.Vertical
            ControlLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ControlLayout.Padding = UDim.new(0, THEME.ControlPadding) 
            ControlLayout.Parent = ControlContainer
            
            -- Title Frame (15px)
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

            -- Helper function to create a basic control component container
            local function CreateControlContainer(Type, Options)
                local Control = BaseComponent(Section, Options)
                
                local nameBase = Options.Text or ""
                
                local Container = CreateBaseFrame(ControlContainer, Type .. nameBase:gsub("%s", ""),
                    UDim2.new(1, 0, 0, THEME.ControlHeight), nil, THEME.ControlBg)
                Container.Name = Type .. "_" .. nameBase:gsub("%s", "")
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
                
                -- Update height counter
                controlCount = controlCount + 1
                local newHeight = calculateSectionHeight(controlCount)
                
                -- Adjust SectionFrame size and update Tab height tracking
                SectionFrame.Size = UDim2.new(1, 0, 0, newHeight)
                -- We only use THEME.ControlHeight + THEME.ControlPadding for tracking column height
                Tab.ColumnHeights[columnKey] = Tab.ColumnHeights[columnKey] + THEME.ControlHeight + THEME.ControlPadding
                
                -- Update UIGridLayout CellSize to fit the longest column so far
                local maxColHeight = math.max(Tab.ColumnHeights[0], Tab.ColumnHeights[1]) + (THEME.SectionHeaderHeight + THEME.SectionContentPadding * 2) + THEME.Padding
                SectionGridLayout.CellSize = UDim2.new(CellScale, -THEME.Padding, 0, maxColHeight)

                return Control, Container
            end

            -- --- 4. CONTROL METHODS ---
            
            -- Checkbox 
            function Section.addCheck(Options)
                -- controlCount is incremented inside CreateControlContainer
                local Control, Container = CreateControlContainer("Check", Options)
                local IsChecked = Options.Default or false
                
                local CheckBox = CreateButton(Container, IsChecked and "✓" or "",
                    UDim2.new(0, 20, 0, 18), UDim2.new(1, -25, 0.5, -9), THEME.Background, UDim.new(0, 3))
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

            -- Slider (Unchanged logic)
            function Section.addSlider(Options)
                -- controlCount is incremented inside CreateControlContainer
                local Control, Container = CreateControlContainer("Slider", Options)
                
                local Min = Options.Minimum or 0
                local Max = Options.Maximum or 100
                local Value = Options.Default or Min
                
                local SliderBar = CreateBaseFrame(Container, "SliderBar", 
                    UDim2.new(0.4, 0, 0, 4), UDim2.new(0.5, 0, 0.5, -2), THEME.Background)
                
                local Fill = CreateBaseFrame(SliderBar, "Fill", 
                    UDim2.new((Value - Min) / (Max - Min), 0, 1, 0), nil, THEME.Accent, UDim.new(0, 0))
                
                local Handle = CreateBaseFrame(SliderBar, "Handle",
                    UDim2.new(0, 10, 0, 10), UDim2.fromScale(0, 0.5), THEME.Accent)
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
                    ValueLabel.Text = string.format("%.0f%s", Value, Options.Postfix or "")
                    
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
            
            -- Dropdown 
            function Section.addDropdown(Options)
                -- controlCount is incremented inside CreateControlContainer
                local Control, Container = CreateControlContainer("Dropdown", Options)
                
                local CurrentSelection = Options.List and Options.List[1] or "None"
                
                local DropdownButton = CreateButton(Container, CurrentSelection,
                    UDim2.new(0.4, 0, 1, 0), UDim2.new(0.5, 0, 0, 0), THEME.Background)
                
                -- Dropdown list parented to the ScreenGui for true overlay
                local ListFrame = CreateBaseFrame(ScreenGui, "DropdownList",
                    UDim2.new(0, 0, 0, 0), UDim2.fromScale(0, 0), THEME.ControlBg)
                ListFrame.BackgroundTransparency = 0
                ListFrame.Visible = false
                ListFrame.ZIndex = 5 
                
                local ListLayout = Instance.new("UIListLayout")
                ListLayout.FillDirection = Enum.FillDirection.Vertical
                ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                ListLayout.Parent = ListFrame
                
                local function OpenList()
                    local absPos = DropdownButton.AbsolutePosition
                    local absSize = DropdownButton.AbsoluteSize
                    
                    if currentDropdownList == ListFrame and ListFrame.Visible then
                        Window.CloseDropdown()
                    else
                        Window.CloseDropdown()
                        currentDropdownList = ListFrame
                        ListFrame.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y)
                        ListFrame.Size = UDim2.new(0, absSize.X, 0, #Options.List * THEME.ControlHeight)
                        ListFrame.Visible = true
                    end
                end

                DropdownButton.MouseButton1Click:Connect(OpenList)
                
                local function SelectOption(option)
                    CurrentSelection = option
                    DropdownButton.Text = option
                    Window.CloseDropdown() 
                    if Options.Callback then Options.Callback(option) end
                end

                for i, option in ipairs(Options.List) do
                    local optionButton = CreateButton(ListFrame, option, 
                        UDim2.new(1, 0, 0, THEME.ControlHeight), nil, THEME.ControlBg)
                    optionButton.MouseEnter:Connect(function() optionButton.BackgroundColor3 = THEME.ControlHover end)
                    optionButton.MouseLeave:Connect(function() optionButton.BackgroundColor3 = THEME.ControlBg end)
                    optionButton.TextXAlignment = Enum.TextXAlignment.Left
                    optionButton.ZIndex = 5
                    
                    optionButton.MouseButton1Click:Connect(function()
                        SelectOption(option)
                    end)
                end
                
                return Control
            end
            
            -- Text Input 
            function Section.addInput(Options)
                -- controlCount is incremented inside CreateControlContainer
                local Control, Container = CreateControlContainer("Input", Options)
                
                local TextBox = Instance.new("TextBox")
                TextBox.Name = "InputBox"
                TextBox.Size = UDim2.new(0.4, 0, 1, 0)
                TextBox.Position = UDim2.new(0.5, 0, 0, 0)
                TextBox.Text = Options.Default or ""
                TextBox.PlaceholderText = Options.Placeholder or ""
                TextBox.TextColor3 = THEME.Text
                TextBox.BackgroundColor3 = THEME.Background
                TextBox.Font = Enum.Font.SourceSans
                TextBox.TextSize = 13
                TextBox.BorderSizePixel = 0
                TextBox.Parent = Container
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = THEME.CornerRadius
                corner.Parent = TextBox

                TextBox.FocusLost:Connect(function(enterPressed)
                    if enterPressed or Options.ContinuousUpdate then
                        if Options.Callback then Options.Callback(TextBox.Text) end
                    end
                end)
                
                return Control
            end

            -- Full RGB/A Color Picker 
            function Section.addColorPicker(Options)
                -- Local references to the controls we are about to create
                local ColorBox
                local rBar, gBar, bBar
                
                local initialColor = Options.Default or Color3.new(1, 0, 0)
                local initialAlpha = Options.DefaultAlpha or 1.0

                local colorState = {
                    R = initialColor.R * 255,
                    G = initialColor.G * 255,
                    B = initialColor.B * 255,
                    A = initialAlpha * 100
                }
                
                -- This function handles all UI updates and callback calls
                local function UpdateColorAndUI(component, value)
                    colorState[component] = value
                    
                    local newR = colorState.R / 255
                    local newG = colorState.G / 255
                    local newB = colorState.B / 255
                    local newA = colorState.A / 100

                    local finalColor = Color3.new(newR, newG, newB)
                    
                    -- Update ColorBox and Slider Bar Colors
                    ColorBox.BackgroundColor3 = finalColor
                    
                    if rBar and rBar.Fill then rBar.Fill.BackgroundColor3 = Color3.new(finalColor.R, 0, 0) end
                    if gBar and gBar.Fill then gBar.Fill.BackgroundColor3 = Color3.new(0, finalColor.G, 0) end
                    if bBar and bBar.Fill then bBar.Fill.BackgroundColor3 = Color3.new(0, 0, finalColor.B) end
                    
                    -- Call the user-defined callback
                    if Options.Callback then Options.Callback(finalColor, newA) end
                end

                -- 1. Color Preview Box (MUST BE CREATED FIRST to assign to ColorBox)
                local Control, Container = CreateControlContainer("ColorPicker", Options)
                Container.BackgroundTransparency = 1 -- Hide the container's background
                Control.Label.Text = Options.Text or "Color"
                
                ColorBox = CreateBaseFrame(Container, "ColorPreview", 
                    UDim2.new(0, 20, 0, 20), UDim2.new(1, -25, 0.5, -10), initialColor, UDim.new(0, 3))
                ColorBox.BackgroundColor3 = initialColor
                
                -- 2. Red Slider (R)
                local RControl = Section.addSlider({
                    Text = "R", Minimum = 0, Maximum = 255, Default = colorState.R, Postfix = "",
                    Callback = function(val) UpdateColorAndUI("R", val) end
                })
                rBar = RControl.SliderBar -- Assign local reference
                RControl.SliderBar.BackgroundTransparency = 0.5
                RControl.ValueLabel.TextColor3 = Color3.new(1, 0, 0)
                
                -- 3. Green Slider (G)
                local GControl = Section.addSlider({
                    Text = "G", Minimum = 0, Maximum = 255, Default = colorState.G, Postfix = "",
                    Callback = function(val) UpdateColorAndUI("G", val) end
                })
                gBar = GControl.SliderBar -- Assign local reference
                GControl.SliderBar.BackgroundTransparency = 0.5
                GControl.ValueLabel.TextColor3 = Color3.new(0, 1, 0)

                -- 4. Blue Slider (B)
                local BControl = Section.addSlider({
                    Text = "B", Minimum = 0, Maximum = 255, Default = colorState.B, Postfix = "",
                    Callback = function(val) UpdateColorAndUI("B", val) end
                })
                bBar = BControl.SliderBar -- Assign local reference
                BControl.SliderBar.BackgroundTransparency = 0.5
                BControl.ValueLabel.TextColor3 = Color3.new(0, 0, 1)

                -- 5. Alpha Slider (A)
                local AControl = Section.addSlider({
                    Text = "A", Minimum = 0, Maximum = 100, Default = colorState.A, Postfix = "%",
                    Callback = function(val) UpdateColorAndUI("A", val) end
                })
                AControl.ValueLabel.TextColor3 = THEME.Text
                AControl.SliderBar.BackgroundColor3 = THEME.Background
                
                -- CRITICAL FIX: Call UpdateColorAndUI one final time 
                -- AFTER ALL controls (including rBar, gBar, bBar) have been assigned.
                UpdateColorAndUI("R", colorState.R)
                
                return Control -- Returns the first container (with the preview box)
            end

            -- Button 
            function Section.addButton(Options)
                -- controlCount is incremented inside CreateControlContainer
                local Control, Container = CreateControlContainer("Button", Options)
                Container.BackgroundTransparency = 1
                
                local Button = CreateButton(Container, Options.Text,
                    UDim2.new(1, 0, 1, 0), nil, THEME.Accent)
                
                Button.MouseButton1Click:Connect(function()
                    if Options.Callback then Options.Callback() end
                    Library:Toast(Options.Text .. " executed.", 2)
                end)

                return Control
            end

            -- Label 
            function Section.addLabel(Options)
                -- controlCount is incremented inside CreateControlContainer
                local Control, Container = CreateControlContainer("Label", Options)
                Container.BackgroundTransparency = 1
                
                local Label = Instance.new("TextLabel")
                Label.Text = Options.Text
                Label.Size = UDim2.new(1, 0, 1, 0)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.TextColor3 = Options.Color or THEME.Text
                Label.BackgroundTransparency = 1
                Label.Font = Enum.Font.SourceSans
                Label.TextSize = 13
                Label.Parent = Container

                Control.Label.TextXAlignment = Enum.TextXAlignment.Center
                Control.Label.Size = UDim2.new(1, 0, 1, 0)
                Control.Label.Position = UDim2.fromScale(0, 0)

                return Control
            end
            
            return Tab:AddChild(Section)
        end
        
        Window:AddChild(Tab)
        
        -- Select the first tab automatically (Safe Initialization)
        if #Window.Children == 1 then
            -- Use task.defer to ensure the select call happens after the function returns 
            -- and the Window object is fully constructed.
            task.defer(function()
                Window.Children[1]:Select()
            end)
        end
        
        return Tab
    end

    -- --- 3. TOAST NOTIFICATION SYSTEM ---
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
            
            local ToastFrame = CreateBaseFrame(
                PlayerGui, "Toast", 
                UDim2.new(0, 300, 0, 50), 
                UDim2.new(0.5, -150, 1, 60), 
                THEME.ToastBg, UDim.new(0, 8)
            )
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
