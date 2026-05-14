'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'
import { pushToUser } from '@/lib/push/send'

export async function sendConnect(receiverId: string): Promise<{ error: string | null }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  const { error } = await supabase
    .from('connections')
    .insert({ sender_id: user.id, receiver_id: receiverId })

  if (error) return { error: error.message }

  const { data: profile } = await supabase
    .from('profiles')
    .select('full_name')
    .eq('id', user.id)
    .single()

  const name = profile?.full_name ?? 'Someone'
  await pushToUser(receiverId, {
    title: 'New connection request',
    body: `${name} wants to connect with you`,
    url: '/app/requests',
  })

  revalidatePath('/app/feed')
  return { error: null }
}
