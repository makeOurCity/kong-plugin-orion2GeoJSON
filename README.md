# Kong-FIWARE Orion Plugins

This project provides Kong plugins for integrating with FIWARE Orion Context Broker.

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. Run the basic environment test:
```bash
./tests/integration/basic.sh
```

This script will:
- Check if Docker is installed
- Verify Docker Compose availability
- Start all services
- Verify each service is running properly

2. After successful test, services will be available at:
- Kong Admin API: http://localhost:8001
- Kong Proxy: http://localhost:8000
- Orion Context Broker: http://localhost:1026

## Manual Start

If you prefer to start services manually:
```bash
docker compose up -d