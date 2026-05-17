-- DiaryUI.client.lua  (LocalScript — StarterGui/DiaryUI)
-- The core emotional mechanic: player writes short sentences.
-- UI is intentionally minimal and dim — no game-y colours.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes      = ReplicatedStorage:WaitForChild("Remotes", 15)
local R            = require(ReplicatedStorage:WaitForChild("Constants")).REMOTES
local submitDiary  = remotes:WaitForChild(R.SUBMIT_DIARY)
local diaryResp    = remotes:WaitForChild(R.DIARY_RESPONSE)
local canWrite     = remotes:WaitForChild(R.CAN_WRITE_TODAY)

-- ============================================================
-- Build ScreenGui
-- ============================================================

local sg = Instance.new("ScreenGui")
sg.Name            = "DiaryUI"
sg.ResetOnSpawn    = false
sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
sg.Parent          = playerGui

-- Floating trigger button (bottom-centre)
local openBtn = Instance.new("TextButton")
openBtn.Size                  = UDim2.new(0, 160, 0, 44)
openBtn.Position              = UDim2.new(0.5, -80, 1, -72)
openBtn.BackgroundColor3      = Color3.fromRGB(28, 24, 48)
openBtn.BackgroundTransparency = 0.25
openBtn.BorderSizePixel       = 0
openBtn.Text                  = "留下話語"
openBtn.TextColor3            = Color3.fromRGB(210, 208, 248)
openBtn.TextSize              = 16
openBtn.Font                  = Enum.Font.GothamLight
openBtn.Parent                = sg
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 22)

-- Main panel
local panel = Instance.new("Frame")
panel.Name                   = "DiaryPanel"
panel.Size                   = UDim2.new(0, 430, 0, 360)
panel.Position               = UDim2.new(0.5, -215, 0.5, -180)
panel.BackgroundColor3       = Color3.fromRGB(14, 11, 26)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel        = 0
panel.Visible                = false
panel.Parent                 = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

-- Heading
local heading = Instance.new("TextLabel")
heading.Size                 = UDim2.new(1, -44, 0, 34)
heading.Position             = UDim2.new(0, 22, 0, 14)
heading.BackgroundTransparency = 1
heading.Text                 = "這裡的生命，會回應留下的話語。"
heading.TextColor3           = Color3.fromRGB(170, 168, 215)
heading.TextSize             = 14
heading.Font                 = Enum.Font.GothamLight
heading.TextXAlignment       = Enum.TextXAlignment.Left
heading.Parent               = panel

-- Daily count
local countLbl = Instance.new("TextLabel")
countLbl.Name                 = "CountLabel"
countLbl.Size                 = UDim2.new(1, -44, 0, 20)
countLbl.Position             = UDim2.new(0, 22, 0, 50)
countLbl.BackgroundTransparency = 1
countLbl.Text                 = "今日：0 / 5"
countLbl.TextColor3           = Color3.fromRGB(105, 105, 148)
countLbl.TextSize             = 13
countLbl.Font                 = Enum.Font.GothamLight
countLbl.TextXAlignment       = Enum.TextXAlignment.Left
countLbl.Parent               = panel

-- Text input
local input = Instance.new("TextBox")
input.Name                   = "InputBox"
input.Size                   = UDim2.new(1, -44, 0, 86)
input.Position               = UDim2.new(0, 22, 0, 80)
input.BackgroundColor3       = Color3.fromRGB(22, 18, 42)
input.BackgroundTransparency = 0.15
input.BorderSizePixel        = 0
input.Text                   = ""
input.PlaceholderText        = "今天，你想留下什麼…"
input.PlaceholderColor3      = Color3.fromRGB(75, 72, 108)
input.TextColor3             = Color3.fromRGB(210, 208, 238)
input.TextSize               = 15
input.Font                   = Enum.Font.GothamLight
input.MultiLine              = true
input.ClearTextOnFocus       = false
input.TextWrapped            = true
input.TextXAlignment         = Enum.TextXAlignment.Left
input.TextYAlignment         = Enum.TextYAlignment.Top
input.Parent                 = panel
Instance.new("UICorner", input).CornerRadius = UDim.new(0, 10)
local inputPad = Instance.new("UIPadding", input)
inputPad.PaddingLeft   = UDim.new(0, 10)
inputPad.PaddingRight  = UDim.new(0, 10)
inputPad.PaddingTop    = UDim.new(0, 8)

