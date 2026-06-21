import Link from 'next/link'
import OAuthButtons from '@/components/auth/oauth-buttons'
import LoginForm from './login-form'

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string }>
}) {
  const { next: rawNext } = await searchParams
  const next =
    rawNext && rawNext.startsWith('/') && !rawNext.startsWith('//')
      ? rawNext
      : '/app/feed'

  return (
    <div className="rounded-2xl border border-white/10 bg-white/5 backdrop-blur-md p-8">
      <h2 className="text-xl font-semibold mb-6">Sign in to your account</h2>

      <OAuthButtons next={next} />
      <LoginForm next={next} />

      <p className="mt-6 text-center text-sm text-muted-foreground">
        No account?{' '}
        <Link href="/signup" className="text-[var(--brand-primary)] hover:underline">
          Sign up
        </Link>
      </p>
    </div>
  )
}
