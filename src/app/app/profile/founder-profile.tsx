'use client'

import { useOptimistic, useState, useTransition } from 'react'
import Image from 'next/image'
import { Plus, Trash2, Building2, Eye, EyeOff, Pencil } from 'lucide-react'
import { toast } from 'sonner'
import { deleteStartup, toggleStartupPublished } from '@/app/actions/profile'
import type { Startup } from '@/lib/supabase/types'
import StartupDialog from './startup-dialog'
import ConfirmDialog from './confirm-dialog'

type OptimisticAction =
  | { type: 'publish'; id: string; published: boolean }
  | { type: 'delete'; id: string }

export default function FounderProfile({ startups }: { startups: Startup[] }) {
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editTarget, setEditTarget] = useState<Startup | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<Startup | null>(null)

  const [optimisticList, applyOptimistic] = useOptimistic<Startup[], OptimisticAction>(
    startups,
    (current, action) => {
      if (action.type === 'publish') {
        return current.map((s) => (s.id === action.id ? { ...s, published: action.published } : s))
      }
      if (action.type === 'delete') {
        return current.filter((s) => s.id !== action.id)
      }
      return current
    }
  )

  function openAdd() {
    setEditTarget(null)
    setDialogOpen(true)
  }

  function openEdit(s: Startup) {
    setEditTarget(s)
    setDialogOpen(true)
  }

  async function confirmDelete() {
    const target = deleteTarget
    if (!target) return
    applyOptimistic({ type: 'delete', id: target.id })
    const res = await deleteStartup(target.id)
    if (res.error) toast.error(res.error)
    else toast.success(`${target.name} deleted`)
  }

  const isEmpty = optimisticList.length === 0

  return (
    <section className="space-y-4" aria-label="My startups">
      <div className="flex items-center justify-between gap-3">
        <h2 className="font-semibold text-base sm:text-lg">My Startups</h2>
        {!isEmpty && (
          <button
            type="button"
            onClick={openAdd}
            className="inline-flex items-center gap-1.5 text-sm font-semibold text-white bg-[var(--brand-primary)] px-4 py-2 rounded-lg hover:opacity-90 transition-opacity min-h-[40px] flex-shrink-0 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
          >
            <Plus className="w-4 h-4" aria-hidden="true" />
            Add
          </button>
        )}
      </div>

      {isEmpty ? (
        <div className="rounded-2xl border border-dashed border-white/15 bg-white/[0.02] p-6 sm:p-8 text-center">
          <div className="mx-auto w-12 h-12 rounded-full bg-[var(--brand-primary)]/10 flex items-center justify-center mb-3">
            <Building2 className="w-6 h-6 text-[var(--brand-primary)]" aria-hidden="true" />
          </div>
          <p className="text-sm font-medium">No startups yet</p>
          <p className="text-xs text-muted-foreground mt-1 max-w-sm mx-auto">
            Add your first startup so investors can discover it in the feed.
          </p>
          <button
            type="button"
            onClick={openAdd}
            className="mt-4 inline-flex items-center gap-1.5 text-sm font-semibold text-white bg-[var(--brand-primary)] px-5 py-2.5 rounded-xl hover:opacity-90 transition-opacity min-h-[44px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
          >
            <Plus className="w-4 h-4" aria-hidden="true" />
            Add your first startup
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {optimisticList.map((s) => (
            <StartupRow
              key={s.id}
              startup={s}
              onEdit={() => openEdit(s)}
              onDelete={() => setDeleteTarget(s)}
              applyOptimistic={applyOptimistic}
            />
          ))}
        </div>
      )}

      <StartupDialog open={dialogOpen} onOpenChange={setDialogOpen} startup={editTarget} />
      <ConfirmDialog
        open={!!deleteTarget}
        onOpenChange={(v) => !v && setDeleteTarget(null)}
        title="Delete startup?"
        description={`"${deleteTarget?.name ?? ''}" will be removed from your profile and the feed.`}
        confirmLabel="Delete"
        destructive
        onConfirm={confirmDelete}
      />
    </section>
  )
}

