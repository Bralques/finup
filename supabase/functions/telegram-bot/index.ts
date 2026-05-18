import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const TELEGRAM_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN')!
const TELEGRAM_API = `https://api.telegram.org/bot${TELEGRAM_TOKEN}`
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// ── Envia mensagem para o Telegram ────────────────────────────
async function sendMessage(chatId: number | string, text: string) {
  await fetch(`${TELEGRAM_API}/sendMessage`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, text, parse_mode: 'Markdown' }),
  })
}

// ── Busca user_id pelo telegram_chat_id ───────────────────────
async function getUserIdByChatId(chatId: string): Promise<string | null> {
  const { data } = await supabase
    .from('notification_settings')
    .select('user_id')
    .eq('telegram_chat_id', chatId)
    .maybeSingle()
  return data?.user_id ?? null
}

// ── Chama bot-parse via HTTP (evita conflito de serve()) ──────
async function callBotParse(userId: string, text: string): Promise<string> {
  const res = await fetch(`${SUPABASE_URL}/functions/v1/bot-parse`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${SERVICE_KEY}`,
    },
    body: JSON.stringify({ userId, text }),
  })
  if (!res.ok) throw new Error(`bot-parse: ${await res.text()}`)
  const { reply } = await res.json()
  return reply
}

// ── Webhook handler ───────────────────────────────────────────
serve(async (req) => {
  if (req.method !== 'POST') return new Response('OK')

  try {
    const update = await req.json()
    const message = update.message ?? update.edited_message
    if (!message?.text) return new Response('OK')

    const chatId = String(message.chat.id)
    const text   = message.text.trim()
    const firstName = message.from?.first_name ?? ''

    // /start — mostra chat_id para o usuário vincular no app
    if (text === '/start') {
      await sendMessage(chatId,
        `👋 Olá${firstName ? `, ${firstName}` : ''}! Sou o bot do *Finup*.\n\n` +
        `Para vincular sua conta, acesse o app:\n` +
        `*Mais → Avisos e Bot → Telegram*\n\n` +
        `Cole este código no campo *Chat ID*:\n` +
        `\`${chatId}\`\n\n` +
        `Depois mande qualquer mensagem para registrar uma transação!\nExemplo: _"gastei 50 no almoço"_`
      )
      return new Response('OK')
    }

    // Busca usuário vinculado
    const userId = await getUserIdByChatId(chatId)

    if (!userId) {
      await sendMessage(chatId,
        `❌ Conta não vinculada ao Finup.\n\n` +
        `Acesse o app → *Mais → Avisos e Bot → Telegram*\n` +
        `e cole este código: \`${chatId}\``
      )
      return new Response('OK')
    }

    // Indicador de digitando...
    await fetch(`${TELEGRAM_API}/sendChatAction`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chat_id: chatId, action: 'typing' }),
    })

    // Processa e responde
    const reply = await callBotParse(userId, text)
    await sendMessage(chatId, reply)

    return new Response('OK')
  } catch (err) {
    console.error('telegram-bot error:', err)
    return new Response('OK')
  }
})
