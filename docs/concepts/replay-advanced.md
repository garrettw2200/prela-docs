# Advanced Replay Features

Prela's replay engine includes advanced features for handling transient failures, computing similarity without heavy dependencies, and re-executing tools and retrievals for comprehensive testing.

## Overview

Advanced replay capabilities enable:

- **API Retry Logic** - Automatic recovery from transient API failures
- **Semantic Similarity Fallback** - Text comparison without 500MB dependencies
- **Tool Re-execution** - Execute tools during replay with safety controls
- **Retrieval Re-execution** - Query vector databases for fresh results

These features make replay more robust, flexible, and production-ready.

## API Retry Logic

### Exponential Backoff

The replay engine automatically retries failed API calls using exponential backoff:

```python
from prela.replay import ReplayEngine, TraceLoader

trace = TraceLoader.from_file("trace.json")
engine = ReplayEngine(
    trace,
    max_retries=3,              # Maximum retry attempts (default: 3)
    retry_initial_delay=1.0,    # Initial delay in seconds (default: 1.0)
    retry_max_delay=60.0,       # Maximum delay cap (default: 60.0)
    retry_exponential_base=2.0, # Exponential base (default: 2.0)
)

result = engine.replay_with_modifications(model="gpt-4o")
```

**Retry Pattern:**
- Attempt 0: No delay (initial request)
- Attempt 1: 1.0s delay (2^0 × 1.0)
- Attempt 2: 2.0s delay (2^1 × 1.0)
- Attempt 3: 4.0s delay (2^2 × 1.0)
- Capped at `retry_max_delay` (60s default)

### Retryable Errors

The engine automatically retries these error types:

**HTTP Status Codes:**
- `429` - Rate limit exceeded
- `503` - Service temporarily unavailable
- `502` - Bad gateway

**Exception Types:**
- Timeout errors (connection timeout, read timeout)
- Connection errors (network issues)
- API responses containing "try again" messages

**Non-Retryable Errors:**
- `401` - Authentication errors (fail immediately)
- `403` - Permission errors (fail immediately)
- `400` - Bad request errors (fail immediately)

### Retry Count Tracking

Each replayed span includes retry count information:

```python
result = engine.replay_with_modifications(model="gpt-4o")

for span in result.spans:
    if span.retry_count > 0:
        print(f"{span.name} required {span.retry_count} retries")
        # Example output:
        # openai.chat.completions.create required 2 retries
```

**Use Cases:**
- Monitor API reliability
- Identify rate limit issues
- Optimize retry configuration
- Debug transient failures

### Configuration Examples

**Aggressive Retries (Development):**
```python
engine = ReplayEngine(
    trace,
    max_retries=5,           # More attempts
    retry_initial_delay=0.5, # Faster retries
    retry_max_delay=30.0,    # Lower cap
)
```

**Conservative Retries (Production):**
```python
engine = ReplayEngine(
    trace,
    max_retries=2,           # Fewer attempts
    retry_initial_delay=2.0, # Slower retries
    retry_max_delay=120.0,   # Higher cap
)
```

**No Retries:**
```python
engine = ReplayEngine(
    trace,
    max_retries=0,  # Disable retries
)
```

---

## Semantic Similarity Fallback

### Overview

Replay comparison uses semantic similarity to compare original vs replayed outputs. By default, this requires `sentence-transformers` (~500MB). The fallback system enables comparison without this dependency.

### Fallback Strategy

Three-tier fallback when `sentence-transformers` is unavailable:

**Tier 1: Exact Match (Fastest)**
```python
if original_text == replayed_text:
    return 1.0  # 100% similarity
```

**Tier 2: difflib SequenceMatcher (Primary)**
```python
import difflib
ratio = difflib.SequenceMatcher(None, original_text, replayed_text).ratio()
# Returns 0.0-1.0 based on edit distance
```

**Tier 3: Jaccard Word Similarity (Secondary)**
```python
words1 = set(original_text.lower().split())
words2 = set(replayed_text.lower().split())
intersection = len(words1 & words2)
union = len(words1 | words2)
return intersection / union if union > 0 else 0.0
```

### Performance Comparison

| Method | Installation Size | Speed | Accuracy |
|--------|------------------|-------|----------|
| sentence-transformers | ~500MB | 10-50ms | High (0.9+ for similar) |
| difflib (fallback) | 0MB (built-in) | 1-5ms | Medium (0.7+ for similar) |
| Jaccard (fallback) | 0MB (built-in) | <1ms | Low (0.5+ for similar) |

