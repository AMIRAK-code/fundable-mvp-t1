'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Layers, Bell, MessageSquare, User } from 'lucide-react'
import UnreadDot from './unread-dot'

const NAV_ITEMS = [
  { href: '/app/feed', icon: Layers, label: 'Feed', unread: false },
  { href: '/app/requests', icon: Bell, label: 'Requests', unread: false },
  { href: '/app/messages', icon: MessageSquare, label: 'Messages', unread: true },
  { href: '/app/profile', icon: User, label: 'Profile', unread: false },
]

export default function BottomNav() {
  const pathname = usePathname()

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 border-t border-white/10 bg-background/95 backdrop-blur-md pb-[env(safe-area-inset-bottom)]">
      <div className="flex items-stretch justify-around px-1 py-1.5 max-w-lg mx-auto">
        {NAV_ITEMS.map(({ href, icon: Icon, label, unread }) => {
          const active = pathname.startsWith(href)
          return (
            <Link
              key={href}
              href={href}
              className={[
                'flex-1 flex flex-col items-center justify-center gap-0.5 py-1.5 rounded-xl transition-colors min-h-[52px]',
                active
                  ? 'text-[var(--brand-primary)]'
                  : 'text-muted-foreground hover:text-foreground',
              ].join(' ')}
            >
              <span className="relative">
                <Icon className="w-5 h-5" strokeWidth={active ? 2.5 : 1.8} />
                {unread && <UnreadDot />}
              </span>
              <span className="text-[10px] font-medium leading-none">{label}</span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}
