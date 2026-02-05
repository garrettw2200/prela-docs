# Custom Spans

Advanced patterns for creating custom spans and organizing traces.

## Nested Spans

```python
import prela

prela.init(service_name="my-app")
tracer = prela.get_tracer()

with tracer.span("parent_operation", prela.SpanType.AGENT) as parent:
    parent.set_attribute("stage", "initialization")

    # Child span 1
    with tracer.span("load_data", prela.SpanType.CUSTOM) as child1:
        child1.set_attribute("source", "database")
        data = load_data()

    # Child span 2
    with tracer.span("process_data", prela.SpanType.CUSTOM) as child2:
        child2.set_attribute("num_records", len(data))
        results = process(data)

    parent.set_attribute("total_results", len(results))
```

## Span Attributes

```python
with tracer.span("custom_op") as span:
    # Basic attributes
    span.set_attribute("user_id", "user123")
    span.set_attribute("request_id", "req456")

    # Numeric attributes
    span.set_attribute("count", 42)
    span.set_attribute("latency_ms", 123.45)

    # Boolean attributes
    span.set_attribute("cached", True)
    span.set_attribute("success", False)

    # Complex attributes (auto-serialized)
    span.set_attribute("metadata", {
        "version": "1.0",
        "features": ["a", "b", "c"]
    })
```

## Span Events

```python
with tracer.span("long_operation") as span:
    # Add events for milestones
    span.add_event("started_phase_1")

    phase1_result = do_phase_1()

    span.add_event("completed_phase_1", {
        "duration_ms": 1000,
        "records_processed": 100
    })

    span.add_event("started_phase_2")

    phase2_result = do_phase_2()

    span.add_event("completed_phase_2", {
        "duration_ms": 2000,
        "records_processed": 200
    })
```

## Span Types

```python
# Agent operations
with tracer.span("agent_reasoning", prela.SpanType.AGENT):
    plan = create_plan()

# LLM calls
with tracer.span("llm_generation", prela.SpanType.LLM):
    response = call_llm()

# Tool invocations
with tracer.span("tool_execution", prela.SpanType.TOOL):
    result = call_tool()

# Retrieval operations
with tracer.span("vector_search", prela.SpanType.RETRIEVAL):
    docs = search_vectors()

# Embedding generation
with tracer.span("embed_text", prela.SpanType.EMBEDDING):
    embedding = embed(text)

# Custom operations
with tracer.span("custom_logic", prela.SpanType.CUSTOM):
    output = custom_function()
```

## Error Handling

```python
with tracer.span("risky_operation") as span:
    try:
        result = risky_function()
        span.set_attribute("result", result)
    except ValueError as e:
        span.set_status(prela.SpanStatus.ERROR, f"Value error: {e}")
        span.set_attribute("error_type", "ValueError")
        span.set_attribute("error_details", str(e))
        raise
    except Exception as e:
        span.set_status(prela.SpanStatus.ERROR, f"Unexpected error: {e}")
        raise
```

## Conditional Tracing

```python
def process_request(request, trace=True):
    """Process request with optional tracing."""
    if trace:
        with tracer.span("process_request") as span:
            span.set_attribute("request_id", request.id)
            return _do_process(request)
    else:
        return _do_process(request)
```

## Trace Correlation

```python
from prela.core.context import get_current_trace_id

with tracer.span("external_call") as span:
    # Get trace ID for correlation
    trace_id = get_current_trace_id()

    # Pass to external service
    response = requests.post(
        "https://api.example.com/process",
        headers={"X-Trace-ID": trace_id},
        json=data
    )

    span.set_attribute("external_trace_id", trace_id)
```

## Multi-Step Pipeline

