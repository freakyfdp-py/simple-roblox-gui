local mod = {}

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function rect(offset_x, offset_y, width, height, corner_radius, screenGui)
	local rectangle = Instance.new("Frame")
	rectangle.Size = UDim2.new(0, width, 0, height)
	rectangle.Position = UDim2.new(0.5, offset_x, 0.5, offset_y)
	rectangle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	rectangle.BorderSizePixel = 2
	rectangle.Parent = screenGui
	
	if corner_radius and corner_radius > 0 then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, corner_radius)
		corner.Parent = rectangle
	end
	
	return rectangle
end

local function text(content, offset_x, offset_y, width, height, font, font_size, color, screenGui, center)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, width, 0, height)
	label.Position = UDim2.new(0.5, offset_x, 0.5, offset_y)
	label.BackgroundTransparency = 1
	label.Text = content
	label.Font = font or Enum.Font.SourceSans
	label.TextSize = font_size or 24
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	
	if center then
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
	else
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
	end
	
	label.Parent = screenGui
	return label
end

mod.rect = rect
mod.text = text

mod.init = function(title, blur)
	title = title or "Example Title"
	blur = blur or false
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = title
	screenGui.Parent = playerGui

	local panel = rect(175 / 2, 325 / 2, 175, 325, 0, screenGui)
	text(title, 0, 0, 36, 12, nil, 16, Color3.fromRGB(255, 255, 255), panel, true)
	return screenGui
end

return mod
