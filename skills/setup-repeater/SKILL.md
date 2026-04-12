---
name: setup-repeater
description: >
  Set up the Bright project and create a local repeater for scanning.
  The repeater acts as a tunnel between Bright's cloud scanner and the local application.
---

## Setup Bright Project & Repeater

### Step 1: Select Bright Project

1. Call `listProjects` to get available Bright projects.
2. If a project name matches the repository name, use that one.
3. Otherwise, use the first available project.
4. Record the `projectId`.

### Step 2: Create Repeater

1. Call `createRepeater` with:
   - `projectId`
   - `name`: `github-plugin-<repo-name>` (use a descriptive name)
2. Record the `repeaterId`.

### Step 3: Start Repeater Locally

Run the Bright CLI repeater as a background process:

```bash
npx @brightsec/cli repeater --id <REPEATER_ID> --token "$BRIGHT_TOKEN" &
```

If `@brightsec/cli` is not available:
```bash
npm install -g @brightsec/cli
npx @brightsec/cli repeater --id <REPEATER_ID> --token "$BRIGHT_TOKEN" &
```

Alternative with Docker (if npm is not available):
```bash
docker run --rm --network host -d brightsec/cli repeater --id <REPEATER_ID> --token "$BRIGHT_TOKEN"
```

Use `--network host` so the repeater can reach `localhost` targets.

### Step 4: Verify Connection

1. Wait 10 seconds for the repeater to connect.
2. Call `listRepeaters` and check that the repeater's status is `connected`.
3. If not connected, wait another 10 seconds and retry (up to 3 attempts).
4. If the repeater fails to connect, check the process logs for errors and report the issue.

### Output

- `projectId`: The Bright project ID to use for all subsequent operations.
- `repeaterId`: The repeater ID to include in all scan/entrypoint/auth configurations.
