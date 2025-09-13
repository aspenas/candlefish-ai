# Quick Test Commands - Candlefish AI Workflows

## Immediate Testing (Run Now)

### Basic Validation Tests
```bash
cd /Users/patricksmith/candlefish-ai

# 1. Run comprehensive test suite
./scripts/test-workflows.sh

# 2. Validate individual YAML files
for file in .github/workflows/*.yml; do 
  python3 -c "import yaml; yaml.safe_load(open('$file'))" && echo "✅ $file" || echo "❌ $file"
done

# 3. Check setup script
bash -n scripts/setup-dev-environment.sh
ls -la scripts/setup-dev-environment.sh

# 4. Validate configuration files
python3 -c "import yaml; yaml.safe_load(open('.pre-commit-config.yaml'))"
node -c .releaserc.js
```

### Tool Availability Check
```bash
# Check required tools
for tool in git python3 node npm docker poetry pre-commit aws terraform; do
  command -v "$tool" && echo "✅ $tool" || echo "❌ $tool missing"
done

# Check versions
python3 --version
node --version
```

## Tests Requiring Setup

### Pre-commit Testing (after fixing config)
```bash
# Fix pre-commit config first (update typescript to ts in .pre-commit-config.yaml)
pre-commit validate-config
pre-commit install
pre-commit run --all-files
```

### Local Docker Services
```bash
# Test Docker environment
docker --version
docker-compose --version

# Start basic services for testing
docker run --rm -d --name test-postgres -e POSTGRES_PASSWORD=test -p 5432:5432 postgres:15
docker run --rm -d --name test-redis -p 6379:6379 redis:7
```

### Security Scanning (if tools available)
```bash
# Install and run security tools
pip install safety detect-secrets
safety check --short-report
detect-secrets scan --baseline .secrets.baseline .

# Container scanning
docker run --rm -v $(pwd):/src aquasecurity/trivy fs /src
```

## Tests Requiring GitHub/AWS Infrastructure

### GitHub Actions Simulation
```bash
# Install act for local GitHub Actions testing
npm install -g @nektos/act

# List available workflows
act --list

# Dry run specific jobs
act --job quality --dry-run
act --job python-tests --dry-run
```

### AWS Infrastructure Tests
```bash
# LocalStack for AWS simulation
docker run -d -p 4566:4566 localstack/localstack
export AWS_ENDPOINT_URL=http://localhost:4566
aws --endpoint-url=$AWS_ENDPOINT_URL s3 ls
```

## Current Status Summary

### ✅ Ready to Test Now
- YAML syntax validation
- Script syntax checking  
- Basic configuration validation
- Tool availability checking
- File structure validation

### ⚠️ Requires Minor Fixes
- Pre-commit config (typescript → ts)
- Shell script shellcheck warnings

### ❌ Requires Project Setup
- Python package structure (pyproject.toml, poetry.lock)
- Core directories (clos/, projects/, agents/)
- Unit test structure
- Application code

### 🔄 Requires Infrastructure
- AWS account and credentials
- GitHub repository with Actions
- Third-party service tokens (SonarCloud, Codecov, etc.)

## Quick Fix Commands

### Fix Pre-commit Config
```bash
# Update .pre-commit-config.yaml line 73:
sed -i '' 's/typescript/ts/' .pre-commit-config.yaml
```

### Create Basic Project Structure
```bash
# Create missing directories
mkdir -p clos/{tests,src} projects/{promoteros,paintbox} agents/{tests,src}

# Create basic Python project file
cat > pyproject.toml << 'EOF'
[tool.poetry]
name = "candlefish-ai"
version = "0.1.0"
description = "Candlefish AI Platform"
authors = ["Patrick Smith <patrick@candlefish.ai>"]

[tool.poetry.dependencies]
python = "^3.11"
fastapi = "^0.104.0"
uvicorn = "^0.24.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.0"
black = "^23.12.0"
ruff = "^0.1.9"
mypy = "^1.8.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
EOF
```

Run these commands to get started with testing your Candlefish AI workflows!