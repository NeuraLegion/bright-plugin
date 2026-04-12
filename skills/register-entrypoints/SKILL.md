---
name: register-entrypoints
description: >
  Register discovered HTTP endpoints with the Bright project as entrypoints
  for scanning. Includes auth and repeater configuration, and prunes dead endpoints.
---

## Register Entrypoints

### Step 1: Construct Requests

For each endpoint discovered in the analyze-codebase phase, construct a realistic HTTP
request:

- **URL**: `<baseUrl><path>` — replace path parameters with realistic sample values:
  - `:id` or `{id}` → `1` or a UUID
  - `:slug` → `test-item`
  - `:userId` → `1`
- **Method**: The HTTP method from discovery.
- **Headers**: Include `Content-Type` (usually `application/json`) and any required headers.
- **Body**: For POST/PUT/PATCH endpoints, use the body schema from discovery as a JSON string
  with realistic field values. DO NOT submit empty bodies `{}` — that would not reach the
  vulnerable code paths.

### Step 2: Register with Bright

For each endpoint, call `addEntrypoint` with:
- `projectId`
- `repeaterId` — so the scanner reaches the local app via the repeater
- `authObjectId` — if authentication is configured (from setup-auth phase)
- `request`: `{ method, url, headers, body }`

If there are more than 15 endpoints, consider using `runDiscovery` with a crawler against
the local base URL instead of registering them individually. This lets Bright's crawler
automatically discover endpoints and their parameters.

### Step 3: Verify Auth on Entrypoints

After registering the first few entrypoints:
1. Use a known authenticated endpoint and check if the response status is 200 (not 401/403).
2. If receiving 401/403, the auth object is not working correctly — go back to setup-auth
   to fix it before continuing.

### Step 4: Prune Dead Entrypoints

After registering all entrypoints:
1. Check which endpoints return 404 (nonexistent routes).
2. Remove those entrypoints to avoid wasting scan time.
3. Report the final count of active entrypoints.

### Output

- List of registered `entrypointIds` with their method + URL.
- Count of active vs. pruned entrypoints.
