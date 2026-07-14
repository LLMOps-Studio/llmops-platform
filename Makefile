# =============================================================================
# LLMOps Platform Orchestration
# =============================================================================

.PHONY: up up-monitoring down clean

# Start core services (Ollama, Chroma, MLflow)
up:
	docker-compose up -d

# Start all services including Postgres, Prometheus, and Grafana
up-monitoring:
	docker-compose --profile monitoring up -d

# Stop and remove all containers
down:
	docker-compose down

# Stop and thoroughly clean all containers and local volumes
clean:
	docker-compose down -v