import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

const ZAPI_INSTANCE_ID  = Deno.env.get('ZAPI_INSTANCE_ID')!
const ZAPI_TOKEN        = Deno.env.get('ZAPI_TOKEN')!
const ZAPI_CLIENT_TOKEN = Deno.env.get('ZAPI_CLIENT_TOKEN')!
const SUPABASE_URL      = Deno.env.get('SUPABASE_URL')!
const SERVICE_KEY       = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

async function sendWhatsApp(phone: string, message: string) {
  const plain = message.replace(/\*([^*]+)\*/g, '*$1*').replace(/`/g, '')
  const url = `https://api.z-api.io/instances/${ZAPI_INSTANCE_ID}/token/${ZAPI_TOKEN}/send-text`
  await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Client-Token': ZAPI_CLIENT_TOKEN },
    body: JSON.stringify({ phone, message: plain }),
  })
}

async function getUserIdByPhone(phone: string): Promise<string | null> {
  const normalized = phone.replace(/\D/g, '')
  const variants = [normalized]
  if (normalized.length === 13 && normalized.startsWith('55')) {
    variants.push(normalized.slice(0, 4) + normalized.slice(5))
  }
  if (normalized.length === 12 && normalized.startsWith('55')) {
    variants.push(normalized.slice(0, 4) + '9' + normalized.slice(4))
  }
  for (const v of variants) {
    const { data } = await supabase
      .from('notification_settings')
      .select('user_id')
      .eq('whatsapp_number', v)
      .eq('whatsapp_enabled', true)
      .maybeSingle()
    if (data?.user_id) return data.user_id
  }
  return null
}

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

serve(async (req) => {
  if (req.method !== 'POST') return new Response('OK')

  let body: Record<string, unknown>
  try { body = await req.json() } catch { return new Response('OK') }

  try {
    if (body.fromMe === true || body.isGroup === true) return new Response('OK')

    const textObj = body.text as Record<string, string> | undefined
    const text = textObj?.message?.trim() ?? ''
    if (!text) return new Response('OK')

    const phone = String(body.phone ?? '').replace(/\D/g, '')
    if (!phone) return new Response('OK')

    const userId = await getUserIdByPhone(phone)

    if (!userId) {
      await sendWhatsApp(phone,
        '❌ Número não vinculado ao Finup.\n\n' +
        'Acesse o app → Mais → Avisos e Bot → WhatsApp\n' +
        `e confirme seu número: ${phone}`
      )
      return new Response('OK')
    }

    const reply = await callBotParse(userId, text)
    await sendWhatsApp(phone, reply)

    return new Response('OK')
  } catch (err) {
    console.error('whatsapp-bot error:', err)
    return new Response('OK')
  }
})
