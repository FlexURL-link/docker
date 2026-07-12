#!/bin/sh

set -e

DATA_DIR="/app/data"
DB_PASSWORD_FILE="$DATA_DIR/.db_password"
DB_PASS=$(openssl rand -hex 16)
DB_USER="flexurl"
DB_NAME="flexurl"
DB_HOST="localhost"
DB_PORT="5432"

export POSTGRES_URL="postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

# --- Generate secrets if missing ---

mkdir -p "$DATA_DIR"

# DB password
if [ -f "$DB_PASSWORD_FILE" ]; then
  DB_PASS=$(cat "$DB_PASSWORD_FILE")
  export POSTGRES_URL="postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
  echo "[FlexURL] Loaded existing DB password"
else
  echo "$DB_PASS" > "$DB_PASSWORD_FILE"
  chmod 600 "$DB_PASSWORD_FILE"
  echo "[FlexURL] Generated new DB password"
fi

# Encryption key
KEY_FILE="$DATA_DIR/.encryption_key"
if [ -z "$ENCRYPTION_KEY" ]; then
  if [ -f "$KEY_FILE" ]; then
    export ENCRYPTION_KEY=$(cat "$KEY_FILE")
    echo "[FlexURL] Loaded existing encryption key"
  else
    ENCRYPTION_KEY=$(openssl rand -hex 32)
    echo "$ENCRYPTION_KEY" > "$KEY_FILE"
    chmod 600 "$KEY_FILE"
    echo "[FlexURL] Generated new encryption key"
  fi
else
  echo "$ENCRYPTION_KEY" > "$KEY_FILE"
  chmod 600 "$KEY_FILE"
fi

# --- Init PostgreSQL ---

PGDATA="$DATA_DIR/pg"

# First run: init database
if [ ! -f "$PGDATA/PG_VERSION" ]; then
  echo "[FlexURL] Initializing PostgreSQL..."
  mkdir -p "$PGDATA"
  chown -R postgres:postgres "$PGDATA"
  printf '%s\n%s\n' "$DB_PASS" "$DB_PASS" > /tmp/.pwfile
  su-exec postgres initdb -D "$PGDATA" --auth=password --username="$DB_USER" --pwfile=/tmp/.pwfile
  rm -f /tmp/.pwfile
  # Allow local socket + TCP connections
  echo "local all all trust" > "$PGDATA/pg_hba.conf"
  echo "host all all 127.0.0.1/32 md5" >> "$PGDATA/pg_hba.conf"
  echo "host all all ::1/128 md5" >> "$PGDATA/pg_hba.conf"
  echo "[FlexURL] PostgreSQL initialized"
fi

# Start PostgreSQL
echo "[FlexURL] Starting PostgreSQL..."
chown -R postgres:postgres "$PGDATA"
su-exec postgres pg_ctl -D "$PGDATA" -l "$DATA_DIR/pg.log" start -w

# Wait for PostgreSQL to be ready
echo "[FlexURL] Waiting for PostgreSQL..."
until su-exec postgres pg_isready -q 2>/dev/null; do
  sleep 1
done
echo "[FlexURL] PostgreSQL is ready"

# Create user/database if first run
su-exec postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 || \
  su-exec postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
su-exec postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 || \
  su-exec postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
su-exec postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 2>/dev/null || true

# Run init.sql
su-exec postgres psql -U "$DB_USER" -d "$DB_NAME" -f /app/init.sql 2>/dev/null || true

echo "[FlexURL] Database ready"

# --- Start Next.js ---

echo "[FlexURL] Starting FlexURL on port ${PORT:-3000}..."
exec su-exec nextjs node /app/server.js
