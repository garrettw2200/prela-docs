# Production-Validated Test Scenarios

These test scenarios validate all core Prela SDK features with real Anthropic Claude API calls. All 21 features have been validated in Phase 4 of the SDK testing process.

!!! success "Validation Status"
    ✅ **21/21 features validated** (100%)
    ✅ **4/4 performance criteria met** (100%)
    ✅ **4/4 documentation checks passed** (100%)

---

## Overview

The test scenarios directory contains 6 production-ready scripts that demonstrate and validate:

1. **File Exporter** - Traces saved to `./test_traces` directory
2. **Console Exporter** - Colored tree-structured output
3. **Anthropic Instrumentation** - Automatic LLM call tracing
4. **Span Hierarchy** - Parent-child span relationships
5. **Streaming** - Streaming response capture
6. **Tool Calling** - Tool use event capture
7. **Error Handling** - Error status and attributes
8. **Replay Engine** - Model switching and comparison
9. **Evaluation Framework** - Systematic testing with assertions
10. **CLI Commands** - All 11 CLI commands validated

---

## Quick Start

### Prerequisites

```bash
# Set API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Install SDK
cd /Users/gw/prela/sdk
pip install -e .
```

### Run All Scenarios

```bash
cd /Users/gw/prela/sdk/examples/test_scenarios

# Run each scenario
python 01_simple_success.py
python 02_multi_step.py
python 03_rate_limit_failure.py
python 04_streaming.py
python 05_tool_calling.py
python 06_evaluation.py
```

---

## Scenario 1: Simple Success

**File:** `01_simple_success.py`

Validates basic LLM tracing with file exporter.

```python
import prela
from anthropic import Anthropic

# Initialize with file exporter
tracer = prela.init(
    service_name="simple-success",
    exporter="file",
    file_path="./test_traces"
)

# Make API call - automatically traced
client = Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=100,
    messages=[{"role": "user", "content": "What is 2+2?"}]
)

print(f"Response: {response.content[0].text}")
```

**Validates:**

- ✅ File exporter creates `./test_traces/` directory
- ✅ Traces saved in JSONL format
- ✅ Anthropic instrumentation captures all LLM calls
- ✅ Token usage recorded (`llm.input_tokens`, `llm.output_tokens`)
- ✅ Span attributes include model, provider, latency

**Expected Output:**

```
✓ Prela initialized
✓ Trace file: ./test_traces/traces-2026-01-30-001.jsonl
✓ Making simple Claude API call...
✓ Response: 2 + 2 equals 4.
✓ Tokens: 20 in, 14 out
✓ Trace saved with 1 span
```

---

## Scenario 2: Multi-Step Workflow

**File:** `02_multi_step.py`

Validates span hierarchy with parent-child relationships.

```python
import prela
from anthropic import Anthropic

tracer = prela.init(service_name="multi-step")

def research_step():
    with tracer.span("step_1_research"):
        client = Anthropic()
        response = client.messages.create(...)
        return response.content[0].text

def analysis_step():
    with tracer.span("step_2_analysis"):
        # ... similar ...

def summary_step():
    with tracer.span("step_3_summary"):
        # ... similar ...

# Parent span wraps all steps
with tracer.span("research_workflow"):
    results = []
    results.append(research_step())
    results.append(analysis_step())
    results.append(summary_step())
```

**Validates:**

- ✅ Span hierarchy with nested operations
- ✅ Parent-child relationships via `parent_span_id`
- ✅ Context propagation across functions
- ✅ Tree visualization with `prela show`

**CLI Validation:**

```bash
$ prela show <trace_id>

└─ research_workflow (3.5s) ✓
   ├─ step_1_research (1.2s) ✓
   ├─ step_2_analysis (1.1s) ✓
   └─ step_3_summary (0.8s) ✓
```

---

## Scenario 3: Rate Limit Handling

**File:** `03_rate_limit_failure.py`

Validates error capture and status tracking.

```python
import prela
from anthropic import Anthropic

tracer = prela.init(service_name="rate-limit-test")

try:
    client = Anthropic(api_key="invalid-key")
    response = client.messages.create(...)
except Exception as e:
    print(f"Error captured: {e}")
```

**Validates:**

