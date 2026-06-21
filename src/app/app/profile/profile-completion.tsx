'use client'

import { useState } from 'react'
import { Check, ChevronDown, Sparkles } from 'lucide-react'
import type { CompletionSummary } from '@/lib/profile-completion'

export default function ProfileCompletion({ summary }: { summary: CompletionSummary }) {
  const [open, setOpen] = useState(summary.percent < 100)

  if (summary.totalCount === 0) return null
  const allDone = summary.percent === 100

  return (
    <section
      className="rounded-2xl border border-white/10 bg-white/[0.03]"
      aria-label="Profile completion"
    >
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        aria-controls="profile-completion-list"
        className="w-full flex items-center gap-3 px-4 py-3 sm:px-5 sm:py-4 text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] rounded-2xl"
      >
        <div
          className={`flex-shrink-0 w-9 h-9 sm:w-10 sm:h-10 rounded-full flex items-center justify-center ${
            allDone
              ? 'bg-[var(--brand-success)]/15 text-[var(--brand-success)]'
              : 'bg-[var(--brand-primary)]/15 text-[var(--brand-primary)]'
          }`}
          aria-hidden="true"
        >
          {allDone ? <Check className="w-4 h-4 sm:w-5 sm:h-5" /> : <Sparkles className="w-4 h-4 sm:w-5 sm:h-5" />}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-baseline justify-between gap-2">
            <p className="text-sm font-semibold">
              {allDone ? 'Profile complete' : 'Complete your profile'}
            </p>
            <p className="text-xs text-muted-foreground tabular-nums">
              {summary.doneCount}/{summary.totalCount}
            </p>
          </div>
          <div
            role="progressbar"
            aria-valuenow={summary.percent}
            aria-valuemin={0}
            aria-valuemax={100}
            aria-label={`Profile ${summary.percent}% complete`}
            className="mt-2 h-1.5 w-full rounded-full bg-white/10 overflow-hidden"
          >
            <div
              className={`h-full rounded-full transition-all ${
                allDone ? 'bg-[var(--brand-success)]' : 'bg-[var(--brand-primary)]'
              }`}
              style={{ width: `${summary.percent}%` }}
            />
          </div>
        </div>
        <ChevronDown
          className={`flex-shrink-0 w-4 h-4 text-muted-foreground transition-transform ${open ? 'rotate-180' : ''}`}
          aria-hidden="true"
        />
      </button>

      {open && (
        <ul id="profile-completion-list" className="px-4 sm:px-5 pb-4 space-y-2">
          {summary.steps.map((step) => (
            <li
              key={step.key}
              className="flex items-center gap-3 text-sm"
            >
              <span
                className={`flex-shrink-0 w-5 h-5 rounded-full border flex items-center justify-center ${
                  step.done
                    ? 'bg-[var(--brand-success)]/20 border-[var(--brand-success)]/40 text-[var(--brand-success)]'
                    : 'border-white/15 text-transparent'
                }`}
                aria-hidden="true"
              >
                {step.done && <Check className="w-3 h-3" />}
              </span>
              <span className={step.done ? 'text-muted-foreground line-through decoration-white/20' : 'text-foreground'}>
                {step.label}
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  )
}
