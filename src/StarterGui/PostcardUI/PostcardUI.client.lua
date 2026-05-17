-- PostcardUI.client.lua  (LocalScript — StarterGui/PostcardUI)
-- Two concerns:
--   1. Incoming postcard notification (slides in, auto-dismisses)
--   2. Send panel (opened via ProximityPrompt near PostcardMailbox Part)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes       = ReplicatedStorage:WaitForChild("Remotes", 15)
local C             = require(ReplicatedStorage:WaitForChild("Constants"))
local R             = C.REMOTES
local sendPostcard  = remotes:WaitForChild(R.SEND_POSTCARD)
local postcardRecv  = remotes:WaitForChild(R.POSTCARD_RECEIVED)

-- ============================================================
-- Build UI
-- ============================================================

local sg = Instance.new("ScreenGui")
sg.Name          = "PostcardUI"
sg.ResetOnSpawn  = false
sg.Parent        = playerGui

-- ── Incoming notification (bottom-right slide-in) ──────────

local notifFrame = Instance.new("Frame")
notifFrame.Name                   = "NotificationFrame"
notifFrame.Size                   = UDim2.new(0, 310, 0, 84)
notifFrame.Position               = UDim2.new(1, 20, 1, -110)  -- off-screen
notifFrame.BackgroundColor3       = Color3.fromRGB(16, 13, 32)
notifFrame.BackgroundTransparency = 0.08
notifFrame.BorderSizePixel        = 0
notifFrame.Visible                = false
notifFrame.Parent                 = sg
Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 12)

local notifTitle = Instance.new("TextLabel")
notifTitle.Size                  = UDim2.new(1, -18, 0, 22)
notifTitle.Position              = UDim2.new(0, 14, 0, 10)
notifTitle.BackgroundTransparency = 1
notifTitle.Text                  = "某位夢語者寄來了一張明信片"
notifTitle.TextColor3            = Color3.fromRGB(148, 144, 200)
notifTitle.TextSize              = 11
notifTitle.Font                  = Enum.Font.Gotham
notifTitle.TextXAlignment        = Enum.TextXAlignment.Left
notifTitle.Parent                = notifFrame

local notifSentence = Instance.new("TextLabel")
notifSentence.Name                 = "SentenceLabel"
notifSentence.Size                 = UDim2.new(1, -18, 0, 36)
notifSentence.Position             = UDim2.new(0, 14, 0, 34)
notifSentence.BackgroundTransparency = 1
notifSentence.Text                 = ""
notifSentence.TextColor3           = Color3.fromRGB(208, 205, 238)
notifSentence.TextSize             = 14
notifSentence.Font                 = Enum.Font.Gotham
notifSentence.TextXAlignment       = Enum.TextXAlignment.Left
notifSentence.TextWrapped          = true
notifSentence.Parent               = notifFrame

local function showNotification(sentence)
	notifSentence.Text = sentence
	notifFrame.Visible = true
	notifFrame.Position = UDim2.new(1, 20, 1, -110)  -- reset to off-screen

	TweenService:Create(notifFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -328, 1, -110),
	}):Play()

	task.delay(7, function()
		TweenService:Create(notifFrame, TweenInfo.new(0.38, Enum.EasingStyle.Quint), {
			Position = UDim2.new(1, 20, 1, -110),
		}):Play()
		task.delay(0.4, function() notifFrame.Visible = false end)
	end)
end

-- ── Send panel ──────────────────────────────────────────────

local sendPanel = Instance.new("Frame")
sendPanel.Name                   = "SendPanel"
sendPanel.Size                   = UDim2.new(0, 390, 0, 440)
sendPanel.Position               = UDim2.new(0.5, -195, 0.5, -220)
sendPanel.BackgroundColor3       = Color3.fromRGB(11, 9, 24)
sendPanel.BackgroundTransparency = 0.05
sendPanel.BorderSizePixel        = 0
sendPanel.Visible                = false
sendPanel.Parent                 = sg
Instance.new("UICorner", sendPanel).CornerRadius = UDim.new(0, 16)

local sendTitle = Instance.new("TextLabel")
sendTitle.Size                  = UDim2.new(1, -60, 0, 32)
sendTitle.Position              = UDim2.new(0, 22, 0, 14)
sendTitle.BackgroundTransparency = 1
sendTitle.Text                  = "寄出一張明信片"
sendTitle.TextColor3            = Color3.fromRGB(185, 180, 225)
sendTitle.TextSize              = 18
sendTitle.Font                  = Enum.Font.Gotham
sendTitle.TextXAlignment        = Enum.TextXAlignment.Left
sendTitle.Parent                = sendPanel

