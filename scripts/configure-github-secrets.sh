#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔐 Configuring GitHub Secrets from AWS Secrets Manager${NC}"

# Check prerequisites
if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI (gh) is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Get repository info
REPO_OWNER="candlefish-ai"
REPO_NAME="candlefish-ai"

# AWS Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="681214184463"

echo -e "${YELLOW}Fetching secrets from AWS Secrets Manager...${NC}"

# Function to get secret from AWS and set in GitHub
set_github_secret() {
    local secret_name=$1
    local github_secret_name=$2
    
    echo -n "Setting $github_secret_name... "
    
    # Get secret from AWS Secrets Manager
    secret_value=$(aws secretsmanager get-secret-value \
        --secret-id "$secret_name" \
        --query SecretString \
        --output text 2>/dev/null || echo "")
    
    if [ -z "$secret_value" ]; then
        echo -e "${YELLOW}Not found in AWS (will need manual configuration)${NC}"
        return
    fi
    
    # Set secret in GitHub
    echo "$secret_value" | gh secret set "$github_secret_name" \
        --repo "$REPO_OWNER/$REPO_NAME" 2>/dev/null || {
        echo -e "${RED}Failed${NC}"
        return
    }
    
    echo -e "${GREEN}✓${NC}"
}

# Create secrets that don't exist in AWS Secrets Manager yet
echo -e "${YELLOW}Creating required secrets in AWS Secrets Manager...${NC}"

# Create AWS Account ID secret
aws secretsmanager create-secret \
    --name candlefish/aws-account-id \
    --secret-string "$AWS_ACCOUNT_ID" \
    --description "AWS Account ID for Candlefish" 2>/dev/null || \
    aws secretsmanager update-secret \
    --secret-id candlefish/aws-account-id \
    --secret-string "$AWS_ACCOUNT_ID"

# Create placeholder secrets if they don't exist
declare -A SECRETS=(
    ["candlefish/docker-username"]="candlefish"
    ["candlefish/docker-password"]="changeme"
    ["candlefish/npm-token"]="changeme"
    ["candlefish/sonar-token"]="changeme"
    ["candlefish/snyk-token"]="changeme"
    ["candlefish/codecov-token"]="changeme"
    ["candlefish/cypress-record-key"]="changeme"
    ["candlefish/slack-webhook"]="https://hooks.slack.com/services/CHANGE/ME/PLEASE"
    ["candlefish/pagerduty-token"]="changeme"
    ["candlefish/pagerduty-routing-key"]="changeme"
    ["candlefish/semantic-release-token"]="changeme"
    ["candlefish/netlify-auth-token"]="changeme"
    ["candlefish/netlify-site-id"]="changeme"
    ["candlefish/cloudfront-distribution-id"]="changeme"
    ["candlefish/terraform-state-bucket"]="candlefish-terraform-state"
    ["candlefish/mail-username"]="notifications@candlefish.ai"
    ["candlefish/mail-password"]="changeme"
)

for secret_name in "${!SECRETS[@]}"; do
    echo -n "Creating $secret_name... "
    aws secretsmanager create-secret \
        --name "$secret_name" \
        --secret-string "${SECRETS[$secret_name]}" \
        --description "Candlefish CI/CD Secret" 2>/dev/null || \
    echo -n "(already exists) "
    echo -e "${GREEN}✓${NC}"
done

# Get AWS credentials (these should already exist)
echo -e "${YELLOW}Retrieving AWS credentials...${NC}"
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id || echo "")
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key || echo "")

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "${RED}AWS credentials not found in CLI configuration${NC}"
    echo "Please configure AWS CLI with: aws configure"
    exit 1
fi

# Store AWS credentials in Secrets Manager
aws secretsmanager create-secret \
    --name candlefish/aws-access-key-id \
    --secret-string "$AWS_ACCESS_KEY_ID" 2>/dev/null || \
aws secretsmanager update-secret \
    --secret-id candlefish/aws-access-key-id \
    --secret-string "$AWS_ACCESS_KEY_ID"

aws secretsmanager create-secret \
    --name candlefish/aws-secret-access-key \
    --secret-string "$AWS_SECRET_ACCESS_KEY" 2>/dev/null || \
