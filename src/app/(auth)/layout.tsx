export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-safe-screen flex items-center justify-center px-4 py-8 sm:py-12 pt-[calc(env(safe-area-inset-top)+2rem)] pb-[calc(env(safe-area-inset-bottom)+2rem)] bg-background">
      <div className="w-full max-w-md">
        <div className="text-center mb-6 sm:mb-8">
          <h1 className="text-3xl sm:text-4xl font-bold tracking-tight">
            Fund<span className="text-[var(--brand-primary)]">able</span>
          </h1>
          <p className="text-muted-foreground mt-2 text-sm">
            Where Founders Meet Investors
          </p>
        </div>
        {children}
      </div>
    </div>
  )
}
