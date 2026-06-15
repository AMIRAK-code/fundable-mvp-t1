'use client'

import { useState, useEffect, useRef, useMemo, useCallback, Fragment } from 'react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'
import {
  ArrowLeft,
  ArrowDown,
  Send,
  User,
  ImageIcon,
  X,
  ChevronDown,
  Briefcase,
  Code2,
  Link2,
  Globe,
  Camera,
  ExternalLink,
  Check,
  Clock,
  AlertCircle,
} from 'lucide-react'
import { toast } from 'sonner'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { createClient } from '@/lib/supabase/client'
import { notifyNewMessage } from '@/app/actions/push'
import { timeOfDay, dayLabel, sameDay } from '@/lib/time'
import type { SocialLinks, Role, StartupStatus, InvestorStatus } from '@/lib/supabase/types'
import {
  STARTUP_STATUS_LABELS,
  STARTUP_STATUS_COLORS,
  INVESTOR_STATUS_LABELS,
  INVESTOR_STATUS_COLORS,
} from '@/lib/supabase/types'

type MsgStatus = 'sending' | 'sent' | 'failed'

interface Msg {
  id: string
  sender_id: string
  content: string
  message_type: 'text' | 'image'
  media_url: string | null
  created_at: string
  status?: MsgStatus
}

interface FounderProfile {
  type: 'founder'
  startup: {
    id: string
    name: string
    pitch: string
    hero_image_url: string | null
    industry: string | null
    status: StartupStatus | null
    links: SocialLinks
  }
}

interface InvestorProfile {
  type: 'investor'
  detail: {
    id: string
    firm_name: string | null
    check_size: string | null
    sectors: string[] | null
    thesis: string | null
    status: InvestorStatus | null
  }
  offers: Array<{
    id: string
    title: string
    description: string
    amount: string | null
    stage: string | null
    sectors: string[] | null
    status: string
    links: SocialLinks
  }>
}

export type ProfileData = FounderProfile | InvestorProfile | null

const LINK_ICONS = [
  { key: 'github',    label: 'GitHub',    Icon: Code2 },
  { key: 'linkedin',  label: 'LinkedIn',  Icon: Link2 },
  { key: 'website',   label: 'Website',   Icon: Globe },
  { key: 'instagram', label: 'Instagram', Icon: Camera },
  { key: 'reddit',    label: 'Reddit',    Icon: ExternalLink },
]

interface Props {
  roomId: string
  currentUserId: string
  otherUser: { id: string; full_name: string | null; avatar_url: string | null; role?: Role }
  initialMessages: Msg[]
  profileData?: ProfileData
}

