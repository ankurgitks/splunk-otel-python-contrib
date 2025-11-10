# Multi-Agent Metric Trigger Harness

This guide covers the multi-agent LangChain harness that intentionally emits
problematic content so evaluation metrics (toxicity, bias, hallucination,
relevance) fire predictably.

## 1. Prerequisites
- macOS or Linux shell with `bash`
- Python 3.11+ and [`uv`](https://github.com/astral-sh/uv)
- Access to Splunk Artifactory via `okta-artifactory-login`
- Valid OpenAI and Circuit credentials (kept outside version control)

## 2. Environment Setup
Run the steps below from
`instrumentation-genai/opentelemetry-instrumentation-langchain/examples/manual`:

```bash
uv venv
source .venv/bin/activate
okta-artifactory-login -t pypi
uv pip install pip
pip install -e ../../../../util/opentelemetry-util-genai --no-deps
pip install -e ../../../../util/opentelemetry-util-genai-emitters-splunk --no-deps
pip install -e ../../../../util/opentelemetry-util-genai-evals --no-deps
pip install -e ../../../../util/opentelemetry-util-genai-evals-deepeval
pip install -e ../../../../instrumentation-genai/opentelemetry-instrumentation-langchain
uv pip install -r requirements.txt
```

### Secrets
Copy `.env.example` if present or create `.env` manually. Populate:
```
OPENAI_API_KEY=...
OPENAI_MODEL_NAME=gpt-4o-mini
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
CLIENT_ID=...
CLIENT_SECRET=...
APP_KEY=...
```
Keep `.env` untracked (`.gitignore` already excludes it).

## 3. Running a Single Scenario
```bash
source .venv/bin/activate
TEST_MODE=single python multi-agent-openai-metrics-trigger.py
```

- Default rotation picks one scenario based on the interval cadence.
- Override with `SCENARIO_INDEX=0` (0-based) or force rotation speed using
  `SCENARIO_ROTATION_SECONDS=900`.
- Model temperature is locked at `0.0` and `random` sources are seeded so span
  layout stays deterministic.

## 4. Running All Scenarios
```bash
TEST_MODE=all python multi-agent-openai-metrics-trigger.py
```
Expect pauses between scenarios and a 120 second flush delay for telemetry.

## 5. Continuous Runner
`run_agent_script.sh` loops forever with a configurable interval:
```bash
RUN_INTERVAL_SECONDS=3600 ./run_agent_script.sh
```
The script sources `.env`, reuses `.venv`, and announces the next run time. Use
`Ctrl+C` to stop.

## 6. Docker Preview (Alpha)
The optional container build mirrors the manual workflow using editable
installs. Log in to Artifactory beforehand so private packages resolve.

```bash
docker build \
  -f deploy/Dockerfile.alpha \
  -t metrics-trigger-alpha .

docker run --rm \
  --env-file /secure/path/manual.env \
  metrics-trigger-alpha
```

Update the env file location as needed and mount certificates or proxies if
required by your network.

## 7. Telemetry Checklist
- Confirm spans appear with `workflow.type=metrics-trigger-test`
- Metrics for token usage and evaluation scores land in Splunk/observability
- Logs show any agent runtime errors for failed runs

## 8. Troubleshooting
- **Missing Pip Credentials**: rerun `okta-artifactory-login -t pypi` and rebuild
  the virtualenv.
- **OpenAI Auth Issues**: ensure `.env` exists and `export $(grep ...)` executes
  cleanly.
- **Non-Deterministic Spans**: verify no extra randomness is introduced and that
  `RUN_INTERVAL_SECONDS` remains in sync with rotation (default 1800).
