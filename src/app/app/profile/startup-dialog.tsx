'use client'

import { useActionState, useEffect, useId, useRef, useState } from 'react'
import Image from 'next/image'
import { Camera, Code2, Link2, Globe, ExternalLink } from 'lucide-react'
import { toast } from 'sonner'
import { upsertStartup } from '@/app/actions/profile'
import type { Startup } from '@/lib/supabase/types'
import SheetDialog from './sheet-dialog'

const MAX_IMAGE_MB = 5
const PITCH_LIMIT = 200

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
] as const

export default function StartupDialog({ open, onOpenChange, startup }: Props) {
  const [state, action, pending] = useActionState(upsertStartup, INIT)
  const fileRef = useRef<HTMLInputElement>(null)
  const [preview, setPreview] = useState<string | null>(null)
  const [fileError, setFileError] = useState<string | null>(null)
  const [pitch, setPitch] = useState(startup?.pitch ?? '')
  const ids = useId()

  useEffect(() => {
    if (state.success) {
      toast.success(startup ? 'Startup updated' : 'Startup added')
      onOpenChange(false)
      setPreview(null)
    } else if (state.error) {
      toast.error(state.error)
    }
  }, [state, onOpenChange, startup])

  useEffect(() => {
    if (!open) {
      setPreview(null)
      setFileError(null)
      setPitch(startup?.pitch ?? '')
    }
  }, [open, startup])

  useEffect(() => {
    return () => {
      if (preview) URL.revokeObjectURL(preview)
    }
  }, [preview])

  function handleFile(e: React.ChangeEvent<HTMLInputElement>) {
    setFileError(null)
    const file = e.target.files?.[0]
    if (!file) return
    if (!file.type.startsWith('image/')) {
      setFileError('Please select an image file.')
      e.target.value = ''
      return
    }
    if (file.size > MAX_IMAGE_MB * 1024 * 1024) {
      setFileError(`Image must be under ${MAX_IMAGE_MB}MB.`)
      e.target.value = ''
      return
    }
    if (preview) URL.revokeObjectURL(preview)
    setPreview(URL.createObjectURL(file))
  }

  const pitchOver = pitch.trim().length > PITCH_LIMIT

  return (
    <SheetDialog
      open={open}
      onOpenChange={onOpenChange}
      title={startup ? 'Edit Startup' : 'Add Startup'}
      description={startup ? 'Update the details investors will see.' : 'Tell investors what you’re building.'}
    >
      <form action={action} className="space-y-4">
        {startup && <input type="hidden" name="id" value={startup.id} />}

        {/* Hero image */}
        <div className="space-y-2">
          <span className="text-sm text-muted-foreground" id={`${ids}-hero-label`}>
            Hero image
          </span>
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            aria-labelledby={`${ids}-hero-label`}
            className="relative w-full aspect-[16/9] sm:aspect-[16/7] rounded-xl border-2 border-dashed border-white/20 hover:border-[var(--brand-primary)] transition-colors overflow-hidden bg-white/5 flex items-center justify-center focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
          >
            {preview || startup?.hero_image_url ? (
              <Image
                src={preview ?? startup!.hero_image_url!}
                alt=""
                fill
                sizes="(min-width: 640px) 448px, 100vw"
                className="object-cover"
              />
            ) : (
              <span className="flex flex-col items-center gap-1 text-muted-foreground">
                <Camera className="w-6 h-6" aria-hidden="true" />
                <span className="text-xs">Upload hero image · PNG/JPG up to {MAX_IMAGE_MB}MB</span>
              </span>
            )}
          </button>
          <input
            ref={fileRef}
            name="hero_image"
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleFile}
          />
          {fileError && (
            <p role="alert" className="text-xs text-destructive">{fileError}</p>
          )}
        </div>

        <div className="space-y-1.5">
          <label htmlFor={`${ids}-name`} className="text-sm text-muted-foreground">
            Startup name <span className="text-destructive" aria-hidden="true">*</span>
          </label>
          <input
            id={`${ids}-name`}
            name="name"
            required
            maxLength={80}
            defaultValue={startup?.name}
            placeholder="Acme AI"
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
          />
        </div>

        <div className="space-y-1.5">
          <div className="flex items-baseline justify-between gap-3">
            <label htmlFor={`${ids}-pitch`} className="text-sm text-muted-foreground">
              One-line pitch <span className="text-destructive" aria-hidden="true">*</span>
            </label>
            <span className={`text-xs ${pitchOver ? 'text-destructive' : 'text-muted-foreground'}`}>
              {pitch.trim().length}/{PITCH_LIMIT}
            </span>
          </div>
          <input
            id={`${ids}-pitch`}
            name="pitch"
            required
            value={pitch}
            onChange={(e) => setPitch(e.target.value)}
            placeholder="We automate X for Y companies"
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
            aria-invalid={pitchOver || undefined}
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor={`${ids}-industry`} className="text-sm text-muted-foreground">
            Industry
          </label>
          <input
            id={`${ids}-industry`}
            name="industry"
            defaultValue={startup?.industry ?? ''}
            placeholder="B2B SaaS, FinTech, HealthTech…"
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
          />
        </div>

        {/* Social links */}
        <fieldset className="space-y-2 pt-1">
          <legend className="text-sm text-muted-foreground font-medium">
            Links <span className="text-xs font-normal">(optional)</span>
          </legend>
          {SOCIAL_FIELDS.map(({ key, label, Icon, placeholder }) => (
            <div key={key} className="flex items-center gap-2">
              <span
                aria-hidden="true"
                className="w-9 h-9 flex items-center justify-center rounded-lg bg-white/5 border border-white/10 flex-shrink-0"
              >
                <Icon className="w-4 h-4 text-muted-foreground" />
              </span>
              <input
                id={`${ids}-link-${key}`}
                name={`link_${key}`}
                type="url"
                inputMode="url"
                aria-label={`${label} URL`}
                defaultValue={(startup?.links as Record<string, string> | undefined)?.[key] ?? ''}
                placeholder={placeholder}
                className="flex-1 rounded-xl border border-white/10 bg-white/5 px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
              />
            </div>
          ))}
        </fieldset>

        <button
          type="submit"
          disabled={pending || pitchOver}
          aria-busy={pending}
          className="w-full rounded-xl bg-[var(--brand-primary)] py-3 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity min-h-[44px]"
        >
          {pending ? 'Saving…' : startup ? 'Save changes' : 'Add startup'}
        </button>
      </form>
    </SheetDialog>
  )
}
