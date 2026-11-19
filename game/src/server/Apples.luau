--!strict
-- Server-authoritative apples. The server decides where every apple lands and who may take it;
-- clients only render apples and send "I want these ids". (roblox-networking: client sends intent.)
--
-- Personal apples (from your own shake) can only be collected by you.
-- Shared apples (Apple Rain) can be collected by anyone, first come first served.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.PlayerData)
local PlayerState = require(script.Parent.PlayerState)
local Analytics = require(script.Parent.Analytics)
local RateLimiter = require(script.Parent.RateLimiter)

export type AppleInfo = { id: number, position: Vector3, golden: boolean }

type Record = {
	id: number,
	owner: number?, -- UserId, or nil for shared apples
	position: Vector3,
	golden: boolean,
	expires: number,
}

local Apples = {}

local records: { [number]: Record } = {}
local nextId = 0
local collectLimiter = RateLimiter.new({ capacity = 30, refillRate = 20, defaultMinInterval = 0.05 })

local function newRecord(owner: number?, position: Vector3, golden: boolean): Record
	nextId += 1
	local rec: Record = {
		id = nextId,
		owner = owner,
		position = position,
		golden = golden,
		expires = os.clock() + Config.Apple.lifetime,
	}
	records[rec.id] = rec
	return rec
end

-- Create apples that only `player` can collect. Returns the info the client needs to render them.
function Apples.spawnPersonal(player: Player, landings: { Vector3 }, goldenIndex: number?): { AppleInfo }
	local infos = {}
	for i, pos in landings do
		local rec = newRecord(player.UserId, pos, i == goldenIndex)
		table.insert(infos, { id = rec.id, position = rec.position, golden = rec.golden })
	end
	return infos
end

-- Create apples anyone can collect, and tell every client to render them.
function Apples.spawnShared(landings: { Vector3 }, goldenFlags: { boolean }?): { AppleInfo }
	local infos = {}
	for i, pos in landings do
		local rec = newRecord(nil, pos, if goldenFlags then goldenFlags[i] == true else false)
		table.insert(infos, { id = rec.id, position = rec.position, golden = rec.golden })
	end
	Remotes.ApplesSpawned:FireAllClients(infos)
	return infos
end

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.Position
end

local function onCollect(player: Player, ids: any)
	-- argument validation: a list of up to N integer ids
	if type(ids) ~= "table" then
		return
	end
	local count = #ids
	if count == 0 or count > Config.Apple.maxPerCollectRequest then
		return
	end
	if not collectLimiter:canPerform(player, "collect") then
		return
	end
	local data = PlayerData.get(player)
	local rootPos = rootPosition(player)
	if not data or not rootPos then
		return
	end

	local capacity = Config.capacity(data.basketLevel)
	local collected: { number } = {}
	local sharedTaken: { number } = {}
	local goldenGained = 0
	local regularGained = 0
	local reason: string? = nil
	local now = os.clock()

	for i = 1, count do
		local id = ids[i]
		if type(id) ~= "number" or id % 1 ~= 0 then
			continue
		end
		local rec = records[id]
		if not rec or rec.expires < now then
			continue
		end
		if rec.owner ~= nil and rec.owner ~= player.UserId then
			continue
		end
		if (rec.position - rootPos).Magnitude > Config.Apple.serverCollectRadius then
			reason = reason or "far"
			continue
		end
		if rec.golden then
			goldenGained += 1
		elseif data.basket + regularGained < capacity then
			regularGained += 1
		else
			reason = "full"
			continue
		end
		records[id] = nil
		table.insert(collected, id)
		if rec.owner == nil then
			table.insert(sharedTaken, id)
		end
	end

	if #collected == 0 then
		if reason then
			Remotes.CollectResult:FireClient(player, collected, 0, reason)
		end
		return
	end

	data.basket += regularGained
	data.golden += goldenGained
	data.totalApples += regularGained + goldenGained
	PlayerState.sync(player)
	PlayerState.reachStep(player, Config.TutorialSteps.FirstCollect)
	if goldenGained > 0 then
		Analytics.economy(player, "Source", "GoldenApples", goldenGained, data.golden, "Gameplay", "GoldenApplePickup")
	end
	if data.basket >= capacity then
		reason = "full"
		PlayerState.reachStep(player, Config.TutorialSteps.BasketFull)
	end

	Remotes.CollectResult:FireClient(player, collected, goldenGained, reason)
	if #sharedTaken > 0 then
		Remotes.ApplesRemoved:FireAllClients(sharedTaken, player.UserId)
	end
end

function Apples.init()
	Remotes.Collect.OnServerEvent:Connect(onCollect)

	-- expire old apples and forget apples of players who left
	task.spawn(function()
		while true do
			task.wait(2)
			local now = os.clock()
			local online: { [number]: boolean } = {}
			for _, p in Players:GetPlayers() do
				online[p.UserId] = true
			end
			for id, rec in records do
				if rec.expires < now or (rec.owner ~= nil and not online[rec.owner]) then
					records[id] = nil
				end
			end
		end
	end)
end

return Apples
