import { Skeleton, SkeletonAvatar } from '@/components/skeleton'

export default function MessagesLoading() {
  return (
    <div className="max-w-lg mx-auto px-3 sm:px-4 pt-[calc(env(safe-area-inset-top)+1rem)] pb-4 space-y-3">
      <h2 className="font-semibold text-sm uppercase tracking-wider text-muted-foreground mb-2">
        Messages
      </h2>

      <div className="space-y-3 stagger-children">
        {Array.from({ length: 6 }).map((_, i) => (
          <div
            key={i}
            className="animate-in-up flex items-center gap-3 rounded-2xl border border-white/10 bg-white/5 p-4"
          >
            <SkeletonAvatar size={48} />
            <div className="flex-1 min-w-0 space-y-2">
              <Skeleton className="h-3.5 w-1/2 rounded-md" />
              <Skeleton className="h-3 w-3/4 rounded-md" />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
