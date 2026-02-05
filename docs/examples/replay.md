# Replay Examples

Practical examples for deterministic replay and A/B testing.

---

## Basic Exact Replay

Re-execute a captured trace without making API calls:

```python
from prela.replay import ReplayEngine
from prela.replay.loader import TraceLoader

# Load trace from file
trace = TraceLoader.from_file("traces.jsonl")

# Create replay engine
engine = ReplayEngine(trace)

# Exact replay (deterministic, no API calls)
result = engine.replay_exact()

# Inspect results
print(f"Trace ID: {result.trace_id}")
print(f"Total Spans: {len(result.spans)}")
print(f"Duration: {result.total_duration_ms:.2f}ms")
print(f"Total Tokens: {result.total_tokens}")
print(f"Estimated Cost: ${result.total_cost_usd:.4f}")

# Examine individual spans
for span in result.spans:
    print(f"\nSpan: {span.name}")
    print(f"  Type: {span.span_type}")
    print(f"  Duration: {span.duration_ms:.2f}ms")
    print(f"  Output: {span.output[:100]}...")  # First 100 chars
```

---

## A/B Testing: Compare Models

Test GPT-4 vs Claude Sonnet:

```python
from prela.replay import ReplayEngine, compare_replays
from prela.replay.loader import TraceLoader

# Load trace (originally GPT-4)
trace = TraceLoader.from_file("gpt4_trace.jsonl")
engine = ReplayEngine(trace)

# Baseline: Original execution
original = engine.replay_exact()

# Experiment: Claude Sonnet
claude_result = engine.replay_with_modifications(
    model="claude-sonnet-4-20250514"
)

# Compare
comparison = compare_replays(original, claude_result)

# Print summary
print(comparison.generate_summary())

# Detailed analysis
print("\n=== Cost Analysis ===")
print(f"GPT-4 Cost: ${original.total_cost_usd:.4f}")
print(f"Claude Cost: ${claude_result.total_cost_usd:.4f}")
print(f"Savings: ${original.total_cost_usd - claude_result.total_cost_usd:.4f}")

print("\n=== Quality Analysis ===")
for diff in comparison.differences:
    if diff.field == "output" and diff.semantic_similarity:
        print(f"{diff.span_name}:")
        print(f"  Semantic Similarity: {diff.semantic_similarity:.1%}")
        if diff.semantic_similarity > 0.85:
            print("  ✓ High quality match")
        else:
            print("  ⚠️ Significant divergence")
```

---

## Parameter Tuning: Temperature

Find optimal temperature setting:

```python
from prela.replay import ReplayEngine
from prela.replay.loader import TraceLoader

trace = TraceLoader.from_file("trace.jsonl")
engine = ReplayEngine(trace)

# Test different temperatures
temperatures = [0.0, 0.3, 0.5, 0.7, 1.0]
results = {}

for temp in temperatures:
    result = engine.replay_with_modifications(temperature=temp)
    results[temp] = result

# Compare outputs
print("Temperature Comparison")
print("=" * 50)

for temp, result in results.items():
    print(f"\nTemperature: {temp}")
    print(f"  Tokens: {result.total_tokens}")
    print(f"  Cost: ${result.total_cost_usd:.4f}")
    print(f"  Duration: {result.total_duration_ms:.0f}ms")

    # Show first span output
    if result.spans:
        output = result.spans[0].output
        print(f"  Output preview: {output[:80]}...")
```

---

## Batch Model Comparison

Compare multiple models and configurations:

