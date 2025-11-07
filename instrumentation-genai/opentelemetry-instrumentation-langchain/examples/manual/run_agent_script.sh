#!/bin/bash

# Continuous Metric Trigger Test Runner
# Runs the metric trigger application every 5 minutes, cycling through test scenarios
# Each run tests a different problematic pattern (Toxicity, Bias, Hallucination, Relevance)

set -e

echo "=============================================================================="
echo "🔄 Continuous Metric Trigger Test Runner"
echo "=============================================================================="
echo "This script runs metric trigger tests every 5 minutes indefinitely."
echo "Each run cycles through different test scenarios."
echo "Press Ctrl+C to stop."
echo "=============================================================================="

# Navigate to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check for .env file
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found in $SCRIPT_DIR"
    echo "Please create a .env file with required variables"
    exit 1
fi

# Load environment variables
export $(grep -v '^#' .env | xargs)

# Check for required variables
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Error: OPENAI_API_KEY not set in .env file"
    exit 1
fi

# Set test mode to single (will rotate through scenarios)

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

echo "🔧 Configuration:"
echo "   Model: ${OPENAI_MODEL_NAME:-gpt-4o-mini}"
echo "   Interval: 5 minutes (300 seconds)"
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
    echo "⏸️  Waiting 5 minutes until next run..."
    echo "   (Next run will be approximately at $(date -v+5M '+%H:%M:%S'))"
    echo ""
    
    # Wait 5 minutes (300 seconds)
    sleep 300
done