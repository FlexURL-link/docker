#!/bin/sh

DATA_DIR="/app/data"
KEY_FILE="$DATA_DIR/.encryption_key"

mkdir -p "$DATA_DIR"

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

exec su-exec nextjs "$@"
