--[[
    UI Library ModuleScript (UILibrary)

    This module provides a simple API for initializing a styled window and
    creating standard components (Button, Label, TextBox) that conform to the
    library's style.
]]

local ui = {}
local Players = game:GetService("Players")

-- Configuration constants for styling
local UI_CONFIG = {
    Size = UDim2.new(0.3, 0, 0.5, 0), -- 30% width, 50% height
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0), -- Centered
    BackgroundColor = Color3.fromRGB(40, 44, 52), -- Dark grey
    BorderColor = Color3.fromRGB(24, 25, 29),
    BorderSizePixel = 2,
    CornerRadius = UDim.new(0, 8),
    HeaderHeight = UDim2.new(0, 30),
    TitleTextColor = Color3.fromRGB(255, 255, 255),
    TitleTextSize = 18,

    -- Component Styles
    ButtonColor = Color3.fromRGB(85, 170, 255), -- Bright blue
    ComponentHeight = 35, -- Standard height for interactive elements
    CornerRadiusSmall = UDim.new(0, 6),
    PrimaryText = Color3.fromRGB(255, 255, 255),
}

--- Initializes the main UI window.
-- @param title string: The title to display on the window header.
-- @return Instance: The main content Frame of the UI.
function ui.Init(title: string)
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        warn("UILibrary.Init() called without a LocalPlayer. UI can only be initialized on the client.")
        return nil
    end

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- 1. Create the ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = title:gsub("%s+", "") .. "Screen" -- Simple name sanitization
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = PlayerGui

    -- 2. Create the main window Frame (Container)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainWindow"
    MainFrame.Size = UI_CONFIG.Size
    MainFrame.AnchorPoint = UI_CONFIG.AnchorPoint
    MainFrame.Position = UI_CONFIG.Position
    MainFrame.BackgroundColor3 = UI_CONFIG.BackgroundColor
    MainFrame.BorderSizePixel = UI_CONFIG.BorderSizePixel
    MainFrame.BorderColor3 = UI_CONFIG.BorderColor
    MainFrame.Parent = ScreenGui

    -- Add rounded corners to the main frame
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UI_CONFIG.CornerRadius
    UICorner.Parent = MainFrame

    -- 3. Create the Header Frame
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.Position = UDim2.new(0, 0, 0, 0)
    Header.BackgroundColor3 = UI_CONFIG.BorderColor
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame

    -- Add rounded corners to the top of the header only
    local UICornerHeader = Instance.new("UICorner")
    UICornerHeader.CornerRadius = UI_CONFIG.CornerRadius
    UICornerHeader.Parent = Header

    -- 4. Create the Title Label
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.Text = title
    TitleLabel.TextColor3 = UI_CONFIG.TitleTextColor
    TitleLabel.TextSize = UI_CONFIG.TitleTextSize
    TitleLabel.Parent = Header

    -- 5. Create a content area
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "Content"
    ContentFrame.Size = UDim2.new(1, 0, 1, -30)
    ContentFrame.Position = UDim2.new(0, 0, 0, 30)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Parent = MainFrame

    -- Add layout and padding for content management
    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingTop = UDim.new(0, 10)
    UIPadding.PaddingBottom = UDim.new(0, 10)
    UIPadding.PaddingLeft = UDim.new(0, 10)
    UIPadding.PaddingRight = UDim.new(0, 10)
    UIPadding.Parent = ContentFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Name = "Layout"
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = ContentFrame

    -- Optional: Add basic dragging functionality to the Header
    local function setupDraggable(element, dragHandle)
        local dragging = false
        local dragStartPos = Vector2.new(0, 0)
        local frameStartPos = UDim2.new(0, 0, 0, 0)

        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStartPos = input.Position
                frameStartPos = element.Position
                input.Handled = true
            end
        end)

        dragHandle.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStartPos
                local newX = frameStartPos.X.Scale + delta.X / element.Parent.AbsoluteSize.X
                local newY = frameStartPos.Y.Scale + delta.Y / element.Parent.AbsoluteSize.Y
                element.Position = UDim2.new(newX, 0, newY, 0)
            end
        end)
    end

    setupDraggable(MainFrame, Header)

    return ContentFrame
end

--- Creates a styled TextButton.
-- @param parent Instance: The container to place the button in (e.g., the ContentFrame).
-- @param text string: The text to display on the button.
-- @return Instance: The created TextButton.
function ui.CreateButton(parent, text)
    local Button = Instance.new("TextButton")
    Button.Name = text:gsub("%s+", "") .. "Button"
    Button.Size = UDim2.new(1, 0, 0, UI_CONFIG.ComponentHeight) -- Full width, fixed height
    Button.BackgroundColor3 = UI_CONFIG.ButtonColor
    Button.Text = text
    Button.Font = Enum.Font.SourceSansBold
    Button.TextColor3 = UI_CONFIG.PrimaryText
    Button.TextSize = 18

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UI_CONFIG.CornerRadiusSmall
    Corner.Parent = Button

    Button.Parent = parent
    return Button
end

--- Creates a styled TextLabel.
-- @param parent Instance: The container to place the label in.
-- @param text string: The text content of the label.
-- @return Instance: The created TextLabel.
function ui.CreateLabel(parent, text)
    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = text
    Label.Font = Enum.Font.SourceSans
    Label.TextColor3 = UI_CONFIG.PrimaryText
    Label.TextSize = 16

    Label.Parent = parent
    return Label
end

--- Creates a styled TextBox.
-- @param parent Instance: The container to place the textbox in.
-- @param placeholder string: The text shown when the box is empty.
-- @return Instance: The created TextBox.
function ui.CreateTextBox(parent, placeholder)
    local TextBox = Instance.new("TextBox")
    TextBox.Name = "TextBox"
    TextBox.Size = UDim2.new(1, 0, 0, UI_CONFIG.ComponentHeight)
    TextBox.BackgroundColor3 = Color3.fromRGB(56, 60, 68) -- Slightly lighter dark color
    TextBox.Text = ""
    TextBox.PlaceholderText = placeholder
    TextBox.Font = Enum.Font.SourceSans
    TextBox.TextColor3 = UI_CONFIG.PrimaryText
    TextBox.TextSize = 16
    TextBox.ClearTextOnFocus = false

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UI_CONFIG.CornerRadiusSmall
    Corner.Parent = TextBox

    TextBox.Parent = parent
    return TextBox
end

return ui
