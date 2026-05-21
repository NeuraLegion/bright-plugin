# Bright Security Plugin for GitHub AgentHQ

A [GitHub AgentHQ Plugin](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-cli-plugins) that runs **Bright DAST** from a single autonomous agent. The current agent can analyze the target repository, build and start the application, complete setup flows, prepare authentication, register entrypoints, run scans through a Repeater, and in full mode remediate and validate findings for up to 5 rounds.

The plugin ships Bright MCP configuration in `.mcp.json` and keeps credentials out of the repository. Bright integration is MCP-only and uses OIDC for authentication.

## How It Works

```
MCP Check -> Analyze Target -> Start App or Harness -> Setup + Scan Prep -> Auth -> Repeater + Entrypoints -> Scan -> [Fix -> Validate] x 5
```

The agent supports three runtime modes:

- `full` (default): full startup, scan, remediation, and validation
- `dynamic`: full startup and scanning only, without harness fallback
- `function`: lightweight harness-based function scanning

If the prompt explicitly asks for scan-only behavior, the agent stops after reporting current-run findings and the gate verdict.

## Installation

```bash
copilot plugin install NeuraLegion/bright-plugin
```

## Runtime Requirements

- [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli)
- A [Bright](https://brightsec.com) environment that exposes the target project, repeaters, auth objects, entrypoints, and scans through MCP
- Bright MCP access through the configured `bright` server in `.mcp.json`
- OIDC support for the Bright MCP server

## Usage

From inside the repository you want to scan:

```bash
# Interactive full remediation mode
copilot --agent bright-security:bright-security \
  -i "Run a full Bright scan against this application, fix the findings, and validate the fixes"

# Autopilot scan-only mode
copilot --agent bright-security:bright-security \
  --autopilot \
  -p "Scan this application with Bright, report current-run findings only, and stop after the gate verdict"
```

### Local development (without installing)

```bash
copilot --plugin-dir /path/to/bright-plugin \
  --agent bright-security:bright-security \
  -i "Run a full Bright scan against this application"
```

You can steer the mode with the prompt, for example:

- `Use dynamic mode and fail if the app cannot start end to end.`
- `Use function mode and scan the selected backend functions through a harness.`
- `Scan only. Do not attempt remediation.`

## Plugin Contents

| Component | Description |
|-----------|-------------|
| `bright-security` agent | Consolidated workflow from `agents/bright-security.agent.md` for target analysis, startup, setup, auth, DAST scanning, remediation, and validation |
| `.mcp.json` | Bright MCP server definition using OIDC against the development playground |
| `hooks.json` + `validate-no-production-targets.sh` | Safety hook that blocks scan commands against non-local targets while allowing Bright control-plane URLs |

The checked-in plugin is now consolidated into the single agent above; older helper skills and sub-agents are not part of the current repository state. The prompt's frontmatter name is `bright-testing-and-remediation-agent`, but the Copilot CLI agent ID is `bright-security` because plugin agent IDs are derived from the agent filename.

## Authentication

MCP access is configured under the `bright` server in `.mcp.json` and uses OIDC workload identity federation:

- MCP URL: `https://development.playground.brightsec.com/mcp`
- OIDC audience: `https://brightsec.com/`
- Token endpoint: `https://development.playground.brightsec.com/api/v1/token`
- Revoke endpoint: `https://development.playground.brightsec.com/api/v1/revoke`

The agent uses MCP only for Bright-side operations. If a required Bright capability is missing from MCP, the run should stop and report that limitation instead of falling back to REST.

If you need to override MCP auth locally with an API key, target the same `bright` server entry:

```bash
copilot --agent bright-security:bright-security \
  --additional-mcp-config '{"mcpServers":{"bright":{"type":"http","url":"https://development.playground.brightsec.com/mcp","headers":{"Authorization":"Api-Key YOUR_KEY"}}}}' \
  -i "Scan only and report current-run findings"
```

## Safety

- Scans are restricted to local targets via a Repeater; the hook blocks non-local target URLs
- Bright Cloud URLs are allowed for control-plane operations such as project, repeater, auth, and scan management
- Destructive or state-corrupting endpoints are excluded before registration
- Findings are reported from the current run's scan IDs only
- The agent is expected to clean up scans, repeaters, and temporary processes at the end of the run

## License

MIT
