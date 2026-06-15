'use client'

import { useState, useTransition } from 'react'
import Link from 'next/link'
import { UserPlus, Clock, CheckCircle, Ban } from 'lucide-react'
import { toast } from 'sonner'
import { sendConnect } from '@/app/actions/connect'
import type { ConnectionStatus } from '@/lib/supabase/types'

interface Props {
  receiverId: string
  status: ConnectionStatus | null
  /** Display name of the other person, used for accessible labels */
  name?: string | null
}

export default function ConnectButton({ receiverId, status, name }: Props) {
  // Optimistic local flag: flips to pending the instant the user taps,
  // reverts only if the server action reports an error.
  const [sent, setSent] = useState(false)
  const [, startTransition] = useTransition()

  const who = name || 'this user'
  const effectiveStatus: ConnectionStatus | null = status ?? (sent ? 'pending' : null)

  if (effectiveStatus === 'accepted') {
    return (
      <Link
        href="/app/messages"
        aria-label={`Connected with ${who} — open messages`}
        className="flex items-center gap-1.5 text-xs font-semibold text-[var(--brand-success)] bg-[var(--brand-success)]/10 px-3 py-1.5 rounded-lg press focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-success)]"
      >
        <CheckCircle className="w-3.5 h-3.5" />
        Connected
      </Link>
    )
  }

  if (effectiveStatus === 'pending') {
    return (
      <span
        aria-label={`Connection request with ${who} is pending`}
        className={`flex items-center gap-1.5 text-xs font-semibold text-muted-foreground bg-white/5 px-3 py-1.5 rounded-lg ${sent ? 'animate-pop' : ''}`}
      >
        <Clock className="w-3.5 h-3.5" />
        Pending
      </span>
    )
  }

  if (effectiveStatus === 'declined') {
    // Terminal: a declined sender cannot re-send (unique constraint on the pair)
    return (
      <span
        aria-label={`${who} is unavailable to connect`}
        className="flex items-center gap-1.5 text-xs font-semibold text-muted-foreground/70 bg-white/5 border border-white/10 px-3 py-1.5 rounded-lg cursor-default"
      >
        <Ban className="w-3.5 h-3.5" />
        Unavailable
      </span>
    )
  }

  const handleConnect = () => {
    setSent(true)
    startTransition(async () => {
      const { error } = await sendConnect(receiverId)
      if (error) {
        setSent(false)
        toast.error(error)
      } else {
        toast.success('Request sent')
      }
    })
  }

  return (
    <button
      onClick={handleConnect}
      aria-label={`Send connection request to ${who}`}
      className="flex items-center gap-1.5 text-xs font-semibold text-white bg-[var(--brand-primary)] hover:opacity-90 px-3 py-1.5 rounded-lg press focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] focus-visible:ring-offset-2 focus-visible:ring-offset-slate-900"
    >
      <UserPlus className="w-3.5 h-3.5" />
      Connect
    </button>
  )
}
