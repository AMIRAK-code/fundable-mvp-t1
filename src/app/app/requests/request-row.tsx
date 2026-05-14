'use client'

import { useTransition } from 'react'
import Image from 'next/image'
import { User, Check, X } from 'lucide-react'
import { acceptConnection, declineConnection } from '@/app/actions/requests'

interface Props {
  connectionId: string
  profile: { id: string; full_name: string | null; avatar_url: string | null } | null
  createdAt: string
}

export default function RequestRow({ connectionId, profile, createdAt }: Props) {
  const [accepting, startAccept] = useTransition()
  const [declining, startDecline] = useTransition()

  return (
    <div className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/5 p-4">
      {profile?.avatar_url ? (
        <Image
          src={profile.avatar_url}
          alt={profile.full_name ?? ''}
          width={44}
          height={44}
          className="rounded-full object-cover flex-shrink-0"
        />
      ) : (
        <div className="w-11 h-11 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0">
          <User className="w-5 h-5 text-muted-foreground" />
        </div>
      )}

      <div className="flex-1 min-w-0">
        <p className="font-semibold text-sm truncate">{profile?.full_name ?? 'Unknown'}</p>
        <p className="text-xs text-muted-foreground mt-0.5">
          {new Date(createdAt).toLocaleDateString()}
        </p>
      </div>

      <div className="flex gap-2 flex-shrink-0">
        <button
          disabled={accepting || declining}
          onClick={() => startAccept(() => { acceptConnection(connectionId) })}
          className="flex items-center gap-1 text-xs font-semibold text-white bg-[var(--brand-primary)] px-3 py-1.5 rounded-lg hover:opacity-90 disabled:opacity-50 transition-opacity"
        >
          <Check className="w-3.5 h-3.5" />
          {accepting ? '…' : 'Accept'}
        </button>
        <button
          disabled={accepting || declining}
          onClick={() => startDecline(() => { declineConnection(connectionId) })}
          className="flex items-center gap-1 text-xs font-semibold text-muted-foreground border border-white/10 bg-white/5 px-3 py-1.5 rounded-lg hover:text-foreground disabled:opacity-50 transition-colors"
        >
          <X className="w-3.5 h-3.5" />
          {declining ? '…' : 'Decline'}
        </button>
      </div>
    </div>
  )
}
