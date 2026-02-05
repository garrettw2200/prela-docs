# Writing Tests

This guide shows how to write effective test cases for your AI agents using Prela's evaluation framework.

## Basic Test Case

```python
from prela.evals import EvalCase, EvalInput, EvalExpected

case = EvalCase(
    id="test_simple_qa",
    name="Simple QA Test",
    input=EvalInput(query="What is the capital of France?"),
    expected=EvalExpected(contains=["Paris"])
)
```

## Test Case Structure

### Required Fields

- **id**: Unique identifier
- **name**: Human-readable name
- **input**: Input data for the agent

### Optional Fields

- **expected**: Expected output patterns
- **assertions**: Validation rules
- **tags**: Categorization labels
- **timeout_seconds**: Maximum execution time
- **description**: Detailed test description

## Input Formats

### Simple Query

```python
input = EvalInput(query="What is Python?")
```

### With Context

```python
input = EvalInput(
    query="Summarize this document",
    context={
        "document": "Long text here...",
        "source": "report.pdf"
    }
)
```

### With Messages (Chat)

```python
input = EvalInput(
    messages=[
        {"role": "system", "content": "You are a helpful assistant"},
        {"role": "user", "content": "Hello!"}
    ]
)
```

### Custom Fields

```python
input = EvalInput(
    query="Process this",
    custom_field="value",
    another_field=123
)
```

## Expected Outputs

### Contains Text

```python
expected = EvalExpected(contains=["success", "completed"])
```

### Does Not Contain

```python
expected = EvalExpected(not_contains=["error", "failed"])
```

### Exact Output

```python
expected = EvalExpected(output="The answer is 42")
```

### Combined

```python
expected = EvalExpected(
    contains=["result"],
    not_contains=["error"],
    output="Exact expected output"
)
```

## Assertions

### Basic Assertions

```python
assertions = [
    {"type": "contains", "value": "success"},
    {"type": "not_contains", "value": "error"},
    {"type": "regex", "pattern": r"\\d+"},
]
```

### Latency Assertions

```python
assertions = [
    {"type": "latency", "max_ms": 5000}
]
```

### JSON Validation

```python
assertions = [
    {"type": "json_valid"},
    {"type": "contains", "value": "result"}
]
```

### Tool Usage

```python
assertions = [
    {"type": "tool_called", "tool_name": "search"},
    {"type": "tool_args", "tool_name": "calculator", "args": {"x": 5}}
]
```

### Semantic Similarity

```python
assertions = [
    {
        "type": "semantic_similarity",
        "threshold": 0.8,
        "reference": "The capital of France is Paris"
    }
]
```

## Complete Examples

### QA Test

```python
from prela.evals import EvalCase, EvalInput, EvalExpected

qa_test = EvalCase(
    id="qa_geography",
    name="Geography Question",
    input=EvalInput(query="What is the capital of Japan?"),
    expected=EvalExpected(
        contains=["Tokyo"],
        not_contains=["error", "don't know"]
    ),
    assertions=[
        {"type": "latency", "max_ms": 3000},
        {"type": "length", "min": 5, "max": 200}
    ],
    tags=["qa", "geography"],
    timeout_seconds=10.0
)
```

### RAG Test

```python
rag_test = EvalCase(
    id="rag_summarization",
    name="Document Summarization",
    input=EvalInput(
        query="Summarize the key findings",
        context={
            "documents": [
                "Doc 1: Revenue increased 15%...",
                "Doc 2: Customer satisfaction at 92%..."
            ]
        }
    ),
    expected=EvalExpected(
        contains=["revenue", "15%", "customer satisfaction"],
        not_contains=["error"]
    ),
    assertions=[
        {"type": "latency", "max_ms": 10000},
        {"type": "length", "min": 50, "max": 500},
        {
            "type": "semantic_similarity",
            "threshold": 0.7,
            "reference": "Revenue grew 15% and customer satisfaction is high"
        }
    ],
    tags=["rag", "summarization"]
)
```

### Tool Use Test

```python
tool_test = EvalCase(
    id="tool_calculator",
    name="Calculator Tool Usage",
    input=EvalInput(query="What is 25 * 4 + 10?"),
    expected=EvalExpected(contains=["110"]),
    assertions=[
        {"type": "tool_called", "tool_name": "calculator"},
        {"type": "tool_args", "tool_name": "calculator", "args": {"expression": "25 * 4 + 10"}},
        {"type": "contains", "value": "110"}
    ],
    tags=["tools", "math"]
)
```

## YAML Format

### Single Test

```yaml
# test.yaml
id: test_greeting
name: Greeting Test
input:
  query: "Say hello"
expected:
  contains: ["hello", "hi"]
  not_contains: ["error"]
tags: ["greeting", "basic"]
timeout_seconds: 5.0
```

### Multiple Tests

```yaml
# suite.yaml
name: My Test Suite
cases:
  - id: test_1
    name: First Test
    input:
      query: "Question 1"
    expected:
      contains: ["answer"]

  - id: test_2
    name: Second Test
    input:
      query: "Question 2"
    expected:
      contains: ["response"]
    assertions:
      - type: latency
        max_ms: 2000
```

### With Setup/Teardown

```yaml
name: Integration Tests
setup: "setup_function"
teardown: "cleanup_function"
default_assertions:
  - type: latency
    max_ms: 5000
cases:
  - id: test_1
    name: Test Case 1
    input:
      query: "Test input"
```

## Best Practices

### 1. Use Descriptive Names

```python
# Good
case = EvalCase(
    id="qa_geography_capitals_europe",
    name="European Capitals Geography Quiz"
)

# Bad
case = EvalCase(id="test1", name="Test")
```

### 2. Add Multiple Assertions

```python
case = EvalCase(
    id="comprehensive_test",
    expected=EvalExpected(contains=["result"]),
    assertions=[
        {"type": "latency", "max_ms": 5000},
        {"type": "json_valid"},
        {"type": "not_contains", "value": "error"}
    ]
)
```

### 3. Use Tags for Organization

```python
case = EvalCase(
    id="test_auth",
    tags=["auth", "critical", "smoke"]
)
```

### 4. Set Realistic Timeouts

```python
# Fast operations
EvalCase(..., timeout_seconds=2.0)

# LLM calls
EvalCase(..., timeout_seconds=30.0)

# Complex workflows
EvalCase(..., timeout_seconds=120.0)
```

### 5. Test Edge Cases

```python
edge_cases = [
    EvalCase(id="empty_input", input=EvalInput(query="")),
    EvalCase(id="very_long_input", input=EvalInput(query="..." * 1000)),
    EvalCase(id="special_chars", input=EvalInput(query="!@#$%^&*()")),
    EvalCase(id="unicode", input=EvalInput(query="你好世界 🌍"))
]
```

## Next Steps

- See [Assertions](assertions.md) for all assertion types
- Learn [Running Evaluations](running.md)
- Explore [CI Integration](ci-integration.md)
