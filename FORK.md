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
- **Rebrand:** the global app directory is `laintas-opencode`
  (config/data/cache/state), the built binary is named
  `laintas-opencode`, and CLI usage/descriptions use that name. Internal
  package names (`@opencode-ai/*`), `OPENCODE_*` environment variables and
  the upstream LICENSE were deliberately left unchanged.
- Known leftover: the TUI wordmark in `packages/tui/src/logo.ts` is a
  block-rendered drawing of the word "opencode"; it has not been redrawn.

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