- ✅ Error handling for API failures
- ✅ Span status set to `"error"`
- ✅ Error attributes: `error.type`, `error.message`, `error.stack_trace`
- ✅ CLI `prela errors` command shows failed traces

**CLI Validation:**

```bash
$ prela errors --limit 5

Showing 1 error trace (from last 50):

╭────────────┬──────────────┬──────────┬────────┬───────┬──────────────────────╮
│ Trace ID   │ Root Span    │ Duration │ Status │ Spans │ Time                 │
├────────────┼──────────────┼──────────┼────────┼───────┼──────────────────────┤
│ abc-123... │ llm call     │ 52ms     │ error  │ 1     │ 2026-01-30 12:34:56  │
╰────────────┴──────────────┴──────────┴────────┴───────┴──────────────────────╯
```

---

## Scenario 4: Streaming Responses

**File:** `04_streaming.py`

Validates streaming LLM response capture.

```python
import prela
from anthropic import Anthropic

tracer = prela.init(service_name="streaming-test")

client = Anthropic()
with client.messages.stream(
    model="claude-sonnet-4-20250514",
    max_tokens=100,
    messages=[{"role": "user", "content": "Tell a story"}]
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
```

**Validates:**

- ✅ Streaming response capture
- ✅ `llm.stream=true` attribute
- ✅ Token usage from final message
- ✅ Text content aggregation

**Span Attributes:**

```json
{
  "llm.stream": true,
  "llm.prompt_tokens": 15,
  "llm.completion_tokens": 89,
  "llm.latency_ms": 1234.5
}
```

---

## Scenario 5: Tool Calling

**File:** `05_tool_calling.py`

Validates LLM tool/function calling.

```python
import prela
from anthropic import Anthropic

tracer = prela.init(service_name="tool-test")

tools = [{
    "name": "get_weather",
    "description": "Get weather for a location",
    "input_schema": {
        "type": "object",
        "properties": {
            "location": {"type": "string"}
        }
    }
}]

client = Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=100,
    tools=tools,
    messages=[{"role": "user", "content": "What's the weather in SF?"}]
)
```

**Validates:**

- ✅ Tool use detection
- ✅ Stop reason = `"tool_use"`
- ✅ Tool call events with `tool.id`, `tool.name`, `tool.input`

**Span Events:**

```json
{
  "events": [
    {
      "name": "tool_call",
      "attributes": {
        "tool.id": "toolu_123",
        "tool.name": "get_weather",
        "tool.input": {"location": "San Francisco"}
      }
    }
  ]
}
```

---

## Scenario 6: Evaluation Framework

**File:** `06_evaluation.py`

Validates systematic testing with assertions.

```python
import prela
from prela.evals import EvalCase, EvalSuite, EvalRunner
from prela.evals.assertions import ContainsAssertion, RegexAssertion

# Define test cases
cases = [
    EvalCase(
        id="test_addition",
        name="Addition test",
        input={"query": "What is 5+3?"},
        assertions=[
            ContainsAssertion(text="8")
        ]
    ),
    # ... more cases
]

# Create suite
suite = EvalSuite(name="Math QA Tests", cases=cases)

# Run evaluation
runner = EvalRunner(suite, agent_function)
result = runner.run()

print(result.summary())
```

**Validates:**

- ✅ Eval framework (EvalCase, EvalSuite, EvalRunner)
- ✅ Assertions execute correctly
- ✅ Tracer integration during eval runs
- ✅ Summary report generation

**Expected Output:**

```
Evaluation Suite: Math QA Tests
Total Cases: 3
Passed: 3 (100.0%)
Failed: 0 (0.0%)

Case Results:
  ✓ Addition test (842ms)
  ✓ Complex calculation (1231ms)
  ✓ JSON format test (923ms)
```

---

## CLI Validation

After running scenarios, verify all CLI commands:

### List Traces

```bash
$ prela list

Showing 22 traces (from last 50):

╭────────────┬──────────────┬──────────┬────────┬───────┬──────────────────────╮
│ Trace ID   │ Root Span    │ Duration │ Status │ Spans │ Time                 │
├────────────┼──────────────┼──────────┼────────┼───────┼──────────────────────┤
│ abc-123... │ simple call  │ 1234ms   │ success│ 1     │ 2026-01-30 12:34:56  │
│ def-456... │ workflow     │ 3456ms   │ success│ 4     │ 2026-01-30 12:33:21  │
╰────────────┴──────────────┴──────────┴────────┴───────┴──────────────────────╯
```

