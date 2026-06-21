'use client'

import { useEffect, useRef, useId } from 'react'
import { X } from 'lucide-react'

interface Props {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  description?: string
  children: React.ReactNode
  size?: 'sm' | 'md'
}

export default function SheetDialog({ open, onOpenChange, title, description, children, size = 'md' }: Props) {
  const containerRef = useRef<HTMLDivElement>(null)
  const previouslyFocused = useRef<HTMLElement | null>(null)
  const titleId = useId()
  const descId = useId()

  useEffect(() => {
    if (!open) return

    previouslyFocused.current = document.activeElement as HTMLElement | null
    const body = document.body
    const prevOverflow = body.style.overflow
    body.style.overflow = 'hidden'

    const focusFirst = () => {
      const root = containerRef.current
      if (!root) return
      // Respect React's autoFocus / a child that already grabbed focus.
      if (root.contains(document.activeElement) && document.activeElement !== document.body) return
      const focusables = root.querySelectorAll<HTMLElement>(
        'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), [tabindex]:not([tabindex="-1"])'
      )
      const target = focusables[0]
      target?.focus({ preventScroll: true })
    }
    const raf = requestAnimationFrame(focusFirst)

    function onKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') {
        e.preventDefault()
        onOpenChange(false)
        return
      }
      if (e.key !== 'Tab') return
      const root = containerRef.current
      if (!root) return
      const focusables = Array.from(
        root.querySelectorAll<HTMLElement>(
          'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), [tabindex]:not([tabindex="-1"])'
        )
      ).filter((el) => el.offsetParent !== null)
      if (focusables.length === 0) return
      const first = focusables[0]
      const last = focusables[focusables.length - 1]
      const active = document.activeElement as HTMLElement | null
      if (e.shiftKey && active === first) {
        e.preventDefault()
        last.focus()
      } else if (!e.shiftKey && active === last) {
        e.preventDefault()
        first.focus()
      }
    }
    document.addEventListener('keydown', onKeyDown)

    return () => {
      cancelAnimationFrame(raf)
      document.removeEventListener('keydown', onKeyDown)
      body.style.overflow = prevOverflow
      previouslyFocused.current?.focus({ preventScroll: true })
    }
  }, [open, onOpenChange])

  if (!open) return null

  const widthClass = size === 'sm' ? 'sm:max-w-sm' : 'sm:max-w-md'

  return (
    <div
      className="fixed inset-0 z-[60] flex items-end sm:items-center justify-center"
      role="dialog"
      aria-modal="true"
      aria-labelledby={titleId}
      aria-describedby={description ? descId : undefined}
    >
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={() => onOpenChange(false)}
        aria-hidden="true"
      />
      <div
        ref={containerRef}
        className={`relative w-full ${widthClass} bg-slate-900 border border-white/10 rounded-t-2xl sm:rounded-2xl p-5 sm:p-6 pb-[max(1.25rem,env(safe-area-inset-bottom))] z-10 max-h-[100dvh] sm:max-h-[92dvh] overflow-y-auto overscroll-contain shadow-2xl`}
      >
        <div className="flex items-start justify-between gap-3 mb-4">
          <div className="min-w-0">
            <h3 id={titleId} className="font-semibold text-lg leading-tight">
              {title}
            </h3>
            {description && (
              <p id={descId} className="text-sm text-muted-foreground mt-1">
                {description}
              </p>
            )}
          </div>
          <button
            type="button"
            onClick={() => onOpenChange(false)}
            aria-label="Close dialog"
            className="flex-shrink-0 -mr-1 -mt-1 inline-flex items-center justify-center w-9 h-9 rounded-lg text-muted-foreground hover:text-foreground hover:bg-white/5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        {children}
      </div>
    </div>
  )
}