-- Char counter
local charLbl = Instance.new("TextLabel")
charLbl.Size                 = UDim2.new(1, -44, 0, 18)
charLbl.Position             = UDim2.new(0, 22, 0, 168)
charLbl.BackgroundTransparency = 1
charLbl.Text                 = "0 / 80"
charLbl.TextColor3           = Color3.fromRGB(75, 72, 108)
charLbl.TextSize             = 12
charLbl.Font                 = Enum.Font.GothamLight
charLbl.TextXAlignment       = Enum.TextXAlignment.Right
charLbl.Parent               = panel

-- Submit
local submitBtn = Instance.new("TextButton")
submitBtn.Name                   = "SubmitBtn"
submitBtn.Size                   = UDim2.new(1, -44, 0, 44)
submitBtn.Position               = UDim2.new(0, 22, 0, 196)
submitBtn.BackgroundColor3       = Color3.fromRGB(62, 52, 112)
submitBtn.BackgroundTransparency = 0.18
submitBtn.BorderSizePixel        = 0
submitBtn.Text                   = "留下"
submitBtn.TextColor3             = Color3.fromRGB(218, 214, 252)
submitBtn.TextSize               = 16
submitBtn.Font                   = Enum.Font.GothamLight
submitBtn.Parent                 = panel
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 10)

-- Status message (below button)
local statusLbl = Instance.new("TextLabel")
statusLbl.Name                 = "StatusLabel"
statusLbl.Size                 = UDim2.new(1, -44, 0, 24)
statusLbl.Position             = UDim2.new(0, 22, 0, 250)
statusLbl.BackgroundTransparency = 1
statusLbl.Text                 = ""
statusLbl.TextColor3           = Color3.fromRGB(148, 200, 158)
statusLbl.TextSize             = 13
statusLbl.Font                 = Enum.Font.GothamLight
statusLbl.TextXAlignment       = Enum.TextXAlignment.Center
statusLbl.Parent               = panel

-- "Today's words" section label
local sectionLbl = Instance.new("TextLabel")
sectionLbl.Size                 = UDim2.new(1, -44, 0, 18)
sectionLbl.Position             = UDim2.new(0, 22, 0, 282)
sectionLbl.BackgroundTransparency = 1
sectionLbl.Text                 = "今日所留"
sectionLbl.TextColor3           = Color3.fromRGB(90, 88, 128)
sectionLbl.TextSize             = 12
sectionLbl.Font                 = Enum.Font.GothamLight
sectionLbl.TextXAlignment       = Enum.TextXAlignment.Left
sectionLbl.Parent               = panel

-- Sentence list
local listFrame = Instance.new("ScrollingFrame")
listFrame.Name                = "TodayList"
listFrame.Size                = UDim2.new(1, -44, 0, 56)
listFrame.Position            = UDim2.new(0, 22, 0, 302)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel     = 0
listFrame.ScrollBarThickness  = 3
listFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
listFrame.Parent              = panel
Instance.new("UIListLayout", listFrame).Padding = UDim.new(0, 4)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size                 = UDim2.new(0, 32, 0, 32)
closeBtn.Position             = UDim2.new(1, -42, 0, 8)
closeBtn.BackgroundTransparency = 1
closeBtn.Text                 = "✕"
closeBtn.TextColor3           = Color3.fromRGB(110, 108, 150)
closeBtn.TextSize             = 16
closeBtn.Font                 = Enum.Font.GothamLight
closeBtn.Parent               = panel

