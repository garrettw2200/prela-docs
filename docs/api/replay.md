# Replay API Reference

Complete API documentation for the Prela replay module.

---

## Module: `prela.replay`

Main replay functionality for deterministic re-execution of traces.

### ReplayEngine

Main engine for replaying captured traces.

```python
from prela.replay import ReplayEngine
```

#### Constructor

```python
ReplayEngine(
    trace: Trace,
    max_retries: int = 3,
    retry_initial_delay: float = 1.0,
    retry_max_delay: float = 60.0,
    retry_exponential_base: float = 2.0,
)
```

**Parameters:**

- `trace` (Trace): Loaded trace object from TraceLoader
- `max_retries` (int, optional): Maximum retry attempts for API calls (default: 3)
- `retry_initial_delay` (float, optional): Initial delay before first retry in seconds (default: 1.0)
- `retry_max_delay` (float, optional): Maximum delay between retries in seconds (default: 60.0)
- `retry_exponential_base` (float, optional): Base for exponential backoff (default: 2.0)

**Example:**

```python
from prela.replay.loader import TraceLoader

trace = TraceLoader.from_file("trace.jsonl")

# Default retry configuration
engine = ReplayEngine(trace)

# Custom retry configuration (more aggressive for flaky networks)
engine = ReplayEngine(
    trace,
    max_retries=5,
    retry_initial_delay=2.0,
    retry_max_delay=120.0,
)
```

#### Methods

##### `replay_exact()`

Execute deterministic replay using cached data (no API calls).

```python
def replay_exact() -> ReplayResult
```

**Returns:** `ReplayResult` with replayed spans and metrics

**Example:**

```python
result = engine.replay_exact()
print(f"Duration: {result.total_duration_ms}ms")
print(f"Cost: ${result.total_cost_usd:.4f}")
```

---

##### `replay_with_modifications()`

Execute replay with parameter modifications (makes real API calls for modified spans).

```python
def replay_with_modifications(
    model: str | None = None,
    temperature: float | None = None,
    system_prompt: str | None = None,
    max_tokens: int | None = None,
    mock_tool_responses: dict[str, Any] | None = None,
    mock_retrieval_results: list[dict[str, Any]] | None = None,
    enable_tool_execution: bool = False,
    tool_execution_allowlist: list[str] | None = None,
    tool_execution_blocklist: list[str] | None = None,
    tool_registry: dict[str, Any] | None = None,
    enable_retrieval_execution: bool = False,
    retrieval_client: Any | None = None,
    retrieval_query_override: str | None = None,
    stream: bool = False,
    stream_callback: Callable[[str], None] | None = None,
) -> ReplayResult
```

**LLM Parameters:**

- `model` (str, optional): Override LLM model name
  - Examples: `"gpt-4o"`, `"claude-sonnet-4-20250514"`
- `temperature` (float, optional): Override temperature (0.0-1.0)
- `system_prompt` (str, optional): Override system instructions
- `max_tokens` (int, optional): Override max output tokens
- `stream` (bool, optional): Enable streaming responses (default: False)
- `stream_callback` (callable, optional): Callback for streaming chunks: `(chunk: str) -> None`

**Tool Parameters:**

- `mock_tool_responses` (dict, optional): Mock tool outputs (highest priority)
  - Format: `{tool_name: {output_data}}`
- `enable_tool_execution` (bool, optional): Re-execute tools instead of using cached data (default: False)
- `tool_execution_allowlist` (list[str], optional): Only execute tools in this list
  - If provided, tools not in list will fail with error
- `tool_execution_blocklist` (list[str], optional): Never execute tools in this list
  - Blocklist takes precedence over allowlist
- `tool_registry` (dict, optional): Map of tool names to callable functions
  - Required when `enable_tool_execution=True`
  - Format: `{tool_name: callable}`

**Retrieval Parameters:**

- `mock_retrieval_results` (list[dict], optional): Mock retrieval documents (highest priority)
  - Format: `[{"text": "...", "score": 0.9}, ...]`
- `enable_retrieval_execution` (bool, optional): Re-query vector database (default: False)
- `retrieval_client` (Any, optional): Vector database client (ChromaDB, Pinecone, Qdrant, Weaviate)
  - Required when `enable_retrieval_execution=True`
- `retrieval_query_override` (str, optional): Override query for all retrieval spans

**Returns:** `ReplayResult` with modified execution

**Priority System:**

For tool and retrieval spans, Prela uses a 3-tier priority system:

1. **Mock responses** (highest priority) - Always used if provided
2. **Real execution** - Used if enabled and no mocks provided
3. **Cached data** (default) - Original captured data

This ensures predictable behavior and prevents accidental tool execution.

**Basic Example:**

```python
# LLM parameter modification
result = engine.replay_with_modifications(
    model="gpt-4o",
    temperature=0.7,
    system_prompt="Be concise and direct"
)
```

**Tool Re-execution Example:**

