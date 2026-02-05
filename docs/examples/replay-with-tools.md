# Replay with Tool Re-execution

This guide demonstrates how to re-execute tools during replay instead of using cached outputs. This enables testing with fresh data, validating tool implementations, and ensuring agent behavior with current external state.

## Overview

Tool re-execution allows you to:

- **Test with fresh data** - Query live APIs instead of cached responses
- **Validate tool implementations** - Ensure tools still work correctly
- **Detect regressions** - Compare cached vs fresh tool outputs
- **Control execution** - Use allowlists/blocklists for safety

**Priority System:**
1. **Mocks** (highest) - Override with test data
2. **Execution** (medium) - Re-execute tool functions
3. **Cached** (lowest) - Use original trace data

## Basic Tool Re-execution

### Simple Example

```python
from prela.replay import ReplayEngine, TraceLoader

# Define tool function
def calculator(expression: str) -> str:
    """Safe calculator tool."""
    try:
        result = eval(expression, {"__builtins__": {}}, {})
        return str(result)
    except Exception as e:
        return f"Error: {str(e)}"

# Create tool registry
tool_registry = {
    "calculator": calculator,
}

# Load trace
trace = TraceLoader.from_file("trace_with_tools.jsonl")

# Enable tool re-execution
engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution=True,
)

# Replay - tools will be re-executed
result = engine.replay_with_modifications(model="gpt-4o")

print(f"Tool calls: {sum(1 for s in result.spans if s.span_type == 'tool')}")
print(f"Tool errors: {sum(1 for s in result.spans if s.span_type == 'tool' and s.status == 'error')}")
```

### Compare Cached vs Fresh Results

```python
from prela.replay import ReplayEngine, TraceLoader

trace = TraceLoader.from_file("trace_with_tools.jsonl")
tool_registry = {"calculator": calculator}

# Test 1: Use cached tool outputs
engine_cached = ReplayEngine(trace, enable_tool_execution=False)
result_cached = engine_cached.replay_with_modifications(model="gpt-4o")

# Test 2: Re-execute tools
engine_fresh = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution=True,
)
result_fresh = engine_fresh.replay_with_modifications(model="gpt-4o")

# Compare
comparison = engine_fresh.compare_replay(result_cached, result_fresh)
print(f"Output similarity: {comparison.output_similarity:.2%}")
print(f"Tool outputs changed: {comparison.output_similarity < 0.99}")
```

---

## Safety Controls

### Allowlist (Recommended)

Only execute approved tools:

```python
# Define multiple tools
def calculator(expr: str) -> str:
    return str(eval(expr))

def search_api(query: str) -> str:
    import requests
    response = requests.get(f"https://api.example.com/search?q={query}")
    return response.json()

def delete_file(path: str) -> str:
    import os
    os.remove(path)
    return "Deleted"

tool_registry = {
    "calculator": calculator,
    "search_api": search_api,
    "delete_file": delete_file,  # Dangerous!
}

# Only execute safe tools
engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution={
        "allowlist": ["calculator", "search_api"],  # Exclude delete_file
    }
)

result = engine.replay_with_modifications(model="gpt-4o")

# delete_file will use cached output (not executed)
```

### Blocklist

Explicitly block dangerous tools:

```python
engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution={
        "blocklist": ["delete_file", "send_email", "make_payment"],
    }
)

# All tools except blocklist will be executed
```

### Combined Controls

Use both for extra safety:

```python
engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution={
        "allowlist": ["calculator", "search_api", "weather_api"],
        "blocklist": ["delete_file"],  # Extra safety (redundant but explicit)
    }
)
```

---

## External API Tools

### HTTP Request Tool

