'use client'

import { useOptimistic, useTransition, useState } from 'react'
import Image from 'next/image'
import { Plus, Building2, Eye, EyeOff } from 'lucide-react'
import { toast } from 'sonner'
import { deleteStartup, toggleStartupPublished } from '@/app/actions/profile'
import type { Startup } from '@/lib/supabase/types'
import { STARTUP_STATUS_LABELS, STARTUP_STATUS_COLORS } from '@/lib/supabase/types'
import StartupDialog from './startup-dialog'
import ConfirmDeleteButton from './confirm-delete-button'

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
      <div className="flex items-center justify-between gap-3">
        <h2 className="font-semibold text-foreground">My Startups</h2>
        <button
          onClick={openAdd}
          className="press flex items-center gap-1.5 text-sm font-semibold text-white bg-[var(--brand-primary)] px-3.5 py-2 rounded-lg hover:opacity-90 transition-opacity min-h-[40px] flex-shrink-0"
        >
          <Plus className="w-4 h-4" aria-hidden />
          Add
        </button>
      </div>

      {startups.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-white/10 p-8 text-center animate-in-up">
          <Building2 className="w-8 h-8 text-muted-foreground mx-auto mb-3" />
          <p className="text-sm text-muted-foreground">No startups yet.</p>
          <p className="text-xs text-muted-foreground mt-1">
            Add your first startup to appear in the feed.
          </p>
        </div>
      ) : (
        <div className="space-y-4 stagger-children">
          {startups.map((s) => (
            <StartupRow key={s.id} startup={s} onEdit={() => openEdit(s)} />
          ))}
        </div>
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
  const [, startPublish] = useTransition()
  const [published, setOptimisticPublished] = useOptimistic(
    startup.published,
    (_current, next: boolean) => next
  )

  function handleTogglePublish() {
    const next = !startup.published
    startPublish(async () => {
      setOptimisticPublished(next)
      const { error } = await toggleStartupPublished(startup.id, next)
      if (error) toast.error(error)
      else toast.success(next ? 'Published to feed' : 'Moved to drafts')
    })
  }

  function handleDelete() {
    startDelete(async () => {
      const { error } = await deleteStartup(startup.id)
      if (error) toast.error(error)
      else toast.success('Startup deleted')
    })
  }

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 overflow-hidden animate-in-up">
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
          {/* Published badge */}
          <div className="absolute top-2 right-2">
            <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${
              published
                ? 'bg-[var(--brand-success)]/20 text-[var(--brand-success)]'
                : 'bg-white/10 text-muted-foreground'
            }`}>
              {published ? 'Live' : 'Draft'}
            </span>
          </div>
        </div>
      )}
      <div className="p-4 space-y-3">
        <div className="min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <p className="font-semibold truncate flex-1 min-w-0">{startup.name}</p>
            {!startup.hero_image_url && (
              <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full flex-shrink-0 ${
                published
                  ? 'bg-[var(--brand-success)]/20 text-[var(--brand-success)]'
                  : 'bg-white/10 text-muted-foreground'
              }`}>
                {published ? 'Live' : 'Draft'}
              </span>
            )}
          </div>
          {startup.industry && (
            <p className="text-xs text-[var(--brand-primary)] mt-0.5">{startup.industry}</p>
          )}
          {startup.status && (
            <span className={`inline-block mt-1.5 px-2 py-0.5 rounded-full border text-[10px] font-semibold uppercase tracking-wide ${STARTUP_STATUS_COLORS[startup.status]}`}>
              {STARTUP_STATUS_LABELS[startup.status]}
            </span>
          )}
          <p className="text-sm text-muted-foreground mt-1 line-clamp-2">{startup.pitch}</p>
        </div>
        <div className="flex gap-2 pt-1 border-t border-white/5">
          <button
            onClick={onEdit}
            className="press flex-1 text-xs font-medium text-muted-foreground hover:text-foreground px-2 py-2 rounded-lg border border-white/10 transition-colors min-h-[36px]"
          >
            Edit
          </button>
          <button
            onClick={handleTogglePublish}
            aria-label={published ? `Unpublish ${startup.name}` : `Publish ${startup.name} to feed`}
            title={published ? 'Unpublish' : 'Publish to feed'}
            className={`press flex-1 flex items-center justify-center gap-1.5 text-xs font-medium px-2 py-2 rounded-lg border transition-colors min-h-[36px] ${
              published
                ? 'border-[var(--brand-success)]/30 text-[var(--brand-success)] hover:opacity-70'
                : 'border-white/10 text-muted-foreground hover:text-[var(--brand-success)] hover:border-[var(--brand-success)]/30'
            }`}
          >
            {published ? <Eye className="w-3.5 h-3.5" aria-hidden /> : <EyeOff className="w-3.5 h-3.5" aria-hidden />}
            {published ? 'Live' : 'Draft'}
          </button>
          <ConfirmDeleteButton
            label={`Delete ${startup.name}`}
            pending={deleting}
            onConfirm={handleDelete}
          />
        </div>
      </div>
    </div>
  )
}
