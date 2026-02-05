# Assertions

Assertions validate agent outputs against expected behavior. Prela provides 10 built-in assertion types across three categories.

## Structural Assertions

### ContainsAssertion

Checks if output contains specific text.

```python
from prela.evals.assertions import ContainsAssertion

assertion = ContainsAssertion(text="success", case_sensitive=False)
result = assertion.evaluate(output="Operation completed successfully!")
print(result.passed)  # True
```

**Configuration:**
```python
{
    "type": "contains",
    "value": "expected text",
    "case_sensitive": False  # Optional, default: False
}
```

### NotContainsAssertion

Checks if output does NOT contain specific text.

```python
from prela.evals.assertions import NotContainsAssertion

assertion = NotContainsAssertion(text="error", case_sensitive=True)
result = assertion.evaluate(output="All tests passed!")
print(result.passed)  # True
```

**Configuration:**
```python
{
    "type": "not_contains",
    "value": "forbidden text",
    "case_sensitive": True  # Optional
}
```

### RegexAssertion

Matches output against a regex pattern.

```python
from prela.evals.assertions import RegexAssertion

assertion = RegexAssertion(pattern=r"\\d{3}-\\d{3}-\\d{4}")
result = assertion.evaluate(output="Call me at 555-123-4567")
print(result.passed)  # True
```

**Configuration:**
```python
{
    "type": "regex",
    "pattern": r"\\d{3}-\\d{3}-\\d{4}"
}
```

### LengthAssertion

Validates output length is within bounds.

```python
from prela.evals.assertions import LengthAssertion

assertion = LengthAssertion(min_length=10, max_length=100)
result = assertion.evaluate(output="This is a medium length response.")
print(result.passed)  # True
```

**Configuration:**
```python
{
    "type": "length",
    "min": 10,    # Optional
    "max": 100    # Optional
}
```

### JSONValidAssertion

Validates output is valid JSON.

```python
from prela.evals.assertions import JSONValidAssertion

assertion = JSONValidAssertion()
result = assertion.evaluate(output='{"key": "value"}')
print(result.passed)  # True
```

**Configuration:**
```python
{"type": "json_valid"}
```

### LatencyAssertion

Validates response time is under threshold.

```python
from prela.evals.assertions import LatencyAssertion
from prela.core.span import Span, SpanType
from datetime import datetime, timezone, timedelta

assertion = LatencyAssertion(max_ms=5000)

# Create span with timing
span = Span(
    name="test",
    span_type=SpanType.LLM,
    started_at=datetime.now(timezone.utc),
    ended_at=datetime.now(timezone.utc) + timedelta(milliseconds=1234)
)

result = assertion.evaluate(output="", trace=[span])
print(result.passed)  # True (1234ms < 5000ms)
```

**Configuration:**
```python
{
    "type": "latency",
    "max_ms": 5000
}
```

## Tool Assertions

### ToolCalledAssertion

Validates that a specific tool was called.

```python
from prela.evals.assertions import ToolCalledAssertion
from prela.core.span import Span, SpanType

assertion = ToolCalledAssertion(tool_name="search")

# Create span with tool call
span = Span(name="tool.search", span_type=SpanType.TOOL)
span.set_attribute("tool.name", "search")

result = assertion.evaluate(output="", trace=[span])
print(result.passed)  # True
```

**Configuration:**
```python
{
    "type": "tool_called",
    "tool_name": "search"
}
```

### ToolArgsAssertion

Validates tool was called with correct arguments.

```python
from prela.evals.assertions import ToolArgsAssertion

assertion = ToolArgsAssertion(
    tool_name="calculator",
    args={"x": 5, "y": 3}
)

# Create span with tool args
span = Span(name="tool.calculator", span_type=SpanType.TOOL)
span.set_attribute("tool.name", "calculator")
span.set_attribute("tool.input", {"x": 5, "y": 3})

result = assertion.evaluate(output="", trace=[span])
print(result.passed)  # True
```

**Configuration:**
```python
{
    "type": "tool_args",
    "tool_name": "calculator",
    "args": {"x": 5, "y": 3}
}
```

