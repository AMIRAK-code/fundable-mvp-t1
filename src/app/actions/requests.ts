'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'
import { pushToUser } from '@/lib/push/send'

export async function acceptConnection(connectionId: string): Promise<{ error: string | null }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  // Fetch the connection to know who the sender is
  const { data: conn } = await supabase
    .from('connections')
    .select('sender_id')
    .eq('id', connectionId)
    .eq('receiver_id', user.id)
    .single()

  const { error } = await supabase
    .from('connections')
    .update({ status: 'accepted' })
    .eq('id', connectionId)
    .eq('receiver_id', user.id)
    .eq('status', 'pending')

  if (error) return { error: error.message }

  if (conn?.sender_id) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', user.id)
      .single()

    const name = profile?.full_name ?? 'Someone'
    await pushToUser(conn.sender_id, {
      title: 'Connection accepted!',
      body: `${name} accepted your connection request`,
      url: '/app/messages',
    })
  }

  // Trigger auto-creates the chat_room
  revalidatePath('/app/requests')
  revalidatePath('/app/messages')
  return { error: null }
}

export async function declineConnection(connectionId: string): Promise<{ error: string | null }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  const { error } = await supabase
    .from('connections')
    .update({ status: 'declined' })
    .eq('id', connectionId)
    .eq('receiver_id', user.id)
    .eq('status', 'pending')

  if (error) return { error: error.message }

  revalidatePath('/app/requests')
  return { error: null }
}
