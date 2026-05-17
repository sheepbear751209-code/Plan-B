-- DeerAI.lua  (ModuleScript — StarterPlayerScripts)
-- Client-side companion deer behaviour.
-- States: idle → following → observing → sitting
-- No combat, no stats. Pure ambient companionship.

local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local DeerAI = {}

local player = Players.LocalPlayer

-- ============================================================
-- Tuning
-- ============================================================

local FOLLOW_DIST   = 9    -- start following beyond this distance
local CLOSE_DIST    = 4    -- "personal space" — won't get closer
local SILENT_SECS   = 90   -- after this many idle seconds, deer moves in
local CHECK_EVERY   = 5    -- movement detection interval (seconds)

-- ============================================================
-- Internal state
-- ============================================================

local deer           = nil
local state          = "idle"
local stateTimer     = 0
local lastActivity   = os.time()
local lastPlayerPos  = nil
local movementTimer  = 0

local function getDeer()
	if deer and deer.Parent then return deer end
	deer = workspace:FindFirstChild("CompanionDeer")
	return deer
end

local function getRoot()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function deerRoot()
	local d = getDeer()
	if not d then return nil end
	return d:FindFirstChild("HumanoidRootPart")
		or d.PrimaryPart
end

local function humanoid()
	local d = getDeer()
	if not d then return nil end
	return d:FindFirstChildWhichIsA("Humanoid")
end

-- ============================================================
-- Movement helpers
-- ============================================================

local function moveTo(pos, speed)
	local h = humanoid()
	if not h then return end
	h.WalkSpeed = speed or 7
	h:MoveTo(pos)
end

local function setState(new)
	if state == new then return end
	state = new
end

-- ============================================================
-- Main think loop
-- ============================================================

local function think(dt)
	stateTimer = stateTimer - dt
	if stateTimer > 0 then return end

	local pRoot = getRoot()
	local dRoot = deerRoot()
	if not pRoot or not dRoot then return end

	local pPos = pRoot.Position
	local dPos = dRoot.Position
	local dist = (dPos - pPos).Magnitude
	local silent = (os.time() - lastActivity) >= SILENT_SECS

	-- Priority 1: silent player — drift closer
	if silent and dist > CLOSE_DIST + 1 then
		setState("following")
		local target = pPos + (dPos - pPos).Unit * CLOSE_DIST
		moveTo(target, 4)
		stateTimer = 3
		return
	end

	-- Priority 2: too far — follow
	if dist > FOLLOW_DIST then
		setState("following")
		local target = pPos + (dPos - pPos).Unit * FOLLOW_DIST
		moveTo(target, 8)
		stateTimer = 2
		return
	end

	-- Priority 3: too close — give space
	if dist < CLOSE_DIST then
		setState("idle")
		local away = dPos + (dPos - pPos).Unit * 2
		moveTo(away, 5)
		stateTimer = 1.5
		return
	end

	-- Priority 4: in-range ambient behaviour
	local roll = math.random(100)
	if roll < 15 then
		setState("sitting")
		stateTimer = math.random(6, 16)
	elseif roll < 35 then
		setState("observing")
		-- Face the player softly
		local look = CFrame.lookAt(
			dPos,
			Vector3.new(pPos.X, dPos.Y, pPos.Z)
		)
		TweenService:Create(dRoot, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {
			CFrame = look
		}):Play()
		stateTimer = math.random(3, 9)
	else
		setState("idle")
		stateTimer = math.random(2, 5)
	end
end

-- ============================================================
-- Activity detection
-- ============================================================

local function checkActivity()
	local root = getRoot()
	if not root then return end
	local pos = root.Position

	if lastPlayerPos then
		if (pos - lastPlayerPos).Magnitude > 1.5 then
			lastActivity = os.time()
		end
	end
	lastPlayerPos = pos
end

-- ============================================================
-- Public API
-- ============================================================

function DeerAI.Init()
	RunService.Heartbeat:Connect(function(dt)
		movementTimer = movementTimer + dt
		if movementTimer >= CHECK_EVERY then
			movementTimer = 0
			checkActivity()
		end
		think(dt)
	end)
end

-- Called from GameClient when player submits a word
function DeerAI.OnWordSubmitted()
	lastActivity = os.time()

	local dRoot = deerRoot()
	local pRoot = getRoot()
	if not dRoot or not pRoot then return end

	-- Brief "noticed something" approach
	setState("observing")
	local dir    = (pRoot.Position - dRoot.Position).Unit
	local target = dRoot.Position + dir * 2.5
	moveTo(target, 10)
	stateTimer = 4
end

return DeerAI