### ToolSequenceAssertion

Validates tools were called in specific order.

```python
from prela.evals.assertions import ToolSequenceAssertion

assertion = ToolSequenceAssertion(sequence=["search", "summarize", "format"])

# Create spans for each tool
spans = [
    Span(name="tool.search", span_type=SpanType.TOOL),
    Span(name="tool.summarize", span_type=SpanType.TOOL),
    Span(name="tool.format", span_type=SpanType.TOOL)
]

for span, tool in zip(spans, ["search", "summarize", "format"]):
    span.set_attribute("tool.name", tool)

result = assertion.evaluate(output="", trace=spans)
print(result.passed)  # True
```

**Configuration:**
```python
{
    "type": "tool_sequence",
    "sequence": ["search", "summarize", "format"]
}
```

## Semantic Assertions

### SemanticSimilarityAssertion

Validates semantic similarity to reference text.

**Requirements:**
```bash
pip install sentence-transformers
```

```python
from prela.evals.assertions import SemanticSimilarityAssertion

assertion = SemanticSimilarityAssertion(
    reference="The capital of France is Paris",
    threshold=0.8
)

result = assertion.evaluate(output="Paris is the capital city of France")
print(result.passed)  # True (similarity > 0.8)
```

**Configuration:**
```python
{
    "type": "semantic_similarity",
    "reference": "Expected meaning",
    "threshold": 0.8,  # 0.0 to 1.0
    "model": "all-MiniLM-L6-v2"  # Optional
}
```

## Using Assertions

### In Test Cases

```python
from prela.evals import EvalCase, EvalInput

case = EvalCase(
    id="test_1",
    input=EvalInput(query="What is 2+2?"),
    assertions=[
        {"type": "contains", "value": "4"},
        {"type": "latency", "max_ms": 3000},
        {"type": "length", "min": 5, "max": 100}
    ]
)
```

### Programmatically

```python
from prela.evals.assertions import ContainsAssertion, LengthAssertion

assertions = [
    ContainsAssertion(text="success"),
    LengthAssertion(min_length=10, max_length=500)
]

for assertion in assertions:
    result = assertion.evaluate(output=agent_output)
    if not result.passed:
        print(f"Failed: {result.message}")
```

### With create_assertion Factory

```python
from prela.evals.runner import create_assertion

# Create from config
config = {"type": "contains", "value": "hello"}
assertion = create_assertion(config)

result = assertion.evaluate(output="Hello, world!")
```

## Best Practices

### 1. Combine Multiple Assertions

```python
assertions = [
    {"type": "contains", "value": "result"},
    {"type": "not_contains", "value": "error"},
    {"type": "json_valid"},
    {"type": "latency", "max_ms": 5000}
]
```

### 2. Use Semantic Similarity for Fuzzy Matching

```python
# Instead of exact match
{"type": "contains", "value": "Paris is the capital of France"}

# Use semantic similarity
{
    "type": "semantic_similarity",
    "threshold": 0.85,
    "reference": "Paris is the capital of France"
}
```

### 3. Validate Tool Usage

```python
# Ensure tool was called
{"type": "tool_called", "tool_name": "search"}

# Ensure correct arguments
{"type": "tool_args", "tool_name": "search", "args": {"query": "expected"}}

# Ensure correct sequence
{"type": "tool_sequence", "sequence": ["retrieve", "process", "respond"]}
```

### 4. Set Realistic Latency Thresholds

```python
# Fast operations
{"type": "latency", "max_ms": 1000}

# LLM calls
{"type": "latency", "max_ms": 10000}

# Complex workflows
{"type": "latency", "max_ms": 30000}
```

## Multi-Agent Assertions

Specialized assertions for testing multi-agent systems (CrewAI, AutoGen, LangGraph, Swarm):

### AgentUsedAssertion

Verify that a specific agent was invoked during execution:

```python
from prela.evals.assertions import AgentUsedAssertion

# Verify agent participated
AgentUsedAssertion(agent_name="Researcher", min_invocations=1)
```

**Use Cases:**
- Verify agent participation in multi-agent workflows
- Ensure critical agents are used
- Test agent selection logic

