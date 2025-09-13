# 🚀 Candlefish AI Platform

> Central orchestration platform for AI-powered applications and services

[![CI/CD Pipeline](https://github.com/candlefish-ai/candlefish-ai/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/candlefish-ai/candlefish-ai/actions/workflows/ci-cd.yml)
[![Security Scan](https://github.com/candlefish-ai/candlefish-ai/actions/workflows/security.yml/badge.svg)](https://github.com/candlefish-ai/candlefish-ai/actions/workflows/security.yml)
[![Documentation](https://github.com/candlefish-ai/candlefish-ai/actions/workflows/docs.yml/badge.svg)](https://docs.candlefish.ai)

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Development Setup](#development-setup)
- [Deployment](#deployment)
- [Services](#services)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

Candlefish AI is a comprehensive platform that orchestrates AI-powered applications and services. It provides:

- **CLOS (Candlefish Operating System)**: Central orchestration engine
- **PromoterOS**: AI-powered concert booking platform
- **Paintbox**: Creative AI tools and brand management
- **AI Agents**: Specialized agents for various tasks

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Load Balancer                         │
└─────────────────────────────────────────────────────────────┘
                                │
                ┌───────────────┴───────────────┐
                │                               │
        ┌───────▼────────┐            ┌────────▼────────┐
        │ CLOS           │            │ PromoterOS      │
        │ Orchestrator   │◄───────────┤ API             │
        └───────┬────────┘            └─────────────────┘
                │
        ┌───────▼────────────────────────┐
        │        AI Agents               │
        ├─────────────┬───────────────────┤
        │ Ticket      │ Venue    │ Price │
        │ Analyzer    │ Matcher  │ Opt.  │
        └─────────────┴───────────────────┘
                │
        ┌───────▼────────────────────────┐
        │     Data Layer                 │
        ├──────────┬──────────┬──────────┤
        │PostgreSQL│  Redis   │    S3    │
        └──────────┴──────────┴──────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 20+
- Python 3.12+
- AWS CLI configured
- GitHub CLI (gh)

### One-Line Setup

```bash
git clone https://github.com/candlefish-ai/candlefish-ai.git && \
cd candlefish-ai && \
./scripts/setup-dev-environment.sh
```

### Manual Setup

1. **Clone the repository**
```bash
git clone https://github.com/candlefish-ai/candlefish-ai.git
cd candlefish-ai
```

2. **Configure environment**
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Install dependencies**
```bash
# Python dependencies
pip install poetry
poetry install

# Node.js dependencies
npm install -g pnpm
pnpm install
```

4. **Start services**
```bash
docker-compose up -d
```

5. **Run migrations**
```bash
poetry run alembic upgrade head
```

6. **Access the application**
- CLOS API: http://localhost:8000
- PromoterOS: http://localhost:8001
- Paintbox: http://localhost:8002
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090

## 💻 Development Setup

### Configure GitHub Secrets

```bash
# Automatically configure GitHub secrets from AWS
./scripts/configure-github-secrets.sh
```

### Install Pre-commit Hooks

```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

### Run Tests

```bash
# Python tests
poetry run pytest

# JavaScript tests
pnpm test

# All tests
./scripts/run-tests.sh
```

### Code Quality

```bash
# Python linting
poetry run ruff check .
poetry run black .
poetry run mypy .

# JavaScript linting
pnpm lint
pnpm typecheck
```

## 🚢 Deployment

### Deploy to Staging

```bash
gh workflow run aws-deployment.yml \
  -f environment=staging \
  -f service=all \
  -f action=deploy
```

### Deploy to Production

```bash
gh workflow run aws-deployment.yml \
  -f environment=production \
  -f service=all \
  -f action=deploy
```

### Infrastructure Management

```bash
# Initialize Terraform
cd terraform/environments/production
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply
```

## 🔧 Services

### CLOS Orchestrator

Central orchestration engine that manages all AI agents and services.

- **Port**: 8000
- **Docs**: http://localhost:8000/docs
- **Health**: http://localhost:8000/health

### PromoterOS

AI-powered concert booking and event management platform.

- **Port**: 8001
- **Features**: Event discovery, venue matching, pricing optimization

### Paintbox

Creative AI tools for brand management and content generation.

- **Port**: 8002
- **Features**: Image generation, brand consistency, creative tools

### AI Agents

Specialized agents for various tasks:

- **Ticket Analyzer**: Analyzes ticket availability and demand
- **Venue Matcher**: Matches events with appropriate venues
- **Price Optimizer**: Optimizes pricing strategies
- **Social Analyzer**: Analyzes social media trends

## 📚 Documentation

- **API Documentation**: https://docs.candlefish.ai/api
- **Architecture Guide**: https://docs.candlefish.ai/architecture
- **Deployment Guide**: https://docs.candlefish.ai/deployment
- **Development Guide**: https://docs.candlefish.ai/development

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Commit using conventional commits
5. Push and create a PR

### Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Code style
- `refactor:` Code refactoring
- `perf:` Performance improvement
- `test:` Testing
- `chore:` Maintenance

## 🔒 Security

- All secrets stored in AWS Secrets Manager
- Automated security scanning with every commit
- Regular dependency updates
- Compliance checks (GDPR, SOC 2, PCI DSS)

Report security issues to: security@candlefish.ai

## 📊 Monitoring

- **Metrics**: Prometheus + Grafana
- **Logs**: CloudWatch Logs
- **Tracing**: AWS X-Ray
- **APM**: New Relic

## 🛠️ Tech Stack

### Backend
- Python 3.12
- FastAPI
- SQLAlchemy
- Celery
- Redis

### Frontend
- TypeScript
- React
- Next.js
- TailwindCSS

### Infrastructure
- AWS (ECS, Lambda, RDS, ElastiCache)
- Terraform
- Docker
- Kubernetes

### AI/ML
- Anthropic Claude
- OpenAI GPT
- Custom ML models

## 📝 License

Copyright © 2024 Candlefish AI. All rights reserved.

## 🆘 Support

- **Documentation**: https://docs.candlefish.ai
- **Issues**: https://github.com/candlefish-ai/candlefish-ai/issues
- **Email**: support@candlefish.ai
- **Slack**: #candlefish-support

## 🎉 Acknowledgments

Built with ❤️ by the Candlefish AI team.

Special thanks to all contributors and the open-source community.