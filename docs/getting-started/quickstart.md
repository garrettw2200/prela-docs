# Quick Start

Get your first trace in 5 minutes with Prela's auto-instrumentation.

---

## Step 1: Get Your API Key

Sign in at [dashboard.prela.dev](https://dashboard.prela.dev), go to **API Keys**, and create a new key. Then set it as an environment variable:

```bash
export PRELA_API_KEY="prela_sk_..."
```

---

## Step 2: Install Prela

```bash
pip install prela
```

---

## Step 3: Initialize Prela

Add one line to your application:

```python
import prela

# Initialize with your service name
# Traces are sent to Prela Cloud automatically when PRELA_API_KEY is set
prela.init(service_name="my-agent")
```

That's it! Prela will automatically instrument any LLM SDKs you use and send traces to your Prela dashboard.

---

## Step 4: Run Your Agent

Use your LLM SDK as normal:

=== "Anthropic"

    ```python
    import prela
    from anthropic import Anthropic

    # Initialize Prela
    prela.init(service_name="my-agent")

    # Use Anthropic normally - automatic tracing!
    client = Anthropic(api_key="sk-...")
    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1024,
        messages=[
            {"role": "user", "content": "Explain quantum computing"}
        ]
    )

    print(response.content[0].text)
    ```

=== "OpenAI"

    ```python
    import prela
    from openai import OpenAI

    # Initialize Prela
    prela.init(service_name="my-agent")

    # Use OpenAI normally - automatic tracing!
    client = OpenAI(api_key="sk-...")
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "user", "content": "Explain quantum computing"}
        ]
    )

    print(response.choices[0].message.content)
    ```

=== "LangChain"

    ```python
    import prela
    from langchain.llms import OpenAI
    from langchain.agents import initialize_agent, Tool

    # Initialize Prela
    prela.init(service_name="my-agent")

    # Create agent - automatic tracing!
    llm = OpenAI(temperature=0)
    tools = [
        Tool(
            name="Calculator",
            func=lambda x: eval(x),
            description="Useful for math"
        )
    ]

    agent = initialize_agent(
        tools,
        llm,
        agent="zero-shot-react-description"
    )

    result = agent.run("What is 25 * 4?")
    print(result)
    ```

---

## Step 5: View Your Traces

Traces appear in your [Prela dashboard](https://dashboard.prela.dev) in real time. If `PRELA_API_KEY` is not set, traces fall back to printing to the console:

```json
{
  "trace_id": "abc123...",
  "span_id": "def456...",
  "name": "anthropic.messages.create",
  "span_type": "llm",
  "status": "success",
  "started_at": "2025-01-26T10:30:00.123456Z",
  "ended_at": "2025-01-26T10:30:01.234567Z",
  "duration_ms": 1111.1,
  "attributes": {
    "service.name": "my-agent",
    "llm.vendor": "anthropic",
    "llm.model": "claude-sonnet-4-20250514",
    "llm.input_tokens": 50,
    "llm.output_tokens": 200,
    "llm.total_tokens": 250,
    "llm.latency_ms": 1111.1
  },
  "events": [
    {
      "name": "llm.request",
      "timestamp": "2025-01-26T10:30:00.123456Z",
      "attributes": {
        "messages": [{"role": "user", "content": "Explain quantum computing"}]
      }
    },
    {
      "name": "llm.response",
      "timestamp": "2025-01-26T10:30:01.234567Z",
      "attributes": {
        "content": "Quantum computing is..."
      }
    }
  ]
}
```

---

## What's Captured?

Every trace automatically includes:

### Request Data
- Model name (`llm.model`)
- Temperature, max tokens, etc.
- Input messages or prompt
- System prompt (if provided)

### Response Data
- Token usage (input, output, total)
- Completion reason (stop, length, tool_use)
- Response content
- Model used (actual model from API)

### Performance
- Total latency in milliseconds
- Time-to-first-token (for streaming)
- Start and end timestamps

### Tool Usage
- Tool/function calls detected
- Tool names and arguments
- Tool call IDs

### Errors
- Exception type and message
- Stack traces
- Error status codes

---

## Export to File

Save traces to a file instead of console:

```python
import prela

prela.init(
    service_name="my-agent",
    exporter="file",
    directory="./traces"  # Traces saved here
)
```

Traces are saved in JSONL format (one JSON object per line):

```bash
cat traces/2025-01-26/trace_abc123.json
```

---

## Custom Spans

Create custom spans for your own functions:

```python
import prela

tracer = prela.get_tracer()

def my_function():
    with tracer.span("my_operation", span_type="custom"):
        # Your code here
        result = expensive_computation()
        return result
```

---

## CLI Commands

Use the CLI to explore traces:

```bash
# List recent traces
prela list

# Show trace details
prela show trace_abc123

# Search for traces
prela search --status error --service my-agent
```

---

## What's Next?

Now that you have basic tracing working:

- [API Keys](https://dashboard.prela.dev/api-keys) - Manage your API keys
- [Configuration](configuration.md) - Learn about all configuration options
- [Concepts](../concepts/tracing.md) - Understand how tracing works
- [Integrations](../integrations/openai.md) - Deep dive into each integration
- [Evaluation](../evals/overview.md) - Test your agents systematically

---

## Troubleshooting

### No traces appearing?

Check that:

1. `PRELA_API_KEY` is set in your environment (`echo $PRELA_API_KEY`)
2. You called `prela.init()` before using your LLM SDK
3. Your LLM SDK is installed (`pip list | grep anthropic`)
4. Auto-instrumentation is enabled (default)

### Want to disable auto-instrumentation?

```python
prela.init(service_name="my-agent", auto_instrument=False)
```

Then manually instrument:

```python
from prela.instrumentation import AnthropicInstrumentor

instrumentor = AnthropicInstrumentor()
instrumentor.instrument(tracer=prela.get_tracer())
```

### Need help?

- [GitHub Issues](https://github.com/prela/prela/issues)
- [Concepts Documentation](../concepts/tracing.md)
