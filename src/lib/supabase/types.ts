export type Role = 'founder' | 'investor'

export interface SocialLinks {
  github?: string
  linkedin?: string
  reddit?: string
  instagram?: string
  website?: string
}
export type ConnectionStatus = 'pending' | 'accepted' | 'declined'

export type StartupStatus =
  | 'idea'
  | 'pre_seed'
  | 'mvp'
  | 'pre_launch'
  | 'launched'
  | 'scaling'
  | 'profitable'

export type InvestorStatus =
  | 'looking'
  | 'reviewing'
  | 'invested'
  | 'advisory'
  | 'closed'

export const STARTUP_STATUS_LABELS: Record<StartupStatus, string> = {
  idea: 'Idea',
  pre_seed: 'Pre-seed',
  mvp: 'MVP',
  pre_launch: 'Pre-launch',
  launched: 'Launched',
  scaling: 'Scaling',
  profitable: 'Profitable',
}

export const INVESTOR_STATUS_LABELS: Record<InvestorStatus, string> = {
  looking: 'Looking for deals',
  reviewing: 'Reviewing pitches',
  invested: 'Recently invested',
  advisory: 'Advisory only',
  closed: 'Closed for now',
}

// Tailwind class names per status — green = active, blue = in-progress, amber = passive, gray = dormant
export const STARTUP_STATUS_COLORS: Record<StartupStatus, string> = {
  idea: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
  pre_seed: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
  mvp: 'bg-blue-500/15 text-blue-400 border-blue-500/30',
  pre_launch: 'bg-blue-500/15 text-blue-400 border-blue-500/30',
  launched: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
  scaling: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
  profitable: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
}

export const INVESTOR_STATUS_COLORS: Record<InvestorStatus, string> = {
  looking: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
  reviewing: 'bg-blue-500/15 text-blue-400 border-blue-500/30',
  invested: 'bg-blue-500/15 text-blue-400 border-blue-500/30',
  advisory: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
  closed: 'bg-white/10 text-muted-foreground border-white/10',
}

export interface Profile {
  id: string
  role: Role
  full_name: string | null
  avatar_url: string | null
  bio: string | null
  created_at: string
}

export interface Startup {
  id: string
  founder_id: string
  name: string
  pitch: string
  hero_image_url: string | null
  industry: string | null
  status: StartupStatus | null
  published: boolean
  links: SocialLinks
  created_at: string
}

export interface InvestmentOffer {
  id: string
  investor_id: string
  title: string
  description: string
  amount: string | null
  stage: string | null
  sectors: string[] | null
  status: 'active' | 'closed'
  links: SocialLinks
  created_at: string
}

export interface InvestorDetail {
  id: string
  investor_id: string
  firm_name: string | null
  check_size: string | null
  sectors: string[] | null
  thesis: string | null
  status: InvestorStatus | null
  created_at: string
}

export interface Connection {
  id: string
  sender_id: string
  receiver_id: string
  status: ConnectionStatus
  created_at: string
}

export interface ChatRoom {
  id: string
  connection_id: string
  created_at: string
}

export interface Message {
  id: string
  chat_room_id: string
  sender_id: string
  content: string
  message_type: 'text' | 'image'
  media_url: string | null
  created_at: string
}

export interface MessageRead {
  chat_room_id: string
  user_id: string
  last_read_at: string
}

// Row shape returned by the get_conversation_overview() RPC
export interface ConversationOverview {
  chat_room_id: string
  last_content: string
  last_type: 'text' | 'image'
  last_sender_id: string
  last_at: string
  unread_count: number
}

export interface PushSubscriptionRow {
  id: string
  user_id: string
  endpoint: string
  p256dh: string
  auth: string
  created_at: string
}

// Joined shapes used in the UI
export interface StartupWithFounder extends Startup {
  profiles: Profile
}

export interface InvestorWithProfile extends InvestorDetail {
  profiles: Profile
}

export interface ConnectionWithProfiles extends Connection {
  sender: Profile
  receiver: Profile
}

export interface MessageWithSender extends Message {
  profiles: Profile
}

// Supabase Database type (used by createClient generic)
export type Database = {
  public: {
    Tables: {
      profiles: { Row: Profile; Insert: Omit<Profile, 'created_at'>; Update: Partial<Omit<Profile, 'id' | 'created_at'>> }
      startups: { Row: Startup; Insert: Omit<Startup, 'id' | 'created_at'>; Update: Partial<Omit<Startup, 'id' | 'created_at'>> }
      investor_details: { Row: InvestorDetail; Insert: Omit<InvestorDetail, 'id' | 'created_at'>; Update: Partial<Omit<InvestorDetail, 'id' | 'created_at'>> }
      connections: { Row: Connection; Insert: Omit<Connection, 'id' | 'created_at' | 'status'>; Update: Partial<Pick<Connection, 'status'>> }
      chat_rooms: { Row: ChatRoom; Insert: Omit<ChatRoom, 'id' | 'created_at'>; Update: never }
      // id may be supplied client-side (crypto.randomUUID) for optimistic sends
      messages: { Row: Message; Insert: Omit<Message, 'id' | 'created_at'> & { id?: string }; Update: never }
      investment_offers: { Row: InvestmentOffer; Insert: Omit<InvestmentOffer, 'id' | 'created_at'>; Update: Partial<Omit<InvestmentOffer, 'id' | 'created_at'>> }
      message_reads: { Row: MessageRead; Insert: MessageRead | Omit<MessageRead, 'last_read_at'>; Update: Partial<Pick<MessageRead, 'last_read_at'>> }
      push_subscriptions: { Row: PushSubscriptionRow; Insert: Omit<PushSubscriptionRow, 'id' | 'created_at'>; Update: Partial<Omit<PushSubscriptionRow, 'id' | 'created_at' | 'user_id'>> }
    }
    Views: Record<string, never>
    Functions: {
      get_unread_counts: {
        Args: Record<string, never>
        Returns: { chat_room_id: string; unread_count: number }[]
      }
      get_conversation_overview: {
        Args: Record<string, never>
        Returns: ConversationOverview[]
      }
      get_push_targets: {
        Args: { target: string }
        Returns: { endpoint: string; p256dh: string; auth: string }[]
      }
    }
    Enums: { role: Role; connection_status: ConnectionStatus }
  }
}
