'use client'

import { useState } from 'react'
import Image from 'next/image'
import { Building2, Code2, Link2, Globe, Camera, ExternalLink, ChevronDown } from 'lucide-react'
import ConnectButton from './connect-button'
import type { ConnectionStatus, Startup } from '@/lib/supabase/types'
import { STARTUP_STATUS_LABELS, STARTUP_STATUS_COLORS } from '@/lib/supabase/types'

// Joined profile shape returned by the feed query
interface FeedProfile {
  id: string
  full_name: string | null
  avatar_url: string | null
}

export type FeedStartup = Startup & { profiles: FeedProfile }

interface Props {
  startup: FeedStartup
  connection: { status: ConnectionStatus } | null
  /** True for the first card in the feed — preloads its hero image */
  priority?: boolean
}

const LINK_ICONS = [
  { key: 'github',    label: 'GitHub',    Icon: Code2 },
  { key: 'linkedin',  label: 'LinkedIn',  Icon: Link2 },
  { key: 'website',   label: 'Website',   Icon: Globe },
  { key: 'instagram', label: 'Instagram', Icon: Camera },
  { key: 'reddit',    label: 'Reddit',    Icon: ExternalLink },
]

export default function FounderCard({ startup, connection, priority = false }: Props) {
  const [expanded, setExpanded] = useState(false)
  const links = (startup.links ?? {}) as Record<string, string>
  const hasLinks = LINK_ICONS.some(({ key }) => links[key])

  const toggle = () => setExpanded((v) => !v)
  const onKeyDown = (e: React.KeyboardEvent<HTMLDivElement>) => {
    if (e.target !== e.currentTarget) return
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      toggle()
    }
  }

  return (
    <div className="rounded-2xl overflow-hidden border border-white/10 bg-slate-900 animate-in-up">
      {/* Main card — clickable to expand */}
      <div
        role="button"
        tabIndex={0}
        aria-expanded={expanded}
        aria-label={`${startup.name} — ${expanded ? 'collapse' : 'expand'} details`}
        onClick={toggle}
        onKeyDown={onKeyDown}
        className="relative min-h-56 cursor-pointer press-subtle focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[var(--brand-primary)]"
      >
        {startup.hero_image_url ? (
          <Image
            src={startup.hero_image_url}
            alt={startup.name}
            fill
            priority={priority}
            className="object-cover"
            sizes="(max-width: 512px) 100vw, 512px"
          />
        ) : (
          <div className="absolute inset-0 bg-gradient-to-br from-[var(--brand-primary)]/30 to-slate-900" />
        )}

        <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/30 to-transparent" />

        {/* Expand indicator */}
        <div className="absolute top-3 right-3">
          <span className={`flex items-center justify-center w-7 h-7 rounded-full bg-black/40 backdrop-blur-sm border border-white/10 text-white/60 transition-transform duration-300 ${expanded ? 'rotate-180' : ''}`}>
            <ChevronDown className="w-4 h-4" />
          </span>
        </div>

        <div className="relative h-full min-h-56 flex flex-col justify-end p-5">
          <div className="flex items-center gap-1.5 mb-2 flex-wrap">
            {startup.industry && (
              <span className="px-2.5 py-0.5 rounded-full bg-white/10 backdrop-blur-sm text-[10px] font-semibold uppercase tracking-wider text-white/70">
                {startup.industry}
              </span>
            )}
            {startup.status && (
              <span className={`px-2.5 py-0.5 rounded-full border backdrop-blur-sm text-[10px] font-semibold uppercase tracking-wider ${STARTUP_STATUS_COLORS[startup.status]}`}>
                {STARTUP_STATUS_LABELS[startup.status]}
              </span>
            )}
          </div>
          <h2 className="text-2xl font-bold text-white leading-tight">{startup.name}</h2>
          <p className="text-sm text-white/75 mt-1 line-clamp-1">{startup.pitch}</p>

          <div className="flex items-center justify-between mt-4">
            <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
              {startup.profiles.avatar_url ? (
                <Image src={startup.profiles.avatar_url} alt={startup.profiles.full_name ?? ''} width={24} height={24} className="rounded-full object-cover" />
              ) : (
                <div className="w-6 h-6 rounded-full bg-white/20 flex items-center justify-center">
                  <Building2 className="w-3 h-3 text-white/60" />
                </div>
              )}
              <span className="text-xs text-white/70 font-medium">{startup.profiles.full_name}</span>
            </div>
            <div onClick={(e) => e.stopPropagation()}>
              <ConnectButton receiverId={startup.profiles.id} status={connection?.status ?? null} name={startup.profiles.full_name} />
            </div>
          </div>
        </div>
      </div>

      {/* Expandable details panel — grid-rows trick handles any content height */}
      <div className={`grid transition-[grid-template-rows] duration-300 ease-in-out ${expanded ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'}`}>
        <div className="overflow-hidden min-h-0">
          <div className="p-5 border-t border-white/10 space-y-4">
            <p className="text-sm text-muted-foreground leading-relaxed">{startup.pitch}</p>

            {hasLinks && (
              <div className="space-y-2">
                <p className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">Links</p>
                <div className="flex flex-wrap gap-2">
                  {LINK_ICONS.map(({ key, label, Icon }) =>
                    links[key] ? (
                      <a
                        key={key}
                        href={links[key]}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/5 border border-white/10 text-xs text-muted-foreground hover:text-foreground hover:bg-white/10 transition-colors press-subtle focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
                        onClick={(e) => e.stopPropagation()}
                      >
                        <Icon className="w-3.5 h-3.5" />
                        {label}
                      </a>
                    ) : null
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
