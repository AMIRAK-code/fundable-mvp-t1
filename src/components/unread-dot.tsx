'use client'

import { useState, useEffect, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'

export default function UnreadDot() {
  const supabase = useMemo(() => createClient(), [])
  const [hasUnread, setHasUnread] = useState(false)

  useEffect(() => {
    let userId: string | null = null

    async function check() {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) return
      userId = user.id

      // Messages in my rooms from others in the last 7 days
      const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
      const { count } = await supabase
        .from('messages')
        .select('id', { count: 'exact', head: true })
        .neq('sender_id', user.id)
        .gt('created_at', since)

      setHasUnread((count ?? 0) > 0)
    }

    check()

    // Refresh dot when a new message lands
    const channel = supabase
      .channel('unread-dot')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'messages' },
        (payload) => {
          // Only mark unread if the message is from someone else
          if ((payload.new as { sender_id: string }).sender_id !== userId) {
            setHasUnread(true)
          }
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [supabase])

  if (!hasUnread) return null

  return (
    <span className="absolute -top-0.5 -right-0.5 w-2 h-2 bg-[var(--brand-primary)] rounded-full ring-2 ring-background" />
  )
}