aws secretsmanager update-secret \
    --secret-id candlefish/aws-secret-access-key \
    --secret-string "$AWS_SECRET_ACCESS_KEY"

# New Relic License Key (from AWS Secrets Manager)
aws secretsmanager create-secret \
    --name candlefish/newrelic-key \
    --secret-string "changeme-add-real-key" 2>/dev/null || \
aws secretsmanager update-secret \
    --secret-id candlefish/newrelic-key \
    --secret-string "changeme-add-real-key"

echo -e "${YELLOW}Setting GitHub secrets...${NC}"

# Map AWS Secrets to GitHub Secrets
declare -A SECRET_MAPPING=(
    ["candlefish/aws-account-id"]="AWS_ACCOUNT_ID"
    ["candlefish/aws-access-key-id"]="AWS_ACCESS_KEY_ID"
    ["candlefish/aws-secret-access-key"]="AWS_SECRET_ACCESS_KEY"
    ["candlefish/docker-username"]="DOCKER_USERNAME"
    ["candlefish/docker-password"]="DOCKER_PASSWORD"
    ["candlefish/npm-token"]="NPM_TOKEN"
    ["candlefish/sonar-token"]="SONAR_TOKEN"
    ["candlefish/snyk-token"]="SNYK_TOKEN"
    ["candlefish/codecov-token"]="CODECOV_TOKEN"
    ["candlefish/cypress-record-key"]="CYPRESS_RECORD_KEY"
    ["candlefish/slack-webhook"]="SLACK_WEBHOOK"
    ["candlefish/datadog-api-key"]="DATADOG_API_KEY"
    ["candlefish/newrelic-key"]="NEW_RELIC_API_KEY"
    ["candlefish/pagerduty-token"]="PAGERDUTY_TOKEN"
    ["candlefish/pagerduty-routing-key"]="PAGERDUTY_ROUTING_KEY"
    ["candlefish/semantic-release-token"]="SEMANTIC_RELEASE_TOKEN"
    ["candlefish/netlify-auth-token"]="NETLIFY_AUTH_TOKEN"
    ["candlefish/netlify-site-id"]="NETLIFY_SITE_ID"
    ["candlefish/cloudfront-distribution-id"]="CLOUDFRONT_DISTRIBUTION_ID"
    ["candlefish/terraform-state-bucket"]="TF_STATE_BUCKET"
    ["candlefish/mail-username"]="MAIL_USERNAME"
    ["candlefish/mail-password"]="MAIL_PASSWORD"
)

# Check if we're authenticated with GitHub
if ! gh auth status &>/dev/null; then
    echo -e "${RED}Not authenticated with GitHub CLI${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

# Set each secret in GitHub
for aws_secret in "${!SECRET_MAPPING[@]}"; do
    github_secret="${SECRET_MAPPING[$aws_secret]}"
    set_github_secret "$aws_secret" "$github_secret"
done

# Additional GitHub-specific secrets
echo -e "${YELLOW}Setting GitHub-specific secrets...${NC}"

# GitHub Token (use current auth token)
echo -n "Setting GITHUB_TOKEN... "
gh secret set GITHUB_TOKEN --repo "$REPO_OWNER/$REPO_NAME" < <(gh auth token) && \
    echo -e "${GREEN}✓${NC}" || echo -e "${RED}Failed${NC}"

echo -e "${GREEN}
╔═══════════════════════════════════════════╗
║   ✅ GitHub Secrets Configuration Complete  ║
╚═══════════════════════════════════════════╝

Secrets configured in GitHub repository: $REPO_OWNER/$REPO_NAME

${YELLOW}Important Notes:${NC}
1. Some secrets are placeholders and need to be updated:
   - Docker Hub credentials
   - NPM token for package publishing
   - Third-party service tokens (SonarCloud, Snyk, etc.)
   - Notification webhooks (Slack, PagerDuty)

2. To update a secret in AWS and sync to GitHub:
   aws secretsmanager update-secret --secret-id <name> --secret-string <value>
   Then run this script again.

3. To view current GitHub secrets:
   gh secret list --repo $REPO_OWNER/$REPO_NAME

${NC}"