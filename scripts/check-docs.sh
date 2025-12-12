#!/usr/bin/env bash
set -euo pipefail

# Check if documentation is in sync with workflow definitions
# Usage: ./scripts/check-docs.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error_count=0

echo "Checking workflow documentation..."
echo ""

for workflow_file in .github/workflows/*.yaml; do
    workflow_name=$(basename "$workflow_file")
    echo "📋 Checking $workflow_name"

    # Check if yq is installed
    if ! command -v yq &> /dev/null; then
        echo -e "${RED}Error: yq is not installed. Install with: brew install yq${NC}"
        exit 1
    fi

    # Extract inputs from workflow
    inputs=$(yq '.on.workflow_call.inputs | keys' "$workflow_file" 2>/dev/null | grep -v "^null$" | sed 's/- //' || true)

    if [ -n "$inputs" ]; then
        echo "  Checking inputs..."
        while IFS= read -r input; do
            if grep -q "\`$input\`" README.md; then
                echo -e "    ${GREEN}✓${NC} $input"
            else
                echo -e "    ${RED}✗${NC} $input (not found in README)"
                ((error_count++))
            fi
        done <<< "$inputs"
    fi

    # Extract outputs from workflow
    outputs=$(yq '.on.workflow_call.outputs | keys' "$workflow_file" 2>/dev/null | grep -v "^null$" | sed 's/- //' || true)

    if [ -n "$outputs" ]; then
        echo "  Checking outputs..."
        while IFS= read -r output; do
            if grep -q "\`$output\`" README.md; then
                echo -e "    ${GREEN}✓${NC} $output"
            else
                echo -e "    ${RED}✗${NC} $output (not found in README)"
                ((error_count++))
            fi
        done <<< "$outputs"
    fi

    # Extract secrets from workflow
    secrets=$(yq '.on.workflow_call.secrets | keys' "$workflow_file" 2>/dev/null | grep -v "^null$" | sed 's/- //' || true)

    if [ -n "$secrets" ]; then
        echo "  Checking secrets..."
        while IFS= read -r secret; do
            if grep -q "\`$secret\`" README.md; then
                echo -e "    ${GREEN}✓${NC} $secret"
            else
                echo -e "    ${RED}✗${NC} $secret (not found in README)"
                ((error_count++))
            fi
        done <<< "$secrets"
    fi

    echo ""
done

if [ $error_count -eq 0 ]; then
    echo -e "${GREEN}✓ All workflow inputs/outputs/secrets are documented${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $error_count undocumented workflow fields${NC}"
    echo -e "${YELLOW}Tip: Run './scripts/generate-docs.sh' to generate documentation${NC}"
    exit 1
fi
