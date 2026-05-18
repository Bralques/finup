import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const AI_PROVIDER    = Deno.env.get('AI_PROVIDER') ?? 'grok'
const XAI_API_KEY    = Deno.env.get('XAI_API_KEY') ?? ''
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? ''
const GROQ_API_KEY   = Deno.env.get('GROQ_API_KEY') ?? ''
const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY') ?? ''

// ── Tipos ─────────────────────────────────────────────────────

interface MonthSummary {
  month: string      // "2026-05"
  income: number
  expense: number
  balance: number
}

interface CategorySpend {
  name: string
  total: number
  budget_limit: number | null
  over_budget: boolean
}

interface GoalStatus {
  name: string
  target: number
  current: number
  progress: number    // 0-1
  days_left: number | null
  monthly_needed: number | null
}

export interface FinancialAnalysis {
  score: number                    // 0-10 saúde financeira geral
  score_label: string              // "Crítica" | "Preocupante" | "Regular" | "Boa" | "Excelente"
  summary: string                  // parágrafo resumo
  positives: string[]              // pontos positivos
  alerts: string[]                 // alertas e riscos
  recommendations: string[]        // ações práticas (máx 5)
  goals_outlook: string            // perspectiva para as metas
  savings_rate: number             // % da renda poupada
  trend: 'improving' | 'stable' | 'worsening'
  trend_label: string
  generated_at: string
}

// ── Coleta dados financeiros do usuário ───────────────────────

async function collectUserData(userId: string) {
  const now = new Date()
  const threeMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 3, 1)
  const from = threeMonthsAgo.toISOString().split('T')[0]

  // Contas e saldo total
  const { data: accounts } = await supabase
    .from('accounts')
    .select('name, type, balance')
    .eq('user_id', userId)
    .eq('is_active', true)

  // Transações dos últimos 3 meses
  const { data: transactions } = await supabase
    .from('transactions')
    .select('amount, type, date, category_id')
    .eq('user_id', userId)
    .gte('date', from)
    .eq('is_paid', true)
    .neq('type', 'transfer')
    .order('date')

  // Categorias
  const { data: categories } = await supabase
    .from('categories')
    .select('id, name, type')
    .eq('user_id', userId)

  // Orçamentos do mês atual
  const { data: budgets } = await supabase
    .from('budgets')
    .select('category_id, amount_limit')
    .eq('user_id', userId)
    .eq('month', now.getMonth() + 1)
    .eq('year', now.getFullYear())

  // Metas
  const { data: goals } = await supabase
    .from('goals')
    .select('name, target_amount, current_amount, deadline')
    .eq('user_id', userId)
    .eq('is_completed', false)

  // Dívidas externas abertas
  const { data: externalDebts } = await supabase
    .from('external_debts')
    .select('creditor_name, current_amount, original_amount')
    .eq('user_id', userId)
    .neq('status', 'paid')

  // Cobranças (quem me deve)
  const { data: debtsOwed } = await supabase
    .from('debts')
    .select('total_amount, paid_installments, installments_count')
    .eq('user_id', userId)
    .eq('type', 'owed_to_me')
    .eq('is_completed', false)

  return { accounts, transactions, categories, budgets, goals, externalDebts, debtsOwed }
}

// ── Processa dados em formato para a IA ──────────────────────

