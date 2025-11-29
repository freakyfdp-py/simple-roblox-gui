--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local task = task or {} 

local UI_CONFIG = {
    WINDOW_SIZE = UDim2.new(0, 400, 0.6, 0),
    WINDOW_COLOR = Color3.fromHex("1e1e1e"),
    TAB_BAR_COLOR = Color3.fromHex("2a2a2a"),
    SECTION_COLOR = Color3.fromHex("383838"),
    ACCENT_COLOR = Color3.fromHex("00aaff"),
    TEXT_COLOR = Color3.new(1, 1, 1),
    PADDING = 10,
    LINE_HEIGHT = 30,
}

type ControlCallback = (value: any) -> ()

local UI = {}

local function createControlFrame(parent: GuiObject, name: string): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = UDim2.new(1, 0, 0, UI_CONFIG.LINE_HEIGHT)
    frame.BackgroundColor3 = UI_CONFIG.SECTION_COLOR
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local paddingLayout = Instance.new("UIPadding")
    paddingLayout.PaddingTop = UDim.new(0, 5)
    paddingLayout.PaddingBottom = UDim.new(0, 5)
    paddingLayout.Parent = frame
    
    return frame
end

local function createLabel(parent: GuiObject, text: string): TextLabel
    local label = Instance.new("TextLabel")
    label.Text = text
    label.TextColor3 = UI_CONFIG.TEXT_COLOR
    label.TextSize = 14
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundColor3 = UI_CONFIG.SECTION_COLOR
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, UI_CONFIG.PADDING, 0, 0)
    label.Parent = parent
    return label
end

local Section = {}
Section.__index = Section

function Section:createSeparator()
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(1, -2 * UI_CONFIG.PADDING, 0, 1)
    separator.Position = UDim2.new(0, UI_CONFIG.PADDING, 0, 0)
    separator.BackgroundColor3 = UI_CONFIG.TAB_BAR_COLOR
    separator.BorderSizePixel = 0
    separator.Parent = self.Container
end

function Section:createLabel(text: string)
    local frame = createControlFrame(self.Container, "LabelControl")
    local label = createLabel(frame, text)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
end

function Section:createButton(text: string, callback: ControlCallback)
    local frame = createControlFrame(self.Container, "ButtonControl")
    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Text = text
    button.TextColor3 = UI_CONFIG.TEXT_COLOR
    button.TextSize = 15
    button.Font = Enum.Font.SourceSansSemibold
    button.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
    button.Size = UDim2.new(1, -2 * UI_CONFIG.PADDING, 1, -10)
    button.Position = UDim2.new(0, UI_CONFIG.PADDING, 0, 5)
    button.Parent = frame

    button.MouseButton1Click:Connect(function()
        callback()
    end)
end

function Section:createToggle(name: string, default: boolean, callback: ControlCallback)
    local currentState = default
    local frame = createControlFrame(self.Container, "ToggleControl")
    createLabel(frame, name)

    local toggle = Instance.new("TextButton")
    toggle.Name = "Toggle"
    toggle.Size = UDim2.new(0, 20, 0, 20)
    toggle.Position = UDim2.new(1, -UI_CONFIG.PADDING - 20, 0.5, -10)
    toggle.BorderSizePixel = 0
    toggle.Parent = frame

    local function updateToggleAppearance()
        if currentState then
            toggle.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
            toggle.Text = "ON"
            toggle.TextColor3 = UI_CONFIG.TEXT_COLOR
            toggle.TextSize = 12
        else
            toggle.BackgroundColor3 = UI_CONFIG.TAB_BAR_COLOR
            toggle.Text = "OFF"
            toggle.TextColor3 = UI_CONFIG.TEXT_COLOR
            toggle.TextSize = 12
        end
    end

    updateToggleAppearance()

    toggle.MouseButton1Click:Connect(function()
        currentState = not currentState
        updateToggleAppearance()
        callback(currentState)
    end)

    return currentState
end

function Section:createTextInput(name: string, default: string, callback: ControlCallback)
    local frame = createControlFrame(self.Container, "TextInputControl")
    createLabel(frame, name)

    local input = Instance.new("TextBox")
    input.Name = "Input"
    input.PlaceholderText = default
    input.Text = default
    input.TextColor3 = UI_CONFIG.TEXT_COLOR
    input.TextSize = 14
    input.Font = Enum.Font.SourceSans
    input.BackgroundColor3 = UI_CONFIG.TAB_BAR_COLOR
    input.Size = UDim2.new(0.4, 0, 0.7, 0)
    input.Position = UDim2.new(0.5, UI_CONFIG.PADDING, 0.5, -input.Size.Y.Offset / 2)
    input.Parent = frame

    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            callback(input.Text)
        end
    end)
