// Image upload validation shared by server actions and client upload paths.

const ALLOWED_IMAGE_TYPES: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/gif': 'gif',
}

export const MAX_IMAGE_BYTES = 5 * 1024 * 1024 // 5 MB

export type ImageValidation =
  | { ok: true; ext: string }
  | { ok: false; error: string }

/**
 * Validates an uploaded image by MIME type and size and returns a safe file
 * extension derived from the *type* (never from the user-supplied filename).
 * Rejecting SVG/HTML prevents stored-XSS / abuse hosting in public buckets.
 */
export function validateImageUpload(file: File): ImageValidation {
  if (!file || file.size === 0) return { ok: false, error: 'File is empty.' }
  if (file.size > MAX_IMAGE_BYTES) {
    return { ok: false, error: 'Image must be 5 MB or smaller.' }
  }
  const ext = ALLOWED_IMAGE_TYPES[file.type]
  if (!ext) {
    return { ok: false, error: 'Only JPEG, PNG, WebP, or GIF images are allowed.' }
  }
  return { ok: true, ext }
}
