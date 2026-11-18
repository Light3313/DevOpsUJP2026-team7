#!/usr/bin/env bash

set -Eeuo pipefail

# Контейнери
DB_CONTAINER="${DB_CONTAINER:-dev-wiki-db-1}"
WEB_CONTAINER="${WEB_CONTAINER:-dev-php-wikimedia-1}"

# База даних
DB_NAME="wikidb"

# Конфігурація MediaWiki
CONFIG_PATH="/var/www/html/LocalSettings.php"

# Директорія резервних копій
BACKUP_DIR="${BACKUP_DIR:-/home/dev/backups/mywiki}"
LOG_FILE="$BACKUP_DIR/backup.log"

# Кількість днів зберігання
RETENTION_DAYS=14

# Час створення копії
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

DB_TMP="$BACKUP_DIR/.database_${TIMESTAMP}.sql.gz.tmp"
CONFIG_TMP="$BACKUP_DIR/.config_${TIMESTAMP}.tar.gz.tmp"

DB_FINAL="$BACKUP_DIR/database_${TIMESTAMP}.sql.gz"
CONFIG_FINAL="$BACKUP_DIR/config_${TIMESTAMP}.tar.gz"

STAGE_DIR=""

# Запис повідомлень у журнал
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Прибирання тимчасових файлів у разі помилки
cleanup_error() {
    local rc=$?
    trap - ERR

    rm -f "$DB_TMP" "$CONFIG_TMP"

    if [[ -n "$STAGE_DIR" ]]; then
        rm -rf "$STAGE_DIR"
    fi

    log "ERROR: Резервне копіювання завершилося з помилкою (код $rc)."
    exit "$rc"
}

trap cleanup_error ERR

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

log "Початок резервного копіювання MediaWiki."

# 1. Перевірка Docker
command -v docker >/dev/null

if [[ "$(docker inspect -f '{{.State.Running}}' "$DB_CONTAINER")" != "true" ]]; then
    echo "Контейнер бази даних не запущений."
    exit 1
fi

if [[ "$(docker inspect -f '{{.State.Running}}' "$WEB_CONTAINER")" != "true" ]]; then
    echo "Контейнер MediaWiki не запущений."
    exit 1
fi

log "Контейнери працюють."

# 2. Резервне копіювання бази даних
log "Створення резервної копії бази даних $DB_NAME."

docker exec "$DB_CONTAINER" sh -c '
    set -eu

    : "${MYSQL_USER:?MYSQL_USER не задано}"
    : "${MYSQL_PASSWORD:?MYSQL_PASSWORD не задано}"
    : "${MYSQL_DATABASE:?MYSQL_DATABASE не задано}"

    export MYSQL_PWD="$MYSQL_PASSWORD"

    exec mariadb-dump \
        --single-transaction \
        --quick \
        --routines \
        --triggers \
        --events \
        --hex-blob \
        --default-character-set=utf8mb4 \
        -u"$MYSQL_USER" \
        "$MYSQL_DATABASE"
' | gzip -c > "$DB_TMP"

# Перевірка дампу
gzip -t "$DB_TMP"
test -s "$DB_TMP"

log "Резервну копію бази даних створено."

# 3. Резервне копіювання конфігурації
log "Створення резервної копії LocalSettings.php."

docker exec "$WEB_CONTAINER" test -r "$CONFIG_PATH"

STAGE_DIR=$(mktemp -d "$BACKUP_DIR/.stage.XXXXXX")

docker cp \
    "$WEB_CONTAINER:$CONFIG_PATH" \
    "$STAGE_DIR/LocalSettings.php"

chmod 600 "$STAGE_DIR/LocalSettings.php"

tar -czf "$CONFIG_TMP" \
    -C "$STAGE_DIR" \
    LocalSettings.php

# Перевірка архіву конфігурації
tar -tzf "$CONFIG_TMP" | grep -Fx "LocalSettings.php" >/dev/null

test -s "$CONFIG_TMP"

rm -rf "$STAGE_DIR"
STAGE_DIR=""

log "Резервну копію конфігурації створено."

# 4. Збереження готових копій
mv "$DB_TMP" "$DB_FINAL"
mv "$CONFIG_TMP" "$CONFIG_FINAL"

chmod 600 "$DB_FINAL" "$CONFIG_FINAL"

log "Резервні копії успішно збережено."

# 5. Видалення старих резервних копій
find "$BACKUP_DIR" \
    -maxdepth 1 \
    -type f \
    \( -name 'database_*.sql.gz' -o -name 'config_*.tar.gz' \) \
    -mtime +"$RETENTION_DAYS" \
    -delete

log "Видалено резервні копії старше $RETENTION_DAYS днів."

log "Резервне копіювання успішно завершено."