```python
import requests
from prela.replay import ReplayEngine, TraceLoader

def github_search(query: str, max_results: int = 5) -> str:
    """Search GitHub repositories."""
    response = requests.get(
        "https://api.github.com/search/repositories",
        params={"q": query, "per_page": max_results},
        headers={"Accept": "application/vnd.github.v3+json"},
    )
    response.raise_for_status()

    data = response.json()
    repos = data.get("items", [])

    results = []
    for repo in repos:
        results.append({
            "name": repo["full_name"],
            "stars": repo["stargazers_count"],
            "url": repo["html_url"],
        })

    return str(results)

# Test with live API
tool_registry = {"github_search": github_search}

engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution={"allowlist": ["github_search"]},
)

result = engine.replay_with_modifications(model="gpt-4o")
print("Replayed with fresh GitHub data")
```

### Database Query Tool

```python
import psycopg2
from prela.replay import ReplayEngine, TraceLoader

def query_users(filter: str) -> str:
    """Query user database."""
    conn = psycopg2.connect("dbname=mydb user=postgres")
    cur = conn.cursor()

    # Safe parameterized query
    cur.execute("SELECT id, name, email FROM users WHERE name LIKE %s", (f"%{filter}%",))
    results = cur.fetchall()

    cur.close()
    conn.close()

    return str([{"id": r[0], "name": r[1], "email": r[2]} for r in results])

# Test with current database state
tool_registry = {"query_users": query_users}

engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution={"allowlist": ["query_users"]},
)

result = engine.replay_with_modifications(model="gpt-4o")
print("Replayed with current database data")
```

---

## Mocking Tools

### Override with Test Data

```python
from prela.replay import ReplayEngine, TraceLoader

trace = TraceLoader.from_file("trace_with_api_tools.jsonl")

# Mock API responses for testing
tool_mocks = {
    "github_search": '[{"name": "test/repo", "stars": 100}]',
    "weather_api": '{"temp": 72, "condition": "sunny"}',
}

engine = ReplayEngine(
    trace,
    tool_mocks=tool_mocks,  # Mocks override execution
)

result = engine.replay_with_modifications(model="gpt-4o")
print("Replayed with mocked tool outputs")
```

### Selective Mocking

```python
# Define real tool functions
def calculator(expr: str) -> str:
    return str(eval(expr))

def expensive_api(query: str) -> str:
    import requests
    response = requests.get(f"https://expensive-api.com/search?q={query}")
    return response.json()

tool_registry = {
    "calculator": calculator,
    "expensive_api": expensive_api,
}

# Mock only the expensive API
tool_mocks = {
    "expensive_api": '{"results": ["mocked result 1", "mocked result 2"]}',
}

engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution={"allowlist": ["calculator"]},
    tool_mocks=tool_mocks,  # Mock expensive_api
)

# calculator: Re-executed
# expensive_api: Mocked (not executed)
result = engine.replay_with_modifications(model="gpt-4o")
```

---

## Error Handling

### Capture Tool Failures

```python
def risky_tool(input: str) -> str:
    """Tool that might fail."""
    if input == "error":
        raise ValueError("Invalid input")
    if input == "timeout":
        import time
        time.sleep(100)  # Timeout
    return f"Processed: {input}"

tool_registry = {"risky_tool": risky_tool}

engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution=True,
)

result = engine.replay_with_modifications(model="gpt-4o")

# Check for tool errors
for span in result.spans:
    if span.span_type == "tool" and span.status == "error":
        print(f"Tool {span.name} failed:")
        print(f"  Error type: {span.attributes.get('error.type')}")
        print(f"  Error message: {span.attributes.get('error.message')}")
```

### Fallback to Cached on Error

```python
def flaky_api(query: str) -> str:
    """API that sometimes fails."""
    import random
    if random.random() < 0.3:  # 30% failure rate
        raise Exception("API unavailable")
    return fetch_real_data(query)

tool_registry = {"flaky_api": flaky_api}

engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution=True,
)

result = engine.replay_with_modifications(model="gpt-4o")

# If tool fails, cached output is used automatically
# Span status will show ERROR, but replay continues
```

---

## Integration Testing