```python
from prela.replay import ReplayEngine, compare_replays
from prela.replay.loader import TraceLoader
import json

trace = TraceLoader.from_file("trace.jsonl")
engine = ReplayEngine(trace)

# Baseline
baseline = engine.replay_exact()

# Experiments
experiments = {
    "gpt-4o": {"model": "gpt-4o"},
    "gpt-4o-temp0.7": {"model": "gpt-4o", "temperature": 0.7},
    "claude-sonnet": {"model": "claude-sonnet-4-20250514"},
    "claude-haiku": {"model": "claude-3-haiku-20240307"},
}

results = {}
comparisons = {}

# Run experiments
for name, modifications in experiments.items():
    print(f"Running: {name}...")
    result = engine.replay_with_modifications(**modifications)
    results[name] = result
    comparisons[name] = compare_replays(baseline, result)

# Generate report
report = {
    "baseline": {
        "cost": baseline.total_cost_usd,
        "tokens": baseline.total_tokens,
        "duration_ms": baseline.total_duration_ms,
    },
    "experiments": {}
}

for name, result in results.items():
    comparison = comparisons[name]

    report["experiments"][name] = {
        "cost": result.total_cost_usd,
        "cost_delta": result.total_cost_usd - baseline.total_cost_usd,
        "tokens": result.total_tokens,
        "tokens_delta": result.total_tokens - baseline.total_tokens,
        "duration_ms": result.total_duration_ms,
        "avg_similarity": sum(
            d.semantic_similarity or 0
            for d in comparison.differences
            if d.semantic_similarity
        ) / len([d for d in comparison.differences if d.semantic_similarity])
        if [d for d in comparison.differences if d.semantic_similarity]
        else None,
    }

# Save report
with open("experiment_report.json", "w") as f:
    json.dump(report, f, indent=2)

print("\n=== Experiment Report ===")
print(json.dumps(report, indent=2))

# Find best option
best_cost = min(results.items(), key=lambda x: x[1].total_cost_usd)
print(f"\nLowest cost: {best_cost[0]} (${best_cost[1].total_cost_usd:.4f})")
```

---

## System Prompt Testing

Test different instruction styles:

```python
from prela.replay import ReplayEngine, compare_replays
from prela.replay.loader import TraceLoader

trace = TraceLoader.from_file("trace.jsonl")
engine = ReplayEngine(trace)

# Original
original = engine.replay_exact()

# Test variations
prompts = {
    "concise": "You are a helpful assistant. Be concise and direct.",
    "detailed": "You are a helpful assistant. Provide detailed explanations with examples.",
    "technical": "You are a technical expert. Use precise terminology and cite sources.",
}

results = {}

for name, prompt in prompts.items():
    result = engine.replay_with_modifications(system_prompt=prompt)
    results[name] = result

# Analyze outputs
print("System Prompt Comparison")
print("=" * 50)

for name, result in results.items():
    comparison = compare_replays(original, result)

    print(f"\n{name.upper()}")
    print(f"  Prompt: {prompts[name]}")
    print(f"  Output length: {len(result.spans[0].output) if result.spans else 0} chars")
    print(f"  Tokens: {result.total_tokens}")
    print(f"  Cost: ${result.total_cost_usd:.4f}")

    # Semantic similarity
    similarities = [
        d.semantic_similarity
        for d in comparison.differences
        if d.semantic_similarity
    ]
    if similarities:
        avg_sim = sum(similarities) / len(similarities)
        print(f"  Avg similarity: {avg_sim:.1%}")
```

---

## Regression Testing

Ensure new model versions don't break functionality:

