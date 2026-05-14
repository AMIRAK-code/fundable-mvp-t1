import Link from 'next/link'
import Image from 'next/image'
import { User, MessageSquare } from 'lucide-react'
import { createClient } from '@/lib/supabase/server'

export default async function MessagesPage() {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Accepted connections I'm part of
  const { data: conns } = await supabase
    .from('connections')
    .select('id, sender_id, receiver_id')
    .eq('status', 'accepted')
    .or(`sender_id.eq.${user!.id},receiver_id.eq.${user!.id}`)

  if (!conns?.length) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-3 px-4 text-center">
        <MessageSquare className="w-10 h-10 text-muted-foreground" />
        <p className="font-semibold">No conversations yet</p>
        <p className="text-sm text-muted-foreground max-w-xs">
          Accept a connection request or get accepted to start chatting.
        </p>
      </div>
    )
  }

  const connIds = conns.map((c) => c.id)

  // Get chat rooms
  const { data: rooms } = await supabase
    .from('chat_rooms')
    .select('id, connection_id, created_at')
    .in('connection_id', connIds)

  if (!rooms?.length) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-3 px-4 text-center">
        <MessageSquare className="w-10 h-10 text-muted-foreground" />
        <p className="text-sm text-muted-foreground">Rooms are being set up…</p>
      </div>
    )
  }

  // Other participant IDs (one per connection)
  const otherIds = conns.map((c) =>
    c.sender_id === user!.id ? c.receiver_id : c.sender_id
  )

  const { data: profiles } = await supabase
    .from('profiles')
    .select('id, full_name, avatar_url')
    .in('id', otherIds)

  const profileMap = Object.fromEntries((profiles ?? []).map((p) => [p.id, p]))

  // Last message per room (one query, dedup in JS)
  const roomIds = rooms.map((r) => r.id)
  const { data: allMsgs } = await supabase
    .from('messages')
    .select('chat_room_id, content, created_at, sender_id')
    .in('chat_room_id', roomIds)
    .order('created_at', { ascending: false })

  const lastMsgMap: Record<string, { content: string; created_at: string; sender_id: string }> = {}
  for (const m of allMsgs ?? []) {
    if (!lastMsgMap[m.chat_room_id]) lastMsgMap[m.chat_room_id] = m
  }

  // Map connection_id → connection
  const connById = Object.fromEntries(conns.map((c) => [c.id, c]))

  // Sort rooms by most recent activity
  const sorted = [...rooms].sort((a, b) => {
    const at = lastMsgMap[a.id]?.created_at ?? a.created_at
    const bt = lastMsgMap[b.id]?.created_at ?? b.created_at
    return bt.localeCompare(at)
  })

  return (
    <div className="max-w-lg mx-auto px-4 pt-6 pb-8 space-y-3">
      <h2 className="font-semibold text-sm uppercase tracking-wider text-muted-foreground mb-4">
        Messages
      </h2>

      {sorted.map((room) => {
        const conn = connById[room.connection_id]
        if (!conn) return null
        const otherId = conn.sender_id === user!.id ? conn.receiver_id : conn.sender_id
        const other = profileMap[otherId]
        const lastMsg = lastMsgMap[room.id]

        return (
          <Link
            key={room.id}
            href={`/app/messages/${room.id}`}
            className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/5 p-4 hover:bg-white/10 transition-colors"
          >
            {other?.avatar_url ? (
              <Image
                src={other.avatar_url}
                alt={other.full_name ?? ''}
                width={48}
                height={48}
                className="rounded-full object-cover flex-shrink-0"
              />
            ) : (
              <div className="w-12 h-12 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0">
                <User className="w-5 h-5 text-muted-foreground" />
              </div>
            )}

            <div className="flex-1 min-w-0">
              <div className="flex items-baseline justify-between gap-2">
                <p className="font-semibold text-sm truncate">{other?.full_name ?? 'Unknown'}</p>
                {lastMsg && (
                  <span className="text-[10px] text-muted-foreground flex-shrink-0">
                    {formatTime(lastMsg.created_at)}
                  </span>
                )}
              </div>
              <p className="text-xs text-muted-foreground mt-0.5 truncate">
                {lastMsg
                  ? `${lastMsg.sender_id === user!.id ? 'You: ' : ''}${lastMsg.content}`
                  : 'Say hello 👋'}
              </p>
            </div>
          </Link>
        )
      })}
    </div>
  )
}

function formatTime(iso: string) {
  const d = new Date(iso)
  const now = new Date()
  if (d.toDateString() === now.toDateString()) {
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  }
  return d.toLocaleDateString([], { month: 'short', day: 'numeric' })
}