function processData(data: Awaited<ReturnType<typeof collectUserData>>) {
  const { accounts, transactions, categories, budgets, goals, externalDebts, debtsOwed } = data

  // Saldo total (exceto cartão de crédito)
  const totalBalance = (accounts ?? [])
    .filter((a) => a.type !== 'credit_card')
    .reduce((s, a) => s + a.balance, 0)

  // Resumo por mês
  const monthMap = new Map<string, MonthSummary>()
  for (const t of transactions ?? []) {
    const month = t.date.slice(0, 7)
    if (!monthMap.has(month)) {
      monthMap.set(month, { month, income: 0, expense: 0, balance: 0 })
    }
    const m = monthMap.get(month)!
    if (t.type === 'income') m.income += t.amount
    else m.expense += t.amount
    m.balance = m.income - m.expense
  }
  const monthSummaries = Array.from(monthMap.values()).sort((a, b) => a.month.localeCompare(b.month))

  // Gasto por categoria (mês atual)
  const now = new Date()
  const currentMonth = now.toISOString().slice(0, 7)
  const catSpend = new Map<string, number>()
  for (const t of (transactions ?? []).filter((x) => x.date.startsWith(currentMonth) && x.type === 'expense')) {
    if (t.category_id) {
      catSpend.set(t.category_id, (catSpend.get(t.category_id) ?? 0) + t.amount)
    }
  }

  const budgetMap = new Map((budgets ?? []).map((b) => [b.category_id, b.amount_limit]))
  const catMap = new Map((categories ?? []).map((c) => [c.id, c.name]))

  const categoryBreakdown: CategorySpend[] = Array.from(catSpend.entries())
    .map(([id, total]) => ({
      name: catMap.get(id) ?? 'Outros',
      total,
      budget_limit: budgetMap.get(id) ?? null,
      over_budget: budgetMap.has(id) ? total > budgetMap.get(id)! : false,
    }))
    .sort((a, b) => b.total - a.total)
    .slice(0, 8)

  // Status das metas
  const goalsStatus: GoalStatus[] = (goals ?? []).map((g) => {
    const progress = g.target_amount > 0 ? g.current_amount / g.target_amount : 0
    const remaining = g.target_amount - g.current_amount
    let daysLeft: number | null = null
    let monthlyNeeded: number | null = null

    if (g.deadline) {
      const deadline = new Date(g.deadline)
      daysLeft = Math.max(0, Math.floor((deadline.getTime() - now.getTime()) / 86400000))
      const monthsLeft = daysLeft / 30
      monthlyNeeded = monthsLeft > 0 ? remaining / monthsLeft : remaining
    }

    return {
      name: g.name,
      target: g.target_amount,
      current: g.current_amount,
      progress,
      days_left: daysLeft,
      monthly_needed: monthlyNeeded,
    }
  })

  // Taxa de poupança (último mês completo)
  const lastMonth = monthSummaries.slice(-1)[0]
  const savingsRate = lastMonth && lastMonth.income > 0
    ? Math.max(0, (lastMonth.income - lastMonth.expense) / lastMonth.income)
    : 0

  // Total de dívidas externas
  const totalExternalDebt = (externalDebts ?? [])
    .reduce((s, d) => s + (d.current_amount ?? d.original_amount), 0)

  // Total que me devem
  const totalOwedToMe = (debtsOwed ?? [])
    .reduce((s, d) => {
      const installmentAmt = d.installments_count > 0 ? d.total_amount / d.installments_count : d.total_amount
      return s + (d.total_amount - installmentAmt * d.paid_installments)
    }, 0)

  return {
    totalBalance,
    monthSummaries,
    categoryBreakdown,
    goalsStatus,
    savingsRate,
    totalExternalDebt,
    totalOwedToMe,
  }
}

// ── Prompt para a IA ──────────────────────────────────────────