```python
from prela.replay import ReplayEngine, compare_replays
from prela.replay.loader import TraceLoader

def regression_test(trace_file, new_model, similarity_threshold=0.85):
    """
    Test if new model produces similar results to original.

    Returns:
        dict: Test results with pass/fail status
    """
    trace = TraceLoader.from_file(trace_file)
    engine = ReplayEngine(trace)

    # Baseline
    original = engine.replay_exact()

    # New version
    new_result = engine.replay_with_modifications(model=new_model)

    # Compare
    comparison = compare_replays(original, new_result)

    # Analyze
    passed_spans = []
    failed_spans = []

    for diff in comparison.differences:
        if diff.field == "output" and diff.semantic_similarity:
            if diff.semantic_similarity >= similarity_threshold:
                passed_spans.append({
                    "name": diff.span_name,
                    "similarity": diff.semantic_similarity,
                })
            else:
                failed_spans.append({
                    "name": diff.span_name,
                    "similarity": diff.semantic_similarity,
                    "original": diff.original_value[:200],
                    "new": diff.new_value[:200],
                })

    # Results
    total_spans = len(passed_spans) + len(failed_spans)
    pass_rate = len(passed_spans) / total_spans if total_spans > 0 else 0

    return {
        "passed": pass_rate >= 0.95,  # 95% pass rate required
        "pass_rate": pass_rate,
        "passed_spans": len(passed_spans),
        "failed_spans": len(failed_spans),
        "failures": failed_spans,
    }


# Run regression tests
test_files = [
    "test_cases/customer_support.jsonl",
    "test_cases/code_review.jsonl",
    "test_cases/data_analysis.jsonl",
]

for test_file in test_files:
    print(f"\nTesting: {test_file}")
    result = regression_test(test_file, new_model="gpt-4o")

    if result["passed"]:
        print(f"✓ PASSED ({result['pass_rate']:.1%} similarity)")
    else:
        print(f"✗ FAILED ({result['pass_rate']:.1%} similarity)")
        print(f"  Failed spans: {result['failed_spans']}")
        for failure in result["failures"]:
            print(f"\n  - {failure['name']} ({failure['similarity']:.1%})")
            print(f"    Original: {failure['original']}...")
            print(f"    New: {failure['new']}...")
```

---

## Cost Optimization

Find the cheapest model that maintains quality:

```python
from prela.replay import ReplayEngine, compare_replays
from prela.replay.loader import TraceLoader

def find_optimal_model(trace_file, models, min_similarity=0.85):
    """
    Find cheapest model with acceptable quality.

    Args:
        trace_file: Path to trace file
        models: List of model names to test
        min_similarity: Minimum semantic similarity threshold

    Returns:
        dict: Best model and cost analysis
    """
    trace = TraceLoader.from_file(trace_file)
    engine = ReplayEngine(trace)

    # Baseline
    original = engine.replay_exact()

    # Test models
    candidates = []

    for model in models:
        result = engine.replay_with_modifications(model=model)
        comparison = compare_replays(original, result)

        # Calculate average similarity
        similarities = [
            d.semantic_similarity
            for d in comparison.differences
            if d.semantic_similarity
        ]
        avg_similarity = sum(similarities) / len(similarities) if similarities else 0

        if avg_similarity >= min_similarity:
            candidates.append({
                "model": model,
                "cost": result.total_cost_usd,
                "similarity": avg_similarity,
                "tokens": result.total_tokens,
            })

    # Sort by cost (cheapest first)
    candidates.sort(key=lambda x: x["cost"])

    return {
        "original_cost": original.total_cost_usd,
        "original_model": original.spans[0].attributes.get("llm.model") if original.spans else None,
        "candidates": candidates,
        "best_option": candidates[0] if candidates else None,
    }


# Test model lineup
models_to_test = [
    "gpt-4o",
    "gpt-4o-mini",
    "claude-sonnet-4-20250514",
    "claude-3-haiku-20240307",
]

result = find_optimal_model("trace.jsonl", models_to_test)

print("Cost Optimization Results")
print("=" * 50)
print(f"Original: {result['original_model']} (${result['original_cost']:.4f})")

if result["best_option"]:
    best = result["best_option"]
    savings = result["original_cost"] - best["cost"]
    savings_pct = (savings / result["original_cost"]) * 100

    print(f"\n✓ Best Option: {best['model']}")
    print(f"  Cost: ${best['cost']:.4f}")
    print(f"  Savings: ${savings:.4f} ({savings_pct:.1f}%)")
    print(f"  Quality: {best['similarity']:.1%} similar")
    print(f"  Tokens: {best['tokens']}")

    print("\nAll Candidates:")
    for candidate in result["candidates"]:
        print(f"  - {candidate['model']}: ${candidate['cost']:.4f} ({candidate['similarity']:.1%})")
else:
    print("\n✗ No models met quality threshold")
```

---

## Mock Tool Responses

Test different tool outputs:

