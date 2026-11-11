# laintas-opencode

A terminal AI agent that ships with exactly one backend: **Laintas**.

`laintas-opencode` is a Laintas-maintained fork of [OpenCode](https://github.com/anomalyco/opencode) (MIT), pinned to upstream v1.19.5 with a small set of patch commits on top. All other vendors' model adapters, sign-in plugins and the models.dev catalog have been removed. What remains is the OpenCode terminal experience, wired exclusively to your Laintas account:

- **Sign in with Laintas** — device-code login against `accounts.laintas.com`. No API key to copy or paste; the token is your login.
- **Models from Laintas** — the model list is fetched live from `https://laintas.com/v1/models`, and usage is billed to your Laintas account balance.
- **First run prompts you to sign in** — run `laintas-opencode` and approve the device code in your browser.

It is a separate product from Laintas CLI (which is independently developed); this one is honestly a fork, and upstream attribution is preserved. See [FORK.md](FORK.md) for the base version, what was removed/added, and the maintenance model.

## Install

Download the binary for your platform from the [latest release](https://github.com/lin7c/laintas-opencode/releases/latest):

| Platform | Asset |
|---|---|
| Linux x64 | `laintas-opencode-linux-x64` |
| Linux arm64 | `laintas-opencode-linux-arm64` |
| macOS (Apple Silicon) | `laintas-opencode-darwin-arm64` |
| macOS (Intel) | `laintas-opencode-darwin-x64` |
| Windows x64 | `laintas-opencode-windows-x64.exe` |

Additional baseline (older CPUs without AVX2) and musl (Alpine) builds are attached to each release as well, plus a `checksums.txt` with SHA-256 sums for every asset.

```bash
# Linux / macOS example
chmod +x laintas-opencode-linux-x64
mv laintas-opencode-linux-x64 ~/.local/bin/laintas-opencode
laintas-opencode            # first run opens the Laintas sign-in flow
```

On Windows, rename the download to `laintas-opencode.exe`, put it somewhere on your `PATH`, and run `laintas-opencode` in a terminal.

Verify your download against `checksums.txt`:

```bash
sha256sum -c checksums.txt --ignore-missing
```

## Usage

```bash
laintas-opencode auth login   # sign in with Laintas (device code)
laintas-opencode              # start the TUI; /models picks what to run
laintas-opencode run -m laintas/gpt-6-luna "say pong"
```

Configuration, data and cache live under `laintas-opencode` directories (e.g. `~/.config/laintas-opencode`), separate from a stock OpenCode install. Self-update is disabled: new builds are published by Laintas as releases of this repository.

## License

MIT, inherited from upstream OpenCode — see [LICENSE](LICENSE). Upstream copyright notices are retained.
