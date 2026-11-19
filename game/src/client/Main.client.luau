-- Apple Ape client controller: input -> remotes, remotes -> visuals/HUD, guide + goals.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local Hud = require(script.Parent.Hud)
local Juice = require(script.Parent.Juice)
local Sounds = require(script.Parent.Sounds)
local AppleVisuals = require(script.Parent.AppleVisuals)
local Guide = require(script.Parent.Guide)

local player = Players.LocalPlayer
local Steps = Config.TutorialSteps

---------------------------------------------------------------------------
-- trees
---------------------------------------------------------------------------
local treesById: { [number]: Model } = {}
local function registerTree(model: Instance)
	if model:IsA("Model") then
		local id = model:GetAttribute("TreeId")
		if type(id) == "number" then
			treesById[id] = model
		end
	end
end
for _, model in CollectionService:GetTagged("AppleTree") do
	registerTree(model)
end
CollectionService:GetInstanceAddedSignal("AppleTree"):Connect(registerTree)

local function treeBase(model: Model): Vector3?
	local base = model:GetAttribute("Base")
	return if typeof(base) == "Vector3" then base else nil
end

local function burstPoint(model: Model): Vector3
	local trunk = model.PrimaryPart
	local a = trunk and trunk:FindFirstChild("BurstPoint") :: Attachment?
	if a then
		return a.WorldPosition
	end
	return model:GetPivot().Position + Vector3.new(0, 10, 0)
end

local function rootPart(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local nearestTree: Model? = nil
local nearestTreeId: number? = nil
local highlight = Instance.new("Highlight")
highlight.FillTransparency = 1
highlight.OutlineColor = Config.Colors.golden
highlight.OutlineTransparency = 0.2
highlight.DepthMode = Enum.HighlightDepthMode.Occluded
highlight.Parent = Workspace

local function closestTree(maxDistance: number): (Model?, number?, number)
	local root = rootPart()
	if not root then
		return nil, nil, math.huge
	end
	local best, bestId, bestDist = nil, nil, maxDistance
	for id, model in treesById do
		local base = treeBase(model)
		if base then
			local d = Vector3.new(root.Position.X - base.X, 0, root.Position.Z - base.Z).Magnitude
			if d < bestDist then
				best, bestId, bestDist = model, id, d
			end
		end
	end
	return best, bestId, bestDist
end

---------------------------------------------------------------------------
-- state helpers
---------------------------------------------------------------------------
local function attr(name: string, default: number): number
	local v = player:GetAttribute(name)
	return if type(v) == "number" then v else default
end

local function basketFull(): boolean
	return attr("Basket", 0) >= attr("Capacity", Config.Basket.baseCapacity)
end

local function raining(): boolean
	local endsAt = Workspace:GetAttribute("RainEndsAt")
	return type(endsAt) == "number" and endsAt > Workspace:GetServerTimeNow()
end

---------------------------------------------------------------------------
-- shaking
---------------------------------------------------------------------------
local lastShake = 0
local fullWarnedAt = 0

local function warnFull()
	if os.clock() - fullWarnedAt > 2.5 then
		fullWarnedAt = os.clock()
		Hud.banner("BASKET FULL! Go SELL 🍎", Config.Colors.golden, 2)
		Sounds.play("error", 0.7, 0.4)
	end
end

local function tryShake()
	if not player:GetAttribute("Loaded") then
		return
	end
	local tree, treeId = nearestTree, nearestTreeId
	if not tree or not treeId then
		Hud.toast("Walk up to a tree first!")
		return
	end
	if basketFull() then
		warnFull()
		return
	end
	local now = os.clock()
	if now - lastShake < Config.Shake.cooldown then
		return
	end
	lastShake = now
	-- predicted feedback: feel instant even with latency
	Juice.wobbleTree(tree, 1)
	Juice.leafBurst(tree, 16)
	Juice.addTrauma(0.18)
	Sounds.play("shake", 0.9 + math.random() * 0.25, 0.6)
	Remotes.Shake:FireServer(treeId)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
		tryShake()
	elseif
		input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	then
		-- clicking/tapping the tree itself also shakes it
		local camera = Workspace.CurrentCamera
		local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		local treeParts = {}
		for _, model in treesById do
			table.insert(treeParts, model)
		end
		params.FilterDescendantsInstances = treeParts
		local result = Workspace:Raycast(ray.Origin, ray.Direction * 200, params)
		if result and nearestTree and result.Instance:IsDescendantOf(nearestTree) then
			tryShake()
		end
	end
end)

