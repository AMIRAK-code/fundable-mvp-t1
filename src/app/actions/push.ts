'use server'

import { createClient } from '@/lib/supabase/server'
import { pushToUser } from '@/lib/push/send'
import { rateLimit } from '@/lib/security/rate-limit'

export async function saveSubscription(
  endpoint: string,
  p256dh: string,
  auth: string
): Promise<{ error: string | null }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  const { error } = await supabase
    .from('push_subscriptions')
    .upsert(
      { user_id: user.id, endpoint, p256dh, auth },
      { onConflict: 'user_id,endpoint' }
    )
  return { error: error?.message ?? null }
}

export async function notifyNewMessage(
  recipientId: string,
  preview: string
): Promise<void> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return

  // Only allow notifying users you actually share an accepted connection with —
  // prevents using this action to spam/phish arbitrary users.
  const { data: connection } = await supabase
    .from('connections')
    .select('id')
    .eq('status', 'accepted')
    .or(
      `and(sender_id.eq.${user.id},receiver_id.eq.${recipientId}),and(sender_id.eq.${recipientId},receiver_id.eq.${user.id})`
    )
    .maybeSingle()
  if (!connection) return

  // Throttle to curb notification flooding.
  if (!rateLimit(`notify:${user.id}`, 30, 60_000)) return

  const { data: profile } = await supabase
    .from('profiles')
    .select('full_name')
    .eq('id', user.id)
    .single()

  const name = profile?.full_name ?? 'Someone'
  await pushToUser(recipientId, {
    title: name,
    // Never trust client-supplied length; bound the preview server-side.
    body: (preview || '📷 Image').slice(0, 100),
    url: '/app/messages',
  })
}
