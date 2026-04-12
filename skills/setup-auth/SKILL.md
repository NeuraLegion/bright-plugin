---
name: setup-auth
description: >
  Detect whether the application requires authentication, and if so, create and
  test a Bright auth object. Supports JWT, API key, session, and custom auth flows.
---

## Setup Authentication

### Step 1: Detect Authentication Requirements

Analyze the source code for authentication patterns:

1. **Middleware/Guards**: Look for auth middleware in route definitions:
   - Express: `passport.authenticate()`, `express-jwt`, custom `authMiddleware`
   - NestJS: `@UseGuards(AuthGuard)`, `@ApiBearerAuth()`
   - Django: `@login_required`, `IsAuthenticated` permission class
   - Spring: `@PreAuthorize`, `SecurityFilterChain`
   - Go: auth middleware in router setup

2. **Login Endpoints**: Find endpoints that accept credentials and return tokens:
   - POST `/auth/login`, `/api/login`, `/auth/token`, `/oauth/token`
   - Look at the request body: email/username + password fields
   - Look at the response: JWT token, session cookie, API key

3. **Token Usage**: How is the token sent on subsequent requests?
   - `Authorization: Bearer <token>` header (JWT)
   - `X-API-Key: <key>` header (API key)
   - Cookie-based session
   - Custom header

4. **Token Extraction**: Where in the login response is the token?
   - Body field: `$.token`, `$.access_token`, `$.data.token`
   - Set-Cookie header

Determine:
- `requiresAuth`: true/false
- `authType`: jwt, api_key, session, basic, oauth, none
- `loginEndpoint`: path and method
- `loginBody`: JSON with realistic test credentials (look for seed data, test fixtures, .env.example)
- `headerName`: e.g., `Authorization`
- `headerTemplate`: e.g., `Bearer {{token}}`
- `tokenJsonPath`: e.g., `$.token`

### Step 2: Check Existing Auth Objects

If auth is required:
1. Call `listAuths` for the project.
2. If a suitable auth object already exists (matching type and login endpoint), reuse it.
3. Record the `authObjectId`.

### Step 3: Create Auth Object

If no suitable auth object exists:

1. Call `addAuth` with the detected configuration:
   - Auth type and credentials
   - `repeaterId` — so auth testing goes through the repeater to reach localhost
   - Re-authentication triggers: `[401, 403]`
2. Record the `authObjectId`.

### Step 4: Test Auth Object

1. The auth object should be tested automatically upon creation.
2. If the test fails:
   a. Read application source code to understand what went wrong.
   b. Common issues:
      - Wrong login body format (check DTOs/schemas)
      - Wrong token extraction path (check actual response structure)
      - Wrong header format
      - App not running or not reachable via repeater
      - CORS or other middleware blocking
   c. Call `editAuth` with corrected parameters.
   d. Retry up to 10 times.
3. If auth still cannot be configured after retries, report the failure with details.

### Output

- `authObjectId`: The ID of the working auth object (or null if no auth needed).
- Auth type and configuration summary.
