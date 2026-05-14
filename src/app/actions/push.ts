'use server'

import { createClient } from '@/lib/supabase/server'
import { pushToUser } from '@/lib/push/send'

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

  const { data: profile } = await supabase
    .from('profiles')
    .select('full_name')
    .eq('id', user.id)
    .single()

  const name = profile?.full_name ?? 'Someone'
  await pushToUser(recipientId, {
    title: name,
    body: preview || '📷 Image',
    url: '/app/messages',
  })
}
