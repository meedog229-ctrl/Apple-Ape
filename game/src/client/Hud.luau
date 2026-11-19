--!strict
-- Mobile-first HUD (blueprint U1-U8). Built in code with Scale sizing + size constraints.
-- Layout:
--   top-left   : basket bar, coins (+ opens shop), golden apples
--   top-center : APPLE DROP countdown (the hero element)
--   right      : goal tracker
--   left edge  : SHOP button
--   bottom     : big SHAKE button (above the jump button on touch screens)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Sounds = require(script.Parent.Sounds)

local Hud = {}

local player = Players.LocalPlayer
local C = Config.Colors
local FONT = Enum.Font.FredokaOne

---------------------------------------------------------------------------
-- tiny UI helpers
---------------------------------------------------------------------------
local function new(className: string, props: { [string]: any }, children: { Instance }?): any
	local inst = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(inst :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(radius: number?): UICorner
	return new("UICorner", { CornerRadius = UDim.new(radius or 0.25, 0) })
end

local function stroke(thickness: number?, color: Color3?): UIStroke
	return new("UIStroke", {
		Thickness = thickness or 3,
		Color = color or C.uiStroke,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function textStroke(): UIStroke
	return new("UIStroke", { Thickness = 2.5, Color = C.uiStroke })
end

local function label(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = FONT,
		TextScaled = true,
		TextColor3 = C.white,
	}
	for k, v in props do
		defaults[k] = v
	end
	return new("TextLabel", defaults, { textStroke() })
end

-- Every button squishes on press and plays a click (blueprint U3).
local function juicyButton(button: GuiButton, onActivated: () -> ())
	local scale = button:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = button })
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.06 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end)
	button.Activated:Connect(function()
		scale.Scale = 0.88
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
		Sounds.play("click", 1.1, 0.4)
		onActivated()
	end)
end

local function bounce(gui: GuiObject, amount: number?)
	local scale = gui:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = gui })
	scale.Scale = 1 + (amount or 0.12)
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
end

-- Counting number display (blueprint U8: count up instead of jumping).
local function countingText(textLabel: TextLabel, prefix: string, suffix: (() -> string)?)
	local value = new("NumberValue", { Parent = textLabel })
	value.Changed:Connect(function(v)
		textLabel.Text = prefix .. Format.short(v) .. (if suffix then suffix() else "")
	end)
	return function(target: number)
		TweenService:Create(value, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Value = target }):Play()
	end
end

---------------------------------------------------------------------------
-- build
---------------------------------------------------------------------------
local gui: ScreenGui
local refs: { [string]: any } = {}
local callbacks = {
	onShake = function() end,
	onBuy = function(_kind: string) end,
}

