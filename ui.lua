local lib = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local UI_BG_COLOR = Color3.fromRGB(35, 39, 42)
local UI_ELEMENT_COLOR = Color3.fromRGB(44, 47, 51)
local UI_SECTION_COLOR = Color3.fromRGB(54, 57, 63)
local UI_ACCENT_COLOR = Color3.fromRGB(88, 101, 242)
local UI_TOGGLE_ON = Color3.fromRGB(67, 181, 129)
local UI_TOGGLE_OFF = Color3.fromRGB(240, 71, 71)
local UI_TEXT_COLOR = Color3.new(0.9, 0.9, 0.9)
local FONT = Enum.Font.SourceSansBold
local CORNER_RADIUS = 6

local function c(o, p)
    for k, v in pairs(p) do o[k] = v end
    return o
end

function lib.makeText(parent, text, size, color, align)
    local l = Instance.new("TextLabel")
    c(l, {
        Parent = parent,
        Text = text,
        Size = UDim2.new(0, size.X, 0, size.Y),
        BackgroundTransparency = 1,
        TextColor3 = color or UI_TEXT_COLOR,
        TextScaled = true,
        Font = FONT,
        TextXAlignment = align or Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center
    })
    return l
end

function lib.makeRect(parent, size, bg, stroke, corner)
    local f = Instance.new("Frame")
    c(f, {Parent = parent, Size = UDim2.new(0, size.X, 0, size.Y), BackgroundColor3 = bg})

    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = stroke or Color3.fromRGB(25, 29, 32)
    s.Parent = f

    if corner and corner > 0 then
        local u = Instance.new("UICorner")
        u.CornerRadius = UDim.new(0, corner)
        u.Parent = f
    end
    return f
end

