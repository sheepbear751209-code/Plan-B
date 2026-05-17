-- BlackHoleManager.lua  (ModuleScript — ServerScriptService/Modules)
-- Manages black hole spawn timing and active state.
-- Each black hole is a portal to a random showcase world (read-only viewing).

local Constants = require(game.ReplicatedStorage.Constants)

local BlackHoleManager = {}

local active      = {}    -- [id] = { position, spawnedAt, duration }
local nextSpawnAt = 0

local function makeId()
	return tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

-- ============================================================
-- Public API
-- ============================================================

function BlackHoleManager.ShouldSpawn()
	return os.time() >= nextSpawnAt
end

-- spawnPosition: Vector3 (chosen by GameServer, typically above the map)
-- Returns id, position
function BlackHoleManager.Spawn(spawnPosition)
	local W   = Constants.WORLD
	local id  = makeId()
	active[id] = {
		position  = spawnPosition,
		spawnedAt = os.time(),
		duration  = W.BLACK_HOLE_DURATION,
	}

	local interval = math.random(W.BLACK_HOLE_INTERVAL_MIN, W.BLACK_HOLE_INTERVAL_MAX)
	nextSpawnAt = os.time() + interval

	return id, spawnPosition
end

function BlackHoleManager.Remove(id)
	active[id] = nil
end

-- Returns only the still-live holes, pruning expired ones
function BlackHoleManager.GetActive()
	local now   = os.time()
	local valid = {}
	for id, bh in pairs(active) do
		if now < bh.spawnedAt + bh.duration then
			valid[id] = bh
		else
			active[id] = nil
		end
	end
	return valid
end

return BlackHoleManager
