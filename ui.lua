local module = {}

local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local function createText(text, parent)
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(0, 200, 0, 50)
	textLabel.Position = UDim2.new(0.5, -100, 0.5, -25)
	textLabel.Text = text or "NULL"
	textLabel.Parent = parent
	return textLabel
end

module.init = function init(title)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Parent = playerGui
	screenGui.Name = NextInteger(1000000, 9999999999)
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 200, 0, 100)
	mainFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
	mainFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	mainFrame.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	
	local function visible(state)
		if not state then
			local state = true
		end
		screenGui.Enabled = state
	end
	
	local function isVisible()
		return screenGui.Visible
	end
end

return module
