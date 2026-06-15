import { Bell } from 'lucide-react'
import { Skeleton, SkeletonAvatar } from '@/components/skeleton'

export default function RequestsLoading() {
  return (
    <div className="max-w-lg mx-auto px-3 sm:px-4 pt-[calc(env(safe-area-inset-top)+1rem)] pb-4 space-y-6">
      <section className="space-y-3">
        {/* Mirrors incoming requests header */}
        <div className="flex items-center gap-2">
          <Bell className="w-4 h-4 text-[var(--brand-primary)]" />
          <h2 className="font-semibold text-sm uppercase tracking-wider text-muted-foreground">
            Incoming Requests
          </h2>
        </div>

        <div className="space-y-3 stagger-children">
          {Array.from({ length: 3 }).map((_, i) => (
            <div
              key={i}
              className="animate-in-up flex items-center gap-3 rounded-2xl border border-white/10 bg-white/5 p-4"
            >
              <SkeletonAvatar size={44} />
              <div className="flex-1 min-w-0 space-y-2">
                <Skeleton className="h-3.5 w-1/2 rounded-md" />
                <Skeleton className="h-3 w-1/3 rounded-md" />
              </div>
              <div className="flex gap-2 flex-shrink-0">
                <Skeleton className="h-8 w-20 rounded-lg" />
                <Skeleton className="h-8 w-20 rounded-lg" />
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}
