import type { InvestorDetail, InvestmentOffer } from '@/lib/supabase/types'
import InvestorForm from './investor-form'
import InvestorOffers from './investor-offers'

interface Props {
  details: InvestorDetail | null
  offers: InvestmentOffer[]
}

export default function InvestorProfile({ details, offers }: Props) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 lg:gap-8">
      <section className="space-y-4" aria-label="Investment details">
        <h2 className="font-semibold text-base sm:text-lg">Investment Details</h2>
        <InvestorForm details={details} />
      </section>
      <InvestorOffers offers={offers} />
    </div>
  )
}
