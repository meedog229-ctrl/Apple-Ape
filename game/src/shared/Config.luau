--!strict
-- Apple Ape: every tunable number lives here. Server and client both read this module.
-- Change values, rebuild, playtest. Keep secrets (anti-cheat thresholds) server-side only if this grows.

local RunService = game:GetService("RunService")

local Config = {}

Config.GameName = "Apple Ape"

-- Basket = how many regular apples you can carry before selling.
Config.Basket = {
	baseCapacity = 25,
	capacityPerLevel = 15,
	maxLevel = 25,
	baseCost = 15,
	costGrowth = 1.55,
}

-- Shake = how many apples burst out of a tree per shake.
Config.Shake = {
	cooldown = 0.45, -- seconds between shakes (server enforces)
	range = 16, -- studs from trunk you must be within
	baseApples = 3,
	applesPerLevel = 1,
	maxLevel = 25,
	baseCost = 25,
	costGrowth = 1.7,
	goldenChance = 0.03, -- chance that one apple in a shake is golden
}

Config.Apple = {
	coinValue = 1, -- coins per regular apple when sold
	lifetime = 25, -- seconds an uncollected apple stays on the ground
	landMinRadius = 4,
	landMaxRadius = 9,
	magnetRadius = 7, -- client: apples within this distance fly to you
	serverCollectRadius = 14, -- server tolerance (magnet + latency)
	maxPerCollectRequest = 40,
}

-- First-time experience (blueprint R1-R3): first shake is huge and guaranteed golden.
Config.Tutorial = {
	firstShakeMultiplier = 10,
}

-- The Apple Drop (blueprint signature twist). Aligned to UTC :00, :10, :20 ...
Config.Drop = {
	intervalSeconds = 600,
	studioIntervalSeconds = 120, -- shorter cycle when testing in Studio
	rainDuration = 30,
	rainSpawnEvery = 0.15, -- seconds between rain apples
	rainGoldenChance = 0.06,
	plazaCenter = Vector3.new(0, 0, 70),
	plazaRadius = 22,
}

function Config.dropInterval(): number
	if RunService:IsStudio() then
		return Config.Drop.studioIntervalSeconds
	end
	return Config.Drop.intervalSeconds
end

-- World layout (studs). Ground top surface is at Y = 0.
Config.World = {
	spawn = Vector3.new(0, 0, -18),
	sellPad = Vector3.new(-38, 0, -6),
	trees = {
		Vector3.new(-9, 0, 16),
		Vector3.new(9, 0, 16),
		Vector3.new(-27, 0, 22),
		Vector3.new(27, 0, 22),
		Vector3.new(-14, 0, 38),
		Vector3.new(14, 0, 38),
	},
}

Config.Colors = {
	apple = Color3.fromRGB(226, 38, 38),
	golden = Color3.fromRGB(255, 205, 40),
	leaf = Color3.fromRGB(76, 175, 80),
	leafDark = Color3.fromRGB(46, 125, 50),
	trunk = Color3.fromRGB(121, 85, 58),
	grass = Color3.fromRGB(110, 190, 90),
	coin = Color3.fromRGB(255, 196, 0),
	ui = Color3.fromRGB(28, 32, 48),
	uiStroke = Color3.fromRGB(14, 16, 26),
	white = Color3.fromRGB(255, 255, 255),
	good = Color3.fromRGB(70, 200, 90),
	bad = Color3.fromRGB(235, 70, 70),
}

-- Built-in Studio sounds so the prototype works with no uploads.
-- Swap for your own asset ids ("rbxassetid://123") later; a bad id just stays silent.
Config.Sounds = {
	shake = "rbxasset://sounds/swoosh.wav",
	pop = "rbxasset://sounds/electronicpingshort.wav",
	golden = "rbxasset://sounds/electronicpingshort.wav",
	click = "rbxasset://sounds/button.wav",
	sell = "rbxasset://sounds/electronicpingshort.wav",
	error = "rbxasset://sounds/button.wav",
}

-- Cost for buying the NEXT level when you are at `level` (levels start at 1).
function Config.upgradeCost(kind: string, level: number): number
	local def = if kind == "Basket" then Config.Basket else Config.Shake
	return math.floor(def.baseCost * def.costGrowth ^ (level - 1))
end

function Config.capacity(basketLevel: number): number
	return Config.Basket.baseCapacity + (basketLevel - 1) * Config.Basket.capacityPerLevel
end

function Config.applesPerShake(shakeLevel: number): number
	return Config.Shake.baseApples + (shakeLevel - 1) * Config.Shake.applesPerLevel
end

function Config.maxLevel(kind: string): number
	return if kind == "Basket" then Config.Basket.maxLevel else Config.Shake.maxLevel
end

-- Tutorial steps (also used as AnalyticsService onboarding funnel steps).
Config.TutorialSteps = {
	Joined = 1,
	FirstShake = 2,
	FirstCollect = 3,
	BasketFull = 4,
	FirstSell = 5,
	FirstUpgrade = 6,
	SawAppleDrop = 7,
}
Config.TutorialStepNames = {
	"Joined",
	"FirstShake",
	"FirstCollect",
	"BasketFull",
	"FirstSell",
	"FirstUpgrade",
	"SawAppleDrop",
}

return Config
