import type { InvestorDetail } from '@/lib/supabase/types'
import InvestorForm from './investor-form'

export default function InvestorProfile({ details }: { details: InvestorDetail | null }) {
  return (
    <div className="space-y-4">
      <h2 className="font-semibold text-foreground">Investment Details</h2>
      <InvestorForm details={details} />
    </div>
  )
}