```python
from prela.replay import ReplayEngine
from prela.replay.loader import TraceLoader

trace = TraceLoader.from_file("trace_with_tools.jsonl")
engine = ReplayEngine(trace)

# Original execution
original = engine.replay_exact()

# Test with different tool responses
mock_responses = {
    "search": {
        "results": [
            {"title": "Alternative Result 1", "url": "https://example.com/1"},
            {"title": "Alternative Result 2", "url": "https://example.com/2"},
        ]
    },
    "calculator": {
        "result": 42  # Different calculation result
    },
}

modified = engine.replay_with_modifications(
    mock_tool_responses=mock_responses
)

# Compare how agent adapts to different tool outputs
print("Tool Response Testing")
print("=" * 50)

print("\nOriginal Tool Outputs:")
for span in original.spans:
    if span.span_type == "tool":
        print(f"  {span.name}: {span.output[:100]}...")

print("\nModified Tool Outputs:")
for span in modified.spans:
    if span.span_type == "tool":
        print(f"  {span.name}: {span.output[:100]}...")

print("\nAgent Behavior Changes:")
# Compare final outputs
original_output = original.spans[-1].output if original.spans else ""
modified_output = modified.spans[-1].output if modified.spans else ""

print(f"Original: {original_output[:200]}...")
print(f"Modified: {modified_output[:200]}...")
```

---

## Tool Re-execution

Re-execute tools during replay with safety controls.

### Basic Tool Re-execution

```python
from prela.replay import ReplayEngine
from prela.replay.loader import TraceLoader

# Load trace with tool calls
trace = TraceLoader.from_file("trace_with_tools.jsonl")
engine = ReplayEngine(trace)

# Define tool implementations
def my_calculator(input_data):
    """Calculate sum of two numbers."""
    a = input_data.get("a", 0)
    b = input_data.get("b", 0)
    result = a + b
    print(f"Calculator: {a} + {b} = {result}")
    return {"result": result}

def my_search(input_data):
    """Search for information."""
    query = input_data.get("query", "")
    print(f"Searching for: {query}")
    # Simulate fresh search
    return {
        "results": [
            {"title": "Fresh Result 1", "url": "https://example.com/1"},
            {"title": "Fresh Result 2", "url": "https://example.com/2"},
        ]
    }

# Create tool registry
tool_registry = {
    "calculator": my_calculator,
    "search": my_search,
}

# Original execution (cached data)
original = engine.replay_exact()

# Re-execute tools with current implementations
modified = engine.replay_with_modifications(
    enable_tool_execution=True,
    tool_registry=tool_registry,
)

# Compare results
print("\nTool Re-execution Comparison")
print("=" * 60)

for orig_span, mod_span in zip(original.spans, modified.spans):
    if orig_span.span_type == "tool":
        print(f"\n{orig_span.name}:")
        print(f"  Cached:  {orig_span.output}")
        print(f"  Fresh:   {mod_span.output}")
        print(f"  Changed: {orig_span.output != mod_span.output}")
```

### Using Allowlist for Safety

```python
from prela.replay import ReplayEngine
from prela.replay.loader import TraceLoader

trace = TraceLoader.from_file("trace_with_tools.jsonl")
engine = ReplayEngine(trace)

# Define tools
def safe_calculator(input_data):
    return {"result": input_data["a"] + input_data["b"]}

def dangerous_delete(input_data):
    # This should never execute!
    raise RuntimeError("This tool should be blocked!")

tool_registry = {
    "calculator": safe_calculator,
    "delete_file": dangerous_delete,
}

# Only allow calculator to execute
result = engine.replay_with_modifications(
    enable_tool_execution=True,
    tool_execution_allowlist=["calculator"],  # Only allow this
    tool_registry=tool_registry,
)

# Check which tools ran
for span in result.spans:
    if span.span_type == "tool":
        if span.error:
            print(f"❌ {span.name}: {span.error}")
        else:
            print(f"✅ {span.name}: {span.output}")

# Output:
# ✅ calculator: {'result': 10}
# ❌ delete_file: Tool 'delete_file' not in allowlist
```

### Using Blocklist for Safety

