'use client'

import { useTransition } from 'react'
import { AlertTriangle } from 'lucide-react'
import SheetDialog from './sheet-dialog'

interface Props {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  description: string
  confirmLabel?: string
  cancelLabel?: string
  destructive?: boolean
  onConfirm: () => void | Promise<void>
}

export default function ConfirmDialog({
  open,
  onOpenChange,
  title,
  description,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  destructive = false,
  onConfirm,
}: Props) {
  const [pending, startTransition] = useTransition()

  function handleConfirm() {
    startTransition(async () => {
      await onConfirm()
      onOpenChange(false)
    })
  }

  return (
    <SheetDialog open={open} onOpenChange={onOpenChange} title={title} description={description} size="sm">
      <div className="flex items-start gap-3 mb-5">
        <div
          className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center ${
            destructive ? 'bg-destructive/15 text-destructive' : 'bg-[var(--brand-primary)]/15 text-[var(--brand-primary)]'
          }`}
          aria-hidden="true"
        >
          <AlertTriangle className="w-5 h-5" />
        </div>
        <p className="text-sm text-muted-foreground leading-relaxed pt-2">
          This action cannot be undone.
        </p>
      </div>

      <div className="flex flex-col-reverse sm:flex-row gap-2 sm:justify-end">
        <button
          type="button"
          onClick={() => onOpenChange(false)}
          disabled={pending}
          className="w-full sm:w-auto rounded-xl border border-white/10 bg-white/5 px-4 py-2.5 text-sm font-medium text-foreground hover:bg-white/10 disabled:opacity-50 transition-colors min-h-[44px]"
        >
          {cancelLabel}
        </button>
        <button
          type="button"
          onClick={handleConfirm}
          disabled={pending}
          autoFocus
          className={`w-full sm:w-auto rounded-xl px-4 py-2.5 text-sm font-semibold text-white disabled:opacity-50 transition-opacity min-h-[44px] ${
            destructive
              ? 'bg-destructive hover:opacity-90'
              : 'bg-[var(--brand-primary)] hover:opacity-90'
          }`}
        >
          {pending ? 'Working…' : confirmLabel}
        </button>
      </div>
    </SheetDialog>
  )
}
