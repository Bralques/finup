-- ============================================================
-- Finup - Migration 004: Configurações do Bot de Lançamentos
-- Execute no Supabase SQL Editor após a migration 003
-- ============================================================

-- Adicionar campos de bot nas notification_settings
ALTER TABLE notification_settings
  ADD COLUMN IF NOT EXISTS telegram_chat_id TEXT,
  ADD COLUMN IF NOT EXISTS default_account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;

-- Índice para lookup rápido por chat_id (telegram)
CREATE UNIQUE INDEX IF NOT EXISTS idx_notif_telegram_chat_id
  ON notification_settings(telegram_chat_id)
  WHERE telegram_chat_id IS NOT NULL;

-- Índice para lookup por whatsapp_number (bot incoming)
CREATE UNIQUE INDEX IF NOT EXISTS idx_notif_whatsapp_number
  ON notification_settings(whatsapp_number)
  WHERE whatsapp_number IS NOT NULL;

-- View para facilitar lookup do bot (evita N queries)
CREATE OR REPLACE VIEW bot_user_context AS
SELECT
  ns.user_id,
  ns.telegram_chat_id,
  ns.whatsapp_number,
  ns.whatsapp_enabled,
  a.id          AS default_account_id,
  a.name        AS default_account_name,
  a.balance     AS default_account_balance,
  a.currency
FROM notification_settings ns
LEFT JOIN accounts a ON a.id = ns.default_account_id AND a.is_active = true;