function lib.Init(title, corner)
    local gui = Instance.new("ScreenGui")
    gui.Name = title:gsub("%s+", "") .. "GUI"
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false

    local mainFrame = lib.makeRect(gui, Vector2.new(500, 400), UI_BG_COLOR, nil, corner or CORNER_RADIUS * 2)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)

    local header = lib.makeText(mainFrame, title or "Window", Vector2.new(500, 40), UI_TEXT_COLOR, Enum.TextXAlignment.Center)
    header.Size = UDim2.new(1, 0, 0, 40)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.TextWrapped = true

    local content = Instance.new("Frame")
    c(content, {Parent = mainFrame, Size = UDim2.new(1, -20, 1, -60), Position = UDim2.new(0, 10, 0, 50), BackgroundTransparency = 1})

    local tabBar = Instance.new("Frame")
    c(tabBar, {Parent = content, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1})

    local tabLayout = Instance.new("UIListLayout")
    c(tabLayout, {
        Parent = tabBar,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 5)
    })

    local tabContainer = Instance.new("Frame")
    c(tabContainer, {Parent = content, Size = UDim2.new(1, 0, 1, -30), Position = UDim2.new(0, 0, 0, 30), BackgroundTransparency = 1})

    local tabs = {}
    local keybinds = {}

    local dragging, dragInput, dragStart, startPos = false
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not dragInput then
            dragging = true
            dragInput = input
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and input == dragInput then
            dragging = false
            dragInput = nil
        end
    end)

    local function tweenChildrenTransparency(frame, targetTransparency, tweenInfo)
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                TweenService:Create(child, tweenInfo, {TextTransparency = targetTransparency}):Play()
                if child:IsA("TextButton") then
                    TweenService:Create(child, tweenInfo, {BackgroundTransparency = targetTransparency}):Play()
                end
            elseif child:IsA("Frame") or child:IsA("ScrollingFrame") then
                TweenService:Create(child, tweenInfo, {BackgroundTransparency = targetTransparency}):Play()
                tweenChildrenTransparency(child, targetTransparency, tweenInfo)
            elseif child:IsA("UIStroke") then
                TweenService:Create(child, tweenInfo, {Transparency = targetTransparency}):Play()
            end
        end
    end

    local visible = false
    mainFrame.BackgroundTransparency = 1
    mainFrame.Visible = false
    tweenChildrenTransparency(mainFrame, 1, TweenInfo.new(0))

    local function toggleUI()
        visible = not visible
        local duration = 0.25
        local tweenInfoIn = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tweenInfoOut = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

        if visible then
            mainFrame.Visible = true
            TweenService:Create(mainFrame, tweenInfoIn, {BackgroundTransparency = 0}):Play()
            tweenChildrenTransparency(mainFrame, 0, tweenInfoIn)
        else
            local fadeOut = TweenService:Create(mainFrame, tweenInfoOut, {BackgroundTransparency = 1})
            
            tweenChildrenTransparency(mainFrame, 1, tweenInfoOut)
            
            fadeOut:Play()
            
            fadeOut.Completed:Wait()
            mainFrame.Visible = false
        end
    end
    
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.F5 then
            toggleUI()
        end
    end)

    local toastContainer = Instance.new("Frame")
    c(toastContainer, {
        Parent = gui,
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -310, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    })

    local toastLayout = Instance.new("UIListLayout")
    c(toastLayout, {
        Parent = toastContainer,
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 10)
    })

    function lib.showToast(title, description, duration)
        duration = duration or 3
        local fadeDuration = 0.25

        local toast = lib.makeRect(toastContainer, Vector2.new(300, 70), UI_ELEMENT_COLOR, Color3.fromRGB(60, 60, 60), CORNER_RADIUS)
        toast.Size = UDim2.new(0, 300, 0, 70)
        toast.BackgroundTransparency = 1

        local titleLabel = lib.makeText(toast, title, Vector2.new(280, 20), UI_ACCENT_COLOR, Enum.TextXAlignment.Left)
        titleLabel.Size = UDim2.new(1, -20, 0, 20)
        titleLabel.Position = UDim2.new(0, 10, 0, 5)
        titleLabel.Font = FONT
        titleLabel.TextTransparency = 1

        local descLabel = lib.makeText(toast, description, Vector2.new(280, 40), UI_TEXT_COLOR, Enum.TextXAlignment.Left)
        descLabel.Size = UDim2.new(1, -20, 0, 30)
        descLabel.Position = UDim2.new(0, 10, 0, 25)
        descLabel.TextScaled = false
        descLabel.TextSize = 14
        descLabel.TextTransparency = 1

        local barFrame = lib.makeRect(toast, Vector2.new(280, 3), UI_SECTION_COLOR, nil, 1)
        barFrame.Size = UDim2.new(1, 0, 0, 3)
        barFrame.Position = UDim2.new(0, 0, 1, -3)
        barFrame.BackgroundTransparency = 1
        barFrame.UIStroke.Transparency = 1


        local timerBar = lib.makeRect(barFrame, Vector2.new(280, 3), UI_ACCENT_COLOR, nil, 1)
        timerBar.Size = UDim2.new(1, 0, 1, 0)
        timerBar.UIStroke.Transparency = 1
        timerBar.BackgroundTransparency = 1

        -- Fade In
        local tweenInfoIn = TweenInfo.new(fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(toast, tweenInfoIn, {BackgroundTransparency = 0}):Play()
        TweenService:Create(titleLabel, tweenInfoIn, {TextTransparency = 0}):Play()
        TweenService:Create(descLabel, tweenInfoIn, {TextTransparency = 0}):Play()
        TweenService:Create(barFrame, tweenInfoIn, {BackgroundTransparency = 0}):Play()
        TweenService:Create(barFrame.UIStroke, tweenInfoIn, {Transparency = 0}):Play()
        TweenService:Create(timerBar, tweenInfoIn, {BackgroundTransparency = 0}):Play()
        
        -- Timer Bar
        local tweenInfoTimer = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local timerTween = TweenService:Create(timerBar, tweenInfoTimer, {Size = UDim2.new(0, 0, 1, 0)})
        timerTween:Play()

        task.delay(duration, function()
            -- Fade Out
            local tweenInfoOut = TweenInfo.new(fadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local fadeOut = TweenService:Create(toast, tweenInfoOut, {BackgroundTransparency = 1})

            TweenService:Create(titleLabel, tweenInfoOut, {TextTransparency = 1}):Play()
            TweenService:Create(descLabel, tweenInfoOut, {TextTransparency = 1}):Play()
            TweenService:Create(barFrame, tweenInfoOut, {BackgroundTransparency = 1}):Play()
            TweenService:Create(barFrame.UIStroke, tweenInfoOut, {Transparency = 1}):Play()
            TweenService:Create(timerBar, tweenInfoOut, {BackgroundTransparency = 1}):Play()
            
            fadeOut:Play()
            
            fadeOut.Completed:Wait()
            if toast.Parent then
                toast:Destroy()
            end
        end)
    end

    local function createTab(tabName)
        local btn = Instance.new("TextButton")
        c(btn, {Parent = tabBar, Size = UDim2.new(0, 80, 0, 30), BackgroundColor3 = UI_ELEMENT_COLOR, Text = tabName, TextColor3 = UI_TEXT_COLOR, TextScaled = true, AutoButtonColor = true, Font = FONT})
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, CORNER_RADIUS)

        local tabFrame = Instance.new("ScrollingFrame")
        c(tabFrame, {Parent = tabContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, CanvasSize = UDim2.new(0, 0, 0, 0)})
        tabFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tabFrame

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
        end)

        local function selectTab()
            for k, v in pairs(tabs) do
                v.frame.Visible = false
                v.button.BackgroundColor3 = UI_ELEMENT_COLOR
            end
            tabFrame.Visible = true
            btn.BackgroundColor3 = UI_SECTION_COLOR
        end

        btn.MouseButton1Click:Connect(selectTab)

        tabs[tabName] = {button = btn, frame = tabFrame, sections = {}, selectTab = selectTab}
        return tabs[tabName]
    end

    local function createSection(tab, sectionName)
        local section = lib.makeRect(tab.frame, Vector2.new(0, 0), UI_SECTION_COLOR, nil, CORNER_RADIUS)
        section.Size = UDim2.new(1, 0, 0, 0) -- Start with zero height, adjusted by layout

        local title = lib.makeText(section, sectionName, Vector2.new(0, 25), UI_TEXT_COLOR, Enum.TextXAlignment.Left)
        title.Size = UDim2.new(1, -20, 0, 25)
        title.Position = UDim2.new(0, 10, 0, 0)
        title.TextScaled = false
        title.TextSize = 16

        local secContent = Instance.new("Frame")
        -- Content frame is slightly inset and takes the remaining height
        c(secContent, {Parent = section, Size = UDim2.new(1, -20, 1, -35), Position = UDim2.new(0, 10, 0, 30), BackgroundTransparency = 1})

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = secContent

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            -- Set the section height based on its content plus padding
            section.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 40)
        end)

        section.Parent = tab.frame
        tab.sections[sectionName] = {frame = section, content = secContent}
        return tab.sections[sectionName]
    end

    local function addLabel(section, text)
        local l = lib.makeText(section.content, text, Vector2.new(0, 25), UI_TEXT_COLOR, Enum.TextXAlignment.Left)
        l.Size = UDim2.new(1, 0, 0, 25)
        l.TextScaled = false
        l.TextSize = 14
        return l
    end

    local function addSeparator(section)
        -- Separator should use UI_SECTION_COLOR to contrast with elements, or UI_BG_COLOR for a strong divider
        local s = lib.makeRect(section.content, Vector2.new(0, 2), UI_SECTION_COLOR, nil, 0)
        s.Size = UDim2.new(1, 0, 0, 2)
        return s
    end

    local function addButton(section, text, callback, keybind)
        -- Element background color and UICorner applied
        local b = lib.makeRect(section.content, Vector2.new(0, 35), UI_ELEMENT_COLOR, nil, CORNER_RADIUS)
        b.Size = UDim2.new(1, 0, 0, 35)

        local btnText = lib.makeText(b, text, Vector2.new(0, 35), UI_TEXT_COLOR, Enum.TextXAlignment.Center)
        btnText.Size = UDim2.new(1, 0, 1, 0)

        b.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if callback then callback() end
            end
        end)
        
        if keybind then keybinds[keybind] = function(inputState) if inputState == "Begin" then callback() end end end
        return b
    end

    local function addToggle(section, text, default, callback, keybind, mode)
        -- Element background color and UICorner applied
        local f = lib.makeRect(section.content, Vector2.new(0, 35), UI_ELEMENT_COLOR, nil, CORNER_RADIUS)
        f.Size = UDim2.new(1, 0, 0, 35)

        local lbl = lib.makeText(f, text, Vector2.new(0, 35), UI_TEXT_COLOR, Enum.TextXAlignment.Left)
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.TextScaled = false
        lbl.TextSize = 14

        local box = lib.makeRect(f, Vector2.new(20, 20), default and UI_TOGGLE_ON or UI_TOGGLE_OFF, Color3.fromRGB(30,30,30), 4)
        box.Position = UDim2.new(1, -30, 0.5, -10)
        
        local toggled = default

        local function toggleState()
            toggled = not toggled
            box.BackgroundColor3 = toggled and UI_TOGGLE_ON or UI_TOGGLE_OFF
            if callback then callback(toggled) end
        end

        f.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if mode == "Hold" then
                    if not toggled then
                        toggled = true
                        box.BackgroundColor3 = UI_TOGGLE_ON
                        if callback then callback(true) end
                    end
                else
                    toggleState()
                end
            end
        end)
        f.InputEnded:Connect(function(input)
            if mode == "Hold" and input.UserInputType == Enum.UserInputType.MouseButton1 then
                toggled = false
                box.BackgroundColor3 = UI_TOGGLE_OFF
                if callback then callback(false) end
            end
        end)

        if keybind then
            keybinds[keybind] = function(inputState)
                if mode == "Toggle" and inputState == "Begin" then toggleState()
                elseif mode == "Hold" then
                    if inputState == "Begin" then
                        toggled = true
                        box.BackgroundColor3 = UI_TOGGLE_ON
                        if callback then callback(true) end
                    elseif inputState == "End" then
                        toggled = false
                        box.BackgroundColor3 = UI_TOGGLE_OFF
                        if callback then callback(false) end
                    end
                end
            end
        end
        return {
            frame = f, 
            setState = function(state) toggled = state; box.BackgroundColor3 = state and UI_TOGGLE_ON or UI_TOGGLE_OFF end,
            getState = function() return toggled end
        }
    end

    local function addSlider(section, text, min, max, default, callback)
        local frameHeight = 45
        -- Element background color and UICorner applied
        local f = lib.makeRect(section.content, Vector2.new(0, frameHeight), UI_ELEMENT_COLOR, nil, CORNER_RADIUS)
        f.Size = UDim2.new(1, 0, 0, frameHeight)

        local currentValue = default
        
        local label = lib.makeText(f, text .. ": " .. string.format("%.1f", currentValue), Vector2.new(0, 20), UI_TEXT_COLOR, Enum.TextXAlignment.Left)
        label.Size = UDim2.new(1, -10, 0, 18)
        label.Position = UDim2.new(0, 10, 0, 3)
        label.TextScaled = false
        label.TextSize = 14

        local sliderBar = lib.makeRect(f, Vector2.new(0, 6), UI_SECTION_COLOR, nil, 3)
        sliderBar.Size = UDim2.new(1, -20, 0, 6)
        sliderBar.Position = UDim2.new(0, 10, 0, 25)
        
        local fill = lib.makeRect(sliderBar, Vector2.new(0, 6), UI_ACCENT_COLOR, nil, 3)
        fill.Size = UDim2.new(0, 0, 1, 0)
        
        local thumb = lib.makeRect(sliderBar, Vector2.new(14, 14), Color3.new(1, 1, 1), Color3.fromRGB(30,30,30), 7)
        thumb.Position = UDim2.new(0, -7, 0.5, -7)
        
        local isDragging = false

        local function calculateValue(inputX)
            local barPos = sliderBar.AbsolutePosition.X
            local barWidth = sliderBar.AbsoluteSize.X
            
            local relativeX = math.clamp(inputX - barPos, 0, barWidth)
            local ratio = relativeX / barWidth
            
            local value = min + (max - min) * ratio
            value = math.floor(value * 10 + 0.5) / 10
            
            return value, ratio
        end
        
        local function updateUI(value, ratio)
            currentValue = value
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            thumb.Position = UDim2.new(ratio, -7, 0.5, -7)
            label.Text = text .. ": " .. string.format("%.1f", currentValue)
            if callback then callback(currentValue) end
        end

        local function handleInput(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.MouseButton1 then
                local value, ratio = calculateValue(input.Position.X)
                updateUI(value, ratio)
            end
        end

        local function startDrag(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
                handleInput(input)
            end
        end
        
        local function endDrag(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = false
            end
        end
        
        local function moveDrag(input, gameProcessedEvent)
            if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement and not gameProcessedEvent then
                handleInput(input)
            end
        end

        sliderBar.InputBegan:Connect(startDrag)
        thumb.InputBegan:Connect(startDrag)
        
        UserInputService.InputChanged:Connect(moveDrag)
        UserInputService.InputEnded:Connect(endDrag)
        
        local initRatio = (default - min) / (max - min)
        updateUI(default, initRatio)
        
        return {
            frame = f, 
            set = function(val) 
                local ratio = (val - min) / (max - min)
                local value = math.floor(val * 10 + 0.5) / 10
                updateUI(value, ratio) 
            end, 
            getValue = function() return currentValue end
        }
    end

    UserInputService.InputBegan:Connect(function(input, processed)
        if input.UserInputType.Name:find("Key") and not processed and keybinds[input.KeyCode] then 
            keybinds[input.KeyCode]("Begin") 
        end
    end)
    UserInputService.InputEnded:Connect(function(input, processed)
        if input.UserInputType.Name:find("Key") and not processed and keybinds[input.KeyCode] then 
            keybinds[input.KeyCode]("End") 
        end
    end)

    return {
        gui = gui, frame = mainFrame, tabBar = tabBar, tabContainer = tabContainer,
        createTab = createTab, createSection = createSection,
        addLabel = addLabel, addSeparator = addSeparator,
        addButton = addButton, addToggle = addToggle,
        addSlider = addSlider,
        showToast = lib.showToast
    }
end

return lib
