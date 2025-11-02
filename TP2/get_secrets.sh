#!/usr/bin/env bash
set -euo pipefail

export HOME=/opt/meow
export AZURE_CONFIG_DIR=/opt/meow/.azure
export AZURE_CORE_COLLECT_TELEMETRY=no
mkdir -p "$AZURE_CONFIG_DIR"

KV_NAME="${KV_NAME:-kv-emrep-24163}"
ENV_FILE="${ENV_FILE:-/opt/meow/.env}"

upsert_env() {
  local key="$1" val="$2"
  mkdir -p "$(dirname "$ENV_FILE")"
  touch "$ENV_FILE"
  if grep -qE "^${key}=" "$ENV_FILE"; then
    sed -i -E "s#^${key}=.*#${key}=${val}#" "$ENV_FILE"
  else
    echo "${key}=${val}" >> "$ENV_FILE"
  fi
}

/usr/bin/az login --identity >/dev/null 2>&1 || true

DB_PASS="$(/usr/bin/az keyvault secret show --vault-name "$KV_NAME" --name DB-PASSWORD --query value -o tsv 2>/dev/null || true)"
[ -n "${DB_PASS:-}" ] && upsert_env "DB_PASSWORD" "$DB_PASS"

FLASK_SECRET="$(/usr/bin/az keyvault secret show --vault-name "$KV_NAME" --name FLASK-SECRET-KEY --query value -o tsv 2>/dev/null || true)"
[ -n "${FLASK_SECRET:-}" ] && upsert_env "FLASK_SECRET_KEY" "$FLASK_SECRET"

exit 0