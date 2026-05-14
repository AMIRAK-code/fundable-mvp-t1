'use client'

import Link from 'next/link'

export default function FeedHeader({ view }: { view: 'founders' | 'investors' }) {
  const tabs = [
    { label: 'Founders', value: 'founders' },
    { label: 'Investors', value: 'investors' },
  ] as const

  return (
    <header className="sticky top-0 z-40 bg-background/90 backdrop-blur-md border-b border-white/10">
      <div className="flex items-center justify-between px-4 py-3 max-w-lg mx-auto">
        <span className="text-lg font-bold tracking-tight">
          Fund<span className="text-[var(--brand-primary)]">able</span>
        </span>

        <div className="flex bg-white/5 rounded-xl p-1 gap-1">
          {tabs.map((tab) => (
            <Link
              key={tab.value}
              href={`/app/feed?view=${tab.value}`}
              className={[
                'px-4 py-1.5 rounded-lg text-sm font-medium transition-all',
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