### difflib Behavior

**Exact match:**
```python
original = "Hello world"
replayed = "Hello world"
similarity = 1.0  # 100%
```

**Case change:**
```python
original = "Hello World"
replayed = "hello world"
similarity = 0.82  # 82%
```

**Minor edit:**
```python
original = "The quick brown fox"
replayed = "The quick red fox"
similarity = 0.85  # 85%
```

**Word reorder:**
```python
original = "cat dog bird"
replayed = "dog bird cat"
similarity = 0.67  # 67%
```

**Completely different:**
```python
original = "Hello world"
replayed = "Goodbye universe"
similarity = 0.15  # 15%
```

### Availability Flags

Comparison results include flags indicating which method was used:

```python
comparison = engine.compare_replay(original_result, replayed_result)

print(f"Semantic similarity available: {comparison.semantic_similarity_available}")
print(f"Model used: {comparison.semantic_similarity_model}")
# Output (with sentence-transformers):
# Semantic similarity available: True
# Model used: all-MiniLM-L6-v2

# Output (without sentence-transformers):
# Semantic similarity available: False
# Model used: None
```

### Installation Options

**Minimal (fallback only):**
```bash
pip install prela
# Uses difflib + Jaccard, no heavy dependencies
# Fast installation, 0 additional storage
```

**Full (best accuracy):**
```bash
pip install prela[similarity]
# Downloads sentence-transformers (~500MB first time)
# Better accuracy for semantic comparison
```

### When to Use Each Method

**Use Fallback (difflib) When:**
- Installation size matters (containers, edge devices)
- Comparing structured output (JSON, code)
- Fast installation required (CI/CD)
- Exact or near-exact matches expected

**Use sentence-transformers When:**
- Comparing natural language text
- Semantic meaning matters more than exact wording
- High accuracy required
- Storage/bandwidth not constrained

---

## Tool Re-execution

### Overview

Instead of replaying cached tool outputs, you can re-execute tools during replay to test with fresh data.

### Basic Usage

```python
from prela.replay import ReplayEngine, TraceLoader

# Define tool functions
def calculator(expression: str) -> str:
    """Safe calculator tool."""
    return str(eval(expression))

def search_api(query: str) -> str:
    """Search API tool."""
    import requests
    response = requests.get(f"https://api.example.com/search?q={query}")
    return response.json()

# Create tool registry
tool_registry = {
    "calculator": calculator,
    "search_api": search_api,
}

trace = TraceLoader.from_file("trace.json")
engine = ReplayEngine(trace, tool_registry=tool_registry, enable_tool_execution=True)

result = engine.replay_with_modifications(model="gpt-4o")
```

### Safety Controls

**Allowlist (Recommended):**
```python
engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution={
        "allowlist": ["calculator", "search_api"],  # Only these tools
    }
)
```

**Blocklist:**
```python
engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution={
        "blocklist": ["delete_file", "send_email"],  # Block dangerous tools
    }
)
```

**All Tools:**
```python
engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution=True,  # Enable all tools in registry
)
```

### Priority System

When a tool call is encountered, the engine uses this priority:

1. **Mocks** (highest priority) - If mock provided via `tool_mocks` parameter
2. **Execution** (medium priority) - If enabled and tool in registry
3. **Cached** (lowest priority) - Original output from trace

```python
engine = ReplayEngine(
    trace,
    tool_registry={"calculator": calculator_fn},
    enable_tool_execution=True,
    tool_mocks={"calculator": "42"},  # Mock overrides execution
)
```

### Error Handling

Tool errors are captured safely:

```python
def risky_tool(input: str) -> str:
    """Tool that might fail."""
    if input == "error":
        raise ValueError("Invalid input")
    return f"Processed: {input}"

tool_registry = {"risky_tool": risky_tool}

engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution=True,
)

result = engine.replay_with_modifications(model="gpt-4o")

# Errors captured in span status, replay continues
for span in result.spans:
    if span.span_type == "tool" and span.status == "error":
        print(f"Tool {span.name} failed: {span.attributes.get('error.message')}")
```

### Use Cases

**Integration Testing:**
```python
# Test with real APIs
tool_registry = {
    "github_api": github.search_repositories,
    "slack_api": slack.post_message,
}

engine = ReplayEngine(
    trace,
    tool_registry=tool_registry,
    enable_tool_execution={"allowlist": ["github_api"]},  # Only test GitHub
)
```

