import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

// ── Provedor de IA configurável via env var ───────────────────
// AI_PROVIDER = "grok" | "gemini" | "groq" | "anthropic"
// Por padrão usa Grok (grátis com $25 de crédito)
const AI_PROVIDER = Deno.env.get('AI_PROVIDER') ?? 'grok'

// Chaves por provedor — só configure a do que for usar
const XAI_API_KEY       = Deno.env.get('XAI_API_KEY') ?? ''        // Grok
const GEMINI_API_KEY    = Deno.env.get('GEMINI_API_KEY') ?? ''      // Gemini
const GROQ_API_KEY      = Deno.env.get('GROQ_API_KEY') ?? ''        // Groq (Llama)
const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY') ?? ''   // Claude

export interface ParsedMessage {
  action: 'register' | 'query_balance' | 'query_summary' | 'query_help' | 'query_analysis' | 'unknown'
  type?: 'income' | 'expense' | 'transfer'
  amount?: number
  description?: string
  is_installment?: boolean
  installments?: number
  category_hint?: string
  confidence: number
}

export interface UserContext {
  user_id: string
  default_account_id: string | null
  default_account_name: string | null
  default_account_balance: number | null
}

const SYSTEM_PROMPT = `Você é um assistente financeiro brasileiro. Analise a mensagem e extraia as informações de lançamento financeiro.

Responda APENAS com JSON válido (sem markdown, sem explicações), seguindo este schema:
{
  "action": "register" | "query_balance" | "query_summary" | "query_help" | "unknown",
  "type": "income" | "expense" | "transfer",
  "amount": number (valor em reais, sem símbolo),
  "description": "descrição curta do gasto/receita",
  "is_installment": boolean,
  "installments": number (número de parcelas se parcelado),
  "category_hint": "dica de categoria em português (ex: Alimentação, Transporte, Salário)",
  "confidence": number (0 a 1)
}

Regras:
- "gastei", "paguei", "comprei" → expense
- "recebi", "entrou", "salário", "freela" → income
- "transferi", "mandei", "enviei" → transfer
- "saldo", "quanto tenho" → query_balance
- "resumo", "quanto gastei" → query_summary
- "ajuda", "help", "o que posso" → query_help
- "me analisa", "análise", "como estou", "diagnóstico" → query_analysis
- Valores: "50 reais" = 50, "1k" = 1000, "1,5k" = 1500, "2.5k" = 2500, "R$200" = 200
- Se não reconhecer nada financeiro: action = "unknown"`

// ── Grok (xAI) — OpenAI-compatible ───────────────────────────
async function callGrok(userMessage: string): Promise<string> {
  const res = await fetch('https://api.x.ai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${XAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: 'grok-3-mini',        // mais rápido e barato; use 'grok-3' para melhor qualidade
      max_tokens: 256,
      temperature: 0,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: `Mensagem: "${userMessage}"` },
      ],
    }),
  })
  if (!res.ok) throw new Error(`Grok error: ${await res.text()}`)
  const data = await res.json()
  return data.choices[0].message.content.trim()
}

// ── Gemini (Google) — grátis generoso ────────────────────────
async function callGemini(userMessage: string): Promise<string> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      system_instruction: { parts: [{ text: SYSTEM_PROMPT }] },
      contents: [{ parts: [{ text: `Mensagem: "${userMessage}"` }] }],
      generationConfig: { maxOutputTokens: 256, temperature: 0 },
    }),
  })
  if (!res.ok) throw new Error(`Gemini error: ${await res.text()}`)
  const data = await res.json()
  return data.candidates[0].content.parts[0].text.trim()
}

