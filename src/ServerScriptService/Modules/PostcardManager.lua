-- PostcardManager.lua  (ModuleScript — ServerScriptService/Modules)
-- Anonymous fixed-sentence postcard delivery.
-- Sender identity is never stored — only the sentence and receive time.

local DataStoreService = game:GetService("DataStoreService")
local Constants        = require(game.ReplicatedStorage.Constants)

local PostcardManager = {}

local store        = DataStoreService:GetDataStore("NeverlandPostcards_v1")
local MAX_RECEIVED = 12

-- ============================================================
-- Internal
-- ============================================================

local function loadReceived(userId)
	local ok, data = pcall(function()
		return store:GetAsync("Received_" .. userId)
	end)
	return (ok and data) or {}
end

local function saveReceived(userId, list)
	pcall(function()
		store:SetAsync("Received_" .. userId, list)
	end)
end

-- ============================================================
-- Public API
-- ============================================================

function PostcardManager.GetReceived(userId)
	return loadReceived(userId)
end

-- sentenceIndex → index into Constants.POSTCARDS
-- Returns ok (bool), error string
function PostcardManager.Send(fromUserId, toUserId, sentenceIndex)
	local sentences = Constants.POSTCARDS
	if type(sentenceIndex) ~= "number"
		or sentenceIndex < 1
		or sentenceIndex > #sentences
	then
		return false, "invalid_sentence"
	end

	if fromUserId == toUserId then return false, "self_send" end

	local received = loadReceived(toUserId)

	-- Cap storage
	if #received >= MAX_RECEIVED then
		table.remove(received, 1)
	end

	table.insert(received, {
		sentence   = sentences[sentenceIndex],
		receivedAt = os.time(),
		-- No sender field — deliberate
	})

	saveReceived(toUserId, received)
	return true
end

-- Pick a random online player excluding the sender.
-- onlinePlayers: array of Player objects
function PostcardManager.PickTarget(excludeUserId, onlinePlayers)
	local pool = {}
	for _, p in ipairs(onlinePlayers) do
		if p.UserId ~= excludeUserId then
			table.insert(pool, p.UserId)
		end
	end
	if #pool == 0 then return nil end
	return pool[math.random(1, #pool)]
end

return PostcardManager
