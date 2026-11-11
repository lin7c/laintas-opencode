import { resolveChannel } from "./utils"

const arg = process.argv[2]
const channel = arg === "dev" || arg === "beta" || arg === "prod" ? arg : resolveChannel()

const appId = channel === "prod" ? "com.laintas.opencode" : `com.laintas.opencode.${channel}`
const productName = channel === "prod" ? "laintas-opencode" : `laintas-opencode ${channel.charAt(0).toUpperCase() + channel.slice(1)}`
const summary = `AI coding agent on your Laintas account${channel !== "prod" ? ` (${channel})` : ""}`

const xml = `<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>${appId}</id>

  <metadata_license>CC0-1.0</metadata_license>
  <project_license>MIT</project_license>

  <name>${productName}</name>
  <summary>${summary}</summary>

  <developer id="com.laintas">
    <name>Laintas</name>
  </developer>

  <description>
    <p>
      laintas-opencode is an AI coding agent for your terminal and desktop.
      It signs in with your Laintas account; models and billing run through
      Laintas. Based on the open source OpenCode project (MIT).
    </p>
  </description>

  <launchable type="desktop-id">${appId}.desktop</launchable>

  <content_rating type="oars-1.1" />

  <url type="bugtracker">https://github.com/lin7c/laintas-opencode/issues</url>
  <url type="homepage">https://opencode.laintas.com</url>
  <url type="vcs-browser">https://github.com/lin7c/laintas-opencode</url>
</component>
`

await Bun.write(`resources/${appId}.metainfo.xml`, xml)
console.log(`Generated metainfo for ${channel} at resources/${appId}.metainfo.xml`)
