# Basic Examples

Simple examples to get started with Prela tracing.

## Minimal Setup

```python
import prela

# One-line initialization
prela.init(service_name="my-app")

# Your agent code here - auto-instrumented!
from anthropic import Anthropic

client = Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello!"}]
)

# Trace automatically captured and exported to console
```

## Basic Custom Span

```python
import prela

prela.init(service_name="my-app")
tracer = prela.get_tracer()

# Create a custom span
with tracer.span("process_request", prela.SpanType.AGENT) as span:
    span.set_attribute("user_id", "user123")
    span.set_attribute("request_type", "query")

    # Do work
    result = process_query("What is AI?")

    span.set_attribute("result_length", len(result))
```

## File Export

```python
import prela

# Export to file instead of console
prela.init(
    service_name="my-app",
    exporter="file",
    directory="./traces"
)

# Traces saved to ./traces/my-app/YYYY-MM-DD/trace_*.jsonl
```

## With Sampling

```python
import prela

# Sample 10% of requests (production)
prela.init(
    service_name="my-app",
    sample_rate=0.1
)

# Only 10% of traces will be captured
```

## Multiple LLM Calls

```python
import prela
from openai import OpenAI

prela.init(service_name="chatbot")

client = OpenAI()

# Parent span for the conversation
with prela.get_tracer().span("conversation", prela.SpanType.AGENT) as conv:
    # First message (auto-traced)
    response1 = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": "Tell me a joke"}]
    )

    # Second message (auto-traced)
    response2 = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "user", "content": "Tell me a joke"},
            {"role": "assistant", "content": response1.choices[0].message.content},
            {"role": "user", "content": "Explain why it's funny"}
        ]
    )

    conv.set_attribute("messages_exchanged", 2)
```

## Error Handling

```python
import prela
from openai import OpenAI, APIError

prela.init(service_name="my-app")
tracer = prela.get_tracer()

client = OpenAI()

with tracer.span("llm_call", prela.SpanType.LLM) as span:
    try:
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[{"role": "user", "content": "Hello"}]
        )
        span.set_attribute("success", True)
    except APIError as e:
        span.set_status(prela.SpanStatus.ERROR, str(e))
        span.set_attribute("error_type", type(e).__name__)
        raise
```

## Simple RAG

```python
import prela
from openai import OpenAI

prela.init(service_name="rag-app")
tracer = prela.get_tracer()

client = OpenAI()

def answer_question(question: str, documents: list[str]) -> str:
    with tracer.span("rag_query", prela.SpanType.AGENT) as span:
        # Retrieval
        with tracer.span("retrieve", prela.SpanType.RETRIEVAL) as r_span:
            r_span.set_attribute("query", question)
            r_span.set_attribute("num_docs", len(documents))
            # Assume documents already retrieved
            context = "\n\n".join(documents)

        # LLM call (auto-traced)
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": f"Context:\n{context}"},
                {"role": "user", "content": question}
            ]
        )

        answer = response.choices[0].message.content
        span.set_attribute("answer_length", len(answer))

        return answer

# Use it
docs = ["Document 1 text", "Document 2 text"]
answer = answer_question("What is in the documents?", docs)
```

## Environment Variables

```bash
# .env
PRELA_SERVICE_NAME=my-app
PRELA_EXPORTER=file
PRELA_TRACE_DIR=./traces
PRELA_SAMPLE_RATE=1.0
```

```python
import prela
from dotenv import load_dotenv

load_dotenv()

# Reads configuration from environment
prela.init()
```

## Async Example

```python
import asyncio
import prela
from openai import AsyncOpenAI

prela.init(service_name="async-app")

async def main():
    client = AsyncOpenAI()

    # Async LLM call (auto-traced)
    response = await client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "user", "content": "Hello async!"}]
    )

    print(response.choices[0].message.content)

asyncio.run(main())
```

## Next Steps

- Learn [Custom Spans](custom-spans.md)
- Explore [Parallel Execution](parallel.md)
- See [Production Setup](production.md)