function buildPrompt(processed: ReturnType<typeof processData>): string {
  const {
    totalBalance, monthSummaries, categoryBreakdown,
    goalsStatus, savingsRate, totalExternalDebt, totalOwedToMe,
  } = processed

  const formatBRL = (v: number) => v.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
  const formatPct = (v: number) => `${(v * 100).toFixed(1)}%`

  const monthsText = monthSummaries.map((m) =>
    `  ${m.month}: receitas ${formatBRL(m.income)}, despesas ${formatBRL(m.expense)}, saldo ${formatBRL(m.balance)}`
  ).join('\n')

  const catsText = categoryBreakdown.map((c) =>
    `  ${c.name}: ${formatBRL(c.total)}${c.budget_limit ? ` (limite ${formatBRL(c.budget_limit)}${c.over_budget ? ' ⚠️ EXCEDIDO' : ''})` : ''}`
  ).join('\n')

  const goalsText = goalsStatus.map((g) =>
    `  ${g.name}: ${formatPct(g.progress)} concluído (${formatBRL(g.current)} / ${formatBRL(g.target)})` +
    (g.monthly_needed ? ` — precisa poupar ${formatBRL(g.monthly_needed)}/mês` : '') +
    (g.days_left !== null ? ` — ${g.days_left} dias restantes` : '')
  ).join('\n')

  return `Você é um consultor financeiro pessoal especializado em finanças pessoais brasileiras.

Analise os dados financeiros abaixo e gere uma análise completa e honesta em português brasileiro.

## DADOS FINANCEIROS

**Saldo total atual:** ${formatBRL(totalBalance)}
**Taxa de poupança (último mês):** ${formatPct(savingsRate)}
**Dívidas externas (Serasa/SPC):** ${totalExternalDebt > 0 ? formatBRL(totalExternalDebt) : 'Nenhuma'}
**Cobranças a receber:** ${totalOwedToMe > 0 ? formatBRL(totalOwedToMe) : 'Nenhuma'}

**Histórico mensal (últimos 3 meses):**
${monthsText || '  Sem dados'}

**Gastos por categoria (mês atual):**
${catsText || '  Sem dados'}

**Status das metas:**
${goalsText || '  Nenhuma meta cadastrada'}

---

Responda APENAS com JSON válido (sem markdown), seguindo exatamente este schema:
{
  "score": number (0 a 10, saúde financeira geral),
  "score_label": "Crítica" | "Preocupante" | "Regular" | "Boa" | "Excelente",
  "summary": "parágrafo de 2-3 frases resumindo a situação financeira atual",
  "positives": ["ponto positivo 1", "ponto positivo 2"],
  "alerts": ["alerta 1", "alerta 2"],
  "recommendations": ["ação concreta 1", "ação concreta 2", "ação concreta 3"],
  "goals_outlook": "análise de 1-2 frases sobre o progresso e viabilidade das metas",
  "savings_rate": number (taxa de poupança decimal),
  "trend": "improving" | "stable" | "worsening",
  "trend_label": "Melhorando" | "Estável" | "Piorando",
  "generated_at": "${new Date().toISOString()}"
}`
}

// ── Chamadas às IAs (mesma lógica do bot-parse) ───────────────

async function callAI(prompt: string): Promise<string> {
  switch (AI_PROVIDER) {
    case 'gemini': {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { maxOutputTokens: 1024, temperature: 0.3 },
        }),
      })
      if (!res.ok) throw new Error(`Gemini: ${await res.text()}`)
      const d = await res.json()
      return d.candidates[0].content.parts[0].text.trim()
    }

    case 'groq': {
      const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${GROQ_API_KEY}` },
        body: JSON.stringify({
          model: 'llama-3.3-70b-versatile',
          max_tokens: 1024,
          temperature: 0.3,
          messages: [{ role: 'user', content: prompt }],
        }),
      })
      if (!res.ok) throw new Error(`Groq: ${await res.text()}`)
      const d = await res.json()
      return d.choices[0].message.content.trim()
    }

    case 'anthropic': {
      const res = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-api-key': ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01' },
        body: JSON.stringify({ model: 'claude-haiku-4-5-20251001', max_tokens: 1024, messages: [{ role: 'user', content: prompt }] }),
      })
      if (!res.ok) throw new Error(`Anthropic: ${await res.text()}`)
      const d = await res.json()
      return d.content[0].text.trim()
    }

    default: {  // grok
      const res = await fetch('https://api.x.ai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${XAI_API_KEY}` },
        body: JSON.stringify({
          model: 'grok-3-mini',
          max_tokens: 1024,
          temperature: 0.3,
          messages: [{ role: 'user', content: prompt }],
        }),
      })
      if (!res.ok) throw new Error(`Grok: ${await res.text()}`)
      const d = await res.json()
      return d.choices[0].message.content.trim()
    }
  }
}

// ── Handler principal ─────────────────────────────────────────

serve(async (req) => {
  if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 })

  try {
    const { userId } = await req.json()
    if (!userId) return new Response(JSON.stringify({ error: 'userId obrigatório' }), { status: 400 })

    const raw = await collectUserData(userId)
    const processed = processData(raw)
    const prompt = buildPrompt(processed)

    const aiResponse = await callAI(prompt)
    const cleaned = aiResponse.replace(/```json?\n?/g, '').replace(/```/g, '').trim()
    const analysis: FinancialAnalysis = JSON.parse(cleaned)

    return new Response(JSON.stringify({ analysis, processed }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('financial-analysis error:', err)
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 })
  }
})
