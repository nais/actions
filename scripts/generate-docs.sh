#!/usr/bin/env bash
set -euo pipefail

# Generate markdown documentation for workflow inputs/outputs/secrets
# Usage: ./scripts/generate-docs.sh [workflow-file]

if [ $# -eq 0 ]; then
    echo "Usage: $0 <workflow-file>"
    echo "Example: $0 .github/workflows/mise-build-deploy-nais.yaml"
    exit 1
fi

workflow_file="$1"

if [ ! -f "$workflow_file" ]; then
    echo "Error: File not found: $workflow_file"
    exit 1
fi

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed. Install with: brew install yq"
    exit 1
fi

workflow_name=$(basename "$workflow_file")
echo "# Documentation for $workflow_name"
echo ""

# Generate inputs table
echo "## Inputs"
echo ""
echo "| Input | Description | Required | Default |"
echo "|-------|-------------|----------|---------|"

inputs=$(yq '.on.workflow_call.inputs | keys' "$workflow_file" 2>/dev/null | grep -v "^null$" | sed 's/- //' || true)

if [ -n "$inputs" ]; then
    while IFS= read -r input; do
        description=$(yq ".on.workflow_call.inputs.$input.description" "$workflow_file" | sed 's/^"//;s/"$//')
        required=$(yq ".on.workflow_call.inputs.$input.required" "$workflow_file")
        default=$(yq ".on.workflow_call.inputs.$input.default" "$workflow_file")

        # Format required field
        if [ "$required" = "true" ]; then
            required="Yes"
        else
            required="No"
        fi

        # Format default field
        if [ "$default" = "null" ]; then
            default="-"
        else
            default="\`$default\`"
        fi

        echo "| \`$input\` | $description | $required | $default |"
    done <<< "$inputs"
else
    echo "| - | No inputs defined | - | - |"
fi

echo ""

# Generate secrets table
echo "## Secrets"
echo ""
echo "| Secret | Description | Required |"
echo "|--------|-------------|----------|"

secrets=$(yq '.on.workflow_call.secrets | keys' "$workflow_file" 2>/dev/null | grep -v "^null$" | sed 's/- //' || true)

if [ -n "$secrets" ]; then
    while IFS= read -r secret; do
        description=$(yq ".on.workflow_call.secrets.$secret.description" "$workflow_file" 2>/dev/null || echo "No description")
        required=$(yq ".on.workflow_call.secrets.$secret.required" "$workflow_file")

        if [ "$required" = "true" ]; then
            required="Yes"
        else
            required="No"
        fi

        echo "| \`$secret\` | $description | $required |"
    done <<< "$secrets"
else
    echo "| - | No secrets defined | - |"
fi

echo ""

# Generate outputs table
echo "## Outputs"
echo ""
echo "| Output | Description |"
echo "|--------|-------------|"

outputs=$(yq '.on.workflow_call.outputs | keys' "$workflow_file" 2>/dev/null | grep -v "^null$" | sed 's/- //' || true)

if [ -n "$outputs" ]; then
    while IFS= read -r output; do
        description=$(yq ".on.workflow_call.outputs.$output.description" "$workflow_file" | sed 's/^"//;s/"$//')
        echo "| \`$output\` | $description |"
    done <<< "$outputs"
else
    echo "| - | No outputs defined |"
fi

echo ""
echo "---"
echo ""
echo "Copy the tables above and paste them into your README.md"
