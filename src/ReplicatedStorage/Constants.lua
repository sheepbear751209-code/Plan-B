-- Constants.lua
-- Shared config between server and client. No game logic here.

local Constants = {}

-- ============================================================
-- DIARY
-- ============================================================
Constants.DIARY = {
	MAX_SENTENCES_PER_DAY = 5,
	MIN_SENTENCES_PER_DAY = 1,
	MIN_CHARS             = 10,  -- ~5 Chinese characters
	MAX_CHARS             = 80,  -- ~40 Chinese characters
	FREE_RETENTION_DAYS   = 30,
}

-- ============================================================
-- WORLD KEYWORD MAPPING
-- Words the player writes → which world axis they nudge
-- Intentionally fuzzy: partial matches count
-- ============================================================
Constants.KEYWORDS = {
	RAIN   = { "雨", "rain", "濕", "淋", "潮", "霧", "濛" },
	SEA    = { "海", "sea", "ocean", "浪", "波", "洋", "漂" },
	NIGHT  = { "夜", "night", "暗", "黑", "深夜", "星", "月" },
	FLOWER = { "花", "flower", "bloom", "開", "瓣", "草", "植" },
	WIND   = { "風", "wind", "breeze", "吹", "飄", "搖" },
	LIGHT  = { "光", "light", "亮", "shine", "陽", "燈", "晨" },
	ALONE  = { "孤", "alone", "lonely", "獨", "寂", "空", "一個人" },
	HOPE   = { "希望", "hope", "夢", "dream", "願", "明天", "未來" },
}

-- ============================================================
-- MOOD CLASSIFICATION
-- Auto-tagged on each diary entry
-- ============================================================
Constants.MOOD_KEYWORDS = {
	CALM   = { "平靜", "安", "靜", "peaceful", "calm", "輕", "緩", "穩" },
	LONELY = { "孤獨", "寂寞", "alone", "lonely", "空", "沉", "冷", "沒有人" },
	HOPE   = { "希望", "期待", "wish", "hope", "夢", "光", "好", "加油" },
	CHAOS  = { "混亂", "迷茫", "lost", "confused", "亂", "不安", "煩", "怎麼" },
}

Constants.MOOD_DISPLAY = {
	CALM   = "平靜",
	LONELY = "孤獨",
	HOPE   = "希望",
	CHAOS  = "混亂",
}

-- ============================================================
-- POSTCARD SENTENCE LIBRARY
-- Fixed set — no free input for safety & tone control
-- ============================================================
Constants.POSTCARDS = {
	"今晚的風很安靜。",
	"這裡似乎剛下過雨。",
	"遠處有什麼在發光。",
	"我在這裡，你也是嗎。",
	"草原記住了你的樣子。",
	"霧散了，但某些事仍然模糊。",
	"這片湖，比昨天更深了。",
	"夜裡，花開得很輕。",
	"有什麼離開了，但留下了形狀。",
	"你的世界，很安靜。",
	"天空今晚是深藍色的。",
	"風把某個聲音帶走了。",
}

-- ============================================================
-- WORLD STATE DEFAULTS & TUNING
-- Scale: 0 - 100 for each axis
-- ============================================================
Constants.WORLD = {
	-- Default starting values
	DEFAULT_RAIN     = 20,
	DEFAULT_BLOOM    = 15,
	DEFAULT_DARKNESS = 30,
	DEFAULT_LAKE     = 50,
	DEFAULT_WIND     = 40,

	-- Per-keyword nudge strength (small — change feels gradual)
	KEYWORD_WEIGHT = 2.5,

	-- Drift rate back toward baseline per diary submission (0-1)
	DRIFT_RATE = 0.015,

	-- Black hole timing
	BLACK_HOLE_INTERVAL_MIN = 120,
	BLACK_HOLE_INTERVAL_MAX = 360,
	BLACK_HOLE_DURATION     = 60,
}

-- ============================================================
-- REMOTE EVENT / FUNCTION NAMES
-- Single source of truth — prevents typo bugs
-- ============================================================
Constants.REMOTES = {
	-- Events (fire-and-forget)
	SUBMIT_DIARY      = "SubmitDiary",
	DIARY_RESPONSE    = "DiaryResponse",
	WORLD_STATE_UPDATE = "WorldStateUpdate",
	EGG_ACTIVATED     = "EggActivated",
	TRIGGER_BLACK_HOLE = "TriggerBlackHole",
	SEND_POSTCARD     = "SendPostcard",
	POSTCARD_RECEIVED = "PostcardReceived",

	-- Functions (request/response)
	GET_DIARY_HISTORY = "GetDiaryHistory",
	GET_WORLD_STATE   = "GetWorldState",
	GET_POSTCARDS     = "GetPostcards",
	CAN_WRITE_TODAY   = "CanWriteToday",
}

return Constants
