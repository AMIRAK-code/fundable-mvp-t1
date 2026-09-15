'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { BookOpen, MessagesSquare } from 'lucide-react'

const ITEMS = [
  { href: '/birds', icon: BookOpen, label: 'Species' },
  { href: '/birds/ask', icon: MessagesSquare, label: 'Ask' },
]

export default function BirdNav() {
  const pathname = usePathname()

  return (
    <nav className="flex items-center gap-1">
      {ITEMS.map(({ href, icon: Icon, label }) => {
        const active =
          href === '/birds' ? !pathname.startsWith('/birds/ask') : pathname.startsWith(href)

        return (
          <Link
            key={href}
            href={href}
            aria-current={active ? 'page' : undefined}
            className={[
              'flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-sm font-medium transition-colors',
              active
                ? 'bg-[var(--bird-primary)]/15 text-[var(--bird-primary)]'
                : 'text-muted-foreground hover:bg-white/5 hover:text-foreground',
            ].join(' ')}
          >
            <Icon className="h-4 w-4" strokeWidth={active ? 2.4 : 1.8} />
            {label}
          </Link>
        )
      })}
    </nav>
  )
}