function StartupRow({
  startup,
  onEdit,
  onDelete,
  applyOptimistic,
}: {
  startup: Startup
  onEdit: () => void
  onDelete: () => void
  applyOptimistic: (a: OptimisticAction) => void
}) {
  const [publishing, startPublish] = useTransition()

  function handleTogglePublish() {
    const next = !startup.published
    startPublish(async () => {
      applyOptimistic({ type: 'publish', id: startup.id, published: next })
      const res = await toggleStartupPublished(startup.id, next)
      if (res.error) toast.error(res.error)
      else toast.success(next ? 'Published to feed' : 'Unpublished')
    })
  }

  return (
    <article className="rounded-2xl border border-white/10 bg-white/5 overflow-hidden flex flex-col">
      {startup.hero_image_url ? (
        <div className="relative h-32 sm:h-36 md:h-40 bg-white/5">
          <Image
            src={startup.hero_image_url}
            alt=""
            fill
            className="object-cover"
            sizes="(min-width: 768px) 320px, 100vw"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
          <div className="absolute top-2 right-2">
            <span
              className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${
                startup.published
                  ? 'bg-[var(--brand-success)]/20 text-[var(--brand-success)]'
                  : 'bg-black/40 text-white/80'
              }`}
            >
              {startup.published ? 'Live' : 'Draft'}
            </span>
          </div>
        </div>
      ) : null}

      <div className="p-4 space-y-3 flex-1 flex flex-col">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2 flex-wrap">
            <p className="font-semibold truncate flex-1 min-w-0">{startup.name}</p>
            {!startup.hero_image_url && (
              <span
                className={`text-[10px] font-semibold px-2 py-0.5 rounded-full flex-shrink-0 ${
                  startup.published
                    ? 'bg-[var(--brand-success)]/20 text-[var(--brand-success)]'
                    : 'bg-white/10 text-muted-foreground'
                }`}
              >
                {startup.published ? 'Live' : 'Draft'}
              </span>
            )}
          </div>
          {startup.industry && (
            <p className="text-xs text-[var(--brand-primary)] mt-0.5">{startup.industry}</p>
          )}
          <p className="text-sm text-muted-foreground mt-1 line-clamp-2 [overflow-wrap:anywhere]">
            {startup.pitch}
          </p>
        </div>

        <div className="flex gap-2 pt-3 border-t border-white/5">
          <button
            type="button"
            onClick={onEdit}
            aria-label={`Edit ${startup.name}`}
            className="flex-1 inline-flex items-center justify-center gap-1.5 text-xs font-medium text-muted-foreground hover:text-foreground px-2 py-2 rounded-lg border border-white/10 hover:border-white/20 transition-colors min-h-[44px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
          >
            <Pencil className="w-3.5 h-3.5" aria-hidden="true" />
            <span>Edit</span>
          </button>
          <button
            type="button"
            disabled={publishing}
            onClick={handleTogglePublish}
            aria-pressed={startup.published}
            aria-label={startup.published ? 'Unpublish startup' : 'Publish startup'}
            className={`flex-1 inline-flex items-center justify-center gap-1.5 text-xs font-medium px-2 py-2 rounded-lg border transition-colors disabled:opacity-50 min-h-[44px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] ${
              startup.published
                ? 'border-[var(--brand-success)]/30 text-[var(--brand-success)] hover:bg-[var(--brand-success)]/5'
                : 'border-white/10 text-muted-foreground hover:text-[var(--brand-success)] hover:border-[var(--brand-success)]/30'
            }`}
          >
            {startup.published ? (
              <Eye className="w-3.5 h-3.5" aria-hidden="true" />
            ) : (
              <EyeOff className="w-3.5 h-3.5" aria-hidden="true" />
            )}
            <span>{startup.published ? 'Live' : 'Draft'}</span>
          </button>
          <button
            type="button"
            onClick={onDelete}
            aria-label={`Delete ${startup.name}`}
            className="inline-flex items-center justify-center text-destructive hover:bg-destructive/10 px-3 py-2 rounded-lg border border-destructive/20 transition-colors min-h-[44px] min-w-[44px] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-destructive"
          >
            <Trash2 className="w-4 h-4" aria-hidden="true" />
          </button>
        </div>
      </div>
    </article>
  )
}