end

function Section:createSlider(name: string, min: number, max: number, default: number, step: number, callback: ControlCallback)
    local currentValue = default
    local frame = createControlFrame(self.Container, "SliderControl")
    createLabel(frame, name)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Text = string.format("%.1f", currentValue)
    valueLabel.TextColor3 = UI_CONFIG.TEXT_COLOR
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.BackgroundTransparency = 1
    valueLabel.Size = UDim2.new(0.3, 0, 1, 0)
    valueLabel.Position = UDim2.new(1, -UI_CONFIG.PADDING, 0, 0)
    valueLabel.Parent = frame

    local sliderBar = Instance.new("Frame")
    sliderBar.Name = "SliderBar"
    sliderBar.Size = UDim2.new(0.4, 0, 0, 4)
    sliderBar.Position = UDim2.new(0.5, UI_CONFIG.PADDING, 0.5, -2)
    sliderBar.BackgroundColor3 = UI_CONFIG.TAB_BAR_COLOR
    sliderBar.BorderSizePixel = 0
    sliderBar.Parent = frame
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0.5, 0, 1, 0)
    fill.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
    fill.BorderSizePixel = 0
    fill.Parent = sliderBar

    local function updateSliderVisuals(value: number)
        local ratio = (value - min) / (max - min)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valueLabel.Text = string.format("%.1f", value)
    end

    local dummyButton = Instance.new("TextButton")
    dummyButton.Text = "Drag (Simulated)"
    dummyButton.TextSize = 10
    dummyButton.Size = UDim2.new(0.4, 0, 1, 0)
    dummyButton.Position = sliderBar.Position
    dummyButton.BackgroundTransparency = 1
    dummyButton.Parent = frame

    dummyButton.MouseButton1Click:Connect(function()
        currentValue = math.min(max, currentValue + step * 2)
        if currentValue > max then currentValue = min end
        updateSliderVisuals(currentValue)
        callback(currentValue)
    end)
    
    updateSliderVisuals(default)

    return currentValue
end


function Section.new(tabContainer: GuiObject)
    local self = setmetatable({}, Section)

    self.Container = Instance.new("Frame")
    self.Container.Name = "SectionContainer"
    self.Container.Size = UDim2.new(1, 0, 0, 0) 
    self.Container.AutomaticSize = Enum.AutomaticSize.Y 
    self.Container.BackgroundColor3 = UI_CONFIG.SECTION_COLOR
    self.Container.BorderSizePixel = 0
    self.Container.Parent = tabContainer

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 1)
    listLayout.Parent = self.Container
    
    return self
end

local Tab = {}
Tab.__index = Tab

function Tab:createSection(title: string)
    local header = Instance.new("TextLabel")
    header.Name = "SectionHeader"
    header.Text = title
    header.TextColor3 = UI_CONFIG.TEXT_COLOR
    header.TextSize = 16
    header.Font = Enum.Font.SourceSansSemibold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 25)
    header.Parent = self.InnerContainer 

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, UI_CONFIG.PADDING)
    padding.Parent = header
    
    local sectionObject = Section.new(self.InnerContainer)
    sectionObject.Container.Name = "Section_" .. title:gsub("%s+", "_")
    
    return sectionObject
end

function Tab.new(windowContainer: GuiObject, tabName: string)
    local self = setmetatable({}, Tab)
    
    self.Container = Instance.new("ScrollingFrame")
    self.Container.Name = "Content_" .. tabName:gsub("%s+", "_")
    self.Container.Size = UDim2.new(1, 0, 1, -UI_CONFIG.LINE_HEIGHT * 2) 
    self.Container.Position = UDim2.new(0, 0, UI_CONFIG.LINE_HEIGHT * 2, 0)
    self.Container.BackgroundColor3 = UI_CONFIG.WINDOW_COLOR
    self.Container.BackgroundTransparency = 1
    self.Container.BorderSizePixel = 0
    self.Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.Container.VerticalScrollBarInset = Enum.ScrollBarInset.Always
    self.Container.Parent = windowContainer
    self.Container.Visible = false

    self.InnerContainer = Instance.new("Frame")
    self.InnerContainer.Name = "InnerContainer"
    self.InnerContainer.Size = UDim2.new(1, 0, 0, 0)
    self.InnerContainer.AutomaticSize = Enum.AutomaticSize.Y
    self.InnerContainer.BackgroundTransparency = 1
    self.InnerContainer.Parent = self.Container

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, UI_CONFIG.PADDING)
    listLayout.Parent = self.InnerContainer
    
    self.InnerContainer.SizeChanged:Connect(function()
        self.Container.CanvasSize = UDim2.new(0, 0, 0, self.InnerContainer.AbsoluteSize.Y)
    end)

    return self