local sendSub = Instance.new("TextLabel")
sendSub.Size                  = UDim2.new(1, -44, 0, 18)
sendSub.Position              = UDim2.new(0, 22, 0, 48)
sendSub.BackgroundTransparency = 1
sendSub.Text                  = "選擇一句，匿名寄給某位夢語者。"
sendSub.TextColor3            = Color3.fromRGB(95, 92, 135)
sendSub.TextSize              = 13
sendSub.Font                  = Enum.Font.Gotham
sendSub.TextXAlignment        = Enum.TextXAlignment.Left
sendSub.Parent                = sendPanel

local sendClose = Instance.new("TextButton")
sendClose.Size                  = UDim2.new(0, 34, 0, 34)
sendClose.Position              = UDim2.new(1, -46, 0, 8)
sendClose.BackgroundTransparency = 1
sendClose.Text                  = "✕"
sendClose.TextColor3            = Color3.fromRGB(110, 108, 150)
sendClose.TextSize              = 18
sendClose.Font                  = Enum.Font.Gotham
sendClose.Parent                = sendPanel

local sentScroll = Instance.new("ScrollingFrame")
sentScroll.Size                = UDim2.new(1, -44, 0, 300)
sentScroll.Position            = UDim2.new(0, 22, 0, 76)
sentScroll.BackgroundTransparency = 1
sentScroll.BorderSizePixel     = 0
sentScroll.ScrollBarThickness  = 3
sentScroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
sentScroll.Parent              = sendPanel
Instance.new("UIListLayout", sentScroll).Padding = UDim.new(0, 8)

local confirmBtn = Instance.new("TextButton")
confirmBtn.Size                   = UDim2.new(1, -44, 0, 44)
confirmBtn.Position               = UDim2.new(0, 22, 1, -62)
confirmBtn.BackgroundColor3       = Color3.fromRGB(60, 50, 108)
confirmBtn.BackgroundTransparency = 0.2
confirmBtn.BorderSizePixel        = 0
confirmBtn.Text                   = "寄出"
confirmBtn.TextColor3             = Color3.fromRGB(218, 214, 252)
confirmBtn.TextSize               = 16
confirmBtn.Font                   = Enum.Font.Gotham
confirmBtn.Parent                 = sendPanel
Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 10)

-- Build sentence option buttons
local selectedIdx = nil
local sentBtns    = {}

for i, sentence in ipairs(C.POSTCARDS) do
	local btn = Instance.new("TextButton")
	btn.LayoutOrder          = i
	btn.Size                 = UDim2.new(1, -4, 0, 44)
	btn.BackgroundColor3     = Color3.fromRGB(26, 22, 48)
	btn.BackgroundTransparency = 0.28
	btn.BorderSizePixel      = 0
	btn.Text                 = sentence
	btn.TextColor3           = Color3.fromRGB(188, 185, 222)
	btn.TextSize             = 13
	btn.Font                 = Enum.Font.Gotham
	btn.TextXAlignment       = Enum.TextXAlignment.Left
	btn.TextWrapped          = true
	btn.Parent               = sentScroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	local pad = Instance.new("UIPadding", btn)
	pad.PaddingLeft  = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)

	sentBtns[i] = btn

	btn.MouseButton1Click:Connect(function()
		selectedIdx = i
		for j, b in ipairs(sentBtns) do
			b.BackgroundColor3     = (j == i) and Color3.fromRGB(55, 45, 95) or Color3.fromRGB(26, 22, 48)
			b.BackgroundTransparency = (j == i) and 0.1 or 0.28
		end
	end)
end

sentScroll.CanvasSize = UDim2.new(0, 0, 0, #C.POSTCARDS * 52)

-- ============================================================
-- Logic
-- ============================================================

local function resetSendPanel()
	selectedIdx = nil
	for _, b in ipairs(sentBtns) do
		b.BackgroundColor3     = Color3.fromRGB(26, 22, 48)
		b.BackgroundTransparency = 0.28
	end
end

confirmBtn.MouseButton1Click:Connect(function()
	if not selectedIdx then return end
	sendPostcard:FireServer(selectedIdx)
	sendPanel.Visible = false
	resetSendPanel()
end)

sendClose.MouseButton1Click:Connect(function()
	sendPanel.Visible = false
	resetSendPanel()
end)

postcardRecv.OnClientEvent:Connect(function(data)
	if data and data.sentence then
		showNotification(data.sentence)
	end
end)

-- ============================================================
-- Mailbox proximity prompt
-- ============================================================

task.spawn(function()
	task.wait(3)
	local mailbox = workspace:FindFirstChild("PostcardMailbox")
	if not mailbox then return end

	local prompt = mailbox:FindFirstChildWhichIsA("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt", mailbox)
	end
	prompt.ActionText            = "寄出"
	prompt.ObjectText            = "匿名明信片"
	prompt.MaxActivationDistance = 12

	prompt.Triggered:Connect(function()
		sendPanel.Visible = true
	end)
end)
