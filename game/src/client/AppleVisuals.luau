--!strict
-- Client-side apple rendering + magnet pickup.
-- The server already decided every apple's id and landing spot; we animate them,
-- ask to collect nearby ones, and only "pop" them once the server confirms.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Juice = require(script.Parent.Juice)
local Sounds = require(script.Parent.Sounds)

export type AppleInfo = { id: number, position: Vector3, golden: boolean }

type Visual = {
	id: number,
	part: Part,
	golden: boolean,
	shared: boolean,
	from: Vector3,
	to: Vector3,
	spawnedAt: number,
	delay: number,
	flight: number,
	arc: number,
	landed: boolean,
	pendingSince: number?, -- collect requested, waiting for server
	expiresAt: number,
}

local AppleVisuals = {}

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "ClientApples"
folder.Parent = Workspace

local visuals: { [number]: Visual } = {}
local pool: { Part } = {}
local basketFull = false
local outgoing: { number } = {}
local lastSend = 0
local comboCount = 0
local comboAt = 0

AppleVisuals.onGolden = nil :: ((position: Vector3) -> ())?

local function makePart(): Part
	local p = table.remove(pool)
	if p then
		return p
	end
	p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(1.4, 1.4, 1.4)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic
	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Size = Vector3.new(0.15, 0.45, 0.15)
	stem.Color = Config.Colors.trunk
	stem.Anchored = true
	stem.CanCollide = false
	stem.CanQuery = false
	stem.CanTouch = false
	stem.Parent = p
	return p
end

local function release(v: Visual)
	visuals[v.id] = nil
	local p = v.part
	local glow = p:FindFirstChild("Glow")
	if glow then
		glow:Destroy()
	end
	local sparkle = p:FindFirstChild("Sparkle")
	if sparkle then
		sparkle:Destroy()
	end
	p.Parent = nil
	if #pool < 150 then
		table.insert(pool, p)
	else
		p:Destroy()
	end
end

local function spawnVisual(
	info: AppleInfo,
	from: Vector3,
	delay: number,
	isShared: boolean,
	flight: number,
	arc: number
)
	if visuals[info.id] then
		return
	end
	local p = makePart()
	p.Color = if info.golden then Config.Colors.golden else Config.Colors.apple
	p.Material = if info.golden then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p.Transparency = 0
	p.Position = from
	if info.golden then
		local light = Instance.new("PointLight")
		light.Name = "Glow"
		light.Color = Config.Colors.golden
		light.Range = 10
		light.Brightness = 2
		light.Parent = p
		local e = Instance.new("ParticleEmitter")
		e.Name = "Sparkle"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Config.Colors.golden)
		e.LightEmission = 1
		e.Size = NumberSequence.new(0.5, 0)
		e.Lifetime = NumberRange.new(0.5, 0.9)
		e.Rate = 12
		e.Speed = NumberRange.new(1, 3)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Parent = p
	end
	p.Parent = folder
	visuals[info.id] = {
		id = info.id,
		part = p,
		golden = info.golden,
		shared = isShared,
		from = from,
		to = info.position,
		spawnedAt = os.clock(),
		delay = delay,
		flight = flight,
		arc = arc,
		landed = false,
		pendingSince = nil,
		expiresAt = os.clock() + Config.Apple.lifetime - 0.5,
	}
end

-- Apples bursting out of a tree you shook.
function AppleVisuals.burst(apples: { AppleInfo }, from: Vector3)
	for i, info in apples do
		spawnVisual(info, from, (i - 1) * 0.025, false, 0.55, 6)
	end
end

-- Apple Rain: apples fall from the sky.
function AppleVisuals.rain(apples: { AppleInfo })
	for _, info in apples do
		spawnVisual(info, info.position + Vector3.new(0, 60, 0), 0, true, 1.1, 0)
	end
end

function AppleVisuals.removeShared(ids: { number })
	for _, id in ids do
		local v = visuals[id]
		if v and not v.pendingSince then
			release(v)
		end
	end
end

function AppleVisuals.setBasketFull(full: boolean)
	basketFull = full
end

local function popCombo(): number
	local now = os.clock()
	if now - comboAt > 1.2 then
		comboCount = 0
	end
	comboAt = now
	comboCount += 1
	return math.min(1 + comboCount * 0.04, 2)
end

function AppleVisuals.onCollectResult(collectedIds: { number }, _goldenGained: number, reason: string?)
	for _, id in collectedIds do
		local v = visuals[id]
		if v then
			local pos = v.part.Position
			if v.golden then
				Sounds.play("golden", 1.5, 0.8)
				Juice.popNumber(pos, 1, "golden")
				Juice.sparkle(pos, Config.Colors.golden, 30)
				if AppleVisuals.onGolden then
					AppleVisuals.onGolden(pos)
				end
			else
				Sounds.play("pop", popCombo(), 0.35)
				Juice.popNumber(pos, 1, "apple")
			end
			release(v)
		end
	end
	if reason == "full" then
		basketFull = true
	end
end

local function root(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local r = root()
	local rootPos = r and r.Position
	for _, v in visuals do
		local t = now - v.spawnedAt - v.delay
		if now > v.expiresAt and not v.pendingSince then
			release(v)
			continue
		end
		if t < 0 then
			continue
		end
		if v.pendingSince and rootPos then
			-- fly toward the player while the server confirms
			local alpha = math.clamp((now - v.pendingSince) / 0.18, 0, 1)
			v.part.Position = v.part.Position:Lerp(rootPos, alpha * 0.5)
			if now - v.pendingSince > 1.5 then
				-- server said no (or packet lost): put it back on the ground
				v.pendingSince = nil
				v.part.Position = v.to
			end
		elseif not v.landed then
			local a = math.clamp(t / v.flight, 0, 1)
			local pos = v.from:Lerp(v.to, a)
			if v.arc > 0 then
				pos += Vector3.new(0, v.arc * 4 * a * (1 - a), 0)
			else
				-- rain: ease-in fall
				pos = v.from:Lerp(v.to, a * a)
			end
			v.part.Position = pos
			if a >= 1 then
				v.landed = true
			end
		else
			-- idle bob + spin so apples on the ground read as "pick me up"
			local bob = math.sin((now + v.id) * 4) * 0.15
			v.part.CFrame = CFrame.new(v.to + Vector3.new(0, bob, 0)) * CFrame.Angles(0, now * 2 + v.id, 0)
		end
		local stem = v.part:FindFirstChild("Stem") :: BasePart?
		if stem then
			stem.CFrame = v.part.CFrame * CFrame.new(0, 0.85, 0)
		end

		-- magnet: queue landed apples near us for a collect request
		if rootPos and v.landed and not v.pendingSince then
			local wantsIt = v.golden or not basketFull
			if wantsIt and (v.to - rootPos).Magnitude <= Config.Apple.magnetRadius then
				v.pendingSince = now
				table.insert(outgoing, v.id)
			end
		end
	end

	if #outgoing > 0 and now - lastSend > 0.08 then
		lastSend = now
		local batch = {}
		for i = 1, math.min(#outgoing, Config.Apple.maxPerCollectRequest) do
			batch[i] = outgoing[i]
		end
		for _ = 1, #batch do
			table.remove(outgoing, 1)
		end
		Remotes.Collect:FireServer(batch)
	end
end)

return AppleVisuals
