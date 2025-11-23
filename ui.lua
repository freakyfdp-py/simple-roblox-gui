local Library = {}
local Players = game:GetService("Players")
local LocalPlayer = nil
repeat LocalPlayer = Players.LocalPlayer task.wait(0.1) until LocalPlayer ~= nil
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
    local WindowFrame = CreateBaseFrame(ScreenGui, cleanName(Title).."Window", UDim2.new(0, W.X, 0, W.Y), UDim2.new(0.5, -W.X/2, 0.5, -W.Y/2), THEME.Background)
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
        Tab.ColumnHeights = {[0]=0,[1]=0}
        local W = THEME.WindowSize
        Tab.MaxColumnHeight = W.Y - THEME.HeaderHeight - THEME.Padding * 2
        local TabButton = CreateButton(TabBar, Name, UDim2.new(1,0,0,30), nil, THEME.Header)
        TabButton.TextXAlignment = Enum.TextXAlignment.Center
        Tab.Instance = TabButton
        local PageScroll = Instance.new("ScrollingFrame")
        PageScroll.Name = Name.."PageScroll"
        PageScroll.Size = UDim2.new(1,0,1,0)
        PageScroll.CanvasSize = UDim2.new(0,0,0,0)
        PageScroll.BackgroundTransparency = 1
        PageScroll.ScrollBarThickness = 6
        PageScroll.Visible = false
        PageScroll.Parent = PageContainer
        Tab.PageScroll = PageScroll
        local PageFrame = CreateBaseFrame(PageScroll, Name.."Page", UDim2.new(1,0,0,0), nil, THEME.Background)
        PageFrame.BackgroundTransparency = 1
        local ListLayout = Instance.new("UIListLayout")
        ListLayout.FillDirection = Enum.FillDirection.Vertical
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Parent = PageFrame
        local SectionGridLayout = Instance.new("UIGridLayout")
        SectionGridLayout.Name = "SectionLayout"
        SectionGridLayout.CellPadding = UDim2.new(0, THEME.Padding/2,0, THEME.Padding)
        SectionGridLayout.StartCorner = Enum.StartCorner.TopLeft
        SectionGridLayout.FillDirection = Enum.FillDirection.Horizontal
        SectionGridLayout.FillDirectionMaxCells = THEME.SectionColumnCount
        SectionGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        local CellScale = 1 / THEME.SectionColumnCount
        SectionGridLayout.CellSize = UDim2.new(CellScale,-THEME.Padding,0,1)
        SectionGridLayout.Parent = PageFrame
        function Tab:Select()
            Window.CloseDropdown()
            for _, childTab in ipairs(Window.Children) do
                if type(childTab)=="table" and childTab.PageScroll and childTab.Instance then
                    childTab.PageScroll.Visible=false
                    childTab.Instance.BackgroundColor3=THEME.Header
                end
            end
            Tab.PageScroll.Visible=true
            Tab.Instance.BackgroundColor3=THEME.Accent
        end
        TabButton.MouseButton1Click:Connect(function() Tab:Select() end)
        Tab.addSection = function(SectionName, Side)
            local Section = BaseComponent(Tab,{Text=SectionName,Side=Side})
            local function calculateSectionHeight(controlCount)
                local totalContentHeight=THEME.SectionHeaderHeight+(controlCount*THEME.ControlHeight)+((controlCount>0 and controlCount-1 or 0)*THEME.ControlPadding)
                return totalContentHeight+(2*THEME.SectionContentPadding)
            end
            local controlCount=0
            local columnKey=0
            local columnLayoutOrder=0
            if Side=="Right" then columnKey=1 columnLayoutOrder=1 else
                local assumedSectionHeight=calculateSectionHeight(1)
                local newLeftHeight=Tab.ColumnHeights[0]+assumedSectionHeight
                if newLeftHeight>Tab.MaxColumnHeight*0.9 and Tab.ColumnHeights[1]<Tab.ColumnHeights[0] then columnKey=1 columnLayoutOrder=1 end
            end
            local SectionContainer=CreateBaseFrame(PageFrame,SectionName.."SectionContainer",UDim2.new(1,0,0,0),UDim2.fromScale(0,0),THEME.Background)
            SectionContainer.BackgroundTransparency=1
            SectionContainer.LayoutOrder=columnLayoutOrder
            local SectionFrame=CreateBaseFrame(SectionContainer,SectionName.."Frame",UDim2.new(1,0,0,100),nil,THEME.ControlBg)
            Section.Instance=SectionFrame
            local ControlContainer=CreateBaseFrame(SectionFrame,"ControlContainer",UDim2.new(1,-THEME.SectionContentPadding*2,1,-THEME.SectionContentPadding*2),UDim2.new(0,THEME.SectionContentPadding,0,THEME.SectionContentPadding),THEME.ControlBg)
            ControlContainer.BackgroundTransparency=1
            local ControlLayout=Instance.new("UIListLayout")
            ControlLayout.FillDirection=Enum.FillDirection.Vertical
            ControlLayout.SortOrder=Enum.SortOrder.LayoutOrder
            ControlLayout.Padding=UDim.new(0,THEME.ControlPadding)
            ControlLayout.Parent=ControlContainer
            local TitleFrame=Instance.new("Frame")
            TitleFrame.Size=UDim2.new(1,0,0,THEME.SectionHeaderHeight)
            TitleFrame.BackgroundTransparency=1
            TitleFrame.Parent=ControlContainer
            local SectionTitle=Instance.new("TextLabel")
            SectionTitle.Text=SectionName
            SectionTitle.Size=UDim2.new(1,0,1,0)
            SectionTitle.TextColor3=THEME.Accent
            SectionTitle.BackgroundTransparency=1
            SectionTitle.Font=Enum.Font.SourceSansBold
            SectionTitle.TextSize=14
            SectionTitle.Parent=TitleFrame
            Section.UIContainer=ControlContainer
            local function CreateControlContainer(Type,Options)
                local Control=BaseComponent(Section,Options)
                local nameBase=Options.Text or ""
                local Container=CreateBaseFrame(ControlContainer,Type..cleanName(nameBase),UDim2.new(1,0,0,THEME.ControlHeight),nil,THEME.ControlBg)
                Container.Name=Type.."_"..cleanName(nameBase)
                Container.BackgroundTransparency=0
                Control.Instance=Container
                local TextLabel=Instance.new("TextLabel")
                TextLabel.Text=Options.Text or Type
                TextLabel.Size=UDim2.new(0.5,-5,1,0)
                TextLabel.Position=UDim2.new(0,THEME.Padding,0,0)
                TextLabel.TextColor3=THEME.Text
                TextLabel.BackgroundTransparency=1
                TextLabel.Font=Enum.Font.SourceSans
                TextLabel.TextSize=13
                TextLabel.TextXAlignment=Enum.TextXAlignment.Left
                TextLabel.Parent=Container
                Control.Label=TextLabel
                controlCount=controlCount+1
                local newHeight=calculateSectionHeight(controlCount)
                SectionFrame.Size=UDim2.new(1,0,0,newHeight)
                Tab.ColumnHeights[columnKey]=Tab.ColumnHeights[columnKey]+THEME.ControlHeight+THEME.ControlPadding
                local maxColHeight=math.max(Tab.ColumnHeights[0],Tab.ColumnHeights[1])+(THEME.SectionHeaderHeight+THEME.SectionContentPadding*2)+THEME.Padding
                SectionGridLayout.CellSize=UDim2.new(CellScale,-THEME.Padding,0,maxColHeight)
                return Control,Container
            end

            Section.addCheck=function(Options)
                local Control,Container=CreateControlContainer("Check",Options)
                local IsChecked=Options.Default or false
                local CheckBox=CreateButton(Container,IsChecked and "✓" or "",UDim2.new(0,20,0,18),UDim2.new(1,-25,0.5,-9),THEME.Background,UDim.new(0,3))
                CheckBox.TextSize=16
                CheckBox.TextXAlignment=Enum.TextXAlignment.Center
                CheckBox.BorderColor3=THEME.Accent
                CheckBox.BorderSizePixel=1
                local function UpdateVisual() CheckBox.BackgroundColor3=IsChecked and THEME.Accent or THEME.Background CheckBox.Text=IsChecked and "✓" or "" end
                UpdateVisual()
                CheckBox.MouseButton1Click:Connect(function()
                    IsChecked=not IsChecked
                    UpdateVisual()
                    if Options.Callback then Options.Callback(IsChecked) end
                end)
                return Control
            end

            Section.addInput=function(Options)
                local Control,Container=CreateControlContainer("Input",Options)
                local TextBox=Instance.new("TextBox")
                TextBox.Name="InputBox"
                TextBox.Size=UDim2.new(0.4,0,1,0)
                TextBox.Position=UDim2.new(0.5,0,0,0)
                TextBox.Text=Options.Default or ""
                TextBox.PlaceholderText=Options.Placeholder or ""
                TextBox.TextColor3=THEME.Text
                TextBox.BackgroundColor3=THEME.Background
                TextBox.Font=Enum.Font.SourceSans
                TextBox.TextSize=13
                TextBox.BorderSizePixel=0
                TextBox.Parent=Container
                local corner=Instance.new("UICorner")
                corner.CornerRadius=THEME.CornerRadius
                corner.Parent=TextBox
                TextBox.FocusLost:Connect(function(enterPressed)
                    if enterPressed or Options.ContinuousUpdate then
                        if Options.Callback then Options.Callback(TextBox.Text) end
                    end
                end)
                return Control
            end

            Section.addDropdown=function(Options)
                local Control,Container=CreateControlContainer("Dropdown",Options)
                local CurrentSelection=Options.List and Options.List[1] or "None"
                local DropdownButton=CreateButton(Container,CurrentSelection,UDim2.new(0.4,0,1,0),UDim2.new(0.5,0,0,0),THEME.Background)
                local ListFrame=CreateBaseFrame(PlayerGui,"DropdownList",UDim2.new(0,0,0,0),UDim2.fromScale(0,0),THEME.ControlBg)
                ListFrame.BackgroundTransparency=0
                ListFrame.Visible=false
                ListFrame.ZIndex=5
                local ListLayout=Instance.new("UIListLayout")
                ListLayout.FillDirection=Enum.FillDirection.Vertical
                ListLayout.SortOrder=Enum.SortOrder.LayoutOrder
                ListLayout.Parent=ListFrame
                local function OpenList()
                    local absPos=DropdownButton.AbsolutePosition
                    local absSize=DropdownButton.AbsoluteSize
                    if currentDropdownList==ListFrame and ListFrame.Visible then
                        Window.CloseDropdown()
                    else
                        Window.CloseDropdown()
                        currentDropdownList=ListFrame
                        ListFrame.Position=UDim2.fromOffset(absPos.X,absPos.Y+absSize.Y)
                        ListFrame.Size=UDim2.new(0,absSize.X,0,#Options.List*THEME.ControlHeight)
                        ListFrame.Visible=true
                    end
                end
                DropdownButton.MouseButton1Click:Connect(OpenList)
                local function SelectOption(option)
                    CurrentSelection=option
                    DropdownButton.Text=option
                    Window.CloseDropdown()
                    if Options.Callback then Options.Callback(option) end
                end
                for i,option in ipairs(Options.List) do
                    local optionButton=CreateButton(ListFrame,option,UDim2.new(1,0,0,THEME.ControlHeight),nil,THEME.ControlBg)
                    optionButton.MouseEnter:Connect(function() optionButton.BackgroundColor3=THEME.ControlHover end)
                    optionButton.MouseLeave:Connect(function() optionButton.BackgroundColor3=THEME.ControlBg end)
                    optionButton.TextXAlignment=Enum.TextXAlignment.Left
                    optionButton.MouseButton1Click:Connect(function() SelectOption(option) end)
                end
                ListFrame.Parent=PlayerGui
                return Control
            end

            Section.addColorPicker=function(Options)
                local Control,Container=CreateControlContainer("ColorPicker",Options)
                local SelectedColor=Options.Default or Color3.fromRGB(255,255,255)
                local Alpha=Options.DefaultAlpha or 1
                local ColorButton=CreateButton(Container,"",UDim2.new(0.4,0,1,0),UDim2.new(0.5,0,0,0),SelectedColor)
                local function OpenPicker()
                    if Options.Callback then Options.Callback(SelectedColor,Alpha) end
                end
                ColorButton.MouseButton1Click:Connect(OpenPicker)
                return Control
            end

            Window:addChild(Tab)
            return Section
        end
        Window:addChild(Tab)
        table.insert(Window.Children,Tab)
        return Tab
    end

    function Window:Toast(Message,Duration)
        local ToastFrame=CreateBaseFrame(PlayerGui,"ToastFrame",UDim2.new(0,300,0,40),UDim2.new(0.5,-150,0,50),THEME.ToastBg)
        local Label=Instance.new("TextLabel")
        Label.Text=Message
        Label.Size=UDim2.new(1,0,1,0)
        Label.BackgroundTransparency=1
        Label.TextColor3=THEME.Text
        Label.Font=Enum.Font.SourceSansBold
        Label.TextSize=16
        Label.Parent=ToastFrame
        ToastFrame.Parent=PlayerGui
        TweenService:Create(ToastFrame,TweenInfo.new(0.3),{Position=UDim2.new(0.5,-150,0,60)}):Play()
        task.delay(Duration or 2.5,function()
            TweenService:Create(ToastFrame,TweenInfo.new(0.3),{Position=UDim2.new(0.5,-150,0,0)}):Play()
            task.delay(0.3,function() ToastFrame:Destroy() end)
        end)
    end

    return Window
end

return Library