end

local Window = {}
Window.__index = Window

function Window:createTab(name: string)
    local tabObject = Tab.new(self.Container, name)
    table.insert(self.Tabs, tabObject)
    
    local button = Instance.new("TextButton")
    button.Name = name .. "TabButton"
    button.Text = name
    button.Font = Enum.Font.SourceSansSemibold
    button.TextSize = 14
    button.TextColor3 = UI_CONFIG.TEXT_COLOR
    button.BackgroundColor3 = UI_CONFIG.TAB_BAR_COLOR
    button.BorderSizePixel = 0
    button.Parent = self.TabBar

    local currentTab = tabObject

    local function switchTab()
        for _, tab in ipairs(self.Tabs) do
            tab.Container.Visible = false
        end
        for _, btn in ipairs(self.TabBar:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = UI_CONFIG.TAB_BAR_COLOR
            end
        end

        currentTab.Container.Visible = true
        button.BackgroundColor3 = UI_CONFIG.ACCENT_COLOR
    end

    button.MouseButton1Click:Connect(switchTab)
    
    if #self.Tabs == 1 then
        if task.wait then
            task.wait() 
        else
            wait()
        end
        switchTab()
    end

    return tabObject
end

function Window.new(title: string)
    local self = setmetatable({}, Window)
    self.Tabs = {}

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "UIModuleGUI"
    self.ScreenGui.Parent = playerGui

    self.Container = Instance.new("Frame")
    self.Container.Name = "Window_" .. title:gsub("%s+", "_")
    self.Container.Size = UI_CONFIG.WINDOW_SIZE
    self.Container.Position = UDim2.new(0.5, -UI_CONFIG.WINDOW_SIZE.X.Offset / 2, 0.5, -UI_CONFIG.WINDOW_SIZE.Y.Offset / 2)
    self.Container.BackgroundColor3 = UI_CONFIG.WINDOW_COLOR
    self.Container.BorderSizePixel = 1
    self.Container.BorderColor3 = UI_CONFIG.TAB_BAR_COLOR
    self.Container.Parent = self.ScreenGui
    
    local titleBar = Instance.new("TextLabel")
    titleBar.Name = "TitleBar"
    titleBar.Text = title
    titleBar.TextColor3 = UI_CONFIG.TEXT_COLOR
    titleBar.TextSize = 18
    titleBar.Font = Enum.Font.SourceSansSemibold
    titleBar.BackgroundColor3 = UI_CONFIG.TAB_BAR_COLOR
    titleBar.Size = UDim2.new(1, 0, 0, UI_CONFIG.LINE_HEIGHT)
    titleBar.Parent = self.Container
    
    local drag
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local startPos = self.Container.AbsolutePosition
            local startMousePos = Players.LocalPlayer:GetMouse().AbsolutePosition
            
            drag = RunService.Heartbeat:Connect(function()
                local newMousePos = Players.LocalPlayer:GetMouse().AbsolutePosition
                local delta = newMousePos - startMousePos
                
                self.Container.Position = UDim2.fromOffset(startPos.X + delta.X, startPos.Y + delta.Y)
            end)
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if drag then drag:Disconnect() end
        end
    end)


    self.TabBar = Instance.new("Frame")
    self.TabBar.Name = "TabBar"
    self.TabBar.Size = UDim2.new(1, 0, 0, UI_CONFIG.LINE_HEIGHT)
    self.TabBar.Position = UDim2.new(0, 0, 0, UI_CONFIG.LINE_HEIGHT)
    self.TabBar.BackgroundColor3 = UI_CONFIG.TAB_BAR_COLOR
    self.TabBar.BorderSizePixel = 0
    self.TabBar.Parent = self.Container

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = self.TabBar
    
    local buttonSize = Instance.new("UISizeConstraint")
    buttonSize.MinSize = Vector2.new(60, UI_CONFIG.LINE_HEIGHT)
    buttonSize.Parent = self.TabBar
    
    return self
end

function UI:Init(title: string): Window
    if not Players.LocalPlayer then
        warn("UI.Init() must be called from a LocalScript.")
        return nil
    end

    local newWindow = Window.new(title)
    return newWindow
end

return UI
