import Link from 'next/link'
import Image from 'next/image'
import { User, MessageSquare, ImageIcon } from 'lucide-react'
import { createClient } from '@/lib/supabase/server'
import { timeAgo } from '@/lib/time'
import EmptyState from '@/components/empty-state'
import type { ConversationOverview } from '@/lib/supabase/types'

export default async function MessagesPage() {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Connections and the per-room overview RPC are independent — fetch in parallel
  const [{ data: conns }, { data: overviewRows }] = await Promise.all([
    supabase
      .from('connections')
      .select('id, sender_id, receiver_id')
      .eq('status', 'accepted')
      .or(`sender_id.eq.${user!.id},receiver_id.eq.${user!.id}`),
    supabase.rpc('get_conversation_overview'),
  ])

  if (!conns?.length) {
    return (
      <div className="max-w-lg mx-auto px-3 sm:px-4 min-h-[60vh] flex items-center justify-center">
        <EmptyState
          icon={MessageSquare}
          title="No conversations yet"
          hint="Accept a connection request or get accepted to start chatting."
        />
      </div>
    )
  }

  const connIds = conns.map((c) => c.id)
  const otherIds = conns.map((c) =>
    c.sender_id === user!.id ? c.receiver_id : c.sender_id
  )

  // Rooms and the other participants' profiles only depend on connections — parallel
  const [{ data: rooms }, { data: profiles }] = await Promise.all([
    supabase
      .from('chat_rooms')
      .select('id, connection_id, created_at')
      .in('connection_id', connIds),
    supabase
      .from('profiles')
      .select('id, full_name, avatar_url')
      .in('id', otherIds),
  ])

  if (!rooms?.length) {
    return (
      <div className="max-w-lg mx-auto px-3 sm:px-4 min-h-[60vh] flex items-center justify-center">
        <EmptyState
          icon={MessageSquare}
          title="Rooms are being set up…"
          hint="Refresh in a moment to start chatting."
        />
      </div>
    )
  }

  const profileMap = Object.fromEntries((profiles ?? []).map((p) => [p.id, p]))
  const connById = Object.fromEntries(conns.map((c) => [c.id, c]))
  const overviews = (overviewRows ?? []) as ConversationOverview[]
  const overviewMap = Object.fromEntries(overviews.map((o) => [o.chat_room_id, o]))

  // Sort rooms by most recent activity
  const sorted = [...rooms].sort((a, b) => {
    const at = overviewMap[a.id]?.last_at ?? a.created_at
    const bt = overviewMap[b.id]?.last_at ?? b.created_at
    return bt.localeCompare(at)
  })

  return (
    <div className="max-w-lg mx-auto px-3 sm:px-4 pt-[calc(env(safe-area-inset-top)+1rem)] pb-4">
      <h2 className="font-semibold text-sm uppercase tracking-wider text-muted-foreground mb-3">
        Messages
      </h2>

      <div className="space-y-3 stagger-children">
        {sorted.map((room) => {
          const conn = connById[room.connection_id]
          if (!conn) return null
          const otherId =
            conn.sender_id === user!.id ? conn.receiver_id : conn.sender_id
          const other = profileMap[otherId]
          const ov = overviewMap[room.id]
          const unread = ov?.unread_count ?? 0
          const fromMe = ov?.last_sender_id === user!.id

          return (
            <Link
              key={room.id}
              href={`/app/messages/${room.id}`}
              className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/5 p-4 hover:bg-white/10 transition-colors press animate-in-up"
            >
              {other?.avatar_url ? (
                <Image
                  src={other.avatar_url}
                  alt={other.full_name ?? ''}
                  width={48}
                  height={48}
                  className="w-12 h-12 rounded-full object-cover flex-shrink-0"
                />
              ) : (
                <div className="w-12 h-12 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0">
                  <User className="w-5 h-5 text-muted-foreground" />
                </div>
              )}

              <div className="flex-1 min-w-0">
                <p
                  className={`text-sm truncate ${
                    unread > 0 ? 'font-bold text-foreground' : 'font-semibold'
                  }`}
                >
                  {other?.full_name ?? 'Unknown'}
                </p>
                <p
                  className={`text-xs mt-0.5 truncate ${
                    unread > 0 ? 'text-foreground' : 'text-muted-foreground'
                  }`}
                >
                  {!ov ? (
                    'Say hello 👋'
                  ) : ov.last_type === 'image' ? (
                    <span className="inline-flex items-center gap-1 align-bottom">
                      {fromMe && <span>You:</span>}
                      <ImageIcon className="w-3 h-3 flex-shrink-0" aria-hidden="true" />
                      <span>Photo</span>
                    </span>
                  ) : (
                    `${fromMe ? 'You: ' : ''}${ov.last_content}`
                  )}
                </p>
              </div>

              <div className="flex flex-col items-end gap-1 flex-shrink-0">
                {ov && (
                  <span className="text-[10px] text-muted-foreground">
                    {timeAgo(ov.last_at)}
                  </span>
                )}
                {unread > 0 && (
                  <span className="flex items-center justify-center bg-[var(--brand-primary)] text-white text-[10px] font-bold rounded-full min-w-[18px] h-[18px] px-1 animate-pop">
                    {unread > 99 ? '99+' : unread}
                  </span>
                )}
              </div>
            </Link>
          )
        })}
      </div>
    </div>
  )
}
