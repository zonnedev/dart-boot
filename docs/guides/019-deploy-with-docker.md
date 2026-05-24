# Guide 019: Deploy with Docker

## What you'll build

A production-ready Docker image of your Boot app — small, fast, and secure.

## What you'll learn

- How to compile a Boot app to a native executable
- How to write a multi-stage Dockerfile
- How to use docker-compose with a database
- How to configure via environment variables
- How to add health checks

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)
- Docker installed

---

## Step 1: Compile to native executable

Boot apps can be compiled to a standalone binary — no Dart SDK needed at runtime:

```bash
boot build
dart compile exe bin/main.dart -o server
./server  # runs without Dart installed
```

The binary is ~10-20MB and starts in ~40ms.

---

## Step 2: Write the Dockerfile

**`Dockerfile`**

```dockerfile
# Stage 1: Build
FROM dart:3.12 AS build
WORKDIR /app

# Copy pubspec first (for dependency caching)
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

# Copy source and build
COPY . .
RUN dart run build_runner build --delete-conflicting-outputs
RUN dart compile exe bin/main.dart -o /app/server

# Stage 2: Run (minimal image)
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server
COPY --from=build /app/application.yml /app/application.yml

WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["/app/server"]
```

**What's happening:**

- **Stage 1** — uses the full Dart SDK to compile. Installs deps, runs code gen, compiles to native.
- **Stage 2** — starts from `scratch` (empty image). Copies only the binary + config. No Dart SDK, no source code.
- `/runtime/` — Dart's minimal runtime libraries needed by the compiled binary.
- Final image is ~15MB.

---

## Step 3: Create docker-compose.yml

**`docker-compose.yml`**

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: todo_app
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 2s
      timeout: 3s
      retries: 5

  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      BOOT_ENV: prod
      PG_HOST: postgres
      PG_PORT: 5432
      PG_DATABASE: todo_app
      PG_USERNAME: postgres
      PG_PASSWORD: ${DB_PASSWORD:-postgres}
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  pgdata:
```

**What's happening:**

- PostgreSQL starts first, with a health check
- The app waits for PostgreSQL to be healthy before starting
- Config is passed via environment variables (no secrets in files)
- `${DB_PASSWORD:-postgres}` reads from `.env` file or defaults to "postgres"

---

## Step 4: Create .env file (for local docker-compose)

**`.env`**

```
DB_PASSWORD=supersecret
```

Add to `.gitignore`:
```
.env
```

---

## Step 5: Build and run

```bash
docker compose up --build
```

Output:
```
postgres-1  | database system is ready to accept connections
app-1       | Boot started in 43ms — http://0.0.0.0:8080
```

Test:
```bash
curl http://localhost:8080/todos/
```

---

## Step 6: Production application.yml

The Docker image includes `application.yml` but environment variables override everything:

**`application.yml`** (in the image — safe defaults):

```yaml
boot:
  env: prod
  logging:
    level: info
    format: json
    stacktrace:
      filter:
        enabled: true
        max-depth: 5

server:
  port: 8080
```

**Runtime overrides via env vars:**

```yaml
# docker-compose.yml
environment:
  BOOT_ENV: prod
  PG_HOST: prod-db.internal
  PG_PASSWORD: ${DB_PASSWORD}
  SERVER_PORT: 8080
```

---

## Step 7: Add a health check endpoint

Boot can expose a `/health` endpoint for Docker/Kubernetes:

```dart
@Controller('/health')
class HealthController {
  final Database _db;
  HealthController(this._db);

  @Get('/')
  Future<Response> health(Request request) async {
    try {
      await _db.query('SELECT 1');
      return Response.json({'status': 'UP', 'db': 'connected'});
    } catch (e) {
      return Response(503,
        headers: {'content-type': 'application/json'},
        body: '{"status": "DOWN", "db": "disconnected"}',
      );
    }
  }
}
```

Add to docker-compose:

```yaml
app:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/health/"]
    interval: 10s
    timeout: 5s
    retries: 3
```

---

## Step 8: Graceful shutdown

Boot handles `SIGTERM` automatically — when Docker stops the container:

1. Stops accepting new connections
2. Waits for in-flight requests to complete
3. Calls `@PreDestroy` on all beans (closes DB pools, etc.)
4. Exits cleanly

Docker sends `SIGTERM`, waits 10 seconds, then `SIGKILL`. Boot shuts down in <1 second.

---

## Step 9: Optimize the Docker image

**Layer caching** — the Dockerfile copies `pubspec.yaml` first so `dart pub get` is cached unless dependencies change.

**Ignore unnecessary files:**

**`.dockerignore`**

```
.dart_tool/
build/
.git/
test/
*.md
.env
```

---

## Step 10: Test the Docker build

```bash
# Build
docker compose build

# Run
docker compose up -d

# Check health
curl http://localhost:8080/health/

# View logs
docker compose logs -f app

# Stop
docker compose down
```

---

## What you've learned

- `dart compile exe` creates a standalone binary (~15MB)
- Multi-stage Dockerfile: build with SDK, run without it
- `scratch` base image = minimal attack surface
- Environment variables configure production (no secrets in files)
- `depends_on` + `healthcheck` ensures correct startup order
- Boot handles `SIGTERM` for graceful shutdown
- Health endpoints let Docker/K8s monitor your app
- `.dockerignore` keeps the build context small

## Next steps

- [Guide 020: Test Your Application](020-test-your-application.md) — comprehensive testing strategies
