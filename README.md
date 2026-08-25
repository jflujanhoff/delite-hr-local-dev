# delite-hr-local-dev

Local development orchestration for the Delite HR platform. Expects the following repos cloned side by side:

```
11.Delite AI/
├── delite-hr-backend/     (delite-agent-service — being renamed as the split below lands)
├── delite-hr-frontend/
├── delite-hr-service/     (HR/job-application domain — see its README)
└── delite-hr-local-dev/   ← you are here
```

`delite-hr-backend` and `delite-hr-service` are two separate backend services being split apart per the plan at `/Users/lujan/.claude/plans/majestic-noodling-conway.md` — `delite-hr-backend` (evolving into delite-agent-service) owns projects/documents/chat/generic tools, `delite-hr-service` owns the HR domain (company research, keywords, analytics, applications). They run as two separate processes below, each with its own database, and (from a later phase on) talk to each other over REST/MCP rather than sharing code.

## Setup

1. Make sure all repos are cloned and `delite-hr-backend/.env` + `delite-hr-service/.env` exist.
2. Start everything:
   ```bash
   chmod +x start.sh
   ./start.sh
   ```

Everything — Postgres, Redis, LocalStack (S3 emulator), the agent-service backend + its Celery worker, the hr-service backend + its own dedicated Redis and Celery worker, Flower, and the frontend — runs as a Docker container. There's nothing to `npm install` on the host; the frontend's dependencies install inside its own container image.

`delite-hr-service` gets its own Postgres database (`delite_hr_apps`) on the same Postgres instance as `delite-hr-backend`'s `delite_hr` database — separate databases, not a shared schema. This is created automatically by `postgres-init/create-hr-service-db.sh` on first container init; if you already have an existing `postgres_data` volume from before this database existed, run `./start.sh --reset` (wipes it) or create it by hand: `docker compose exec postgres psql -U postgres -c "CREATE DATABASE delite_hr_apps;"`.

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
| API (delite-agent-service) | http://localhost:8000 |
| HR API (delite-hr-service) | http://localhost:8001 |
| Flower (Celery) | http://localhost:5555 |
| LocalStack (S3) | http://localhost:4566 |
| Postgres | localhost:5432 (`delite_hr` + `delite_hr_apps` databases) |
| Redis (agent-service) | localhost:6379 |
| Redis (hr-service) | localhost:6381 |