---------------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------------
Hud.build({
	onShake = tryShake,
	onBuy = function(kind: string)
		Remotes.BuyUpgrade:FireServer(kind)
	end,
})

AppleVisuals.onGolden = function(_position: Vector3)
	Juice.bigMoment(Hud.flashFrame(), 0.8)
end

---------------------------------------------------------------------------
-- goals + guide (blueprint R3/R4: one obvious next step at a time)
---------------------------------------------------------------------------
local function updateGoalAndGuide()
	local step = attr("TutorialStep", 0)

	if raining() then
		Hud.setGoal("APPLE RAIN! Grab apples at the plaza!")
		Guide.setTarget(Config.Drop.plazaCenter, 8)
		return
	end
	if basketFull() then
		Hud.setGoal("Basket full! Sell at the SELL stand")
		Guide.setTarget(Config.World.sellPad, 6)
		return
	end
	if step < Steps.FirstShake then
		Hud.setGoal("Walk to a tree and SHAKE it!")
		local tree = closestTree(math.huge)
		Guide.setTarget(tree and treeBase(tree), 15)
		return
	end
	if step < Steps.FirstSell then
		Hud.setGoal(`Fill your basket ({attr("Basket", 0)}/{attr("Capacity", 25)})`)
		Guide.setTarget(nil)
		return
	end
	if step < Steps.FirstUpgrade then
		Hud.setGoal("Open the SHOP and buy a Bigger Basket!")
		Guide.setTarget(nil)
		return
	end
	-- after the tutorial: point at the next affordable upgrade, else the next drop
	Guide.setTarget(nil)
	local coins = attr("Coins", 0)
	local basketCost = Config.upgradeCost("Basket", attr("BasketLevel", 1))
	local shakeCost = Config.upgradeCost("Shake", attr("ShakeLevel", 1))
	local cheapest = math.min(basketCost, shakeCost)
	if coins >= cheapest then
		Hud.setGoal("You can afford an upgrade! Open the SHOP")
	else
		local at = Workspace:GetAttribute("NextDropAt")
		local left = if type(at) == "number" then at - Workspace:GetServerTimeNow() else 0
		Hud.setGoal(`Earn 🪙{Format.short(cheapest - coins)} more · Drop in {Format.clock(left)}`)
	end
end

---------------------------------------------------------------------------
-- attribute -> HUD
---------------------------------------------------------------------------
local function refreshBasket()
	Hud.setBasket(attr("Basket", 0), attr("Capacity", Config.Basket.baseCapacity))
	AppleVisuals.setBasketFull(basketFull())
	updateGoalAndGuide()
end

local lastGolden = -1
local function refreshAll()
	refreshBasket()
	Hud.setCoins(attr("Coins", 0))
	local golden = attr("Golden", 0)
	if golden ~= lastGolden then
		Hud.setGolden(golden)
		lastGolden = golden
	end
	Hud.refreshShop()
end

for _, name in { "Basket", "Capacity" } do
	player:GetAttributeChangedSignal(name):Connect(refreshBasket)
end
player:GetAttributeChangedSignal("Coins"):Connect(function()
	Hud.setCoins(attr("Coins", 0))
	updateGoalAndGuide()
end)
player:GetAttributeChangedSignal("Golden"):Connect(function()
	Hud.setGolden(attr("Golden", 0))
end)
for _, name in { "BasketLevel", "ShakeLevel" } do
	player:GetAttributeChangedSignal(name):Connect(Hud.refreshShop)
end
player:GetAttributeChangedSignal("TutorialStep"):Connect(updateGoalAndGuide)
player:GetAttributeChangedSignal("Loaded"):Connect(refreshAll)
if player:GetAttribute("Loaded") then
	refreshAll()
end

---------------------------------------------------------------------------
-- remotes
---------------------------------------------------------------------------
Remotes.ShakeResult.OnClientEvent:Connect(function(treeId: number, apples, info)
	local tree = treesById[treeId]
	if not tree then
		return
	end
	AppleVisuals.burst(apples, burstPoint(tree))
	if info and info.firstShake then
		Hud.banner("WOW! MEGA SHAKE! 🍎🍎🍎", Config.Colors.golden, 2.2)
		Juice.wobbleTree(tree, 2)
		Juice.leafBurst(tree, 40)
		Juice.bigMoment(Hud.flashFrame(), 1)
	end
end)

Remotes.TreeShaken.OnClientEvent:Connect(function(treeId: number, userId: number)
	if userId == player.UserId then
		return -- already predicted locally
	end
	local tree = treesById[treeId]
	if tree then
		Juice.wobbleTree(tree, 0.7)
		Juice.leafBurst(tree, 8)
	end
end)

