#!/bin/bash
set -e

cd "$(dirname "$0")"

usage() {
  echo "---------------------------------------------------------------------"
  echo " FIRST TIME SETUP"
  echo "---------------------------------------------------------------------"
  echo "  Nothing to install locally — frontend deps install inside the"
  echo "  container on first build."
  echo ""
  echo "---------------------------------------------------------------------"
  echo " START"
  echo "---------------------------------------------------------------------"
  echo "  ./start.sh                   Start everything (Docker)"
  echo "  ./start.sh --logs            Start everything, then tail all logs"
  echo "  ./start.sh --build           Rebuild Docker images, then start"
  echo "  ./start.sh --build-logs      Rebuild Docker images, start, then tail all logs"
  echo "  ./start.sh --restart         Stop → rebuild → start fresh"
  echo "  ./start.sh --restart-logs    Stop → rebuild → start fresh, then tail all logs"
  echo "  ./start.sh --backend-only    Start backend services only (no frontend)"
  echo "  ./start.sh --frontend-only   Start frontend service only"
  echo ""
  echo "---------------------------------------------------------------------"
  echo " STOP"
  echo "---------------------------------------------------------------------"
  echo "  ./start.sh --stop            Stop all services"
  echo "  ./start.sh --reset           ⚠️  Wipe DB, storage, LocalStack, and Docker volumes"
  echo ""
  echo "---------------------------------------------------------------------"
  echo " LOGS"
  echo "---------------------------------------------------------------------"
  echo "  docker compose logs -f               Tail all logs"
  echo "  docker compose logs -f backend       Tail API logs only"
  echo "  docker compose logs -f frontend      Tail frontend logs only"
  echo "  docker compose logs -f celery_worker Tail Celery worker logs"
  echo ""
  echo "---------------------------------------------------------------------"
  echo " URLS"
  echo "---------------------------------------------------------------------"
  echo "  Frontend   → http://localhost:3000"
  echo "  API        → http://localhost:8000"
  echo "  Flower     → http://localhost:5555"
  echo "  LocalStack → http://localhost:4566"
  echo "---------------------------------------------------------------------"
}

BACKEND_SERVICES="postgres redis localstack backend celery_worker flower"
FRONTEND_SERVICE="frontend"

TAIL_LOGS=false
BACKEND_ONLY=false
FRONTEND_ONLY=false

for arg in "$@"; do
  [[ "$arg" == "--logs" ]]          && TAIL_LOGS=true
  [[ "$arg" == "--backend-only" ]]  && BACKEND_ONLY=true
  [[ "$arg" == "--frontend-only" ]] && FRONTEND_ONLY=true
done

services_to_start() {
  if $BACKEND_ONLY; then
    echo "$BACKEND_SERVICES"
  elif $FRONTEND_ONLY; then
    echo "$FRONTEND_SERVICE"
  else
    echo "$BACKEND_SERVICES $FRONTEND_SERVICE"
  fi
}

print_urls() {
  echo ""
  echo "Services running:"
  echo "  Frontend   → http://localhost:3000"
  echo "  API        → http://localhost:8000"
  echo "  Flower     → http://localhost:5555"
  echo "  LocalStack → http://localhost:4566"
  echo ""
}

case "$1" in
  --build|--build-logs)
    echo "Building images..."
    docker compose build
    echo "Starting services..."
    docker compose up -d $(services_to_start)
    [[ "$1" == "--build-logs" ]] && TAIL_LOGS=true
    ;;
  --restart|--restart-logs)
    echo "Stopping services..."
    docker compose down
    echo "Rebuilding images..."
    docker compose build
    echo "Starting services..."
    docker compose up -d $(services_to_start)
    [[ "$1" == "--restart-logs" ]] && TAIL_LOGS=true
    ;;
  --stop)
    echo "Stopping services..."
    docker compose down
    echo "All services stopped."
    exit 0
    ;;
  --reset)
    echo "⚠️  This will DELETE the database, all storage files, LocalStack state, and Docker volumes."
    read -r -p "Are you sure? (yes/N) " confirm
    if [[ "$confirm" != "yes" ]]; then
      echo "Aborted."
      exit 0
    fi
    echo "Stopping services and wiping volumes..."
    docker compose down -v
    echo "Deleting storage files..."
    rm -rf "../delite-hr-backend/storage/*"
    echo "Rebuilding images..."
    docker compose build
    echo "Starting fresh..."
    docker compose up -d $(services_to_start)
    ;;
  --frontend-only)
    echo "Starting frontend..."
    docker compose up -d frontend
    print_urls
    exit 0
    ;;
  --backend-only)
    echo "Starting backend services..."
    docker compose up -d $BACKEND_SERVICES
    ;;
  --logs)
    echo "Starting services..."
    docker compose up -d $(services_to_start)
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  "")
    echo "Starting services..."
    docker compose up -d $(services_to_start)
    ;;
  *)
    echo "Unknown flag: $1"
    usage
    exit 1
    ;;
esac

print_urls

if $TAIL_LOGS; then
  echo "Tailing logs (Ctrl+C to stop tailing — services keep running)..."
  docker compose logs -f
else
  echo "Logs:     docker compose logs -f"
  echo "Stop all: ./start.sh --stop"
fi
