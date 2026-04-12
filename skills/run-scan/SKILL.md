---
name: run-scan
description: >
  Select security tests, launch Bright DAST scans against registered entrypoints,
  monitor progress, and retrieve findings.
---

## Run Security Scans

### Step 1: Select Tests

1. Call `listTests` to get the full Bright test catalog with tags.
2. Map endpoint characteristics to relevant tests:

| Endpoint Characteristic | Bright Test Tags |
|------------------------|-----------------|
| Accepts user input in body/query | `xss`, `stored_xss`, `sqli`, `nosql` |
| Has URL/path parameters | `lfi`, `ssrf`, `open_redirect` |
| File upload endpoints | `file_upload` |
| Template rendering | `ssti` |
| Command/process execution | `osi` |
| Authentication endpoints | `jwt`, `brute_force_login` |
| All endpoints | `header_security`, `cookie_security`, `secret_tokens`, `csrf` |
| Admin/management endpoints | `bac`, `id_enumeration`, `bopla` |

3. Do NOT include multi-auth tests or `lrrl` (Lack of Resources and Rate Limiting) — these
   are destructive or require special setup.

### Step 2: Group and Launch Scans

1. Group endpoints by their test set to minimize the number of scans (up to 5 groups).
2. For each group, call `runScan` with:
   - `projectId`
   - `entrypointIds`: array of entrypoint IDs for this group
   - `tests`: array of Bright test tags for this group
   - `repeaters`: `["<REPEATER_ID>"]` — ALWAYS an array, never a string
   - `authObjectId`: if authentication is configured
   - `attackLocationTypes`: `["body", "query", "fragment"]` — add `"path"` if endpoints have path parameters
3. Record each `scanId`.

### Step 3: Monitor Scans

1. Wait 60 seconds before the first status check.
2. Call `getScanStatus` for each scan.
3. Repeat every 60 seconds until all scans reach `done`, `stopped`, or `failed`.
4. If a scan fails, check application health. If the app is down, restart it and note the failure.

### Step 4: Retrieve Findings

1. Call `listIssues` for the project to get all discovered vulnerabilities.
2. For each finding, record:
   - `name`: Vulnerability type (e.g., "SQL Injection", "Reflected XSS")
   - `severity`: Critical, High, Medium, Low
   - `method`: HTTP method of the affected endpoint
   - `url`: URL of the affected endpoint
   - `details`: Description and evidence from the scanner
   - `remedy`: Suggested remediation from the scanner

### Output

- Number of scans launched and their completion status.
- Full list of findings with name, severity, method, URL, details, and remedy.
- Severity breakdown: Critical / High / Medium / Low counts.
