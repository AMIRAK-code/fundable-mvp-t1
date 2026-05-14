'use client'

import { useTransition } from 'react'
import { LogOut } from 'lucide-react'
import { logout } from '@/app/actions/auth'

export default function LogoutButton() {
  const [pending, startTransition] = useTransition()

  return (
    <button
      disabled={pending}
      onClick={() => startTransition(() => logout())}
      className="flex items-center gap-2 text-sm text-muted-foreground hover:text-destructive disabled:opacity-50 transition-colors"
    >
      <LogOut className="w-4 h-4" />
      {pending ? 'Signing out…' : 'Sign out'}
    </button>
  )
}
