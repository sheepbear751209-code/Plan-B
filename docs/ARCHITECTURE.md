# Neverland : After the Words — Prototype Architecture

> 透過文字留下情緒痕跡，世界會緩慢改變的夢境療癒遊戲

---

## 1. Explorer 結構（Roblox Studio）

```
Workspace
├── CompanionEgg          ← Part (球形，白色)
│   ├── PointLight
│   ├── ParticleEmitter   ← 星塵粒子
│   ├── ClickDetector
│   └── HumSound          ← Sound (低鳴音)
├── CompanionDeer         ← Rig (Humanoid，無武器)
│   ├── HumanoidRootPart
│   └── Humanoid
├── MemoryHouse           ← Part / Model (草原中的小屋)
│   └── ProximityPrompt   ← (由 DiaryUI.client.lua 建立)
├── PostcardMailbox       ← Part / Model
│   └── ProximityPrompt   ← (由 PostcardUI.client.lua 建立)
├── RainEffect            ← Part (天空層)
│   └── ParticleEmitter   ← Rate 由 GameClient 控制
├── LakeSurface           ← Part (水面平面)
├── RainChimeZone         ← Folder
│   ├── RainOrb_1         ← Part + Sound + ParticleEmitter
│   ├── RainOrb_2
│   └── ...（建議 5~7 顆，不同高度）
└── Terrain               ← 長夜草原、湖泊、遠方遺跡

ServerScriptService
├── GameServer.server.lua ← 唯一 Server Script
└── Modules               ← Folder
    ├── DiaryManager.lua
    ├── WorldStateManager.lua
    ├── PostcardManager.lua
    └── BlackHoleManager.lua

ReplicatedStorage
├── Constants.lua         ← ModuleScript (共用常數)
└── Remotes               ← Folder (由 GameServer 建立)
    ├── [RemoteEvents]
    └── [RemoteFunctions]

StarterPlayerScripts
├── GameClient.client.lua ← 主客戶端 LocalScript
├── DeerAI.lua            ← ModuleScript
├── EggController.lua     ← ModuleScript
└── MiniGames.lua         ← ModuleScript

StarterGui
├── DiaryUI
│   └── DiaryUI.client.lua    ← LocalScript
├── MemoryHouseUI
│   └── MemoryHouseUI.client.lua ← LocalScript
└── PostcardUI
    └── PostcardUI.client.lua ← LocalScript

Lighting
├── BloomEffect           ← 由 GameClient 控制 Intensity/Size
└── Atmosphere            ← 由 GameClient 控制 Haze
```

---

## 2. ModuleScript 職責表

| 模組 | 位置 | 職責 | 狀態 |
|------|------|------|------|
| `Constants` | ReplicatedStorage | 所有共用常數、關鍵詞表、句庫 | ✅ 完成 |
| `DiaryManager` | Server/Modules | DataStore 讀寫、日記驗證、心情分類 | ✅ 完成 |
| `WorldStateManager` | Server/Modules | 世界狀態讀寫、關鍵詞分析、showcase pool | ✅ 完成 |
| `PostcardManager` | Server/Modules | 匿名明信片收發、目標選擇 | ✅ 完成 |
| `BlackHoleManager` | Server/Modules | 黑洞計時、spawn、清除 | ✅ 完成 |
| `DeerAI` | StarterPlayerScripts | 鹿的狀態機（idle/follow/observe/sit） | ✅ 完成 |
| `EggController` | StarterPlayerScripts | 蛋的視覺反應（發光、晃動、顏色） | ✅ 完成 |
| `MiniGames` | StarterPlayerScripts | 雨聲風鈴 + 湖面漣漪 | ✅ 完成 |

---

## 3. 資料流設計

