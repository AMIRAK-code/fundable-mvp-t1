'use client'

export default function GlobalError({
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <html lang="en" className="dark">
      <body style={{ background: '#0a0a0a', color: '#fafafa', fontFamily: 'system-ui, sans-serif' }}>
        <div
          style={{
            minHeight: '100dvh',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            textAlign: 'center',
            padding: '0 24px',
          }}
        >
          <h2 style={{ fontWeight: 600, fontSize: 18 }}>Something went wrong</h2>
          <p style={{ fontSize: 14, opacity: 0.6, marginTop: 8 }}>
            Fundable hit an unexpected error.
          </p>
          <button
            onClick={reset}
            style={{
              marginTop: 24,
              padding: '10px 24px',
              borderRadius: 12,
              background: '#3b82f6',
              color: '#fff',
              fontSize: 14,
              fontWeight: 600,
              border: 'none',
            }}
          >
            Reload
          </button>
        </div>
      </body>
    </html>
  )
}