```python
def run_pipeline(input_data):
    with tracer.span("pipeline", prela.SpanType.AGENT) as pipeline_span:
        pipeline_span.set_attribute("pipeline_name", "data_processing")

        # Step 1: Validation
        with tracer.span("validate", prela.SpanType.CUSTOM) as validate_span:
            validate_span.set_attribute("input_size", len(input_data))
            validated = validate(input_data)
            validate_span.set_attribute("valid", validated)

        if not validated:
            pipeline_span.set_status(prela.SpanStatus.ERROR, "Validation failed")
            return None

        # Step 2: Transform
        with tracer.span("transform", prela.SpanType.CUSTOM) as transform_span:
            transformed = transform(input_data)
            transform_span.set_attribute("output_size", len(transformed))

        # Step 3: Enrich with LLM
        with tracer.span("enrich", prela.SpanType.LLM) as enrich_span:
            # LLM call (auto-traced as child)
            enriched = call_llm(transformed)
            enrich_span.set_attribute("enrichment_applied", True)

        # Step 4: Finalize
        with tracer.span("finalize", prela.SpanType.CUSTOM) as final_span:
            result = finalize(enriched)
            final_span.set_attribute("result_size", len(result))

        pipeline_span.set_attribute("success", True)
        return result
```

## Tool Usage Tracking

```python
def agent_with_tools(query: str):
    with tracer.span("agent_workflow", prela.SpanType.AGENT) as agent_span:
        tools_used = []

        # Tool 1: Search
        with tracer.span("tool.search", prela.SpanType.TOOL) as search_span:
            search_span.set_attribute("tool.name", "search")
            search_span.set_attribute("tool.input", query)
            results = search(query)
            search_span.set_attribute("tool.output", results)
            tools_used.append("search")

        # Tool 2: Summarize
        with tracer.span("tool.summarize", prela.SpanType.TOOL) as summ_span:
            summ_span.set_attribute("tool.name", "summarize")
            summ_span.set_attribute("tool.input", results)
            summary = summarize(results)
            summ_span.set_attribute("tool.output", summary)
            tools_used.append("summarize")

        agent_span.set_attribute("tools_used", tools_used)
        agent_span.set_attribute("num_tools", len(tools_used))

        return summary
```

## Batch Processing

```python
def process_batch(items: list):
    with tracer.span("batch_processing", prela.SpanType.AGENT) as batch_span:
        batch_span.set_attribute("batch_size", len(items))

        results = []
        for i, item in enumerate(items):
            with tracer.span(f"process_item_{i}", prela.SpanType.CUSTOM) as item_span:
                item_span.set_attribute("item_id", item.id)
                item_span.set_attribute("batch_index", i)

                try:
                    result = process_item(item)
                    item_span.set_attribute("success", True)
                    results.append(result)
                except Exception as e:
                    item_span.set_status(prela.SpanStatus.ERROR, str(e))
                    item_span.set_attribute("success", False)

        batch_span.set_attribute("successful", len(results))
        batch_span.set_attribute("failed", len(items) - len(results))

        return results
```

## Retry Logic

```python
import time

def call_with_retry(func, max_retries=3):
    with tracer.span("retry_wrapper", prela.SpanType.CUSTOM) as wrapper_span:
        wrapper_span.set_attribute("max_retries", max_retries)

        for attempt in range(max_retries):
            with tracer.span(f"attempt_{attempt}", prela.SpanType.CUSTOM) as attempt_span:
                attempt_span.set_attribute("attempt_number", attempt)

                try:
                    result = func()
                    attempt_span.set_attribute("success", True)
                    wrapper_span.set_attribute("attempts_needed", attempt + 1)
                    return result
                except Exception as e:
                    attempt_span.set_status(prela.SpanStatus.ERROR, str(e))
                    attempt_span.set_attribute("success", False)

                    if attempt < max_retries - 1:
                        delay = 2 ** attempt
                        attempt_span.add_event("retrying", {"delay_seconds": delay})
                        time.sleep(delay)
                    else:
                        wrapper_span.set_status(prela.SpanStatus.ERROR, "All retries failed")
                        raise
```

## Next Steps

- See [Parallel Execution](parallel.md)
- Explore [Production Setup](production.md)
- Learn about [Context Propagation](../concepts/context.md)
