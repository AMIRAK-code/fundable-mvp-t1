'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Layers, Bell, MessageSquare, User } from 'lucide-react'

const NAV_ITEMS = [
  { href: '/app/feed', icon: Layers, label: 'Feed' },
  { href: '/app/requests', icon: Bell, label: 'Requests' },
  { href: '/app/messages', icon: MessageSquare, label: 'Messages' },
  { href: '/app/profile', icon: User, label: 'Profile' },
]

export default function BottomNav() {
  const pathname = usePathname()

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 border-t border-white/10 bg-background/90 backdrop-blur-md">
      <div className="flex items-center justify-around px-2 py-2 max-w-lg mx-auto">
        {NAV_ITEMS.map(({ href, icon: Icon, label }) => {
          const active = pathname.startsWith(href)
          return (
            <Link
              key={href}
              href={href}
              className={[
                'flex flex-col items-center gap-1 px-4 py-1.5 rounded-xl transition-colors',
                active
                  ? 'text-[var(--brand-primary)]'
                  : 'text-muted-foreground hover:text-foreground',
              ].join(' ')}
            >
              <Icon className="w-5 h-5" strokeWidth={active ? 2.5 : 1.8} />
              <span className="text-[10px] font-medium">{label}</span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}
