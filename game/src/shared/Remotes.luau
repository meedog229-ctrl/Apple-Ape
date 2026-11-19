--!strict
-- Single place that defines every RemoteEvent. The server creates them; clients wait for them.
-- Client -> Server remotes carry INTENT only. The server validates and decides outcomes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	-- client -> server
	"Shake", -- (treeId: number)
	"Collect", -- (appleIds: {number})
	"BuyUpgrade", -- (kind: "Basket" | "Shake")
	-- server -> client
	"ShakeResult", -- (treeId, apples: {AppleInfo}, info)
	"TreeShaken", -- (treeId, userId) broadcast so everyone sees the tree wobble
	"CollectResult", -- (collectedIds, goldenGained, reason?)
	"ApplesSpawned", -- (apples: {AppleInfo}) shared apples (Apple Rain)
	"ApplesRemoved", -- (ids) shared apples taken by someone
	"Notify", -- (kind: string, data: any)
}

local folder: Folder
if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		folder = existing :: Folder
	else
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

local Remotes: { [string]: RemoteEvent } = {}
for _, name in NAMES do
	Remotes[name] = folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
