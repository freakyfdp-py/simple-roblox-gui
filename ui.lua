local mod = {}

local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isVisible = true
local toggleKey = Enum.KeyCode.RightShift
local themeColor = Color3.fromRGB(110, 40, 180) 

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
	
	local themeToggle = Instance.new("TextButton", main)
	themeToggle.Size = UDim2.new(0, 24, 0, 24)
	themeToggle.Position = UDim2.new(0, 10, 0, 8)
	themeToggle.BackgroundColor3 = themeColor
	themeToggle.Text = "+"
	themeToggle.TextColor3 = Color3.new(1,1,1)
	themeToggle.Font = Enum.Font.GothamBold
	themeToggle.TextSize = 18
	Instance.new("UICorner", themeToggle).CornerRadius = UDim.new(1, 0)

	local sidebar = Instance.new("Frame", main)
	sidebar.Size = UDim2.new(0, 130, 1, -50)
	sidebar.Position = UDim2.new(0, 10, 0, 45)
	sidebar.BackgroundTransparency = 1
	Instance.new("UIListLayout", sidebar).Padding = UDim.new(0, 6)
	
	local container = Instance.new("Frame", main)
	container.Size = UDim2.new(1, -160, 1, -50)
	container.Position = UDim2.new(0, 150, 0, 45)
	container.BackgroundTransparency = 1

	local uiState = {main = main, sidebar = sidebar, container = container, sg = sg}

	local settings = mod.addTab(uiState, "Settings")
	mod.addSection(settings, "Menu Controls")
	
	mod.addButton(settings, "Toggle Key: [" .. toggleKey.Name .. "]", function(btn)
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

	mod.addButton(settings, "Destroy Menu", function() sg:Destroy() end)

	themeToggle.MouseButton1Click:Connect(function()
		local colors = {Color3.fromRGB(110, 40, 180), Color3.fromRGB(200, 50, 50), Color3.fromRGB(50, 200, 100), Color3.fromRGB(50, 100, 200)}
		themeColor = colors[math.random(1, #colors)]
		themeToggle.BackgroundColor3 = themeColor
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == toggleKey then
			isVisible = not isVisible
			main.Visible = isVisible
		end
	end)

	return uiState
end

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
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Instance.new("UIListLayout", page).Padding = UDim.new(0, 10)
	
	tabBtn.MouseButton1Click:Connect(function()
		for _, v in pairs(ui.container:GetChildren()) do
			if v:IsA("ScrollingFrame") then v.Visible = false end
		end
		page.Visible = true
	end)
	return page
end

function mod.addSection(parent, text)
	local label = Instance.new("TextLabel", parent)
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Text = "  " .. text:upper()
	label.TextColor3 = Color3.fromRGB(120, 120, 140)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 10
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
end

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

-- FIXED DROPDOWN
function mod.addDropdown(parent, text, options, callback)
	local expanded = false
	local frame = Instance.new("Frame", parent)
	frame.Size = UDim2.new(1, -10, 0, 35)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.ClipsDescendants = true
	Instance.new("UICorner", frame)
	
	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.new(1, 0, 0, 35)
	btn.BackgroundTransparency = 1
	btn.Text = "  " .. text .. " ▼"
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.Gotham
	btn.TextXAlignment = Enum.TextXAlignment.Left
	
	btn.MouseButton1Click:Connect(function()
		expanded = not expanded
		frame.Size = expanded and UDim2.new(1, -10, 0, (#options * 30) + 40) or UDim2.new(1, -10, 0, 35)
	end)
	
	for i, v in ipairs(options) do
		local opt = Instance.new("TextButton", frame)
		opt.Size = UDim2.new(1, 0, 0, 30)
		opt.Position = UDim2.new(0, 0, 0, (i * 30) + 5)
		opt.BackgroundTransparency = 1
		opt.Text = tostring(v)
		opt.TextColor3 = Color3.fromRGB(180, 180, 180)
		opt.Font = Enum.Font.Gotham
		opt.MouseButton1Click:Connect(function()
			btn.Text = "  " .. text .. ": " .. tostring(v)
			expanded = false
			frame.Size = UDim2.new(1, -10, 0, 35)
			callback(v)
		end)
	end
end

-- ADDED TOGGLE (SWITCH)
function mod.addToggle(parent, text, default, callback)
	local state = default or false
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(1, -10, 0, 35)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	btn.Text = "  " .. text
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.Gotham
	btn.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UICorner", btn)

	local box = Instance.new("Frame", btn)
	box.Size = UDim2.new(0, 20, 0, 20)
	box.Position = UDim2.new(1, -30, 0.5, -10)
	box.BackgroundColor3 = state and themeColor or Color3.fromRGB(50, 50, 60)
	Instance.new("UICorner", box)

	btn.MouseButton1Click:Connect(function()
		state = not state
		box.BackgroundColor3 = state and themeColor or Color3.fromRGB(50, 50, 60)
		callback(state)
	end)
end

return mod
