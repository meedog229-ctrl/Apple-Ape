--!strict
-- Game feel (blueprint F1/F2): tree wobble, leaf bursts, camera shake (trauma model),
-- FOV punch + flash "hit-stop" for golden moments, floating numbers.
-- All local and cosmetic: nothing here affects gameplay state.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Juice = {}

local player = Players.LocalPlayer

---------------------------------------------------------------------------
-- Camera shake: add trauma (0..1); shake strength = trauma^2, decays over time.
---------------------------------------------------------------------------
local trauma = 0
local MAX_ANGLE = math.rad(2.2)
local MAX_OFFSET = 0.35
Juice.shakeEnabled = true -- expose for a future settings toggle (motion sensitivity)

function Juice.addTrauma(amount: number)
	trauma = math.clamp(trauma + amount, 0, 1)
end

RunService:BindToRenderStep("AppleApeCameraShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if trauma <= 0 then
		return
	end
	trauma = math.max(0, trauma - dt * 1.6)
	if not Juice.shakeEnabled then
		return
	end
	local camera = Workspace.CurrentCamera
	local s = trauma * trauma
	local t = os.clock() * 25
	local rx = (math.noise(t, 1) * 2) * MAX_ANGLE * s
	local ry = (math.noise(t, 2) * 2) * MAX_ANGLE * s
	local rz = (math.noise(t, 3) * 2) * MAX_ANGLE * s
	local offset = Vector3.new(math.noise(t, 4), math.noise(t, 5), 0) * MAX_OFFSET * s
	camera.CFrame = camera.CFrame * CFrame.new(offset) * CFrame.Angles(rx, ry, rz)
end)

---------------------------------------------------------------------------
-- Tree wobble: rotate the whole tree around its base, damped spring style.
---------------------------------------------------------------------------
local wobbling: { [Model]: { start: number, strength: number, original: CFrame } } = {}

function Juice.wobbleTree(tree: Model, strength: number?)
	local state = wobbling[tree]
	if state then
		state.start = os.clock()
		state.strength = math.max(state.strength, strength or 1)
	else
		wobbling[tree] = { start = os.clock(), strength = strength or 1, original = tree:GetPivot() }
	end
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for tree, state in wobbling do
		local base = tree:GetAttribute("Base")
		if typeof(base) ~= "Vector3" or not tree.Parent then
			wobbling[tree] = nil
			continue
		end
		local t = now - state.start
		local duration = 0.55
		if t >= duration then
			tree:PivotTo(state.original)
			wobbling[tree] = nil
			continue
		end
		local damp = (1 - t / duration) ^ 2
		local angle = math.sin(t * 38) * math.rad(7) * state.strength * damp
		local squash = 1 + math.sin(t * 38) * 0.04 * damp -- tiny "breathing" via tilt combo
		local around = CFrame.new(base) * CFrame.Angles(angle * 0.6, 0, angle) * CFrame.new(-base)
		tree:PivotTo(around * state.original * CFrame.new(0, (squash - 1) * 2, 0))
	end
end)

---------------------------------------------------------------------------
-- Leaf burst from the canopy (one emitter per tree, created lazily, Emit() bursts).
---------------------------------------------------------------------------
local emitters: { [Model]: ParticleEmitter } = {}

local function leafEmitter(tree: Model): ParticleEmitter?
	local existing = emitters[tree]
	if existing then
		return existing
	end
	local trunk = tree.PrimaryPart
	local burst = trunk and trunk:FindFirstChild("BurstPoint") :: Attachment?
	if not burst then
		return nil
	end
	local e = Instance.new("ParticleEmitter")
	e.Name = "LeafBurst"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Config.Colors.leaf, Config.Colors.leafDark)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0.2) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.6, 1.1)
	e.Speed = NumberRange.new(8, 16)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, -18, 0)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-200, 200)
	e.Rate = 0
	e.LightInfluence = 0.6
	e.Parent = burst
	emitters[tree] = e
	return e
end

function Juice.leafBurst(tree: Model, amount: number?)
	local e = leafEmitter(tree)
	if e then
		e:Emit(amount or 18)
	end
end

---------------------------------------------------------------------------
-- Sparkle burst at a world position (golden pickups, sells).
---------------------------------------------------------------------------
function Juice.sparkle(position: Vector3, color: Color3, amount: number?)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.Position = position
	holder.Parent = Workspace
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Speed = NumberRange.new(10, 22)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Parent = holder
	e:Emit(amount or 24)
	Debris:AddItem(holder, 1.5)
end

---------------------------------------------------------------------------
-- Floating "+N" text above a world position. Accumulates rapid pickups into one label.
---------------------------------------------------------------------------
local active: { gui: BillboardGui, label: TextLabel, amount: number, born: number, kind: string }? = nil

function Juice.popNumber(position: Vector3, amount: number, kind: "apple" | "golden" | "coin")
	local now = os.clock()
	if kind ~= "golden" and active and active.kind == kind and now - active.born < 0.6 and active.gui.Parent then
		active.amount += amount
		active.born = now
		active.label.Text = "+" .. active.amount
		active.label.TextSize = math.min(60, 34 + active.amount)
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 70)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.1, 0.1, 0.1)
	holder.Position = position
	holder.Parent = Workspace
	gui.Adornee = holder
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 36
	label.TextColor3 = if kind == "golden"
		then Config.Colors.golden
		elseif kind == "coin" then Config.Colors.coin
		else Config.Colors.white
	label.Text = (if kind == "golden" then "+1 GOLDEN!" else "+" .. amount)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Config.Colors.uiStroke
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	active = { gui = gui, label = label, amount = amount, born = now, kind = kind }

	-- rise and fade after a short hold
	task.spawn(function()
		local entry = active
		while entry and os.clock() - entry.born < 0.6 do
			task.wait(0.1)
		end
		local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(gui, tweenInfo, { StudsOffsetWorldSpace = Vector3.new(0, 7, 0) }):Play()
		TweenService:Create(label, tweenInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, tweenInfo, { Transparency = 1 }):Play()
		task.wait(0.65)
		gui:Destroy()
		holder:Destroy()
	end)
end

---------------------------------------------------------------------------
-- "Hit-stop" for big moments (Sakurai: stop for big moments): FOV punch + white flash.
-- `flash` is a full-screen Frame owned by the HUD.
---------------------------------------------------------------------------
local baseFov: number? = nil

function Juice.bigMoment(flash: Frame?, strength: number?)
	local s = strength or 1
	local camera = Workspace.CurrentCamera
	baseFov = baseFov or camera.FieldOfView
	local fov = baseFov :: number
	camera.FieldOfView = fov - 8 * s
	TweenService:Create(camera, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		FieldOfView = fov,
	}):Play()
	Juice.addTrauma(0.35 * s)
	if flash then
		flash.BackgroundTransparency = 0.35
		TweenService:Create(flash, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	end
end

return Juice
