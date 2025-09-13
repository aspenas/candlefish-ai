# Candlefish AI - Workflow Test Plan & Analysis

## Executive Summary

This document provides a comprehensive test plan for validating the Candlefish AI workflows, including local testing capabilities, infrastructure requirements, and identified issues.

## Test Results Summary

### ✅ Validated Components

1. **YAML Syntax Validation**: All 7 workflow files have valid YAML syntax
2. **Setup Script**: `/Users/patricksmith/candlefish-ai/scripts/setup-dev-environment.sh` is executable with valid syntax
3. **Release Configuration**: `.releaserc.js` is properly formatted JavaScript

### ⚠️ Issues Identified

1. **Pre-commit Configuration**: Type tag 'typescript' not recognized (may require newer identify/pre-commit versions)
2. **Missing Project Structure**: Core directories `clos/` and `projects/` are not present
3. **Missing Dependencies**: No `pyproject.toml` or `poetry.lock` found in project root

## Workflow Analysis

### GitHub Actions Workflows

| Workflow | File | Status | Local Testable | Notes |
|----------|------|--------|---------------|--------|
| CI/CD Pipeline | `ci-cd.yml` | ✅ Valid | Partial | Requires AWS, GitHub context |
| Test Automation | `test-automation.yml` | ✅ Valid | Yes | Most components can run locally |
| Security & Compliance | `security.yml` | ✅ Valid | Partial | Some tools require GitHub Security |
| AWS Deployment | `aws-deployment.yml` | ✅ Valid | No | Requires AWS credentials |
| Release | `release.yml` | ✅ Valid | No | Requires GitHub releases |
| Documentation | `docs.yml` | ✅ Valid | Yes | Can test doc generation locally |
| Monitoring & Alerts | `monitoring-alerts.yml` | ✅ Valid | No | Requires AWS/monitoring services |

## Local Testing Strategy

### Phase 1: Immediate Tests (No Dependencies Required)

These tests can be run right now on any system:

```bash
# 1. Validate all YAML syntax
cd /Users/patricksmith/candlefish-ai
for file in .github/workflows/*.yml; do 
  python3 -c "import yaml; yaml.safe_load(open('$file'))" && echo "✅ $file" || echo "❌ $file"
done

# 2. Validate setup script syntax
bash -n scripts/setup-dev-environment.sh

# 3. Check file permissions
ls -la scripts/setup-dev-environment.sh

# 4. Validate semantic release config
node -c .releaserc.js

# 5. Check pre-commit config structure (may show warnings)
pre-commit validate-config .pre-commit-config.yaml
```

### Phase 2: Dependency-Based Tests (Requires Setup)

These require dependencies but can run without cloud services:

```bash
# 1. Install Poetry and Python dependencies
curl -sSL https://install.python-poetry.org | python3 -
export PATH="$HOME/.local/bin:$PATH"
poetry install --no-interaction --no-ansi

# 2. Install Node.js dependencies (requires package.json)
npm install -g pnpm semantic-release

# 3. Test code quality tools locally
poetry run ruff check . || echo "No Python files to check"
poetry run black --check . || echo "No Python files to check" 
poetry run mypy clos/ agents/ || echo "Directories not found"

# 4. Test pre-commit hooks (after fixing config)
pre-commit install
pre-commit run --all-files

# 5. Test unit testing framework
poetry run pytest tests/ || echo "No tests directory found"
```

### Phase 3: Container & Service Tests (Requires Docker)

```bash
# 1. Test Docker setup from setup script
./scripts/setup-dev-environment.sh --dry-run

# 2. Test individual Docker services
docker-compose -f docker-compose.dev.yml config
docker-compose -f docker-compose.dev.yml up -d postgres redis

# 3. Test container builds (when Dockerfiles exist)
docker build -t candlefish-test -f docker/clos/Dockerfile . || echo "Dockerfile not found"

# 4. Test security scanning on containers
docker run --rm -v $(pwd):/src aquasecurity/trivy fs /src
```

### Phase 4: GitHub Infrastructure Tests (Requires GitHub)

```bash
# 1. Test workflow syntax with act (local GitHub Actions)
npm install -g @nektos/act
act --list

# 2. Test specific jobs locally
act --job quality --dry-run
act --job test --dry-run

# 3. Test GitHub CLI integration
gh auth status
gh workflow list
```

## Test Commands by Category

### Syntax & Configuration Validation

```bash
# YAML validation
find .github/workflows -name "*.yml" -exec python3 -c "import yaml; yaml.safe_load(open('{}'))" \; -print

# JavaScript validation  
node -c .releaserc.js

# Shell script validation
bash -n scripts/setup-dev-environment.sh
shellcheck scripts/setup-dev-environment.sh

# Pre-commit config validation
pre-commit validate-config
```

### Dependency & Environment Tests

