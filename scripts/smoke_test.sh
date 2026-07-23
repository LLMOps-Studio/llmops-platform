#!/usr/bin/env bash
# One-command health/consistency check for the full LLMOps Studio stack.
# Run after `docker compose up -d` (give it ~30-60s to warm up first).
#
# Usage: ./scripts/smoke_test.sh
#
# Checks HTTP-level reachability and a few known-fragile spots (the
# Project Context dropdown, model discovery, dashboard aggregation) that
# have silently broken before without any container-level error -- exit
# code 0 only if every check passes.

set -u
FAILURES=0
BASE="http://localhost"

check() {
  local name="$1"
  local url="$2"
  local grep_for="${3:-}"

  body=$(curl -fsS --max-time 5 "$url" 2>/dev/null)
  status=$?

  if [ $status -ne 0 ]; then
    echo "❌ $name -- unreachable ($url)"
    FAILURES=$((FAILURES + 1))
    return
  fi

  if [ -n "$grep_for" ] && ! echo "$body" | grep -q "$grep_for"; then
    echo "⚠️  $name -- reachable but response looks wrong (expected to contain '$grep_for')"
    echo "    got: $(echo "$body" | head -c 200)"
    FAILURES=$((FAILURES + 1))
    return
  fi

  echo "✅ $name"
}

echo "== Core infrastructure =="
check "Ollama"        "$BASE:11435/api/tags"
check "ChromaDB"       "$BASE:8088/api/v2/heartbeat"
check "MLflow"        "$BASE:5000/health"

echo
echo "== Python services (health endpoints) =="
check "Studio Core"    "$BASE:8000/health" "healthy"
check "RAG Lab"        "$BASE:8002/health" "healthy"
check "PromptOps Lab"  "$BASE:8003/health" "healthy"
check "Schema Lab"     "$BASE:8004/health" "healthy"
check "Review Lab"     "$BASE:8005/health" "healthy"
check "Memory Lab"     "$BASE:8006/health" "healthy"

echo
echo "== Regression checks for previously-broken endpoints =="
check "Project Context dropdown (Faz 1 fix)" "$BASE:8000/api/v1/projects" "finwise-scribe"
check "Model discovery reads OLLAMA_HOST (Faz 1 fix)" "$BASE:8000/api/v1/models" "models"
check "Dashboard aggregation (Faz 1 fix)" "$BASE:8000/api/v1/dashboard" "runs"

echo
echo "== UI runtime config (Faz 2 fix) =="
check "config.js is generated (not the empty default)" "$BASE:5173/config.js" "STUDIO_CORE_URL"

echo
echo "----------------------------------------"
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed. See above."
  echo "Common causes: containers still warming up (wait and re-run), a build"
  echo "that predates the Faz 0-3 patches (rebuild with --no-cache), or a"
  echo "genuinely new regression."
  exit 1
fi
