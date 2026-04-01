// Stub for bun:bundle — feature() is compile-time in Bun; always returns false in external builds
// Set on globalThis immediately to ensure it's available during CJS module init
export function feature(_flag: string): boolean {
  return false
}
// Also set globally for modules that reference feature before their local import is initialized
;(globalThis as any).feature = feature
