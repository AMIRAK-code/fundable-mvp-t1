export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen flex items-center justify-center px-4 py-12 bg-background">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold tracking-tight">
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