```python
# Define tool registry
def my_calculator(input_data):
    return {"result": input_data["a"] + input_data["b"]}

tool_registry = {"calculator": my_calculator}

# Re-execute tools with allowlist
result = engine.replay_with_modifications(
    enable_tool_execution=True,
    tool_execution_allowlist=["calculator"],  # Only allow calculator
    tool_registry=tool_registry,
)
```

**Retrieval Re-execution Example:**

```python
import chromadb

# Setup ChromaDB client
client = chromadb.Client()

# Re-query vector database
result = engine.replay_with_modifications(
    enable_retrieval_execution=True,
    retrieval_client=client,
    retrieval_query_override="Updated search query",  # Optional
)
```

---

### compare_replays()

Compare two replay results and generate difference report.

```python
from prela.replay import compare_replays
```

```python
def compare_replays(
    original: ReplayResult,
    modified: ReplayResult
) -> ReplayComparison
```

**Parameters:**

- `original` (ReplayResult): Baseline replay result
- `modified` (ReplayResult): Modified replay result

**Returns:** `ReplayComparison` with differences and summary

**Example:**

```python
original = engine.replay_exact()
modified = engine.replay_with_modifications(model="gpt-4o")

comparison = compare_replays(original, modified)
print(comparison.generate_summary())
```

---

## Module: `prela.replay.loader`

Load traces from various formats.

### TraceLoader

Utility for loading traces from files or data structures.

```python
from prela.replay.loader import TraceLoader
```

#### Class Methods

##### `from_file()`

Load trace from JSON or JSONL file.

```python
@classmethod
def from_file(cls, file_path: str) -> Trace
```

**Parameters:**

- `file_path` (str): Path to trace file (.json or .jsonl)

**Returns:** `Trace` object

**Example:**

```python
trace = TraceLoader.from_file("traces.jsonl")
```

---

##### `from_dict()`

Load trace from dictionary.

```python
@classmethod
def from_dict(cls, data: dict) -> Trace
```

**Parameters:**

- `data` (dict): Trace dictionary with `trace_id` and `spans` keys

**Returns:** `Trace` object

**Example:**

```python
trace_dict = {
    "trace_id": "abc-123",
    "spans": [...]
}
trace = TraceLoader.from_dict(trace_dict)
```

---

##### `from_spans()`

Load trace from list of Span objects.

```python
@classmethod
def from_spans(cls, spans: list[Span]) -> Trace
```

**Parameters:**

- `spans` (list[Span]): List of Span objects

**Returns:** `Trace` object

**Example:**

```python
from prela.core import Span

spans = [span1, span2, span3]
trace = TraceLoader.from_spans(spans)
```

---

### Trace

Represents a loaded trace with span tree structure.

#### Properties

```python
@property
def trace_id(self) -> str
    """Trace ID (from first span)."""

@property
def spans(self) -> list[Span]
    """All spans in trace."""

@property
def root_spans(self) -> list[Span]
    """Root spans (no parent)."""
```

#### Methods

##### `walk_depth_first()`

Traverse spans in depth-first order.

```python
def walk_depth_first(self) -> list[Span]
```

**Returns:** Ordered list of spans

**Example:**

```python
trace = TraceLoader.from_file("trace.jsonl")
for span in trace.walk_depth_first():
    print(f"{span.name} ({span.span_type})")
```

---

## Data Classes

### ReplayResult

Result of a replay execution.

```python
from prela.replay import ReplayResult
```

#### Attributes

```python
@dataclass
class ReplayResult:
    trace_id: str
    """Trace ID."""

    spans: list[ReplayedSpan]
    """Replayed spans with outputs."""

    total_duration_ms: float
    """Total execution duration in milliseconds."""

    total_tokens: int
    """Total token usage across all spans."""

    total_cost_usd: float
    """Total estimated cost in USD."""

    metadata: dict[str, Any]
    """Additional metadata."""
```

---

### ReplayedSpan

Individual span replay result.

```python
from prela.replay import ReplayedSpan
```

#### Attributes

```python
@dataclass
class ReplayedSpan:
    span_id: str
    """Span ID."""

    name: str
    """Span name."""

    span_type: str
    """Span type (llm, tool, retrieval, etc)."""

    output: str
    """Span output (response, result, etc)."""

    duration_ms: float
    """Span duration in milliseconds."""

    tokens: int | None
    """Token usage (LLM spans only)."""

    cost_usd: float | None
    """Estimated cost in USD (LLM spans only)."""

    attributes: dict[str, Any]
    """Span attributes."""

    error: str | None
    """Error message if span failed."""

    retry_count: int
    """Number of retry attempts (0 if no retries)."""
```

**Example: Checking Retry Counts**

```python
result = engine.replay_with_modifications(model="gpt-4o")

# Check which spans required retries
for span in result.spans:
    if span.retry_count > 0:
        print(f"{span.name} required {span.retry_count} retries")
```

---

### ReplayComparison

Comparison between two replay results.

```python
from prela.replay import ReplayComparison
```

#### Attributes

```python
@dataclass
class ReplayComparison:
    original: ReplayResult
    """Original replay result."""

    modified: ReplayResult
    """Modified replay result."""

    differences: list[SpanDifference]
    """List of differences found."""
```

#### Methods