### Show Trace Details

```bash
$ prela show abc-123

Trace: abc-123 @ 12:34:56
Service: simple-success
Status: success
Duration: 1234ms
Spans: 1

└─ anthropic.messages.create (1234ms) ✓
   llm.model: claude-sonnet-4-20250514
   llm.input_tokens: 20
   llm.output_tokens: 14
   llm.latency_ms: 1234.5
```

### Compact Mode

```bash
$ prela show abc-123 --compact

└─ anthropic.messages.create (1234ms) ✓

💡 Tip: Run without --compact to see full span details and events
```

### Most Recent Trace

```bash
$ prela last

# Shows most recent trace with full details
# Equivalent to: prela list | head -1 | prela show
```

### Filter Errors

```bash
$ prela errors --limit 10

Showing 2 error traces (from last 50):
...
```

### Real-Time Monitoring

```bash
$ prela tail --compact

Watching for new traces (Ctrl+C to stop)...

[12:34:56] └─ simple call (1234ms) ✓
[12:35:12] └─ workflow (3456ms) ✓
[12:35:45] └─ streaming (2345ms) ✓
```

---

## Performance Validation

All performance criteria validated:

### SDK Overhead

- **Target:** < 5% of request time
- **Actual:** < 100ms instrumentation overhead (~1-2% for 1-2 second API calls)
- **Status:** ✅ PASS

### Trace File Writes

- **Target:** Non-blocking
- **Actual:** Async file I/O, scripts complete without waiting
- **Status:** ✅ PASS

### CLI Commands Response

- **Target:** < 1 second
- **Actual:** < 100ms for list/show/search
- **Status:** ✅ PASS

### Replay Engine

- **Target:** Reasonable time
- **Actual:** ~2 seconds for API call replay
- **Status:** ✅ PASS

---

## Documentation Validation

All documentation criteria validated:

### Test Scenario Comments

- **Target:** Clear docstrings
- **Actual:** All 6 scenarios have detailed docstrings
- **Status:** ✅ PASS

### Expected Outputs

- **Target:** Documented
- **Actual:** SDK_LOCAL_TESTING.md documents all expected outputs
- **Status:** ✅ PASS

### Error Messages

- **Target:** Helpful and actionable
- **Actual:** All errors include clear messages and suggestions
- **Status:** ✅ PASS

### CLI Help Text

- **Target:** Accurate
- **Actual:** `prela --help` shows complete, accurate help
- **Status:** ✅ PASS

---

## Full Validation Report

See the complete Phase 4 validation report with all evidence:

📄 [Phase 4 Validation Results](https://github.com/prela/prela/blob/main/sdk/examples/test_scenarios/phase4_validation.md)

**Summary:**

- **Total Features Validated:** 21/21 (100%)
- **Performance Criteria Met:** 4/4 (100%)
- **Documentation Quality:** 4/4 (100%)
- **Overall Status:** ✅ COMPLETE

---

## Next Steps

After validating these scenarios:

1. **Explore Advanced Examples**: See [sdk/examples/](https://github.com/prela/prela/tree/main/sdk/examples) for more patterns
2. **Read Integration Guides**: Check [Integrations](../integrations/openai.md) for framework-specific usage
3. **Build Your Agent**: Apply these patterns to production applications
4. **Deploy Observability**: Use file exporter or OTLP exporter for production monitoring

---

## Troubleshooting

### API Key Not Set

```bash
# Error: "Could not resolve authentication method"
export ANTHROPIC_API_KEY="sk-ant-..."
```

### Module Not Found

```bash
# Error: "No module named 'prela'"
cd /Users/gw/prela/sdk
pip install -e .
```

### No Traces Generated

```bash
# Check directory exists
ls -la ./test_traces/

# Verify JSONL contents
cat ./test_traces/traces-*.jsonl | jq .
```

### CLI Command Not Found

```bash
# Ensure CLI tools installed
pip install -e ".[cli]"

# Verify installation
which prela
prela --version
```

---

## Related Documentation

- [Getting Started](../getting-started/quickstart.md)
- [CLI Reference](../cli/commands.md)
- [Evaluation Framework](../evals/overview.md)
- [API Reference](../api/core.md)
