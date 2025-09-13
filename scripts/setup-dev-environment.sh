#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up Candlefish AI Development Environment${NC}"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    local missing=()
    
    # Check required commands
    for cmd in git node npm python3 pip docker docker-compose aws terraform kubectl helm; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        else
            echo -e "✅ $cmd is installed"
        fi
    done
    
    # Check Python version
    python_version=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    if (( $(echo "$python_version < 3.11" | bc -l) )); then
        echo -e "${RED}❌ Python 3.11+ is required (found $python_version)${NC}"
        exit 1
    fi
    
    # Check Node version
    node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if (( node_version < 18 )); then
        echo -e "${RED}❌ Node.js 18+ is required (found v$node_version)${NC}"
        exit 1
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing required tools: ${missing[*]}${NC}"
        echo "Please install the missing tools and try again."
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites installed${NC}"
}

# Install Python dependencies
install_python_deps() {
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    
    # Install Poetry
    if ! command -v poetry &> /dev/null; then
        echo "Installing Poetry..."
        curl -sSL https://install.python-poetry.org | python3 -
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Install Python packages
    poetry install --no-interaction --no-ansi
    
    # Install pre-commit hooks
    poetry run pre-commit install
    poetry run pre-commit install --hook-type commit-msg
    
    echo -e "${GREEN}✅ Python dependencies installed${NC}"
}

