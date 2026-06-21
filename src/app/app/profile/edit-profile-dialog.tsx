'use client'

import { useActionState, useEffect, useRef, useState } from 'react'
import Image from 'next/image'
import { Camera, User } from 'lucide-react'
import { toast } from 'sonner'
import { updateProfile } from '@/app/actions/auth'
import type { Profile } from '@/lib/supabase/types'
import SheetDialog from './sheet-dialog'

const MAX_IMAGE_MB = 5

interface Props {
  open: boolean
  onOpenChange: (open: boolean) => void
  profile: Profile
}

const INIT = { error: null as string | null, success: false }

export default function EditProfileDialog({ open, onOpenChange, profile }: Props) {
  const [state, action, pending] = useActionState(updateProfile, INIT)
  const fileRef = useRef<HTMLInputElement>(null)
  const [preview, setPreview] = useState<string | null>(null)
  const [fileError, setFileError] = useState<string | null>(null)
  const [bio, setBio] = useState(profile.bio ?? '')

  useEffect(() => {
    if (!open) {
      setPreview(null)
      setFileError(null)
      setBio(profile.bio ?? '')
    }
  }, [open, profile.bio])

  useEffect(() => {
    return () => {
      if (preview) URL.revokeObjectURL(preview)
    }
  }, [preview])

  useEffect(() => {
    if (state.success) {
      toast.success('Profile updated')
      onOpenChange(false)
    } else if (state.error) {
      toast.error(state.error)
    }
  }, [state, onOpenChange])

  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
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

  const bioLen = bio.trim().length
  const bioLimit = 280
  const bioOver = bioLen > bioLimit

  return (
    <SheetDialog
      open={open}
      onOpenChange={onOpenChange}
      title="Edit profile"
      description="Update your photo, name, and bio."
    >
      <form action={action} className="space-y-5">
        {/* Avatar */}
        <div className="flex flex-col items-center gap-3">
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            aria-label="Upload profile photo"
            className="relative w-24 h-24 rounded-full border-2 border-dashed border-white/20 hover:border-[var(--brand-primary)] transition-colors flex items-center justify-center overflow-hidden bg-white/5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
          >
            {preview ? (
              <Image src={preview} alt="" fill sizes="96px" className="object-cover" />
            ) : profile.avatar_url ? (
              <Image src={profile.avatar_url} alt="" fill sizes="96px" className="object-cover" />
            ) : (
              <User className="w-8 h-8 text-muted-foreground" />
            )}
            <span className="absolute bottom-0 right-0 w-7 h-7 rounded-full bg-[var(--brand-primary)] text-white flex items-center justify-center border-2 border-slate-900 shadow">
              <Camera className="w-3.5 h-3.5" />
            </span>
          </button>
          <p className="text-xs text-muted-foreground">PNG/JPG up to {MAX_IMAGE_MB}MB</p>
          <input
            ref={fileRef}
            name="avatar"
            type="file"
            accept="image/*"
            className="hidden"
            onChange={handleFileChange}
          />
          {fileError && (
            <p role="alert" className="text-xs text-destructive">{fileError}</p>
          )}
        </div>

        <div className="space-y-1.5">
          <label htmlFor="edit_full_name" className="text-sm text-muted-foreground">
            Full name <span className="text-destructive" aria-hidden="true">*</span>
          </label>
          <input
            id="edit_full_name"
            name="full_name"
            type="text"
            required
            defaultValue={profile.full_name ?? ''}
            placeholder="Your name"
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)]"
          />
        </div>

        <div className="space-y-1.5">
          <div className="flex items-baseline justify-between gap-3">
            <label htmlFor="edit_bio" className="text-sm text-muted-foreground">
              Bio
            </label>
            <span className={`text-xs ${bioOver ? 'text-destructive' : 'text-muted-foreground'}`}>
              {bioLen}/{bioLimit}
            </span>
          </div>
          <textarea
            id="edit_bio"
            name="bio"
            rows={4}
            value={bio}
            onChange={(e) => setBio(e.target.value)}
            placeholder="A line or two about you."
            className="w-full rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)] resize-none"
            aria-invalid={bioOver || undefined}
          />
          <p className="text-xs text-muted-foreground">A short, public summary shown on your card.</p>
        </div>

        <button
          type="submit"
          disabled={pending || bioOver}
          aria-busy={pending}
          className="w-full rounded-xl bg-[var(--brand-primary)] py-3 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50 transition-opacity min-h-[44px]"
        >
          {pending ? 'Saving…' : 'Save changes'}
        </button>
      </form>
    </SheetDialog>
  )
}
