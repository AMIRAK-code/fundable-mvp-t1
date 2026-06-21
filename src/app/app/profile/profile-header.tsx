'use client'

import { useState } from 'react'
import Image from 'next/image'
import { User, Pencil } from 'lucide-react'
import type { Profile } from '@/lib/supabase/types'
import EditProfileDialog from './edit-profile-dialog'
import LogoutButton from './logout-button'

export default function ProfileHeader({ profile }: { profile: Profile }) {
  const [editOpen, setEditOpen] = useState(false)

  return (
    <>
      <header className="rounded-2xl border border-white/10 bg-white/[0.03] p-4 sm:p-5 md:p-6">
        <div className="flex items-start gap-4 sm:gap-5">
          {profile.avatar_url ? (
            <Image
              src={profile.avatar_url}
              alt=""
              width={72}
              height={72}
              sizes="72px"
              className="rounded-full object-cover border-2 border-[var(--brand-primary)]/40 w-16 h-16 sm:w-20 sm:h-20 md:w-24 md:h-24 flex-shrink-0"
            />
          ) : (
            <div className="w-16 h-16 sm:w-20 sm:h-20 md:w-24 md:h-24 rounded-full bg-white/10 border border-white/10 flex items-center justify-center flex-shrink-0">
              <User className="w-7 h-7 sm:w-8 sm:h-8 md:w-10 md:h-10 text-muted-foreground" aria-hidden="true" />
            </div>
          )}
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2">
              <div className="min-w-0">
                <h1 className="font-bold text-lg sm:text-xl md:text-2xl leading-tight truncate">
                  {profile.full_name ?? 'Unnamed'}
                </h1>
                <p className="text-xs sm:text-sm text-[var(--brand-primary)] font-semibold capitalize mt-0.5">
                  {profile.role}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setEditOpen(true)}
                aria-label="Edit profile"
                className="flex-shrink-0 inline-flex items-center gap-1.5 text-xs font-medium text-muted-foreground hover:text-foreground border border-white/10 hover:border-white/20 bg-white/5 px-3 py-2 rounded-lg min-h-[36px] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
              >
                <Pencil className="w-3.5 h-3.5" aria-hidden="true" />
                <span className="hidden sm:inline">Edit</span>
              </button>
            </div>
            {profile.bio ? (
              <p className="text-sm text-muted-foreground mt-2 break-words [overflow-wrap:anywhere]">
                {profile.bio}
              </p>
            ) : (
              <button
                type="button"
                onClick={() => setEditOpen(true)}
                className="text-sm text-[var(--brand-primary)] hover:underline mt-2 inline-flex items-center gap-1"
              >
                + Add a short bio
              </button>
            )}
          </div>
        </div>

        <div className="mt-4 pt-4 border-t border-white/10 flex items-center justify-end">
          <LogoutButton />
        </div>
      </header>

      <EditProfileDialog open={editOpen} onOpenChange={setEditOpen} profile={profile} />
    </>
  )
}
