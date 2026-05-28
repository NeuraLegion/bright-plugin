---
name: run-repeater
description: "Start a Bright Repeater using a configuration file."
argument-hint: "A command line arguments for starting a Bright Repeater."
---

# Run Bright Repeater

Use to start a Bright Repeater using a temporary configuration file.

## Rules

- Never pass the token directly in shell command arguments or process parameters. Keep the token out of process titles, logs, progress updates, final reports, and repository files.
- Extract `id`, `hostname`, and `token` into the secure temporary configuration file:
  ```bash
  set -e

  config_dir="${TMPDIR:-/tmp}/.brightsec"
  mkdir -p "$config_dir"
  chmod 700 "$config_dir"

  config_file="$config_dir/cli.json"
  umask 077
  cat > "$config_file" <<EOF
  {
    "id": "<extracted-repeater-id>",
    "hostname": "<extracted-repeater-hostname>",
    "token": "<extracted-repeater-token>",
    "logLevel": "notice"
  }
  EOF
  chmod 600 "$config_file"
  ```

- Run the repeater in background (async) mode so it persists during a session:
  ```bash
  bright-cli repeater --config "$config_file"
  ```
- If `bright-cli` is not installed, use the equivalent package runner:
  ```bash
  npx -y @brightsec/cli repeater --config "$config_file"
  ```
- Treat the repeater as ready only after its process starts and reports a successful connection to the Cloud. 
- If an existing process uses the same repeater ID, stop only the exact numeric PID for that process.
- Retry connection failures up to 3 times after checking arguments, and outbound access to Bright Cloud. If the Repeater still does not connect, stop and report the blocker.
