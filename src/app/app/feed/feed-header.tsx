'use client'

import Link from 'next/link'

export default function FeedHeader({ view }: { view: 'founders' | 'investors' }) {
  const tabs = [
    { label: 'Founders', value: 'founders' },
    { label: 'Investors', value: 'investors' },
  ] as const

  return (
    <header className="sticky top-0 z-40 bg-background/95 backdrop-blur-md border-b border-white/10 pt-[env(safe-area-inset-top)]">
      <div className="flex items-center justify-between gap-2 px-3 sm:px-4 py-2.5 max-w-lg mx-auto">
        <span className="text-base sm:text-lg font-bold tracking-tight flex-shrink-0">
          Fund<span className="text-[var(--brand-primary)]">able</span>
        </span>

        <div className="flex bg-white/5 rounded-xl p-1 gap-1">
          {tabs.map((tab) => (
            <Link
              key={tab.value}
              href={`/app/feed?view=${tab.value}`}
              className={[
                'px-3 sm:px-4 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition-all whitespace-nowrap',
                view === tab.value
                  ? 'bg-[var(--brand-primary)] text-white shadow'
                  : 'text-muted-foreground hover:text-foreground',
              ].join(' ')}
            >
              {tab.label}
            </Link>
          ))}
        </div>
      </div>
    </header>
  )
}
