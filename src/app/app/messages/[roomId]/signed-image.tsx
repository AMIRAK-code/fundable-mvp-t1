'use client'

import { useEffect, useState } from 'react'
import Image from 'next/image'
import { createClient } from '@/lib/supabase/client'

/**
 * Renders a chat image stored in the private `message-media` bucket. The
 * message row stores the object *path* (e.g. "{roomId}/123.jpg"); we mint a
 * short-lived signed URL on demand. Legacy rows that stored a full public URL
 * (start with http) are rendered as-is for backwards compatibility.
 */
export default function SignedImage({
  path,
  isOwn,
}: {
  path: string
  isOwn: boolean
}) {
  const isLegacyUrl = path.startsWith('http')
  const [url, setUrl] = useState<string | null>(isLegacyUrl ? path : null)

  useEffect(() => {
    if (isLegacyUrl) return
    let active = true
    createClient()
      .storage.from('message-media')
      .createSignedUrl(path, 3600)
      .then(({ data }) => {
        if (active && data?.signedUrl) setUrl(data.signedUrl)
      })
    return () => {
      active = false
    }
  }, [path, isLegacyUrl])

  if (!url) {
    return (
      <div
        className={`max-w-[72%] w-44 h-44 rounded-2xl bg-white/5 animate-pulse ${
          isOwn ? 'rounded-br-sm' : 'rounded-bl-sm'
        }`}
      />
    )
  }

  return (
    <a
      href={url}
      target="_blank"
      rel="noopener noreferrer"
      className={`max-w-[72%] rounded-2xl overflow-hidden block ${
        isOwn ? 'rounded-br-sm' : 'rounded-bl-sm'
      }`}
    >
      <Image
        src={url}
        alt="Image"
        width={240}
        height={240}
        className="object-cover max-h-60 w-auto"
        unoptimized
      />
    </a>
  )
}