const URL_RE = /(https?:\/\/[^\s<>"{}|\\^`[\]]+)/g
const GROUP_WINDOW_MS = 2 * 60_000

function linkify(text: string) {
  // split with a capture group: odd indices are always the captured URLs,
  // which avoids the stateful lastIndex pitfall of .test() on a /g regex
  const parts = text.split(URL_RE)
  return parts.map((part, i) =>
    i % 2 === 1 ? (
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

function withinGroupWindow(a: Msg, b: Msg) {
  return Math.abs(new Date(b.created_at).getTime() - new Date(a.created_at).getTime()) < GROUP_WINDOW_MS
}

function FounderProfilePanel({ startup }: { startup: FounderProfile['startup'] }) {
  const links = (startup.links ?? {}) as Record<string, string>
  const hasLinks = LINK_ICONS.some(({ key }) => links[key])

  return (
    <>
      {startup.hero_image_url && (
        <div className="relative w-full h-28 rounded-xl overflow-hidden">
          <Image src={startup.hero_image_url} alt={startup.name} fill className="object-cover" sizes="(max-width: 512px) 100vw, 512px" />
        </div>
      )}
      <div>
        <p className="font-semibold text-foreground">{startup.name}</p>
        <div className="flex items-center gap-1.5 mt-1 flex-wrap">
          {startup.industry && (
            <span className="px-2 py-0.5 rounded-full bg-white/10 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">
              {startup.industry}
            </span>
          )}
          {startup.status && (
            <span className={`px-2 py-0.5 rounded-full border text-[10px] font-semibold uppercase tracking-wider ${STARTUP_STATUS_COLORS[startup.status]}`}>
              {STARTUP_STATUS_LABELS[startup.status]}
            </span>
          )}
        </div>
      </div>
      <p className="text-sm text-muted-foreground leading-relaxed">{startup.pitch}</p>
      {hasLinks && (
        <div className="space-y-1.5">
          <p className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">Links</p>
          <div className="flex flex-wrap gap-1.5">
            {LINK_ICONS.map(({ key, label, Icon }) =>
              links[key] ? (
                <a key={key} href={links[key]} target="_blank" rel="noopener noreferrer"
                  className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-white/5 border border-white/10 text-xs text-muted-foreground hover:text-foreground hover:bg-white/10 transition-colors press-subtle">
                  <Icon className="w-3.5 h-3.5" />{label}
                </a>
              ) : null
            )}
          </div>
        </div>
      )}
    </>
  )
}

function InvestorProfilePanel({ detail, offers }: { detail: InvestorProfile['detail']; offers: InvestorProfile['offers'] }) {
  return (
    <>
      {detail.status && (
        <span className={`inline-block px-2 py-0.5 rounded-full border text-[10px] font-semibold uppercase tracking-wider ${INVESTOR_STATUS_COLORS[detail.status]}`}>
          {INVESTOR_STATUS_LABELS[detail.status]}
        </span>
      )}
      {detail.check_size && (
        <p className="text-xs text-muted-foreground">Check size: <span className="text-foreground font-medium">{detail.check_size}</span></p>
      )}
      {detail.sectors && detail.sectors.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          {detail.sectors.map((s) => (
            <span key={s} className="px-2 py-0.5 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] text-[10px] font-semibold uppercase tracking-wide">{s}</span>
          ))}
        </div>
      )}
      {detail.thesis && (
        <div className="space-y-1">
          <p className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">Investment Thesis</p>
          <p className="text-sm text-muted-foreground leading-relaxed">{detail.thesis}</p>
        </div>
      )}
      {offers.length > 0 && (
        <div className="space-y-2">
          <p className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
            <Briefcase className="w-3 h-3" /> Active Offers
          </p>
          {offers.map((o) => {
            const ol = (o.links ?? {}) as Record<string, string>
            const offerHasLinks = LINK_ICONS.some(({ key }) => ol[key])
            return (
              <div key={o.id} className="rounded-xl bg-white/5 border border-white/10 p-3 space-y-2">
                <div className="flex items-baseline justify-between gap-2">
                  <p className="text-sm font-medium text-foreground">{o.title}</p>
                  {o.amount && <span className="text-xs text-[var(--brand-primary)] flex-shrink-0">{o.amount}</span>}
                </div>
                {(o.stage || (o.sectors && o.sectors.length > 0)) && (
                  <div className="flex items-center gap-2 flex-wrap">
                    {o.stage && <span className="text-[10px] text-muted-foreground">{o.stage}</span>}
                    {o.sectors?.map((s) => (
                      <span key={s} className="text-[10px] px-1.5 py-0.5 rounded-full bg-[var(--brand-success)]/10 text-[var(--brand-success)] font-semibold uppercase tracking-wide">{s}</span>
                    ))}
                  </div>
                )}
                {offerHasLinks && (
                  <div className="flex flex-wrap gap-1.5 pt-1">
                    {LINK_ICONS.map(({ key, label, Icon }) =>
                      ol[key] ? (
                        <a key={key} href={ol[key]} target="_blank" rel="noopener noreferrer"
                          className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-white/5 border border-white/10 text-xs text-muted-foreground hover:text-foreground hover:bg-white/10 transition-colors press-subtle">
                          <Icon className="w-3 h-3" />{label}
                        </a>
                      ) : null
                    )}
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}
    </>
  )
}

export default function ChatView({ roomId, currentUserId, otherUser, initialMessages, profileData }: Props) {
  const router = useRouter()
  const supabase = useMemo(() => createClient(), [])
  const [messages, setMessages] = useState<Msg[]>(initialMessages)
  const [input, setInput] = useState('')
  const [uploading, setUploading] = useState(false)
  const [imagePreview, setImagePreview] = useState<{ file: File; url: string } | null>(null)
  const [profileExpanded, setProfileExpanded] = useState(false)
  const [otherTyping, setOtherTyping] = useState(false)
  const [fabCount, setFabCount] = useState(0)

  const containerRef = useRef<HTMLDivElement>(null)
  const fileRef = useRef<HTMLInputElement>(null)
  const channelRef = useRef<RealtimeChannel | null>(null)
  const nearBottomRef = useRef(true)
  const hadDisconnectRef = useRef(false)
  const typingHideRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const lastTypingSentRef = useRef(0)
  const markReadTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const prevLenRef = useRef(initialMessages.length)
  const previewUrlRef = useRef<string | null>(null)
  const initialIdsRef = useRef(new Set(initialMessages.map((m) => m.id)))

  const lastOwnId = useMemo(() => {
    for (let i = messages.length - 1; i >= 0; i--) {
      if (messages[i].sender_id === currentUserId) return messages[i].id
    }
    return null
  }, [messages, currentUserId])

  const scrollToBottom = useCallback((behavior: ScrollBehavior = 'smooth') => {
    const el = containerRef.current
    if (el) el.scrollTo({ top: el.scrollHeight, behavior })
  }, [])

  // Debounced read receipt — own row only
  const markRead = useCallback(() => {
    if (markReadTimerRef.current) clearTimeout(markReadTimerRef.current)
    markReadTimerRef.current = setTimeout(() => {
      void supabase
        .from('message_reads')
        .upsert(
          { chat_room_id: roomId, user_id: currentUserId, last_read_at: new Date().toISOString() },
          { onConflict: 'chat_room_id,user_id' }
        )
        .then(() => {})
    }, 1000)
  }, [supabase, roomId, currentUserId])

  // Merge-dedupe the latest 50 messages after a realtime reconnect
  const refetchLatest = useCallback(async () => {
    const { data } = await supabase
      .from('messages')
      .select('id, sender_id, content, message_type, media_url, created_at')
      .eq('chat_room_id', roomId)
      .order('created_at', { ascending: false })
      .limit(50)
    if (!data) return
    const latest = ([...data] as Msg[]).reverse()
    setMessages((prev) => {
      const byId = new Map(prev.map((m) => [m.id, m]))
      let changed = false
      for (const m of latest) {
        const existing = byId.get(m.id)
        if (!existing) {
          byId.set(m.id, m)
          changed = true
        } else if (existing.status === 'sending') {
          byId.set(m.id, { ...m, status: 'sent' })
          changed = true
        }
      }
      if (!changed) return prev
      return Array.from(byId.values()).sort((a, b) => a.created_at.localeCompare(b.created_at))
    })
  }, [supabase, roomId])

  // Initial pin to bottom + read receipt on mount and when the tab regains focus
  useEffect(() => {
    scrollToBottom('auto')
    markRead()
    const onVisibility = () => {
      if (document.visibilityState === 'visible') markRead()
    }
    document.addEventListener('visibilitychange', onVisibility)
    return () => {
      document.removeEventListener('visibilitychange', onVisibility)
      if (markReadTimerRef.current) clearTimeout(markReadTimerRef.current)
      if (typingHideRef.current) clearTimeout(typingHideRef.current)
    }
  }, [scrollToBottom, markRead])

  // Smart scroll: follow new messages only when near bottom or it's our own
  useEffect(() => {
    const appended = messages.length - prevLenRef.current
    prevLenRef.current = messages.length
    if (appended <= 0) return
    const last = messages[messages.length - 1]
    if (last?.sender_id === currentUserId || nearBottomRef.current) {
      requestAnimationFrame(() => scrollToBottom('smooth'))
    } else {
      setFabCount((c) => c + appended)
    }
  }, [messages, currentUserId, scrollToBottom])

  // Keep the typing bubble in view when already at the bottom
  useEffect(() => {
    if (otherTyping && nearBottomRef.current) {
      requestAnimationFrame(() => scrollToBottom('smooth'))
    }
  }, [otherTyping, scrollToBottom])

  // Revoke any pending preview object URL on unmount
  useEffect(() => {
    previewUrlRef.current = imagePreview?.url ?? null
  }, [imagePreview])
  useEffect(() => () => {
    if (previewUrlRef.current) URL.revokeObjectURL(previewUrlRef.current)
  }, [])

  // Single realtime channel: postgres INSERTs + typing broadcasts + reconnect recovery
  useEffect(() => {
    const channel = supabase
      .channel(`room-${roomId}`)
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'messages', filter: `chat_room_id=eq.${roomId}` },
        (payload) => {
          const newMsg = payload.new as Msg
          setMessages((prev) => {
            const idx = prev.findIndex((m) => m.id === newMsg.id)
            if (idx !== -1) {
              // confirms our own optimistic message — adopt server row, mark sent
              const next = [...prev]
              next[idx] = { ...newMsg, status: 'sent' }
              return next
            }
            return [...prev, newMsg.sender_id === currentUserId ? { ...newMsg, status: 'sent' } : newMsg]
          })
          if (newMsg.sender_id !== currentUserId) {
            setOtherTyping(false)
            if (typingHideRef.current) clearTimeout(typingHideRef.current)
            if (document.visibilityState === 'visible') markRead()
          }
        }
      )
      .on('broadcast', { event: 'typing' }, (msg) => {
        const fromId = (msg as { payload?: { userId?: string } }).payload?.userId
        if (!fromId || fromId === currentUserId) return
        setOtherTyping(true)
        if (typingHideRef.current) clearTimeout(typingHideRef.current)
        typingHideRef.current = setTimeout(() => setOtherTyping(false), 3000)
      })
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          if (hadDisconnectRef.current) {
            hadDisconnectRef.current = false
            refetchLatest()
          }
        } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
          hadDisconnectRef.current = true
        }
      })
    channelRef.current = channel
    return () => {
      channelRef.current = null
      supabase.removeChannel(channel)
    }
  }, [roomId, supabase, currentUserId, markRead, refetchLatest])

  function handleScroll() {
    const el = containerRef.current
    if (!el) return
    const near = el.scrollHeight - el.scrollTop - el.clientHeight < 120
    nearBottomRef.current = near
    if (near) setFabCount(0)
  }

  function handleInputChange(e: React.ChangeEvent<HTMLInputElement>) {
    setInput(e.target.value)
    const now = Date.now()
    if (now - lastTypingSentRef.current < 2000) return
    lastTypingSentRef.current = now
    channelRef.current?.send({ type: 'broadcast', event: 'typing', payload: { userId: currentUserId } })
  }

  async function insertMessage(msg: Msg) {
    const { error } = await supabase.from('messages').insert({
      id: msg.id,
      chat_room_id: roomId,
      sender_id: currentUserId,
      content: msg.content,
      message_type: msg.message_type,
      media_url: msg.media_url,
    })
    if (error) {
      setMessages((prev) => prev.map((m) => (m.id === msg.id ? { ...m, status: 'failed' as const } : m)))
      toast.error('Message not sent — tap it to retry')
      return
    }
    setMessages((prev) => prev.map((m) => (m.id === msg.id && m.status === 'sending' ? { ...m, status: 'sent' as const } : m)))
    notifyNewMessage(otherUser.id, msg.message_type === 'image' ? '📷 Photo' : msg.content.slice(0, 100), roomId)
  }

  function retryMessage(msg: Msg) {
    if (msg.status !== 'failed') return
    setMessages((prev) => prev.map((m) => (m.id === msg.id ? { ...m, status: 'sending' as const } : m)))
    insertMessage(msg)
  }

  async function handleSend() {
    if (imagePreview) { await handleImageSend(imagePreview.file); return }
    const text = input.trim()
    if (!text) return
    setInput('')
    const optimistic: Msg = {
      id: crypto.randomUUID(),
      sender_id: currentUserId,
      content: text,
      message_type: 'text',
      media_url: null,
      created_at: new Date().toISOString(),
      status: 'sending',
    }
    setMessages((prev) => [...prev, optimistic])
    await insertMessage(optimistic)
  }

  async function handleImageSend(file: File) {
    if (uploading) return
    setUploading(true)
    const ext = file.name.split('.').pop() ?? 'jpg'
    const path = `${roomId}/${Date.now()}.${ext}`
    const { error: uploadError } = await supabase.storage.from('message-media').upload(path, file)
    if (uploadError) {
      // keep the preview so the user can simply press send again
      setUploading(false)
      toast.error('Upload failed — tap send to retry')
      return
    }
    const { data: { publicUrl } } = supabase.storage.from('message-media').getPublicUrl(path)
    clearPreview()
    setUploading(false)
    const optimistic: Msg = {
      id: crypto.randomUUID(),
      sender_id: currentUserId,
      content: '',
      message_type: 'image',
      media_url: publicUrl,
      created_at: new Date().toISOString(),
      status: 'sending',
    }
    setMessages((prev) => [...prev, optimistic])
    await insertMessage(optimistic)
  }

  function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    if (imagePreview) URL.revokeObjectURL(imagePreview.url)
    setImagePreview({ file, url: URL.createObjectURL(file) })
    e.target.value = ''
  }

  function clearPreview() {
    if (imagePreview) URL.revokeObjectURL(imagePreview.url)
    setImagePreview(null)
  }

  const miniAvatar = otherUser.avatar_url ? (
    <Image src={otherUser.avatar_url} alt="" width={24} height={24} className="w-6 h-6 rounded-full object-cover flex-shrink-0 mb-0.5" />
  ) : (
    <div className="w-6 h-6 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0 mb-0.5">
      <User className="w-3 h-3 text-muted-foreground" />
    </div>
  )

  return (
    <div className="flex flex-col h-[calc(100dvh-64px-env(safe-area-inset-bottom))] bg-background">
      {/* Header */}
      <header className="border-b border-white/10 bg-background/95 backdrop-blur-md flex-shrink-0">
        <div className="flex items-center gap-3 px-3 sm:px-4 py-2.5 pt-[calc(env(safe-area-inset-top)+0.625rem)]">
          <button
            onClick={() => router.back()}
            aria-label="Go back"
            className="text-muted-foreground hover:text-foreground transition-colors p-1 press-subtle"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <button
            type="button"
            onClick={() => profileData && setProfileExpanded((v) => !v)}
            disabled={!profileData}
            aria-expanded={profileExpanded}
            aria-label={profileData ? (profileExpanded ? 'Hide profile details' : 'Show profile details') : undefined}
            className={`flex items-center gap-3 flex-1 min-w-0 text-left ${profileData ? 'cursor-pointer press-subtle' : 'cursor-default'}`}
          >
            {otherUser.avatar_url ? (
              <Image src={otherUser.avatar_url} alt={otherUser.full_name ?? ''} width={36} height={36} className="w-9 h-9 rounded-full object-cover flex-shrink-0" />
            ) : (
              <div className="w-9 h-9 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0">
                <User className="w-4 h-4 text-muted-foreground" />
              </div>
            )}
            <div className="flex-1 min-w-0">
              <span className="font-semibold truncate block">{otherUser.full_name}</span>
              {profileData?.type === 'investor' && profileData.detail.firm_name && (
                <span className="text-xs text-[var(--brand-primary)] truncate block">{profileData.detail.firm_name}</span>
              )}
              {profileData?.type === 'founder' && profileData.startup.name && (
                <span className="text-xs text-[var(--brand-primary)] truncate block">{profileData.startup.name}</span>
              )}
            </div>
            {profileData && (
              <span className={`text-muted-foreground transition-transform duration-300 flex-shrink-0 ${profileExpanded ? 'rotate-180' : ''}`}>
                <ChevronDown className="w-4 h-4" />
              </span>
            )}
          </button>
        </div>

        {/* Expandable profile panel */}
        <div className={`overflow-hidden transition-all duration-300 ease-in-out ${profileExpanded ? 'max-h-[500px]' : 'max-h-0'}`}>
          <div className="px-4 pb-4 space-y-3 border-t border-white/10 pt-3">
            {profileData?.type === 'founder' && <FounderProfilePanel startup={profileData.startup} />}
            {profileData?.type === 'investor' && <InvestorProfilePanel detail={profileData.detail} offers={profileData.offers} />}
          </div>
        </div>
      </header>

      {/* Messages */}
      <div className="relative flex-1 min-h-0">
        <div
          ref={containerRef}
          onScroll={handleScroll}
          role="log"
          aria-live="polite"
          aria-label="Messages"
          className="h-full overflow-y-auto px-4 py-4"
        >
          {messages.length === 0 && !otherTyping && (
            <p className="text-center text-sm text-muted-foreground pt-12 animate-in-up">Say hello 👋</p>
          )}
          {messages.map((msg, i) => {
            const prev = messages[i - 1]
            const next = messages[i + 1]
            const isOwn = msg.sender_id === currentUserId
            const newDay = !prev || !sameDay(prev.created_at, msg.created_at)
            const isFirstOfGroup =
              newDay || prev.sender_id !== msg.sender_id || !withinGroupWindow(prev, msg)
            const isLastOfGroup =
              !next || next.sender_id !== msg.sender_id || !withinGroupWindow(msg, next) || !sameDay(msg.created_at, next.created_at)
            const corners = isOwn
              ? `${isFirstOfGroup ? '' : 'rounded-tr-md'} ${isLastOfGroup ? 'rounded-br-sm' : 'rounded-br-md'}`
              : `${isFirstOfGroup ? '' : 'rounded-tl-md'} ${isLastOfGroup ? 'rounded-bl-sm' : 'rounded-bl-md'}`
            const entrance = initialIdsRef.current.has(msg.id) ? '' : 'animate-pop'

            return (
              <Fragment key={msg.id}>
                {newDay && (
                  <div className="flex justify-center pt-4 pb-2">
                    <span className="px-2.5 py-0.5 rounded-full text-[10px] font-semibold uppercase tracking-wider bg-white/5 border border-white/10 text-muted-foreground">
                      {dayLabel(msg.created_at)}
                    </span>
                  </div>
                )}
                <div className={isFirstOfGroup ? 'mt-3' : 'mt-0.5'}>
                  <div className={`flex items-end gap-2 ${isOwn ? 'justify-end' : 'justify-start'}`}>
                    {!isOwn && (isLastOfGroup ? miniAvatar : <div className="w-6 flex-shrink-0" aria-hidden="true" />)}

                    {msg.message_type === 'image' && msg.media_url ? (
                      <a
                        href={msg.media_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className={`max-w-[72%] rounded-2xl overflow-hidden block ${corners} ${entrance} ${msg.status === 'sending' ? 'opacity-70' : ''}`}
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
                        corners,
                        entrance,
                        msg.status === 'sending' ? 'opacity-70' : '',
                        isOwn
                          ? 'bg-[var(--brand-primary)] text-white'
                          : 'bg-white/10 text-foreground',
                      ].join(' ')}>
                        {linkify(msg.content)}
                      </div>
                    )}
                  </div>

                  {msg.status === 'failed' ? (
                    <div className="flex justify-end mt-1 px-1">
                      <button
                        onClick={() => retryMessage(msg)}
                        aria-label="Message failed to send. Tap to retry"
                        className="flex items-center gap-1 text-[10px] font-medium text-red-400 press-subtle"
                      >
                        <AlertCircle className="w-3 h-3" />
                        Tap to retry
                      </button>
                    </div>
                  ) : isLastOfGroup ? (
                    isOwn ? (
                      <div className="flex items-center justify-end gap-1 mt-1 px-1 text-[10px] text-white/60">
                        <span>{timeOfDay(msg.created_at)}</span>
                        {msg.id === lastOwnId && (
                          msg.status === 'sending' ? (
                            <Clock className="w-3 h-3" aria-label="Sending" />
                          ) : (
                            <Check className="w-3 h-3" aria-label="Sent" />
                          )
                        )}
                      </div>
                    ) : (
                      <div className="mt-1 ml-8 px-1 text-[10px] text-muted-foreground">
                        {timeOfDay(msg.created_at)}
                      </div>
                    )
                  ) : null}
                </div>
              </Fragment>
            )
          })}

          {/* Typing indicator */}
          {otherTyping && (
            <div className="flex items-end gap-2 mt-3 animate-in-up">
              {miniAvatar}
              <div role="status" className="px-4 py-3 rounded-2xl rounded-bl-sm bg-white/10 flex items-center gap-1" aria-label={`${otherUser.full_name ?? 'They'} is typing`}>
                {[0, 1, 2].map((d) => (
                  <span
                    key={d}
                    className="w-1.5 h-1.5 rounded-full bg-white/40 animate-bounce"
                    style={{ animationDelay: `${d * 150}ms` }}
                  />
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Scroll-to-bottom FAB */}
        {fabCount > 0 && (
          <button
            onClick={() => { scrollToBottom('smooth'); setFabCount(0) }}
            aria-label={`Scroll to ${fabCount} new ${fabCount === 1 ? 'message' : 'messages'}`}
            className="absolute bottom-3 right-3 z-10 flex items-center gap-1.5 rounded-full bg-slate-800 border border-white/10 shadow-lg pl-2.5 pr-3 h-9 text-xs font-semibold text-foreground press animate-pop"
          >
            <ArrowDown className="w-4 h-4" />
            <span className="flex items-center justify-center bg-[var(--brand-primary)] text-white text-[10px] font-bold rounded-full min-w-[18px] h-[18px] px-1">
              {fabCount > 99 ? '99+' : fabCount}
            </span>
          </button>
        )}
      </div>

      {/* Image preview strip */}
      {imagePreview && (
        <div className="px-4 py-2 border-t border-white/10 bg-background flex-shrink-0 animate-in-up">
          <div className="relative inline-block">
            <Image src={imagePreview.url} alt="Preview" width={80} height={80} className="rounded-xl object-cover h-20 w-auto" unoptimized />
            <button
              onClick={clearPreview}
              aria-label="Remove image preview"
              className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full bg-slate-700 border border-white/20 flex items-center justify-center hover:bg-slate-600 transition-colors press"
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
          aria-label="Attach image"
          className="w-10 h-10 flex items-center justify-center rounded-xl border border-white/10 bg-white/5 text-muted-foreground hover:text-foreground hover:bg-white/10 transition-colors flex-shrink-0 press"
        >
          <ImageIcon className="w-4 h-4" />
        </button>
        <input
          value={input}
          onChange={handleInputChange}
          onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSend() } }}
          disabled={!!imagePreview}
          placeholder={imagePreview ? 'Press send to share image…' : 'Message…'}
          aria-label="Message"
          className="flex-1 rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)] disabled:opacity-50"
        />
        <button
          onClick={handleSend}
          disabled={(!input.trim() && !imagePreview) || uploading}
          aria-label="Send message"
          className="w-10 h-10 flex items-center justify-center rounded-xl bg-[var(--brand-primary)] text-white hover:opacity-90 disabled:opacity-40 transition-opacity flex-shrink-0 press"
        >
          {uploading ? (
            <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" aria-hidden="true" />
          ) : (
            <Send className="w-4 h-4" />
          )}
        </button>
      </div>
    </div>
  )
}
