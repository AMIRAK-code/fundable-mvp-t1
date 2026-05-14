'use client'

import { useTransition, useState } from 'react'
import Image from 'next/image'
import { Plus, Trash2, Building2 } from 'lucide-react'
import { deleteStartup } from '@/app/actions/profile'
import type { Startup } from '@/lib/supabase/types'
import StartupDialog from './startup-dialog'

export default function FounderProfile({ startups }: { startups: Startup[] }) {
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editTarget, setEditTarget] = useState<Startup | null>(null)

  function openAdd() {
    setEditTarget(null)
    setDialogOpen(true)
  }

  function openEdit(s: Startup) {
    setEditTarget(s)
    setDialogOpen(true)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="font-semibold text-foreground">My Startups</h2>
        <button
          onClick={openAdd}
          className="flex items-center gap-1.5 text-xs font-semibold text-white bg-[var(--brand-primary)] px-3 py-1.5 rounded-lg hover:opacity-90 transition-opacity"
        >
          <Plus className="w-3.5 h-3.5" />
          Add Startup
        </button>
      </div>

      {startups.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-white/10 p-8 text-center">
          <Building2 className="w-8 h-8 text-muted-foreground mx-auto mb-3" />
          <p className="text-sm text-muted-foreground">No startups yet.</p>
          <p className="text-xs text-muted-foreground mt-1">
            Add your first startup to appear in the feed.
          </p>
        </div>
      ) : (
        startups.map((s) => (
          <StartupRow key={s.id} startup={s} onEdit={() => openEdit(s)} />
        ))
      )}

      <StartupDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        startup={editTarget}
      />
    </div>
  )
}

function StartupRow({
  startup,
  onEdit,
}: {
  startup: Startup
  onEdit: () => void
}) {
  const [deleting, startDelete] = useTransition()

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 overflow-hidden">
      {startup.hero_image_url && (
        <div className="relative h-28">
          <Image
            src={startup.hero_image_url}
            alt={startup.name}
            fill
            className="object-cover"
            sizes="512px"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
        </div>
      )}
      <div className="p-4">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <p className="font-semibold truncate">{startup.name}</p>
            {startup.industry && (
              <p className="text-xs text-[var(--brand-primary)] mt-0.5">{startup.industry}</p>
            )}
            <p className="text-sm text-muted-foreground mt-1 line-clamp-2">{startup.pitch}</p>
          </div>
          <div className="flex gap-2 flex-shrink-0">
            <button
              onClick={onEdit}
              className="text-xs text-muted-foreground hover:text-foreground px-2 py-1 rounded-lg border border-white/10 transition-colors"
            >
              Edit
            </button>
            <button
              disabled={deleting}
              onClick={() => startDelete(() => { deleteStartup(startup.id) })}
              className="text-xs text-destructive hover:text-red-400 px-2 py-1 rounded-lg border border-destructive/20 disabled:opacity-50 transition-colors"
            >
              <Trash2 className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