##### `generate_summary()`

Generate human-readable comparison summary.

```python
def generate_summary() -> str
```

**Returns:** Formatted summary string

**Example:**

```python
comparison = compare_replays(original, modified)
print(comparison.generate_summary())
```

---

### SpanDifference

Represents a difference between two span executions.

```python
from prela.replay import SpanDifference
```

#### Attributes

```python
@dataclass
class SpanDifference:
    span_id: str
    """Span ID."""

    span_name: str
    """Span name."""

    field: str
    """Field that changed (output, tokens, cost, etc)."""

    original_value: Any
    """Original value."""

    new_value: Any
    """New value."""

    semantic_similarity: float | None
    """Semantic similarity score (0.0-1.0) for text outputs."""
```

---

## Module: `prela.replay.comparison`

Compare replay results with semantic analysis.

### ReplayComparator

Comparison engine with semantic similarity.

```python
from prela.replay.comparison import ReplayComparator
```

#### Constructor

```python
ReplayComparator(use_semantic_similarity: bool = True)
```

**Parameters:**

- `use_semantic_similarity` (bool): Enable semantic text comparison
  - Requires `sentence-transformers` package
  - Gracefully degrades if not installed

#### Methods

##### `compare()`

Compare two replay results.

```python
def compare(
    original: ReplayResult,
    modified: ReplayResult
) -> ReplayComparison
```

**Parameters:**

- `original` (ReplayResult): Baseline result
- `modified` (ReplayResult): Modified result

**Returns:** `ReplayComparison` object

**Example:**

```python
comparator = ReplayComparator(use_semantic_similarity=True)
comparison = comparator.compare(original, modified)
```

---

## CLI Commands

### `prela replay`

Replay traces from command line.

```bash
prela replay TRACE_FILE [OPTIONS]
```

#### Arguments

- `TRACE_FILE`: Path to trace file (.json or .jsonl)

#### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--model TEXT` | Override LLM model | None |
| `--temperature FLOAT` | Set temperature (0.0-1.0) | None |
| `--system-prompt TEXT` | Override system prompt | None |
| `--max-tokens INT` | Set max output tokens | None |
| `--compare` | Compare with original | False |
| `--output PATH` | Save results to file | None |

#### Examples

```bash
# Exact replay
prela replay trace.json

# Modified replay
prela replay trace.json --model gpt-4o

# With comparison
prela replay trace.json --model gpt-4o --compare

# Save results
prela replay trace.json --model gpt-4o --output result.json

# Multiple parameters
prela replay trace.json \
  --model claude-sonnet-4 \
  --temperature 0.7 \
  --compare
```

---

## Environment Variables

### `PRELA_CAPTURE_FOR_REPLAY`

Enable replay capture globally.

```bash
export PRELA_CAPTURE_FOR_REPLAY=true
```

Equivalent to:

```python
prela.init(capture_for_replay=True)
```

---

## Type Hints

All replay APIs include full type hints for IDE support:

```python
from typing import Any

from prela.replay import ReplayEngine, ReplayResult, compare_replays
from prela.replay.loader import Trace, TraceLoader

def analyze_trace(file_path: str, new_model: str) -> dict[str, Any]:
    """Analyze trace with new model."""
    trace: Trace = TraceLoader.from_file(file_path)
    engine: ReplayEngine = ReplayEngine(trace)

    original: ReplayResult = engine.replay_exact()
    modified: ReplayResult = engine.replay_with_modifications(model=new_model)

    comparison = compare_replays(original, modified)

    return {
        "original_cost": original.total_cost_usd,
        "modified_cost": modified.total_cost_usd,
        "summary": comparison.generate_summary(),
    }
```

---

## Error Handling

### Common Exceptions

#### `FileNotFoundError`

Raised when trace file doesn't exist:

```python
try:
    trace = TraceLoader.from_file("missing.jsonl")
except FileNotFoundError:
    print("Trace file not found")
```

#### `ValueError`

Raised when trace data is invalid:

```python
try:
    trace = TraceLoader.from_dict({"invalid": "data"})
except ValueError as e:
    print(f"Invalid trace: {e}")
```

#### `APIError`

Raised when API calls fail during modified replay:

```python
try:
    result = engine.replay_with_modifications(model="gpt-4o")
except Exception as e:
    print(f"API error: {e}")
```

---

## Performance Considerations

### Memory Usage

Replay engines store:

- Original trace spans: O(n)
- Replay results: O(n)
- Comparison differences: O(n)

**Recommendation:** For large traces (>10,000 spans), process in batches.

### Semantic Similarity

Computing semantic similarity requires:

- Sentence-transformers model: ~90MB download (first use)
- Embedding computation: ~10-50ms per span

**Recommendation:** Disable for quick comparisons without quality analysis:

```python
comparator = ReplayComparator(use_semantic_similarity=False)
```

---

## Next Steps

- **[Replay Concepts](../concepts/replay.md)**: Understand replay fundamentals
- **[Replay Examples](../examples/replay.md)**: Practical code examples
- **[CLI Reference](../cli/commands.md#replay)**: Command-line usage
