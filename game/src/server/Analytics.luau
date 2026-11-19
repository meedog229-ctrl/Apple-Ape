--!strict
-- Thin, crash-proof wrapper around AnalyticsService (blueprint D6).
-- Funnel steps show in Creator Dashboard > Analytics > Funnels; economy in > Economy.

local AnalyticsService = game:GetService("AnalyticsService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Analytics = {}

function Analytics.onboardingStep(player: Player, step: number)
	local name = Config.TutorialStepNames[step]
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)
	end)
end

-- flow: "Source" (earned) or "Sink" (spent). transactionType: Enum.AnalyticsEconomyTransactionType name.
function Analytics.economy(
	player: Player,
	flow: "Source" | "Sink",
	currency: string,
	amount: number,
	endingBalance: number,
	transactionType: string,
	itemSku: string?
)
	if amount <= 0 then
		return
	end
	pcall(function()
		local flowType = if flow == "Source"
			then Enum.AnalyticsEconomyFlowType.Source
			else Enum.AnalyticsEconomyFlowType.Sink
		AnalyticsService:LogEconomyEvent(player, flowType, currency, amount, endingBalance, transactionType, itemSku)
	end)
end

function Analytics.custom(player: Player, eventName: string, value: number?)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, eventName, value or 1)
	end)
end

return Analytics
