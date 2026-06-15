'use client'

import { useState, useTransition } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import { User, Check, X, Loader2, MessageSquare } from 'lucide-react'
import { toast } from 'sonner'
import { timeAgo } from '@/lib/time'
import { acceptConnection, declineConnection } from '@/app/actions/requests'

interface Props {
  connectionId: string
  profile: { id: string; full_name: string | null; avatar_url: string | null } | null
  createdAt: string
}

type View = 'pending' | 'accepted' | 'collapsing' | 'hidden'

export default function RequestRow({ connectionId, profile, createdAt }: Props) {
  const [view, setView] = useState<View>('pending')
  const [syncing, setSyncing] = useState(false)
  const [, startTransition] = useTransition()

  function handleAccept() {
    setView('accepted') // optimistic morph
    setSyncing(true)
    startTransition(async () => {
      const { error } = await acceptConnection(connectionId)
      setSyncing(false)
      if (error) {
        setView('pending')
        toast.error(error)
      }
    })
  }

  function handleDecline() {
    setView('collapsing') // optimistic fade + collapse
    setSyncing(true)
    startTransition(async () => {
      const { error } = await declineConnection(connectionId)
      setSyncing(false)
      if (error) {
        setView('pending')
        toast.error(error)
      } else {
        setView('hidden')
      }
    })
  }

  if (view === 'hidden') return null

  const name = profile?.full_name ?? 'Unknown'

  return (
    <div
      className={`overflow-hidden transition-all duration-300 ease-out ${
        view === 'collapsing' ? 'opacity-0 max-h-0 scale-[0.98]' : 'opacity-100 max-h-32'
      }`}
    >
      <div
        className={`flex items-center gap-3 rounded-2xl border p-4 animate-in-up transition-colors ${
          view === 'accepted'
            ? 'border-[var(--brand-success)]/30 bg-[var(--brand-success)]/5'
            : 'border-white/10 bg-white/5'
        }`}
      >
        {profile?.avatar_url ? (
          <Image
            src={profile.avatar_url}
            alt={name}
            width={44}
            height={44}
            className="rounded-full object-cover flex-shrink-0 w-11 h-11"
          />
        ) : (
          <div className="w-11 h-11 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0">
            <User className="w-5 h-5 text-muted-foreground" />
          </div>
        )}

        <div className="flex-1 min-w-0">
          <p className="font-semibold text-sm truncate">{name}</p>
          <p className="text-xs text-muted-foreground mt-0.5">
            {view === 'accepted' ? (
              <span className="inline-flex items-center gap-1 text-[var(--brand-success)] font-semibold animate-pop">
                <Check className="w-3 h-3" />
                Connected
              </span>
            ) : (
              timeAgo(createdAt)
            )}
          </p>
        </div>

        {view === 'accepted' ? (
          <div className="flex items-center gap-2 flex-shrink-0 animate-pop">
            {syncing && (
              <Loader2 className="w-3.5 h-3.5 animate-spin text-muted-foreground" aria-hidden />
            )}
            <Link
              href="/app/messages"
              className="press flex items-center gap-1.5 text-xs font-semibold text-white bg-[var(--brand-primary)] px-3 py-1.5 rounded-lg hover:opacity-90 transition-opacity"
              aria-label={`Message ${name}`}
            >
              <MessageSquare className="w-3.5 h-3.5" />
              Message
            </Link>
          </div>
        ) : (
          <div className="flex gap-2 flex-shrink-0">
            <button
              disabled={view !== 'pending' || syncing}
              onClick={handleAccept}
              aria-label={`Accept request from ${name}`}
              className="press flex items-center gap-1 text-xs font-semibold text-white bg-[var(--brand-primary)] px-3 py-1.5 rounded-lg hover:opacity-90 disabled:opacity-50 transition-opacity"
            >
              {syncing ? (
                <Loader2 className="w-3.5 h-3.5 animate-spin" aria-hidden />
              ) : (
                <Check className="w-3.5 h-3.5" aria-hidden />
              )}
              Accept
            </button>
            <button
              disabled={view !== 'pending' || syncing}
              onClick={handleDecline}
              aria-label={`Decline request from ${name}`}
              className="press flex items-center gap-1 text-xs font-semibold text-muted-foreground border border-white/10 bg-white/5 px-3 py-1.5 rounded-lg hover:text-foreground disabled:opacity-50 transition-colors"
            >
              <X className="w-3.5 h-3.5" aria-hidden />
              Decline
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
