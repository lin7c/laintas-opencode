import type { Argv } from "yargs"
import { UI } from "../ui"
import * as prompts from "@clack/prompts"

export const UpgradeCommand = {
  command: "upgrade [target]",
  describe: "laintas-opencode updates are managed by Laintas",
  builder: (yargs: Argv) => {
    return yargs.positional("target", {
      describe: "ignored; kept for command compatibility",
      type: "string",
    })
  },
  handler: async () => {
    UI.empty()
    UI.println(UI.logo("  "))
    UI.empty()
    prompts.intro("Upgrade")
    // laintas-opencode never upgrades itself into upstream OpenCode.
    // New builds are published by Laintas through its own channels.
    prompts.log.info(
      "laintas-opencode updates are managed by Laintas. Download new builds from Laintas instead of upgrading in place.",
    )
    prompts.outro("Done")
  },
}
