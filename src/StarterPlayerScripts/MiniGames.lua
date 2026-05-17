-- MiniGames.lua  (ModuleScript — StarterPlayerScripts)
-- Two relaxation mini-games. No win/lose. No score. Pure ambient play.
--
-- 1. Rain Chime  — click floating orbs to trigger tones and rain ripples
-- 2. Lake Ripple — proximity to lake edge spawns expanding water rings

local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")
local Players      = game:GetService("Players")

local MiniGames = {}

local player = Players.LocalPlayer

-- ============================================================
-- Mini-game 1: Rain Chime
-- Setup: place Parts named "RainOrb" inside a Folder "RainChimeZone"
-- Each orb should have a child Sound with a distinct pitch
-- ============================================================

local function initRainChime()
	local zone = workspace:FindFirstChild("RainChimeZone")
	if not zone then return end

	for _, orb in ipairs(zone:GetChildren()) do
		if not orb:IsA("BasePart") then continue end

		local cd = orb:FindFirstChildWhichIsA("ClickDetector")
		if not cd then
			cd = Instance.new("ClickDetector", orb)
			cd.MaxActivationDistance = 20
		end

		local originalSize = orb.Size

		cd.MouseClick:Connect(function()
			-- Visual bounce
			TweenService:Create(orb, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = originalSize * 1.35,
			}):Play()
			task.delay(0.22, function()
				TweenService:Create(orb, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {
					Size = originalSize,
				}):Play()
			end)

			-- Sound
			local snd = orb:FindFirstChildWhichIsA("Sound")
			if snd then snd:Play() end

			-- Rain droplet particle burst
			local p = orb:FindFirstChildWhichIsA("ParticleEmitter")
			if p then p:Emit(6) end

			-- Small ripple ring on the ground near the orb
			local ripple = Instance.new("Part")
			ripple.Size         = Vector3.new(0.3, 0.05, 0.3)
			ripple.Position     = Vector3.new(orb.Position.X, orb.Position.Y - orb.Size.Y * 0.5, orb.Position.Z)
			ripple.Anchored     = true
			ripple.CanCollide   = false
			ripple.Material     = Enum.Material.Neon
			ripple.Color        = Color3.fromRGB(160, 200, 230)
			ripple.Transparency = 0.4
			ripple.Shape        = Enum.PartType.Cylinder
			ripple.Parent       = workspace

			TweenService:Create(ripple, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {
				Size        = Vector3.new(12, 0.05, 12),
				Transparency = 1,
			}):Play()
			Debris:AddItem(ripple, 1.4)
		end)
	end
end

-- ============================================================
-- Mini-game 2: Lake Ripple
-- Setup: place a Part named "LakeSurface" at water level
-- Player walking near it spawns expanding rings automatically
-- ============================================================

local RIPPLE_RADIUS   = 18   -- how close the player needs to be (studs)
local RIPPLE_INTERVAL = 0.8  -- seconds between auto-ripples
local lastRippleAt    = 0

local function spawnLakeRipple(centre)
	local x = centre.X + math.random(-4, 4)
	local z = centre.Z + math.random(-4, 4)

	local ring = Instance.new("Part")
	ring.Size         = Vector3.new(0.6, 0.08, 0.6)
	ring.Position     = Vector3.new(x, centre.Y + 0.05, z)
	ring.Anchored     = true
	ring.CanCollide   = false
	ring.Material     = Enum.Material.Neon
	ring.Color        = Color3.fromRGB(170, 210, 235)
	ring.Transparency = 0.35
	ring.Shape        = Enum.PartType.Cylinder
	ring.Parent       = workspace

	TweenService:Create(ring, TweenInfo.new(2, Enum.EasingStyle.Sine), {
		Size        = Vector3.new(10, 0.04, 10),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 2.2)
end

local function initLakeRipple()
	local lake = workspace:FindFirstChild("LakeSurface")
	if not lake then return end

	RunService.Heartbeat:Connect(function()
		local now  = os.clock()
		if now - lastRippleAt < RIPPLE_INTERVAL then return end

		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		if (root.Position - lake.Position).Magnitude <= RIPPLE_RADIUS then
			lastRippleAt = now
			spawnLakeRipple(lake.Position)
		end
	end)
end

-- ============================================================
-- Public API
-- ============================================================

function MiniGames.Init()
	initRainChime()
	initLakeRipple()
end

return MiniGames
