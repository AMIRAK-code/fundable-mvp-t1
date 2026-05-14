'use client'

import { useState, useEffect, useRef, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'
import { ArrowLeft, Send, User, ImageIcon, X } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { notifyNewMessage } from '@/app/actions/push'

interface Msg {
  id: string
  sender_id: string
  content: string
  message_type: 'text' | 'image'
  media_url: string | null
  created_at: string
}

interface Props {
  roomId: string
  currentUserId: string
  otherUser: { id: string; full_name: string | null; avatar_url: string | null }
  initialMessages: Msg[]
}

const URL_RE = /(https?:\/\/[^\s<>"{}|\\^`[\]]+)/g

function linkify(text: string) {
  const parts = text.split(URL_RE)
  return parts.map((part, i) =>
    URL_RE.test(part) ? (
      <a
        key={i}
        href={part}
        target="_blank"
        rel="noopener noreferrer"
        className="underline underline-offset-2 break-all hover:opacity-80"
        onClick={(e) => e.stopPropagation()}
      >
        {part}
      </a>
    ) : (
      part
    )
  )
}

export default function ChatView({ roomId, currentUserId, otherUser, initialMessages }: Props) {
  const router = useRouter()
  const supabase = useMemo(() => createClient(), [])
  const [messages, setMessages] = useState<Msg[]>(initialMessages)
  const [input, setInput] = useState('')
  const [sending, setSending] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [imagePreview, setImagePreview] = useState<{ file: File; url: string } | null>(null)
  const containerRef = useRef<HTMLDivElement>(null)
  const fileRef = useRef<HTMLInputElement>(null)

  // Scroll to bottom on new messages
  useEffect(() => {
    if (!containerRef.current) return
    containerRef.current.scrollTop = containerRef.current.scrollHeight
  }, [messages])

  // Realtime subscription
  useEffect(() => {
    const channel = supabase
      .channel(`room-${roomId}`)
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'messages', filter: `chat_room_id=eq.${roomId}` },
        (payload) => {
          const newMsg = payload.new as Msg
          setMessages((prev) => prev.some((m) => m.id === newMsg.id) ? prev : [...prev, newMsg])
        }
      )
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [roomId, supabase])

  async function handleSend() {
    if (imagePreview) { await handleImageSend(imagePreview.file); return }
    const text = input.trim()
    if (!text || sending) return
    setInput('')
    setSending(true)
    await supabase.from('messages').insert({
      chat_room_id: roomId,
      sender_id: currentUserId,
      content: text,
      message_type: 'text',
      media_url: null,
    })
    notifyNewMessage(otherUser.id, text.slice(0, 100))
    setSending(false)
  }

  async function handleImageSend(file: File) {
    setUploading(true)
    const ext = file.name.split('.').pop() ?? 'jpg'
    const path = `${roomId}/${Date.now()}.${ext}`
    const { error: uploadError } = await supabase.storage.from('message-media').upload(path, file)
    if (uploadError) { setUploading(false); return }
    const { data: { publicUrl } } = supabase.storage.from('message-media').getPublicUrl(path)
    await supabase.from('messages').insert({
      chat_room_id: roomId,
      sender_id: currentUserId,
      content: '',
      message_type: 'image',
      media_url: publicUrl,
    })
    setImagePreview(null)
    setUploading(false)
    notifyNewMessage(otherUser.id, '📷 Image')
  }

  function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    setImagePreview({ file, url: URL.createObjectURL(file) })
    e.target.value = ''
  }

  return (
    <div className="flex flex-col h-[calc(100dvh-64px-env(safe-area-inset-bottom))] bg-background">
      {/* Header */}
      <header className="flex items-center gap-3 px-3 sm:px-4 py-2.5 pt-[calc(env(safe-area-inset-top)+0.625rem)] border-b border-white/10 bg-background/95 backdrop-blur-md flex-shrink-0">
        <button onClick={() => router.back()} className="text-muted-foreground hover:text-foreground transition-colors p-1">
          <ArrowLeft className="w-5 h-5" />
        </button>
        {otherUser.avatar_url ? (
          <Image src={otherUser.avatar_url} alt={otherUser.full_name ?? ''} width={36} height={36} className="rounded-full object-cover" />
        ) : (
          <div className="w-9 h-9 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0">
            <User className="w-4 h-4 text-muted-foreground" />
          </div>
        )}
        <span className="font-semibold truncate">{otherUser.full_name}</span>
      </header>

      {/* Messages */}
      <div ref={containerRef} className="flex-1 overflow-y-auto px-4 py-4 space-y-3">
        {messages.length === 0 && (
          <p className="text-center text-sm text-muted-foreground pt-12">Say hello 👋</p>
        )}
        {messages.map((msg) => {
          const isOwn = msg.sender_id === currentUserId
          return (
            <div key={msg.id} className={`flex items-end gap-2 ${isOwn ? 'justify-end' : 'justify-start'}`}>
              {!isOwn && (
                <div className="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0 mb-0.5">
                  {otherUser.avatar_url ? (
                    <Image src={otherUser.avatar_url} alt="" width={24} height={24} className="rounded-full object-cover" />
                  ) : (
                    <User className="w-3 h-3 text-muted-foreground" />
                  )}
                </div>
              )}

              {msg.message_type === 'image' && msg.media_url ? (
                <a
                  href={msg.media_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={`max-w-[72%] rounded-2xl overflow-hidden block ${isOwn ? 'rounded-br-sm' : 'rounded-bl-sm'}`}
                >
                  <Image
                    src={msg.media_url}
                    alt="Image"
                    width={240}
                    height={240}
                    className="object-cover max-h-60 w-auto"
                    unoptimized
                  />
                </a>
              ) : (
                <div className={[
                  'max-w-[72%] px-4 py-2.5 rounded-2xl text-sm leading-relaxed whitespace-pre-wrap break-words',
                  isOwn
                    ? 'bg-[var(--brand-primary)] text-white rounded-br-sm'
                    : 'bg-white/10 text-foreground rounded-bl-sm',
                ].join(' ')}>
                  {linkify(msg.content)}
                </div>
              )}
            </div>
          )
        })}
      </div>

      {/* Image preview strip */}
      {imagePreview && (
        <div className="px-4 py-2 border-t border-white/10 bg-background flex-shrink-0">
          <div className="relative inline-block">
            <Image src={imagePreview.url} alt="Preview" width={80} height={80} className="rounded-xl object-cover h-20 w-auto" unoptimized />
            <button
              onClick={() => setImagePreview(null)}
              className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full bg-slate-700 border border-white/20 flex items-center justify-center hover:bg-slate-600 transition-colors"
            >
              <X className="w-3 h-3" />
            </button>
          </div>
        </div>
      )}

      {/* Input bar */}
      <div className="flex items-center gap-2 px-4 py-3 border-t border-white/10 bg-background flex-shrink-0 pb-safe">
        <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={handleFileSelect} />
        <button
          onClick={() => fileRef.current?.click()}
          className="w-10 h-10 flex items-center justify-center rounded-xl border border-white/10 bg-white/5 text-muted-foreground hover:text-foreground hover:bg-white/10 transition-colors flex-shrink-0"
        >
          <ImageIcon className="w-4 h-4" />
        </button>
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSend() } }}
          disabled={!!imagePreview}
          placeholder={imagePreview ? 'Press send to share image…' : 'Message…'}
          className="flex-1 rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)] disabled:opacity-50"
        />
        <button
          onClick={handleSend}
          disabled={(!input.trim() && !imagePreview) || sending || uploading}
          className="w-10 h-10 flex items-center justify-center rounded-xl bg-[var(--brand-primary)] text-white hover:opacity-90 disabled:opacity-40 transition-opacity flex-shrink-0"
        >
          {uploading ? (
            <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
          ) : (
            <Send className="w-4 h-4" />
          )}
        </button>
      </div>
    </div>
  )
}
