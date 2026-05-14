'use client'

import { useState } from 'react'
import Image from 'next/image'
import { Building2, Code2, Link2, Globe, Camera, ExternalLink, ChevronDown } from 'lucide-react'
import ConnectButton from './connect-button'
import type { ConnectionStatus, SocialLinks } from '@/lib/supabase/types'

interface Startup {
  id: string
  founder_id: string
  name: string
  pitch: string
  hero_image_url: string | null
  industry: string | null
  links: SocialLinks
  profiles: { id: string; full_name: string | null; avatar_url: string | null }
}

interface Props {
  startup: Startup
  connection: { status: ConnectionStatus } | null
}

const LINK_ICONS = [
  { key: 'github',    label: 'GitHub',    Icon: Code2 },
  { key: 'linkedin',  label: 'LinkedIn',  Icon: Link2 },
  { key: 'website',   label: 'Website',   Icon: Globe },
  { key: 'instagram', label: 'Instagram', Icon: Camera },
  { key: 'reddit',    label: 'Reddit',    Icon: ExternalLink },
]

export default function FounderCard({ startup, connection }: Props) {
  const [expanded, setExpanded] = useState(false)
  const links = (startup.links ?? {}) as Record<string, string>
  const hasLinks = LINK_ICONS.some(({ key }) => links[key])

  return (
    <div className="rounded-2xl overflow-hidden border border-white/10 bg-slate-900">
      {/* Main card — clickable to expand */}
      <div
        className="relative min-h-56 cursor-pointer"
        onClick={() => setExpanded((v) => !v)}
      >
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

        <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/30 to-transparent" />

        {/* Expand indicator */}
        <div className="absolute top-3 right-3">
          <span className={`flex items-center justify-center w-7 h-7 rounded-full bg-black/40 backdrop-blur-sm border border-white/10 text-white/60 transition-transform duration-300 ${expanded ? 'rotate-180' : ''}`}>
            <ChevronDown className="w-4 h-4" />
          </span>
        </div>

        <div className="relative h-full min-h-56 flex flex-col justify-end p-5">
          {startup.industry && (
            <span className="self-start mb-2 px-2.5 py-0.5 rounded-full bg-white/10 backdrop-blur-sm text-[10px] font-semibold uppercase tracking-wider text-white/70">
              {startup.industry}
            </span>
          )}
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
              <ConnectButton receiverId={startup.profiles.id} status={connection?.status ?? null} />
            </div>
          </div>
        </div>
      </div>

      {/* Expandable details panel */}
      <div className={`overflow-hidden transition-all duration-300 ease-in-out ${expanded ? 'max-h-96' : 'max-h-0'}`}>
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
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/5 border border-white/10 text-xs text-muted-foreground hover:text-foreground hover:bg-white/10 transition-colors"
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
  )
}
