-- MemoryHouseUI.client.lua  (LocalScript — StarterGui/MemoryHouseUI)
-- Shows the player's diary history: date, mood, sentences.
-- Enabled by proximity prompt near the MemoryHouse Part in workspace.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes        = ReplicatedStorage:WaitForChild("Remotes", 15)
local R              = require(ReplicatedStorage:WaitForChild("Constants"))
local getDiaryHistory = remotes:WaitForChild(R.REMOTES.GET_DIARY_HISTORY)

local MOOD_COLOR = R.MOOD_KEYWORDS and {} or {
	CALM   = Color3.fromRGB(140, 175, 220),
	LONELY = Color3.fromRGB(155, 138, 200),
	HOPE   = Color3.fromRGB(228, 208, 135),
	CHAOS  = Color3.fromRGB(208, 148, 175),
}
MOOD_COLOR = {
	CALM   = Color3.fromRGB(140, 175, 220),
	LONELY = Color3.fromRGB(155, 138, 200),
	HOPE   = Color3.fromRGB(228, 208, 135),
	CHAOS  = Color3.fromRGB(208, 148, 175),
}

local MOOD_NAME = { CALM = "平靜", LONELY = "孤獨", HOPE = "希望", CHAOS = "混亂" }

-- ============================================================
-- Build UI
-- ============================================================

local sg = Instance.new("ScreenGui")
sg.Name           = "MemoryHouseUI"
sg.ResetOnSpawn   = false
sg.Enabled        = false
sg.Parent         = playerGui

local bg = Instance.new("Frame")
bg.Size                   = UDim2.new(0, 490, 0, 540)
bg.Position               = UDim2.new(0.5, -245, 0.5, -270)
bg.BackgroundColor3       = Color3.fromRGB(11, 9, 22)
bg.BackgroundTransparency = 0.04
bg.BorderSizePixel        = 0
bg.Parent                 = sg
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 16)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size                  = UDim2.new(1, -60, 0, 34)
titleLbl.Position              = UDim2.new(0, 24, 0, 16)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                  = "記憶居所"
titleLbl.TextColor3            = Color3.fromRGB(185, 180, 225)
titleLbl.TextSize              = 20
titleLbl.Font                  = Enum.Font.GothamLight
titleLbl.TextXAlignment        = Enum.TextXAlignment.Left
titleLbl.Parent                = bg

local subtitleLbl = Instance.new("TextLabel")
subtitleLbl.Size                  = UDim2.new(1, -60, 0, 20)
subtitleLbl.Position              = UDim2.new(0, 24, 0, 48)
subtitleLbl.BackgroundTransparency = 1
subtitleLbl.Text                  = "你留下的每一句話，都在這裡。"
subtitleLbl.TextColor3            = Color3.fromRGB(95, 92, 135)
subtitleLbl.TextSize              = 13
subtitleLbl.Font                  = Enum.Font.GothamLight
subtitleLbl.TextXAlignment        = Enum.TextXAlignment.Left
subtitleLbl.Parent                = bg

local closeBtn = Instance.new("TextButton")
closeBtn.Size                  = UDim2.new(0, 34, 0, 34)
closeBtn.Position              = UDim2.new(1, -46, 0, 10)
closeBtn.BackgroundTransparency = 1
closeBtn.Text                  = "✕"
closeBtn.TextColor3            = Color3.fromRGB(110, 108, 150)
closeBtn.TextSize              = 18
closeBtn.Font                  = Enum.Font.GothamLight
closeBtn.Parent                = bg

local scroll = Instance.new("ScrollingFrame")
scroll.Size                 = UDim2.new(1, -32, 1, -82)
scroll.Position             = UDim2.new(0, 16, 0, 74)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel      = 0
scroll.ScrollBarThickness   = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 75, 120)
scroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
scroll.Parent               = bg

local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding   = UDim.new(0, 10)

-- ============================================================
-- Entry card builder
-- ============================================================

local function buildCard(entry, order)
	local sentenceCount = entry.sentences and #entry.sentences or 0
	local cardHeight    = 48 + sentenceCount * 20

	local card = Instance.new("Frame")
	card.LayoutOrder          = order
	card.Size                 = UDim2.new(1, -8, 0, cardHeight)
	card.BackgroundColor3     = Color3.fromRGB(20, 16, 38)
	card.BackgroundTransparency = 0.18
	card.BorderSizePixel      = 0
	card.Parent               = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	local mood      = entry.mood or "CALM"
	local moodColor = MOOD_COLOR[mood] or MOOD_COLOR.CALM

	-- Left mood bar
	local bar = Instance.new("Frame")
	bar.Size             = UDim2.new(0, 4, 1, -14)
	bar.Position         = UDim2.new(0, 8, 0, 7)
	bar.BackgroundColor3 = moodColor
	bar.BackgroundTransparency = 0.25
	bar.BorderSizePixel  = 0
	bar.Parent           = card
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 2)

	-- Date + mood tag
	local meta = Instance.new("TextLabel")
	meta.Size                  = UDim2.new(1, -24, 0, 20)
	meta.Position              = UDim2.new(0, 20, 0, 8)
	meta.BackgroundTransparency = 1
	meta.Text                  = (entry.date or "未知日期") .. "  ·  " .. (MOOD_NAME[mood] or "平靜")
	meta.TextColor3            = moodColor
	meta.TextSize              = 12
	meta.Font                  = Enum.Font.GothamLight
	meta.TextXAlignment        = Enum.TextXAlignment.Left
	meta.Parent                = card

	-- Sentences
	local yOff = 28
	for _, s in ipairs(entry.sentences or {}) do
		local lbl = Instance.new("TextLabel")
		lbl.Size                  = UDim2.new(1, -24, 0, 18)
		lbl.Position              = UDim2.new(0, 20, 0, yOff)
		lbl.BackgroundTransparency = 1
		lbl.Text                  = s
		lbl.TextColor3            = Color3.fromRGB(185, 183, 215)
		lbl.TextSize              = 13
		lbl.Font                  = Enum.Font.GothamLight
		lbl.TextXAlignment        = Enum.TextXAlignment.Left
		lbl.TextTruncate          = Enum.TextTruncate.AtEnd
		lbl.Parent                = card
		yOff = yOff + 20
	end

	return cardHeight
end

-- ============================================================
-- Load and render history
-- ============================================================

local function loadHistory()
	-- Clear previous
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	local history = getDiaryHistory:InvokeServer(20)

	if not history or #history == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size                  = UDim2.new(1, 0, 0, 80)
		empty.BackgroundTransparency = 1
		empty.Text                  = "這裡還沒有記憶。\n回到草原，留下你的第一句話。"
		empty.TextColor3            = Color3.fromRGB(90, 88, 128)
		empty.TextSize              = 14
		empty.Font                  = Enum.Font.GothamLight
		empty.TextXAlignment        = Enum.TextXAlignment.Center
		empty.TextYAlignment        = Enum.TextYAlignment.Center
		empty.Parent                = scroll
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		return
	end

	local totalH = 0
	for i, entry in ipairs(history) do
		local h = buildCard(entry, i)
		totalH = totalH + h + 10
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 12)
end

-- ============================================================
-- Events
-- ============================================================

closeBtn.MouseButton1Click:Connect(function()
	sg.Enabled = false
end)

sg:GetPropertyChangedSignal("Enabled"):Connect(function()
	if sg.Enabled then
		task.spawn(loadHistory)
	end
end)
