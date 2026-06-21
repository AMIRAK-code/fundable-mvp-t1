import Link from 'next/link'
import { redirect } from 'next/navigation'
import { ArrowLeft, Activity } from 'lucide-react'
import { createClient } from '@/lib/supabase/server'

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  // Gate on the admin flag (readable for one's own profile under RLS).
  const { data: profile } = (await supabase
    .from('profiles')
    .select('is_admin')
    .eq('id', user.id)
    .single()) as { data: { is_admin: boolean } | null }

  if (!profile?.is_admin) redirect('/app/feed')

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-white/10 bg-background/95 backdrop-blur-md sticky top-0 z-10">
        <div className="max-w-5xl mx-auto flex items-center gap-3 px-4 py-3 pt-[calc(env(safe-area-inset-top)+0.75rem)]">
          <Link href="/app/feed" className="text-muted-foreground hover:text-foreground transition-colors">
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <Activity className="w-5 h-5 text-[var(--brand-primary)]" />
          <h1 className="font-semibold">Platform Monitoring</h1>
        </div>
      </header>
      <main className="max-w-5xl mx-auto px-4 py-6">{children}</main>
    </div>
  )
}
