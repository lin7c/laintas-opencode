type Channel = "dev" | "beta" | "prod"
const raw = import.meta.env.OPENCODE_CHANNEL
export const CHANNEL: Channel = raw === "dev" || raw === "beta" || raw === "prod" ? raw : "dev"

// Auto-update is disabled for laintas-opencode desktop v1. The Laintas repo
// (lin7c/laintas-opencode) hosts both the CLI releases (tags "v*") and the
// desktop releases (tags "desktop-v*"), and electron-updater's GitHub
// provider cannot resolve desktop updates from that layout: it looks for a
// latest.yml on the newest semver-looking release, which is a CLI release
// without one. The publish metadata in electron-builder.config.ts already
// points at lin7c/laintas-opencode; re-enable this once a dedicated desktop
// update feed exists (see desktop-recon.md, updater section).
export const UPDATER_ENABLED = false