```python
# Block dangerous tools explicitly
result = engine.replay_with_modifications(
    enable_tool_execution=True,
    tool_execution_blocklist=["delete_file", "shutdown", "execute_code"],
    tool_registry=tool_registry,
)

# Blocked tools will fail with error
for span in result.spans:
    if span.span_type == "tool" and span.error:
        print(f"🚫 Blocked: {span.name}")
```

### Testing with Mock vs Real Execution

```python
# Priority 1: Mocks (highest)
mock_result = engine.replay_with_modifications(
    mock_tool_responses={
        "search": {"results": ["Mocked result"]}
    }
)

# Priority 2: Real execution (if no mocks)
real_result = engine.replay_with_modifications(
    enable_tool_execution=True,
    tool_registry=tool_registry,
)

# Priority 3: Cached (default, if execution not enabled)
cached_result = engine.replay_exact()

print("Mock output:", mock_result.spans[0].output)
print("Real output:", real_result.spans[0].output)
print("Cached output:", cached_result.spans[0].output)
```

---

## Retrieval Re-execution

Re-query vector databases to test with updated data.

### ChromaDB Re-execution

```python
from prela.replay import ReplayEngine
from prela.replay.loader import TraceLoader
import chromadb

# Load trace with retrieval spans
trace = TraceLoader.from_file("trace_with_retrieval.jsonl")
engine = ReplayEngine(trace)

# Setup ChromaDB with fresh data
client = chromadb.Client()
collection = client.create_collection("my_docs")

# Add updated documents
collection.add(
    documents=[
        "Python is a high-level programming language",
        "JavaScript is widely used for web development",
        "Rust provides memory safety without garbage collection",
    ],
    ids=["1", "2", "3"],
)

# Original execution (cached documents)
original = engine.replay_exact()

# Re-query with current vector store
modified = engine.replay_with_modifications(
    enable_retrieval_execution=True,
    retrieval_client=collection,
)

# Compare retrieved documents
print("Retrieval Comparison")
print("=" * 60)

for orig_span, mod_span in zip(original.spans, modified.spans):
    if orig_span.span_type == "retrieval":
        print(f"\nQuery: {orig_span.input}")
        print(f"\nOriginal Documents ({len(orig_span.output)}):")
        for doc in orig_span.output[:2]:
            print(f"  - {doc.get('text', '')[:80]}...")

        print(f"\nFresh Documents ({len(mod_span.output)}):")
        for doc in mod_span.output[:2]:
            print(f"  - {doc.get('text', '')[:80]}...")
```

### Query Override

```python
# Original query: "What is Python?"
# Test with different query
result = engine.replay_with_modifications(
    enable_retrieval_execution=True,
    retrieval_client=collection,
    retrieval_query_override="What is JavaScript?",
)

print(f"Original query: {original.spans[0].input}")
print(f"New query: {result.spans[0].input}")
print(f"Results changed: {original.spans[0].output != result.spans[0].output}")
```

### A/B Testing Retrieval Strategies

```python
# Test multiple query formulations
queries = [
    "Python programming language features",  # Detailed
    "Python features",                        # Concise
    "What makes Python popular?",            # Question form
]

results = {}
for query in queries:
    result = engine.replay_with_modifications(
        enable_retrieval_execution=True,
        retrieval_client=collection,
        retrieval_query_override=query,
    )

    # Analyze results
    results[query] = {
        "doc_count": len(result.spans[0].output),
        "avg_score": sum(d.get("score", 0) for d in result.spans[0].output) / len(result.spans[0].output) if result.spans[0].output else 0,
    }

# Find best query
best_query = max(results.items(), key=lambda x: x[1]["avg_score"])
print(f"\nBest Query: {best_query[0]}")
print(f"Avg Score: {best_query[1]['avg_score']:.2f}")
```

---

## Custom Retry Configuration

Configure retry behavior for different scenarios.

### High-Retry Configuration (Flaky Networks)

