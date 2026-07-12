# FlexURL

Self-hosted URL shortener with encryption at rest. Create short links via a web UI, visitors are redirected automatically.

- Next.js 16 + PostgreSQL
- AES-256-GCM encryption (URLs stored encrypted)
- Auto-generated encryption key (no manual setup needed)
- Docker ready

## Quick Start

### Docker Compose (recommended)

```bash
git clone <repo-url> && cd docker
docker compose up -d
```

App is available at `http://localhost:3000`.

### Docker Run

```bash
# Start PostgreSQL
docker run -d --name flexurl-db \
  -e POSTGRES_USER=flexurl \
  -e POSTGRES_PASSWORD=flexurl \
  -e POSTGRES_DB=flexurl \
  -v pgdata:/var/lib/postgresql/data \
  -v ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro \
  -p 5432:5432 \
  postgres:16-alpine

# Build the app
docker build -t flexurl .

# Run the app
docker run -d --name flexurl-app \
  -p 3000:3000 \
  -e POSTGRES_URL=postgresql://flexurl:flexurl@host.docker.internal:5432/flexurl \
  -v app-data:/app/data \
  --link flexurl-db \
  flexurl
```

> Replace `host.docker.internal` with your PostgreSQL address.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_URL` | (required) | PostgreSQL connection string |
| `NEXT_PUBLIC_BASE_URL` | `http://localhost:3000` | Public URL shown in the UI |
| `NEXT_PUBLIC_API_URL` | (empty = same origin) | API base URL for the frontend |
| `ALLOWED_ORIGIN` | `*` | CORS origin for the create API |

`ENCRYPTION_KEY` is **auto-generated** on first startup and stored in the `app-data` volume. You don't need to set it manually.

## Update

### Docker Compose

```bash
git pull
docker compose up -d --build
```

Your data (database + encryption key) is preserved in named volumes.

### Docker Run

```bash
# Rebuild
docker build -t flexurl .

# Stop and remove old container
docker stop flexurl-app && docker rm flexurl-app

# Start new container (same volumes)
docker run -d --name flexurl-app \
  -p 3000:3000 \
  -e POSTGRES_URL=postgresql://flexurl:flexurl@host.docker.internal:5432/flexurl \
  -v app-data:/app/data \
  --link flexurl-db \
  flexurl
```

## Stop

### Docker Compose

```bash
docker compose down
```

### Docker Run

```bash
docker stop flexurl-app flexurl-db
```

Data is preserved. Use `docker compose down -v` or `docker volume rm` to delete it.

## License

MIT
