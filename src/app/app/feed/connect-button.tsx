'use client'

import { useTransition } from 'react'
import { UserPlus, Clock, CheckCircle } from 'lucide-react'
import { sendConnect } from '@/app/actions/connect'
import type { ConnectionStatus } from '@/lib/supabase/types'

interface Props {
  receiverId: string
  status: ConnectionStatus | null
}

export default function ConnectButton({ receiverId, status }: Props) {
  const [pending, startTransition] = useTransition()

  if (status === 'accepted') {
    return (
      <span className="flex items-center gap-1.5 text-xs font-semibold text-[var(--brand-success)] bg-[var(--brand-success)]/10 px-3 py-1.5 rounded-lg">
        <CheckCircle className="w-3.5 h-3.5" />
        Connected
      </span>
    )
  }

  if (status === 'pending') {
    return (
      <span className="flex items-center gap-1.5 text-xs font-semibold text-muted-foreground bg-white/5 px-3 py-1.5 rounded-lg">
        <Clock className="w-3.5 h-3.5" />
        Pending
      </span>
    )
  }

  return (
    <button
      disabled={pending}
      onClick={() => startTransition(() => { sendConnect(receiverId) })}
      className="flex items-center gap-1.5 text-xs font-semibold text-white bg-[var(--brand-primary)] hover:opacity-90 disabled:opacity-50 px-3 py-1.5 rounded-lg transition-opacity"
    >
      <UserPlus className="w-3.5 h-3.5" />
      {pending ? 'Sending…' : 'Connect'}
    </button>
  )
}
