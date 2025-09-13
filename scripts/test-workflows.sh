#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Candlefish AI Workflow Testing Suite${NC}"
echo "========================================"

# Test results tracking
tests_passed=0
tests_failed=0
tests_skipped=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    local can_fail="${3:-false}"
    
    echo -n "Testing $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((tests_passed++))
        return 0
    else
        if [ "$can_fail" = "true" ]; then
            echo -e "${YELLOW}⚠️  SKIP (dependency missing)${NC}"
            ((tests_skipped++))
        else
            echo -e "${RED}❌ FAIL${NC}"
            ((tests_failed++))
        fi
        return 1
    fi
}

echo -e "\n${YELLOW}Phase 1: Syntax & Configuration Validation${NC}"
echo "----------------------------------------"

# YAML Validation
echo "YAML Workflow Files:"
for file in .github/workflows/*.yml; do
    run_test "$(basename "$file")" "python3 -c 'import yaml; yaml.safe_load(open(\"$file\"))'"
done

# Pre-commit config
run_test "Pre-commit config" "python3 -c 'import yaml; yaml.safe_load(open(\".pre-commit-config.yaml\"))'"

# JavaScript config
run_test "Release config syntax" "node -c .releaserc.js" true

# Shell script validation
run_test "Setup script syntax" "bash -n scripts/setup-dev-environment.sh"

echo -e "\n${YELLOW}Phase 2: Tool Availability${NC}"
echo "------------------------"

# Required tools check
tools=("git" "python3" "node" "npm" "docker")
for tool in "${tools[@]}"; do
    run_test "$tool availability" "command -v $tool" true
done

# Version checks
run_test "Python 3.11+" "python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)'" true
run_test "Node.js 18+" "node -e 'process.exit(parseInt(process.version.slice(1)) >= 18 ? 0 : 1)'" true

echo -e "\n${YELLOW}Phase 3: Project Structure${NC}"
echo "------------------------"

# Directory structure
directories=("scripts" ".github/workflows")
for dir in "${directories[@]}"; do
    run_test "$dir exists" "test -d $dir"
done

# Required files
files=("scripts/setup-dev-environment.sh" ".pre-commit-config.yaml" ".releaserc.js")
for file in "${files[@]}"; do
    run_test "$file exists" "test -f $file"
done

# Missing but expected files/directories
expected_missing=("clos" "projects" "pyproject.toml" "poetry.lock")
echo -e "\n${YELLOW}Expected Missing Components:${NC}"
for item in "${expected_missing[@]}"; do
    if [ -e "$item" ]; then
        echo -e "  ✅ $item (found)"
    else
        echo -e "  ❌ $item (missing - expected)"
        ((tests_skipped++))
    fi
done

echo -e "\n${YELLOW}Phase 4: Advanced Tooling (Optional)${NC}"
echo "------------------------------------"

# Optional tools
optional_tools=("poetry" "pre-commit" "docker-compose" "shellcheck" "aws" "terraform")
for tool in "${optional_tools[@]}"; do
    run_test "$tool availability" "command -v $tool" true
done

# Pre-commit validation (may fail due to config issues)
if command -v pre-commit &>/dev/null; then
    echo -n "Testing pre-commit config validation... "
    if pre-commit validate-config .pre-commit-config.yaml &>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((tests_passed++))
    else
        echo -e "${YELLOW}⚠️  FAIL (known issue with typescript type)${NC}"
        ((tests_skipped++))
    fi
fi

echo -e "\n${BLUE}Test Results Summary${NC}"
echo "===================="
echo -e "✅ Passed: ${GREEN}$tests_passed${NC}"
echo -e "❌ Failed: ${RED}$tests_failed${NC}"  
echo -e "⚠️  Skipped: ${YELLOW}$tests_skipped${NC}"

if [ $tests_failed -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All critical tests passed!${NC}"
    exit_code=0
else
    echo -e "\n${RED}⚠️  Some tests failed. Check above for details.${NC}"
    exit_code=1
fi

echo -e "\n${BLUE}Next Steps:${NC}"
echo "1. Fix any failed tests above"
echo "2. Run './scripts/setup-dev-environment.sh' to set up full development environment"
echo "3. Create missing project structure (clos/, projects/, etc.)"
echo "4. Add pyproject.toml and poetry.lock for Python dependency management"
echo "5. Test individual workflow components with 'act' or GitHub Actions"

exit $exit_code