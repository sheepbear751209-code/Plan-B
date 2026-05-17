-- EggController.lua  (ModuleScript — StarterPlayerScripts)
-- Manages the companion egg's visual feedback.
-- Egg glows, wobbles, and changes colour in response to player words.
-- Clicking it plays a low hum.

local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")

local EggController = {}

-- ============================================================
-- Mood → colour mapping
-- ============================================================

local MOOD_COLOR = {
	CALM   = Color3.fromRGB(190, 210, 255),
	LONELY = Color3.fromRGB(175, 165, 215),
	HOPE   = Color3.fromRGB(255, 235, 160),
	CHAOS  = Color3.fromRGB(215, 160, 185),
}

local DEFAULT_COLOR = Color3.fromRGB(230, 230, 240)

-- ============================================================
-- Internal helpers
-- ============================================================

local egg = nil

local function getEgg()
	if egg and egg.Parent then return egg end
	egg = workspace:FindFirstChild("CompanionEgg")
	return egg
end

local function ensureLight()
	local e = getEgg()
	if not e then return nil end
	local light = e:FindFirstChildWhichIsA("PointLight")
	if not light then
		light = Instance.new("PointLight", e)
		light.Brightness = 0.6
		light.Color      = DEFAULT_COLOR
		light.Range      = 14
	end
	return light
end

-- Float egg continuously up and down
local floatConnection = nil

local function startFloat()
	local e = getEgg()
	if not e or not e:IsA("BasePart") then return end
	local baseY = e.Position.Y

	TweenService:Create(e, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Position = Vector3.new(e.Position.X, baseY + 0.45, e.Position.Z),
	}):Play()
end

local function wobble()
	local e = getEgg()
	if not e or not e:IsA("BasePart") then return end
	local base = e.CFrame

	TweenService:Create(e, TweenInfo.new(0.12, Enum.EasingStyle.Bounce), {
		CFrame = base * CFrame.Angles(0, 0, math.rad(9)),
	}):Play()
	task.delay(0.24, function()
		TweenService:Create(e, TweenInfo.new(0.25, Enum.EasingStyle.Bounce), {
			CFrame = base * CFrame.Angles(0, 0, math.rad(-6)),
		}):Play()
	end)
	task.delay(0.55, function()
		TweenService:Create(e, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {
			CFrame = base,
		}):Play()
	end)
end

local function pulseGlow(color)
	local light = ensureLight()
	if not light then return end

	light.Color = color or DEFAULT_COLOR
	TweenService:Create(light, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
		Brightness = 4,
	}):Play()
	task.delay(0.6, function()
		TweenService:Create(light, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {
			Brightness = 0.6,
		}):Play()
	end)
end

-- Emit a brief particle burst (if ParticleEmitter exists on egg)
local function emitParticles(count)
	local e = getEgg()
	if not e then return end
	local p = e:FindFirstChildWhichIsA("ParticleEmitter")
	if p then p:Emit(count or 8) end
end

-- ============================================================
-- Public API
-- ============================================================

function EggController.Init()
	local e = getEgg()
	if not e then
		warn("[EggController] 'CompanionEgg' not found in Workspace. Place a Part named CompanionEgg.")
		return
	end

	ensureLight()
	startFloat()

	-- Click / tap to play hum
	local cd = e:FindFirstChildWhichIsA("ClickDetector")
	if not cd then
		cd = Instance.new("ClickDetector", e)
		cd.MaxActivationDistance = 18
	end

	cd.MouseClick:Connect(function()
		EggController.OnClick()
	end)
end

function EggController.OnClick()
	wobble()

	local e = getEgg()
	if not e then return end
	local sound = e:FindFirstChild("HumSound")
	if sound then sound:Play() end
end

-- Called from GameClient when server confirms a word was saved
function EggController.OnWordReceived(data)
	local mood  = data and data.mood or "CALM"
	local color = MOOD_COLOR[mood] or DEFAULT_COLOR

	pulseGlow(color)
	wobble()
	emitParticles(12)

	-- Gradually shift egg colour toward mood colour
	local e = getEgg()
	if e and e:IsA("BasePart") then
		TweenService:Create(e, TweenInfo.new(3, Enum.EasingStyle.Sine), {
			Color = color,
		}):Play()
	end
end

return EggController
