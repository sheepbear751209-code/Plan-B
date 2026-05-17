-- GameClient.client.lua  (LocalScript — StarterPlayerScripts)
-- Master client controller. Applies world state to Lighting,
-- routes remote events to sub-modules, initialises AI and mini-games.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local Debris            = game:GetService("Debris")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Wait for server to create Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
if not remotes then
	warn("[Neverland] Remotes not found — is GameServer running?")
	return
end

local R = require(ReplicatedStorage:WaitForChild("Constants")).REMOTES

local worldStateUpdate = remotes:WaitForChild(R.WORLD_STATE_UPDATE)
local diaryResponse    = remotes:WaitForChild(R.DIARY_RESPONSE)
local eggActivated     = remotes:WaitForChild(R.EGG_ACTIVATED)
local triggerBlackHole = remotes:WaitForChild(R.TRIGGER_BLACK_HOLE)
local postcardReceived = remotes:WaitForChild(R.POSTCARD_RECEIVED)
local getWorldState    = remotes:WaitForChild(R.GET_WORLD_STATE)

local DeerAI        = require(script.Parent:WaitForChild("DeerAI"))
local EggController = require(script.Parent:WaitForChild("EggController"))
local MiniGames     = require(script.Parent:WaitForChild("MiniGames"))

-- ============================================================
-- World state → Lighting / FX
-- ============================================================

local function applyWorldState(state)
	if not state then return end

	-- Ambient colour: darker as darkness rises, cooler as rain rises
	local r = math.floor(math.max(40, 130 - state.darkness * 0.6))
	local g = math.floor(math.max(40, 135 - state.darkness * 0.65))
	local b = math.floor(math.min(255, 155 - state.darkness * 0.3 + state.rain * 0.3))

	TweenService:Create(Lighting, TweenInfo.new(6, Enum.EasingStyle.Sine), {
		Ambient    = Color3.fromRGB(r, g, b),
		Brightness = math.max(0.4, 2.2 - (state.darkness / 100)),
	}):Play()

	-- Bloom post-effect
	local bloom = Lighting:FindFirstChildWhichIsA("BloomEffect")
	if bloom then
		TweenService:Create(bloom, TweenInfo.new(5, Enum.EasingStyle.Sine), {
			Intensity = 0.25 + (state.bloom / 100) * 0.75,
			Size      = 18  + state.bloom * 0.35,
		}):Play()
	end

	-- Rain particle emitter in Workspace (placed in Studio as RainEffect/ParticleEmitter)
	local rainEffect = workspace:FindFirstChild("RainEffect")
	if rainEffect then
		local emitter = rainEffect:FindFirstChildWhichIsA("ParticleEmitter")
		if emitter then
			TweenService:Create(emitter, TweenInfo.new(4), {
				Rate = state.rain * 0.6,
			}):Play()
		end
	end

	-- Wind: drive the wind speed property if atmosphere exists
	local atmo = Lighting:FindFirstChildWhichIsA("Atmosphere")
	if atmo then
		-- Haze up slightly when rain is high
		TweenService:Create(atmo, TweenInfo.new(8, Enum.EasingStyle.Sine), {
			Haze = state.rain * 0.004,
		}):Play()
	end
end

-- ============================================================
-- Black Hole visuals
-- ============================================================

local function spawnBlackHoleVisual(id, position)
	local part = Instance.new("Part")
	part.Name        = "BlackHole_" .. id
	part.Size        = Vector3.new(6, 6, 0.5)
	part.Position    = position
	part.Anchored    = true
	part.CanCollide  = false
	part.CastShadow  = false
	part.Material    = Enum.Material.Neon
	part.Color       = Color3.fromRGB(8, 4, 18)
	part.Transparency = 0
	part.Parent      = workspace

	-- Spin
	local spinning = true
	task.spawn(function()
		while spinning and part.Parent do
			part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(1.5), 0)
			task.wait()
		end
	end)

	-- Glow
	local light = Instance.new("PointLight", part)
	light.Brightness = 2
	light.Color      = Color3.fromRGB(80, 40, 160)
	light.Range      = 30

	-- Proximity prompt — no player name shown
	local prompt = Instance.new("ProximityPrompt", part)
	prompt.ActionText           = "進入"
	prompt.ObjectText           = "某位夢語者留下的世界"
	prompt.MaxActivationDistance = 20
	prompt.HoldDuration         = 1.5

	prompt.Triggered:Connect(function()
		-- Prototype: show a simple overlay
		-- Full version: teleport to a reserved server with that world's state
		local gui = player.PlayerGui:FindFirstChild("BlackHoleUI")
		if gui then gui.Enabled = true end
		spinning = false
	end)

	return part
end

triggerBlackHole.OnClientEvent:Connect(function(data)
	if data.active then
		spawnBlackHoleVisual(data.id, data.position)
	else
		local part = workspace:FindFirstChild("BlackHole_" .. data.id)
		if part then
			TweenService:Create(part, TweenInfo.new(1), { Size = Vector3.new(0, 0, 0) }):Play()
			Debris:AddItem(part, 1.2)
		end
	end
end)

-- ============================================================
-- Egg & Deer event routing
-- ============================================================

eggActivated.OnClientEvent:Connect(function(data)
	EggController.OnWordReceived(data)
	DeerAI.OnWordSubmitted()
end)

-- Postcard notification is handled entirely by PostcardUI.client.lua (showNotification with slide tween)

worldStateUpdate.OnClientEvent:Connect(applyWorldState)

-- ============================================================
-- Boot sequence
-- ============================================================

task.spawn(function()
	task.wait(2) -- let character settle

	-- Pull and apply saved world state
	local state = getWorldState:InvokeServer()
	applyWorldState(state)

	-- Initialise client sub-systems
	EggController.Init()
	DeerAI.Init()
	MiniGames.Init()
end)

print("[Neverland] Client ready.")
