import Link from 'next/link'

export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 px-4">
      <h1 className="text-5xl font-bold tracking-tight">
        Fund<span className="text-[var(--brand-primary)]">able</span>
      </h1>
      <p className="text-muted-foreground text-lg text-center max-w-sm">
        Where Founders Meet Investors
      </p>
      <div className="flex gap-4">
        <Link
          href="/login"
          className="rounded-xl bg-[var(--brand-primary)] px-6 py-2.5 text-sm font-semibold text-white hover:opacity-90 transition-opacity"
        >
          Sign In
        </Link>
        <Link
          href="/signup"
          className="rounded-xl border border-white/10 bg-white/5 px-6 py-2.5 text-sm font-semibold hover:bg-white/10 transition-colors"
        >
          Sign Up
        </Link>
      </div>
    </main>
  )
}
