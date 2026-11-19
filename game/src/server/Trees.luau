--!strict
-- Shake handling. Client says "I shook tree N"; server checks range, cooldown and basket,
-- decides how many apples fall and where, then tells the shaker (and wobbles the tree for all).

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.PlayerData)
local PlayerState = require(script.Parent.PlayerState)
local Apples = require(script.Parent.Apples)
local Analytics = require(script.Parent.Analytics)
local RateLimiter = require(script.Parent.RateLimiter)

local Trees = {}

local treeBases: { [number]: Vector3 } = {}
local shakeLimiter = RateLimiter.new({
	capacity = 6,
	refillRate = 1 / Config.Shake.cooldown,
	defaultMinInterval = Config.Shake.cooldown * 0.8, -- small allowance for network jitter
})
local rng = Random.new()

local function landingSpots(base: Vector3, count: number): { Vector3 }
	local spots = {}
	for i = 1, count do
		local angle = (i / count) * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		local radius = rng:NextNumber(Config.Apple.landMinRadius, Config.Apple.landMaxRadius)
		spots[i] = base + Vector3.new(math.cos(angle) * radius, 0.6, math.sin(angle) * radius)
	end
	return spots
end

local function onShake(player: Player, treeId: any)
	if type(treeId) ~= "number" or treeId % 1 ~= 0 then
		return
	end
	local base = treeBases[treeId]
	if not base then
		return
	end
	local ok = shakeLimiter:canPerform(player, "shake")
	if not ok then
		return
	end
	local data = PlayerData.get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not data or not root then
		return
	end
	local flat = Vector3.new(root.Position.X - base.X, 0, root.Position.Z - base.Z)
	if flat.Magnitude > Config.Shake.range then
		return
	end
	local capacity = Config.capacity(data.basketLevel)
	if data.basket >= capacity then
		Remotes.Notify:FireClient(player, "BasketFull", { capacity = capacity })
		return
	end

	local firstShake = data.tutorialStep < Config.TutorialSteps.FirstShake
	local count = Config.applesPerShake(data.shakeLevel)
	local goldenIndex: number? = nil
	if firstShake then
		-- blueprint R2: a huge first payoff + a guaranteed golden apple ("moment of joy")
		count *= Config.Tutorial.firstShakeMultiplier
		goldenIndex = 1
	elseif rng:NextNumber() < Config.Shake.goldenChance then
		goldenIndex = rng:NextInteger(1, count)
	end
	count = math.min(count, 60)

	data.totalShakes += 1
	local infos = Apples.spawnPersonal(player, landingSpots(base, count), goldenIndex)
	Remotes.ShakeResult:FireClient(player, treeId, infos, { firstShake = firstShake })
	Remotes.TreeShaken:FireAllClients(treeId, player.UserId)
	PlayerState.reachStep(player, Config.TutorialSteps.FirstShake)
	if data.totalShakes % 50 == 0 then
		Analytics.custom(player, "Shakes50", data.totalShakes)
	end
end

function Trees.init(trees: { [number]: Model })
	for id, model in trees do
		local base = model:GetAttribute("Base")
		if typeof(base) == "Vector3" then
			treeBases[id] = base
		end
	end
	Remotes.Shake.OnServerEvent:Connect(onShake)
end

return Trees
