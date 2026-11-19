--!strict
-- Builds the prototype map in code: ground, starter orchard, sell stand, Apple Drop plaza.
-- Primitive parts only so it works in a fresh place with no uploaded assets.
-- Replace with real models later; keep the "AppleTree" tag + TreeId attribute contract.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local World = {}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	-- Shape first (it can change Size), CFrame/Position last (table order is not guaranteed)
	if props.Shape then
		p.Shape = props.Shape
	end
	for key, value in props do
		if key ~= "Shape" and key ~= "CFrame" and key ~= "Position" then
			(p :: any)[key] = value
		end
	end
	if props.CFrame then
		p.CFrame = props.CFrame
	elseif props.Position then
		p.Position = props.Position
	end
	return p
end

local function label(parent: BasePart, text: string, offsetY: number, color: Color3, size: UDim2?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = size or UDim2.fromScale(10, 2.5)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 140
	gui.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = color
	t.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Config.Colors.uiStroke
	stroke.Parent = t
	t.Parent = gui
	gui.Parent = parent
	return gui
end

local function buildTree(id: number, base: Vector3, folder: Folder): Model
	local model = Instance.new("Model")
	model.Name = "AppleTree" .. id

	local trunkHeight = 9
	local trunk = part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(trunkHeight, 2.6, 2.6),
		CFrame = CFrame.new(base + Vector3.new(0, trunkHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Config.Colors.trunk,
		Material = Enum.Material.Wood,
	})
	trunk.Parent = model

	-- canopy: a few overlapping leaf balls
	local canopyCenter = base + Vector3.new(0, trunkHeight + 2.5, 0)
	local offsets = {
		Vector3.new(0, 0, 0),
		Vector3.new(3, -1, 1),
		Vector3.new(-3, -1, -1),
		Vector3.new(1, 1.5, -3),
		Vector3.new(-1, 1, 3),
	}
	for i, offset in offsets do
		local ball = part({
			Name = "Leaves" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(8, 8, 8) * (if i == 1 then 1.15 else 0.85),
			Position = canopyCenter + offset,
			Color = if i % 2 == 0 then Config.Colors.leafDark else Config.Colors.leaf,
			Material = Enum.Material.Grass,
			CanCollide = false,
		})
		ball.Parent = model
	end

	-- decorative apples hanging in the canopy (purely visual)
	local rng = Random.new(id * 97)
	for i = 1, 9 do
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.6, 0.4), rng:NextNumber(-1, 1)).Unit
		local apple = part({
			Name = "DecorApple" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.1, 1.1, 1.1),
			Position = canopyCenter + dir * 4.6,
			Color = Config.Colors.apple,
			CanCollide = false,
			CanQuery = false,
		})
		apple.Parent = model
	end

	-- attachment the client uses as the "apples burst from here" point
	local burst = Instance.new("Attachment")
	burst.Name = "BurstPoint"
	burst.WorldPosition = canopyCenter
	burst.Parent = trunk

	model.PrimaryPart = trunk
	model:SetAttribute("TreeId", id)
	model:SetAttribute("Base", base)
	CollectionService:AddTag(model, "AppleTree")
	model.Parent = folder
	return model
end

function World.build(): { trees: { [number]: Model }, sellPad: BasePart }
	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = Workspace

	-- remove the default baseplate if the place has one
	local oldBaseplate = Workspace:FindFirstChild("Baseplate")
	if oldBaseplate then
		oldBaseplate:Destroy()
	end

	local ground = part({
		Name = "Ground",
		Size = Vector3.new(400, 4, 400),
		Position = Vector3.new(0, -2, 20),
		Color = Config.Colors.grass,
		Material = Enum.Material.Grass,
	})
	ground.Parent = map

	-- spawn: faces the orchard so the first thing you see is a tree (blueprint R1)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame =
		CFrame.lookAt(Config.World.spawn + Vector3.new(0, 0.5, 0), Config.World.spawn + Vector3.new(0, 0.5, 10))
	spawn.Color = Color3.fromRGB(255, 220, 120)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = map

	-- orchard
	local treeFolder = Instance.new("Folder")
	treeFolder.Name = "Trees"
	treeFolder.Parent = map
	local trees = {}
	for i, pos in Config.World.trees do
		trees[i] = buildTree(i, pos, treeFolder)
	end

	-- sell stand: a glowing pad + a little hut sign
	local sellPad = part({
		Name = "SellPad",
		Size = Vector3.new(12, 0.6, 12),
		Position = Config.World.sellPad + Vector3.new(0, 0.3, 0),
		Color = Config.Colors.coin,
		Material = Enum.Material.Neon,
		Transparency = 0.15,
	})
	sellPad.Parent = map
	local sign = part({
		Name = "SellSign",
		Size = Vector3.new(12, 6, 1),
		Position = Config.World.sellPad + Vector3.new(0, 7, -6.5),
		Color = Color3.fromRGB(150, 100, 60),
		Material = Enum.Material.WoodPlanks,
	})
	sign.Parent = map
	label(sign, "SELL APPLES", 4.5, Config.Colors.coin, UDim2.fromScale(14, 3))
	for _, x in { -5.5, 5.5 } do
		part({
			Name = "Post",
			Size = Vector3.new(1, 10, 1),
			Position = Config.World.sellPad + Vector3.new(x, 5, -6.5),
			Color = Config.Colors.trunk,
			Material = Enum.Material.Wood,
		}).Parent =
			map
	end

	-- Apple Drop plaza: a ring the rain falls into + a countdown billboard
	local plaza = part({
		Name = "DropPlaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, Config.Drop.plazaRadius * 2, Config.Drop.plazaRadius * 2),
		CFrame = CFrame.new(Config.Drop.plazaCenter + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(240, 200, 120),
		Material = Enum.Material.Sand,
	})
	plaza.Parent = map
	local tower = part({
		Name = "DropTower",
		Size = Vector3.new(3, 14, 3),
		Position = Config.Drop.plazaCenter + Vector3.new(0, 7, 0),
		Color = Color3.fromRGB(200, 60, 50),
		Material = Enum.Material.SmoothPlastic,
	})
	tower.Parent = map
	local countdown = label(tower, "APPLE DROP", 11, Config.Colors.golden, UDim2.fromScale(16, 4))
	countdown.Name = "DropCountdown"
	countdown.MaxDistance = 400

	-- bright, friendly lighting
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
	Lighting.GlobalShadows = true
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.25
		atmosphere.Haze = 1
		atmosphere.Color = Color3.fromRGB(200, 230, 255)
		atmosphere.Parent = Lighting
	end

	return { trees = trees, sellPad = sellPad }
end

return World
