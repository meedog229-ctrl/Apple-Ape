--!strict
-- Mirrors server-owned data onto Player attributes so the HUD can display it.
-- Attributes are DISPLAY ONLY: the server never reads them back as truth.

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local Analytics = require(script.Parent.Analytics)

local PlayerState = {}

function PlayerState.sync(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	player:SetAttribute("Coins", data.coins)
	player:SetAttribute("Basket", data.basket)
	player:SetAttribute("Capacity", Config.capacity(data.basketLevel))
	player:SetAttribute("Golden", data.golden)
	player:SetAttribute("BasketLevel", data.basketLevel)
	player:SetAttribute("ShakeLevel", data.shakeLevel)
	player:SetAttribute("TutorialStep", data.tutorialStep)
	player:SetAttribute("Loaded", true)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins") :: IntValue?
		if coins then
			coins.Value = data.coins
		end
	end
end

-- Advance the tutorial/onboarding funnel. Steps only ever move forward, and each logs once.
function PlayerState.reachStep(player: Player, step: number)
	local data = PlayerData.get(player)
	if not data or data.tutorialStep >= step then
		return
	end
	for s = data.tutorialStep + 1, step do
		Analytics.onboardingStep(player, s)
	end
	data.tutorialStep = step
	player:SetAttribute("TutorialStep", step)
end

function PlayerState.createLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
	leaderstats.Parent = player
end

function PlayerState.init()
	local function onPlayerAdded(player: Player)
		PlayerState.createLeaderstats(player)
		local data = PlayerData.load(player)
		if not data then
			player:Kick("Couldn't load your apples. Please rejoin in a minute!")
			return
		end
		if player.Parent == nil then
			return
		end
		PlayerState.sync(player)
		PlayerState.reachStep(player, Config.TutorialSteps.Joined)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	-- players who joined before this script connected (common in Studio Play Solo)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return PlayerState
