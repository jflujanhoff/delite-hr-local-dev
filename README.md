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
2. Start everything:
   ```bash
   chmod +x start.sh
   ./start.sh
   ```

Everything — Postgres, Redis, LocalStack (S3 emulator), backend, Celery worker, Flower, and the frontend — runs as a Docker container. There's nothing to `npm install` on the host; the frontend's dependencies install inside its own container image.

File storage uses the same `boto3`/S3 code path as production, pointed at LocalStack instead of real AWS (`STORAGE_BACKEND=s3`, `S3_ENDPOINT_URL=http://localstack:4566` in `delite-hr-backend/.env`). Deploying to real AWS later is an env-var change (bucket, region, credentials/IAM role), not a code change.

## Commands

| Command | Description |
|---|---|
| `./start.sh` | Start everything (Docker) |
| `./start.sh --build` | Rebuild images then start |
| `./start.sh --restart` | Stop → rebuild → start fresh |
| `./start.sh --stop` | Stop all services |
| `./start.sh --reset` | Wipe DB, storage, LocalStack state, and Docker volumes |
| `./start.sh --logs` | Start then tail all logs |
| `./start.sh --backend-only` | Backend services only (no frontend) |
| `./start.sh --frontend-only` | Frontend only |

## URLs

| Service | URL |
|---|---|
| Frontend | http://localhost:3000 |
| API | http://localhost:8000 |
| Flower (Celery) | http://localhost:5555 |
| LocalStack (S3) | http://localhost:4566 |
| Postgres | localhost:5432 |
| Redis | localhost:6379 |
