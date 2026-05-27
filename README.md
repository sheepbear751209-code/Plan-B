# Plan-B — 問卷調查系統

C / B 雙端問卷系統：公開填寫（C 端） + 內部管理後台（B 端）。
使用 **Supabase**（免費雲端資料庫 + 帳號系統）+ **GitHub Pages** 部署，完全免費。

---

## 📁 檔案結構

```
Plan-B/
├── index.html          # C 端：公開問卷填寫頁
├── style.css           # C 端樣式
├── admin.html          # B 端：內部管理後台
├── admin.css           # B 端樣式
├── supabase-setup.sql  # 資料庫初始化 SQL（只需執行一次）
└── README.md           # 本說明
```

---

## 🚀 完整設定流程（約 15 分鐘）

### 步驟一：建立 Supabase 專案

1. 前往 https://supabase.com 免費註冊
2. 點 **New project**，填入名稱與資料庫密碼（記住密碼）
3. 等待專案建立完成（約 1–2 分鐘）

### 步驟二：建立資料庫結構

1. 在 Supabase 控制台左側點選 **SQL Editor**
2. 點 **New query**
3. 複製 `supabase-setup.sql` 全部內容貼上，點 **Run**
4. 確認左側 Table Editor 出現 `submissions` 和 `case_records` 兩張表

### 步驟三：取得 API 金鑰

1. 左側點 **Settings → API**
2. 複製 **Project URL**（格式：`https://xxxx.supabase.co`）
3. 複製 **anon public** key（這個 key 可以公開，由 RLS 控制安全性）

### 步驟四：填入設定值

**C 端（index.html）** — 找到設定區：
```js
const SUPABASE_URL      = 'https://YOUR_PROJECT.supabase.co';  // ← 換成你的
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';                      // ← 換成你的
```

**B 端（admin.html）** — 同樣找到設定區填入相同的值。

### 步驟五：新增 B 端內部人員帳號

1. Supabase 控制台左側 → **Authentication → Users**
2. 點 **Invite user** 或 **Add user**
3. 輸入每位內部人員的 Email 與初始密碼（共 3–5 人）
4. 人員用此 Email + 密碼登入 `admin.html`

### 步驟六：啟用 GitHub Pages

1. GitHub 倉庫 → **Settings → Pages**
2. Source 選 `Deploy from a branch`，Branch 選 `main`，目錄 `/(root)`
3. 儲存後約 1 分鐘出現網址：
   - C 端：`https://你的帳號.github.io/Plan-B/`
   - B 端：`https://你的帳號.github.io/Plan-B/admin.html`（只分享給內部人員）

---

## 📊 B 端功能說明

| 功能 | 說明 |
|------|------|
| **登入** | Email + 密碼，僅限在 Supabase 建立的帳號 |
| **回應管理** | 查看所有問卷回應，可依狀態篩選、搜尋 |
| **狀態標記** | 新進 → 處理中（可在詳情頁下拉選單切換） |
| **內部備註** | 對每筆回應新增備註，填寫者看不到 |
| **結案** | 點「結案」按鈕，填入處理人員、處理結果、案件摘要後確認 |
| **結案紀錄** | 永久保存的結案記錄，含問卷原始內容快照 |
| **匯出 CSV** | 在「結案紀錄」頁一鍵匯出，可用 Excel 開啟 |
| **即時刷新** | 多位成員同時操作時，列表自動更新 |

---

## ✏️ 自訂問卷題目

問卷題目在 `index.html` 的 `<form>` 區塊內。

新增題目後，需同步在以下兩處更新欄位名稱：
1. `supabase-setup.sql` 的 `submissions` 資料表（新增欄位）
2. `index.html` 的 submit handler `payload` 物件
3. `admin.html` 的 `openDetail()` 函式（顯示新欄位）
4. `admin.html` 的 `confirmCloseCase()` 中的 `snapshot_*` 欄位

---

## 💡 注意事項

- **Supabase 免費方案**：閒置 7 天後專案會暫停，需登入一次喚醒；或升級 $25/月 Pro 方案關閉此機制
- **ANON KEY 是安全的**：可以放在前端程式碼，Supabase RLS 確保匿名用戶只能新增問卷，無法讀取或修改任何資料
- **不要暴露 service_role key**：這個 key 有最高權限，永遠不要放進任何 HTML / JS 檔案
