import { notFound } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import ChatView from './chat-view'
import type { ProfileData } from './chat-view'

export default async function ChatRoomPage({
  params,
}: {
  params: Promise<{ roomId: string }>
}) {
  const { roomId } = await params
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Get room with its connection (RLS ensures only participants can access)
  const { data: room } = await supabase
    .from('chat_rooms')
    .select('id, connection_id')
    .eq('id', roomId)
    .single()

  if (!room) notFound()

  const { data: conn } = await supabase
    .from('connections')
    .select('sender_id, receiver_id')
    .eq('id', room.connection_id)
    .single()

  if (!conn) notFound()

  const isParticipant =
    conn.sender_id === user!.id || conn.receiver_id === user!.id
  if (!isParticipant) notFound()

  const otherId =
    conn.sender_id === user!.id ? conn.receiver_id : conn.sender_id

  // Profile, both role-data branches, messages and the read receipt are all
  // independent of each other — run the whole batch in parallel
  const [
    { data: otherUser },
    { data: startup },
    { data: investorDetail },
    { data: offers },
    { data: raw },
  ] = await Promise.all([
    supabase
      .from('profiles')
      .select('id, full_name, avatar_url, role')
      .eq('id', otherId)
      .single(),
    supabase
      .from('startups')
      .select('id, name, pitch, hero_image_url, industry, status, links')
      .eq('founder_id', otherId)
      .eq('published', true)
      .limit(1)
      .maybeSingle(),
    supabase
      .from('investor_details')
      .select('id, firm_name, check_size, sectors, thesis, status')
      .eq('investor_id', otherId)
      .maybeSingle(),
    supabase
      .from('investment_offers')
      .select('id, title, description, amount, stage, sectors, status, links')
      .eq('investor_id', otherId)
      .eq('status', 'active'),
    supabase
      .from('messages')
      .select('id, sender_id, content, message_type, media_url, created_at')
      .eq('chat_room_id', roomId)
      .order('created_at', { ascending: false })
      .limit(50),
    // Mark the room read for the current user (own row only)
    supabase
      .from('message_reads')
      .upsert(
        {
          chat_room_id: roomId,
          user_id: user!.id,
          last_read_at: new Date().toISOString(),
        },
        { onConflict: 'chat_room_id,user_id' }
      ),
  ])

  let profileData: ProfileData = null
  if (otherUser?.role === 'founder' && startup) {
    profileData = { type: 'founder', startup }
  } else if (otherUser?.role === 'investor' && investorDetail) {
    profileData = { type: 'investor', detail: investorDetail, offers: offers ?? [] }
  }

  const initialMessages = (raw ?? []).reverse()

  return (
    <ChatView
      roomId={roomId}
      currentUserId={user!.id}
      otherUser={otherUser ?? { id: otherId, full_name: 'Unknown', avatar_url: null, role: 'founder' as const }}
      initialMessages={initialMessages}
      profileData={profileData}
    />
  )
}
