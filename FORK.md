# laintas-opencode — fork notes

`laintas-opencode` is a fork of **OpenCode v1.19.5**
([anomalyco/opencode](https://github.com/anomalyco/opencode), tag `v1.19.5`).

OpenCode is licensed under the MIT License; the original copyright notice
and license text are retained unchanged in [LICENSE](LICENSE). This fork is
a separate product maintained by Laintas. It is **not** OpenCode, and it is
also distinct from Laintas CLI (an independent Laintas product); the two
must not be conflated.

## What was removed

- **All bundled vendor model providers.** `BUNDLED_PROVIDERS` in
  `packages/opencode/src/provider/provider.ts` now contains only
  `@ai-sdk/openai-compatible`.
- **The models.dev vendor catalog.** The provider layer builds its catalog
  from an empty record instead of the fetched models.dev data, and all
  per-vendor custom loaders in `custom()` were deleted.
- **All vendor auth plugins** (Codex, Copilot, Modal, GitLab, Poe,
  Cloudflare Workers AI / AI Gateway, Azure, DigitalOcean, Snowflake
  Cortex, XAI, Cerebras). `internalPlugins()` in
  `packages/opencode/src/plugin/index.ts` returns only the Laintas plugin.
- **Upstream self-update.** `Installation.latest` always reports the
  installed version; `upgrade` / `upgradeMajor` refuse with a
  managed-by-Laintas message; the TUI update check is disabled; the
  `upgrade` CLI command is a stub explaining that updates come from
  Laintas.

## What was added

- **Built-in Laintas provider** (`packages/opencode/src/plugin/laintas.ts`):
  - Sign-in is a Laintas device-code login against
    `https://accounts.laintas.com/api/auth/cli-device` (client
    `opencode`). No API key is shown or handled by the user.
  - Inference goes to the Laintas OpenAI-compatible endpoint
    `https://laintas.com/v1` with the session token injected per request;
    billing is settled against the user's Laintas account balance.
  - The model list is populated from `GET https://laintas.com/v1/models`
    for the signed-in account.
  - **Model picker badges:** each model row in the TUI picker shows the
    same badge as the Laintas web picker - the model's tier (e.g. `T2`),
    `laintas-model` for models on Laintas GPUs, or `Activated` for models
    served by the caller's own key. The facade passes the gateway's flags
    through under a `laintas` key on each `/v1/models` entry; the plugin
    derives the badge text and carries it in the model's `options`
    (`laintasBadge`), the dialog renders it as the row footer, and the
    plugin's request wrapper strips it from outgoing request bodies (the
    AI SDK would otherwise spread provider options into the body).
- **Rebrand:** the global app directory is `laintas-opencode`
  (config/data/cache/state), the built binary is named
  `laintas-opencode`, and CLI usage/descriptions use that name. Internal
  package names (`@opencode-ai/*`), `OPENCODE_*` environment variables and
  the upstream LICENSE were deliberately left unchanged.
- Known leftover: the TUI wordmark in `packages/tui/src/logo.ts` is a
  block-rendered drawing of the word "opencode"; it has not been redrawn.

## Desktop app

`packages/desktop` is upstream OpenCode's Electron desktop app (Electron
42, electron-builder 26), carried in this fork and rebranded on the
`desktop` branch (Phase 1, on top of the `laintas` branch):

- **Origin:** the desktop package ships in the upstream v1.19.5 tree; the
  fork did not write a new shell. It renders the shared `@opencode-ai/app`
  UI and talks to the same Laintas-only backend as the CLI.
- **Identity:** app ids are `com.laintas.opencode` /
  `com.laintas.opencode.beta` / `com.laintas.opencode.dev` (builder config,
  the runtime `APP_IDS`/`APP_NAMES` in `src/main/index.ts`, the metainfo
  generator, and the config tests all agree); product name is
  `laintas-opencode`; artifacts are named
  `laintas-opencode-desktop-<os>-<arch>.<ext>`; homepage is
  https://opencode.laintas.com. The `opencode://` URL scheme is kept for
  deep-link compatibility.
- **Icons:** the Laintas Everything asterisk tile (deep green, cream
  asterisk, amber core) replaces the upstream artwork in
  `packages/desktop/icons/{dev,beta,prod}` for every size
  electron-builder consumes, including `icon.icns` and `icon.ico`
  (generated locally from `icons/laintas-asterisk.svg` with cairosvg +
  Pillow). The Tauri-era `android/` and `ios/` subfolders still hold
  upstream art; nothing in the Electron build reads them.
- **Updates:** the in-app auto-updater is **disabled for v1**
  (`UPDATER_ENABLED = false` in `src/main/constants.ts`). This repo hosts
  CLI releases (`v*`) and desktop releases (`desktop-v*`) side by side,
  which electron-updater's GitHub provider cannot resolve desktop updates
  from; the builder `publish` metadata already points at
  `lin7c/laintas-opencode` for when a dedicated desktop feed exists.
- **Signing status (Phase 2):** v1 desktop builds ship **unsigned and
  unnotarized**. The builder config only signs/notarizes when
  `LAINTAS_DESKTOP_SIGN=1` is set (it is not, anywhere); the Windows sign
  hook self-skips without Azure Trusted Signing variables. macOS
  Gatekeeper blocks first launch until the user allows the app manually,
  and Windows SmartScreen warns. Code-signing certificates are a separate
  decision, tracked outside this repo.
- **Sidecar CLI (Phase 2):** every channel build (dev/beta/prod) bundles
  this fork's own CLI build from `packages/opencode/dist` as
  `resources/opencode-cli`; nothing is downloaded from npm anymore. The
  desktop's default (v1) mode runs the embedded node server built from
  this same tree, so the sidecar is only exercised by the opt-in v2
  background-CLI mode (`OPENCODE_SIDECAR_V2=1`). Known gap: the v2 daemon
  commands the desktop drives (`service status|start|get password`)
  belong to upstream's next-generation CLI and are **not** implemented
  by this fork's CLI, so v2 mode cannot manage a daemon until that
  changes; v1 mode is unaffected. WSL support installs the CLI from the
  `desktop-v*` GitHub release asset
  `laintas-opencode-linux-x64-baseline` published by the same workflow.
- **Provider UI (Phase 2):** the shared app's third-party provider entry
  points are removed — the popular/custom rows in provider settings, the
  connect buttons in the model dialogs, the "add more models" panels and
  the opencode.ai/zen links. The connect dialog itself remains for the
  Laintas device-code sign-in, and only ever lists the providers the
  server exposes (Laintas). The notification icon is the local asterisk
  artwork instead of an opencode.ai URL.
- **Still open:** renderer branding leftovers (splash wordmark, changelog
  and docs URLs) are tracked in `desktop-recon.md` at the workspace root.

## How to build

Requires [Bun](https://bun.sh).

```bash
bun install
cd packages/opencode
bun run script/build.ts --single   # current platform only
# artifact: packages/opencode/dist/<target>/bin/laintas-opencode
```

(See `script/build.ts` for the exact flags; `--single` builds just the
host platform, a bare run builds every platform.)

## Maintenance model

- Upstream is **pinned** at v1.19.5. This fork does not track upstream
  releases automatically and never self-updates into upstream OpenCode.
- All Laintas changes live as small, logical commits on the `laintas`
  branch on top of the pinned release commit, so they can be reviewed —
  and, if ever needed, replayed onto a newer upstream tag — as a patch
  series.
- Upstream security fixes are evaluated and cherry-picked deliberately
  by the Laintas maintainer; new builds are published by Laintas through
  its own channels.
