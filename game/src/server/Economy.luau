--!strict
-- Selling (step on the sell pad) and coin upgrades. All prices and grants are server-side.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.PlayerData)
local PlayerState = require(script.Parent.PlayerState)
local Analytics = require(script.Parent.Analytics)
local RateLimiter = require(script.Parent.RateLimiter)

local Economy = {}

local buyLimiter = RateLimiter.new({ capacity = 8, refillRate = 4, defaultMinInterval = 0.1 })
local lastSell: { [Player]: number } = {}

local function sell(player: Player)
	local now = os.clock()
	if lastSell[player] and now - lastSell[player] < 0.5 then
		return
	end
	lastSell[player] = now
	local data = PlayerData.get(player)
	if not data or data.basket <= 0 then
		return
	end
	local apples = data.basket
	local earned = apples * Config.Apple.coinValue
	data.basket = 0
	data.coins += earned
	PlayerState.sync(player)
	PlayerState.reachStep(player, Config.TutorialSteps.FirstSell)
	Analytics.economy(player, "Source", "Coins", earned, data.coins, "Gameplay", "SellApples")
	Remotes.Notify:FireClient(player, "Sold", { apples = apples, coins = earned })
end

local function onBuyUpgrade(player: Player, kind: any)
	if kind ~= "Basket" and kind ~= "Shake" then
		return
	end
	if not buyLimiter:canPerform(player, "buy") then
		return
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local level = if kind == "Basket" then data.basketLevel else data.shakeLevel
	if level >= Config.maxLevel(kind) then
		Remotes.Notify:FireClient(player, "MaxLevel", { kind = kind })
		return
	end
	local cost = Config.upgradeCost(kind, level)
	if data.coins < cost then
		Remotes.Notify:FireClient(player, "NotEnoughCoins", { need = cost - data.coins })
		return
	end
	data.coins -= cost
	if kind == "Basket" then
		data.basketLevel += 1
	else
		data.shakeLevel += 1
	end
	PlayerState.sync(player)
	PlayerState.reachStep(player, Config.TutorialSteps.FirstUpgrade)
	Analytics.economy(player, "Sink", "Coins", cost, data.coins, "Shop", kind .. "Upgrade")
	Remotes.Notify:FireClient(player, "Upgraded", { kind = kind, level = level + 1 })
end

function Economy.init(sellPad: BasePart)
	sellPad.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			sell(player)
		end
	end)
	Remotes.BuyUpgrade.OnServerEvent:Connect(onBuyUpgrade)
	Players.PlayerRemoving:Connect(function(player)
		lastSell[player] = nil
	end)
end

return Economy