```python
from prela.replay import ReplayEngine
from prela.replay.loader import TraceLoader

trace = TraceLoader.from_file("trace.jsonl")

# More retries, longer delays for unreliable connections
engine = ReplayEngine(
    trace,
    max_retries=5,              # More attempts
    retry_initial_delay=2.0,    # Start with 2s delay
    retry_max_delay=120.0,      # Allow up to 2 minutes
    retry_exponential_base=2.0,
)

result = engine.replay_with_modifications(model="gpt-4o")

# Check retry statistics
total_retries = sum(span.retry_count for span in result.spans)
print(f"Total retries needed: {total_retries}")

# Show which spans needed retries
for span in result.spans:
    if span.retry_count > 0:
        print(f"⚠️  {span.name}: {span.retry_count} retries")
```

### Fast-Fail Configuration (Production)

```python
# Minimal retries for production (fail fast)
engine = ReplayEngine(
    trace,
    max_retries=1,           # Only 1 retry
    retry_initial_delay=0.5, # Quick retry
    retry_max_delay=2.0,     # Max 2s delay
)

result = engine.replay_with_modifications(model="gpt-4o")
```

### Monitoring Retry Patterns

```python
import time

start = time.time()

result = engine.replay_with_modifications(model="gpt-4o")

elapsed = time.time() - start

# Analyze retry impact
retry_stats = {
    "total_spans": len(result.spans),
    "spans_with_retries": sum(1 for s in result.spans if s.retry_count > 0),
    "total_retries": sum(s.retry_count for s in result.spans),
    "elapsed_time": elapsed,
}

print("\nRetry Statistics")
print("=" * 60)
print(f"Total Spans: {retry_stats['total_spans']}")
print(f"Spans with Retries: {retry_stats['spans_with_retries']}")
print(f"Total Retry Attempts: {retry_stats['total_retries']}")
print(f"Elapsed Time: {retry_stats['elapsed_time']:.2f}s")

# Calculate estimated retry overhead
base_time = result.total_duration_ms / 1000
retry_overhead = elapsed - base_time
print(f"Estimated Retry Overhead: {retry_overhead:.2f}s")
```

---

## Semantic Fallback Example

Compare accuracy with and without sentence-transformers.

### Using Fallback (No Dependencies)

```python
from prela.replay import ReplayEngine, compare_replays
from prela.replay.loader import TraceLoader

trace = TraceLoader.from_file("trace.jsonl")
engine = ReplayEngine(trace)

# Original execution
original = engine.replay_exact()

# Modified execution
modified = engine.replay_with_modifications(
    model="gpt-4o",
    temperature=0.7,
)

# Compare (will use fallback if sentence-transformers not installed)
comparison = compare_replays(original, modified)

# Check which method was used
if comparison.semantic_similarity_available:
    print(f"✅ Using embeddings: {comparison.semantic_similarity_model}")
else:
    print("⚠️  Using fallback: difflib + Jaccard")

# Show similarities
print("\nSemantic Similarities:")
for diff in comparison.differences:
    if diff.field == "output" and diff.semantic_similarity:
        method = "embeddings" if comparison.semantic_similarity_available else "fallback"
        print(f"{diff.span_name}: {diff.semantic_similarity:.1%} ({method})")
```

### Accuracy Comparison

```python
# Test fallback accuracy
test_pairs = [
    ("Hello World", "hello world"),           # Case change
    ("The quick brown fox", "the fast brown fox"),  # Word change
    ("cat dog bird", "dog bird cat"),         # Word reorder
    ("Python programming", "JavaScript programming"),  # Different topic
]

print("\nFallback Accuracy Test")
print("=" * 60)

from prela.replay.comparison import ReplayComparator

# Use fallback explicitly
comparator = ReplayComparator(use_semantic_similarity=False)

for text1, text2 in test_pairs:
    similarity = comparator._compute_fallback_similarity(text1, text2)
    print(f"\n'{text1}' vs '{text2}'")
    print(f"  Similarity: {similarity:.2%}")

    if similarity > 0.9:
        status = "✅ Highly similar"
    elif similarity > 0.7:
        status = "⚠️  Moderately similar"
    else:
        status = "❌ Different"
    print(f"  Status: {status}")
```

### When to Install sentence-transformers

