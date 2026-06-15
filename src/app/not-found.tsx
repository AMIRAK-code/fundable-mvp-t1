import Link from 'next/link'
import { Compass } from 'lucide-react'

export default function NotFound() {
  return (
    <div className="min-h-safe-screen flex flex-col items-center justify-center px-6 text-center bg-background">
      <div className="w-14 h-14 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center mb-4">
        <Compass className="w-6 h-6 text-muted-foreground" />
      </div>
      <h2 className="font-semibold text-lg">Page not found</h2>
      <p className="text-sm text-muted-foreground mt-1.5 max-w-[280px] leading-relaxed">
        This page doesn&apos;t exist or was removed.
      </p>
      <Link
        href="/app/feed"
        className="press mt-6 px-6 py-2.5 rounded-xl bg-[var(--brand-primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity"
      >
        Back to feed
      </Link>
    </div>
  )
}
