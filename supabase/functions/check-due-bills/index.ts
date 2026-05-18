import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

interface FixedBill {
  id: string
  user_id: string
  name: string
  amount: number
  day_of_month: number
  reminder_days_before: number
  whatsapp_reminder: boolean
}

interface NotificationSettings {
  user_id: string
  whatsapp_number: string
  whatsapp_enabled: boolean
  bill_reminder: boolean
  daily_summary: boolean
  weekly_summary: boolean
  budget_alert: boolean
}

function formatCurrency(value: number): string {
  return value.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}

function nextDueDate(dayOfMonth: number, from: Date): Date {
  const candidate = new Date(from.getFullYear(), from.getMonth(), dayOfMonth)
  if (candidate <= from) {
    candidate.setMonth(candidate.getMonth() + 1)
  }
  return candidate
}

async function sendWhatsapp(to: string, message: string): Promise<void> {
  const res = await supabase.functions.invoke('send-whatsapp', {
    body: { to, message },
  })
  if (res.error) throw res.error
}

async function checkDueBills(): Promise<void> {
  const now = new Date()

  // Buscar contas fixas ativas com aviso WhatsApp habilitado
  const { data: bills, error: billsError } = await supabase
    .from('fixed_bills')
    .select('id, user_id, name, amount, day_of_month, reminder_days_before, whatsapp_reminder')
    .eq('is_active', true)
    .eq('whatsapp_reminder', true)

  if (billsError || !bills?.length) return

  // Buscar configurações de notificação dos usuários
  const userIds = [...new Set(bills.map((b: FixedBill) => b.user_id))]
  const { data: settings } = await supabase
    .from('notification_settings')
    .select('*')
    .in('user_id', userIds)
    .eq('whatsapp_enabled', true)
    .eq('bill_reminder', true)
    .not('whatsapp_number', 'is', null)

  if (!settings?.length) return

  const settingsByUser = new Map<string, NotificationSettings>(
    settings.map((s: NotificationSettings) => [s.user_id, s])
  )

  for (const bill of bills as FixedBill[]) {
    const userSettings = settingsByUser.get(bill.user_id)
    if (!userSettings) continue

    const due = nextDueDate(bill.day_of_month, now)
    const daysLeft = Math.floor((due.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))

    if (daysLeft <= bill.reminder_days_before && daysLeft >= 0) {
      const dueDateStr = due.toLocaleDateString('pt-BR')
      const message = daysLeft === 0
        ? `🔴 *AppFinance* - Conta vence HOJE!\n\n📄 *${bill.name}*\n💰 Valor: ${formatCurrency(bill.amount)}\n📅 Vencimento: ${dueDateStr}`
        : `⚠️ *AppFinance* - Conta a vencer\n\n📄 *${bill.name}*\n💰 Valor: ${formatCurrency(bill.amount)}\n📅 Vence em: ${daysLeft} dia${daysLeft > 1 ? 's' : ''} (${dueDateStr})`

      await sendWhatsapp(userSettings.whatsapp_number, message)
    }
  }
}

async function sendDailySummaries(): Promise<void> {
  const { data: settings } = await supabase
    .from('notification_settings')
    .select('user_id, whatsapp_number')
    .eq('whatsapp_enabled', true)
    .eq('daily_summary', true)
    .not('whatsapp_number', 'is', null)

  if (!settings?.length) return

  const now = new Date()
  const today = now.toISOString().split('T')[0]
  const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0]

  for (const { user_id, whatsapp_number } of settings) {
    const { data: txs } = await supabase
      .from('transactions')
      .select('amount, type')
      .eq('user_id', user_id)
      .eq('date', today)
      .eq('is_paid', true)
      .neq('type', 'transfer')

    if (!txs?.length) continue

    let income = 0
    let expense = 0
    for (const t of txs) {
      if (t.type === 'income') income += t.amount
      else expense += t.amount
    }

    const message = `📊 *AppFinance - Resumo de hoje (${new Date(today).toLocaleDateString('pt-BR')})*\n\n✅ Receitas: ${formatCurrency(income)}\n🔴 Despesas: ${formatCurrency(expense)}\n💰 Saldo do dia: ${formatCurrency(income - expense)}`

    await sendWhatsapp(whatsapp_number, message)
  }
}

async function sendWeeklySummaries(): Promise<void> {
  const now = new Date()
  if (now.getDay() !== 1) return // só segunda-feira

  const { data: settings } = await supabase
    .from('notification_settings')
    .select('user_id, whatsapp_number')
    .eq('whatsapp_enabled', true)
    .eq('weekly_summary', true)
    .not('whatsapp_number', 'is', null)

  if (!settings?.length) return

  const weekStart = new Date(now)
  weekStart.setDate(now.getDate() - 7)

  for (const { user_id, whatsapp_number } of settings) {
    const { data: txs } = await supabase
      .from('transactions')
      .select('amount, type')
      .eq('user_id', user_id)
      .gte('date', weekStart.toISOString().split('T')[0])
      .lte('date', now.toISOString().split('T')[0])
      .eq('is_paid', true)
      .neq('type', 'transfer')

    if (!txs?.length) continue

    let income = 0
    let expense = 0
    for (const t of txs) {
      if (t.type === 'income') income += t.amount
      else expense += t.amount
    }

    const message = `📈 *AppFinance - Resumo Semanal*\n\n✅ Receitas: ${formatCurrency(income)}\n🔴 Despesas: ${formatCurrency(expense)}\n💰 Saldo: ${formatCurrency(income - expense)}\n\nBoa semana! 💪`

    await sendWhatsapp(whatsapp_number, message)
  }
}

serve(async (req) => {
  try {
    await Promise.all([
      checkDueBills(),
      sendDailySummaries(),
      sendWeeklySummaries(),
    ])

    return new Response(JSON.stringify({ success: true, timestamp: new Date().toISOString() }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('check-due-bills error:', err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

// Para agendar via pg_cron (rode no SQL Editor do Supabase):
// SELECT cron.schedule('check-due-bills', '0 8 * * *', $$
//   SELECT net.http_post(
//     url := 'https://SEU_PROJECT_ID.supabase.co/functions/v1/check-due-bills',
//     headers := '{"Authorization": "Bearer SUA_SERVICE_ROLE_KEY"}'::jsonb
//   );
// $$);
