import { Skeleton, SkeletonAvatar } from '@/components/skeleton'

export default function ProfileLoading() {
  return (
    <div className="max-w-lg mx-auto px-3 sm:px-4 pt-[calc(env(safe-area-inset-top)+1rem)] pb-4 space-y-5 stagger-children">
      {/* Mirrors profile header */}
      <div className="animate-in-up flex items-center gap-3 sm:gap-4">
        <SkeletonAvatar size={56} />
        <div className="flex-1 min-w-0 space-y-2">
          <Skeleton className="h-4 w-40 rounded-md" />
          <Skeleton className="h-3 w-20 rounded-md" />
        </div>
      </div>

      <hr className="border-white/10" />

      {/* Role-specific form blocks */}
      <Skeleton className="animate-in-up h-40 rounded-2xl" />
      <Skeleton className="animate-in-up h-40 rounded-2xl" />
    </div>
  )
}
