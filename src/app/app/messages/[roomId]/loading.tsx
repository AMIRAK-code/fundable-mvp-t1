import { ArrowLeft } from 'lucide-react'
import { Skeleton, SkeletonAvatar } from '@/components/skeleton'

export default function ChatRoomLoading() {
  return (
    <div className="flex flex-col h-[calc(100dvh-64px-env(safe-area-inset-bottom))] bg-background">
      {/* Mirrors chat header */}
      <header className="border-b border-white/10 bg-background/95 backdrop-blur-md flex-shrink-0">
        <div className="flex items-center gap-3 px-3 sm:px-4 py-2.5 pt-[calc(env(safe-area-inset-top)+0.625rem)]">
          <span className="p-1 text-muted-foreground flex-shrink-0" aria-hidden="true">
            <ArrowLeft className="w-5 h-5" />
          </span>
          <SkeletonAvatar size={36} />
          <div className="flex-1 min-w-0">
            <Skeleton className="h-4 w-32 rounded-md" />
          </div>
        </div>
      </header>

      {/* Message bubbles, alternating sides */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3 stagger-children">
        <div className="animate-in-up flex items-end gap-2 justify-start">
          <SkeletonAvatar size={24} />
          <Skeleton className="h-12 w-48 max-w-[72%] rounded-2xl rounded-bl-sm" />
        </div>
        <div className="animate-in-up flex items-end gap-2 justify-end">
          <Skeleton className="h-9 w-36 max-w-[72%] rounded-2xl rounded-br-sm" />
        </div>
        <div className="animate-in-up flex items-end gap-2 justify-start">
          <SkeletonAvatar size={24} />
          <Skeleton className="h-9 w-40 max-w-[72%] rounded-2xl rounded-bl-sm" />
        </div>
        <div className="animate-in-up flex items-end gap-2 justify-end">
          <Skeleton className="h-14 w-52 max-w-[72%] rounded-2xl rounded-br-sm" />
        </div>
      </div>

      {/* Mirrors input bar */}
      <div className="flex items-center gap-2 px-4 py-3 border-t border-white/10 bg-background flex-shrink-0 pb-safe">
        <Skeleton className="w-10 h-10 rounded-xl flex-shrink-0" />
        <Skeleton className="flex-1 h-10 rounded-xl" />
        <Skeleton className="w-10 h-10 rounded-xl flex-shrink-0" />
      </div>
    </div>
  )
}
