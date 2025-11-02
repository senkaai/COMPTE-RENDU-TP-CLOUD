#!/usr/bin/env bash
set -euo pipefail

export HOME=/var/lib/backup AZURE_CONFIG_DIR=/var/lib/backup/.azure AZURE_CORE_COLLECT_TELEMETRY=no
mkdir -p "$AZURE_CONFIG_DIR"

DB_HOST=${DB_HOST:-127.0.0.1}
DB_NAME=${DB_NAME:-meow_database}
DB_USER=${DB_USER:-backup}
DB_PASS=${DB_PASS:-B4ckup!123}
SA_NAME=${SA_NAME:-step24}
CONTAINER=${CONTAINER:-meow}

TS=$(date -u +%Y%m%dT%H%M%SZ)
ARCHIVE="/tmp/${DB_NAME}_${TS}.sql.gz"

mysqldump --single-transaction --routines --events \
  -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip -c > "$ARCHIVE"

/usr/bin/az login --identity >/dev/null 2>&1 || true
/usr/bin/az storage blob upload \
  --account-name "$SA_NAME" \
  --container-name "$CONTAINER" \
  --name "backups/$(basename "$ARCHIVE")" \
  --file "$ARCHIVE" \
  --auth-mode login -o table

rm -f "$ARCHIVE"
exit 0
EOF