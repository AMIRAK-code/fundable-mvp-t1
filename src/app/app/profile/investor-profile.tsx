import type { InvestorDetail, InvestmentOffer } from '@/lib/supabase/types'
import InvestorForm from './investor-form'
import InvestorOffers from './investor-offers'

interface Props {
  details: InvestorDetail | null
  offers: InvestmentOffer[]
}

export default function InvestorProfile({ details, offers }: Props) {
  return (
    <div className="space-y-8">
      <div className="space-y-4">
        <h2 className="font-semibold text-foreground">Investment Details</h2>
        <InvestorForm details={details} />
      </div>
      <InvestorOffers offers={offers} />
    </div>
  )
}
