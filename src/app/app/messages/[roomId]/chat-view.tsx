'use client'

import { useState, useEffect, useRef, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'
import { ArrowLeft, Send, User } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

interface Msg {
  id: string
  sender_id: string
  content: string
  created_at: string
}

interface Props {
  roomId: string
  currentUserId: string
  otherUser: { id: string; full_name: string | null; avatar_url: string | null }
  initialMessages: Msg[]
}

export default function ChatView({
  roomId,
  currentUserId,
  otherUser,
  initialMessages,
}: Props) {
  const router = useRouter()
  const supabase = useMemo(() => createClient(), [])
  const [messages, setMessages] = useState<Msg[]>(initialMessages)
  const [input, setInput] = useState('')
  const [sending, setSending] = useState(false)
  const containerRef = useRef<HTMLDivElement>(null)
  const isFirstRender = useRef(true)

  // Scroll to bottom
  useEffect(() => {
    if (!containerRef.current) return
    containerRef.current.scrollTop = containerRef.current.scrollHeight
    isFirstRender.current = false
  }, [messages])

  // Realtime subscription
  useEffect(() => {
    const channel = supabase
      .channel(`room-${roomId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `chat_room_id=eq.${roomId}`,
        },
        (payload) => {
          const newMsg = payload.new as Msg
          setMessages((prev) =>
            prev.some((m) => m.id === newMsg.id) ? prev : [...prev, newMsg]
          )
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [roomId, supabase])

  async function handleSend() {
    const text = input.trim()
    if (!text || sending) return
    setInput('')
    setSending(true)

    await supabase.from('messages').insert({
      chat_room_id: roomId,
      sender_id: currentUserId,
      content: text,
    })

    setSending(false)
  }

  return (
    <div className="flex flex-col h-screen bg-background">
      {/* Header */}
      <header className="flex items-center gap-3 px-4 py-3 border-b border-white/10 bg-background/90 backdrop-blur-md flex-shrink-0">
        <button
          onClick={() => router.back()}
          className="text-muted-foreground hover:text-foreground transition-colors p-1"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>

        {otherUser.avatar_url ? (
          <Image
            src={otherUser.avatar_url}
            alt={otherUser.full_name ?? ''}
            width={36}
            height={36}
            className="rounded-full object-cover"
          />
        ) : (
          <div className="w-9 h-9 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0">
            <User className="w-4 h-4 text-muted-foreground" />
          </div>
        )}

        <span className="font-semibold truncate">{otherUser.full_name}</span>
      </header>

      {/* Messages */}
      <div
        ref={containerRef}
        className="flex-1 overflow-y-auto px-4 py-4 space-y-3"
      >
        {messages.length === 0 && (
          <p className="text-center text-sm text-muted-foreground pt-12">
            Say hello 👋
          </p>
        )}

        {messages.map((msg) => {
          const isOwn = msg.sender_id === currentUserId
          return (
            <div
              key={msg.id}
              className={`flex items-end gap-2 ${isOwn ? 'justify-end' : 'justify-start'}`}
            >
              {!isOwn && (
                <div className="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0 mb-0.5">
                  {otherUser.avatar_url ? (
                    <Image
                      src={otherUser.avatar_url}
                      alt=""
                      width={24}
                      height={24}
                      className="rounded-full object-cover"
                    />
                  ) : (
                    <User className="w-3 h-3 text-muted-foreground" />
                  )}
                </div>
              )}

              <div
                className={[
                  'max-w-[72%] px-4 py-2.5 rounded-2xl text-sm leading-relaxed',
                  isOwn
                    ? 'bg-[var(--brand-primary)] text-white rounded-br-sm'
                    : 'bg-white/10 text-foreground rounded-bl-sm',
                ].join(' ')}
              >
                {msg.content}
              </div>
            </div>
          )
        })}
      </div>

      {/* Input bar */}
      <div className="flex items-center gap-2 px-4 py-3 border-t border-white/10 bg-background flex-shrink-0 pb-safe">
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault()
              handleSend()
            }
          }}
          placeholder="Message…"
          className="flex-1 rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
        />
        <button
          onClick={handleSend}
          disabled={!input.trim() || sending}
          className="w-10 h-10 flex items-center justify-center rounded-xl bg-[var(--brand-primary)] text-white hover:opacity-90 disabled:opacity-40 transition-opacity flex-shrink-0"
        >
          <Send className="w-4 h-4" />
        </button>
      </div>
    </div>
  )
}
