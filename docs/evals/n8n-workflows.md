# N8N Workflow Evaluation

Prela provides a specialized evaluation framework for systematically testing n8n workflows. This enables automated testing, regression detection, and continuous integration of workflow changes.

## Overview

The n8n evaluation framework allows you to:

- **Test workflows automatically** - Trigger workflows and validate results
- **Assert on node outputs** - Verify specific node data using path notation
- **Check execution metrics** - Validate duration, status, token usage
- **Test AI nodes** - Assert on LLM token budgets and costs
- **Integrate with CI/CD** - Run tests in GitHub Actions, GitLab CI, etc.

**Key Features:**
- Async HTTP-based execution (n8n API)
- Node output validation with dot-notation paths
- Token budget assertions for AI nodes
- Duration and status assertions
- Convenience factory functions for clean test syntax

## Installation

```bash
# Install Prela with evaluation support
pip install prela

# Requires: httpx for async HTTP calls
pip install httpx
```

## Quick Start

### Basic Workflow Test

```python
import asyncio
from prela.evals.n8n import eval_n8n_workflow, N8nEvalCase
from prela.evals.n8n.assertions import node_completed, workflow_completed

async def test_simple_workflow():
    case = N8nEvalCase(
        id="test_basic",
        name="Basic workflow execution",
        trigger_data={"message": "Hello World"},
        node_assertions={
            "Process Data": [node_completed("Process Data")],
        },
        workflow_assertions=[workflow_completed()],
    )

    results = await eval_n8n_workflow(
        workflow_id="workflow-123",
        test_cases=[case],
        n8n_url="http://localhost:5678",
    )

    print(f"Passed: {results['passed']}/{results['total']}")

asyncio.run(test_simple_workflow())
```

## N8nEvalCase

Data structure for defining test cases:

```python
@dataclass
class N8nEvalCase:
    id: str                                # Unique test case ID
    name: str                              # Test case name
    trigger_data: dict                     # Data to trigger workflow
    node_assertions: dict[str, list]       # Per-node assertions {node_name: [assertions]}
    workflow_assertions: list              # Workflow-level assertions
    expected_output: Any | None            # Expected final output (optional)
    tags: list[str]                        # Tags for filtering (optional)
    timeout_seconds: float                 # Execution timeout (default: 30s)
    metadata: dict[str, Any]               # Additional metadata (optional)
```

**Example:**
```python
case = N8nEvalCase(
    id="test_ai_workflow",
    name="AI content generation workflow",
    trigger_data={
        "topic": "AI agents",
        "length": "short"
    },
    node_assertions={
        "OpenAI GPT-4": [
            node_completed("OpenAI GPT-4"),
            node_output("OpenAI GPT-4", "response.content", expected_value="AI agents"),
            tokens_under("OpenAI GPT-4", 1000)
        ],
        "Format Output": [
            node_completed("Format Output"),
            node_output("Format Output", "formatted", expected_value=True)
        ]
    },
    workflow_assertions=[
        workflow_completed(),
        duration_under(15.0)
    ],
    expected_output={"status": "success"},
    tags=["ai", "content", "production"],
    timeout_seconds=60,
)
```

## Assertions

### N8nNodeCompleted

Verify that a node completed successfully.

**Usage:**
```python
from prela.evals.n8n.assertions import N8nNodeCompleted, node_completed

# Class instantiation
assertion = N8nNodeCompleted(node_name="Data Processor")

# Convenience function
assertion = node_completed("Data Processor")
```

**Checks:**
- Node exists in execution
- Node status is "success"

---

### N8nNodeOutput

Assert on node outputs using dot-notation paths.

**Usage:**
```python
from prela.evals.n8n.assertions import N8nNodeOutput, node_output

# Simple path
assertion = node_output("API Call", "response.status", 200)

# Nested path
assertion = node_output("API Call", "response.data.user.id", "user-123")

# Array index
assertion = node_output("Process Items", "items.0.name", "first-item")
```

**Path Notation:**
- `response.status` - Navigate nested objects with dots
- `items.0.name` - Access array elements with numeric indices
- `data.user.id` - Multiple levels of nesting supported