```bash
# Check required tools
for cmd in git node npm python3 pip docker docker-compose aws terraform kubectl helm; do
  command -v "$cmd" && echo "✅ $cmd" || echo "❌ $cmd missing"
done

# Version checks
python3 --version | grep -E "3\.(1[1-9]|[2-9][0-9])" && echo "✅ Python 3.11+" || echo "❌ Python < 3.11"
node --version | grep -E "v(1[8-9]|[2-9][0-9])" && echo "✅ Node 18+" || echo "❌ Node < 18"

# Poetry installation test
poetry --version || curl -sSL https://install.python-poetry.org | python3 -
```

### Security & Quality Tests

```bash
# Secret scanning
detect-secrets scan --baseline .secrets.baseline || echo "detect-secrets not installed"
gitleaks detect --source . || echo "gitleaks not installed"

# Code quality (when files exist)
ruff check . || echo "No Python files or ruff not installed"  
black --check . || echo "No Python files or black not installed"
mypy . || echo "No Python files or mypy not installed"

# Dependency vulnerability scanning
safety check || echo "safety not installed"
npm audit || echo "No package.json or npm not available"
```

### Infrastructure & Service Tests

```bash
# LocalStack for AWS testing
docker run -d -p 4566:4566 localstack/localstack
aws --endpoint-url=http://localhost:4566 s3 ls || echo "LocalStack not ready"

# Database testing
docker run -d -e POSTGRES_PASSWORD=test -p 5432:5432 postgres:15
psql -h localhost -U postgres -d postgres -c "SELECT 1;" || echo "PostgreSQL not ready"

# Redis testing
docker run -d -p 6379:6379 redis:7
redis-cli ping || echo "Redis not ready"
```

## Required Infrastructure

### For Full Workflow Testing

1. **GitHub Infrastructure**:
   - GitHub repository with Actions enabled
   - GitHub secrets configured (AWS keys, tokens)
   - Branch protection rules
   - Status checks enabled

2. **AWS Infrastructure**:
   - AWS Account (681214184463)
   - ECS clusters for staging/production
   - ECR repositories for container images
   - Lambda functions for serverless components
   - Secrets Manager for configuration
   - CloudWatch for monitoring

3. **Third-party Services**:
   - SonarCloud account and token
   - Codecov account and token
   - Snyk account and token
   - Cypress Dashboard (optional)
   - Slack webhook for notifications

### Local Development Setup

1. **Required Tools**:
   - Docker & Docker Compose
   - Python 3.11+
   - Node.js 18+
   - Poetry
   - AWS CLI
   - Terraform
   - kubectl & Helm

2. **Optional Tools**:
   - act (for local GitHub Actions testing)
   - LocalStack (for AWS service simulation)
   - k3d/kind (for local Kubernetes testing)

## Recommendations

### Immediate Actions

1. **Fix Pre-commit Config**: Update to use supported type tags or newer pre-commit/identify versions
2. **Create Missing Directories**: Add placeholder `clos/`, `projects/`, `agents/` directories
3. **Add Core Files**: Create `pyproject.toml`, `poetry.lock`, and basic `package.json`
4. **Shell Script Improvements**: Fix shellcheck warnings in setup script

### Short-term Improvements

1. **Add Mock Tests**: Create unit tests that can run without external dependencies
2. **Docker Development**: Add development Dockerfiles for easier testing
3. **Local Testing Scripts**: Create scripts to run workflow components locally
4. **Documentation**: Add testing instructions for each workflow

### Long-term Enhancements

1. **Test Pyramid Implementation**: Add comprehensive unit, integration, and E2E tests
2. **Staging Environment**: Set up dedicated staging environment for testing
3. **Monitoring Integration**: Add test result monitoring and alerting
4. **Automated Dependency Updates**: Set up Dependabot or similar for maintenance

## Test Execution Matrix

| Test Type | Local | Docker | GitHub | AWS | Status |
|-----------|-------|--------|--------|-----|---------|
| YAML Validation | ✅ | ✅ | ✅ | ✅ | Ready |
| Script Syntax | ✅ | ✅ | ✅ | ✅ | Ready |
| Pre-commit | ⚠️ | ✅ | ✅ | ✅ | Needs fix |
| Unit Tests | ❌ | ❌ | ❌ | ❌ | Missing structure |
| Integration Tests | ❌ | ⚠️ | ⚠️ | ⚠️ | Partial |
| E2E Tests | ❌ | ❌ | ⚠️ | ⚠️ | Missing apps |
| Security Scans | ⚠️ | ✅ | ✅ | ✅ | Tools needed |
| Deployment | ❌ | ❌ | ⚠️ | ❌ | Needs AWS |

Legend: ✅ Ready, ⚠️ Partial/Issues, ❌ Not Ready

## Next Steps

1. Run Phase 1 tests immediately to validate current state
2. Fix pre-commit configuration issues
3. Create minimal project structure to enable Phase 2 tests
4. Set up Docker environment for Phase 3 tests
5. Configure GitHub and AWS infrastructure for full testing
6. Implement missing test suites and monitoring

This test plan provides a roadmap for validating the Candlefish AI workflows from basic syntax checking to full end-to-end deployment testing.