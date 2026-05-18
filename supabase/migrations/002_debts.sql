-- ============================================================
-- Finup - Migration 002: Cobranças (Debts/Split)
-- Execute no Supabase SQL Editor após a migration 001
-- ============================================================

CREATE TABLE IF NOT EXISTS debts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  person_name TEXT NOT NULL,
  description TEXT,
  total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount > 0),
  installments_count INT DEFAULT 1 NOT NULL CHECK (installments_count >= 1),
  paid_installments INT DEFAULT 0 NOT NULL CHECK (paid_installments >= 0),
  due_date DATE,
  type TEXT NOT NULL DEFAULT 'owed_to_me' CHECK (type IN ('owed_to_me', 'i_owe')),
  notes TEXT,
  is_completed BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT paid_lte_total CHECK (paid_installments <= installments_count)
);

CREATE INDEX idx_debts_user_id ON debts(user_id);
CREATE INDEX idx_debts_type ON debts(user_id, type);
CREATE INDEX idx_debts_completed ON debts(user_id, is_completed);

ALTER TABLE debts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "debts_user_policy" ON debts
  FOR ALL USING (auth.uid() = user_id);

CREATE TRIGGER update_debts_updated_at
  BEFORE UPDATE ON debts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
