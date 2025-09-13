# Candlefish AI Workflow Automation

## 🚀 Complete Workflow Automation Solution

This repository now includes comprehensive workflow automation for the Candlefish AI platform, enabling efficient CI/CD pipelines, automated testing, deployment, monitoring, and documentation generation.

## 📁 Workflow Structure

```
.github/workflows/
├── ci-cd.yml              # Main CI/CD pipeline
├── test-automation.yml    # Comprehensive testing suite
├── aws-deployment.yml     # AWS deployment automation
├── monitoring-alerts.yml  # Monitoring and alerting
├── release.yml           # Semantic release automation
├── security.yml          # Security scanning and compliance
└── docs.yml              # Documentation generation

Configuration Files:
├── .releaserc.js         # Semantic release configuration
├── .pre-commit-config.yaml # Pre-commit hooks
└── scripts/
    └── setup-dev-environment.sh # Development setup script
```

## 🎯 Key Features

### 1. **CI/CD Pipeline** (`ci-cd.yml`)
- Multi-service build and deployment
- Parallel job execution for efficiency
- Environment-specific deployments (staging/production)
- Automatic rollback on failure
- Docker image building and scanning
- ECS, Lambda, and Kubernetes deployments

### 2. **Test Automation** (`test-automation.yml`)
- Unit, integration, and E2E testing
- Multi-browser testing with Cypress
- Performance testing with K6
- Contract testing with Pact
- Mutation testing for code quality
- Coverage reporting and enforcement

### 3. **AWS Deployment** (`aws-deployment.yml`)
- Infrastructure provisioning with Terraform
- ECS service deployments
- Lambda function deployments
- Kubernetes deployments to EKS
- Database migrations
- Post-deployment validation

### 4. **Monitoring & Alerts** (`monitoring-alerts.yml`)
- System health checks every 5 minutes
- Performance monitoring
- Cost tracking and alerts
- PagerDuty integration for critical alerts
- Slack notifications
- Automatic issue creation for failures

### 5. **Release Automation** (`release.yml`)
- Semantic versioning based on commit messages
- Automatic changelog generation
- Multi-format release assets
- Documentation updates
- Deployment to staging and production
- Release notifications

### 6. **Security Scanning** (`security.yml`)
- Dependency vulnerability scanning
- Secret detection
- Container security scanning
- Infrastructure security checks
- Compliance verification (GDPR, SOC 2, PCI DSS)
- Security report generation

### 7. **Documentation Generation** (`docs.yml`)
- API documentation from code
- Architecture diagrams with Mermaid
- User guides and tutorials
- Deployment to GitHub Pages
- S3 backup of documentation

## 🚦 Getting Started

### Prerequisites
- GitHub repository with Actions enabled
- AWS account (ID: 681214184463)
- Required secrets configured in GitHub

### Required GitHub Secrets
```yaml
# AWS
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

# Container Registry
DOCKER_USERNAME
DOCKER_PASSWORD

# Monitoring
DATADOG_API_KEY
NEW_RELIC_API_KEY
PAGERDUTY_TOKEN
PAGERDUTY_ROUTING_KEY
SLACK_WEBHOOK

# Security
SNYK_TOKEN
SONAR_TOKEN
GITLEAKS_LICENSE

# Release
SEMANTIC_RELEASE_TOKEN
NPM_TOKEN

# Testing
CYPRESS_RECORD_KEY
CODECOV_TOKEN

# Deployment
NETLIFY_AUTH_TOKEN
NETLIFY_SITE_ID
CLOUDFRONT_DISTRIBUTION_ID
```

### Initial Setup
```bash
# 1. Clone the repository
git clone https://github.com/your-org/candlefish-ai.git
cd candlefish-ai

# 2. Run the setup script
./scripts/setup-dev-environment.sh

# 3. Install pre-commit hooks
pre-commit install

# 4. Configure environment variables
cp .env.example .env.local
# Edit .env.local with your values
```

## 📊 Workflow Triggers

