'use client'

import { useEffect } from 'react'
import { RefreshCw } from 'lucide-react'

export default function ErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error(error)
  }, [error])

  return (
    <div className="min-h-safe-screen flex flex-col items-center justify-center px-6 text-center bg-background">
      <div className="w-14 h-14 rounded-2xl bg-destructive/10 border border-destructive/20 flex items-center justify-center mb-4">
        <RefreshCw className="w-6 h-6 text-destructive" />
      </div>
      <h2 className="font-semibold text-lg">Something went wrong</h2>
      <p className="text-sm text-muted-foreground mt-1.5 max-w-[280px] leading-relaxed">
        An unexpected error occurred. Your data is safe — try again.
      </p>
      <button
        onClick={reset}
        className="press mt-6 px-6 py-2.5 rounded-xl bg-[var(--brand-primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity"
      >
        Try again
      </button>
    </div>
  )
}