### Test Agent with Live External Systems

```python
from prela.replay import ReplayEngine, TraceLoader
import os

# Define tools for real services
def slack_send_message(channel: str, message: str) -> str:
    """Send Slack message."""
    import requests
    response = requests.post(
        "https://slack.com/api/chat.postMessage",
        headers={"Authorization": f"Bearer {os.environ['SLACK_TOKEN']}"},
        json={"channel": channel, "text": message},
    )
    return response.json()

def github_create_issue(repo: str, title: str, body: str) -> str:
    """Create GitHub issue."""
    import requests
    response = requests.post(
        f"https://api.github.com/repos/{repo}/issues",
        headers={"Authorization": f"token {os.environ['GITHUB_TOKEN']}"},
        json={"title": title, "body": body},
    )
    return response.json()

tool_registry = {
    "slack_send_message": slack_send_message,
    "github_create_issue": github_create_issue,
}

# Run integration test
engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution={
        "allowlist": ["slack_send_message"],  # Only test Slack
    }
)

result = engine.replay_with_modifications(model="gpt-4o")
print("Integration test with live Slack API completed")
```

---

## Tool Consistency Testing

### Detect Tool Behavior Changes

```python
from prela.replay import ReplayEngine, TraceLoader

trace = TraceLoader.from_file("baseline_trace.jsonl")

# Test current tool implementation
def calculator_v2(expr: str) -> str:
    """Updated calculator with better error handling."""
    try:
        # New safety checks
        if any(x in expr for x in ["__", "import", "exec", "eval"]):
            return "Error: Forbidden operation"
        result = eval(expr, {"__builtins__": {}}, {})
        return str(result)
    except Exception as e:
        return f"Error: {str(e)}"

tool_registry = {"calculator": calculator_v2}

# Test 1: Cached outputs (baseline)
result_baseline = ReplayEngine(trace).replay_with_modifications(model="gpt-4")

# Test 2: Re-execute with new implementation
result_current = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution=True,
).replay_with_modifications(model="gpt-4")

# Compare
comparison = ReplayEngine(trace).compare_replay(result_baseline, result_current)

if comparison.output_similarity < 0.95:
    print("⚠️  Warning: Tool behavior changed significantly")
    print(f"Similarity: {comparison.output_similarity:.2%}")
else:
    print("✓ Tool behavior consistent")
```

---

## Regression Testing

### Automated Tool Tests

```python
import pytest
from prela.replay import ReplayEngine, TraceLoader

@pytest.mark.parametrize("tool_name,tool_fn", [
    ("calculator", calculator),
    ("weather_api", weather_api),
    ("search_api", search_api),
])
def test_tool_consistency(tool_name, tool_fn):
    """Test that tool implementations produce consistent results."""
    trace = TraceLoader.from_file(f"baselines/{tool_name}_trace.jsonl")

    # Baseline: Use cached outputs
    engine_baseline = ReplayEngine(trace)
    result_baseline = engine_baseline.replay_with_modifications(
        model="gpt-4",
        temperature=0.0,
    )

    # Current: Re-execute tool
    engine_current = ReplayEngine(
        trace,
        tool_registry={tool_name: tool_fn},
        enable_tool_execution={"allowlist": [tool_name]},
    )
    result_current = engine_current.replay_with_modifications(
        model="gpt-4",
        temperature=0.0,
    )

    # Compare
    comparison = engine_baseline.compare_replay(result_baseline, result_current)

    assert comparison.output_similarity >= 0.90, \
        f"Tool {tool_name} behavior changed: {comparison.output_similarity:.2%}"
```

### CI/CD Integration

```yaml
# .github/workflows/tool-tests.yml
name: Tool Consistency Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install prela pytest

      - name: Run tool tests
        run: |
          pytest tests/test_tool_consistency.py -v

      - name: Check for regressions
        run: |
          python scripts/check_tool_regression.py
```

---

## Best Practices

