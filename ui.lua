local UILib = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function new(c,p)
    local o = Instance.new(c)
    for k,v in pairs(p) do o[k] = v end
    return o
end

local function tween(o,p,t)
    TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p):Play()
end

function UILib.init(title)
    local Window = {}
    local sg = new("ScreenGui",{Parent=game.CoreGui,ResetOnSpawn=false})
    local main = new("Frame",{
        Parent=sg,
        Size=UDim2.new(0,550,0,380),
        Position=UDim2.new(0.5,-275,0.5,-190),
        BackgroundColor3=Color3.fromRGB(28,28,28),
        BorderSizePixel=0
    })

    local dragging,dragStart,startPos
    main.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            dragStart=i.Position
            startPos=main.Position
        end
    end)
    main.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dragStart
            main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)

    local top = new("TextLabel",{
        Parent=main,
        Size=UDim2.new(1,0,0,40),
        BackgroundColor3=Color3.fromRGB(35,35,35),
        BorderSizePixel=0,
        Font=Enum.Font.GothamBold,
        Text=title,
        TextColor3=Color3.new(1,1,1),
        TextSize=18
    })

    local leftTabs = new("Frame",{
        Parent=main,
        Position=UDim2.new(0,0,0,40),
        Size=UDim2.new(0,125,1,-40),
        BackgroundColor3=Color3.fromRGB(32,32,32),
        BorderSizePixel=0
    })

    local tablist = new("UIListLayout",{
        Parent=leftTabs,
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,4)
    })

    local pages = new("Frame",{
        Parent=main,
        Position=UDim2.new(0,125,0,40),
        Size=UDim2.new(1,-125,1,-40),
        BackgroundColor3=Color3.fromRGB(25,25,25),
        BorderSizePixel=0
    })

    local dropdownHolder = new("Frame",{
        Parent=sg,
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        ZIndex=50
    })

    Window.Instance=main
    Window.Tabs={}
    Window.Active=nil

    function Window:addTab(name)
        local Tab={}

        local btn = new("TextButton",{
            Parent=leftTabs,
            Size=UDim2.new(1,0,0,32),
            BackgroundColor3=Color3.fromRGB(40,40,40),
            BorderSizePixel=0,
            Font=Enum.Font.GothamBold,
            Text=name,
            TextColor3=Color3.new(1,1,1),
            TextSize=14
        })

        local page = new("ScrollingFrame",{
            Parent=pages,
            Size=UDim2.new(1,0,1,0),
            CanvasSize=UDim2.new(0,0,0,0),
            BackgroundTransparency=1,
            BorderSizePixel=0,
            Visible=false,
            ScrollBarThickness=4
        })

        local pl = new("UIListLayout",{Parent=page,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
        new("UIPadding",{Parent=page,PaddingLeft=UDim.new(0,10),PaddingTop=UDim.new(0,10)})

        btn.MouseButton1Click:Connect(function()
            if Window.Active then Window.Active.page.Visible=false end
            page.Visible=true
            Window.Active={page=page,btn=btn}
        end)

        function Tab:addSection(sec)
            local Sec={}

            local holder = new("Frame",{
                Parent=page,
                Size=UDim2.new(1,-20,0,50),
                BackgroundColor3=Color3.fromRGB(32,32,32),
                BorderSizePixel=0
            })

            local title = new("TextLabel",{
                Parent=holder,
                Size=UDim2.new(1,0,0,28),
                BackgroundColor3=Color3.fromRGB(45,45,45),
                BorderSizePixel=0,
                Font=Enum.Font.GothamSemibold,
                TextColor3=Color3.new(1,1,1),
                Text=sec,
                TextSize=14
            })

            local body = new("Frame",{
                Parent=holder,
                Position=UDim2.new(0,0,0,28),
                Size=UDim2.new(1,0,1,-28),
                BackgroundTransparency=1
            })

            local lay = new("UIListLayout",{Parent=body,Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})

            local function resize()
                task.defer(function()
                    holder.Size=UDim2.new(1,-20,0,lay.AbsoluteContentSize.Y+35)
                    page.CanvasSize=UDim2.new(0,0,0,pl.AbsoluteContentSize.Y+20)
                end)
            end
            lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)

            function Sec:addCheck(cfg)
                local b=new("TextButton",{
                    Parent=body,
                    Size=UDim2.new(1,-10,0,28),
                    BackgroundColor3=Color3.fromRGB(50,50,50),
                    BorderSizePixel=0,
                    Font=Enum.Font.Gotham,
                    Text=cfg.Text,
                    TextColor3=Color3.new(1,1,1),
                    TextSize=14
                })

                local state=cfg.Default
                local ind=new("Frame",{
                    Parent=b,
                    Size=UDim2.new(0,22,0,22),
                    Position=UDim2.new(1,-26,0.5,-11),
                    BackgroundColor3=state and Color3.fromRGB(0,255,80) or Color3.fromRGB(80,80,80),
                    BorderSizePixel=0
                })

                b.MouseButton1Click:Connect(function()
                    state=not state
                    tween(ind,{BackgroundColor3=state and Color3.fromRGB(0,255,80) or Color3.fromRGB(80,80,80)},0.15)
                    cfg.Callback(state)
                end)
            end

            function Sec:addDropdown(cfg)
                local frame=new("Frame",{
                    Parent=body,
                    Size=UDim2.new(1,-10,0,28),
                    BackgroundColor3=Color3.fromRGB(50,50,50),
                    BorderSizePixel=0
                })

                local lbl=new("TextLabel",{
                    Parent=frame,
                    Size=UDim2.new(1,-25,1,0),
                    BackgroundTransparency=1,
                    Font=Enum.Font.Gotham,
                    Text=cfg.Text,
                    TextColor3=Color3.new(1,1,1),
                    TextSize=14
                })

                local btn=new("TextButton",{
                    Parent=frame,
                    Size=UDim2.new(0,22,0,22),
                    Position=UDim2.new(1,-24,0.5,-11),
                    BackgroundColor3=Color3.fromRGB(70,70,70),
                    Text="▼",
                    TextColor3=Color3.new(1,1,1),
                    Font=Enum.Font.GothamBold,
                    TextSize=12,
                    BorderSizePixel=0
                })

                local drop=new("Frame",{
                    Parent=dropdownHolder,
                    Size=UDim2.new(0,frame.AbsoluteSize.X,0,0),
                    Position=UDim2.new(0,frame.AbsolutePosition.X,0,frame.AbsolutePosition.Y+28),
                    BackgroundColor3=Color3.fromRGB(45,45,45),
                    BorderSizePixel=0,
                    ClipsDescendants=true,
                    ZIndex=60,
                    Visible=false
                })

                new("UIListLayout",{Parent=drop,SortOrder=Enum.SortOrder.LayoutOrder})

                local open=false

                btn.MouseButton1Click:Connect(function()
                    open=not open
                    drop.Visible=open
                    drop.Position=UDim2.new(0,frame.AbsolutePosition.X,0,frame.AbsolutePosition.Y+28)
                    drop.Size=UDim2.new(0,frame.AbsoluteSize.X,0,0)
                    tween(drop,{Size=UDim2.new(0,frame.AbsoluteSize.X,0,open and (#cfg.List*24) or 0)},0.2)
                end)

                for _,item in ipairs(cfg.List) do
                    local op=new("TextButton",{
                        Parent=drop,
                        Size=UDim2.new(1,0,0,24),
                        BackgroundColor3=Color3.fromRGB(55,55,55),
                        BorderSizePixel=0,
                        Font=Enum.Font.Gotham,
                        Text=item,
                        TextColor3=Color3.new(1,1,1),
                        TextSize=14,
                        ZIndex=61
                    })
                    op.MouseButton1Click:Connect(function()
                        cfg.Callback(item)
                        open=false
                        tween(drop,{Size=UDim2.new(0,frame.AbsoluteSize.X,0,0)},0.2)
                        task.wait(0.2)
                        drop.Visible=false
                    end)
                end
            end

            function Sec:addInput(cfg)
                local box=new("TextBox",{
                    Parent=body,
                    Size=UDim2.new(1,-10,0,28),
                    BackgroundColor3=Color3.fromRGB(50,50,50),
                    BorderSizePixel=0,
                    Text=cfg.Default,
                    PlaceholderText=cfg.Placeholder,
                    Font=Enum.Font.Gotham,
                    TextColor3=Color3.new(1,1,1),
                    TextSize=14
                })
                box.FocusLost:Connect(function()
                    cfg.Callback(box.Text)
                end)
            end

            function Sec:addColorPicker(cfg)
                local b=new("TextButton",{
                    Parent=body,
                    Size=UDim2.new(1,-10,0,28),
                    BackgroundColor3=cfg.Default,
                    BorderSizePixel=0,
                    Text=cfg.Text,
                    Font=Enum.Font.Gotham,
                    TextColor3=Color3.new(1,1,1),
                    TextSize=14
                })
                b.MouseButton1Click:Connect(function()
                    cfg.Callback(cfg.Default,cfg.DefaultAlpha)
                end)
            end

            return Sec
        end

        Window.Tabs[name]={page=page,btn=btn}
        return Tab
    end

    function Window:Toast(msg,dur)
        local t=new("TextLabel",{
            Parent=sg,
            Size=UDim2.new(0,300,0,32),
            Position=UDim2.new(1,-310,1,-40),
            BackgroundColor3=Color3.fromRGB(40,40,40),
            Text=msg,
            TextColor3=Color3.new(1,1,1),
            Font=Enum.Font.GothamBold,
            TextSize=14,
            BorderSizePixel=0,
            ZIndex=999
        })
        tween(t,{Position=UDim2.new(1,-310,1,-80)},0.25)
        task.wait(dur)
        tween(t,{Position=UDim2.new(1,-310,1,-40)},0.25)
        task.wait(0.25)
        t:Destroy()
    end

    return Window
end

return UILib