// ── Groq (Llama) — ultra rápido e grátis ─────────────────────
async function callGroq(userMessage: string): Promise<string> {
  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${GROQ_API_KEY}`,
    },
    body: JSON.stringify({
      model: 'llama-3.3-70b-versatile',   // melhor custo-benefício no Groq
      max_tokens: 256,
      temperature: 0,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: `Mensagem: "${userMessage}"` },
      ],
    }),
  })
  if (!res.ok) throw new Error(`Groq error: ${await res.text()}`)
  const data = await res.json()
  return data.choices[0].message.content.trim()
}

// ── Anthropic (Claude) ────────────────────────────────────────
async function callAnthropic(userMessage: string): Promise<string> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 256,
      messages: [{ role: 'user', content: `${SYSTEM_PROMPT}\n\nMensagem: "${userMessage}"` }],
    }),
  })
  if (!res.ok) throw new Error(`Anthropic error: ${await res.text()}`)
  const data = await res.json()
  return data.content[0].text.trim()
}

// ── Roteador principal ────────────────────────────────────────
async function callAI(userMessage: string): Promise<string> {
  switch (AI_PROVIDER) {
    case 'gemini':   return callGemini(userMessage)
    case 'groq':     return callGroq(userMessage)
    case 'anthropic': return callAnthropic(userMessage)
    default:          return callGrok(userMessage)   // grok é o padrão
  }
}

// ── Parser da resposta JSON da IA ────────────────────────────
export async function parseMessage(text: string): Promise<ParsedMessage> {
  try {
    const raw = await callAI(text)

    // Remove possível markdown residual (```json ... ```)
    const cleaned = raw.replace(/```json?\n?/g, '').replace(/```/g, '').trim()
    return JSON.parse(cleaned) as ParsedMessage
  } catch (err) {
    console.error('parseMessage error:', err)
    return { action: 'unknown', confidence: 0 }
  }
}

// ── Resto das funções (inalterado) ────────────────────────────

export async function getUserContext(userId: string): Promise<UserContext> {
  const { data } = await supabase
    .from('bot_user_context')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle()

  return {
    user_id: userId,
    default_account_id: data?.default_account_id ?? null,
    default_account_name: data?.default_account_name ?? null,
    default_account_balance: data?.default_account_balance ?? null,
  }
}

export async function getFirstAccount(userId: string) {
  const { data } = await supabase
    .from('accounts')
    .select('id, name, balance')
    .eq('user_id', userId)
    .eq('is_active', true)
    .neq('type', 'credit_card')
    .order('created_at')
    .limit(1)
    .maybeSingle()

  return data
}

export async function findCategory(userId: string, hint: string, type: string) {
  if (!hint) return null

  const { data: cats } = await supabase
    .from('categories')
    .select('id, name')
    .eq('user_id', userId)
    .eq('type', type)

  if (!cats?.length) return null

  const lower = hint.toLowerCase()
  const exact = cats.find((c) => c.name.toLowerCase() === lower)
  if (exact) return exact

  return cats.find((c) =>
    c.name.toLowerCase().includes(lower) || lower.includes(c.name.toLowerCase())
  ) ?? null
}

export async function registerTransaction(
  userId: string,
  parsed: ParsedMessage,
  accountId: string
) {
  const category = parsed.category_hint
    ? await findCategory(userId, parsed.category_hint, parsed.type ?? 'expense')
    : null

  if (parsed.is_installment && (parsed.installments ?? 1) > 1) {
    const count = parsed.installments!
    const installmentAmount = parsed.amount! / count
    const groupId = crypto.randomUUID()

    const rows = Array.from({ length: count }, (_, i) => {
      const date = new Date()
      date.setMonth(date.getMonth() + i)
      return {
        user_id: userId,
        account_id: accountId,
        category_id: category?.id ?? null,
        amount: installmentAmount,
        type: parsed.type ?? 'expense',
        description: parsed.description ?? null,
        date: date.toISOString().split('T')[0],
        is_paid: i === 0,
        installment_number: i + 1,
        total_installments: count,
        installment_group_id: groupId,
      }
    })

    await supabase.from('transactions').insert(rows)
    return { installments: count, installmentAmount }
  }

  await supabase.from('transactions').insert({
    user_id: userId,
    account_id: accountId,
    category_id: category?.id ?? null,
    amount: parsed.amount,
    type: parsed.type ?? 'expense',
    description: parsed.description ?? null,
    date: new Date().toISOString().split('T')[0],
    is_paid: true,
  })

  return null
}

export function formatCurrency(value: number): string {
  return value.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}

export async function buildReply(
  userId: string,
  parsed: ParsedMessage,
  accountId: string,
  accountName: string
): Promise<string> {
  if (parsed.action === 'query_balance') {
    const { data: accounts } = await supabase
      .from('accounts')
      .select('name, balance')
      .eq('user_id', userId)
      .eq('is_active', true)
      .neq('type', 'credit_card')

    if (!accounts?.length) return '❌ Nenhuma conta encontrada no Finup.'

    const total = accounts.reduce((s, a) => s + a.balance, 0)
    const lines = accounts.map((a) => `  • ${a.name}: ${formatCurrency(a.balance)}`).join('\n')
    return `💰 *Seus saldos:*\n${lines}\n\n*Total: ${formatCurrency(total)}*`
  }

  if (parsed.action === 'query_summary') {
    const now = new Date()
    const from = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0]
    const to = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().split('T')[0]

    const { data: txns } = await supabase
      .from('transactions')
      .select('amount, type')
      .eq('user_id', userId)
      .gte('date', from)
      .lte('date', to)
      .neq('type', 'transfer')

    let income = 0, expense = 0
    for (const t of txns ?? []) {
      if (t.type === 'income') income += t.amount
      else expense += t.amount
    }

    const month = now.toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' })
    return `📊 *Resumo de ${month}:*\n✅ Receitas: ${formatCurrency(income)}\n🔴 Despesas: ${formatCurrency(expense)}\n💰 Saldo: ${formatCurrency(income - expense)}`
  }

  if (parsed.action === 'query_help') {
    return `🤖 *Finup Bot — Como usar:*\n\n` +
      `💸 *Despesas:* "gastei 47 no mercado"\n` +
      `💰 *Receitas:* "recebi 3000 de salário"\n` +
      `🔄 *Transferência:* "transferi 500 para poupança"\n` +
      `💳 *Parcelado:* "comprei TV 1200 em 6x"\n\n` +
      `📊 *Consultas:*\n` +
      `• "saldo" — ver saldo das contas\n` +
      `• "resumo" — gastos do mês\n` +
      `• "me analisa" — análise completa com IA\n\n` +
      `_Conta padrão: ${accountName}_`
  }

  const emoji = parsed.type === 'income' ? '✅' : parsed.type === 'transfer' ? '🔄' : '✅'
  const typeLabel = parsed.type === 'income' ? 'Receita' : parsed.type === 'transfer' ? 'Transferência' : 'Despesa'

  if (parsed.is_installment && (parsed.installments ?? 1) > 1) {
    const each = (parsed.amount ?? 0) / (parsed.installments ?? 1)
    return `${emoji} *${typeLabel} parcelada registrada!*\n💰 Total: ${formatCurrency(parsed.amount ?? 0)}\n💳 ${parsed.installments}x de ${formatCurrency(each)}\n📝 ${parsed.description ?? '—'}\n🏦 Conta: ${accountName}`
  }

  return `${emoji} *${typeLabel} registrada!*\n💰 Valor: ${formatCurrency(parsed.amount ?? 0)}\n📝 ${parsed.description ?? '—'}\n🏦 Conta: ${accountName}`
}

export async function handleBotMessage(userId: string, text: string): Promise<string> {
  const parsed = await parseMessage(text)

  if (parsed.action === 'unknown' || parsed.confidence < 0.4) {
    return '🤔 Não entendi. Tente: "gastei 50 no almoço" ou "recebi 1000 de salário"\n\nDigite *ajuda* para ver todos os comandos.'
  }

  let ctx = await getUserContext(userId)
  let accountId = ctx.default_account_id
  let accountName = ctx.default_account_name ?? 'Conta principal'

  if (!accountId) {
    const first = await getFirstAccount(userId)
    if (!first) return '❌ Nenhuma conta cadastrada no Finup. Acesse o app e crie uma conta primeiro.'
    accountId = first.id
    accountName = first.name
  }

  if (parsed.action === 'query_analysis') {
    try {
      const result = await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/financial-analysis`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        },
        body: JSON.stringify({ userId }),
      })
      const { analysis } = await result.json()
      const a = analysis
      const pct = (v: number) => `${(v * 100).toFixed(1)}%`
      return (
        `🤖 *Análise Financeira Finup*\n\n` +
        `📊 *Score: ${a.score}/10 — ${a.score_label}*\n\n` +
        `${a.summary}\n\n` +
        (a.positives?.length ? `✅ *Positivos:*\n${a.positives.map((p: string) => `• ${p}`).join('\n')}\n\n` : '') +
        (a.alerts?.length ? `⚠️ *Alertas:*\n${a.alerts.map((al: string) => `• ${al}`).join('\n')}\n\n` : '') +
        (a.recommendations?.length ? `💡 *Recomendações:*\n${a.recommendations.map((r: string, i: number) => `${i+1}. ${r}`).join('\n')}\n\n` : '') +
        `💰 Taxa de poupança: ${pct(a.savings_rate)} | ${a.trend_label}`
      )
    } catch {
      return '❌ Erro ao gerar análise. Tente novamente em instantes.'
    }
  }

  if (parsed.action === 'register') {
    if (!parsed.amount || parsed.amount <= 0) {
      return '❌ Não identifiquei o valor. Tente: "gastei 50 no almoço"'
    }
    await registerTransaction(userId, parsed, accountId)
  }

  return buildReply(userId, parsed, accountId, accountName)
}

// bot-parse: aceita POST com {userId, text} e retorna {reply}
// Chamado internamente por telegram-bot e whatsapp-bot via HTTP.
serve(async (req) => {
  if (req.method !== 'POST') return new Response('OK')
  try {
    const { userId, text } = await req.json()
    if (!userId || !text) {
      return new Response(JSON.stringify({ error: 'userId e text são obrigatórios' }), {
        status: 400, headers: { 'Content-Type': 'application/json' },
      })
    }
    const reply = await handleBotMessage(userId, text)
    return new Response(JSON.stringify({ reply }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error(err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { 'Content-Type': 'application/json' },
    })
  }
})