### TaskCompletedAssertion

Verify that a task completed successfully (CrewAI):

```python
from prela.evals.assertions import TaskCompletedAssertion

# Verify task completion
TaskCompletedAssertion(task_description="Research AI trends")
```

**Use Cases:**
- Verify task completion in CrewAI crews
- Ensure all workflow steps execute
- Test task orchestration

### DelegationOccurredAssertion

Verify agent-to-agent delegation (CrewAI):

```python
from prela.evals.assertions import DelegationOccurredAssertion

# Verify specific delegation
DelegationOccurredAssertion(from_agent="Manager", to_agent="Worker")

# Verify any delegation to agent
DelegationOccurredAssertion(to_agent="Worker")
```

**Use Cases:**
- Test hierarchical crew processes
- Verify delegation logic
- Ensure proper task routing

### HandoffOccurredAssertion

Verify agent handoffs (Swarm):

```python
from prela.evals.assertions import HandoffOccurredAssertion

# Verify specific handoff
HandoffOccurredAssertion(from_agent="Triage", to_agent="Billing")

# Verify any handoff from agent
HandoffOccurredAssertion(from_agent="Triage")
```

**Use Cases:**
- Test Swarm routing logic
- Verify specialist assignment
- Ensure handoff triggers work

### AgentCollaborationAssertion

Verify minimum number of agents participated:

```python
from prela.evals.assertions import AgentCollaborationAssertion

# Require at least 3 agents
AgentCollaborationAssertion(min_agents=3)
```

**Use Cases:**
- Ensure multi-agent collaboration
- Verify sufficient agent participation
- Test collaborative workflows

### ConversationTurnsAssertion

Verify conversation length (AutoGen):

```python
from prela.evals.assertions import ConversationTurnsAssertion

# Verify turn count range
ConversationTurnsAssertion(min_turns=2, max_turns=10)
```

**Use Cases:**
- Test conversation flow
- Verify termination conditions
- Ensure efficient dialogues

### NoCircularDelegationAssertion

Detect circular delegation loops:

```python
from prela.evals.assertions import NoCircularDelegationAssertion

# Verify no circular delegation
NoCircularDelegationAssertion()
```

**Use Cases:**
- Prevent infinite delegation loops
- Verify workflow correctness
- Ensure proper delegation graphs

### Example: Multi-Agent Test

```python
from prela.evals import EvalCase, EvalSuite, EvalRunner
from prela.evals.assertions import (
    AgentUsedAssertion,
    AgentCollaborationAssertion,
    DelegationOccurredAssertion,
    NoCircularDelegationAssertion
)

# Test multi-agent workflow
test_case = EvalCase(
    id="test_research_crew",
    name="Research crew with delegation",
    input={"topic": "AI agents"},
    assertions=[
        # Verify all agents used
        AgentUsedAssertion(agent_name="Manager", min_invocations=1),
        AgentUsedAssertion(agent_name="Researcher", min_invocations=1),
        AgentUsedAssertion(agent_name="Writer", min_invocations=1),

        # Verify collaboration
        AgentCollaborationAssertion(min_agents=3),

        # Verify delegation flow
        DelegationOccurredAssertion(from_agent="Manager", to_agent="Researcher"),
        DelegationOccurredAssertion(from_agent="Manager", to_agent="Writer"),

        # Verify no circular delegation
        NoCircularDelegationAssertion()
    ]
)

suite = EvalSuite(name="Multi-Agent Tests", cases=[test_case])
runner = EvalRunner(suite, my_crew_function)
result = runner.run()
```

For framework-specific examples:
- [CrewAI Integration](../integrations/crewai.md#multi-agent-assertions)
- [AutoGen Integration](../integrations/autogen.md#multi-agent-assertions)
- [LangGraph Integration](../integrations/langgraph.md#multi-agent-assertions)
- [Swarm Integration](../integrations/swarm.md#multi-agent-assertions)

## Next Steps

- See [Writing Tests](writing-tests.md) for test case creation
- Learn [Running Evaluations](running.md)
- Explore [CI Integration](ci-integration.md)