**Regression Testing:**
```python
# Compare cached vs fresh results
result1 = engine.replay_with_modifications(enable_tool_execution=False)  # Use cached
result2 = engine.replay_with_modifications(enable_tool_execution=True)   # Re-execute

comparison = engine.compare_replay(result1, result2)
print(f"Tool output consistency: {comparison.output_similarity}")
```

**Controlled Testing:**
```python
# Test subset of tools
engine = ReplayEngine(
    trace,
    tool_registry=all_tools,
    enable_tool_execution={
        "allowlist": ["safe_tool_1", "safe_tool_2"],
        "blocklist": ["dangerous_tool"],  # Extra safety
    }
)
```

---

## Retrieval Re-execution

### Overview

Re-execute vector database queries during replay to test with current data:

```python
from prela.replay import ReplayEngine, TraceLoader
import chromadb

# Initialize vector database client
client = chromadb.Client()
collection = client.get_or_create_collection("my_docs")

trace = TraceLoader.from_file("trace.json")
engine = ReplayEngine(
    trace,
    retrieval_client=client,
    enable_retrieval_execution=True,
)

result = engine.replay_with_modifications(model="gpt-4o")
```

### Supported Vector Databases

**ChromaDB (Fully Implemented):**
```python
import chromadb

client = chromadb.Client()
collection = client.get_or_create_collection("docs")

engine = ReplayEngine(
    trace,
    retrieval_client=client,
    enable_retrieval_execution=True,
)
```

**Pinecone (Placeholder):**
```python
import pinecone

pinecone.init(api_key="...")
index = pinecone.Index("my-index")

engine = ReplayEngine(
    trace,
    retrieval_client=index,
    enable_retrieval_execution=True,
)
```

**Qdrant (Placeholder):**
```python
from qdrant_client import QdrantClient

client = QdrantClient(url="http://localhost:6333")

engine = ReplayEngine(
    trace,
    retrieval_client=client,
    enable_retrieval_execution=True,
)
```

**Weaviate (Placeholder):**
```python
import weaviate

client = weaviate.Client(url="http://localhost:8080")

engine = ReplayEngine(
    trace,
    retrieval_client=client,
    enable_retrieval_execution=True,
)
```

### Query Override

Override the original query:

```python
engine = ReplayEngine(
    trace,
    retrieval_client=client,
    enable_retrieval_execution=True,
    retrieval_query_override="Updated query text",
)

# All retrieval spans will use the new query
result = engine.replay_with_modifications(model="gpt-4o")
```

### Priority System

When a retrieval operation is encountered:

1. **Execution** (if enabled and client provided) - Query vector database
2. **Cached** (fallback) - Original documents from trace

```python
# Test with fresh data
result1 = engine.replay_with_modifications(enable_retrieval_execution=True)

# Test with cached data
result2 = engine.replay_with_modifications(enable_retrieval_execution=False)

# Compare consistency
comparison = engine.compare_replay(result1, result2)
```

### Use Cases

**Data Freshness Testing:**
```python
# Verify agent works with current data
engine = ReplayEngine(
    trace,
    retrieval_client=chroma_client,
    enable_retrieval_execution=True,
)

result = engine.replay_with_modifications(model="gpt-4o")
print(f"Documents retrieved: {len(result.spans[0].documents)}")
```

**RAG Pipeline Testing:**
```python
# Test retrieval → generation pipeline
engine = ReplayEngine(
    trace,
    retrieval_client=chroma_client,
    enable_retrieval_execution=True,
    enable_tool_execution=True,  # Also re-execute tools
)

result = engine.replay_with_modifications(
    model="gpt-4o",
    temperature=0.0,  # Deterministic generation
)
```

**Query Sensitivity Testing:**
```python
# Test different query variations
queries = [
    "original query",
    "rephrased query",
    "shorter query",
]

results = []
for query in queries:
    engine = ReplayEngine(
        trace,
        retrieval_client=client,
        enable_retrieval_execution=True,
        retrieval_query_override=query,
    )
    results.append(engine.replay_with_modifications(model="gpt-4o"))

# Compare outputs across query variations
```

---

## Combining Advanced Features

### Complete Example

