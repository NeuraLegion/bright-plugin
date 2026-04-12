# Bright Security Plugin for GitHub AgentHQ

A [GitHub AgentHQ Plugin](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-cli-plugins) that integrates **Bright DAST** (Dynamic Application Security Testing) into the Copilot harness. It automatically discovers endpoints, scans for vulnerabilities, generates fixes, and validates them — all without storing any long-lived secrets.

## How It Works

```
Analyze Code → Discover Endpoints → Configure Auth → Start Repeater → [Scan → Fix → Validate] × 5
```

The plugin runs up to 5 rounds of scan-fix-validate, aiming to reach zero open vulnerabilities. Each round:

1. **Scans** the application using Bright's DAST engine via a local Repeater
2. **Fixes** each discovered vulnerability with targeted code changes
3. **Validates** the fixes by re-scanning to confirm they resolved the issue

## Installation

```bash
copilot plugin install NeuraLegion/bright-plugin
```

## Usage

From inside the repository you want to scan:

```bash
# Interactive mode
copilot --agent bright-security:bright-security \
  -i "Scan this application for security vulnerabilities"

# Autopilot mode
copilot --agent bright-security:bright-security \
  --autopilot \
  -p "Scan this application for security vulnerabilities"
```

### Local development (without installing)

```bash
copilot --plugin-dir /path/to/bright-plugin \
  --agent bright-security:bright-security \
  -i "Scan this application for security vulnerabilities"
```

## Plugin Contents

| Component | Description |
|-----------|-------------|
| **bright-security** agent | Main orchestrator — drives the full scan-fix-validate workflow |
| **fix-findings** agent | Sub-agent specialized in taint analysis and secure code fix generation |
| **analyze-codebase** skill | Detects tech stack and discovers HTTP endpoints |
| **setup-repeater** skill | Creates and starts a Bright Repeater for local scanning |
| **setup-auth** skill | Detects and configures authentication (JWT, API key, session, etc.) |
| **register-entrypoints** skill | Registers endpoints with Bright and prunes dead routes |
| **run-scan** skill | Selects tests, launches scans, polls for completion, retrieves findings |
| **fix-and-validate** skill | Iterative fix-commit-restart-rescan loop |

## Authentication

The plugin authenticates with Bright's MCP server via **OIDC workload identity federation** — no API keys or secrets are stored in the repository. GitHub's Copilot harness handles the token exchange automatically.

For local testing, you can pass an API key at runtime:

```bash
copilot --agent bright-security:bright-security \
  --additional-mcp-config '{"mcpServers":{"brightsec.com":{"type":"http","url":"https://app.brightsec.com/mcp","headers":{"Authorization":"Api-Key YOUR_KEY"}}}}' \
  -i "Scan this application"
```

## Safety

- Only scans `localhost` targets via Repeater — never external/production URLs
- Filters out destructive endpoints (DELETE methods, credential mutation paths)
- All tokens are short-lived and automatically revoked on job completion
- A `before:tool:bash` hook blocks commands targeting non-localhost URLs

## Requirements

- [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli)
- A [Bright](https://brightsec.com) account
- Node.js (for `@brightsec/cli` Repeater)

## License

MIT
