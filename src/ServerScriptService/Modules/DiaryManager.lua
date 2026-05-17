-- DiaryManager.lua  (ModuleScript — ServerScriptService/Modules)
-- Owns all diary read/write, DataStore I/O, and mood classification.
-- One player's diary = one DataStore key.

local DataStoreService = game:GetService("DataStoreService")
local Constants = require(game.ReplicatedStorage.Constants)

local DiaryManager = {}

local store = DataStoreService:GetDataStore("NeverlandDiary_v1")

-- ============================================================
-- Internal helpers
-- ============================================================

local function today()
	local d = os.date("*t", os.time())
	return string.format("%04d-%02d-%02d", d.year, d.month, d.day)
end

local function classifyMood(sentences)
	local text = table.concat(sentences, " "):lower()
	local scores = { CALM = 0, LONELY = 0, HOPE = 0, CHAOS = 0 }

	for mood, keywords in pairs(Constants.MOOD_KEYWORDS) do
		for _, kw in ipairs(keywords) do
			if text:find(kw, 1, true) then
				scores[mood] = scores[mood] + 1
			end
		end
	end

	local top, topScore = "CALM", -1
	for mood, score in pairs(scores) do
		if score > topScore then
			top, topScore = mood, score
		end
	end
	return top
end

local function defaultData()
	return {
		entries       = {},   -- newest first
		lastEntryDate = "",
		totalEntries  = 0,
		isPremium     = false,
	}
end

-- ============================================================
-- DataStore I/O  (pcall-wrapped everywhere)
-- ============================================================

function DiaryManager.Load(userId)
	local ok, data = pcall(function()
		return store:GetAsync("Player_" .. userId)
	end)
	return (ok and data) or defaultData()
end

local function save(userId, data)
	return pcall(function()
		store:SetAsync("Player_" .. userId, data)
	end)
end

-- ============================================================
-- Public API
-- ============================================================

-- Returns { canWrite, todayCount, max, sentences }
function DiaryManager.TodayStatus(userId)
	local data    = DiaryManager.Load(userId)
	local todayStr = today()

	local entry = nil
	for _, e in ipairs(data.entries) do
		if e.date == todayStr then entry = e; break end
	end

	local count = entry and #entry.sentences or 0
	return {
		canWrite   = count < Constants.DIARY.MAX_SENTENCES_PER_DAY,
		todayCount = count,
		max        = Constants.DIARY.MAX_SENTENCES_PER_DAY,
		sentences  = entry and entry.sentences or {},
	}
end

-- Returns ok (bool), payload (entry | error string)
function DiaryManager.Submit(userId, rawText)
	-- Validate
	if type(rawText) ~= "string" then return false, "invalid" end
	local text = rawText:match("^%s*(.-)%s*$")
	local len  = #text
	if len < Constants.DIARY.MIN_CHARS then return false, "too_short" end
	if len > Constants.DIARY.MAX_CHARS then return false, "too_long"  end

	-- Load once and derive status from the same data (avoids double DataStore read)
	local data    = DiaryManager.Load(userId)
	local todayStr = today()

	local entry = nil
	for _, e in ipairs(data.entries) do
		if e.date == todayStr then entry = e; break end
	end

	local todayCount = entry and #entry.sentences or 0
	if todayCount >= Constants.DIARY.MAX_SENTENCES_PER_DAY then
		return false, "daily_limit"
	end

	if not entry then
		entry = { date = todayStr, sentences = {}, mood = "CALM" }
		table.insert(data.entries, 1, entry)
	end

	table.insert(entry.sentences, text)
	entry.mood       = classifyMood(entry.sentences)
	data.lastEntryDate = todayStr
	data.totalEntries  = data.totalEntries + 1

	-- Trim to FREE_RETENTION_DAYS window (free tier)
	if not data.isPremium then
		local cutoff = os.time() - (Constants.DIARY.FREE_RETENTION_DAYS * 86400)
		local kept = {}
		for _, e in ipairs(data.entries) do
			if #kept < 30 and (e.date >= os.date("%Y-%m-%d", cutoff)) then
				table.insert(kept, e)
			end
		end
		data.entries = kept
	end

	local ok = save(userId, data)
	if ok then
		return true, entry
	else
		return false, "save_failed"
	end
end

-- Returns array of recent entries (newest first)
function DiaryManager.History(userId, limit)
	local data   = DiaryManager.Load(userId)
	local result = {}
	for i, e in ipairs(data.entries) do
		if i > (limit or 15) then break end
		table.insert(result, e)
	end
	return result
end

return DiaryManager
