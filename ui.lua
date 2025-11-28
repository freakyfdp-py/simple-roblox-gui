local lib = {}

local function c(o, p)
    for k, v in pairs(p) do
        o[k] = v
    end
    return o
end

function lib.makeText(parent, text, size, color)
    local l = Instance.new("TextLabel")
    c(l, {
        Parent = parent,
        Text = text,
        Size = UDim2.new(0, size.X, 0, size.Y),
        BackgroundTransparency = 1,
        TextColor3 = color or Color3.new(1,1,1),
        TextScaled = true
    })
    return l
end

function lib.makeRect(parent, size, bg, stroke, corner)
    local f = Instance.new("Frame")
    c(f, {
        Parent = parent,
        Size = UDim2.new(0, size.X, 0, size.Y),
        BackgroundColor3 = bg
    })
    local s = Instance.new("UIStroke")
    s.Thickness = 1
    s.Color = stroke or bg
    s.Parent = f
    if corner and corner>0 then
        local u = Instance.new("UICorner")
        u.CornerRadius = UDim.new(0, corner)
        u.Parent = f
    end
    return f
end

function lib.Init(title, corner)
    local gui = Instance.new("ScreenGui")
    gui.Parent = game.CoreGui
    local mainFrame = lib.makeRect(gui, Vector2.new(500, 350), Color3.fromRGB(30,30,30), nil, corner or 10)
    mainFrame.Position = UDim2.new(0.5,-250,0.5,-175)
    local header = lib.makeText(mainFrame, title or "Window", Vector2.new(500,40), Color3.new(1,1,1))
    header.Position = UDim2.new(0,0,0,0)
    local content = Instance.new("Frame")
    c(content, {Parent=mainFrame, Size=UDim2.new(1,-20,1,-60), Position=UDim2.new(0,10,0,50), BackgroundTransparency=1})
    local tabBar = Instance.new("Frame")
    c(tabBar, {Parent=content, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1})
    local tabContainer = Instance.new("Frame")
    c(tabContainer, {Parent=content, Size=UDim2.new(1,0,1,-30), Position=UDim2.new(0,0,0,30), BackgroundTransparency=1})
    local tabs = {}
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
    local visible = true
    game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode==Enum.KeyCode.F5 then visible = not visible gui.Enabled = visible end
    end)

    local function createTab(tabName)
        local btn = lib.makeRect(tabBar, Vector2.new(80,30), Color3.fromRGB(50,50,50), nil, 5)
        local label = lib.makeText(btn, tabName, Vector2.new(80,30), Color3.new(1,1,1))
        label.Position = UDim2.new(0,0,0,0)
        local tabFrame = Instance.new("Frame")
        c(tabFrame,{Parent=tabContainer, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false})
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0,5)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tabFrame
        btn.MouseButton1Click:Connect(function()
            for _,v in pairs(tabContainer:GetChildren()) do if v:IsA("Frame") then v.Visible=false end end
            tabFrame.Visible = true
        end)
        tabs[tabName] = {button=btn, frame=tabFrame, sections={}}
        return tabs[tabName]
    end

    local function createSection(tab, sectionName)
        local section = lib.makeRect(tab.frame, Vector2.new(0,0), Color3.fromRGB(40,40,40), nil, 5)
        local title = lib.makeText(section, sectionName, Vector2.new(0,25), Color3.new(1,1,1))
        title.Size = UDim2.new(1,0,0,25)
        title.Position = UDim2.new(0,0,0,0)
        local secContent = Instance.new("Frame")
        c(secContent,{Parent=section, Size=UDim2.new(1,-10,1,-35), Position=UDim2.new(0,5,0,30), BackgroundTransparency=1})
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0,5)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = secContent
        tab.sections[sectionName] = {frame=section, content=secContent}
        section.Parent = tab.frame
        return tab.sections[sectionName]
    end

    local function addLabel(section, text) return lib.makeText(section.content, text, Vector2.new(0,25), Color3.new(1,1,1)) end
    local function addSeparator(section) return lib.makeRect(section.content, Vector2.new(0,2), Color3.fromRGB(100,100,100), nil,0) end
    local function addButton(section,text,callback)
        local b = lib.makeRect(section.content, Vector2.new(0,30), Color3.fromRGB(60,60,60), nil,5)
        local lbl = lib.makeText(b,text,Vector2.new(0,30),Color3.new(1,1,1))
        lbl.Size=UDim2.new(1,0,1,0)
        b.MouseButton1Click=callback or function() end
        return b
    end
    local function addToggle(section,text,default,callback)
        local f = lib.makeRect(section.content, Vector2.new(0,30), Color3.fromRGB(50,50,50), nil,5)
        local lbl = lib.makeText(f,text,Vector2.new(0,30),Color3.new(1,1,1))
        lbl.Size=UDim2.new(0.7,0,1,0)
        local box = lib.makeRect(f, Vector2.new(20,20), default and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0), nil,3)
        box.Position = UDim2.new(0.75,0,0.5,-10)
        local toggled=default
        f.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                toggled = not toggled
                box.BackgroundColor3 = toggled and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
                if callback then callback(toggled) end
            end
        end)
        return f
    end
    local function addSlider(section,text,min,max,default,decimals,callback)
        decimals=decimals or 0
        local f=lib.makeRect(section.content,Vector2.new(0,40),Color3.fromRGB(50,50,50),nil,5)
        local lbl=lib.makeText(f,text,Vector2.new(150,40),Color3.new(1,1,1)); lbl.Position=UDim2.new(0,5,0,0)
        local bar=lib.makeRect(f,Vector2.new(150,20),Color3.fromRGB(100,100,100),nil,5); bar.Position=UDim2.new(0,160,0.5,-10)
        local fill=lib.makeRect(bar,Vector2.new(150*((default-min)/(max-min)),20),Color3.fromRGB(0,255,0),nil,5)
        local valLbl=lib.makeText(f,tostring(default),Vector2.new(50,40),Color3.new(1,1,1)); valLbl.Position=UDim2.new(0,320,0,0)
        local dragging=false
        local function updateValue(posX)
            local pos=math.clamp(posX-bar.AbsolutePosition.X,0,bar.AbsoluteSize.X)
            fill:TweenSize(UDim2.new(0,pos,1,0),"Out","Quad",0.1,true)
            local val=min+((pos/bar.AbsoluteSize.X)*(max-min))
            val=math.floor(val*(10^decimals))/(10^decimals)
            valLbl.Text=tostring(val)
            if callback then callback(val) end
        end
        bar.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; updateValue(input.Position.X) end
        end)
        bar.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        game:GetService("UserInputService").InputChanged:Connect(function(input) if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then updateValue(input.Position.X) end end)
        return f
    end
    local function addDropdown(section,text,options,callback)
        local f=lib.makeRect(section.content,Vector2.new(0,30),Color3.fromRGB(50,50,50),nil,5)
        local lbl=lib.makeText(f,text,Vector2.new(150,30),Color3.new(1,1,1)); lbl.Position=UDim2.new(0,5,0,0)
        local selected=lib.makeText(f,options[1] or "",Vector2.new(100,30),Color3.new(1,1,1)); selected.Position=UDim2.new(0,160,0,0)
        local dropFrame=lib.makeRect(f,Vector2.new(150,#options*25),Color3.fromRGB(60,60,60),nil,5)
        dropFrame.Position=UDim2.new(0,160,0,30); dropFrame.Visible=false
        for i,opt in pairs(options) do
            local optBtn=lib.makeText(dropFrame,opt,Vector2.new(150,25),Color3.new(1,1,1))
            optBtn.Position=UDim2.new(0,0,0,(i-1)*25)
            optBtn.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 then
                    selected.Text=opt
                    dropFrame:TweenSize(UDim2.new(0,150,0,0),"Out","Quad",0.15,true)
                    wait(0.15) dropFrame.Visible=false
                    if callback then callback(opt) end
                end
            end)
        end
        f.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                dropFrame.Visible=true
                dropFrame:TweenSize(UDim2.new(0,150,0,#options*25),"Out","Quad",0.15,true)
            end
        end)
        dropFrame.Parent=f
        return f
    end

    return {
        gui=gui, frame=mainFrame, tabBar=tabBar, tabContainer=tabContainer,
        createTab=createTab, createSection=createSection,
        addLabel=addLabel, addSeparator=addSeparator,
        addButton=addButton, addToggle=addToggle,
        addSlider=addSlider, addDropdown=addDropdown
    }
end

return lib
