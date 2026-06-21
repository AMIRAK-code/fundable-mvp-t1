'use client'

import { useState, useTransition } from 'react'
import { LogOut } from 'lucide-react'
import { toast } from 'sonner'
import { logout } from '@/app/actions/auth'
import ConfirmDialog from './confirm-dialog'

export default function LogoutButton() {
  const [open, setOpen] = useState(false)
  const [pending, startTransition] = useTransition()

  function handleConfirm() {
    startTransition(async () => {
      try {
        await logout()
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Could not sign out'
        toast.error(msg)
      }
    })
  }

  return (
    <>
      <button
        type="button"
        disabled={pending}
        onClick={() => setOpen(true)}
        className="inline-flex items-center gap-2 text-sm font-medium text-muted-foreground hover:text-destructive disabled:opacity-50 transition-colors min-h-[44px] px-3 -mr-3 rounded-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]"
      >
        <LogOut className="w-4 h-4" aria-hidden="true" />
        {pending ? 'Signing out…' : 'Sign out'}
      </button>
      <ConfirmDialog
        open={open}
        onOpenChange={setOpen}
        title="Sign out?"
        description="You'll need to log in again to use your account."
        confirmLabel="Sign out"
        destructive
        onConfirm={handleConfirm}
      />
    </>
  )
}
