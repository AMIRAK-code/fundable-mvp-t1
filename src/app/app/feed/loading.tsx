import { Skeleton } from '@/components/skeleton'

export default function FeedLoading() {
  return (
    <div className="flex flex-col min-h-screen">
      {/* Mirrors FeedHeader */}
      <header className="sticky top-0 z-40 bg-background/95 backdrop-blur-md border-b border-white/10 pt-[env(safe-area-inset-top)]">
        <div className="flex items-center justify-between gap-2 px-3 sm:px-4 py-2.5 max-w-lg mx-auto">
          <span className="text-base sm:text-lg font-bold tracking-tight flex-shrink-0">
            Fund<span className="text-[var(--brand-primary)]">able</span>
          </span>
          <Skeleton className="h-[38px] w-40 rounded-xl" />
        </div>
      </header>

      <div className="flex-1 px-4 pt-4 pb-6 max-w-lg mx-auto w-full space-y-4 stagger-children">
        <Skeleton className="animate-in-up h-56 rounded-2xl" />
        <Skeleton className="animate-in-up h-56 rounded-2xl" />
      </div>
    </div>
  )
}