```
玩家輸入文字
    │
    ▼
DiaryUI.client.lua
    │  FireServer(sentence)
    ▼
GameServer.server.lua
    ├─► DiaryManager.Submit()   → DataStore 儲存
    ├─► WorldStateManager.UpdateFromSentences()  → DataStore 更新
    │       └─ 關鍵詞分析 → 調整 rain/bloom/darkness/lake/wind
    └─► WorldStateManager.AddToShowcase()  → showcase pool
    │
    │  FireClient(newState)     FireClient({ success, entry })
    ▼                            ▼
GameClient.client.lua          DiaryUI.client.lua
    │  applyWorldState()            │  showStatus()
    ▼                               ▼
Lighting / Rain / Bloom         更新今日句子列表
    │
    ▼
EggController.OnWordReceived()  ← eggActivated event
DeerAI.OnWordSubmitted()
```

---

## 4. DataStore 結構

### NeverlandDiary_v1

```
Key: "Player_{userId}"
{
  entries = [
    {
      date      = "2026-05-17",   -- YYYY-MM-DD
      sentences = ["今天風很大。", "..."],
      mood      = "CALM"          -- CALM | LONELY | HOPE | CHAOS
    },
    ...  -- newest first, free tier keeps ~30 entries
  ],
  lastEntryDate = "2026-05-17",
  totalEntries  = 12,
  isPremium     = false
}
```

### NeverlandWorld_v1

```
Key: "WorldState_{userId}"
{
  rain      = 42,   -- 0~100
  bloom     = 28,
  darkness  = 35,
  lake      = 55,
  wind      = 48,
  updatedAt = 1747440000
}

Key: "Showcase_Pool_v1"
[
  { state = { rain=42, bloom=28, ... }, at = 1747440000 },
  ...  -- max 20 entries, FIFO
]
```

### NeverlandPostcards_v1

```
Key: "Received_{userId}"
[
  {
    sentence   = "今晚的風很安靜。",
    receivedAt = 1747440000
    -- 無寄送者資訊 (匿名設計)
  },
  ...  -- max 12 entries
]
```

---

## 5. Prototype 開發順序

```
Week 1  核心迴圈驗證
  [1] GameServer + Constants + DiaryManager
      → 可以寫字、存 DataStore
  [2] DiaryUI（最基本的輸入介面）
      → 驗證玩家願意留字

Week 2  世界回應 + 情感連結
  [3] WorldStateManager + GameClient applyWorldState
      → Lighting 隨文字改變
  [4] EggController（發光、晃動）
      → 驗證玩家感覺生命在回應

Week 3  陪伴 + 記憶
  [5] DeerAI
      → 驗證玩家對小鹿產生情感
  [6] MemoryHouseUI
      → 驗證玩家願意回顧自己的文字

Week 4  社交 + 付費意願測試
  [7] PostcardManager + PostcardUI
  [8] BlackHoleManager + 黑洞視覺
  [9] MiniGames（雨聲風鈴 + 湖面漣漪）
 [10] 付費觀測站（只需假資料UI，驗證付費意願）
```

---

## 6. 最小可運行 MVP（Day 1 可測試）

只需這些運作：

1. `Constants.lua`
2. `DiaryManager.lua`
3. `GameServer.server.lua`（只開 submitDiary / canWriteToday）
4. `DiaryUI.client.lua`（只要輸入框 + 送出按鈕）
5. 一個 `CompanionEgg` Part 在 Workspace

玩家能：輸入文字 → 存入 DataStore → 蛋發光

這已經可以驗證：**玩家是否願意留下短句**。

---

## 7. 建議先用假資料的功能

| 功能 | 假資料策略 |
|------|-----------|
| 黑洞進入後的「其他世界」 | 顯示一個靜態的假世界畫面（一張截圖）即可驗證意願 |
| 展示黑洞的 showcase pool | 用本地假資料 `{ rain=60, bloom=30, ... }` 代替 |
| 明信片接收（單人測試） | 進遊戲時直接 FireClient 一張假明信片 |
| 付費觀測站 UI | 做出介面 + 假資料時間軸，不接真實付費，只問「你願意付費嗎」 |
| 世界縮時相冊 | 用幾張固定截圖模擬，不需要真實錄製 |

---

## 8. Roblox 平台限制與注意事項