function Hud.build(handlers: { onShake: () -> (), onBuy: (kind: string) -> () })
	callbacks = handlers
	gui = new("ScreenGui", {
		Name = "AppleApeHud",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		Parent = player:WaitForChild("PlayerGui"),
	})

	-- full-screen flash for big moments (sits on top)
	refs.flash = new("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.white,
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = gui,
	})

	-- top-left stat stack --------------------------------------------------
	local stats = new("Frame", {
		Name = "Stats",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.012, 0.02),
		Size = UDim2.fromScale(0.3, 0.27),
		Parent = gui,
	}, {
		new("UISizeConstraint", { MinSize = Vector2.new(190, 120), MaxSize = Vector2.new(340, 200) }),
		new("UIListLayout", { Padding = UDim.new(0.05, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local function statRow(name: string, order: number, icon: string, color: Color3): Frame
		return new("Frame", {
			Name = name,
			LayoutOrder = order,
			Size = UDim2.fromScale(1, 0.3),
			BackgroundColor3 = C.ui,
			BackgroundTransparency = 0.15,
			Parent = stats,
		}, {
			corner(0.4),
			stroke(3),
			label({
				Name = "Icon",
				Text = icon,
				Size = UDim2.fromScale(0.2, 0.9),
				Position = UDim2.fromScale(0.02, 0.05),
				TextColor3 = color,
			}),
		})
	end

	-- basket bar
	local basketRow = statRow("Basket", 1, "🍎", C.apple)
	refs.basketRow = basketRow
	local track = new("Frame", {
		Name = "Track",
		Position = UDim2.fromScale(0.22, 0.2),
		Size = UDim2.fromScale(0.74, 0.6),
		BackgroundColor3 = Color3.fromRGB(60, 20, 20),
		Parent = basketRow,
	}, { corner(0.5) })
	refs.basketFill = new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = C.apple,
		Parent = track,
	}, {
		corner(0.5),
		new("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(255, 120, 110), C.apple),
			Rotation = 90,
		}),
	})
	refs.basketText = label({
		Name = "Amount",
		Text = "0 / 25",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
		Parent = track,
	})

	-- coins
	local coinRow = statRow("Coins", 2, "🪙", C.coin)
	refs.coinRow = coinRow
	refs.coinText = label({
		Name = "Amount",
		Text = "0",
		Size = UDim2.fromScale(0.55, 0.8),
		Position = UDim2.fromScale(0.22, 0.1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.coin,
		Parent = coinRow,
	})
	local plus = new("TextButton", {
		Name = "Plus",
		Text = "+",
		Font = FONT,
		TextScaled = true,
		TextColor3 = C.white,
		BackgroundColor3 = C.good,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.97, 0.5),
		Size = UDim2.fromScale(0.18, 0.8),
		Parent = coinRow,
	}, { corner(0.35), stroke(2.5), textStroke() })
	juicyButton(plus, function()
		Hud.toggleShop(true)
	end)
	refs.setCoins = countingText(refs.coinText, "")

	-- golden apples
	local goldRow = statRow("Golden", 3, "✨", C.golden)
	refs.goldRow = goldRow
	refs.goldText = label({
		Name = "Amount",
		Text = "0",
		Size = UDim2.fromScale(0.7, 0.8),
		Position = UDim2.fromScale(0.22, 0.1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.golden,
		Parent = goldRow,
	})
	refs.setGolden = countingText(refs.goldText, "", function()
		return " Golden"
	end)

	-- top-center Apple Drop countdown -------------------------------------
	refs.dropPill = new("Frame", {
		Name = "DropPill",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.015),
		Size = UDim2.fromScale(0.3, 0.075),
		BackgroundColor3 = Color3.fromRGB(190, 45, 45),
		Parent = gui,
	}, {
		corner(0.5),
		stroke(3),
		new("UISizeConstraint", { MinSize = Vector2.new(210, 40), MaxSize = Vector2.new(420, 64) }),
		new(
			"UIGradient",
			{ Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200)), Rotation = 90 }
		),
	})
	refs.dropText = label({
		Name = "Text",
		Text = "🍎 APPLE DROP IN 0:00",
		Size = UDim2.fromScale(0.92, 0.75),
		Position = UDim2.fromScale(0.04, 0.12),
		Parent = refs.dropPill,
	})

	-- right goal tracker ---------------------------------------------------
	refs.goal = new("Frame", {
		Name = "Goal",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.985, 0.2),
		Size = UDim2.fromScale(0.25, 0.12),
		BackgroundColor3 = C.ui,
		BackgroundTransparency = 0.15,
		Parent = gui,
	}, {
		corner(0.2),
		stroke(3),
		new("UISizeConstraint", { MinSize = Vector2.new(170, 60), MaxSize = Vector2.new(320, 96) }),
		label({
			Name = "Title",
			Text = "GOAL",
			Size = UDim2.fromScale(0.9, 0.3),
			Position = UDim2.fromScale(0.05, 0.05),
			TextColor3 = C.golden,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
	refs.goalText = label({
		Name = "Text",
		Text = "Shake a tree!",
		Size = UDim2.fromScale(0.9, 0.55),
		Position = UDim2.fromScale(0.05, 0.38),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = refs.goal,
	})

	-- left-edge SHOP button -------------------------------------------------
	local shopButton = new("TextButton", {
		Name = "ShopButton",
		Text = "🛒 SHOP",
		Font = FONT,
		TextScaled = true,
		TextColor3 = C.white,
		BackgroundColor3 = Color3.fromRGB(60, 140, 230),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.012, 0.5),
		Size = UDim2.fromScale(0.13, 0.08),
		Parent = gui,
	}, {
		corner(0.35),
		stroke(3),
		textStroke(),
		new("UISizeConstraint", { MinSize = Vector2.new(100, 44), MaxSize = Vector2.new(170, 64) }),
	})
	refs.shopButton = shopButton
	juicyButton(shopButton, function()
		Hud.toggleShop()
	end)

	-- SHAKE button -----------------------------------------------------------
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local shake = new("TextButton", {
		Name = "ShakeButton",
		Text = if touch then "SHAKE!" else "SHAKE! [E]",
		Font = FONT,
		TextScaled = true,
		TextColor3 = C.white,
		BackgroundColor3 = C.good,
		AnchorPoint = if touch then Vector2.new(1, 1) else Vector2.new(0.5, 1),
		-- touch: sit above the jump button; desktop: bottom center
		Position = if touch then UDim2.new(1, -25, 1, -175) else UDim2.fromScale(0.5, 0.96),
		Size = if touch then UDim2.fromOffset(120, 120) else UDim2.fromScale(0.2, 0.1),
		Visible = false,
		Parent = gui,
	}, {
		corner(if touch then 1 else 0.4),
		stroke(4),
		textStroke(),
		new("UIPadding", {
			PaddingLeft = UDim.new(0.1, 0),
			PaddingRight = UDim.new(0.1, 0),
			PaddingTop = UDim.new(0.15, 0),
			PaddingBottom = UDim.new(0.15, 0),
		}),
		new("UISizeConstraint", { MinSize = Vector2.new(110, 56), MaxSize = Vector2.new(260, 120) }),
	})
	refs.shakeButton = shake
	juicyButton(shake, function()
		callbacks.onShake()
	end)

	-- banner (big center messages) + toast (small) ----------------------------
	refs.banner = label({
		Name = "Banner",
		Text = "",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromScale(0.6, 0.1),
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	})
	refs.toast = label({
		Name = "Toast",
		Text = "",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.82),
		Size = UDim2.fromScale(0.5, 0.05),
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	})

	Hud.buildShop()
end

---------------------------------------------------------------------------
-- shop panel (coin upgrades for now; Robux products come in Phase B)
---------------------------------------------------------------------------
local UPGRADES = {
	{ kind = "Basket", title = "Bigger Basket", icon = "🧺", attr = "BasketLevel" },
	{ kind = "Shake", title = "Stronger Shake", icon = "💪", attr = "ShakeLevel" },
}

function Hud.buildShop()
	local panel = new("Frame", {
		Name = "Shop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.5, 0.55),
		BackgroundColor3 = C.ui,
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	}, {
		corner(0.06),
		stroke(4),
		new("UISizeConstraint", { MinSize = Vector2.new(300, 230), MaxSize = Vector2.new(560, 380) }),
		label({
			Name = "Title",
			Text = "🛒 SHOP",
			Size = UDim2.fromScale(0.6, 0.14),
			Position = UDim2.fromScale(0.2, 0.03),
			TextColor3 = C.golden,
			ZIndex = 11,
		}),
	})
	refs.shop = panel
	local close = new("TextButton", {
		Name = "Close",
		Text = "X",
		Font = FONT,
		TextScaled = true,
		TextColor3 = C.white,
		BackgroundColor3 = C.bad,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.97, 0.03),
		Size = UDim2.fromScale(0.1, 0.14),
		ZIndex = 11,
		Parent = panel,
	}, { corner(0.3), stroke(2.5), textStroke(), new("UIAspectRatioConstraint", { AspectRatio = 1 }) })
	juicyButton(close, function()
		Hud.toggleShop(false)
	end)

	refs.cards = {}
	for i, def in UPGRADES do
		local card = new("Frame", {
			Name = def.kind,
			Position = UDim2.fromScale(0.04 + (i - 1) * 0.48, 0.22),
			Size = UDim2.fromScale(0.44, 0.72),
			BackgroundColor3 = Color3.fromRGB(45, 52, 75),
			ZIndex = 11,
			Parent = panel,
		}, {
			corner(0.1),
			stroke(3),
			label({
				Name = "Icon",
				Text = def.icon,
				Size = UDim2.fromScale(1, 0.22),
				Position = UDim2.fromScale(0, 0.03),
				ZIndex = 12,
			}),
			label({
				Name = "Title",
				Text = def.title,
				Size = UDim2.fromScale(0.9, 0.14),
				Position = UDim2.fromScale(0.05, 0.26),
				ZIndex = 12,
			}),
		})
		local info = label({
			Name = "Info",
			Text = "",
			Size = UDim2.fromScale(0.9, 0.2),
			Position = UDim2.fromScale(0.05, 0.42),
			TextColor3 = Color3.fromRGB(200, 220, 255),
			ZIndex = 12,
			Parent = card,
		})
		local buy = new("TextButton", {
			Name = "Buy",
			Text = "",
			Font = FONT,
			TextScaled = true,
			TextColor3 = C.white,
			BackgroundColor3 = C.good,
			Position = UDim2.fromScale(0.08, 0.7),
			Size = UDim2.fromScale(0.84, 0.22),
			ZIndex = 12,
			Parent = card,
		}, { corner(0.35), stroke(3), textStroke() })
		juicyButton(buy, function()
			callbacks.onBuy(def.kind)
		end)
		refs.cards[def.kind] = { info = info, buy = buy, def = def }
	end
