import webpush from 'web-push'
import { createClient } from '@/lib/supabase/server'

webpush.setVapidDetails(
  process.env.VAPID_SUBJECT!,
  process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY!,
  process.env.VAPID_PRIVATE_KEY!
)

interface PushTarget {
  endpoint: string
  p256dh: string
  auth: string
}

export async function pushToUser(
  userId: string,
  payload: { title: string; body: string; url: string }
) {
  const supabase = await createClient()
  // Security-definer RPC — a direct select on push_subscriptions is blocked by
  // RLS for other users' rows, so pushes to the recipient would never fire.
  const { data } = await supabase.rpc('get_push_targets', { target: userId })
  const subs = (data ?? []) as PushTarget[]

  if (!subs.length) return

  await Promise.allSettled(
    subs.map((sub) =>
      webpush.sendNotification(
        { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
        JSON.stringify(payload)
      )
    )
  )
}
