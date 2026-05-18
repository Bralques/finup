-- ============================================================
-- Finup - Migration 003: Dívidas Externas (Serasa, SPC, Protesto)
-- Execute no Supabase SQL Editor após a migration 002
-- ============================================================

CREATE TABLE IF NOT EXISTS external_debts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  creditor_name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'credit'
    CHECK (type IN ('credit','loan','financing','credit_card','utility','tax','protest','other')),
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active','negotiating','paid','disputed')),
  source TEXT NOT NULL DEFAULT 'serasa'
    CHECK (source IN ('serasa','spc','protest','bacen','other')),
  original_amount DECIMAL(12,2) NOT NULL CHECK (original_amount > 0),
  current_amount DECIMAL(12,2),           -- valor atualizado com juros/multa
  due_date DATE,                          -- data original de vencimento
  negativated_at DATE,                    -- data em que foi negativado
  contract_number TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_external_debts_user_id ON external_debts(user_id);
CREATE INDEX idx_external_debts_status  ON external_debts(user_id, status);
CREATE INDEX idx_external_debts_source  ON external_debts(user_id, source);

ALTER TABLE external_debts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "external_debts_user_policy" ON external_debts
  FOR ALL USING (auth.uid() = user_id);

CREATE TRIGGER update_external_debts_updated_at
  BEFORE UPDATE ON external_debts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
