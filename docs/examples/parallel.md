# Parallel Execution

Examples of tracing parallel and concurrent operations.

## Thread Pool Execution

```python
from concurrent.futures import ThreadPoolExecutor, as_completed
import prela
from prela.core.context import copy_context_to_thread

prela.init(service_name="parallel-app")
tracer = prela.get_tracer()

def process_item(item_id):
    """Process a single item (runs in worker thread)."""
    with tracer.span(f"process_{item_id}", prela.SpanType.CUSTOM) as span:
        span.set_attribute("item_id", item_id)
        # Processing logic
        return f"Result for {item_id}"

# Create parent span
with tracer.span("batch_processing", prela.SpanType.AGENT) as parent:
    parent.set_attribute("batch_size", 10)

    # Wrap function INSIDE parent span context
    wrapped_process = copy_context_to_thread(process_item)

    # Submit to thread pool
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = [
            executor.submit(wrapped_process, i)
            for i in range(10)
        ]

        # Collect results
        results = []
        for future in as_completed(futures):
            result = future.result()
            results.append(result)

    parent.set_attribute("results_count", len(results))

# All child spans properly linked to parent
```

## Async Concurrent Operations

```python
import asyncio
import prela
from openai import AsyncOpenAI

prela.init(service_name="async-app")
tracer = prela.get_tracer()

async def fetch_completion(prompt: str, index: int):
    """Fetch completion asynchronously."""
    with tracer.span(f"completion_{index}", prela.SpanType.LLM) as span:
        span.set_attribute("prompt_index", index)
        client = AsyncOpenAI()

        response = await client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}]
        )

        return response.choices[0].message.content

async def process_batch(prompts: list[str]):
    """Process multiple prompts concurrently."""
    with tracer.span("async_batch", prela.SpanType.AGENT) as batch_span:
        batch_span.set_attribute("num_prompts", len(prompts))

        # Create tasks
        tasks = [
            fetch_completion(prompt, i)
            for i, prompt in enumerate(prompts)
        ]

        # Run concurrently
        results = await asyncio.gather(*tasks)

        batch_span.set_attribute("results_count", len(results))
        return results

# Run
prompts = ["Prompt 1", "Prompt 2", "Prompt 3"]
results = asyncio.run(process_batch(prompts))
```

## Parallel with Different Span Types

```python
from concurrent.futures import ThreadPoolExecutor
from prela.core.context import copy_context_to_thread

def search_database(query: str):
    with tracer.span("database_search", prela.SpanType.RETRIEVAL) as span:
        span.set_attribute("query", query)
        # Search logic
        return ["result1", "result2"]

def call_llm(prompt: str):
    with tracer.span("llm_call", prela.SpanType.LLM) as span:
        span.set_attribute("prompt", prompt)
        # LLM call
        return "LLM response"

def execute_tool(tool_name: str):
    with tracer.span(f"tool_{tool_name}", prela.SpanType.TOOL) as span:
        span.set_attribute("tool.name", tool_name)
        # Tool execution
        return f"{tool_name} result"

with tracer.span("parallel_operations", prela.SpanType.AGENT) as parent:
    # Wrap functions
    wrapped_search = copy_context_to_thread(search_database)
    wrapped_llm = copy_context_to_thread(call_llm)
    wrapped_tool = copy_context_to_thread(execute_tool)

    # Execute in parallel
    with ThreadPoolExecutor() as executor:
        search_future = executor.submit(wrapped_search, "user query")
        llm_future = executor.submit(wrapped_llm, "generate text")
        tool_future = executor.submit(wrapped_tool, "calculator")

        # Collect results
        search_results = search_future.result()
        llm_response = llm_future.result()
        tool_result = tool_future.result()

    parent.set_attribute("operations_completed", 3)
```

## Map-Reduce Pattern

```python
from concurrent.futures import ThreadPoolExecutor
from prela.core.context import copy_context_to_thread

def map_function(item):
    """Map step (parallel)."""
    with tracer.span(f"map_{item}", prela.SpanType.CUSTOM) as span:
        span.set_attribute("input", item)
        result = item * 2  # Transform
        span.set_attribute("output", result)
        return result

def reduce_function(results):
    """Reduce step (sequential)."""
    with tracer.span("reduce", prela.SpanType.CUSTOM) as span:
        span.set_attribute("input_count", len(results))
        total = sum(results)
        span.set_attribute("total", total)
        return total

with tracer.span("map_reduce", prela.SpanType.AGENT) as parent:
    items = [1, 2, 3, 4, 5]

    # Map phase (parallel)
    with tracer.span("map_phase", prela.SpanType.CUSTOM) as map_span:
        wrapped_map = copy_context_to_thread(map_function)

        with ThreadPoolExecutor(max_workers=3) as executor:
            map_results = list(executor.map(wrapped_map, items))

        map_span.set_attribute("results_count", len(map_results))

    # Reduce phase (sequential)
    with tracer.span("reduce_phase", prela.SpanType.CUSTOM):
        final_result = reduce_function(map_results)

    parent.set_attribute("final_result", final_result)
```

