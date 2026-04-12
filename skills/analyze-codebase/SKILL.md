---
name: analyze-codebase
description: >
  Detect the technology stack and discover all HTTP endpoints in the repository.
  Returns a structured list of endpoints with method, path, parameters, and body schema.
---

## Analyze Codebase

### Step 1: Detect Technology Stack

Read top-level configuration and dependency files to identify:
- **Languages**: from file extensions and config (package.json → Node.js/TypeScript, requirements.txt → Python, go.mod → Go, pom.xml → Java, Gemfile → Ruby, Cargo.toml → Rust)
- **Frameworks**: from dependencies (express, fastify, nestjs, django, flask, rails, spring-boot, gin, echo, fiber, actix-web, etc.)
- **Databases**: from dependencies or ORM config (mongoose → MongoDB, typeorm/prisma/sequelize → SQL, redis, etc.)

Files to check: `package.json`, `go.mod`, `requirements.txt`, `Gemfile`, `pom.xml`, `build.gradle`, `Cargo.toml`, `Dockerfile`, `docker-compose.yml`, `composer.json`.

### Step 2: Find Controller/Route Files

Based on the detected framework, search for files that define HTTP endpoints:

| Framework | File Patterns |
|-----------|--------------|
| Express/Fastify | `src/**/*.routes.{ts,js}`, `src/**/*.controller.{ts,js}`, `routes/**/*.{ts,js}` |
| NestJS | `src/**/*.controller.ts` (look for `@Controller`, `@Get`, `@Post` decorators) |
| Django | `**/urls.py` |
| Flask | `**/*.py` (look for `@app.route` or `Blueprint`) |
| Rails | `config/routes.rb`, `app/controllers/**/*.rb` |
| Spring Boot | `**/*Controller.java`, `**/*Resource.java` (look for `@RestController`, `@RequestMapping`) |
| Go / Gin / Echo | `**/*handler*.go`, `**/*router*.go`, `**/routes.go` |
| FastAPI | `**/*.py` (look for `@app.get`, `@router.post`, etc.) |

Use `bash` with `find` to locate candidate files, then `view` to confirm they contain route definitions.

### Step 3: Extract Endpoints

For each controller/route file, extract every HTTP endpoint:

- **method**: GET, POST, PUT, PATCH, DELETE
- **path**: The URL path (e.g., `/api/users/:id`). Resolve route prefixes from parent routers/controllers.
- **bodySchema**: For POST/PUT/PATCH endpoints, inspect DTOs, decorators (`@IsString`, `@ApiBody`), TypeScript interfaces, Mongoose schemas, or `req.body` property access to determine the expected request body with realistic sample values.
- **queryParams**: List of query parameter names and sample values.
- **contentType**: Usually `application/json` for API endpoints, or `multipart/form-data` for file uploads.

### Step 4: Filter Destructive Endpoints

Remove endpoints that would break the application if fuzzed by the scanner:

1. **ALL `DELETE` method endpoints** — too destructive.
2. **`PUT`/`PATCH` on user mutation paths** — changing user credentials breaks auth:
   - `/users/me`, `/users/profile`, `/users/account`
   - `/profile`, `/account`, `/settings/password`
   - `/change-password`, `/reset-password`, `/update-password`
   - `/update-email`, `/update-profile`
   - `/users/{id}` (numeric ID patterns)
3. **Endpoints with credential fields in the body**: `password`, `newPassword`, `currentPassword`, `oldPassword`, `passwd`.

### Output

Present the results as a structured list:
- Tech stack summary (languages, frameworks, databases)
- Endpoint count (total discovered vs. filtered)
- Full endpoint list with method, path, body schema, query params, content type
