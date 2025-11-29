local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local lib = {}

local function c(o,p)
    for k,v in pairs(p) do o[k]=v end
    return o
end

local binds = {}
local listening = nil

local function keyToText(k)
    if not k or k == Enum.KeyCode.Unknown then return "NONE" end
    return k.Name
end

local function registerBind(keycode, entry)
    if not keycode then return end
    local name = keycode.Name
    binds[name] = binds[name] or {}
    table.insert(binds[name], entry)
end

local function unregisterBind(keycode, entry)
    if not keycode then return end
    local name = keycode.Name
    if not binds[name] then return end
    for i,v in ipairs(binds[name]) do
        if v == entry then
            table.remove(binds[name], i)
            break
        end
    end
    if #binds[name] == 0 then binds[name] = nil end
end

function lib.makeText(parent,text,size,color)
    local l = Instance.new("TextLabel")
    c(l,{
        Parent=parent,
        Text=tostring(text or ""),
        Size=UDim2.new(0,size.X,0,size.Y),
        BackgroundTransparency=1,
        TextColor3=color or Color3.new(1,1,1),
        TextScaled=true,
        Font=Enum.Font.Gotham
    })
    return l
end

function lib.makeRect(parent,size,bg,stroke,corner)
    local f=Instance.new("Frame")
    c(f,{Parent=parent,Size=UDim2.new(0,size.X,0,size.Y),BackgroundColor3=bg,ClipsDescendants=true})
    local s=Instance.new("UIStroke")
    s.Thickness=1
    s.Color=stroke or bg
    s.Parent=f
    if corner and corner>0 then
        local u=Instance.new("UICorner")
        u.CornerRadius=UDim.new(0,corner)
        u.Parent=f
    end
    return f
end