```python
from prela.replay import ReplayEngine, TraceLoader
import chromadb

# Define tools
def calculator(expr: str) -> str:
    return str(eval(expr))

def search_api(query: str) -> str:
    import requests
    return requests.get(f"https://api.example.com/search?q={query}").json()

# Initialize vector database
chroma_client = chromadb.Client()
collection = chroma_client.get_or_create_collection("docs")

# Load trace
trace = TraceLoader.from_file("trace.json")

# Create engine with all advanced features
engine = ReplayEngine(
    trace,
    # API retry configuration
    max_retries=3,
    retry_initial_delay=1.0,
    retry_max_delay=60.0,
    # Tool re-execution
    tool_registry={"calculator": calculator, "search_api": search_api},
    enable_tool_execution={"allowlist": ["calculator"]},
    # Retrieval re-execution
    retrieval_client=chroma_client,
    enable_retrieval_execution=True,
)

# Replay with modifications
result = engine.replay_with_modifications(
    model="gpt-4o",
    temperature=0.7,
)

# Analyze results
print(f"Replayed {len(result.spans)} spans")
print(f"Retries required: {sum(s.retry_count for s in result.spans)}")
print(f"Tools executed: {sum(1 for s in result.spans if s.span_type == 'tool')}")
print(f"Retrievals executed: {sum(1 for s in result.spans if s.span_type == 'retrieval')}")

# Compare with original (using fallback similarity)
comparison = engine.compare_replay(
    original_result=trace,
    replayed_result=result,
)

print(f"\nSemantic similarity available: {comparison.semantic_similarity_available}")
print(f"Similarity model: {comparison.semantic_similarity_model or 'difflib (fallback)'}")
print(f"Output similarity: {comparison.output_similarity:.2%}")
```

---

## Best Practices

### 1. Start with Defaults

Use default retry configuration unless you have specific needs:

```python
engine = ReplayEngine(trace)  # max_retries=3, exponential backoff
```

### 2. Use Allowlists for Tool Execution

Always specify which tools are safe to execute:

```python
engine = ReplayEngine(
    trace,
    tool_registry=all_tools,
    enable_tool_execution={"allowlist": ["safe_tool_1", "safe_tool_2"]},
)
```

### 3. Monitor Retry Counts

Track which spans require retries:

```python
retry_spans = [s for s in result.spans if s.retry_count > 0]
if retry_spans:
    print(f"Warning: {len(retry_spans)} spans required retries")
```

### 4. Fallback is Usually Sufficient

Use `difflib` fallback unless semantic understanding is critical:

```python
# No need to install sentence-transformers for most use cases
pip install prela  # Fallback is fast and accurate enough
```

### 5. Combine Features Carefully

Enable only features you need:

```python
# Development: Enable everything
engine = ReplayEngine(
    trace,
    max_retries=5,
    enable_tool_execution=True,
    enable_retrieval_execution=True,
)

# Production: Conservative settings
engine = ReplayEngine(
    trace,
    max_retries=2,
    enable_tool_execution={"allowlist": ["read_only_tool"]},
    enable_retrieval_execution=False,  # Use cached data
)
```

---

## Troubleshooting

### Issue: Retries Not Working

**Symptoms:** API calls fail immediately without retrying.

**Solutions:**
1. Check error type is retryable:
   ```python
   # 429, 503, 502 are retryable
   # 401, 403, 400 are not
   ```

2. Verify max_retries > 0:
   ```python
   engine = ReplayEngine(trace, max_retries=3)  # Not 0
   ```

### Issue: Tool Execution Failing

**Symptoms:** Tools not executing during replay.

**Solutions:**
1. Verify tool in registry:
   ```python
   print(tool_registry.keys())  # Check tool name matches
   ```

2. Check allowlist/blocklist:
   ```python
   enable_tool_execution={"allowlist": ["tool_name"]}  # Exact match required
   ```

3. Ensure tool function signature is correct:
   ```python
   def my_tool(input: str) -> str:  # Must accept string, return string
       return result
   ```

### Issue: Retrieval Client Not Working

**Symptoms:** Retrieval not re-executing, using cached data.

**Solutions:**
1. Verify client type is supported:
   ```python
   # ChromaDB fully supported
   # Others are placeholders
   ```

2. Check enable_retrieval_execution is True:
   ```python
   engine = ReplayEngine(
       trace,
       retrieval_client=client,
       enable_retrieval_execution=True,  # Must be True
   )
   ```

---

## Next Steps

- [Replay Multi-Agent Examples](../examples/replay-multi-agent.md) - Replay with CrewAI, AutoGen, LangGraph, Swarm
- [Replay with Tools Examples](../examples/replay-with-tools.md) - Tool re-execution patterns
- [Basic Replay](replay.md) - Core replay concepts
- [CLI Replay Commands](../cli/commands.md) - Command-line replay interface
