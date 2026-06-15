'use server'

import { createClient } from '@/lib/supabase/server'
import { pushToUser } from '@/lib/push/send'

export async function sendConnect(receiverId: string): Promise<{ error: string | null }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'You need to be signed in to connect' }
  if (user.id === receiverId) return { error: 'You cannot connect with yourself' }

  const { error } = await supabase
    .from('connections')
    .insert({ sender_id: user.id, receiver_id: receiverId })

  if (error) {
    // 23505 = unique violation: a connection (pending/accepted/declined) already exists
    if (error.code === '23505') return { error: 'Request already exists' }
    return { error: 'Could not send request. Please try again.' }
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('full_name')
    .eq('id', user.id)
    .single()

  // Awaited on purpose: serverless cannot fire-and-forget safely.
  // The optimistic UI on the client already hides this latency.
  const name = profile?.full_name ?? 'Someone'
  await pushToUser(receiverId, {
    title: 'New connection request',
    body: `${name} wants to connect with you`,
    url: '/app/requests',
  })

  // No revalidatePath here: the feed button is optimistic and revalidating
  // would refetch the whole feed and destroy scroll position.
  return { error: null }
}