function lib.Init(title,corner)
    local gui=Instance.new("ScreenGui")
    gui.ResetOnSpawn=false
    gui.Parent=game.CoreGui

    local mainFrame=lib.makeRect(gui,Vector2.new(620,420),Color3.fromRGB(24,24,24),nil,12)
    mainFrame.Position=UDim2.new(0.5,-310,0.5,-210)
    mainFrame.Name="MemeSenseLikeMenu"

    local header=Instance.new("Frame")
    c(header,{Parent=mainFrame,Size=UDim2.new(1,0,0,44),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.fromRGB(18,18,18)})
    local headerCorner=Instance.new("UICorner"); headerCorner.CornerRadius=UDim.new(0,10); headerCorner.Parent=header
    local titleLabel=lib.makeText(header,title or "MEMESENSE",Vector2.new(300,40),Color3.fromRGB(200,200,200))
    titleLabel.Position=UDim2.new(0,12,0,2)
    titleLabel.TextXAlignment=Enum.TextXAlignment.Left

    local leftBar=lib.makeRect(mainFrame,Vector2.new(140,372),Color3.fromRGB(28,28,28),nil,10)
    leftBar.Position=UDim2.new(0,12,0,56)
    local leftList=Instance.new("UIListLayout"); leftList.Parent=leftBar; leftList.Padding=UDim.new(0,8); leftList.SortOrder=Enum.SortOrder.LayoutOrder; leftList.HorizontalAlignment=Enum.HorizontalAlignment.Center

    local rightArea=lib.makeRect(mainFrame,Vector2.new(448,372),Color3.fromRGB(20,20,20),nil,10)
    rightArea.Position=UDim2.new(0,164,0,56)

    local tabContainer=Instance.new("Frame")
    c(tabContainer,{Parent=rightArea,Size=UDim2.new(1,-20,1,-20),Position=UDim2.new(0,10,0,10),BackgroundTransparency=1})

    local notifications = Instance.new("Frame")
    c(notifications,{Parent=mainFrame,Size=UDim2.new(0,300,0,120),Position=UDim2.new(1,-310,1,-140),BackgroundTransparency=1,ClipsDescendants=true})
    local notList = Instance.new("UIListLayout"); notList.Parent=notifications; notList.VerticalAlignment=Enum.VerticalAlignment.Bottom; notList.Padding=UDim.new(0,8)

    local tabs={}
    local visible=true

    local dragging=false
    local dragInput,dragStart,startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            dragStart=input.Position
            startPos=mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement then dragInput=input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input==dragInput then
            local delta=input.Position-dragStart
            mainFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)

    UserInputService.InputBegan:Connect(function(input,processed)
        if not processed and input.KeyCode==Enum.KeyCode.F5 then
            visible=not visible
            gui.Enabled=visible
        end
        local kc = input.KeyCode
        if kc and kc ~= Enum.KeyCode.Unknown then
            local list = binds[kc.Name]
            if list then
                for _,entry in ipairs(list) do
                    if entry.kind == "toggle" then
                        if entry.bindMode == "Hold" then
                            if not entry.state then
                                entry.state = true
                                entry.setVisual(entry.state)
                                pcall(entry.callback, entry.state)
                            end
                        elseif entry.bindMode == "Toggle" then
                            entry.state = not entry.state
                            entry.setVisual(entry.state)
                            pcall(entry.callback, entry.state)
                        end
                    elseif entry.kind == "button" then
                        pcall(entry.callback)
                    end
                end
            end
            if listening and listening.waiting then
                listening.key = kc
                listening.updateText(keyToText(kc))
                listening.done = true
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        local kc = input.KeyCode
        if kc and kc ~= Enum.KeyCode.Unknown then
            local list = binds[kc.Name]
            if list then
                for _,entry in ipairs(list) do
                    if entry.kind == "toggle" and entry.bindMode == "Hold" then
                        if entry.state then
                            entry.state = false
                            entry.setVisual(entry.state)
                            pcall(entry.callback, entry.state)
                        end
                    end
                end
            end
        end
    end)

    local function notify(text, duration)
        duration = duration or 3
        local nf = Instance.new("Frame")
        c(nf,{Parent=notifications,Size=UDim2.new(1,0,0,36),BackgroundColor3=Color3.fromRGB(24,24,24)})
        local nc = Instance.new("UICorner"); nc.CornerRadius=UDim.new(0,6); nc.Parent=nf
        local nlabel = lib.makeText(nf,tostring(text),Vector2.new(260,36),Color3.fromRGB(220,220,220))
        nlabel.Position=UDim2.new(0,12,0,0)
        nf.Size = UDim2.new(1,0,0,0)
        nf:TweenSize(UDim2.new(1,0,0,36),"Out","Quad",0.18,true)
        delay(duration, function()
            nf:TweenSize(UDim2.new(1,0,0,0),"In","Quad",0.15,true)
            task.wait(0.15)
            nf:Destroy()
        end)
    end

    local function makeTabButton(parent,text)
        local btn=Instance.new("TextButton")
        c(btn,{
            Parent=parent,
            Size=UDim2.new(0,116,0,36),
            BackgroundColor3=Color3.fromRGB(40,40,40),
            Text=text,
            TextColor3=Color3.fromRGB(220,220,220),
            TextScaled=true,
            AutoButtonColor=false,
            BorderSizePixel=0,
            Font=Enum.Font.GothamBold
        })
        local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,8); corner.Parent=btn
        local stroke=Instance.new("UIStroke"); stroke.Thickness=1; stroke.Transparency=0.75; stroke.Parent=btn
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn,TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(68,68,68)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn,TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(40,40,40)}):Play()
        end)
        return btn
    end

    local function createTab(tabName)
        local btn=makeTabButton(leftBar,tabName)
        local content=Instance.new("Frame")
        c(content,{Parent=tabContainer,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false})
        local contentLayout=Instance.new("UIListLayout"); contentLayout.Parent=content; contentLayout.Padding=UDim.new(0,10); contentLayout.SortOrder=Enum.SortOrder.LayoutOrder
        tabs[tabName]={button=btn,frame=content,sections={}}
        btn.MouseButton1Click:Connect(function()
            for k,v in pairs(tabs) do
                v.frame.Visible=false
                TweenService:Create(v.button,TweenInfo.new(0.14),{TextColor3=Color3.fromRGB(220,220,220)}):Play()
            end
            tabs[tabName].frame.Visible=true
            TweenService:Create(btn,TweenInfo.new(0.14),{TextColor3=Color3.fromRGB(255,170,255)}):Play()
        end)
        return tabs[tabName]
    end

    local function createSection(tab,sectionName)
        local sectionFrame=lib.makeRect(tab.frame,Vector2.new(0,0),Color3.fromRGB(30,30,30),nil,8)
        local headerArea=lib.makeRect(sectionFrame,Vector2.new(0,36),Color3.fromRGB(25,25,25),nil,8)
        headerArea.Position=UDim2.new(0,0,0,0)
        headerArea.Size=UDim2.new(1,0,0,36)
        local title=lib.makeText(headerArea,sectionName,Vector2.new(260,36),Color3.fromRGB(220,220,220))
        title.Position=UDim2.new(0,12,0,0)
        title.TextXAlignment=Enum.TextXAlignment.Left
        local secContent=Instance.new("Frame")
        c(secContent,{Parent=sectionFrame,Size=UDim2.new(1,-16,1,-46),Position=UDim2.new(0,8,0,44),BackgroundTransparency=1})
        local layout=Instance.new("UIListLayout"); layout.Parent=secContent; layout.Padding=UDim.new(0,8); layout.SortOrder=Enum.SortOrder.LayoutOrder
        tab.sections[sectionName]={frame=sectionFrame,content=secContent}
        sectionFrame.Parent=tab.frame
        return tab.sections[sectionName]
    end

    local function makeBindWidget(parent, kind, target)
        local kbBtn = Instance.new("TextButton")
        c(kbBtn,{Parent=parent,Size=UDim2.new(0,76,0,28),Position=UDim2.new(1,-88,0,4),BackgroundColor3=Color3.fromRGB(26,26,26),Text="NONE",TextColor3=Color3.fromRGB(200,200,200),TextScaled=true,AutoButtonColor=false,BorderSizePixel=0,Font=Enum.Font.Gotham})
        local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,6); corner.Parent=kbBtn
        local modeText = Instance.new("TextLabel")
        c(modeText,{Parent=parent,Size=UDim2.new(0,56,0,20),Position=UDim2.new(1,-150,0,8),BackgroundTransparency=1,Text="",TextColor3=Color3.fromRGB(170,170,170),TextScaled=true,Font=Enum.Font.Gotham})
        modeText.Text = kind == "toggle" and "Mode: Toggle" or ""
        local entry = {
            kind = kind,
            target = target,
            bindKey = nil,
            bindMode = kind == "toggle" and "Toggle" or "Toggle",
            state = false,
            callback = nil,
            setVisual = function() end
        }
        local prompt = Instance.new("Frame")
        c(prompt,{Parent=mainFrame,Size=UDim2.new(0,260,0,80),BackgroundColor3=Color3.fromRGB(26,26,26),Visible=false})
        local pCorner=Instance.new("UICorner"); pCorner.CornerRadius=UDim.new(0,8); pCorner.Parent=prompt
        local pLabel = lib.makeText(prompt,"Press a key to bind",Vector2.new(220,28),Color3.fromRGB(220,220,220))
        pLabel.Position=UDim2.new(0,12,0,8)
        local holdBtn = Instance.new("TextButton")
        c(holdBtn,{Parent=prompt,Size=UDim2.new(0,100,0,28),Position=UDim2.new(0,12,0,40),Text="Hold",TextScaled=true,BackgroundColor3=Color3.fromRGB(40,40,40),TextColor3=Color3.fromRGB(220,220,220),AutoButtonColor=false})
        local toggleBtn = Instance.new("TextButton")
        c(toggleBtn,{Parent=prompt,Size=UDim2.new(0,100,0,28),Position=UDim2.new(0,136,0,40),Text="Toggle",TextScaled=true,BackgroundColor3=Color3.fromRGB(40,40,40),TextColor3=Color3.fromRGB(220,220,220),AutoButtonColor=false})
        local phCorner = Instance.new("UICorner"); phCorner.CornerRadius=UDim.new(0,6); phCorner.Parent=holdBtn
        local ptCorner = Instance.new("UICorner"); ptCorner.CornerRadius=UDim.new(0,6); ptCorner.Parent=toggleBtn

        local function updateBindVisual()
            if entry.bindKey then
                kbBtn.Text = keyToText(entry.bindKey)
            else
                kbBtn.Text = "NONE"
            end
            if entry.kind == "toggle" then
                modeText.Text = "Mode: "..(entry.bindMode or "Toggle")
            end
        end

        local function startListening()
            if listening then return end
            listening = {waiting=true, key=nil, done=false, updateText=function(txt) kbBtn.Text = txt end}
            prompt.Position = UDim2.new(0.5,-130,0.5,-40)
            prompt.Visible = true
            kbBtn.Text = "..."
        end

        local function finishListening()
            if not listening then return end
            prompt.Visible = false
            local kc = listening.key
            local mode = entry.bindMode
            if entry.bindKey then
                unregisterBind(entry.bindKey, entry)
            end
            entry.bindKey = kc
            if kc then
                registerBind(kc, entry)
            end
            updateBindVisual()
            listening = nil
        end

        kbBtn.MouseButton1Click:Connect(function()
            startListening()
        end)

        holdBtn.MouseButton1Click:Connect(function()
            if entry.kind == "toggle" then entry.bindMode = "Hold"; updateBindVisual() end
        end)
        toggleBtn.MouseButton1Click:Connect(function()
            entry.bindMode = "Toggle"; updateBindVisual()
        end)

        RunService.Heartbeat:Connect(function()
            if listening and listening.done then
                finishListening()
            end
        end)

        entry.updateText = updateBindVisual

        return entry, kbBtn, modeText
    end

    local function addLabel(section,text)
        return lib.makeText(section.content,text,Vector2.new(0,28),Color3.fromRGB(220,220,220))
    end

    local function addSeparator(section)
        return lib.makeRect(section.content,Vector2.new(0,2),Color3.fromRGB(60,60,60),nil,2)
    end

    local function addButton(section,text,callback)
        local b=Instance.new("TextButton")
        c(b,{Parent=section.content,Size=UDim2.new(1,0,0,34),BackgroundColor3=Color3.fromRGB(40,40,40),Text=text,TextColor3=Color3.fromRGB(230,230,230),TextScaled=true,AutoButtonColor=false,BorderSizePixel=0,Font=Enum.Font.GothamBold})
        local u=Instance.new("UICorner"); u.CornerRadius=UDim.new(0,6); u.Parent=b
        local stroke=Instance.new("UIStroke"); stroke.Thickness=1; stroke.Transparency=0.8; stroke.Parent=b
        b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(64,64,64)}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(40,40,40)}):Play() end)
        b.MouseButton1Click:Connect(function() pcall(callback) end)
        local entry, kbBtn = makeBindWidget(section.content, "button", b)
        entry.callback = callback
        entry.kind = "button"
        entry.setVisual = function() end
        entry.bindKey = nil
        entry.bindMode = "Toggle"
        entry.updateText()
        return b, entry
    end

    local function addToggle(section,text,default,callback)
        local f=lib.makeRect(section.content,Vector2.new(0,34),Color3.fromRGB(35,35,35),nil,8)
        local lbl=lib.makeText(f,text,Vector2.new(260,34),Color3.fromRGB(220,220,220))
        lbl.Position=UDim2.new(0,12,0,0)
        lbl.TextXAlignment=Enum.TextXAlignment.Left
        local holder=lib.makeRect(f,Vector2.new(46,26),Color3.fromRGB(18,18,18),nil,8)
        holder.Position=UDim2.new(1,-56,0,4)
        local glow=Instance.new("Frame")
        c(glow,{Parent=holder,Size=UDim2.new(0.45,0,1,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.fromRGB(160,160,160)})
        local glowCorner=Instance.new("UICorner"); glowCorner.CornerRadius=UDim.new(0,6); glowCorner.Parent=glow
        local inner=Instance.new("TextButton")
        c(inner,{Parent=holder,Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0,0,0,0),BackgroundTransparency=1,Text="",AutoButtonColor=false})
        local toggled = default and true or false
        if toggled then
            glow.Size=UDim2.new(1,0,1,0)
            glow.BackgroundColor3=Color3.fromRGB(110,255,160)
        else
            glow.Size=UDim2.new(0.45,0,1,0)
            glow.BackgroundColor3=Color3.fromRGB(160,160,160)
        end
        inner.MouseButton1Click:Connect(function()
            toggled = not toggled
            if toggled then
                TweenService:Create(glow,TweenInfo.new(0.14,Enum.EasingStyle.Quad),{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(110,255,160)}):Play()
            else
                TweenService:Create(glow,TweenInfo.new(0.14,Enum.EasingStyle.Quad),{Size=UDim2.new(0.45,0,1,0),BackgroundColor3=Color3.fromRGB(160,160,160)}):Play()
            end
            if callback then pcall(callback,toggled) end
        end)
        local entry, kbBtn, modeText = makeBindWidget(section.content, "toggle", f)
        entry.kind = "toggle"
        entry.state = toggled
        entry.callback = callback
        entry.setVisual = function(state)
            toggled = state and true or false
            if toggled then
                glow.Size=UDim2.new(1,0,1,0)
                glow.BackgroundColor3=Color3.fromRGB(110,255,160)
            else
                glow.Size=UDim2.new(0.45,0,1,0)
                glow.BackgroundColor3=Color3.fromRGB(160,160,160)
            end
        end
        entry.updateText()
        return f, entry
    end

    local function addSlider(section,text,min,max,default,decimals,callback)
        decimals = decimals or 0
        local f=lib.makeRect(section.content,Vector2.new(0,46),Color3.fromRGB(34,34,34),nil,8)
        local lbl=lib.makeText(f,text,Vector2.new(220,30),Color3.fromRGB(220,220,220)); lbl.Position=UDim2.new(0,12,0,6); lbl.TextXAlignment=Enum.TextXAlignment.Left
        local valLbl=lib.makeText(f,tostring(default),Vector2.new(56,30),Color3.fromRGB(220,220,220)); valLbl.Position=UDim2.new(1,-68,0,6); valLbl.TextXAlignment=Enum.TextXAlignment.Right
        local barHolder=lib.makeRect(f,Vector2.new(0,0),Color3.fromRGB(24,24,24),nil,6)
        barHolder.Position=UDim2.new(0,12,0,28)
        barHolder.Size=UDim2.new(1,-88,0,12)
        local bg=Instance.new("Frame"); c(bg,{Parent=barHolder,Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.fromRGB(60,60,60)})
        local bgCorner=Instance.new("UICorner"); bgCorner.CornerRadius=UDim.new(0,6); bgCorner.Parent=bg
        local fill=Instance.new("Frame"); c(fill,{Parent=bg,Size=UDim2.new(math.clamp((default-min)/(max-min),0,1),0,1,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.fromRGB(170,80,255)})
        local fillCorner=Instance.new("UICorner"); fillCorner.CornerRadius=UDim.new(0,6); fillCorner.Parent=fill
        local handle=Instance.new("TextButton"); c(handle,{Parent=bg,Size=UDim2.new(0,14,0,14),BackgroundColor3=Color3.fromRGB(220,220,220),AutoButtonColor=false,BorderSizePixel=0,Text=""})
        handle.Position=UDim2.new(fill.Size.X.Scale,fill.Size.X.Offset/((bg.AbsoluteSize.X>0 and bg.AbsoluteSize.X) or 1),0, -1)
        local handleCorner=Instance.new("UICorner"); handleCorner.CornerRadius=UDim.new(0,7); handleCorner.Parent=handle
        local dragging=false
        local function updateValueFromX(x)
            local absX = math.clamp(x - bg.AbsolutePosition.X,0,bg.AbsoluteSize.X)
            local frac = (bg.AbsoluteSize.X>0) and (absX / bg.AbsoluteSize.X) or 0
            fill.Size = UDim2.new(frac,0,1,0)
            handle.Position = UDim2.new(frac, -7, 0, -1)
            local val = min + frac * (max - min)
            val = math.floor(val * (10^decimals)) / (10^decimals)
            valLbl.Text = tostring(val)
            if callback then pcall(callback,val) end
        end
        handle.MouseButton1Down:Connect(function()
            dragging=true
            TweenService:Create(handle,TweenInfo.new(0.12),{Size=UDim2.new(0,18,0,18),BackgroundColor3=Color3.fromRGB(255,255,255)}):Play()
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 and dragging then
                dragging=false
                TweenService:Create(handle,TweenInfo.new(0.12),{Size=UDim2.new(0,14,0,14),BackgroundColor3=Color3.fromRGB(220,220,220)}):Play()
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                updateValueFromX(input.Position.X)
            end
        end)
        bg.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                updateValueFromX(input.Position.X)
            end
        end)
        RunService.Heartbeat:Connect(function()
            if bg.AbsoluteSize.X>0 then
                handle.Position = UDim2.new(fill.Size.X.Scale, -7, 0, -1)
            end
        end)
        return f
    end

    local function addDropdown(section,text,options,callback)
        local f=lib.makeRect(section.content,Vector2.new(0,36),Color3.fromRGB(35,35,35),nil,8)
        local lbl=lib.makeText(f,text,Vector2.new(220,30),Color3.fromRGB(220,220,220)); lbl.Position=UDim2.new(0,12,0,3); lbl.TextXAlignment=Enum.TextXAlignment.Left
        local selBtn=Instance.new("TextButton")
        c(selBtn,{Parent=f,Size=UDim2.new(0,156,0,28),Position=UDim2.new(1,-172,0,4),BackgroundColor3=Color3.fromRGB(26,26,26),Text=options[1] or "",TextColor3=Color3.fromRGB(220,220,220),TextScaled=true,AutoButtonColor=false,BorderSizePixel=0,Font=Enum.Font.Gotham})
        local selCorner=Instance.new("UICorner"); selCorner.CornerRadius=UDim.new(0,6); selCorner.Parent=selBtn
        local dropFrame=lib.makeRect(f,Vector2.new(156, #options*32),Color3.fromRGB(28,28,28),nil,8)
        dropFrame.Position=UDim2.new(1,-172,0,44)
        dropFrame.Visible=false
        dropFrame.Size=UDim2.new(0,156,0,0)
        local dropLayout=Instance.new("UIListLayout"); dropLayout.Parent=dropFrame; dropLayout.Padding=UDim.new(0,4)
        for i,opt in ipairs(options) do
            local optBtn=Instance.new("TextButton")
            c(optBtn,{Parent=dropFrame,Size=UDim2.new(1,0,0,28),BackgroundColor3=Color3.fromRGB(28,28,28),Text=opt,TextColor3=Color3.fromRGB(220,220,220),TextScaled=true,AutoButtonColor=false,BorderSizePixel=0,Font=Enum.Font.Gotham})
            local oc=Instance.new("UICorner"); oc.CornerRadius=UDim.new(0,6); oc.Parent=optBtn
            optBtn.MouseEnter:Connect(function() TweenService:Create(optBtn,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(44,44,44)}):Play() end)
            optBtn.MouseLeave:Connect(function() TweenService:Create(optBtn,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(28,28,28)}):Play() end)
            optBtn.MouseButton1Click:Connect(function()
                selBtn.Text = opt
                dropFrame:TweenSize(UDim2.new(0,156,0,0),"Out","Quad",0.15,true)
                task.wait(0.15)
                dropFrame.Visible=false
                if callback then pcall(callback,opt) end
            end)
        end
        selBtn.MouseButton1Click:Connect(function()
            if not dropFrame.Visible then
                dropFrame.Visible=true
                dropFrame:TweenSize(UDim2.new(0,156,0,#options*32),"Out","Quad",0.15,true)
            else
                dropFrame:TweenSize(UDim2.new(0,156,0,0),"Out","Quad",0.15,true)
                task.wait(0.15)
                dropFrame.Visible=false
            end
        end)
        return f
    end

    return {
        gui=gui,
        frame=mainFrame,
        leftBar=leftBar,
        rightArea=rightArea,
        notify=notify,
        createTab=createTab,
        createSection=createSection,
        addLabel=addLabel,
        addSeparator=addSeparator,
        addButton=addButton,
        addToggle=addToggle,
        addSlider=addSlider,
        addDropdown=addDropdown
    }
end

return lib
