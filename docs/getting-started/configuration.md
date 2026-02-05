# Configuration

Configure Prela using function parameters or environment variables.

---

## Basic Configuration

### Service Name

Identify your application in traces:

```python
import prela

prela.init(service_name="customer-support-bot")
```

Or via environment variable:

```bash
export PRELA_SERVICE_NAME="customer-support-bot"
```

```python
prela.init()  # Uses PRELA_SERVICE_NAME
```

---

## Exporters

Choose where traces are sent.

### Console Exporter

Print traces to stdout (default):

```python
prela.init(
    service_name="my-agent",
    exporter="console"
)
```

Options:

- `pretty`: Enable pretty-printing (default: `True`)
- `indent`: JSON indentation spaces (default: `2`)

```python
from prela.exporters import ConsoleExporter

prela.init(
    service_name="my-agent",
    exporter=ConsoleExporter(pretty=True, indent=4)
)
```

### File Exporter

Save traces to JSONL files:

```python
prela.init(
    service_name="my-agent",
    exporter="file",
    directory="./traces"
)
```

Files are organized by date:

```
traces/
├── 2025-01-26/
│   ├── trace_abc123.json
│   ├── trace_def456.json
│   └── trace_ghi789.json
└── 2025-01-27/
    └── trace_jkl012.json
```

Options:

- `directory`: Base directory (default: `"./traces"`)
- `max_file_size`: Rotate after N bytes (default: `None`, no rotation)

```python
from prela.exporters import FileExporter

prela.init(
    service_name="my-agent",
    exporter=FileExporter(
        directory="./production-traces",
        max_file_size=10 * 1024 * 1024  # 10 MB
    )
)
```

### Custom Exporter

Implement your own exporter:

```python
from prela.exporters import BaseExporter, ExportResult
from typing import List
from prela.core import Span

class MyExporter(BaseExporter):
    def export(self, spans: List[Span]) -> ExportResult:
        # Send to your backend
        for span in spans:
            my_backend.send(span.to_dict())
        return ExportResult.SUCCESS

prela.init(
    service_name="my-agent",
    exporter=MyExporter()
)
```

---

## Sampling

Control which traces are recorded.

### Sample Rate

Sample a percentage of traces:

```python
prela.init(
    service_name="my-agent",
    sample_rate=0.1  # Sample 10% of traces
)
```

Uses probability-based sampling with hash consistency (same trace ID = same decision).

### Always On/Off

For development or to disable tracing:

```python
# Development: trace everything
prela.init(service_name="my-agent", sample_rate=1.0)

# Disable tracing
prela.init(service_name="my-agent", sample_rate=0.0)
```

### Custom Sampler

Implement your own sampling logic:

```python
from prela.core import BaseSampler

class MySampler(BaseSampler):
    def should_sample(self, trace_id: str) -> bool:
        # Custom logic
        return my_sampling_logic(trace_id)

from prela import init, get_tracer

tracer = get_tracer()
tracer.sampler = MySampler()
```

---

## Auto-Instrumentation

Enable or disable auto-instrumentation:

```python
# Enabled by default
prela.init(service_name="my-agent", auto_instrument=True)

# Disable (manual instrumentation required)
prela.init(service_name="my-agent", auto_instrument=False)
```

Environment variable:

```bash
export PRELA_AUTO_INSTRUMENT=false
```

---

## Debug Mode

Enable verbose logging:

```python
prela.init(service_name="my-agent", debug=True)
```

Or via environment:

```bash
export PRELA_DEBUG=true
```

Logs include:

- Instrumentation status
- Span creation/completion
- Export attempts
- Sampling decisions
- Errors and warnings

---

## Environment Variables

All configuration can be set via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `PRELA_SERVICE_NAME` | Service name | `"unknown"` |
| `PRELA_EXPORTER` | Exporter type (`"console"`, `"file"`) | `"console"` |
| `PRELA_SAMPLE_RATE` | Sampling rate (0.0-1.0) | `1.0` |
| `PRELA_AUTO_INSTRUMENT` | Enable auto-instrumentation | `true` |
| `PRELA_DEBUG` | Enable debug logging | `false` |
| `PRELA_TRACE_DIR` | Directory for file exporter | `"./traces"` |

Example:

```bash
export PRELA_SERVICE_NAME="my-agent"
export PRELA_EXPORTER="file"
export PRELA_SAMPLE_RATE="0.1"
export PRELA_AUTO_INSTRUMENT="true"
export PRELA_DEBUG="false"
export PRELA_TRACE_DIR="./traces"
```

```python
import prela

# Uses all environment variables
prela.init()
```

**Priority:** Function parameters override environment variables.

---

## Production Configuration

Recommended settings for production:

```python
import prela

prela.init(
    service_name="production-agent",
    exporter="file",
    directory="/var/log/prela/traces",
    sample_rate=0.1,  # 10% sampling
    debug=False
)
```

With environment variables:

```bash
export PRELA_SERVICE_NAME="production-agent"
export PRELA_EXPORTER="file"
export PRELA_TRACE_DIR="/var/log/prela/traces"
export PRELA_SAMPLE_RATE="0.1"
export PRELA_DEBUG="false"
```

---

## Development Configuration

Recommended settings for development:

```python
import prela

prela.init(
    service_name="dev-agent",
    exporter="console",
    sample_rate=1.0,  # Trace everything
    debug=True
)
```

---

## CLI Configuration

Configure CLI behavior with `.prela.yaml`:

```yaml
# .prela.yaml
service_name: my-agent
trace_directory: ./traces
default_exporter: file
```

Place in your project root or home directory (`~/.prela.yaml`).

---

## Configuration Examples

### Multiple Exporters

Send traces to multiple destinations:

```python
from prela.exporters import ConsoleExporter, FileExporter

console = ConsoleExporter(pretty=True)
file = FileExporter(directory="./traces")

# Export to both (requires custom tracer setup)
tracer = prela.get_tracer()
# Note: Current version supports single exporter
# Multi-exporter support coming in future release
```

### Dynamic Configuration

Change configuration at runtime:

```python
import prela

# Initial setup
prela.init(service_name="my-agent", sample_rate=1.0)

# Later: reduce sampling
tracer = prela.get_tracer()
from prela.core import ProbabilitySampler
tracer.sampler = ProbabilitySampler(rate=0.1)
```

### Per-Environment Configuration

```python
import os
import prela

env = os.getenv("ENVIRONMENT", "development")

if env == "production":
    prela.init(
        service_name="my-agent",
        exporter="file",
        directory="/var/log/traces",
        sample_rate=0.05,  # 5%
        debug=False
    )
elif env == "staging":
    prela.init(
        service_name="my-agent-staging",
        exporter="file",
        directory="./traces",
        sample_rate=0.2,  # 20%
        debug=True
    )
else:  # development
    prela.init(
        service_name="my-agent-dev",
        exporter="console",
        sample_rate=1.0,
        debug=True
    )
```

---

## Next Steps

- [Concepts: Tracing](../concepts/tracing.md) - Understand distributed tracing
- [Concepts: Sampling](../concepts/sampling.md) - Learn about sampling strategies
- [Concepts: Exporters](../concepts/exporters.md) - Deep dive into exporters
