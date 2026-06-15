'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Layers, Bell, MessageSquare, User } from 'lucide-react'
import { useNavBadges, NavBadge } from './nav-badges'

const NAV_ITEMS = [
  { href: '/app/feed', icon: Layers, label: 'Feed', badge: null },
  { href: '/app/requests', icon: Bell, label: 'Requests', badge: 'requests' },
  { href: '/app/messages', icon: MessageSquare, label: 'Messages', badge: 'messages' },
  { href: '/app/profile', icon: User, label: 'Profile', badge: null },
] as const

export default function BottomNav() {
  const pathname = usePathname()
  const badges = useNavBadges()

  return (
    <nav
      aria-label="Primary"
      className="fixed bottom-0 left-0 right-0 z-50 border-t border-white/10 bg-background/95 backdrop-blur-md pb-[env(safe-area-inset-bottom)]"
    >
      <div className="flex items-stretch justify-around px-1 py-1.5 max-w-lg mx-auto">
        {NAV_ITEMS.map(({ href, icon: Icon, label, badge }) => {
          const active = pathname.startsWith(href)
          const count = badge ? badges[badge] : 0
          return (
            <Link
              key={href}
              href={href}
              aria-current={active ? 'page' : undefined}
              aria-label={count > 0 ? `${label}, ${count > 9 ? '9+' : count} new` : label}
              className={[
                'press flex-1 flex flex-col items-center justify-center gap-0.5 py-1.5 rounded-xl transition-colors min-h-[52px]',
                active
                  ? 'text-[var(--brand-primary)]'
                  : 'text-muted-foreground hover:text-foreground',
              ].join(' ')}
            >
              <span className="relative">
                <Icon className="w-5 h-5" strokeWidth={active ? 2.5 : 1.8} />
                <NavBadge count={count} />
              </span>
              <span className="text-[10px] font-medium leading-none">{label}</span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}