```python
# Check if you need better accuracy
comparison = compare_replays(original, modified)

low_confidence_count = sum(
    1 for diff in comparison.differences
    if diff.semantic_similarity and 0.6 < diff.semantic_similarity < 0.8
)

if low_confidence_count > 5 and not comparison.semantic_similarity_available:
    print("⚠️  Consider installing sentence-transformers for better accuracy")
    print("   pip install prela[similarity]")
    print(f"   {low_confidence_count} similarities in ambiguous range (60-80%)")
else:
    print("✅ Fallback accuracy is sufficient for this use case")
```

---

## CLI Workflow

Using the command-line interface:

### 1. Capture Trace with Replay Data

```bash
# Enable replay capture in your application
export PRELA_CAPTURE_FOR_REPLAY=true

# Run your application
python my_agent.py

# Traces saved to traces.jsonl with replay data
```

### 2. Exact Replay (Verify)

```bash
# Quick verification
prela replay traces.jsonl

# Output:
# Trace ID: abc-123
# Duration: 2.5s
# Tokens: 1,234
# Cost: $0.0185
```

### 3. Modified Replay (Experiment)

```bash
# Test with GPT-4o
prela replay traces.jsonl --model gpt-4o --compare

# Output:
# Original: gpt-4 ($0.0185)
# Modified: gpt-4o ($0.0092)
# Savings: $0.0093 (50.3%)
# Avg Similarity: 87.2%
```

### 4. Save Results

```bash
# Export comparison to JSON
prela replay traces.jsonl \
  --model gpt-4o \
  --temperature 0.7 \
  --compare \
  --output experiment_results.json
```

### 5. Batch Processing

```bash
# Process multiple traces
for trace in test_cases/*.jsonl; do
  echo "Processing: $trace"
  prela replay "$trace" --model gpt-4o --compare
done
```

---

## CI/CD Integration

Automate regression testing in CI:

```yaml
# .github/workflows/regression_test.yml
name: Regression Test

on:
  pull_request:
    branches: [main]

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
          pip install prela sentence-transformers

      - name: Run regression tests
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          python scripts/regression_test.py

      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: regression-results
          path: regression_results/
```

**scripts/regression_test.py**:

```python
#!/usr/bin/env python3
"""Regression test runner for CI."""

import glob
import json
import sys
from pathlib import Path

from prela.replay import ReplayEngine, compare_replays
from prela.replay.loader import TraceLoader


def main():
    test_cases = glob.glob("test_traces/*.jsonl")
    results = []
    failed = []

    for test_file in test_cases:
        print(f"Testing: {test_file}")

        trace = TraceLoader.from_file(test_file)
        engine = ReplayEngine(trace)

        original = engine.replay_exact()
        modified = engine.replay_with_modifications(model="gpt-4o")

        comparison = compare_replays(original, modified)

        # Check similarity threshold
        similarities = [
            d.semantic_similarity
            for d in comparison.differences
            if d.semantic_similarity
        ]
        avg_similarity = sum(similarities) / len(similarities) if similarities else 0

        passed = avg_similarity >= 0.85

        result = {
            "test": test_file,
            "passed": passed,
            "similarity": avg_similarity,
            "cost_delta": modified.total_cost_usd - original.total_cost_usd,
        }
        results.append(result)

        if not passed:
            failed.append(result)

    # Save results
    Path("regression_results").mkdir(exist_ok=True)
    with open("regression_results/summary.json", "w") as f:
        json.dump(results, f, indent=2)

    # Print summary
    print("\n" + "=" * 50)
    print(f"Passed: {len(results) - len(failed)}/{len(results)}")
    print(f"Failed: {len(failed)}")

    if failed:
        print("\nFailures:")
        for f in failed:
            print(f"  - {f['test']} ({f['similarity']:.1%})")
        sys.exit(1)

    print("\n✓ All regression tests passed!")


if __name__ == "__main__":
    main()
```

---

## Next Steps

- **[Replay Concepts](../concepts/replay.md)**: Understand replay fundamentals
- **[CLI Reference](../cli/commands.md#replay)**: Complete CLI documentation
- **[API Reference](../api/replay.md)**: Detailed API documentation