| Workflow | Trigger | Description |
|----------|---------|-------------|
| CI/CD | Push to main/develop, PR | Main pipeline for build and deploy |
| Tests | Push, PR, Daily at 2 AM | Comprehensive test suite |
| AWS Deploy | Manual, Push to main | Deploy to AWS infrastructure |
| Monitoring | Every 5 minutes | Health and performance checks |
| Release | Push to main | Semantic versioning and release |
| Security | Push, PR, Weekly | Security and compliance scanning |
| Docs | Push to main | Documentation generation |

## 🔄 Development Workflow

### Feature Development
1. Create feature branch from `develop`
2. Make changes and commit using conventional commits
3. Pre-commit hooks run automatically
4. Push changes to trigger CI/CD
5. Create PR to trigger full test suite
6. Merge to `develop` for staging deployment
7. Merge to `main` for production release

### Commit Message Format
```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`

### Release Process
1. Commits to `main` trigger semantic release
2. Version bumped based on commit types
3. Changelog updated automatically
4. GitHub release created with assets
5. Deployment to production environments
6. Notifications sent to team

## 🛠️ Manual Operations

### Deploy to Specific Environment
```bash
gh workflow run aws-deployment.yml \
  -f environment=staging \
  -f service=all \
  -f action=deploy
```

### Trigger Security Scan
```bash
gh workflow run security.yml
```

### Create Manual Release
```bash
gh workflow run release.yml \
  -f release_type=minor \
  -f prerelease_tag=beta
```

## 📈 Monitoring Dashboard

Access monitoring at:
- **CloudWatch**: AWS Console → CloudWatch → Dashboards → Candlefish
- **New Relic**: https://one.newrelic.com
- **DataDog**: https://app.datadoghq.com
- **GitHub Actions**: https://github.com/your-org/candlefish-ai/actions

## 🔐 Security Features

- **Secret Scanning**: Automatic detection of exposed secrets
- **Dependency Updates**: Renovate bot for automatic updates
- **Container Scanning**: Trivy, Snyk, and Anchore scanning
- **Code Analysis**: CodeQL, Semgrep, and SonarCloud
- **Compliance Checks**: GDPR, SOC 2, PCI DSS verification
- **Infrastructure Security**: Terraform security scanning

## 📚 Documentation

- **API Docs**: https://docs.candlefish.ai/api
- **Architecture**: https://docs.candlefish.ai/architecture
- **User Guides**: https://docs.candlefish.ai/guides
- **Deployment**: https://docs.candlefish.ai/deployment

## 🆘 Troubleshooting

### Common Issues

1. **Workflow Fails on First Run**
   - Ensure all required secrets are configured
   - Check AWS credentials and permissions

2. **Docker Build Fails**
   - Verify Dockerfile paths in workflow
   - Check Docker registry credentials

3. **Deployment Rollback**
   - Automatic rollback on validation failure
   - Manual rollback: `gh workflow run aws-deployment.yml -f action=rollback`

4. **Test Failures**
   - Check test reports in GitHub Actions artifacts
   - Review coverage reports in Codecov

## 📞 Support

- **Documentation**: https://docs.candlefish.ai
- **Issues**: https://github.com/your-org/candlefish-ai/issues
- **Slack**: #candlefish-dev
- **Email**: devops@candlefish.ai

## 🎉 Summary

Your Candlefish AI platform now has enterprise-grade workflow automation including:

✅ **7 Comprehensive GitHub Actions Workflows**
- CI/CD Pipeline with multi-service support
- Automated testing across all levels
- AWS deployment with Terraform
- Real-time monitoring and alerting
- Semantic release automation
- Security scanning and compliance
- Documentation generation

✅ **Development Tools**
- Pre-commit hooks for code quality
- Development environment setup script
- Docker Compose for local services
- Semantic versioning configuration

✅ **Production Features**
- Multi-environment deployments
- Automatic rollback on failures
- Health checks and monitoring
- Security scanning at every level
- Compliance verification
- Cost monitoring and alerts

✅ **Best Practices**
- Parallel job execution for speed
- Caching for efficiency
- Matrix testing across versions
- Comprehensive error handling
- Detailed logging and reporting
- Slack and PagerDuty integration

The workflows are production-ready and can be customized based on your specific needs. All scripts are executable and configured for your AWS account (681214184463).