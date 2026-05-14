'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

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

  revalidatePath('/app/feed')
  return { error: null }
}