# Install Node dependencies
install_node_deps() {
    echo -e "${YELLOW}Installing Node.js dependencies...${NC}"
    
    # Install pnpm
    if ! command -v pnpm &> /dev/null; then
        echo "Installing pnpm..."
        npm install -g pnpm
    fi
    
    # Install global tools
    npm install -g semantic-release @commitlint/cli @commitlint/config-conventional
    
    # Install project dependencies
    for project in projects/*/; do
        if [ -f "$project/package.json" ]; then
            echo "Installing dependencies for $(basename $project)..."
            (cd "$project" && pnpm install --frozen-lockfile)
        fi
    done
    
    echo -e "${GREEN}✅ Node.js dependencies installed${NC}"
}

# Setup local services
setup_services() {
    echo -e "${YELLOW}Setting up local services...${NC}"
    
    # Create Docker network
    docker network create candlefish-dev 2>/dev/null || true
    
    # Create docker-compose for local development
    cat > docker-compose.dev.yml <<EOF
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: candlefish
      POSTGRES_PASSWORD: localdev123
      POSTGRES_DB: candlefish_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - candlefish-dev
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U candlefish"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - candlefish-dev
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  localstack:
    image: localstack/localstack:latest
    environment:
      - SERVICES=s3,dynamodb,secretsmanager,lambda,sqs,sns
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
      - LAMBDA_EXECUTOR=docker
      - DOCKER_HOST=unix:///var/run/docker.sock
    ports:
      - "4566:4566"
      - "4571:4571"
    volumes:
      - localstack_data:/tmp/localstack
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - candlefish-dev

volumes:
  postgres_data:
  redis_data:
  localstack_data:

networks:
  candlefish-dev:
    external: true
EOF
    
    # Start services
    docker-compose -f docker-compose.dev.yml up -d
    
    # Wait for services to be ready
    echo "Waiting for services to be ready..."
    sleep 10
    
    # Check service health
    docker-compose -f docker-compose.dev.yml ps
    
    echo -e "${GREEN}✅ Local services started${NC}"
}

# Setup AWS local environment
setup_aws_local() {
    echo -e "${YELLOW}Setting up AWS local environment...${NC}"
    
    # Configure AWS CLI for LocalStack
    aws configure set aws_access_key_id test --profile localstack
    aws configure set aws_secret_access_key test --profile localstack
    aws configure set region us-east-1 --profile localstack
    
    # Create S3 buckets
    aws --endpoint-url=http://localhost:4566 --profile localstack \
        s3 mb s3://candlefish-dev-assets 2>/dev/null || true
    aws --endpoint-url=http://localhost:4566 --profile localstack \
        s3 mb s3://candlefish-dev-backups 2>/dev/null || true
    
    # Create DynamoDB tables
    aws --endpoint-url=http://localhost:4566 --profile localstack \
        dynamodb create-table \
        --table-name candlefish-sessions \
        --attribute-definitions AttributeName=id,AttributeType=S \
        --key-schema AttributeName=id,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST 2>/dev/null || true
    
    # Create secrets
    aws --endpoint-url=http://localhost:4566 --profile localstack \
        secretsmanager create-secret \
        --name candlefish/database-url \
        --secret-string "postgresql://candlefish:localdev123@localhost:5432/candlefish_dev" 2>/dev/null || true
    
    echo -e "${GREEN}✅ AWS local environment configured${NC}"
}

# Initialize database
initialize_database() {
    echo -e "${YELLOW}Initializing database...${NC}"
    
    # Wait for PostgreSQL to be ready
    until docker exec $(docker-compose -f docker-compose.dev.yml ps -q postgres) \
        pg_isready -U candlefish > /dev/null 2>&1; do
        echo "Waiting for PostgreSQL..."
        sleep 2
    done
    
    # Run migrations
    poetry run alembic upgrade head
    
    # Seed development data
    poetry run python scripts/seed_dev_data.py
    
    echo -e "${GREEN}✅ Database initialized${NC}"
}

# Setup environment variables
setup_environment() {
    echo -e "${YELLOW}Setting up environment variables...${NC}"
    
    if [ ! -f .env.local ]; then
        cat > .env.local <<EOF
# Candlefish AI Local Development Environment

# Database
DATABASE_URL=postgresql://candlefish:\${DB_PASSWORD:-localdev}@localhost:5432/candlefish_dev
REDIS_URL=redis://localhost:6379

# AWS
AWS_REGION=us-east-1
AWS_ENDPOINT_URL=http://localhost:4566
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test

# Application
ENVIRONMENT=development
DEBUG=true
SECRET_KEY=$(openssl rand -hex 32)
JWT_SECRET=$(openssl rand -hex 32)

# Services
CLOS_PORT=8000
PROMOTEROS_PORT=8001
PAINTBOX_PORT=8002

# External APIs (use test keys for development)
ANTHROPIC_API_KEY=your_test_key_here
OPENAI_API_KEY=your_test_key_here
TIKTOK_API_KEY=your_test_key_here

# Monitoring (optional)
NEW_RELIC_LICENSE_KEY=
DATADOG_API_KEY=
SENTRY_DSN=

# Feature Flags
ENABLE_AGENT_LOGGING=true
ENABLE_PERFORMANCE_MONITORING=false
ENABLE_RATE_LIMITING=false
EOF
        echo -e "${GREEN}✅ Created .env.local from template${NC}"
        echo -e "${YELLOW}⚠️  Please update .env.local with your API keys${NC}"
    else
        echo -e "${GREEN}✅ .env.local already exists${NC}"
    fi
}

# Create development scripts
create_dev_scripts() {
    echo -e "${YELLOW}Creating development helper scripts...${NC}"
    
    mkdir -p scripts/dev
    
    # Create start script
    cat > scripts/dev/start.sh <<'EOF'
#!/bin/bash
echo "Starting Candlefish AI development environment..."

# Start Docker services
docker-compose -f docker-compose.dev.yml up -d

# Start CLOS orchestrator
poetry run python clos/orchestrator.py &

# Start PromoterOS API
(cd projects/promoteros && pnpm run dev) &

# Start Paintbox service
(cd projects/paintbox && pnpm run dev) &

echo "Services started. Press Ctrl+C to stop."
wait
EOF
    
    # Create stop script
    cat > scripts/dev/stop.sh <<'EOF'
#!/bin/bash
echo "Stopping Candlefish AI development environment..."

# Stop application services
pkill -f "clos/orchestrator.py"
pkill -f "pnpm run dev"

# Stop Docker services
docker-compose -f docker-compose.dev.yml down

echo "Services stopped."
EOF
    
    # Create reset script
    cat > scripts/dev/reset.sh <<'EOF'
#!/bin/bash
echo "Resetting development environment..."

# Stop services
./scripts/dev/stop.sh

# Remove volumes
docker-compose -f docker-compose.dev.yml down -v

# Clean build artifacts
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "dist" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "build" -exec rm -rf {} + 2>/dev/null || true

echo "Environment reset complete."
EOF
    
    chmod +x scripts/dev/*.sh
    
    echo -e "${GREEN}✅ Development scripts created${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}
╔═══════════════════════════════════════════╗
║   Candlefish AI Development Setup        ║
╚═══════════════════════════════════════════╝
${NC}"
    
    check_prerequisites
    install_python_deps
    install_node_deps
    setup_services
    setup_aws_local
    setup_environment
    initialize_database
    create_dev_scripts
    
    echo -e "${GREEN}
╔═══════════════════════════════════════════╗
║   ✅ Setup Complete!                      ║
╚═══════════════════════════════════════════╝

Next steps:
1. Update .env.local with your API keys
2. Run './scripts/dev/start.sh' to start all services
3. Access the application:
   - CLOS API: http://localhost:8000
   - PromoterOS: http://localhost:8001
   - Paintbox: http://localhost:8002
   - API Documentation: http://localhost:8000/docs

Useful commands:
- Start services: ./scripts/dev/start.sh
- Stop services: ./scripts/dev/stop.sh
- Reset environment: ./scripts/dev/reset.sh
- Run tests: poetry run pytest
- Run linting: poetry run ruff check .
- Deploy to staging: gh workflow run aws-deployment.yml -f environment=staging

Documentation: https://docs.candlefish.ai
${NC}"
}

# Run main function
main "$@"