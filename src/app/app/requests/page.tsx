import Image from 'next/image'
import { User, Bell } from 'lucide-react'
import { createClient } from '@/lib/supabase/server'
import RequestRow from './request-row'

export default async function RequestsPage() {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // ── Incoming pending requests ──────────────────────────────────────────
  const { data: incomingConns } = await supabase
    .from('connections')
    .select('id, sender_id, created_at')
    .eq('receiver_id', user!.id)
    .eq('status', 'pending')
    .order('created_at', { ascending: false })

  const senderIds = incomingConns?.map((c) => c.sender_id) ?? []
  const { data: senderProfiles } = senderIds.length
    ? await supabase
        .from('profiles')
        .select('id, full_name, avatar_url')
        .in('id', senderIds)
    : { data: [] }

  const senderMap = Object.fromEntries((senderProfiles ?? []).map((p) => [p.id, p]))

  // ── Sent requests ──────────────────────────────────────────────────────
  const { data: sentConns } = await supabase
    .from('connections')
    .select('id, receiver_id, status, created_at')
    .eq('sender_id', user!.id)
    .order('created_at', { ascending: false })

  const receiverIds = sentConns?.map((c) => c.receiver_id) ?? []
  const { data: receiverProfiles } = receiverIds.length
    ? await supabase
        .from('profiles')
        .select('id, full_name, avatar_url')
        .in('id', receiverIds)
    : { data: [] }

  const receiverMap = Object.fromEntries((receiverProfiles ?? []).map((p) => [p.id, p]))

  return (
    <div className="max-w-lg mx-auto px-3 sm:px-4 pt-[calc(env(safe-area-inset-top)+1rem)] pb-4 space-y-6">
      {/* ── Incoming ── */}
      <section className="space-y-3">
        <div className="flex items-center gap-2">
          <Bell className="w-4 h-4 text-[var(--brand-primary)]" />
          <h2 className="font-semibold text-sm uppercase tracking-wider text-muted-foreground">
            Incoming Requests
          </h2>
          {(incomingConns?.length ?? 0) > 0 && (
            <span className="ml-auto text-xs font-semibold text-white bg-[var(--brand-primary)] px-2 py-0.5 rounded-full">
              {incomingConns!.length}
            </span>
          )}
        </div>

        {!incomingConns?.length ? (
          <p className="text-sm text-muted-foreground py-4 text-center">
            No pending requests.
          </p>
        ) : (
          incomingConns.map((c) => {
            const profile = senderMap[c.sender_id]
            return (
              <RequestRow
                key={c.id}
                connectionId={c.id}
                profile={profile ?? null}
                createdAt={c.created_at}
              />
            )
          })
        )}
      </section>

      <hr className="border-white/10" />

      {/* ── Sent ── */}
      <section className="space-y-3">
        <h2 className="font-semibold text-sm uppercase tracking-wider text-muted-foreground">
          Sent Requests
        </h2>

        {!sentConns?.length ? (
          <p className="text-sm text-muted-foreground py-4 text-center">
            You haven't sent any requests yet.
          </p>
        ) : (
          sentConns.map((c) => {
            const profile = receiverMap[c.receiver_id]
            return (
              <SentRow
                key={c.id}
                profile={profile ?? null}
                status={c.status}
              />
            )
          })
        )}
      </section>
    </div>
  )
}

function SentRow({
  profile,
  status,
}: {
  profile: { id: string; full_name: string | null; avatar_url: string | null } | null
  status: string
}) {
  const statusStyle =
    status === 'accepted'
      ? 'text-[var(--brand-success)] bg-[var(--brand-success)]/10'
      : status === 'declined'
        ? 'text-destructive bg-destructive/10'
        : 'text-muted-foreground bg-white/5'

  return (
    <div className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/5 p-4">
      {profile?.avatar_url ? (
        <Image
          src={profile.avatar_url}
          alt={profile.full_name ?? ''}
          width={40}
          height={40}
          className="rounded-full object-cover flex-shrink-0"
        />
      ) : (
        <div className="w-10 h-10 rounded-full bg-white/10 flex items-center justify-center flex-shrink-0">
          <User className="w-4 h-4 text-muted-foreground" />
        </div>
      )}
      <span className="flex-1 font-medium text-sm truncate">
        {profile?.full_name ?? 'Unknown'}
      </span>
      <span className={`text-xs font-semibold px-2.5 py-1 rounded-full capitalize ${statusStyle}`}>
        {status}
      </span>
    </div>
  )
}
