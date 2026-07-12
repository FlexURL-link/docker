# FlexURL

Self-hosted URL shortener. Single container, zero configuration.

- PostgreSQL + Next.js in one container
- AES-256-GCM encryption at rest
- Auto-generated DB password + encryption key
- Just works

## Install

### Docker Compose

```bash
git clone https://github.com/FlexURL-link/docker.git && cd docker
docker compose up -d
```

Done. App at `http://localhost:3000`.

### Docker Run

```bash
docker build -t flexurl .

docker run -d --name flexurl \
  -p 3000:3000 \
  -v flexurl-data:/app/data \
  flexurl
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `NEXT_PUBLIC_BASE_URL` | `http://localhost:3000` | Public URL shown in the UI |
| `NEXT_PUBLIC_API_URL` | (empty = same origin) | API base URL for the frontend |
| `ALLOWED_ORIGIN` | `*` | CORS origin for the create API |

DB password and encryption key are **auto-generated** on first start and stored in the `flexurl-data` volume. Nothing to configure.

## Update

### Docker Compose

```bash
docker compose up -d --build
```

### Docker Run

```bash
docker build -t flexurl .
docker stop flexurl && docker rm flexurl
docker run -d --name flexurl -p 3000:3000 -v flexurl-data:/app/data flexurl
```

Data (DB + keys) is preserved in the volume.

## Stop

```bash
# Compose
docker compose down

# Run
docker stop flexurl
```

Data preserved. Add `-v` to delete it.

## License

MIT
