#!/bin/sh
# Runs automatically on first Postgres container init (mounted at
# /docker-entrypoint-initdb.d — only executes against an empty data
# directory, per the official postgres image's own behavior). Creates the
# second database delite-hr-service owns, alongside the existing "delite_hr"
# database delite-agent-service owns on the same Postgres instance. Since
# it only runs on first init, an existing postgres_data volume from before
# this file existed won't pick it up — run `./start.sh --reset` (wipes the
# volume) or `docker compose exec postgres psql -U postgres -c "CREATE
# DATABASE delite_hr_apps;"` by hand in that case.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE delite_hr_apps;
EOSQL