**Example:**
```python
node_output("HTTP Request", "response.status", 200)
node_output("Transform", "output.count", 42)
node_output("Parse JSON", "data.items.0.id", "item-1")
```

---

### N8nWorkflowDuration

Assert that workflow completed within a time limit.

**Usage:**
```python
from prela.evals.n8n.assertions import N8nWorkflowDuration, duration_under

# Class instantiation
assertion = N8nWorkflowDuration(max_seconds=10.0)

# Convenience function
assertion = duration_under(10.0)
```

**Checks:**
- Workflow duration_ms <= max_seconds * 1000

---

### N8nAINodeTokens

Assert that AI node token usage is within budget.

**Usage:**
```python
from prela.evals.n8n.assertions import N8nAINodeTokens, tokens_under

# Class instantiation
assertion = N8nAINodeTokens(node_name="GPT-4", max_tokens=1000)

# Convenience function
assertion = tokens_under("GPT-4", 1000)
```

**Checks:**
- Node total_tokens <= max_tokens

**Note:** Works with AI nodes that report token usage (OpenAI, Anthropic, etc.)

---

### N8nWorkflowStatus

Assert that workflow completed with expected status.

**Usage:**
```python
from prela.evals.n8n.assertions import N8nWorkflowStatus, workflow_completed, workflow_status

# Success status (convenience)
assertion = workflow_completed()  # Expects "success"

# Custom status
assertion = workflow_status("error")  # Expects "error"

# Class instantiation
assertion = N8nWorkflowStatus(expected_status="success")
```

**Statuses:**
- `success` - Workflow completed successfully
- `error` - Workflow failed with error
- `crashed` - Workflow crashed unexpectedly
- `running` - Workflow still executing (should not occur after polling)

## Complete Example

### Lead Scoring Workflow Test

```python
import asyncio
from prela.evals.n8n import eval_n8n_workflow, N8nEvalCase
from prela.evals.n8n.assertions import (
    node_completed,
    node_output,
    duration_under,
    tokens_under,
    workflow_completed,
)

async def test_lead_scoring():
    """Test lead scoring workflow with AI classification."""

    # Test Case 1: High-intent lead
    high_intent_case = N8nEvalCase(
        id="test_high_intent",
        name="High-intent lead scoring",
        trigger_data={
            "email": "I want to buy your premium plan immediately",
            "company": "ACME Corp",
            "employees": 500
        },
        node_assertions={
            "AI Classifier": [
                node_completed("AI Classifier"),
                node_output("AI Classifier", "intent", "high_intent"),
                tokens_under("AI Classifier", 500)
            ],
            "Lead Scorer": [
                node_completed("Lead Scorer"),
                node_output("Lead Scorer", "score", 95)
            ],
            "Route Lead": [
                node_completed("Route Lead"),
                node_output("Route Lead", "route", "sales_team")
            ]
        },
        workflow_assertions=[
            workflow_completed(),
            duration_under(15.0)
        ],
        expected_output={
            "intent": "high_intent",
            "score": 95,
            "route": "sales_team"
        },
        tags=["high-priority", "sales"]
    )

    # Test Case 2: Low-intent lead
    low_intent_case = N8nEvalCase(
        id="test_low_intent",
        name="Low-intent lead scoring",
        trigger_data={
            "email": "Just browsing your website",
            "company": "Unknown",
            "employees": None
        },
        node_assertions={
            "AI Classifier": [
                node_completed("AI Classifier"),
                node_output("AI Classifier", "intent", "low_intent"),
            ],
            "Lead Scorer": [
                node_completed("Lead Scorer"),
                node_output("Lead Scorer", "score", 30)
            ],
        },
        workflow_assertions=[
            workflow_completed(),
            duration_under(15.0)
        ],
        tags=["low-priority"]
    )

    # Run all test cases
    results = await eval_n8n_workflow(
        workflow_id="lead-scoring-workflow-123",
        test_cases=[high_intent_case, low_intent_case],
        n8n_url="http://localhost:5678",
        timeout_seconds=120,
    )

    # Print results
    print(f"\nTest Results: {results['passed']}/{results['total']} passed")
    for case_result in results['cases']:
        status = "✓" if case_result['passed'] else "✗"
        print(f"  {status} {case_result['case_name']}")

        # Print failed assertions
        if not case_result['passed']:
            for assertion_result in case_result['assertion_results']:
                if not assertion_result['passed']:
                    print(f"    ✗ {assertion_result['message']}")

asyncio.run(test_lead_scoring())
```

