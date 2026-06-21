import webpush from 'web-push'
import { createAdminClient } from '@/lib/supabase/admin'
import { logEvent } from '@/lib/monitoring/events'

webpush.setVapidDetails(
  process.env.VAPID_SUBJECT!,
  process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY!,
  process.env.VAPID_PRIVATE_KEY!
)

export async function pushToUser(
  userId: string,
  payload: { title: string; body: string; url: string }
) {
  // Reading another user's subscriptions requires bypassing the (correct)
  // owner-only RLS on push_subscriptions, so this uses the service role.
  const supabase = createAdminClient()
  const { data: subs } = await supabase
    .from('push_subscriptions')
    .select('endpoint, p256dh, auth')
    .eq('user_id', userId)

  if (!subs?.length) return

  const results = await Promise.allSettled(
    subs.map((sub) =>
      webpush.sendNotification(
        { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
        JSON.stringify(payload)
      )
    )
  )

  const failed = results.filter((r) => r.status === 'rejected').length
  if (failed > 0) {
    await logEvent('push.delivery_failed', {
      level: 'warn',
      message: `${failed}/${results.length} push notifications failed`,
      context: { userId, total: results.length, failed },
    })
  }
}