### DataStore
- **請求限制**：每個 key 每分鐘最多 6 次讀/寫。目前架構每次送字最多 2 次寫入（diary + world）→ 安全。
- **大小限制**：每個 key 最多 4MB。日記條目需設上限（已做 30 條）。
- **錯誤處理**：所有 DataStore 操作都已 pcall 包裹，save 失敗不會讓玩家卡住。

### RemoteEvents 安全
- 伺服器**永遠要重新驗證** client 送來的資料（DiaryManager.Submit 有做）。
- 玩家可以偽造 sentenceIndex → PostcardManager 做了範圍檢查。
- 不要在 client 做任何影響 DataStore 的決定。

### TextBox 過濾
- Roblox 的 Chat 過濾不會自動套用到 TextBox。
- **Prototype 階段**：字數限制（10~80字）已大幅降低風險。
- **正式版需要**：使用 `TextService:FilterStringAsync()` 對每句話進行過濾，否則違反 Roblox ToS。

### 中文輸入
- Roblox 的 TextBox 在 PC 支援中文輸入法（IME），但手機端行為可能不同。
- 建議 Prototype 優先在 PC 測試中文輸入。

### 動畫
- DeerAI 目前只控制移動和 CFrame，**實際動畫（走路、坐下）需要在 Studio 設定 AnimationController 並上傳動畫**。
- Prototype 階段沒有動畫仍可測試 AI 邏輯。

### 玩家隱私
- 不儲存任何玩家名稱、ID 在 showcase 或 postcard 中（已實作）。
- 符合 COPPA / GDPR 的最基本原則。

---

## 9. 適合接入 AI 的位置

| 位置 | AI 應用 | 技術 |
|------|---------|------|
| `WorldStateManager.UpdateFromSentences` | 用語意理解替換關鍵詞比對，更準確理解「想說的事」 | Anthropic API / Embeddings |
| 心情分類 `classifyMood` | 情感分析（正/負/中性 → 四種 mood） | Claude API 一次分類 |
| 世界敘事生成 | 每週產生一段「世界說的話」，基於玩家文字風格 | Claude API prompt |
| 記憶居所 AI 摘要 | 「這個月你說了很多關於風的事」 | Summarization |
| 陪伴生物對話 | 長久沉默時，生物「說」一句話（從玩家文字中提取） | Claude API + 句庫 |

**接入原則**：
- AI 呼叫只在伺服器端（永遠不在 client 端暴露 API key）。
- Prototype 不需要 AI，驗證情感機制後再加。

---

## 10. 防止過度工程化備忘

- **不要做** 玩家 HUD、等級條、數值面板。
- **不要做** 多語言系統（Prototype 只做中文）。
- **不要做** 複雜 OOP 繼承（目前 Module 已夠用）。
- **不要做** 自動化測試框架（手測 + print() 足夠）。
- **不要做** CI/CD pipeline（直接發布到 Roblox Studio）。
- **先讓玩家哭，再談技術**。

---

## Studio 快速設置清單

```
□ 將 src/ 下的腳本複製到對應 Roblox Explorer 位置
□ 在 Workspace 放置 CompanionEgg (Part, 球形, 白色, Size 2x2x2)
□ 在 CompanionEgg 加入 PointLight + ParticleEmitter + Sound (HumSound)
□ 在 Workspace 放置 CompanionDeer (R15 Rig 或簡單 Model)
□ 在 Workspace 放置 MemoryHouse + PostcardMailbox (任意 Part)
□ 在 Workspace 放置 LakeSurface (平面 Part，水面高度)
□ 在 Workspace 放置 RainEffect + ParticleEmitter (Rate=0 初始)
□ 建立 RainChimeZone Folder，放入 5 顆 Part，各加 Sound
□ Lighting 加入 BloomEffect (Intensity=0.3, Size=24)
□ Lighting 加入 Atmosphere (Haze=0.01)
□ 測試：進遊戲 → 輸入文字 → DataStore 儲存 → Lighting 改變
```
