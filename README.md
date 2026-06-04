# Bright Security Plugin for GitHub AgentHQ

A [GitHub AgentHQ Plugin](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-cli-plugins) that runs **Bright DAST** from a single autonomous agent. The agent analyzes the target repository, builds and starts the application, prepares authentication, registers entrypoints, runs scans through a Repeater, and remediates and validates findings for up to 5 rounds. It supports both whole-application and pull-request-scoped runs, and the entire run completes within ~60 minutes.

The plugin ships Bright MCP/OIDC configuration in the frontmatter of `agents/main.agent.md`. Bright integration is MCP-only and uses OIDC to keep credentials out of the repository.

## How It Works

```text
Resolve Scope -> MCP Check -> Analyze Target -> Start App or Harness -> Setup + Scan Prep -> Auth -> Repeater + Entrypoints -> Scan -> [Fix -> Validate] x 5
```

### Run scope

A run targets either the whole application or the changes in a single pull request:

- **Whole-application** (default): scans the entire registered surface
- **PR-scoped**: agent traces changed code to affected endpoints and restricts registration and scanning to those endpoints only; falls back to function mode if no endpoint can be traced

### Runtime modes

- `full` (default): full application startup, scan, remediation, and validation; falls back to `function` mode after 3 failed startup retries or 5 failed auth attempts
- `function`: lightweight harness-based scanning targeting specific functions; also used automatically for PR-scoped runs where changed code cannot be traced to an endpoint

If the prompt explicitly asks for scan-only behavior, the agent stops after reporting current-run findings and the gate verdict.

## Installation

```bash
copilot plugin install NeuraLegion/bright-plugin
```

## Runtime Requirements

- [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli)
- A [Bright](https://brightsec.com) environment that exposes the target project, repeaters, auth objects, entrypoints, and scans through MCP
- Bright MCP access through the embedded `bright` server in the `mcp-servers` frontmatter of `agents/main.agent.md`
- OIDC support for the Bright MCP server

## Usage

From inside the repository you want to scan:

```bash
# Interactive full remediation mode
copilot --agent bright-security:main \
  -i "Run a full Bright scan against this application, fix the findings, and validate the fixes"

# PR-scoped scan (only endpoints affected by the current branch)
copilot --agent bright-security:main \
  -i "Run a PR-scoped Bright scan for this pull request, fix confirmed findings, and validate the fixes"

# Autopilot scan-only mode
copilot --agent bright-security:main \
  --autopilot \
  -p "Scan this application with Bright, report current-run findings only, and stop after the gate verdict"
```

### Local development (without installing)

```bash
copilot --plugin-dir /path/to/bright-plugin \
  --agent bright-security:main \
  -i "Run a full Bright scan against this application"
```

You can steer the mode and scope with the prompt, for example:

- `Run in function mode and scan the selected backend functions through a harness.`
- `Run a PR-scoped scan for PR #42.`
- `Scan only. Do not attempt remediation.`

## Plugin Contents

| Component | Description |
|-----------|-------------|
| `agents/main.agent.md` | Single shipped agent. The full Copilot CLI agent identifier is `bright-security:main`; `main` is the agent name within the `bright-security` plugin, and the frontmatter `name` is `bright`. The frontmatter also embeds the `bright` MCP/OIDC server definition. |
| `plugin.json` | Plugin manifest that points Copilot CLI at `agents/` and `hooks.json`. |
| `hooks.json` + `validate-no-production-targets.sh` | Safety hook that blocks scan commands against non-local targets while allowing Bright control-plane URLs |

The agent frontmatter is the source of truth for the shipped Bright MCP configuration.

## Authentication

MCP access is configured under the `bright` server in the `mcp-servers` frontmatter block of `agents/main.agent.md` and uses OIDC workload identity federation. A secondary `cli` server entry is also provided in the same block:

- MCP URL: `https://app.brightsec.com/mcp`
- OIDC audience: `https://brightsec.com/agents/github`
- Token endpoint: `https://app.brightsec.com/api/v1/token`
- Revoke endpoint: `https://app.brightsec.com/api/v1/revoke`

The agent uses MCP only for Bright-side operations. If a required Bright capability is missing from MCP, the run should stop and report that limitation instead of falling back to REST.

If you need to override MCP auth locally with an API key, target the same `bright` server entry. Keys under `mcpServers` are merged by name, so the object you supply replaces the shipped definition for that server while leaving the others untouched:

```bash
copilot --agent bright-security:main \
  --additional-mcp-config '{"mcpServers":{"bright":{"type":"http","url":"https://app.brightsec.com/mcp","headers":{"Authorization":"Api-Key YOUR_KEY"}}}}' \
  -i "Scan only and report current-run findings"
```

## Safety

- Scans are restricted to local targets via a Repeater; the hook blocks non-local target URLs
- Bright Cloud URLs are allowed for control-plane operations such as project, repeater, auth, and scan management
- Destructive or state-corrupting endpoints are excluded before registration
- Findings are reported from the current run's scan IDs only
- All resources created by the agent are prefixed with `bright-agent-`; orphaned resources from previous failed runs are cleaned up at startup
- The agent cleans up scans, repeaters, and temporary processes at the end of the run

## License

Copyright © 2026 [Bright Security Inc.](https://brightsec.com/)

This project is licensed under the MIT License - see the [LICENSE file](LICENSE) for details.
