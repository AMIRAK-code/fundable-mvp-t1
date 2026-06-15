'use client'

import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { usePathname } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

export interface NavBadgeCounts {
  requests: number
  messages: number
}

/**
 * Live badge counts for the bottom nav.
 * - requests: pending incoming connection requests
 * - messages: total unread messages across all chat rooms
 *
 * Refreshes on route change, window focus, tab visibility, and via
 * Supabase realtime (new messages debounced 500ms, connection changes).
 */
export function useNavBadges(): NavBadgeCounts {
  const supabase = useMemo(() => createClient(), [])
  const pathname = usePathname()
  const [counts, setCounts] = useState<NavBadgeCounts>({ requests: 0, messages: 0 })

  const alive = useRef(true)
  const uid = useRef<string | null>(null)
  const uidPromise = useRef<Promise<string | null> | null>(null)

  // Resolve the current user id exactly once, shared by all refetches
  const getUid = useCallback(() => {
    if (!uidPromise.current) {
      uidPromise.current = supabase.auth.getUser().then(({ data }) => {
        uid.current = data.user?.id ?? null
        return uid.current
      })
    }
    return uidPromise.current
  }, [supabase])

  const refetchRequests = useCallback(async () => {
    const id = await getUid()
    if (!id || !alive.current) return
    const { count, error } = await supabase
      .from('connections')
      .select('id', { count: 'exact', head: true })
      .eq('receiver_id', id)
      .eq('status', 'pending')
    if (error || !alive.current) return
    const next = count ?? 0
    setCounts((prev) => (prev.requests === next ? prev : { ...prev, requests: next }))
  }, [supabase, getUid])

  const refetchUnread = useCallback(async () => {
    const id = await getUid()
    if (!id || !alive.current) return
    const { data, error } = await supabase.rpc('get_unread_counts')
    if (error || !alive.current) return
    const rows = (data ?? []) as { chat_room_id: string; unread_count: number }[]
    const total = rows.reduce((sum, r) => sum + Number(r.unread_count ?? 0), 0)
    setCounts((prev) => (prev.messages === total ? prev : { ...prev, messages: total }))
  }, [supabase, getUid])

  const refetchAll = useCallback(() => {
    refetchRequests()
    refetchUnread()
  }, [refetchRequests, refetchUnread])

  // Freshness: refetch on every route change (also covers initial mount)
  useEffect(() => {
    refetchAll()
  }, [pathname, refetchAll])

  // Freshness: window focus, tab visibility, and realtime inserts/updates
  useEffect(() => {
    alive.current = true

    const onFocus = () => refetchAll()
    const onVisibility = () => {
      if (document.visibilityState === 'visible') refetchAll()
    }
    window.addEventListener('focus', onFocus)
    document.addEventListener('visibilitychange', onVisibility)

    let debounce: ReturnType<typeof setTimeout> | null = null
    const debouncedUnread = () => {
      if (debounce) clearTimeout(debounce)
      debounce = setTimeout(() => {
        debounce = null
        refetchUnread()
      }, 500)
    }

    const channel = supabase
      .channel('nav-badges')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'messages' },
        (payload) => {
          const senderId = (payload.new as { sender_id?: string }).sender_id
          if (senderId && senderId === uid.current) return
          debouncedUnread()
        }
      )
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'connections' },
        () => { refetchRequests() }
      )
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'connections' },
        () => { refetchRequests() }
      )
      .subscribe()

    return () => {
      alive.current = false
      if (debounce) clearTimeout(debounce)
      window.removeEventListener('focus', onFocus)
      document.removeEventListener('visibilitychange', onVisibility)
      supabase.removeChannel(channel)
    }
  }, [supabase, refetchAll, refetchRequests, refetchUnread])

  return counts
}

/** Numeric badge pill rendered over a nav icon. Pops on count change, hidden at 0. */
export function NavBadge({ count }: { count: number }) {
  if (count <= 0) return null
  return (
    <span
      key={count}
      aria-hidden="true"
      className="animate-pop absolute -top-1 -right-2 flex items-center justify-center min-w-[16px] h-4 px-1 rounded-full bg-[var(--brand-primary)] text-white text-[9px] font-bold leading-none tabular-nums ring-2 ring-background"
    >
      {count > 9 ? '9+' : count}
    </span>
  )
}
