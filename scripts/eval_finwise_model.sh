#!/usr/bin/env bash
# Brings LLMOps Studio up pointed at Finwise's Ollama (finwise_scribe_v1)
# instead of its own demo Ollama. Run from the llmops-platform directory.
#
# Usage: ./scripts/eval_finwise_model.sh
#
# Assumes Finwise's own `ollama` service is already running
# (cd finwise_scribe && docker compose up -d ollama) -- this script
# doesn't start Finwise's stack, only checks it's reachable.

set -u
FINWISE_OLLAMA="http://localhost:11434"
MODEL_NAME="finwise_scribe_v1"

echo "== Checking Finwise's Ollama ($FINWISE_OLLAMA) =="
tags=$(curl -fsS --max-time 5 "$FINWISE_OLLAMA/api/tags" 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ Can't reach Finwise's Ollama at $FINWISE_OLLAMA."
  echo "   Start it first: cd finwise_scribe && docker compose up -d ollama"
  exit 1
fi
echo "✅ Reachable."

echo
echo "== Checking '$MODEL_NAME' is loaded =="
if echo "$tags" | grep -q "$MODEL_NAME"; then
  echo "✅ '$MODEL_NAME' is present."
else
  echo "❌ '$MODEL_NAME' is not loaded into this Ollama instance yet."
  echo "   Register it (from the finwise_scribe directory):"
  echo "   docker exec -it finwise_ollama ollama create $MODEL_NAME -f /models/Modelfile"
  exit 1
fi

echo
echo "== Bringing up LLMOps Studio, pointed at Finwise's Ollama =="
docker compose -f docker-compose.yml -f docker-compose.finwise-eval.yml up -d
if [ $? -ne 0 ]; then
  echo "❌ docker compose up failed -- see output above."
  exit 1
fi

echo
echo "== Waiting for services to warm up (30s) =="
sleep 30

echo
echo "== Running smoke test =="
if [ -x "./scripts/smoke_test.sh" ]; then
  ./scripts/smoke_test.sh
else
  echo "⚠️  scripts/smoke_test.sh not found or not executable -- skipping."
fi

echo
echo "----------------------------------------"
echo "Ready. Open http://localhost:5173, set Project Context to"
echo "'finwise-scribe' in Studio Canvas, and point any lab's model"
echo "selector at '$MODEL_NAME' to evaluate the real fine-tuned model."
