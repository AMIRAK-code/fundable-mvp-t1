#!/usr/bin/env node
/**
 * Seed a test account in your Supabase project (email/password, pre-confirmed).
 *
 * Why a script: Supabase user creation happens in YOUR project, not in this
 * repo. Run it locally/CI with the service-role key in your environment.
 *
 * Setup:
 *   cp .env.example .env.local   # fill in NEXT_PUBLIC_SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY
 *
 * Usage:
 *   node scripts/create-test-account.mjs \
 *     --email test@fundable.test --password 'Passw0rd!' \
 *     --role founder --name "Test Founder" [--admin]
 *
 * Notes:
 *   - role is 'founder' or 'investor' (stored in user metadata; the
 *     handle_new_user trigger materializes it + full_name into profiles).
 *   - --admin sets profiles.is_admin = true so the account can open /admin
 *     (requires migration 0003 applied).
 *   - Re-running with an existing email is a no-op error from Supabase.
 */
import { readFileSync } from 'node:fs'
import { createClient } from '@supabase/supabase-js'

// Minimal .env.local loader (no dependency); real env vars take precedence.
try {
  for (const line of readFileSync(new URL('../.env.local', import.meta.url), 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/)
    if (m && !(m[1] in process.env)) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '')
  }
} catch {
  /* no .env.local — rely on the ambient environment */
}

function arg(name, fallback) {
  const i = process.argv.indexOf(`--${name}`)
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback
}
const hasFlag = (name) => process.argv.includes(`--${name}`)

const url = process.env.NEXT_PUBLIC_SUPABASE_URL
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
if (!url || !serviceKey) {
  console.error('✖ Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.')
  console.error('  Set them in .env.local (see .env.example) or the environment.')
  process.exit(1)
}

const email = arg('email', 'test@fundable.test')
const password = arg('password', 'Passw0rd!')
const role = arg('role', 'founder')
const fullName = arg('name', 'Test User')
const makeAdmin = hasFlag('admin')

if (!['founder', 'investor'].includes(role)) {
  console.error(`✖ --role must be 'founder' or 'investor' (got '${role}')`)
  process.exit(1)
}

const supabase = createClient(url, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
})

const { data, error } = await supabase.auth.admin.createUser({
  email,
  password,
  email_confirm: true,
  user_metadata: { role, full_name: fullName },
})

if (error) {
  console.error(`✖ Failed to create user: ${error.message}`)
  process.exit(1)
}

const userId = data.user.id
console.log(`✓ Created ${role} account: ${email}  (id ${userId})`)

if (makeAdmin) {
  const { error: adminErr } = await supabase
    .from('profiles')
    .update({ is_admin: true })
    .eq('id', userId)
  if (adminErr) {
    console.error(`⚠ User created but granting admin failed: ${adminErr.message}`)
    console.error('  (Is migration 0003 applied? You can also run the SQL manually.)')
    process.exit(1)
  }
  console.log('✓ Granted admin (is_admin = true) — can open /admin')
}

console.log('\nSign in at /login with the email + password above.')
