-- GameServer.server.lua  (Script — ServerScriptService)
-- Entry point for all server logic.
-- Wires RemoteEvents, delegates to Managers, runs the black hole loop.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DiaryManager      = require(script.Parent.Modules.DiaryManager)
local WorldStateManager = require(script.Parent.Modules.WorldStateManager)
local PostcardManager   = require(script.Parent.Modules.PostcardManager)
local BlackHoleManager  = require(script.Parent.Modules.BlackHoleManager)
local Constants         = require(ReplicatedStorage.Constants)

-- ============================================================
-- Build Remotes folder
-- ============================================================

local remotes = Instance.new("Folder")
remotes.Name   = "Remotes"
remotes.Parent = ReplicatedStorage

local function makeEvent(name)
	local e = Instance.new("RemoteEvent")
	e.Name   = name
	e.Parent = remotes
	return e
end

local function makeFunction(name)
	local f = Instance.new("RemoteFunction")
	f.Name   = name
	f.Parent = remotes
	return f
end

local R = Constants.REMOTES

local submitDiary       = makeEvent(R.SUBMIT_DIARY)
local diaryResponse     = makeEvent(R.DIARY_RESPONSE)
local worldStateUpdate  = makeEvent(R.WORLD_STATE_UPDATE)
local eggActivated      = makeEvent(R.EGG_ACTIVATED)
local triggerBlackHole  = makeEvent(R.TRIGGER_BLACK_HOLE)
local sendPostcard      = makeEvent(R.SEND_POSTCARD)
local postcardReceived  = makeEvent(R.POSTCARD_RECEIVED)

local getDiaryHistory   = makeFunction(R.GET_DIARY_HISTORY)
local getWorldState     = makeFunction(R.GET_WORLD_STATE)
local getPostcards      = makeFunction(R.GET_POSTCARDS)
local canWriteToday     = makeFunction(R.CAN_WRITE_TODAY)

-- ============================================================
-- Diary
-- ============================================================

submitDiary.OnServerEvent:Connect(function(player, sentence)
	local uid = player.UserId
	local ok, result = DiaryManager.Submit(uid, sentence)

	if ok then
		-- Push world state change back to the player
		local newState = WorldStateManager.UpdateFromSentences(uid, { sentence })
		worldStateUpdate:FireClient(player, newState)
		diaryResponse:FireClient(player, { success = true, entry = result })

		-- Egg reacts
		eggActivated:FireClient(player, { mood = result.mood })

		-- Add this world state to anonymous showcase pool
		task.defer(function()
			WorldStateManager.AddToShowcase(newState)
		end)
	else
		diaryResponse:FireClient(player, { success = false, reason = result })
	end
end)

getDiaryHistory.OnServerInvoke = function(player, limit)
	return DiaryManager.History(player.UserId, limit or 15)
end

getWorldState.OnServerInvoke = function(player)
	return WorldStateManager.GetState(player.UserId)
end

getPostcards.OnServerInvoke = function(player)
	return PostcardManager.GetReceived(player.UserId)
end

canWriteToday.OnServerInvoke = function(player)
	return DiaryManager.TodayStatus(player.UserId)
end

-- ============================================================
-- Postcards
-- ============================================================

sendPostcard.OnServerEvent:Connect(function(player, sentenceIndex)
	local allPlayers = Players:GetPlayers()
	local targetId   = PostcardManager.PickTarget(player.UserId, allPlayers)

	if not targetId then return end -- no other players online; prototype: silently drop

	local ok = PostcardManager.Send(player.UserId, targetId, sentenceIndex)
	if not ok then return end

	-- Deliver instantly if target is online
	local target = Players:GetPlayerByUserId(targetId)
	if target then
		postcardReceived:FireClient(target, {
			sentence = Constants.POSTCARDS[sentenceIndex],
		})
	end
end)

-- ============================================================
-- Black Hole loop
-- ============================================================

-- Spawn above the centre of the map; adjust Y as needed in Studio
local BLACK_HOLE_SPAWN = Vector3.new(0, 60, 0)

task.spawn(function()
	while true do
		task.wait(30)
		if BlackHoleManager.ShouldSpawn() then
			local id, pos = BlackHoleManager.Spawn(BLACK_HOLE_SPAWN)
			triggerBlackHole:FireAllClients({ id = id, position = pos, active = true })

			task.delay(Constants.WORLD.BLACK_HOLE_DURATION, function()
				BlackHoleManager.Remove(id)
				triggerBlackHole:FireAllClients({ id = id, active = false })
			end)
		end
	end
end)

-- ============================================================
-- Player join
-- ============================================================

Players.PlayerAdded:Connect(function(player)
	-- Wait for character, then push initial world state
	player.CharacterAdded:Wait()
	task.wait(1)

	local state = WorldStateManager.GetState(player.UserId)
	worldStateUpdate:FireClient(player, state)

	-- Deliver oldest unread postcard if any
	local received = PostcardManager.GetReceived(player.UserId)
	if #received > 0 then
		local latest = received[#received]
		postcardReceived:FireClient(player, { sentence = latest.sentence })
	end
end)

print("[Neverland] Server ready.")
