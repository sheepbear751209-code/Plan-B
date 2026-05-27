# Plan-B — 問卷調查網頁

一個輕量靜態問卷，使用 **Formspree** 收集回應，可部署到 **GitHub Pages**（完全免費）。

---

## 📁 檔案結構

```
Plan-B/
├── index.html   # 問卷填寫頁（受填者看到的）
├── style.css    # 樣式
└── README.md    # 本說明
```

---

## 🚀 三步驟上線流程

### 步驟一：申請 Formspree（免費）

1. 前往 https://formspree.io 並註冊帳號
2. 點選 **+ New Form**，輸入名稱（如「Plan-B 問卷」）
3. 複製頁面上的 endpoint，格式類似：
   `https://formspree.io/f/abcd1234`

### 步驟二：填入 Formspree ID

開啟 `index.html`，找到這一行（約 JS 設定區）：

```js
const FORMSPREE_ENDPOINT = 'https://formspree.io/f/YOUR_FORM_ID';
```

把 `YOUR_FORM_ID` 換成你剛剛複製的 ID，例如：

```js
const FORMSPREE_ENDPOINT = 'https://formspree.io/f/abcd1234';
```

存檔後推送（`git push`）即生效。

### 步驟三：啟用 GitHub Pages

1. 到 GitHub 倉庫頁面 → **Settings** → **Pages**
2. Source 選 **Deploy from a branch**
3. Branch 選 `main`（或你的主分支），目錄選 `/(root)`
4. 儲存後等約 1 分鐘，你的網址就會出現：
   `https://你的帳號.github.io/Plan-B/`

---

## 📊 查看填寫結果

| 方式 | 說明 |
|------|------|
| **Formspree 後台** | 登入 formspree.io，在「Submissions」頁籤看所有回覆 |
| **Email 通知** | 每次有人填寫，Formspree 會自動寄信到你的信箱 |
| **匯出 CSV** | 在後台可一鍵匯出 Excel/CSV 格式，方便統計 |

> **免費方案限制**：每月 50 筆提交，若需要更多可升級付費方案（$10/月起）。

---

## ✏️ 自訂問題

問卷題目都在 `index.html` 的 `<form>` 標籤內。常用的題型範例：

### 文字輸入
```html
<div class="question-block" data-required>
  <label>問題標題 <span class="required">*</span></label>
  <input type="text" name="欄位名稱" placeholder="提示文字" />
  <span class="error-msg">此欄位為必填</span>
</div>
```

### 單選題
```html
<div class="option-group">
  <label class="option-item">
    <input type="radio" name="q1" value="選項A" /> 選項 A
  </label>
  <label class="option-item">
    <input type="radio" name="q1" value="選項B" /> 選項 B
  </label>
</div>
```

### 多選題
```html
<label class="option-item">
  <input type="checkbox" name="q2" value="選項A" /> 選項 A
</label>
```

### 長文字
```html
<textarea name="comment" maxlength="500" placeholder="請輸入…"></textarea>
```

---

## 💡 小技巧

- `data-required` 屬性加在 `.question-block` 上，該題就會在前端驗證
- 評分量尺分數（1–5）可在 JS 裡修改陣列 `[1, 2, 3, 4, 5]` 擴充範圍
- 若希望問卷有截止日期，可在 JS submit 前加日期判斷
