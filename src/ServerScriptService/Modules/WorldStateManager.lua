-- WorldStateManager.lua  (ModuleScript — ServerScriptService/Modules)
-- Owns world-state per player: rain / bloom / darkness / lake / wind.
-- Intentionally fuzzy: players feel the world responds, but can't min-max it.

local DataStoreService = game:GetService("DataStoreService")
local Constants        = require(game.ReplicatedStorage.Constants)

local WorldStateManager = {}

local store = DataStoreService:GetDataStore("NeverlandWorld_v1")

-- ============================================================
-- Internal helpers
-- ============================================================

local function clamp(v) return math.max(0, math.min(100, v)) end

local function defaultState()
	local W = Constants.WORLD
	return {
		rain      = W.DEFAULT_RAIN,
		bloom     = W.DEFAULT_BLOOM,
		darkness  = W.DEFAULT_DARKNESS,
		lake      = W.DEFAULT_LAKE,
		wind      = W.DEFAULT_WIND,
		updatedAt = 0,
	}
end

-- Count keyword hits across a block of text
local function countKeywords(text, keywords)
	local hits = 0
	for _, kw in ipairs(keywords) do
		local _, n = text:gsub(kw, "")
		hits = hits + n
	end
	return hits
end

-- Analyse a list of sentences → influence map  { RAIN=2, NIGHT=1, ... }
local function analyse(sentences)
	local text = table.concat(sentences, " "):lower()
	local inf  = {}
	for cat, keywords in pairs(Constants.KEYWORDS) do
		inf[cat] = countKeywords(text, keywords)
	end
	return inf
end

-- ============================================================
-- DataStore I/O
-- ============================================================

function WorldStateManager.Load(userId)
	local ok, data = pcall(function()
		return store:GetAsync("WorldState_" .. userId)
	end)
	return (ok and data) or defaultState()
end

local function save(userId, state)
	pcall(function()
		store:SetAsync("WorldState_" .. userId, state)
	end)
end

-- ============================================================
-- Public API
-- ============================================================

function WorldStateManager.GetState(userId)
	return WorldStateManager.Load(userId)
end

-- Called after player submits diary sentence(s).
-- Returns the updated state.
function WorldStateManager.UpdateFromSentences(userId, sentences)
	local state = WorldStateManager.Load(userId)
	local inf   = analyse(sentences)
	local W     = Constants.WORLD
	local w     = W.KEYWORD_WEIGHT

	-- Small random fuzz so the world never feels mechanical
	local fuzz = math.random(-1, 1) * 0.5

	if inf.RAIN   > 0 then state.rain     = clamp(state.rain     + inf.RAIN   * w + fuzz) end
	if inf.SEA    > 0 then state.lake     = clamp(state.lake     + inf.SEA    * w + fuzz) end
	if inf.NIGHT  > 0 then state.darkness = clamp(state.darkness + inf.NIGHT  * w + fuzz) end
	if inf.FLOWER > 0 then state.bloom    = clamp(state.bloom    + inf.FLOWER * w + fuzz) end
	if inf.WIND   > 0 then state.wind     = clamp(state.wind     + inf.WIND   * w + fuzz) end
	-- LIGHT counters darkness
	if inf.LIGHT  > 0 then state.darkness = clamp(state.darkness - inf.LIGHT  * w + fuzz) end
	-- ALONE makes the world a little quieter (lower wind)
	if inf.ALONE  > 0 then state.wind     = clamp(state.wind     - inf.ALONE  * (w * 0.5)) end

	-- Slow drift toward baseline — world "breathes" back over time
	local d = W.DRIFT_RATE
	state.rain     = clamp(state.rain     + (W.DEFAULT_RAIN     - state.rain)     * d)
	state.wind     = clamp(state.wind     + (W.DEFAULT_WIND     - state.wind)     * d)
	state.darkness = clamp(state.darkness + (W.DEFAULT_DARKNESS - state.darkness) * d)

	state.updatedAt = os.time()
	save(userId, state)
	return state
end

-- ============================================================
-- Showcase pool  (for Black Hole system)
-- Stores snapshots of world states anonymously
-- ============================================================

local SHOWCASE_KEY = "Showcase_Pool_v1"
local MAX_SHOWCASE = 20

function WorldStateManager.AddToShowcase(state)
	local ok, pool = pcall(function()
		return store:GetAsync(SHOWCASE_KEY)
	end)
	pool = (ok and pool) or {}

	table.insert(pool, { state = state, at = os.time() })
	if #pool > MAX_SHOWCASE then table.remove(pool, 1) end

	pcall(function() store:SetAsync(SHOWCASE_KEY, pool) end)
end

function WorldStateManager.GetShowcasePool()
	local ok, pool = pcall(function()
		return store:GetAsync(SHOWCASE_KEY)
	end)
	return (ok and pool) or {}
end

return WorldStateManager
