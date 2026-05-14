'use client'

import { useActionState, useEffect, useRef, useState } from 'react'
import Image from 'next/image'
import { X, Camera, Code2, Link2, Globe, ExternalLink } from 'lucide-react'
import { upsertStartup } from '@/app/actions/profile'
import type { Startup } from '@/lib/supabase/types'

interface Props {
  open: boolean
  onOpenChange: (open: boolean) => void
  startup: Startup | null
}

const INIT = { error: null as string | null, success: false }

const SOCIAL_FIELDS = [
  { key: 'github',    label: 'GitHub',    Icon: Code2,        placeholder: 'https://github.com/your-startup' },
  { key: 'linkedin',  label: 'LinkedIn',  Icon: Link2,        placeholder: 'https://linkedin.com/company/...' },
  { key: 'website',   label: 'Website',   Icon: Globe,        placeholder: 'https://yourstartup.com' },
  { key: 'instagram', label: 'Instagram', Icon: Camera,       placeholder: 'https://instagram.com/yourstartup' },
  { key: 'reddit',    label: 'Reddit',    Icon: ExternalLink, placeholder: 'https://reddit.com/r/yourstartup' },
]

export default function StartupDialog({ open, onOpenChange, startup }: Props) {
  const [state, action, pending] = useActionState(upsertStartup, INIT)
  const fileRef = useRef<HTMLInputElement>(null)
  const [preview, setPreview] = useState<string | null>(null)

  useEffect(() => {
    if (state.success) { onOpenChange(false); setPreview(null) }
  }, [state.success, onOpenChange])

  useEffect(() => {
    if (!open) setPreview(null)
  }, [open])

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => onOpenChange(false)} />
      <div className="relative w-full sm:max-w-md bg-slate-900 border border-white/10 rounded-t-2xl sm:rounded-2xl p-5 sm:p-6 pb-[max(1.25rem,env(safe-area-inset-bottom))] z-10 max-h-[92dvh] overflow-y-auto">
        <div className="flex items-center justify-between mb-5">
          <h3 className="font-semibold text-lg">{startup ? 'Edit Startup' : 'Add Startup'}</h3>
          <button onClick={() => onOpenChange(false)} className="text-muted-foreground hover:text-foreground transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form action={action} className="space-y-4">
          {startup && <input type="hidden" name="id" value={startup.id} />}

          {/* Hero image */}
          <div className="flex flex-col items-center gap-2">
            <button type="button" onClick={() => fileRef.current?.click()}
              className="relative w-full h-32 rounded-xl border-2 border-dashed border-white/20 hover:border-[var(--brand-primary)] transition-colors overflow-hidden bg-white/5 flex items-center justify-center">
              {preview || startup?.hero_image_url ? (
                <Image src={preview ?? startup!.hero_image_url!} alt="Hero preview" fill className="object-cover" />
              ) : (
                <span className="flex flex-col items-center gap-1 text-muted-foreground">
                  <Camera className="w-6 h-6" />
                  <span className="text-xs">Upload hero image</span>
                </span>
              )}
            </button>
            <input ref={fileRef} name="hero_image" type="file" accept="image/*" className="hidden"
              onChange={(e) => { const f = e.target.files?.[0]; if (f) setPreview(URL.createObjectURL(f)) }} />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">Startup name <span className="text-destructive">*</span></label>
            <input name="name" required defaultValue={startup?.name} placeholder="Acme AI"
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]" />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">One-line pitch <span className="text-destructive">*</span></label>
            <input name="pitch" required defaultValue={startup?.pitch} placeholder="We automate X for Y companies"
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]" />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">Industry</label>
            <input name="industry" defaultValue={startup?.industry ?? ''} placeholder="B2B SaaS, FinTech, HealthTech…"
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]" />
          </div>

          {/* Social links */}
          <div className="space-y-2 pt-1">
            <p className="text-sm text-muted-foreground font-medium">Links <span className="text-xs font-normal">(optional)</span></p>
            {SOCIAL_FIELDS.map(({ key, label, Icon, placeholder }) => (
              <div key={key} className="flex items-center gap-2">
                <div className="w-8 h-8 flex items-center justify-center rounded-lg bg-white/5 border border-white/10 flex-shrink-0">
                  <Icon className="w-3.5 h-3.5 text-muted-foreground" />
                </div>
                <input
                  name={`link_${key}`}
                  defaultValue={(startup?.links as Record<string, string>)?.[key] ?? ''}
                  placeholder={placeholder}
                  className="flex-1 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
                />
              </div>
            ))}
          </div>

          {state.error && (
            <p className="text-sm text-destructive rounded-lg bg-destructive/10 px-4 py-2.5">{state.error}</p>
          )}

          <button type="submit" disabled={pending}
            className="w-full rounded-xl bg-[var(--brand-primary)] py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity">
            {pending ? 'Saving…' : startup ? 'Save Changes' : 'Add Startup'}
          </button>
        </form>
      </div>
    </div>
  )
}
