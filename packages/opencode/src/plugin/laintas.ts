import type { Hooks } from "@opencode-ai/plugin"
import { readFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

// Laintas for laintas-opencode (built-in plugin).
//
// Sign-in is a Laintas device-code login: the CLI opens the Laintas
// accounts page, the user approves this device there, and the CLI receives
// a Laintas session token. Inference goes to the Laintas OpenAI-compatible
// endpoint with that token; billing is settled against the user's Laintas
// account balance by the Laintas gateway. No API key is ever shown, copied
// or stored by hand - the token is the login, managed by the app's own
// auth storage like any other subscription provider.

const PROVIDER_ID = "laintas"
const API_BASE = "https://laintas.com/v1"
const DEVICE_BASE = "https://accounts.laintas.com/api/auth/cli-device"
const CLIENT = "opencode"

type DeviceStart = {
  deviceId: string
  deviceSecret: string
  verificationUri: string
  userCode: string
  expiresIn: number
  interval: number
}

async function startDeviceLogin(): Promise<DeviceStart> {
  const resp = await fetch(`${DEVICE_BASE}/start`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ client: CLIENT }),
  })
  if (!resp.ok) throw new Error(`Laintas sign-in could not start (HTTP ${resp.status})`)
  return (await resp.json()) as DeviceStart
}

async function pollDeviceLogin(start: DeviceStart): Promise<string | null> {
  const resp = await fetch(`${DEVICE_BASE}/poll`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ deviceId: start.deviceId, deviceSecret: start.deviceSecret }),
  })
  if (!resp.ok) return null // expired or already claimed
  const data = (await resp.json()) as { status?: string; token?: string }
  if (data.status === "approved" && data.token) return data.token
  return null
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms))

async function fetchModelIds(access: string): Promise<string[]> {
  const resp = await fetch(`${API_BASE}/models`, {
    headers: { Authorization: `Bearer ${access}` },
  })
  if (!resp.ok) return []
  const body = (await resp.json()) as { data?: Array<{ id: string }> }
  return (body.data || []).map((m) => m?.id).filter(Boolean) as string[]
}

function storedAccessToken(): string | null {
  try {
    const dataHome = process.env.XDG_DATA_HOME || join(homedir(), ".local", "share")
    const raw = readFileSync(join(dataHome, "laintas-opencode", "auth.json"), "utf8")
    const entry = JSON.parse(raw)?.[PROVIDER_ID]
    return entry?.type === "oauth" && entry.access ? entry.access : null
  } catch {
    return null
  }
}

export async function LaintasAuthPlugin(): Promise<Hooks> {
  return {
    // Populate the provider's model list at startup from the signed-in
    // account, so /models always shows what this account can actually use.
    // (The provider hook below does the same where the host calls it; the
    // config hook is the path the app takes for config-declared providers.)
    // Not signed in or offline: leave the config untouched.
    config: async (cfg) => {
      try {
        const access = storedAccessToken()
        if (!access) return
        const ids = await fetchModelIds(access)
        if (!ids.length) return
        const models: Record<string, { name: string }> = {}
        for (const id of ids) models[id] = { name: id }
        const providers = ((cfg as any).provider ||= {})
        const existing = providers[PROVIDER_ID] || {}
        providers[PROVIDER_ID] = {
          ...existing,
          npm: "@ai-sdk/openai-compatible",
          name: "Laintas",
          options: { baseURL: API_BASE, ...(existing.options || {}) },
          models,
        }
      } catch {
        // keep the static config
      }
    },
    auth: {
      provider: PROVIDER_ID,
      loader: async (getAuth) => {
        const auth = await getAuth()
        if (!auth || auth.type !== "oauth") return {}
        return {
          baseURL: API_BASE,
          apiKey: auth.access,
          // Read the token per request so a re-login takes effect without
          // restarting the app, and never let the AI SDK fall back to an
          // "api-key" header scheme the Laintas gateway does not use.
          fetch: async (input: any, init?: any) => {
            const fresh = await getAuth()
            const headers = new Headers(init?.headers)
            if (fresh && fresh.type === "oauth") {
              headers.set("Authorization", `Bearer ${fresh.access}`)
            }
            headers.delete("api-key")
            return fetch(input, { ...init, headers })
          },
        }
      },
      methods: [
        {
          type: "oauth",
          label: "Sign in with Laintas",
          authorize: async () => {
            const start = await startDeviceLogin()
            return {
              url: start.verificationUri,
              instructions:
                `Approve this device in your browser. ` +
                `Only approve if the page shows this same code: ${start.userCode}`,
              method: "auto",
              callback: async () => {
                const deadline = Date.now() + start.expiresIn * 1000
                const interval = Math.max(2, start.interval || 2) * 1000
                while (Date.now() < deadline) {
                  await sleep(interval)
                  const token = await pollDeviceLogin(start)
                  if (token) {
                    return {
                      type: "success" as const,
                      access: token,
                      refresh: token,
                      // The session is long-lived and revocable from the
                      // Laintas account side; a far-future expiry keeps the
                      // app from inventing a refresh flow for it.
                      expires: Date.now() + 365 * 24 * 3600 * 1000,
                    }
                  }
                }
                return { type: "failed" as const }
              },
            }
          },
        },
      ],
    },
    provider: {
      id: PROVIDER_ID,
      models: async (_provider, ctx) => {
        const auth = ctx.auth
        if (!auth || auth.type !== "oauth") return {}
        try {
          const resp = await fetch(`${API_BASE}/models`, {
            headers: { Authorization: `Bearer ${auth.access}` },
          })
          if (!resp.ok) return {}
          const body = (await resp.json()) as { data?: Array<{ id: string }> }
          const models: Record<string, any> = {}
          for (const entry of body.data || []) {
            if (!entry?.id) continue
            models[entry.id] = {
              id: entry.id,
              providerID: PROVIDER_ID,
              api: { id: entry.id, url: API_BASE, npm: "@ai-sdk/openai-compatible" },
              name: entry.id,
              capabilities: {
                temperature: true,
                reasoning: true,
                attachment: false,
                toolcall: true,
                input: { text: true, audio: false, image: true, video: false, pdf: false },
                output: { text: true, audio: false, image: false, video: false, pdf: false },
                interleaved: false,
              },
              // Real prices are settled in the Laintas account; the app's
              // own cost readout is not the bill.
              cost: { input: 0, output: 0, cache: { read: 0, write: 0 } },
              limit: { context: 128000, output: 8192 },
              status: "active",
              options: {},
              headers: {},
              release_date: "",
            }
          }
          return models
        } catch {
          return {}
        }
      },
    },
  } as Hooks
}
