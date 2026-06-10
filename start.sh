#!/bin/bash
set -e

cd "$(dirname "$0")"

BACKEND_DIR="../delite-hr-backend"
FRONTEND_DIR="../delite-hr-frontend"
FRONTEND_PID_FILE=".frontend.pid"

usage() {
  echo "Usage: ./start.sh [--build | --restart | --stop | --reset] [--logs] [--backend-only | --frontend-only]"
  echo ""
  echo "  (no flag)            Start backend (Docker) + frontend (npm run dev)"
  echo "  --build              Rebuild backend images then start both"
  echo "  --restart            Stop → rebuild → start both fresh"
  echo "  --stop               Stop all services (Docker + frontend)"
  echo "  --reset              ⚠️  WIPE EVERYTHING: DB + storage + Docker volumes"
  echo "  --logs               Start then tail backend logs live"
  echo "  --backend-only       Start backend Docker services only"
  echo "  --frontend-only      Start frontend (npm run dev) only"
  echo ""
  echo "Other useful commands:"
  echo "  docker compose logs -f           Tail all logs"
  echo "  docker compose logs -f backend   Tail API only"
  echo "  docker compose down              Stop backend services"
  echo "  cat /tmp/delite-frontend.log     View frontend logs"
}

TAIL_LOGS=false
BACKEND_ONLY=false
FRONTEND_ONLY=false

for arg in "$@"; do
  [[ "$arg" == "--logs" ]]          && TAIL_LOGS=true
  [[ "$arg" == "--backend-only" ]]  && BACKEND_ONLY=true
  [[ "$arg" == "--frontend-only" ]] && FRONTEND_ONLY=true
done

start_frontend() {
  if [[ -f "$FRONTEND_PID_FILE" ]] && kill -0 "$(cat "$FRONTEND_PID_FILE")" 2>/dev/null; then
    echo "Frontend already running (PID $(cat "$FRONTEND_PID_FILE"))."
    return
  fi
  echo "Starting frontend..."
  (cd "$FRONTEND_DIR" && npm run dev > /tmp/delite-frontend.log 2>&1) &
  echo $! > "$FRONTEND_PID_FILE"
  echo "Frontend started (PID $!) — logs: /tmp/delite-frontend.log"
}

stop_frontend() {
  if [[ -f "$FRONTEND_PID_FILE" ]]; then
    PID=$(cat "$FRONTEND_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
      echo "Stopping frontend (PID $PID)..."
      kill "$PID"
    fi
    rm -f "$FRONTEND_PID_FILE"
  fi
}

print_urls() {
  echo ""
  echo "Services running:"
  echo "  Frontend  → http://localhost:3000"
  echo "  API       → http://localhost:8000"
  echo "  Flower    → http://localhost:5555"
  echo ""
}

case "$1" in
  --build)
    echo "Building backend images..."
    docker compose build
    echo "Starting backend services..."
    docker compose up -d
    $BACKEND_ONLY || start_frontend
    ;;
  --restart)
    echo "Stopping services..."
    docker compose down
    stop_frontend
    echo "Rebuilding backend images..."
    docker compose build
    echo "Starting backend services..."
    docker compose up -d
    $BACKEND_ONLY || start_frontend
    ;;
  --stop)
    echo "Stopping backend services..."
    docker compose down
    stop_frontend
    echo "All services stopped."
    exit 0
    ;;
  --reset)
    echo "⚠️  This will DELETE the database, all storage files, and Docker volumes."
    read -r -p "Are you sure? (yes/N) " confirm
    if [[ "$confirm" != "yes" ]]; then
      echo "Aborted."
      exit 0
    fi
    echo "Stopping services and wiping volumes..."
    docker compose down -v
    stop_frontend
    echo "Deleting storage files..."
    rm -rf "$BACKEND_DIR/storage/*"
    echo "Rebuilding images..."
    docker compose build
    echo "Starting fresh..."
    docker compose up -d
    $BACKEND_ONLY || start_frontend
    ;;
  --frontend-only)
    start_frontend
    print_urls
    exit 0
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  "")
    if $FRONTEND_ONLY; then
      start_frontend
      print_urls
      exit 0
    fi
    echo "Starting backend services..."
    docker compose up -d
    $BACKEND_ONLY || start_frontend
    ;;
  *)
    echo "Unknown flag: $1"
    usage
    exit 1
    ;;
esac

print_urls

if $TAIL_LOGS; then
  echo "Tailing backend logs (Ctrl+C to stop tailing — services keep running)..."
  docker compose logs -f
else
  echo "Backend logs:  docker compose logs -f"
  echo "Frontend logs: cat /tmp/delite-frontend.log"
  echo "Stop all:      ./start.sh --stop"
fi
