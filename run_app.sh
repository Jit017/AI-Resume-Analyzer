#!/usr/bin/env bash
# Start Docker MySQL (if needed), then Streamlit with matching DB settings.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

export MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
export MYSQL_PORT="${MYSQL_PORT:-3307}"
export MYSQL_USER="${MYSQL_USER:-root}"
export MYSQL_PASSWORD="${MYSQL_PASSWORD:-resume_analyzer_local}"
export MYSQL_DATABASE="${MYSQL_DATABASE:-cv}"

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop, then run this script again."
  exit 1
fi

echo "Starting MySQL container (port ${MYSQL_PORT})..."
docker compose up -d mysql

echo "Waiting for MySQL to be ready..."
for i in $(seq 1 60); do
  if docker compose exec -T mysql mysqladmin ping -h 127.0.0.1 -uroot -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; then
    echo "MySQL is up."
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "MySQL did not become ready in time."
    exit 1
  fi
  sleep 1
done

cd "$ROOT/App"
exec "$ROOT/venv/bin/python" -m streamlit run App.py "$@"
