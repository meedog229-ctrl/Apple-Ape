--!strict
-- The Apple Drop (blueprint signature twist), prototype version:
-- every cycle (10 min live, 2 min in Studio, aligned to UTC) apples rain on the plaza for 30s
-- and anyone can grab them. The shared contribution pool + golden payout come in Phase B.
--
-- Clients read two Workspace attributes for the countdown:
--   NextDropAt (unix seconds, server time) and RainEndsAt (0 when not raining).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Apples = require(script.Parent.Apples)
local PlayerState = require(script.Parent.PlayerState)
local PlayerData = require(script.Parent.PlayerData)

local AppleDrop = {}

local rng = Random.new()

local function nextBoundary(now: number): number
	local interval = Config.dropInterval()
	return (math.floor(now / interval) + 1) * interval
end

local function rain()
	local endsAt = Workspace:GetServerTimeNow() + Config.Drop.rainDuration
	Workspace:SetAttribute("RainEndsAt", endsAt)
	Remotes.Notify:FireAllClients("RainStarted", { endsAt = endsAt })
	for _, player in Players:GetPlayers() do
		-- only count it as the final onboarding step for players who finished the earlier ones;
		-- otherwise reachStep would back-fill steps they never did and corrupt the funnel
		local data = PlayerData.get(player)
		if data and data.tutorialStep >= Config.TutorialSteps.FirstUpgrade then
			PlayerState.reachStep(player, Config.TutorialSteps.SawAppleDrop)
		end
	end

	local center = Config.Drop.plazaCenter
	local radius = Config.Drop.plazaRadius - 2
	while Workspace:GetServerTimeNow() < endsAt do
		-- spawn a small batch each tick so the network stays light
		local landings, golden = {}, {}
		for i = 1, 3 do
			local angle = rng:NextNumber(0, math.pi * 2)
			local r = radius * math.sqrt(rng:NextNumber())
			landings[i] = center + Vector3.new(math.cos(angle) * r, 0.6, math.sin(angle) * r)
			golden[i] = rng:NextNumber() < Config.Drop.rainGoldenChance
		end
		Apples.spawnShared(landings, golden)
		task.wait(Config.Drop.rainSpawnEvery * 3)
	end
	Workspace:SetAttribute("RainEndsAt", 0)
	Remotes.Notify:FireAllClients("RainEnded", {})
end

function AppleDrop.init()
	Workspace:SetAttribute("RainEndsAt", 0)
	task.spawn(function()
		while true do
			local now = Workspace:GetServerTimeNow()
			local at = nextBoundary(now)
			Workspace:SetAttribute("NextDropAt", at)
			task.wait(math.max(0.05, at - Workspace:GetServerTimeNow()))
			Workspace:SetAttribute("NextDropAt", nextBoundary(Workspace:GetServerTimeNow() + 1))
			rain()
		end
	end)
end

return AppleDrop