**Output:**
```
Test Results: 2/2 passed
  ✓ High-intent lead scoring
  ✓ Low-intent lead scoring
```

## N8nWorkflowEvalRunner

Low-level async runner for advanced usage:

```python
from prela.evals.n8n import N8nWorkflowEvalRunner, N8nWorkflowEvalConfig, N8nEvalCase

# Configure runner
config = N8nWorkflowEvalConfig(
    workflow_id="workflow-123",
    n8n_url="http://localhost:5678",
    n8n_api_key="n8n-api-key",  # Optional
    timeout_seconds=120,
)

# Create runner
runner = N8nWorkflowEvalRunner(config)

# Run test cases
cases = [case1, case2, case3]
results = await runner.run_suite(cases)

# Access detailed results
for case_result in results['cases']:
    print(f"Case: {case_result['case_name']}")
    print(f"Passed: {case_result['passed']}")
    print(f"Duration: {case_result['duration_ms']}ms")
    print(f"Assertions: {len(case_result['assertion_results'])}")
```

**Configuration:**
```python
@dataclass
class N8nWorkflowEvalConfig:
    workflow_id: str           # n8n workflow ID
    n8n_url: str              # n8n instance URL (e.g., http://localhost:5678)
    n8n_api_key: str | None   # Optional API key for authentication
    timeout_seconds: int      # Maximum execution time (default: 120)
```

## Convenience Function

### eval_n8n_workflow()

High-level function for simple usage:

```python
async def eval_n8n_workflow(
    workflow_id: str,
    test_cases: list[N8nEvalCase],
    n8n_url: str = "http://localhost:5678",
    n8n_api_key: str | None = None,
    timeout_seconds: int = 120,
    tracer: Tracer | None = None,
) -> dict:
    """
    Evaluate n8n workflow with test cases.

    Args:
        workflow_id: n8n workflow ID
        test_cases: List of test cases to run
        n8n_url: n8n instance URL
        n8n_api_key: Optional API key
        timeout_seconds: Maximum execution time
        tracer: Optional Prela tracer for observability

    Returns:
        dict with keys:
        - total: Total test cases
        - passed: Number passed
        - failed: Number failed
        - cases: List of case results
    """
```

**Example:**
```python
results = await eval_n8n_workflow(
    workflow_id="my-workflow-123",
    test_cases=[case1, case2],
    n8n_url=os.environ["N8N_URL"],
    n8n_api_key=os.environ["N8N_API_KEY"],
)
```

## CI/CD Integration

### GitHub Actions

```yaml
name: N8N Workflow Tests

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
          pip install prela httpx

      - name: Run workflow tests
        env:
          N8N_URL: ${{ secrets.N8N_URL }}
          N8N_API_KEY: ${{ secrets.N8N_API_KEY }}
        run: |
          python test_workflows.py
```

### GitLab CI

```yaml
test-workflows:
  image: python:3.11
  script:
    - pip install prela httpx
    - python test_workflows.py
  variables:
    N8N_URL: $N8N_URL
    N8N_API_KEY: $N8N_API_KEY
```

### pytest Integration

```python
import pytest
from prela.evals.n8n import eval_n8n_workflow, N8nEvalCase
from prela.evals.n8n.assertions import node_completed, workflow_completed

@pytest.mark.asyncio
async def test_data_pipeline():
    """Test data processing pipeline workflow."""
    case = N8nEvalCase(
        id="test_pipeline",
        name="Data pipeline",
        trigger_data={"data": [1, 2, 3, 4, 5]},
        node_assertions={
            "Process": [node_completed("Process")],
            "Transform": [node_completed("Transform")],
        },
        workflow_assertions=[workflow_completed()],
    )

    results = await eval_n8n_workflow(
        workflow_id=os.environ["WORKFLOW_ID"],
        test_cases=[case],
        n8n_url=os.environ["N8N_URL"],
    )

    assert results['passed'] == results['total'], \
        f"Test failed: {results['passed']}/{results['total']}"
```

