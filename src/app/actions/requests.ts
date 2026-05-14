'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

export async function acceptConnection(connectionId: string): Promise<{ error: string | null }> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Not authenticated' }

  const { error } = await supabase
    .from('connections')
    .update({ status: 'accepted' })
    .eq('id', connectionId)
    .eq('receiver_id', user.id)
    .eq('status', 'pending')

  if (error) return { error: error.message }

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
