# delite-hr-local-dev

Local development orchestration for the Delite HR platform. Expects the following repos cloned side by side:

```
11.Delite AI/
├── delite-hr-backend/
├── delite-hr-frontend/
└── delite-hr-local-dev/   ← you are here
```

## Setup

1. Make sure both repos are cloned and `delite-hr-backend/.env` exists.
2. Install frontend dependencies (first time only):
   ```bash
   cd ../delite-hr-frontend && npm install
   ```
3. Start everything:
   ```bash
   chmod +x start.sh
   ./start.sh
   ```

## Commands

| Command | Description |
|---|---|
| `./start.sh` | Start backend (Docker) + frontend (`npm run dev`) |
| `./start.sh --build` | Rebuild backend images then start both |
| `./start.sh --restart` | Stop → rebuild → start fresh |
| `./start.sh --stop` | Stop all services |
| `./start.sh --reset` | Wipe DB, storage, and Docker volumes |
| `./start.sh --logs` | Start then tail backend logs |
| `./start.sh --backend-only` | Backend Docker services only |
| `./start.sh --frontend-only` | Frontend only |

## URLs

| Service | URL |
|---|---|
| Frontend | http://localhost:3000 |
| API | http://localhost:8000 |
| Flower (Celery) | http://localhost:5555 |
| Postgres | localhost:5432 |
| Redis | localhost:6379 |
