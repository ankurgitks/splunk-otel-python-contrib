#!/bin/bash

# Continuous Metric Trigger Test Runner
# Runs the metric trigger application on a configurable cadence, cycling through test scenarios
# Each run tests a different problematic pattern (Toxicity, Bias, Hallucination, Relevance)

set -e

echo "=============================================================================="
echo "🔄 Continuous Metric Trigger Test Runner"
echo "=============================================================================="
echo "This script runs metric trigger tests on a configurable interval indefinitely."
echo "Each run cycles through different test scenarios."
echo "Press Ctrl+C to stop."
echo "=============================================================================="

# Navigate to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check for .env file and load if present; otherwise rely on injected env vars
if [ -f .env ]; then
    # shellcheck disable=SC2046
    export $(grep -v '^#' .env | xargs)
else
    echo "ℹ️  No .env file found, relying on environment variables supplied at runtime"
fi

# Check for required variables
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Error: OPENAI_API_KEY not set via .env or environment"
    exit 1
fi

# Prefer manual/.venv but fall back to the parent examples/.venv so the script still works
VENV_DIR="${VENV_PATH:-.venv}"
if [ ! -d "$VENV_DIR" ]; then
    if [ -d "../.venv" ]; then
        VENV_DIR="../.venv"
    else
        echo "❌ Error: virtual environment not found. Set VENV_PATH or create .venv"
        exit 1
    fi
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
export TEST_MODE="single"

# Counter for runs
RUN_COUNT=0

# Allow slower cadence to avoid unnecessary token spend
INTERVAL_SECONDS=${RUN_INTERVAL_SECONDS:-1800}
INTERVAL_MINUTES=$((INTERVAL_SECONDS / 60))

echo "🔧 Configuration:"
echo "   Model: ${OPENAI_MODEL_NAME:-gpt-4o-mini}"
echo "   Interval: ${INTERVAL_MINUTES} minutes (${INTERVAL_SECONDS} seconds)"
echo "   OTLP Endpoint: ${OTEL_EXPORTER_OTLP_ENDPOINT:-default}"
echo ""
echo "🚀 Starting continuous test loop..."
echo ""

# Infinite loop
while true; do
    RUN_COUNT=$((RUN_COUNT + 1))
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "=============================================================================="
    echo "🧪 Test Run #$RUN_COUNT at $CURRENT_TIME"
    echo "=============================================================================="
    
    # Run the application
    if python3 multi-agent-openai-metrics-trigger.py; then
        echo ""
        echo "✅ Run #$RUN_COUNT completed successfully"
    else
        echo ""
        echo "❌ Run #$RUN_COUNT failed, but continuing..."
    fi
    
    echo ""
    echo "⏸️  Waiting ${INTERVAL_MINUTES} minutes until next run..."
    NEXT_RUN_TIME=$(date -d "+${INTERVAL_MINUTES} minutes" '+%H:%M:%S' 2>/dev/null || date -v+${INTERVAL_MINUTES}M '+%H:%M:%S')
    echo "   (Next run will be approximately at ${NEXT_RUN_TIME})"
    echo ""
    
    # Wait configured interval (default 30 minutes)
    sleep "${INTERVAL_SECONDS}"
done