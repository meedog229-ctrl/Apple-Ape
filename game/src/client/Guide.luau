--!strict
-- Teach-by-doing guide (blueprint R1/R3): a glowing beam from your feet to the next target
-- plus a bouncing arrow over it. No text walls.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Guide = {}

local player = Players.LocalPlayer

local anchor = Instance.new("Part")
anchor.Name = "GuideTarget"
anchor.Anchored = true
anchor.CanCollide = false
anchor.CanQuery = false
anchor.CanTouch = false
anchor.Transparency = 1
anchor.Size = Vector3.new(0.2, 0.2, 0.2)
anchor.Parent = Workspace

local targetAttachment = Instance.new("Attachment")
targetAttachment.Parent = anchor

local beam = Instance.new("Beam")
beam.Attachment1 = targetAttachment
beam.Color = ColorSequence.new(Config.Colors.golden)
beam.LightEmission = 1
beam.LightInfluence = 0
beam.Width0 = 0.9
beam.Width1 = 0.9
beam.FaceCamera = true
beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
beam.TextureMode = Enum.TextureMode.Static
beam.TextureLength = 2
beam.TextureSpeed = 2
beam.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.6),
	NumberSequenceKeypoint.new(0.5, 0.2),
	NumberSequenceKeypoint.new(1, 0.1),
})
beam.Enabled = false
beam.Parent = anchor

local arrow = Instance.new("BillboardGui")
arrow.Name = "GuideArrow"
arrow.Size = UDim2.fromOffset(90, 90)
arrow.AlwaysOnTop = true
arrow.LightInfluence = 0
arrow.Adornee = anchor
arrow.Enabled = false
local arrowLabel = Instance.new("TextLabel")
arrowLabel.BackgroundTransparency = 1
arrowLabel.Size = UDim2.fromScale(1, 1)
arrowLabel.Font = Enum.Font.FredokaOne
arrowLabel.TextScaled = true
arrowLabel.Text = "⬇"
arrowLabel.TextColor3 = Config.Colors.golden
local arrowStroke = Instance.new("UIStroke")
arrowStroke.Thickness = 4
arrowStroke.Color = Config.Colors.uiStroke
arrowStroke.Parent = arrowLabel
arrowLabel.Parent = arrow
arrow.Parent = player:WaitForChild("PlayerGui")

local target: Vector3? = nil
local arrowHeight = 6

-- Point the guide at a world position (nil hides it).
function Guide.setTarget(position: Vector3?, height: number?)
	target = position
	arrowHeight = height or 6
	if position then
		anchor.Position = position + Vector3.new(0, 0.5, 0)
	end
end

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local show = target ~= nil and root ~= nil
	if show and root then
		local rootAttachment = root:FindFirstChild("GuideAttachment") :: Attachment?
		if not rootAttachment then
			local a = Instance.new("Attachment")
			a.Name = "GuideAttachment"
			a.Position = Vector3.new(0, -2.5, 0)
			a.Parent = root
			rootAttachment = a
		end
		beam.Attachment0 = rootAttachment
		-- hide the beam once you're basically there; keep the arrow
		beam.Enabled = (root.Position - (target :: Vector3)).Magnitude > 10
		arrow.StudsOffsetWorldSpace = Vector3.new(0, arrowHeight + math.sin(os.clock() * 5) * 0.8, 0)
		arrow.Enabled = true
	else
		beam.Enabled = false
		arrow.Enabled = false
	end
end)

return Guide
