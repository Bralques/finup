import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

// ── Credenciais (configure em Supabase → Edge Functions → Secrets) ──
// ZAPI_INSTANCE_ID  → ID da instância Z-API
// ZAPI_TOKEN        → Token da instância
// ZAPI_CLIENT_TOKEN → Client Token da conta

const ZAPI_INSTANCE_ID  = Deno.env.get('ZAPI_INSTANCE_ID')!
const ZAPI_TOKEN        = Deno.env.get('ZAPI_TOKEN')!
const ZAPI_CLIENT_TOKEN = Deno.env.get('ZAPI_CLIENT_TOKEN')!

interface SendWhatsappRequest {
  to: string      // ex: '5511999999999'
  message: string
}

async function sendViaZApi(to: string, message: string): Promise<void> {
  const url = `https://api.z-api.io/instances/${ZAPI_INSTANCE_ID}/token/${ZAPI_TOKEN}/send-text`

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Client-Token': ZAPI_CLIENT_TOKEN,
    },
    body: JSON.stringify({ phone: to, message }),
  })

  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Z-API error: ${err}`)
  }
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  try {
    const { to, message } = await req.json() as SendWhatsappRequest

    if (!to || !message) {
      return new Response(JSON.stringify({ error: 'to e message são obrigatórios' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    await sendViaZApi(to, message)

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('send-whatsapp error:', err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
