import Link from 'next/link'
import { ChevronLeft } from 'lucide-react'
import MfaManager from './mfa-manager'

export default function SecurityPage() {
  return (
    <div className="max-w-lg mx-auto px-3 sm:px-4 pt-[calc(env(safe-area-inset-top)+1rem)] pb-4 space-y-5">
      <div className="flex items-center gap-2">
        <Link
          href="/app/profile"
          className="flex items-center text-sm text-muted-foreground hover:text-foreground"
        >
          <ChevronLeft className="w-5 h-5" />
          Profile
        </Link>
      </div>

      <div>
        <h1 className="text-lg font-bold">Security</h1>
        <p className="text-sm text-muted-foreground mt-0.5">
          Add two-factor authentication for an extra layer of protection.
        </p>
      </div>

      <section className="space-y-3">
        <h2 className="text-sm font-semibold text-muted-foreground">
          Two-factor authentication (TOTP)
        </h2>
        <MfaManager />
      </section>
    </div>
  )
}
