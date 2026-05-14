'use client'

import { useActionState, useRef, useState } from 'react'
import Image from 'next/image'
import { Camera } from 'lucide-react'
import { updateProfile } from '@/app/actions/auth'
import type { Role } from '@/lib/supabase/types'

export default function OnboardingForm({ role }: { role: Role }) {
  const [state, action, pending] = useActionState(updateProfile, { error: null })
  const fileRef = useRef<HTMLInputElement>(null)
  const [preview, setPreview] = useState<string | null>(null)

  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (file) setPreview(URL.createObjectURL(file))
  }

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8">
      <p className="text-sm text-muted-foreground mb-6">
        You signed up as a{' '}
        <span className="text-[var(--brand-primary)] font-semibold capitalize">{role}</span>.
        Fill in your details to appear in the feed.
      </p>

      <form action={action} className="space-y-5">
        {/* Avatar picker */}
        <div className="flex flex-col items-center gap-3">
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            className="relative w-20 h-20 rounded-full border-2 border-dashed border-white/20 hover:border-[var(--brand-primary)] transition-colors flex items-center justify-center overflow-hidden bg-white/5"
          >
            {preview ? (
              <Image src={preview} alt="Avatar preview" fill className="object-cover" />
            ) : (
              <Camera className="w-6 h-6 text-muted-foreground" />
            )}
          </button>
          <span className="text-xs text-muted-foreground">Upload photo (optional)</span>
          <input
            ref={fileRef}
            name="avatar"
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleFileChange}
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="full_name" className="text-sm text-muted-foreground">
            Full name <span className="text-destructive">*</span>
          </label>
          <input
            id="full_name"
            name="full_name"
            type="text"
            required
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
            placeholder={role === 'investor' ? 'Jane Smith' : 'Alex Chen'}
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="bio" className="text-sm text-muted-foreground">
            Bio
          </label>
          <textarea
            id="bio"
            name="bio"
            rows={3}
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)] resize-none"
            placeholder={
              role === 'investor'
                ? 'Partner at XYZ Ventures. Focus on B2B SaaS…'
                : 'Building the future of X. Previously at Y…'
            }
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
          {pending ? 'Saving…' : 'Complete Profile'}
        </button>
      </form>
    </div>
  )
}