end

function Hud.refreshShop()
	if not refs.cards then
		return
	end
	local coins = (player:GetAttribute("Coins") :: number?) or 0
	for kind, card in refs.cards do
		local level = (player:GetAttribute(card.def.attr) :: number?) or 1
		local maxed = level >= Config.maxLevel(kind)
		local cost = Config.upgradeCost(kind, level)
		if kind == "Basket" then
			card.info.Text = `Lv.{level}: holds {Config.capacity(level)}`
				.. (if maxed then "" else ` → {Config.capacity(level + 1)}`)
		else
			card.info.Text = `Lv.{level}: {Config.applesPerShake(level)} apples`
				.. (if maxed then "" else ` → {Config.applesPerShake(level + 1)}`)
		end
		card.buy.Text = if maxed then "MAX" else `🪙 {Format.short(cost)}`
		card.buy.BackgroundColor3 = if maxed
			then Color3.fromRGB(110, 110, 110)
			elseif coins >= cost then C.good
			else Color3.fromRGB(150, 70, 70)
	end
end

function Hud.toggleShop(force: boolean?)
	local panel = refs.shop :: Frame
	local show = if force ~= nil then force else not panel.Visible
	if show then
		Hud.refreshShop()
		panel.Visible = true
		bounce(panel, 0.15)
	else
		panel.Visible = false
	end