## Async Streaming

```python
import asyncio
from openai import AsyncOpenAI

async def stream_completion(prompt: str):
    """Stream completion asynchronously."""
    with tracer.span("streaming_completion", prela.SpanType.LLM) as span:
        client = AsyncOpenAI()

        stream = await client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            stream=True
        )

        chunks = []
        async for chunk in stream:
            if chunk.choices[0].delta.content:
                chunks.append(chunk.choices[0].delta.content)

        full_response = "".join(chunks)
        span.set_attribute("response_length", len(full_response))
        return full_response

async def process_multiple_streams(prompts: list[str]):
    """Process multiple streaming completions concurrently."""
    with tracer.span("multi_stream", prela.SpanType.AGENT) as span:
        span.set_attribute("num_streams", len(prompts))

        # Create streaming tasks
        tasks = [stream_completion(prompt) for prompt in prompts]

        # Run all streams concurrently
        results = await asyncio.gather(*tasks)

        span.set_attribute("total_responses", len(results))
        return results

# Run
prompts = ["Question 1", "Question 2", "Question 3"]
results = asyncio.run(process_multiple_streams(prompts))
```

## Fan-Out Fan-In

```python
from concurrent.futures import ThreadPoolExecutor, as_completed
from prela.core.context import copy_context_to_thread

def query_source(source_name: str, query: str):
    """Query a single data source."""
    with tracer.span(f"query_{source_name}", prela.SpanType.RETRIEVAL) as span:
        span.set_attribute("source", source_name)
        span.set_attribute("query", query)
        # Simulate data retrieval
        return [f"{source_name}_result_{i}" for i in range(3)]

def aggregate_results(all_results: list):
    """Aggregate results from all sources."""
    with tracer.span("aggregate", prela.SpanType.CUSTOM) as span:
        flat_results = [item for sublist in all_results for item in sublist]
        span.set_attribute("total_items", len(flat_results))
        return flat_results

with tracer.span("fan_out_fan_in", prela.SpanType.AGENT) as parent:
    query = "search term"
    sources = ["database", "api", "cache"]

    # Fan-out: Query all sources in parallel
    with tracer.span("fan_out", prela.SpanType.CUSTOM) as fan_out_span:
        wrapped_query = copy_context_to_thread(query_source)

        with ThreadPoolExecutor(max_workers=len(sources)) as executor:
            futures = {
                executor.submit(wrapped_query, source, query): source
                for source in sources
            }

            all_results = []
            for future in as_completed(futures):
                source = futures[future]
                try:
                    result = future.result()
                    all_results.append(result)
                except Exception as e:
                    fan_out_span.add_event(f"{source}_failed", {"error": str(e)})

        fan_out_span.set_attribute("sources_queried", len(sources))
        fan_out_span.set_attribute("successful_queries", len(all_results))

    # Fan-in: Aggregate all results
    with tracer.span("fan_in", prela.SpanType.CUSTOM):
        final_results = aggregate_results(all_results)

    parent.set_attribute("final_count", len(final_results))
```

## Rate-Limited Parallel Execution

```python
import time
from concurrent.futures import ThreadPoolExecutor
from prela.core.context import copy_context_to_thread

class RateLimiter:
    def __init__(self, calls_per_second):
        self.calls_per_second = calls_per_second
        self.last_call = 0

    def wait(self):
        now = time.time()
        time_since_last = now - self.last_call
        min_interval = 1.0 / self.calls_per_second

        if time_since_last < min_interval:
            time.sleep(min_interval - time_since_last)

        self.last_call = time.time()

limiter = RateLimiter(calls_per_second=5)

def rate_limited_operation(item_id):
    """Operation with rate limiting."""
    limiter.wait()

    with tracer.span(f"operation_{item_id}", prela.SpanType.CUSTOM) as span:
        span.set_attribute("item_id", item_id)
        # Operation logic
        return f"Result {item_id}"

with tracer.span("rate_limited_batch", prela.SpanType.AGENT) as parent:
    wrapped_op = copy_context_to_thread(rate_limited_operation)

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(wrapped_op, i) for i in range(20)]
        results = [f.result() for f in futures]

    parent.set_attribute("completed", len(results))
```

## Next Steps

- See [Production Setup](production.md)
- Learn about [Context Propagation](../concepts/context.md)
- Explore [Custom Spans](custom-spans.md)
