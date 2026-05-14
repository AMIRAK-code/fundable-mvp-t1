'use client'

import { useActionState, useEffect, useRef, useState } from 'react'
import Image from 'next/image'
import { X, Camera } from 'lucide-react'
import { upsertStartup } from '@/app/actions/profile'
import type { Startup } from '@/lib/supabase/types'

interface Props {
  open: boolean
  onOpenChange: (open: boolean) => void
  startup: Startup | null
}

const INIT = { error: null as string | null, success: false }

export default function StartupDialog({ open, onOpenChange, startup }: Props) {
  const [state, action, pending] = useActionState(upsertStartup, INIT)
  const fileRef = useRef<HTMLInputElement>(null)
  const [preview, setPreview] = useState<string | null>(null)

  // Close on success
  useEffect(() => {
    if (state.success) {
      onOpenChange(false)
      setPreview(null)
    }
  }, [state.success, onOpenChange])

  // Reset preview when dialog closes
  useEffect(() => {
    if (!open) setPreview(null)
  }, [open])

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={() => onOpenChange(false)}
      />

      {/* Panel */}
      <div className="relative w-full sm:max-w-md bg-slate-900 border border-white/10 rounded-t-2xl sm:rounded-2xl p-6 z-10 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-5">
          <h3 className="font-semibold text-lg">
            {startup ? 'Edit Startup' : 'Add Startup'}
          </h3>
          <button
            onClick={() => onOpenChange(false)}
            className="text-muted-foreground hover:text-foreground transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form action={action} className="space-y-4">
          {startup && <input type="hidden" name="id" value={startup.id} />}

          {/* Hero image */}
          <div className="flex flex-col items-center gap-2">
            <button
              type="button"
              onClick={() => fileRef.current?.click()}
              className="relative w-full h-32 rounded-xl border-2 border-dashed border-white/20 hover:border-[var(--brand-primary)] transition-colors overflow-hidden bg-white/5 flex items-center justify-center"
            >
              {preview || startup?.hero_image_url ? (
                <Image
                  src={preview ?? startup!.hero_image_url!}
                  alt="Hero preview"
                  fill
                  className="object-cover"
                />
              ) : (
                <span className="flex flex-col items-center gap-1 text-muted-foreground">
                  <Camera className="w-6 h-6" />
                  <span className="text-xs">Upload hero image</span>
                </span>
              )}
            </button>
            <input
              ref={fileRef}
              name="hero_image"
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => {
                const f = e.target.files?.[0]
                if (f) setPreview(URL.createObjectURL(f))
              }}
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">
              Startup name <span className="text-destructive">*</span>
            </label>
            <input
              name="name"
              required
              defaultValue={startup?.name}
              placeholder="Acme AI"
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">
              One-line pitch <span className="text-destructive">*</span>
            </label>
            <input
              name="pitch"
              required
              defaultValue={startup?.pitch}
              placeholder="We automate X for Y companies"
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-sm text-muted-foreground">Industry</label>
            <input
              name="industry"
              defaultValue={startup?.industry ?? ''}
              placeholder="B2B SaaS, FinTech, HealthTech…"
              className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
            />
          </div>

          {state.error && (
            <p className="text-sm text-destructive rounded-lg bg-destructive/10 px-4 py-2.5">
              {state.error}
            </p>
          )}

          <button
            type="submit"
            disabled={pending}
            className="w-full rounded-xl bg-[var(--brand-primary)] py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity"
          >
            {pending ? 'Saving…' : startup ? 'Save Changes' : 'Add Startup'}
          </button>
        </form>
      </div>
    </div>
  )
}