### 1. Use Allowlists for Production

Always specify which tools are safe:

```python
# ✓ Good - explicit allowlist
engine = ReplayEngine(
    trace,
    tool_registry=all_tools,
    enable_tool_execution={"allowlist": ["safe_tool_1", "safe_tool_2"]},
)

# ✗ Bad - enables all tools
engine = ReplayEngine(
    trace,
    tool_registry=all_tools,
    enable_tool_execution=True,
)
```

### 2. Mock Expensive Operations

Use mocks for costly API calls:

```python
# Development/testing: Mock expensive APIs
tool_mocks = {
    "gpt4_call": '{"response": "mocked"}',
    "image_generation": '{"url": "https://example.com/mock.png"}',
}

engine = ReplayEngine(trace, tool_mocks=tool_mocks)
```

### 3. Test Tool Isolation

Test tools independently:

```python
# Test one tool at a time
for tool_name in ["tool1", "tool2", "tool3"]:
    engine = ReplayEngine(
        trace,
        tool_registry={tool_name: tools[tool_name]},
        enable_tool_execution={"allowlist": [tool_name]},
    )
    result = engine.replay_with_modifications(model="gpt-4")
    print(f"{tool_name}: {result.status}")
```

### 4. Version Control Tool Implementations

```python
# Store tool versions in trace metadata
import inspect

tool_metadata = {
    "calculator_version": "2.0",
    "calculator_hash": hashlib.sha256(
        inspect.getsource(calculator).encode()
    ).hexdigest()[:8],
}

# Include in trace for future reference
```

### 5. Monitor Tool Execution

```python
result = engine.replay_with_modifications(model="gpt-4o")

# Analyze tool usage
tool_spans = [s for s in result.spans if s.span_type == "tool"]
for span in tool_spans:
    print(f"Tool: {span.name}")
    print(f"  Duration: {span.duration_ms:.0f}ms")
    print(f"  Status: {span.status}")
    print(f"  Executed: {span.attributes.get('executed', False)}")
```

---

## Troubleshooting

### Issue: Tools Not Executing

**Symptoms:** Tools use cached outputs despite enable_tool_execution=True.

**Solutions:**
1. Verify tool is in registry:
   ```python
   print(tool_registry.keys())  # Check tool name
   ```

2. Check allowlist/blocklist:
   ```python
   enable_tool_execution={"allowlist": ["exact_tool_name"]}  # Must match
   ```

3. Ensure tool signature is correct:
   ```python
   def my_tool(input: str) -> str:  # Must accept str, return str
       return result
   ```

### Issue: Tool Errors Not Captured

**Symptoms:** Tool failures crash replay instead of being captured.

**Solutions:**
1. Tool errors are automatically captured - verify span status:
   ```python
   for span in result.spans:
       if span.span_type == "tool":
           print(f"{span.name}: {span.status}")  # Should show ERROR
   ```

2. Check error attributes:
   ```python
   print(span.attributes.get("error.type"))
   print(span.attributes.get("error.message"))
   ```

### Issue: Mocks Not Working

**Symptoms:** Tool executes instead of using mock.

**Solutions:**
1. Verify mock key matches tool name:
   ```python
   tool_mocks = {"exact_tool_name": "mocked output"}  # Must match
   ```

2. Mocks have highest priority - they override execution:
   ```python
   # This should use mock, not execute
   engine = ReplayEngine(
       trace,
       tool_registry={"tool": tool_fn},
       enable_tool_execution=True,
       tool_mocks={"tool": "mock"},  # Mock wins
   )
   ```

---

## Next Steps

- [Replay Advanced Features](../concepts/replay-advanced.md) - API retry, semantic fallback
- [Replay Multi-Agent Examples](replay-multi-agent.md) - Replay with CrewAI, AutoGen, LangGraph, Swarm
- [Basic Replay](replay.md) - Core replay concepts
- [CLI Replay Commands](../cli/commands.md) - Command-line replay interface
