#!/bin/sh
# Every python-services container runs this same image. APP_MODULE picks
# which FastAPI app it serves -- set per-service in docker-compose.yml.
# Example: APP_MODULE=rag_benchmark_lab.api:app
set -eu

if [ -z "${APP_MODULE:-}" ]; then
  echo "APP_MODULE env var is required (e.g. llmops_studio.app:app)" >&2
  exit 1
fi

exec uvicorn "${APP_MODULE}" --host 0.0.0.0 --port "${PORT:-8000}"