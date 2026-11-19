--!strict
-- Player save data with a session lock stored in the SAME key as the data, so the
-- ownership check and the write happen in one UpdateAsync (roblox-datastores skill guidance).
--
-- Studio: if "Enable Studio Access to API Services" is off, data stays in memory only
-- (you'll see a warning) so the prototype is still playable.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local STORE_NAME = "AppleApe_PlayerData_v1"
local SCHEMA_VERSION = 1
local LEASE_SECONDS = 150 -- a lock older than this is treated as abandoned (crashed server)
local AUTOSAVE_SECONDS = 45 -- must stay well under the lease
local LOAD_RETRY_SECONDS = 6

export type Data = {
	schema: number,
	coins: number,
	basket: number, -- regular apples currently carried
	golden: number,
	basketLevel: number,
	shakeLevel: number,
	tutorialStep: number,
	totalApples: number,
	totalShakes: number,
}

type Session = { jobId: string, token: string, renewedAt: number }
type Stored = { data: Data, session: Session? }

local function defaults(): Data
	return {
		schema = SCHEMA_VERSION,
		coins = 0,
		basket = 0,
		golden = 0,
		basketLevel = 1,
		shakeLevel = 1,
		tutorialStep = 0,
		totalApples = 0,
		totalShakes = 0,
	}
end

local function reconcile(saved: any): Data
	local data = defaults()
	if type(saved) == "table" then
		for key, value in pairs(data) do
			local v = saved[key]
			if type(v) == type(value) and v == v then -- reject NaN
				(data :: any)[key] = v
			end
		end
	end
	data.schema = SCHEMA_VERSION
	return data
end

local PlayerData = {}

local profiles: { [Player]: { data: Data, token: string, active: boolean } } = {}
local memoryOnly = false
local store: DataStore? = nil

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		memoryOnly = true
		warn("[PlayerData] DataStores unavailable, using memory only:", result)
	end
end

local function keyFor(player: Player): string
	return "player/" .. tostring(player.UserId)
end

-- Try to acquire the session lock and read data in one atomic UpdateAsync.
-- Returns: "ok", data | "locked", nil | "error", message
local function tryAcquire(player: Player, token: string): (string, any)
	local s = store :: DataStore
	local outcome = "error"
	local loaded: Data? = nil
	local ok, err = pcall(function()
		s:UpdateAsync(keyFor(player), function(old: any, _keyInfo)
			local stored: Stored = if type(old) == "table" and type(old.data) == "table"
				then old
				else { data = defaults(), session = nil }
			local session = stored.session
			local now = os.time()
			if session and session.token ~= token and now - session.renewedAt < LEASE_SECONDS then
				outcome = "locked"
				return nil -- cancel write: someone else owns this profile
			end
			stored.data = reconcile(stored.data)
			stored.session = { jobId = game.JobId, token = token, renewedAt = now }
			outcome = "ok"
			loaded = stored.data
			return stored, { player.UserId }
		end)
	end)
	if not ok then
		return "error", err
	end
	return outcome, loaded
end

function PlayerData.load(player: Player): Data?
	local token = HttpService:GenerateGUID(false)
	if memoryOnly then
		local data = defaults()
		profiles[player] = { data = data, token = token, active = true }
		return data
	end

	local deadline = os.clock() + LEASE_SECONDS + 10
	while player.Parent and os.clock() < deadline do
		local status, result = tryAcquire(player, token)
		if status == "ok" then
			profiles[player] = { data = result, token = token, active = true }
			return result
		elseif status == "error" then
			local message = tostring(result)
			if RunService:IsStudio() and (message:find("403") or message:find("Studio")) then
				warn("[PlayerData] Studio API access is off: playing with memory-only data.")
				memoryOnly = true
				local data = defaults()
				profiles[player] = { data = data, token = token, active = true }
				return data
			end
			warn("[PlayerData] load error for", player.UserId, message)
		end
		task.wait(LOAD_RETRY_SECONDS)
	end
	return nil
end

function PlayerData.get(player: Player): Data?
	local profile = profiles[player]
	return if profile and profile.active then profile.data else nil
end

-- Save; when `release` is true the session lock is cleared (player leaving).
-- Returns "committed" | "lost_ownership" | "unknown" | "skipped".
function PlayerData.save(player: Player, release: boolean?): string
	local profile = profiles[player]
	if not profile or not profile.active then
		return "skipped"
	end
	if memoryOnly then
		return "skipped"
	end
	local s = store :: DataStore
	local snapshot = table.clone(profile.data)
	local result = "unknown"
	local ok, err = pcall(function()
		s:UpdateAsync(keyFor(player), function(old: any, _keyInfo)
			if type(old) ~= "table" or type(old.session) ~= "table" or old.session.token ~= profile.token then
				result = "lost_ownership"
				return nil -- another server took over; never overwrite its data
			end
			result = "committed"
			local stored: Stored = {
				data = snapshot,
				session = if release then nil else { jobId = game.JobId, token = profile.token, renewedAt = os.time() },
			}
			return stored, { player.UserId }
		end)
	end)
	if not ok then
		-- An errored write is UNKNOWN, not failed: the next autosave re-checks ownership and retries.
		warn("[PlayerData] save error (will retry next autosave):", player.UserId, err)
		return "unknown"
	end
	if result == "lost_ownership" then
		warn("[PlayerData] lost session ownership for", player.UserId, "- this server will stop saving")
		profile.active = false
		player:Kick("Your data was opened on another server. Please rejoin.")
	end
	return result
end

function PlayerData.release(player: Player)
	PlayerData.save(player, true)
	profiles[player] = nil
end

function PlayerData.isMemoryOnly(): boolean
	return memoryOnly
end

-- Autosave loop (also renews the session lease).
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for player in profiles do
			task.spawn(PlayerData.save, player, false)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in profiles do
		pending += 1
		task.spawn(function()
			PlayerData.save(player, true)
			pending -= 1
		end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if profiles[player] then
		PlayerData.release(player)
	end
end)

return PlayerData
