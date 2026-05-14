export type Role = 'founder' | 'investor'

export interface SocialLinks {
  github?: string
  linkedin?: string
  reddit?: string
  instagram?: string
  website?: string
}
export type ConnectionStatus = 'pending' | 'accepted' | 'declined'

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
      messages: { Row: Message; Insert: Omit<Message, 'id' | 'created_at'>; Update: never }
      investment_offers: { Row: InvestmentOffer; Insert: Omit<InvestmentOffer, 'id' | 'created_at'>; Update: Partial<Omit<InvestmentOffer, 'id' | 'created_at'>> }
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: { role: Role; connection_status: ConnectionStatus }
  }
}
