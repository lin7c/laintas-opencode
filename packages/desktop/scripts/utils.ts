import { $ } from "bun"
import { chmod, copyFile } from "node:fs/promises"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

export type Channel = "dev" | "beta" | "prod"

export function resolveChannel(): Channel {
  const raw = Bun.env.OPENCODE_CHANNEL
  if (raw === "dev" || raw === "beta" || raw === "prod") return raw
  return "dev"
}

const desktopDir = join(dirname(fileURLToPath(import.meta.url)), "..")

// The desktop sidecar is always this fork's own CLI build, never an upstream
// npm package. packages/opencode/script/build.ts writes one binary per
// target to packages/opencode/dist/<dist>/bin/laintas-opencode[.exe]. The
// target selection mirrors the one upstream used for its CLI packages
// (baseline builds on x64 so CPUs without AVX2 keep working).
export const CLI_BINARIES: Array<{ rustTarget: string; dist: string; os: string }> = [
  {
    rustTarget: "aarch64-apple-darwin",
    dist: "opencode-darwin-arm64",
    os: "darwin",
  },
  {
    rustTarget: "x86_64-apple-darwin",
    dist: "opencode-darwin-x64-baseline",
    os: "darwin",
  },
  {
    rustTarget: "aarch64-pc-windows-msvc",
    dist: "opencode-windows-arm64",
    os: "win32",
  },
  {
    rustTarget: "x86_64-pc-windows-msvc",
    dist: "opencode-windows-x64-baseline",
    os: "win32",
  },
  {
    rustTarget: "x86_64-unknown-linux-gnu",
    dist: "opencode-linux-x64-baseline",
    os: "linux",
  },
  {
    rustTarget: "aarch64-unknown-linux-gnu",
    dist: "opencode-linux-arm64",
    os: "linux",
  },
]

export const RUST_TARGET = Bun.env.RUST_TARGET

function nativeTarget() {
  const { platform, arch } = process
  if (platform === "darwin") return arch === "arm64" ? "aarch64-apple-darwin" : "x86_64-apple-darwin"
  if (platform === "win32") return arch === "arm64" ? "aarch64-pc-windows-msvc" : "x86_64-pc-windows-msvc"
  if (platform === "linux") return arch === "arm64" ? "aarch64-unknown-linux-gnu" : "x86_64-unknown-linux-gnu"
  throw new Error(`Unsupported platform: ${platform}/${arch}`)
}

export function getCurrentCli(target = RUST_TARGET ?? nativeTarget()) {
  const binaryConfig = CLI_BINARIES.find((item) => item.rustTarget === target)
  if (!binaryConfig) throw new Error(`CLI configuration not available for target '${target}'`)

  return binaryConfig
}

export async function copyCliToResources() {
  const cli = getCurrentCli()
  const binary = cli.os === "win32" ? "laintas-opencode.exe" : "laintas-opencode"
  const source = join(desktopDir, "..", "opencode", "dist", cli.dist, "bin", binary)
  if (!(await Bun.file(source).exists())) {
    throw new Error(
      `Fork CLI build not found at ${source}. Build it first from the repository root: ` +
        `bun ./packages/opencode/script/build.ts --single --baseline`,
    )
  }
  const dest = windowsify(join(desktopDir, "resources", "opencode-cli"))
  await copyFile(source, dest)
  if (process.platform !== "win32") await chmod(dest, 0o755)
  if (process.platform === "win32" && process.env.GITHUB_ACTIONS === "true") {
    await $`pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File ../../script/sign-windows.ps1 ${dest}`
  }
  if (process.platform === "darwin") await $`codesign --force --sign - ${dest}`

  console.log(`Copied ${cli.dist} CLI build to ${dest}`)
}

export function windowsify(path: string) {
  if (path.endsWith(".exe")) return path
  return `${path}${process.platform === "win32" ? ".exe" : ""}`
}
