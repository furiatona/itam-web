#!/bin/bash
# xborg.sh - manage Docker Laravel environment with backup
# Usage: ./xborg.sh start|stop|restart

set -euo pipefail

COMPOSE_FILE="local.docker-compose.yml"
APP_SERVICE="app"
DB_SERVICE="db"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-okaAtew0801}"
DB_DATABASE="${DB_DATABASE:-itam_db}"
BACKUP_DIR="./backups/db"

timestamp() {
  date +"%Y%m%d_%H%M%S"
}

backup_database() {
  mkdir -p "$BACKUP_DIR"
  BACKUP_FILE="$BACKUP_DIR/db_backup_$(timestamp).sql"
  echo "Backing up database to $BACKUP_FILE..."

  # Use -T to avoid TTY issues
  docker compose -f "$COMPOSE_FILE" exec -T "$DB_SERVICE" \
    sh -c "mariadb-dump -u root -p'$DB_ROOT_PASSWORD' $DB_DATABASE" > "$BACKUP_FILE"

  echo "Backup completed."
}

start() {
  echo "Starting Docker services..."
  docker compose -f "$COMPOSE_FILE" up -d

  echo "Installing composer dependencies inside container..."
  docker compose -f "$COMPOSE_FILE" exec -T "$APP_SERVICE" composer install --no-dev --optimize-autoloader

  echo "Fixing artisan permissions..."
  docker compose -f "$COMPOSE_FILE" exec -T "$APP_SERVICE" chmod +x artisan

  echo "Running migrations..."
  docker compose -f "$COMPOSE_FILE" exec -T "$APP_SERVICE" php artisan migrate --force

  echo "All services started successfully."
}

stop() {
  echo "Stopping Docker services..."
  backup_database
  docker compose -f "$COMPOSE_FILE" down
  echo "Services stopped."
}

restart() {
  stop
  start
}

# Main
if [ $# -ne 1 ]; then
  echo "Usage: $0 start|stop|restart"
  exit 1
fi

case "$1" in
  start) start ;;
  stop) stop ;;
  restart) restart ;;
  *) echo "Invalid option: $1"; echo "Usage: $0 start|stop|restart"; exit 1 ;;
esac