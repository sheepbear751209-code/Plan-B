-- ============================================================
-- Plan-B 問卷系統 — Supabase 資料庫初始化 SQL
-- 請在 Supabase 控制台的「SQL Editor」中一次執行此完整檔案
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- 1. submissions：儲存 C 端每一筆問卷回應
-- ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS submissions (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  submitted_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- 問卷欄位
  name          TEXT        NOT NULL,
  email         TEXT        NOT NULL,
  phone         TEXT,
  source        TEXT,
  interests     TEXT,                          -- 多選，以「、」分隔
  satisfaction  SMALLINT    CHECK (satisfaction BETWEEN 1 AND 5),
  suggestion    TEXT,

  -- B 端處理欄位
  status        TEXT NOT NULL DEFAULT '新進'
                CHECK (status IN ('新進', '處理中', '已結案')),
  internal_note TEXT                           -- 內部備註，填寫者看不到
);

-- ──────────────────────────────────────────────────────────
-- 2. case_records：結案紀錄（不可修改的永久記錄）
--    包含問卷快照：即使原始 submission 被更改，結案紀錄仍保有
--    結案當下的完整問卷內容，供日後回溯。
-- ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS case_records (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id         UUID        NOT NULL REFERENCES submissions(id),

  -- 結案資訊
  closed_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  handler_name          TEXT        NOT NULL,   -- 處理人員（手動填寫）
  handling_result       TEXT        NOT NULL,   -- 處理結果
  case_summary          TEXT        NOT NULL,   -- 案件摘要

  -- 問卷內容快照（結案當下的副本，永久保存）
  snapshot_name         TEXT        NOT NULL,
  snapshot_email        TEXT        NOT NULL,
  snapshot_phone        TEXT,
  snapshot_source       TEXT,
  snapshot_interests    TEXT,
  snapshot_satisfaction SMALLINT    CHECK (snapshot_satisfaction BETWEEN 1 AND 5),
  snapshot_suggestion   TEXT,
  snapshot_submitted_at TIMESTAMPTZ NOT NULL
);

-- ──────────────────────────────────────────────────────────
-- 3. 索引（加速常用查詢）
-- ──────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_submissions_status
  ON submissions(status);

CREATE INDEX IF NOT EXISTS idx_submissions_submitted_at
  ON submissions(submitted_at DESC);

CREATE INDEX IF NOT EXISTS idx_case_records_submission_id
  ON case_records(submission_id);

CREATE INDEX IF NOT EXISTS idx_case_records_closed_at
  ON case_records(closed_at DESC);

-- ──────────────────────────────────────────────────────────
-- 4. 啟用 Row Level Security（資料安全核心）
-- ──────────────────────────────────────────────────────────
ALTER TABLE submissions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_records ENABLE ROW LEVEL SECURITY;

-- ──────────────────────────────────────────────────────────
-- 5. RLS 政策
--    anon（任何人，C 端）：只能 INSERT submissions
--    authenticated（登入的 B 端人員）：可讀取與管理所有資料
-- ──────────────────────────────────────────────────────────

-- C 端：公開填寫
CREATE POLICY "anon_insert_submissions"
  ON submissions FOR INSERT
  TO anon
  WITH CHECK (true);

-- B 端：讀取所有回應
CREATE POLICY "auth_select_submissions"
  ON submissions FOR SELECT
  TO authenticated
  USING (true);

-- B 端：更新狀態與備註
CREATE POLICY "auth_update_submissions"
  ON submissions FOR UPDATE
  TO authenticated
  USING (true) WITH CHECK (true);

-- B 端：新增結案紀錄
CREATE POLICY "auth_insert_case_records"
  ON case_records FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- B 端：讀取結案紀錄
CREATE POLICY "auth_select_case_records"
  ON case_records FOR SELECT
  TO authenticated
  USING (true);

-- ──────────────────────────────────────────────────────────
-- 6. 觸發器：插入 case_records 時自動將對應 submission 標記「已結案」
--    保證原子性：即使前端 JS 發生錯誤，資料庫層面仍維持一致
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_auto_close_submission()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE submissions
  SET status = '已結案'
  WHERE id = NEW.submission_id;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_auto_close_submission
  AFTER INSERT ON case_records
  FOR EACH ROW
  EXECUTE FUNCTION fn_auto_close_submission();

-- ──────────────────────────────────────────────────────────
-- 7. duty_roster：5 個值班番號的人員設定
-- ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS duty_roster (
  shift_number  SMALLINT PRIMARY KEY CHECK (shift_number BETWEEN 1 AND 5),
  name          TEXT NOT NULL DEFAULT '',
  phone         TEXT NOT NULL DEFAULT ''
);

-- 初始化 5 個番號（若已存在則不更動）
INSERT INTO duty_roster (shift_number, name, phone)
VALUES (1,'',''), (2,'',''), (3,'',''), (4,'',''), (5,'','')
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────
-- 8. shift_calendar：每日值班番號排班
-- ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS shift_calendar (
  date          DATE PRIMARY KEY,
  shift_number  SMALLINT NOT NULL REFERENCES duty_roster(shift_number)
);

CREATE INDEX IF NOT EXISTS idx_shift_calendar_date
  ON shift_calendar(date DESC);

-- ──────────────────────────────────────────────────────────
-- 9. 新表的 RLS
-- ──────────────────────────────────────────────────────────
ALTER TABLE duty_roster    ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_calendar ENABLE ROW LEVEL SECURITY;

-- anon（C 端）可讀，查詢今日值班
CREATE POLICY "anon_select_duty_roster"
  ON duty_roster FOR SELECT TO anon USING (true);

CREATE POLICY "anon_select_shift_calendar"
  ON shift_calendar FOR SELECT TO anon USING (true);

-- B 端（登入後）可完整操作
CREATE POLICY "auth_all_duty_roster"
  ON duty_roster FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

CREATE POLICY "auth_all_shift_calendar"
  ON shift_calendar FOR ALL TO authenticated
  USING (true) WITH CHECK (true);

-- ============================================================
-- 完成！共 4 張資料表：submissions、case_records、
--        duty_roster、shift_calendar
-- ============================================================
