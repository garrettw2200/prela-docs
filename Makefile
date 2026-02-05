.PHONY: help install dev test lint format clean build docs

help:
	@echo "Prela Development Commands"
	@echo "=========================="
	@echo "install    - Install all dependencies"
	@echo "dev        - Start development environment"
	@echo "test       - Run all tests"
	@echo "lint       - Run linters"
	@echo "format     - Format code"
	@echo "clean      - Clean build artifacts"
	@echo "build      - Build all packages"
	@echo "docs       - Build documentation"

install:
	@echo "Installing SDK dependencies..."
	cd sdk && pip install -e ".[dev]"
	@echo "Installing frontend dependencies..."
	cd frontend && npm install
	@echo "Done!"

dev:
	@echo "Starting development environment..."
	docker-compose -f backend/docker-compose.yml up -d
	@echo "Backend services started!"
	@echo "Run 'cd frontend && npm run dev' to start the frontend"

test:
	@echo "Running SDK tests..."
	cd sdk && pytest
	@echo "Running backend tests..."
	cd backend && make test
	@echo "Running frontend tests..."
	cd frontend && npm test

lint:
	@echo "Linting SDK..."
	cd sdk && ruff check . && mypy prela
	@echo "Linting frontend..."
	cd frontend && npm run lint

format:
	@echo "Formatting SDK..."
	cd sdk && black . && ruff check --fix .
	@echo "Formatting frontend..."
	cd frontend && npm run format

clean:
	@echo "Cleaning build artifacts..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "dist" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "build" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
	@echo "Done!"

build:
	@echo "Building SDK..."
	cd sdk && pip install build && python -m build
	@echo "Building frontend..."
	cd frontend && npm run build
	@echo "Done!"

docs:
	@echo "Building documentation..."
	cd docs && mkdocs build
	@echo "Documentation built in docs/site/"
