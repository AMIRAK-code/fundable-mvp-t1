'use client'

import { useEffect, useOptimistic, useRef, useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { Search, X } from 'lucide-react'
import type { StartupStatus } from '@/lib/supabase/types'
import { STARTUP_STATUS_LABELS, STARTUP_STATUS_COLORS } from '@/lib/supabase/types'

type View = 'founders' | 'investors'

interface Props {
  view: View
  q: string
  stage: StartupStatus | null
}

const TABS = [
  { label: 'Founders', value: 'founders' },
  { label: 'Investors', value: 'investors' },
] as const

const STAGES = Object.keys(STARTUP_STATUS_LABELS) as StartupStatus[]

function buildUrl(view: View, q: string, stage: StartupStatus | null) {
  const params = new URLSearchParams()
  params.set('view', view)
  if (q) params.set('q', q)
  if (view === 'founders' && stage) params.set('stage', stage)
  return `/app/feed?${params.toString()}`
}

export default function FeedHeader({ view, q, stage }: Props) {
  const router = useRouter()
  const [, startTransition] = useTransition()

  // Optimistic copies: the active pill / chip moves instantly while the
  // server-rendered feed streams in behind the Suspense boundary.
  const [optimisticView, setOptimisticView] = useOptimistic(view)
  const [optimisticStage, setOptimisticStage] = useOptimistic(stage)

  const [searchOpen, setSearchOpen] = useState(() => q.length > 0)
  const [value, setValue] = useState(q)
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current)
    }
  }, [])

  const switchView = (next: View) => {
    if (next === optimisticView) return
    if (debounceRef.current) clearTimeout(debounceRef.current)
    startTransition(() => {
      setOptimisticView(next)
      router.replace(buildUrl(next, value.trim(), stage))
    })
  }

  const selectStage = (next: StartupStatus | null) => {
    startTransition(() => {
      setOptimisticStage(next)
      router.replace(buildUrl('founders', value.trim(), next), { scroll: false })
    })
  }

  const onSearchChange = (text: string) => {
    setValue(text)
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => {
      startTransition(() => {
        router.replace(buildUrl(view, text.trim(), stage), { scroll: false })
      })
    }, 350)
  }

  const openSearch = () => {
    setSearchOpen(true)
    // Focus after the input mounts
    requestAnimationFrame(() => inputRef.current?.focus())
  }

  const closeSearch = () => {
    if (debounceRef.current) clearTimeout(debounceRef.current)
    setSearchOpen(false)
    setValue('')
    if (q) {
      startTransition(() => {
        router.replace(buildUrl(view, '', stage), { scroll: false })
      })
    }
  }

  return (
    <header className="sticky top-0 z-40 bg-background/95 backdrop-blur-md border-b border-white/10 pt-[env(safe-area-inset-top)]">
      <div className="flex items-center justify-between gap-2 px-3 sm:px-4 py-2.5 max-w-lg mx-auto">
        {searchOpen ? (
          <div className="flex items-center gap-2 w-full animate-in-up">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
              <input
                ref={inputRef}
                type="search"
                value={value}
                onChange={(e) => onSearchChange(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Escape') closeSearch()
                }}
                placeholder={optimisticView === 'founders' ? 'Search startups…' : 'Search investors…'}
                aria-label={optimisticView === 'founders' ? 'Search startups' : 'Search investors'}
                enterKeyHint="search"
                className="w-full rounded-xl border border-white/10 bg-white/5 pl-9 pr-4 py-2 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-[var(--brand-primary)] [&::-webkit-search-cancel-button]:hidden"
              />
            </div>
            <button
              onClick={closeSearch}
              aria-label="Clear search and close"
              className="flex items-center justify-center w-8 h-8 rounded-lg text-muted-foreground hover:text-foreground hover:bg-white/5 press focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] flex-shrink-0"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        ) : (
          <>
            <span className="text-base sm:text-lg font-bold tracking-tight flex-shrink-0">
              Fund<span className="text-[var(--brand-primary)]">able</span>
            </span>

            <div className="flex items-center gap-1.5">
              <div className="flex bg-white/5 rounded-xl p-1 gap-1" role="group" aria-label="Feed view">
                {TABS.map((tab) => (
                  <button
                    key={tab.value}
                    aria-pressed={optimisticView === tab.value}
                    onClick={() => switchView(tab.value)}
                    className={[
                      'px-3 sm:px-4 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition-all whitespace-nowrap press focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]',
                      optimisticView === tab.value
                        ? 'bg-[var(--brand-primary)] text-white shadow'
                        : 'text-muted-foreground hover:text-foreground',
                    ].join(' ')}
                  >
                    {tab.label}
                  </button>
                ))}
              </div>

              <button
                onClick={openSearch}
                aria-label="Search the feed"
                className="flex items-center justify-center w-8 h-8 rounded-lg text-muted-foreground hover:text-foreground hover:bg-white/5 press focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)] flex-shrink-0"
              >
                <Search className="w-4 h-4" />
              </button>
            </div>
          </>
        )}
      </div>

      {optimisticView === 'founders' && (
        <div className="max-w-lg mx-auto px-3 sm:px-4 pb-2.5">
          <div className="flex gap-1.5 overflow-x-auto no-scrollbar" role="group" aria-label="Filter by stage">
            <button
              onClick={() => selectStage(null)}
              aria-pressed={optimisticStage === null}
              className={[
                'px-2.5 py-0.5 rounded-full text-[10px] font-semibold uppercase tracking-wider border whitespace-nowrap flex-shrink-0 press focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]',
                optimisticStage === null
                  ? 'bg-[var(--brand-primary)]/15 text-[var(--brand-primary)] border-[var(--brand-primary)]/30'
                  : 'bg-white/5 text-muted-foreground border-white/10 hover:text-foreground',
              ].join(' ')}
            >
              All
            </button>
            {STAGES.map((s) => (
              <button
                key={s}
                onClick={() => selectStage(s)}
                aria-pressed={optimisticStage === s}
                className={[
                  'px-2.5 py-0.5 rounded-full text-[10px] font-semibold uppercase tracking-wider border whitespace-nowrap flex-shrink-0 press focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--brand-primary)]',
                  optimisticStage === s
                    ? STARTUP_STATUS_COLORS[s]
                    : 'bg-white/5 text-muted-foreground border-white/10 hover:text-foreground',
                ].join(' ')}
              >
                {STARTUP_STATUS_LABELS[s]}
              </button>
            ))}
          </div>
        </div>
      )}
    </header>
  )
}
