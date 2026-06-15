'use client'

import { useEffect, useRef, useState } from 'react'
import { Trash2, Loader2 } from 'lucide-react'

interface Props {
  /** Accessible action name, e.g. 'Delete startup' */
  label: string
  pending: boolean
  onConfirm: () => void
}

/**
 * Two-tap destructive button: first tap arms it into a 'Confirm?' state
 * (auto-disarms after 3s), second tap executes. No window.confirm.
 */
export default function ConfirmDeleteButton({ label, pending, onConfirm }: Props) {
  const [armed, setArmed] = useState(false)
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(
    () => () => {
      if (timer.current) clearTimeout(timer.current)
    },
    []
  )

  function handleClick() {
    if (!armed) {
      setArmed(true)
      timer.current = setTimeout(() => setArmed(false), 3000)
      return
    }
    if (timer.current) clearTimeout(timer.current)
    setArmed(false)
    onConfirm()
  }

  return (
    <button
      disabled={pending}
      onClick={handleClick}
      aria-label={armed ? `Confirm: ${label}` : label}
      className={`press flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg border text-xs font-semibold disabled:opacity-50 transition-colors min-h-[36px] min-w-[40px] ${
        armed
          ? 'animate-pop bg-destructive/15 border-destructive/40 text-destructive'
          : 'text-destructive hover:text-red-400 border-destructive/20'
      }`}
    >
      {pending ? (
        <Loader2 className="w-3.5 h-3.5 animate-spin" aria-hidden />
      ) : (
        <Trash2 className="w-3.5 h-3.5" aria-hidden />
      )}
      {armed && !pending && 'Confirm?'}
    </button>
  )
}
