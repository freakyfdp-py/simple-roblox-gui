local mod = {}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Global State
local isVisible = true
local toggleKey = Enum.KeyCode.RightShift
local themeColor = Color3.fromRGB(110, 40, 180) -- Dark Purple Accent

-- Internal Helpers
local function makeDraggable(frame)
	local dragging, dragInput, dragStart, startPos
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; dragStart = input.Position; startPos = frame.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

-- Initialization
function mod.init(title)
	local sg = Instance.new("ScreenGui", playerGui)
	sg.Name = title
	sg.ResetOnSpawn = false
	
	local main = Instance.new("Frame", sg)
	main.Size = UDim2.new(0, 500, 0, 350)
	main.Position = UDim2.new(0.5, -250, 0.5, -175)
	main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	main.BorderSizePixel = 0
	makeDraggable(main)
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
	
	-- Theme Button (+) Top Left
	local themeToggle = Instance.new("TextButton", main)
	themeToggle.Size = UDim2.new(0, 24, 0, 24)
	themeToggle.Position = UDim2.new(0, 10, 0, 8)
	themeToggle.BackgroundColor3 = themeColor
	themeToggle.Text = "+"
	themeToggle.TextColor3 = Color3.new(1,1,1)
	themeToggle.Font = Enum.Font.GothamBold
	Instance.new("UICorner", themeToggle).CornerRadius = UDim.new(1, 0)

	-- Layouts
	local sidebar = Instance.new("Frame", main)
	sidebar.Size = UDim2.new(0, 130, 1, -50)
	sidebar.Position = UDim2.new(0, 10, 0, 40)
	sidebar.BackgroundTransparency = 1
	local sideLayout = Instance.new("UIListLayout", sidebar)
	sideLayout.Padding = UDim.new(0, 6)
	
	local container = Instance.new("Frame", main)
	container.Size = UDim2.new(1, -160, 1, -50)
	container.Position = UDim2.new(0, 150, 0, 40)
	container.BackgroundTransparency = 1

	local uiState = {main = main, sidebar = sidebar, container = container, sg = sg, accent = themeToggle}

	-- Default Settings Tab
	local settings = mod.addTab(uiState, "Settings")
	mod.addSection(settings, "Menu Configuration")
	
	local bindLabel = "Toggle Key: [" .. toggleKey.Name .. "]"
	mod.addButton(settings, bindLabel, function(btn)
		btn.Text = "..."
		local connection
		connection = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				toggleKey = input.KeyCode
				btn.Text = "Toggle Key: [" .. toggleKey.Name .. "]"
				connection:Disconnect()
			end
		end)
	end)

	mod.addButton(settings, "Destroy Menu", function()
		sg:Destroy()
	end)

	-- Theme Menu Logic (Cycle Colors)
	themeToggle.MouseButton1Click:Connect(function()
		local colors = {Color3.fromRGB(110, 40, 180), Color3.fromRGB(200, 50, 50), Color3.fromRGB(50, 200, 100), Color3.fromRGB(50, 100, 200)}
		themeColor = colors[math.random(1, #colors)]
		themeToggle.BackgroundColor3 = themeColor
	end)

	-- Global Toggle Listener
	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == toggleKey then
			isVisible = not isVisible
			main.Visible = isVisible
		end
	end)

	return uiState
end

-- Tab Component
function mod.addTab(ui, name)
	local tabBtn = Instance.new("TextButton", ui.sidebar)
	tabBtn.Size = UDim2.new(1, 0, 0, 32)
	tabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	tabBtn.Text = name
	tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	tabBtn.Font = Enum.Font.GothamMedium
	tabBtn.TextSize = 13
	Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)
	
	local page = Instance.new("ScrollingFrame", ui.container)
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = (name == "Settings")
	page.ScrollBarThickness = 2
	page.ScrollBarImageColor3 = themeColor
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	
	local layout = Instance.new("UIListLayout", page)
	layout.Padding = UDim.new(0, 10)
	
	tabBtn.MouseButton1Click:Connect(function()
		for _, v in pairs(ui.container:GetChildren()) do v.Visible = false end
		page.Visible = true
	end)
	
	return page
end

-- Section Component
function mod.addSection(parent, text)
	local label = Instance.new("TextLabel", parent)
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Text = text:upper()
	label.TextColor3 = Color3.fromRGB(100, 100, 120)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
end

-- Button Component
function mod.addButton(parent, text, callback)
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(1, -10, 0, 35)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 13
	Instance.new("UICorner", btn)
	
	btn.MouseButton1Click:Connect(function() callback(btn) end)
	return btn
end

-- Slider Component
function mod.addSlider(parent, text, min, max, default, callback)
	local frame = Instance.new("Frame", parent)
	frame.Size = UDim2.new(1, -10, 0, 45)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	Instance.new("UICorner", frame)
	
	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, -10, 0, 20)
	label.Position = UDim2.new(0, 10, 0, 5)
	label.Text = text .. ": " .. default
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1,1,1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.Gotham
	
	local bar = Instance.new("Frame", frame)
	bar.Size = UDim2.new(0.9, 0, 0, 4)
	bar.Position = UDim2.new(0.05, 0, 0.75, 0)
	bar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	
	local fill = Instance.new("Frame", bar)
	fill.BackgroundColor3 = themeColor
	fill.BorderSizePixel = 0
	
	local function update(input)
		local percent = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local val = math.floor(min + (max - min) * percent)
		fill.Size = UDim2.new(percent, 0, 1, 0)
		label.Text = text .. ": " .. val
		callback(val)
	end
	
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			update(input)
			local move = UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
			end)
			local release; release = UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then move:Disconnect(); release:Disconnect() end
			end)
		end
	end)
end

-- Dropdown Component
function mod.addDropdown(parent, text, list, callback)
	local expanded = false
	local frame = Instance.new("Frame", parent)
	frame.Size = UDim2.new(1, -10, 0, 35)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.ClipsDescendants = true
	Instance.new("UICorner", frame)
	
	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.new(1, 0, 0, 35)
	btn.BackgroundTransparency = 1
	btn.Text = "  " .. text .. " >"
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.Gotham
	btn.TextXAlignment = Enum.TextXAlignment.Left
	
	btn.MouseButton1Click:Connect(function()
		expanded = not expanded
		frame.Size = expanded and UDim2.new(1, -10, 0, #list * 30 + 40) or UDim2.new(1, -10, 0, 35)
	end)
	
	for i, v in pairs(list) do
		local opt = Instance.new("TextButton", frame)
		opt.Size = UDim2.new(1, 0, 0, 30)
		opt.Position = UDim2.new(0, 0, 0, i * 30 + 5)
		opt.BackgroundTransparency = 1
		opt.Text = v
		opt.TextColor3 = Color3.fromRGB(180, 180, 180)
		opt.Font = Enum.Font.Gotham
		opt.MouseButton1Click:Connect(function()
			btn.Text = "  " .. text .. ": " .. v
			expanded = false
			frame.Size = UDim2.new(1, -10, 0, 35)
			callback(v)
		end)
	end
end

-- Text Input Component
function mod.addInput(parent, placeholder, callback)
	local box = Instance.new("TextBox", parent)
	box.Size = UDim2.new(1, -10, 0, 35)
	box.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	box.PlaceholderText = placeholder
	box.Text = ""
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Font = Enum.Font.Gotham
	Instance.new("UICorner", box)
	
	box.FocusLost:Connect(function(enter)
		if enter then callback(box.Text) end
	end)
end

return mod