end

function Hud.isShopOpen(): boolean
	return refs.shop and refs.shop.Visible
end

---------------------------------------------------------------------------
-- updates called by the controller
---------------------------------------------------------------------------
local lastBasket = 0

function Hud.setBasket(amount: number, capacity: number)
	local fraction = if capacity > 0 then math.clamp(amount / capacity, 0, 1) else 0
	TweenService:Create(refs.basketFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Size = UDim2.fromScale(fraction, 1),
	}):Play()
	refs.basketText.Text = `{Format.short(amount)} / {Format.short(capacity)}`
	refs.basketFill.BackgroundColor3 = if fraction >= 1 then C.golden else C.apple
	if amount > lastBasket then
		bounce(refs.basketRow, 0.06) -- basket wobble on every pickup
	end
	lastBasket = amount
end

function Hud.setCoins(amount: number)
	refs.setCoins(amount)
	bounce(refs.coinRow, 0.08)
	if Hud.isShopOpen() then
		Hud.refreshShop()
	end
end

function Hud.setGolden(amount: number)
	refs.setGolden(amount)
	bounce(refs.goldRow, 0.12)
end

function Hud.setDrop(text: string, urgent: boolean, raining: boolean)
	refs.dropText.Text = text
	refs.dropPill.BackgroundColor3 = if raining
		then Color3.fromRGB(230, 170, 30)
		elseif urgent then Color3.fromRGB(235, 60, 40)
		else Color3.fromRGB(190, 45, 45)
end

function Hud.pulseDrop()
	bounce(refs.dropPill, 0.1)
end

function Hud.setGoal(text: string)
	if refs.goalText.Text ~= text then
		refs.goalText.Text = text
		bounce(refs.goal, 0.08)
	end
end

function Hud.setShakeVisible(visible: boolean)
	refs.shakeButton.Visible = visible
end

function Hud.pulseShop()
	bounce(refs.shopButton, 0.15)
end

local bannerToken = 0
function Hud.banner(text: string, color: Color3?, seconds: number?)
	bannerToken += 1
	local token = bannerToken
	local b = refs.banner :: TextLabel
	b.Text = text
	b.TextColor3 = color or C.white
	b.Visible = true
	bounce(b, 0.35)
	task.delay(seconds or 1.8, function()
		if token == bannerToken then
			b.Visible = false
		end
	end)
end

local toastToken = 0
function Hud.toast(text: string, color: Color3?)
	toastToken += 1
	local token = toastToken
	local t = refs.toast :: TextLabel
	t.Text = text
	t.TextColor3 = color or C.white
	t.Visible = true
	bounce(t, 0.2)
	task.delay(1.6, function()
		if token == toastToken then
			t.Visible = false
		end
	end)
end

function Hud.flashFrame(): Frame
	return refs.flash
end

return Hud
