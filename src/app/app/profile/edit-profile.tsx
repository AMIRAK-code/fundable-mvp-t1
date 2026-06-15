'use client'

import { useActionState, useEffect, useRef, useState } from 'react'
import Image from 'next/image'
import { Pencil, X, Camera, User, Loader2 } from 'lucide-react'
import { toast } from 'sonner'
import { updateProfile } from '@/app/actions/auth'

interface ProfileFields {
  full_name: string | null
  bio: string | null
  avatar_url: string | null
}

export default function EditProfile({ profile }: { profile: ProfileFields }) {
  const [open, setOpen] = useState(false)
  const [instance, setInstance] = useState(0)

  // Remount the form on every open so stale useActionState success can't
  // instantly re-close the dialog
  function openDialog() {
    setInstance((i) => i + 1)
    setOpen(true)
  }

  // Escape closes + body scroll lock
  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false)
    }
    document.addEventListener('keydown', onKey)
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', onKey)
      document.body.style.overflow = prev
    }
  }, [open])

  return (
    <>
      <button
        onClick={openDialog}
        aria-label="Edit profile"
        className="press flex items-center justify-center w-9 h-9 rounded-xl border border-white/10 bg-white/5 text-muted-foreground hover:text-foreground transition-colors flex-shrink-0"
      >
        <Pencil className="w-4 h-4" aria-hidden />
      </button>

      {open && (
        <div className="fixed inset-0 z-[60] flex items-end sm:items-center justify-center">
          <div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm animate-in fade-in-0 duration-200"
            onClick={() => setOpen(false)}
          />
          <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="edit-profile-title"
            className="relative w-full sm:max-w-md bg-slate-900 border border-white/10 rounded-t-2xl sm:rounded-2xl p-5 sm:p-6 pb-[max(1.25rem,env(safe-area-inset-bottom))] z-10 max-h-[100dvh] sm:max-h-[92dvh] overflow-y-auto overscroll-contain animate-in-up"
          >
            <div className="flex items-center justify-between mb-5">
              <h3 id="edit-profile-title" className="font-semibold text-lg">Edit Profile</h3>
              <button
                onClick={() => setOpen(false)}
                aria-label="Close dialog"
                className="press text-muted-foreground hover:text-foreground transition-colors"
              >
                <X className="w-5 h-5" aria-hidden />
              </button>
            </div>

            <EditProfileForm
              key={instance}
              profile={profile}
              onClose={() => setOpen(false)}
            />
          </div>
        </div>
      )}
    </>
  )
}

const INIT = { error: null as string | null, success: false as boolean | undefined }

function EditProfileForm({
  profile,
  onClose,
}: {
  profile: ProfileFields
  onClose: () => void
}) {
  const [state, action, pending] = useActionState(updateProfile, INIT)
  const fileRef = useRef<HTMLInputElement>(null)
  const previewRef = useRef<string | null>(null)
  const [preview, setPreview] = useState<string | null>(null)

  useEffect(() => {
    if (state.success) {
      toast.success('Profile updated')
      onClose()
    } else if (state.error) {
      toast.error(state.error)
    }
  }, [state, onClose])

  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    if (previewRef.current) URL.revokeObjectURL(previewRef.current)
    const url = URL.createObjectURL(file)
    previewRef.current = url
    setPreview(url)
  }

  // Revoke object URL on unmount
  useEffect(
    () => () => {
      if (previewRef.current) URL.revokeObjectURL(previewRef.current)
    },
    []
  )

  return (
    <form action={action} className="space-y-5">
      <input type="hidden" name="stay" value="1" />

      {/* Avatar picker */}
      <div className="flex flex-col items-center gap-2">
        <button
          type="button"
          onClick={() => fileRef.current?.click()}
          aria-label="Change profile photo"
          className="press relative w-20 h-20 rounded-full border-2 border-dashed border-white/20 hover:border-[var(--brand-primary)] transition-colors flex items-center justify-center overflow-hidden bg-white/5"
        >
          {preview || profile.avatar_url ? (
            <Image
              src={preview ?? profile.avatar_url!}
              alt="Avatar preview"
              fill
              className="object-cover"
              unoptimized={!!preview}
            />
          ) : (
            <User className="w-7 h-7 text-muted-foreground" aria-hidden />
          )}
          <span className="absolute bottom-0 inset-x-0 bg-black/50 py-1 flex items-center justify-center">
            <Camera className="w-3.5 h-3.5 text-white" aria-hidden />
          </span>
        </button>
        <span className="text-xs text-muted-foreground">Tap to change photo</span>
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
        <label htmlFor="edit-full-name" className="text-sm text-muted-foreground">
          Full name <span className="text-destructive">*</span>
        </label>
        <input
          id="edit-full-name"
          name="full_name"
          type="text"
          required
          maxLength={80}
          defaultValue={profile.full_name ?? ''}
          className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
          placeholder="Your name"
        />
      </div>

      <div className="space-y-1.5">
        <label htmlFor="edit-bio" className="text-sm text-muted-foreground">
          Bio
        </label>
        <textarea
          id="edit-bio"
          name="bio"
          rows={3}
          maxLength={1000}
          defaultValue={profile.bio ?? ''}
          className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)] resize-none"
          placeholder="Tell people what you're about…"
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
        className="press w-full rounded-xl bg-[var(--brand-primary)] py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity"
      >
        {pending ? (
          <span className="inline-flex items-center justify-center gap-2">
            <Loader2 className="w-4 h-4 animate-spin" aria-hidden />
            Saving…
          </span>
        ) : (
          'Save Profile'
        )}
      </button>
    </form>
  )
}
