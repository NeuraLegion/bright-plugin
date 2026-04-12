#!/usr/bin/env bash
# validate-no-production-targets.sh
#
# Safety hook: prevents the agent from running scan-related commands against
# external or production URLs. Only localhost / 127.0.0.1 targets are allowed.
#
# This runs as a "before:tool:bash" hook. It receives the bash command as $1.
# Exit 0 to allow, exit 1 to block.

COMMAND="$1"

# Only inspect commands that look like they're starting scans or curling external URLs
if echo "$COMMAND" | grep -qiE '(bright-cli|brightsec|runScan|runDiscovery|curl|wget|http)'; then
  # Allow localhost / 127.0.0.1 / 0.0.0.0 targets
  if echo "$COMMAND" | grep -qiE '(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])'; then
    exit 0
  fi

  # Allow commands that don't contain URLs at all (e.g., bright-cli repeater --id ...)
  if ! echo "$COMMAND" | grep -qiE 'https?://'; then
    exit 0
  fi

  # Allow Bright API URLs (needed for repeater, MCP, etc.)
  if echo "$COMMAND" | grep -qiE 'https?://[^/]*brightsec\.com'; then
    exit 0
  fi

  # Block everything else with an external URL
  echo "BLOCKED: Commands targeting external URLs are not allowed. Only localhost targets via repeater." >&2
  exit 1
fi

exit 0