## Best Practices

### 1. Use Descriptive Test Names

```python
# ✓ Good - clear intent
case = N8nEvalCase(
    id="test_high_priority_leads",
    name="High-priority lead routing with AI classification",
    ...
)

# ✗ Bad - vague
case = N8nEvalCase(
    id="test1",
    name="Test",
    ...
)
```

### 2. Assert on Critical Nodes

Focus assertions on business-critical nodes:

```python
node_assertions={
    "AI Classifier": [
        node_completed("AI Classifier"),
        node_output("AI Classifier", "decision", "approve"),
        tokens_under("AI Classifier", 1000),  # Cost control
    ],
    # Skip non-critical nodes
}
```

### 3. Set Realistic Timeouts

Configure timeouts based on workflow complexity:

```python
# Simple workflow
case = N8nEvalCase(..., timeout_seconds=30)

# Complex AI workflow
case = N8nEvalCase(..., timeout_seconds=120)
```

### 4. Use Tags for Organization

```python
case = N8nEvalCase(
    ...,
    tags=["production", "ai", "high-priority"],
)

# Filter tests by tags
production_cases = [c for c in cases if "production" in c.tags]
```

### 5. Validate Expected Outputs

Assert on final workflow outputs:

```python
case = N8nEvalCase(
    ...,
    expected_output={
        "status": "success",
        "score": 95,
        "next_step": "contact_sales"
    },
)
```

## Troubleshooting

### Issue: Workflow Not Triggering

**Symptoms:** eval_n8n_workflow() times out, workflow never starts.

**Solutions:**
1. Verify workflow ID is correct:
   ```python
   # Check n8n UI for workflow ID
   workflow_id="abc-123-def-456"
   ```

2. Verify n8n URL and API key:
   ```python
   n8n_url="http://localhost:5678"  # Include http://
   n8n_api_key="your-api-key"
   ```

3. Check n8n API is accessible:
   ```bash
   curl http://localhost:5678/api/v1/workflows/abc-123
   ```

### Issue: Assertions Failing

**Symptoms:** node_output() assertions fail unexpectedly.

**Solutions:**
1. Verify path notation is correct:
   ```python
   # ✓ Correct
   node_output("API", "response.data.id", "user-123")

   # ✗ Wrong - typo in path
   node_output("API", "response.datta.id", "user-123")
   ```

2. Check node name matches exactly:
   ```python
   # Node names are case-sensitive
   node_output("OpenAI GPT-4", ...)  # Must match n8n node name exactly
   ```

3. Inspect actual node output:
   ```python
   # Print node data for debugging
   print(execution_result["nodes"]["API Call"])
   ```

### Issue: Timeout Errors

**Symptoms:** Tests timing out even though workflow completes in n8n UI.

**Solutions:**
1. Increase timeout:
   ```python
   case = N8nEvalCase(..., timeout_seconds=180)  # 3 minutes
   ```

2. Check for polling issues:
   ```python
   # Runner polls every 1 second
   # Timeout must be > execution time
   ```

### Issue: Token Assertions Failing

**Symptoms:** tokens_under() fails even though token count seems reasonable.

**Solutions:**
1. Verify AI node reports tokens:
   ```python
   # Check if node has token data
   print(node_data.get("total_tokens"))
   ```

2. Check token field name:
   ```python
   # Different nodes may use different field names
   # Prela looks for: total_tokens, token_count, tokens
   ```

## Next Steps

- [N8N Webhook Integration](../integrations/n8n.md) - External workflow tracing
- [N8N Code Nodes](../integrations/n8n-code-nodes.md) - Internal instrumentation
- [Assertions](assertions.md) - Full assertion reference
- [CI Integration](ci-integration.md) - GitHub Actions, GitLab CI setup
- [Writing Tests](writing-tests.md) - Comprehensive test case patterns