Remotes.CollectResult.OnClientEvent:Connect(function(collectedIds, goldenGained, reason)
	AppleVisuals.onCollectResult(collectedIds, goldenGained, reason)
	if reason == "full" then
		warnFull()
	end
end)

Remotes.ApplesSpawned.OnClientEvent:Connect(function(apples)
	AppleVisuals.rain(apples)
end)

Remotes.ApplesRemoved.OnClientEvent:Connect(function(ids)
	AppleVisuals.removeShared(ids)
end)

Remotes.Notify.OnClientEvent:Connect(function(kind: string, data)
	data = data or {}
	if kind == "BasketFull" then
		warnFull()
	elseif kind == "Sold" then
		Sounds.play("sell", 1.2, 0.7)
		Hud.banner(`SOLD! +{Format.short(data.coins or 0)} 🪙`, Config.Colors.coin, 1.6)
		local root = rootPart()
		if root then
			Juice.sparkle(root.Position, Config.Colors.coin, 30)
			Juice.popNumber(root.Position, data.coins or 0, "coin")
		end
		Juice.addTrauma(0.15)
		if attr("TutorialStep", 0) < Steps.FirstUpgrade then
			task.delay(1.2, function()
				Hud.pulseShop()
			end)
		end
	elseif kind == "Upgraded" then
		Sounds.play("sell", 1.6, 0.6)
		local title = if data.kind == "Basket" then "BIGGER BASKET" else "STRONGER SHAKE"
		Hud.banner(`{title}! Lv.{data.level}`, Config.Colors.good, 1.6)
		Juice.bigMoment(nil, 0.4)
	elseif kind == "NotEnoughCoins" then
		Sounds.play("error", 0.7, 0.4)
		Hud.toast(`Need 🪙{Format.short(data.need or 0)} more coins`, Config.Colors.bad)
	elseif kind == "MaxLevel" then
		Hud.toast("Already max level!")
	elseif kind == "RainStarted" then
		Hud.banner("🍎 APPLE RAIN! Run to the plaza! 🍎", Config.Colors.golden, 2.5)
		Juice.bigMoment(Hud.flashFrame(), 0.6)
		updateGoalAndGuide()
	elseif kind == "RainEnded" then
		Hud.toast("Apple Rain is over. Next drop soon!")
		updateGoalAndGuide()
	end
end)

---------------------------------------------------------------------------
-- per-frame: nearest tree + shake button; every 0.2s: drop countdown
---------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local tree, id = closestTree(Config.Shake.range - 1)
	nearestTree, nearestTreeId = tree, id
	highlight.Adornee = tree
	Hud.setShakeVisible(tree ~= nil)
end)

local worldCountdown: TextLabel? = nil
local lastPulseSecond = -1
task.spawn(function()
	while true do
		task.wait(0.2)
		local now = Workspace:GetServerTimeNow()
		local rainEnds = Workspace:GetAttribute("RainEndsAt")
		local nextAt = Workspace:GetAttribute("NextDropAt")
		local text, urgent, isRaining = "🍎 APPLE DROP", false, false
		if type(rainEnds) == "number" and rainEnds > now then
			isRaining = true
			text = `🍎 APPLE RAIN! {Format.clock(rainEnds - now)}`
		elseif type(nextAt) == "number" then
			local left = nextAt - now
			urgent = left <= 10
			text = `🍎 APPLE DROP IN {Format.clock(left)}`
			-- tension build-up in the last 10 seconds (blueprint F5)
			local second = math.floor(left)
			if urgent and second ~= lastPulseSecond and left > 0 then
				lastPulseSecond = second
				Hud.pulseDrop()
				Sounds.play("click", 1.4 + (10 - second) * 0.05, 0.3)
			end
		end
		Hud.setDrop(text, urgent, isRaining)

		if not worldCountdown then
			local map = Workspace:FindFirstChild("Map")
			local tower = map and map:FindFirstChild("DropTower")
			local board = tower and tower:FindFirstChild("DropCountdown")
			worldCountdown = board and board:FindFirstChild("Text") :: TextLabel?
		end
		if worldCountdown then
			worldCountdown.Text = text
		end

		-- keep the "drop in m:ss" goal fresh
		if attr("TutorialStep", 0) >= Steps.FirstUpgrade and not basketFull() then
			updateGoalAndGuide()
		end
	end
end)

-- first-session guide pointer even before any attribute changes
task.delay(1, updateGoalAndGuide)
