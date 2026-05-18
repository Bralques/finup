-- ============================================================
-- AppFinance - Schema inicial
-- Execute no Supabase SQL Editor:
-- https://supabase.com → seu projeto → SQL Editor
-- ============================================================

-- Habilitar extensão UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- ACCOUNTS (Contas bancárias, cartões, carteiras)
-- ============================================================
CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('checking', 'savings', 'credit_card', 'wallet')),
  balance DECIMAL(12,2) DEFAULT 0 NOT NULL,
  currency TEXT DEFAULT 'BRL' NOT NULL,
  color TEXT DEFAULT '#1E88E5',
  icon TEXT,
  is_active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "accounts_user_policy" ON accounts
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- INCOME_SOURCES (Fontes de renda)
-- ============================================================
CREATE TABLE IF NOT EXISTS income_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('salary', 'freelance', 'rental', 'investment', 'other')),
  expected_amount DECIMAL(12,2),
  day_of_month INT CHECK (day_of_month BETWEEN 1 AND 31),
  is_active BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE income_sources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "income_sources_user_policy" ON income_sources
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- CATEGORIES (Categorias de receita/despesa)
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  icon TEXT DEFAULT 'category',
  color TEXT DEFAULT '#1E88E5',
  parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "categories_user_policy" ON categories
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- TRANSACTIONS (Transações: receitas, despesas, transferências)
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  account_id UUID REFERENCES accounts(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  income_source_id UUID REFERENCES income_sources(id) ON DELETE SET NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  description TEXT,
  date DATE NOT NULL,
  is_paid BOOLEAN DEFAULT true NOT NULL,
  -- Recorrência
  recurrence TEXT DEFAULT 'none' CHECK (recurrence IN ('none','daily','weekly','monthly','yearly')),
  recurrence_end_date DATE,
  recurrence_group_id UUID,
  -- Parcelamento
  installment_group_id UUID,
  installment_number INT,
  total_installments INT,
  -- Transferência
  transfer_account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
  -- Conta fixa origem
  fixed_bill_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_transactions_user_date ON transactions(user_id, date DESC);
CREATE INDEX idx_transactions_account ON transactions(account_id);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_transactions_installment_group ON transactions(installment_group_id);
CREATE INDEX idx_transactions_recurrence_group ON transactions(recurrence_group_id);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "transactions_user_policy" ON transactions
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- FIXED_BILLS (Contas fixas: aluguel, Netflix, academia...)
-- ============================================================
CREATE TABLE IF NOT EXISTS fixed_bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  day_of_month INT NOT NULL CHECK (day_of_month BETWEEN 1 AND 31),
  start_date DATE NOT NULL,
  end_date DATE,
  recurrence TEXT DEFAULT 'monthly' CHECK (recurrence IN ('monthly', 'yearly')),
  is_active BOOLEAN DEFAULT true NOT NULL,
  reminder_days_before INT DEFAULT 3,
  whatsapp_reminder BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE fixed_bills ENABLE ROW LEVEL SECURITY;
CREATE POLICY "fixed_bills_user_policy" ON fixed_bills
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- EXPENSE_DIARY (Diário de gastos - uma entrada por dia)
-- ============================================================
CREATE TABLE IF NOT EXISTS expense_diary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  note TEXT,
  mood TEXT CHECK (mood IN ('great', 'good', 'neutral', 'bad', 'terrible')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(user_id, date)
);

ALTER TABLE expense_diary ENABLE ROW LEVEL SECURITY;
CREATE POLICY "expense_diary_user_policy" ON expense_diary
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- BUDGETS (Orçamentos mensais por categoria)
-- ============================================================
CREATE TABLE IF NOT EXISTS budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE NOT NULL,
  month INT NOT NULL CHECK (month BETWEEN 1 AND 12),
  year INT NOT NULL CHECK (year >= 2000),
  amount_limit DECIMAL(12,2) NOT NULL CHECK (amount_limit > 0),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(user_id, category_id, month, year)
);

ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "budgets_user_policy" ON budgets
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- GOALS (Metas financeiras)
-- ============================================================
CREATE TABLE IF NOT EXISTS goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  target_amount DECIMAL(12,2) NOT NULL CHECK (target_amount > 0),
  current_amount DECIMAL(12,2) DEFAULT 0 NOT NULL,
  deadline DATE,
  color TEXT DEFAULT '#1E88E5',
  icon TEXT DEFAULT 'flag',
  is_completed BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "goals_user_policy" ON goals
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- NOTIFICATION_SETTINGS (Configuração de notificações WhatsApp)
-- ============================================================
CREATE TABLE IF NOT EXISTS notification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  whatsapp_number TEXT,
  whatsapp_enabled BOOLEAN DEFAULT false NOT NULL,
  daily_summary BOOLEAN DEFAULT false NOT NULL,
  weekly_summary BOOLEAN DEFAULT false NOT NULL,
  bill_reminder BOOLEAN DEFAULT true NOT NULL,
  budget_alert BOOLEAN DEFAULT true NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notification_settings_user_policy" ON notification_settings
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- FUNÇÃO: Atualizar updated_at automaticamente
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_accounts_updated_at
  BEFORE UPDATE ON accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_transactions_updated_at
  BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_fixed_bills_updated_at
  BEFORE UPDATE ON fixed_bills FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_expense_diary_updated_at
  BEFORE UPDATE ON expense_diary FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_goals_updated_at
  BEFORE UPDATE ON goals FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_notification_settings_updated_at
  BEFORE UPDATE ON notification_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();
