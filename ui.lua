local lib = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Helper function to apply properties to an instance (shorthand for Instance.new and property setting)
local function c(o, p)
    for k,v in pairs(p) do o[k] = v end
    return o
end

function lib.makeText(parent,text,size,color)
    local l = Instance.new("TextLabel")
    c(l,{
        Parent=parent,
        Text=text,
        Size=UDim2.new(0,size.X,0,size.Y),
        BackgroundTransparency=1,
        TextColor3=color or Color3.new(1,1,1),
        TextScaled=true,
        Font = Enum.Font.SourceSans
    })
    return l
end

function lib.makeRect(parent,size,bg,stroke,corner)
    local f = Instance.new("Frame")
    c(f,{Parent=parent, Size=UDim2.new(0,size.X,0,size.Y), BackgroundColor3=bg})
    
    -- UIStroke
    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = stroke or bg
    s.Parent = f
    
    -- UICorner
    if corner and corner>0 then
        local u = Instance.new("UICorner")
        u.CornerRadius = UDim.new(0,corner)
        u.Parent = f
    end
    return f
end

function lib.Init(title,corner)
    local gui = Instance.new("ScreenGui")
    gui.Parent = game.CoreGui
    gui.ResetOnSpawn = false -- Good practice for persistent UIs

    local mainFrame = lib.makeRect(gui, Vector2.new(500,400), Color3.fromRGB(30,30,30), nil, corner or 10)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)

    local header = lib.makeText(mainFrame, title or "Window", Vector2.new(500,40), Color3.new(1,1,1))
    header.Position = UDim2.new(0,0,0,0)

    local content = Instance.new("Frame")
    c(content, {Parent=mainFrame, Size=UDim2.new(1,-20,1,-60), Position=UDim2.new(0,10,0,50), BackgroundTransparency=1})

    local tabBar = Instance.new("Frame")
    c(tabBar,{Parent=content, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1})

    -- **FIX 1: Add UIListLayout for Tab Button arrangement**
    local tabLayout = Instance.new("UIListLayout")
    c(tabLayout, {
        Parent = tabBar,
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 5) -- Small padding between tabs
    })

    local tabContainer = Instance.new("Frame")
    c(tabContainer,{Parent=content, Size=UDim2.new(1,0,1,-30), Position=UDim2.new(0,0,0,30), BackgroundTransparency=1})

    local tabs = {}
    local keybinds = {}

    -- Dragging
    local dragging, dragInput, dragStart, startPos = false
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not dragInput then -- Check for dragInput to prevent multi-drag issues
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            dragInput = input -- Store the input object for tracking
        end
    end)

    -- Use UserInputService for MouseMovement on the whole screen for better drag tracking
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and input == dragInput then
            dragging = false
            dragInput = nil -- Clear the stored input
        end
    end)

    -- Toggle UI with animation
    local visible = true
    local function toggleUI()
        visible = not visible
        local goal = {Size=visible and UDim2.new(0,500,0,400) or UDim2.new(0,500,0,0)}
        TweenService:Create(mainFrame,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goal):Play()
    end
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode==Enum.KeyCode.F5 then
            toggleUI()
        end
    end)

    -- Tabs
    local function createTab(tabName)
        local btn = Instance.new("TextButton")
        c(btn,{Parent=tabBar, Size=UDim2.new(0,80,0,30), BackgroundColor3=Color3.fromRGB(50,50,50), Text=tabName, TextColor3=Color3.new(1,1,1), TextScaled=true, AutoButtonColor=true, Font = Enum.Font.SourceSans})

        local tabFrame = Instance.new("ScrollingFrame")
        c(tabFrame,{Parent=tabContainer, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false, CanvasSize=UDim2.new(0,0,0,0)})
        tabFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0,6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tabFrame
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            -- Ensures the CanvasSize adjusts to fit content for scrolling
            tabFrame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
        end)

        btn.MouseButton1Click:Connect(function()
            -- De-select all tabs
            for k,v in pairs(tabs) do
                v.frame.Visible=false
                v.button.BackgroundColor3=Color3.fromRGB(50,50,50)
            end
            -- Select current tab
            tabFrame.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(70,70,70) -- Highlight selected tab
        end)

        tabs[tabName] = {button=btn, frame=tabFrame, sections={}}
        
        -- Automatically select the first tab created
        if #tabBar:GetChildren() == 2 then -- 1 is tabLayout, 2 is the button
             btn.MouseButton1Click:Fire()
        end
        
        return tabs[tabName]
    end

    -- Sections
    local function createSection(tab,sectionName)
        local section = lib.makeRect(tab.frame,Vector2.new(0,0),Color3.fromRGB(40,40,40),nil,5)
        
        local title = lib.makeText(section,sectionName,Vector2.new(0,25),Color3.new(1,1,1))
        title.Size = UDim2.new(1,0,0,25)
        title.Position = UDim2.new(0,0,0,0)

        local secContent = Instance.new("Frame")
        c(secContent,{Parent=section, Size=UDim2.new(1,-10,1,-35), Position=UDim2.new(0,5,0,30), BackgroundTransparency=1})
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0,6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = secContent
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            -- Dynamic section size adjustment
            section.Size = UDim2.new(1,0,0,layout.AbsoluteContentSize.Y+35)
        end)

        section.Parent = tab.frame
        tab.sections[sectionName] = {frame=section, content=secContent}
        return tab.sections[sectionName]
    end

    -- Elements
    local function addLabel(section,text)
        local l = lib.makeText(section.content,text,Vector2.new(0,25),Color3.new(1,1,1))
        l.TextXAlignment = Enum.TextXAlignment.Left -- Align left
        l.Size = UDim2.new(1,0,0,25)
        return l
    end

    local function addSeparator(section)
        local s = lib.makeRect(section.content,Vector2.new(0,2),Color3.fromRGB(100,100,100),nil,0)
        s.Size = UDim2.new(1,0,0,2) -- Full width separator
        return s
    end

    local function addButton(section,text,callback,keybind)
        local b = Instance.new("TextButton")
        c(b,{Parent=section.content, Size=UDim2.new(1,0,0,30), BackgroundColor3=Color3.fromRGB(60,60,60), Text=text, TextColor3=Color3.new(1,1,1), TextScaled=true, AutoButtonColor=true, Font = Enum.Font.SourceSans})
        b.MouseButton1Click:Connect(callback or function() end)
        if keybind then keybinds[keybind] = function() callback() end end
        return b
    end

    local function addToggle(section,text,default,callback,keybind,mode)
        local f = lib.makeRect(section.content,Vector2.new(0,30),Color3.fromRGB(50,50,50),nil,5)
        f.Size = UDim2.new(1,0,0,30) -- Ensure full width

        local lbl = lib.makeText(f,text,Vector2.new(0,30),Color3.new(1,1,1))
        lbl.Size = UDim2.new(0.7,0,1,0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local box = lib.makeRect(f,Vector2.new(20,20),default and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0),nil,3)
        box.Position = UDim2.new(0.75,0,0.5,-10)
        
        -- Add a UICorner to the box for visual appeal
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

        local toggled = default

        local function toggleState()
            toggled = not toggled
            box.BackgroundColor3 = toggled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
            if callback then callback(toggled) end
        end

        f.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                if mode=="Hold" then 
                    -- Only activate if not already in "Hold" state (prevent multiple calls)
                    if not toggled then
                        toggled=true; box.BackgroundColor3=Color3.fromRGB(0,255,0); 
                        if callback then callback(true) end
                    end
                else 
                    toggleState() 
                end
            end
        end)
        f.InputEnded:Connect(function(input)
            if mode=="Hold" and input.UserInputType==Enum.UserInputType.MouseButton1 then
                toggled=false; box.BackgroundColor3=Color3.fromRGB(255,0,0); 
                if callback then callback(false) end
            end
        end)

        if keybind then
            keybinds[keybind] = function(inputState)
                if mode=="Toggle" and inputState=="Begin" then toggleState()
                elseif mode=="Hold" then
                    if inputState=="Begin" then 
                        toggled=true; box.BackgroundColor3=Color3.fromRGB(0,255,0); 
                        if callback then callback(true) end
                    elseif inputState=="End" then 
                        toggled=false; box.BackgroundColor3=Color3.fromRGB(255,0,0); 
                        if callback then callback(false) end 
                    end
                end
            end
        end

        return f
    end

    -- Input for keybinds
    UserInputService.InputBegan:Connect(function(input)
        if keybinds[input.KeyCode] then keybinds[input.KeyCode]("Begin") end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if keybinds[input.KeyCode] then keybinds[input.KeyCode]("End") end
    end)

    return {
        gui=gui, frame=mainFrame, tabBar=tabBar, tabContainer=tabContainer,
        createTab=createTab, createSection=createSection,
        addLabel=addLabel, addSeparator=addSeparator,
        addButton=addButton, addToggle=addToggle
    }
end

return lib