-- ============================================================
-- Logic
-- ============================================================

local submitting = false

local ERROR_MSGS = {
	too_short   = "再多說一點點…",
	too_long    = "試著精簡一些。",
	daily_limit = "今日的話語已滿。明日再來。",
	save_failed = "暫時無法儲存，稍後再試。",
}

local function showStatus(msg, isError)
	statusLbl.Text      = msg
	statusLbl.TextColor3 = isError
		and Color3.fromRGB(205, 150, 105)
		or  Color3.fromRGB(148, 200, 158)
	task.delay(4, function()
		if statusLbl.Text == msg then statusLbl.Text = "" end
	end)
end

local function rebuildList(sentences)
	for _, c in ipairs(listFrame:GetChildren()) do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	for i, s in ipairs(sentences) do
		local lbl = Instance.new("TextLabel")
		lbl.LayoutOrder          = i
		lbl.Size                 = UDim2.new(1, 0, 0, 18)
		lbl.BackgroundTransparency = 1
		lbl.Text                 = i .. ". " .. s
		lbl.TextColor3           = Color3.fromRGB(140, 138, 178)
		lbl.TextSize             = 12
		lbl.Font                 = Enum.Font.GothamLight
		lbl.TextXAlignment       = Enum.TextXAlignment.Left
		lbl.TextTruncate         = Enum.TextTruncate.AtEnd
		lbl.Parent               = listFrame
	end
	listFrame.CanvasSize = UDim2.new(0, 0, 0, #sentences * 22)
end

local function refreshStatus()
	local info = canWrite:InvokeServer()
	if not info then return end
	countLbl.Text = string.format("今日：%d / %d", info.todayCount, info.max)
	rebuildList(info.sentences or {})

	if not info.canWrite then
		input.PlaceholderText = "今日的話語已留下，明日再來。"
		input.TextEditable    = false
		submitBtn.Text        = "今日已完成"
		submitBtn.BackgroundTransparency = 0.55
	end
end

input:GetPropertyChangedSignal("Text"):Connect(function()
	local len = #input.Text
	charLbl.Text = len .. " / 80"
	charLbl.TextColor3 = len > 80
		and Color3.fromRGB(215, 110, 110)
		or  Color3.fromRGB(75, 72, 108)
end)

submitBtn.MouseButton1Click:Connect(function()
	if submitting then return end
	local text = input.Text:match("^%s*(.-)%s*$")
	if #text < 10 then showStatus("再多說一點點…", true); return end
	if #text > 80 then showStatus("試著精簡一些。", true); return end

	submitting = true
	submitBtn.Text = "…"
	submitDiary:FireServer(text)
	input.Text = ""
end)

diaryResp.OnClientEvent:Connect(function(data)
	submitting = false
	submitBtn.Text = "留下"

	if data.success then
		showStatus("世界記住了。", false)
		refreshStatus()
	else
		showStatus(ERROR_MSGS[data.reason] or "稍後再試。", true)
	end
end)

openBtn.MouseButton1Click:Connect(function()
	panel.Visible = true
	refreshStatus()
	TweenService:Create(panel, TweenInfo.new(0.28, Enum.EasingStyle.Quint), {
		BackgroundTransparency = 0.08,
	}):Play()
end)

closeBtn.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

-- ============================================================
-- Memory House proximity prompt (wired here to keep GUI logic together)
-- ============================================================

task.spawn(function()
	task.wait(3)
	local house = workspace:FindFirstChild("MemoryHouse")
	if not house then return end

	local prompt = house:FindFirstChildWhichIsA("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt", house)
	end
	prompt.ActionText            = "回顧"
	prompt.ObjectText            = "記憶居所"
	prompt.MaxActivationDistance = 14

	prompt.Triggered:Connect(function()
		local memUI = playerGui:FindFirstChild("MemoryHouseUI")
		if memUI then memUI.Enabled = true end
	end)
end)
