import Image from 'next/image'
import { Building2 } from 'lucide-react'
import ConnectButton from './connect-button'
import type { ConnectionStatus } from '@/lib/supabase/types'

interface Startup {
  id: string
  founder_id: string
  name: string
  pitch: string
  hero_image_url: string | null
  industry: string | null
  profiles: { id: string; full_name: string | null; avatar_url: string | null }
}

interface Props {
  startup: Startup
  connection: { status: ConnectionStatus } | null
}

export default function FounderCard({ startup, connection }: Props) {
  return (
    <div className="relative rounded-2xl overflow-hidden min-h-56 bg-slate-800 border border-white/10">
      {startup.hero_image_url ? (
        <Image
          src={startup.hero_image_url}
          alt={startup.name}
          fill
          className="object-cover"
          sizes="(max-width: 512px) 100vw, 512px"
        />
      ) : (
        <div className="absolute inset-0 bg-gradient-to-br from-[var(--brand-primary)]/30 to-slate-900" />
      )}

      {/* Gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/30 to-transparent" />

      {/* Content */}
      <div className="relative h-full min-h-56 flex flex-col justify-end p-5">
        {startup.industry && (
          <span className="self-start mb-2 px-2.5 py-0.5 rounded-full bg-white/10 backdrop-blur-sm text-[10px] font-semibold uppercase tracking-wider text-white/70">
            {startup.industry}
          </span>
        )}
        <h2 className="text-2xl font-bold text-white leading-tight">{startup.name}</h2>
        <p className="text-sm text-white/75 mt-1 line-clamp-1">{startup.pitch}</p>

        <div className="flex items-center justify-between mt-4">
          <div className="flex items-center gap-2">
            {startup.profiles.avatar_url ? (
              <Image
                src={startup.profiles.avatar_url}
                alt={startup.profiles.full_name ?? ''}
                width={24}
                height={24}
                className="rounded-full object-cover"
              />
            ) : (
              <div className="w-6 h-6 rounded-full bg-white/20 flex items-center justify-center">
                <Building2 className="w-3 h-3 text-white/60" />
              </div>
            )}
            <span className="text-xs text-white/70 font-medium">
              {startup.profiles.full_name}
            </span>
          </div>

          <ConnectButton
            receiverId={startup.profiles.id}
            status={connection?.status ?? null}
          />
        </div>
      </div>
    </div>
  )
}
