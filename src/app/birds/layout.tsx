import type { Metadata } from 'next'
import Link from 'next/link'
import BirdNav from './bird-nav'

export const metadata: Metadata = {
  title: {
    default: 'Aviary — study birds, ask birders',
    template: '%s · Aviary',
  },
  description:
    'A study guide and question board for birders, bird watchers and breeders.',
}

export default function BirdsLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex flex-col min-h-safe-screen bg-background">
      <header className="sticky top-0 z-50 border-b border-white/10 bg-background/90 backdrop-blur-md">
        <div className="mx-auto flex max-w-3xl items-center justify-between gap-4 px-4 py-3">
          <Link href="/birds" className="text-lg font-bold tracking-tight">
            Avi<span className="text-[var(--bird-primary)]">ary</span>
          </Link>
          <BirdNav />
        </div>
      </header>

      <main className="mx-auto w-full max-w-3xl flex-1 px-4 py-6">{children}</main>

      <footer className="border-t border-white/10 px-4 py-6">
        <p className="mx-auto max-w-3xl text-xs leading-relaxed text-muted-foreground">
          Measurements and breeding figures are typical published ranges and vary by
          population. Keeping, breeding and releasing birds is regulated in most
          countries — check the rules where you live before acquiring stock.
        </p>
      </footer>
    </div>
  )
}
