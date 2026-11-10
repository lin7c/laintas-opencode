# Laintas for OpenCode

Use your **Laintas account** inside OpenCode. You sign in with Laintas in
your browser and approve the device — there is **no API key** to create,
copy or paste. Every call is billed to your Laintas account balance, at the
same prices as Laintas's own clients.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/lin7c/opencode-laintas/main/install.sh | bash
opencode auth login   # pick "Laintas" → "Sign in with Laintas"
opencode              # /models → choose a Laintas model
```

Or by hand: add `"opencode-laintas"` to the `plugin` array of your
`opencode.json`, plus a provider entry:

```json
{
  "plugin": ["opencode-laintas"],
  "provider": {
    "laintas": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Laintas",
      "options": { "baseURL": "https://laintas.com/v1" },
      "models": {}
    }
  }
}
```

The model list is fetched from your Laintas account at runtime, so it
always matches what your account can use.

## How it works

- Sign-in is the Laintas device flow: OpenCode shows a verification link
  and a code; you approve on the Laintas accounts page (the page names
  OpenCode as the requesting app and shows the same code).
- OpenCode stores the resulting session token in its own auth storage,
  like any subscription provider. To remove it from this machine, run
  `opencode auth logout` and pick Laintas.
- Inference calls go to `https://laintas.com/v1`, an OpenAI-compatible
  facade in front of the Laintas gateway, which handles balance checks
  and settlement exactly as it does for Laintas CLI.

## Notes

- OpenCode's built-in cost display reads 0 for Laintas models — your
  Laintas usage page is the bill.
- If a call answers 401, the session was revoked or expired: run
  `opencode auth login` again.
