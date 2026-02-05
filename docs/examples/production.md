# Production Setup

Best practices and examples for running Prela in production.

## Production Configuration

```python
import prela
import os

# Production initialization
tracer = prela.init(
    service_name=os.getenv("SERVICE_NAME", "prod-agent"),
    exporter="file",
    directory="/var/log/traces",
    sample_rate=0.05,  # 5% sampling for cost control
    max_file_size_mb=500,
    rotate=True
)
```

## Environment-Based Configuration

```python
# config.py
import os
from prela import init

def get_tracer():
    """Get tracer based on environment."""
    env = os.getenv("ENVIRONMENT", "development")

    if env == "production":
        return init(
            service_name="prod-agent",
            exporter="file",
            directory="/var/log/traces",
            sample_rate=0.01,  # 1% sampling
            max_file_size_mb=1000,
            rotate=True
        )
    elif env == "staging":
        return init(
            service_name="staging-agent",
            exporter="file",
            directory="./traces",
            sample_rate=0.25,  # 25% sampling
            max_file_size_mb=100,
            rotate=True
        )
    else:  # development
        return init(
            service_name="dev-agent",
            exporter="console",
            sample_rate=1.0,  # 100% sampling
            verbosity="verbose"
        )

# Use in your app
tracer = get_tracer()
```

## Sampling Strategy

```python
from prela.core.sampler import RateLimitingSampler

# Rate limiting for high-traffic production
tracer = prela.init(
    service_name="high-traffic-agent",
    sampler=RateLimitingSampler(traces_per_second=10.0)
)

# Probability-based for moderate traffic
tracer = prela.init(
    service_name="moderate-agent",
    sample_rate=0.1  # 10% sampling
)
```

## Error Monitoring

```python
import logging
import prela

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

tracer = prela.init(service_name="prod-agent")

def process_request(request):
    """Process request with comprehensive error handling."""
    with tracer.span("process_request", prela.SpanType.AGENT) as span:
        span.set_attribute("request_id", request.id)
        span.set_attribute("user_id", request.user_id)

        try:
            # Processing logic
            result = process(request)
            span.set_attribute("success", True)
            return result

        except ValueError as e:
            # Business logic error
            logger.warning(f"Validation error: {e}", extra={
                "request_id": request.id,
                "trace_id": span.trace_id
            })
            span.set_status(prela.SpanStatus.ERROR, f"Validation: {e}")
            span.set_attribute("error_type", "validation")
            raise

        except Exception as e:
            # Unexpected error
            logger.error(f"Unexpected error: {e}", extra={
                "request_id": request.id,
                "trace_id": span.trace_id
            }, exc_info=True)
            span.set_status(prela.SpanStatus.ERROR, f"Internal: {e}")
            span.set_attribute("error_type", "internal")
            raise
```

## Performance Monitoring

```python
import time
import prela

tracer = prela.init(service_name="prod-agent")

def monitor_performance(operation_name):
    """Decorator to monitor operation performance."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            with tracer.span(operation_name, prela.SpanType.CUSTOM) as span:
                start = time.time()

                try:
                    result = func(*args, **kwargs)
                    duration = (time.time() - start) * 1000

                    span.set_attribute("duration_ms", duration)
                    span.set_attribute("success", True)

                    # Alert on slow operations
                    if duration > 5000:  # 5 seconds
                        logger.warning(f"Slow operation: {operation_name} took {duration:.0f}ms")

                    return result

                except Exception as e:
                    duration = (time.time() - start) * 1000
                    span.set_attribute("duration_ms", duration)
                    span.set_attribute("success", False)
                    raise

        return wrapper
    return decorator

@monitor_performance("critical_operation")
def critical_operation(data):
    # Critical business logic
    return process_data(data)
```

## Graceful Degradation

```python
import prela

def init_with_fallback():
    """Initialize tracer with graceful fallback."""
    try:
        return prela.init(
            service_name="prod-agent",
            exporter="file",
            directory="/var/log/traces"
        )
    except Exception as e:
        logger.error(f"Failed to initialize tracer: {e}")
        # Fallback: disable tracing
        return prela.init(
            service_name="prod-agent",
            sample_rate=0.0  # Disable tracing
        )

tracer = init_with_fallback()
```

## Resource Management

```python
import prela
from contextlib import contextmanager

@contextmanager
def traced_operation(name, **attributes):
    """Context manager for traced operations with cleanup."""
    span = None
    try:
        with tracer.span(name) as span:
            for key, value in attributes.items():
                span.set_attribute(key, value)
            yield span
    except Exception as e:
        if span:
            span.set_status(prela.SpanStatus.ERROR, str(e))
        raise
    finally:
        # Cleanup logic
        pass

# Usage
with traced_operation("database_query", table="users", operation="select"):
    results = db.query("SELECT * FROM users")
```

## Multi-Tenant Support

```python
import prela
from prela.core.context import get_trace_context

def process_tenant_request(tenant_id, request):
    """Process request with tenant isolation."""
    with tracer.span("tenant_request", prela.SpanType.AGENT) as span:
        # Add tenant context
        span.set_attribute("tenant_id", tenant_id)
        span.set_attribute("request_id", request.id)

        # Store in baggage for child spans
        ctx = get_trace_context()
        ctx.baggage["tenant_id"] = tenant_id
        ctx.baggage["environment"] = "production"

        # Process request
        result = process(request)

        span.set_attribute("result_size", len(result))
        return result
```

## Health Checks

```python
import prela

tracer = prela.init(service_name="prod-agent")

def health_check():
    """Health check endpoint."""
    with tracer.span("health_check", prela.SpanType.CUSTOM) as span:
        checks = {}

        # Check database
        try:
            db.ping()
            checks["database"] = "healthy"
        except Exception as e:
            checks["database"] = f"unhealthy: {e}"
            span.add_event("database_check_failed", {"error": str(e)})

        # Check external API
        try:
            api.ping()
            checks["api"] = "healthy"
        except Exception as e:
            checks["api"] = f"unhealthy: {e}"
            span.add_event("api_check_failed", {"error": str(e)})

        # Check tracing
        checks["tracing"] = "healthy"  # If we got here, tracing works

        all_healthy = all(v == "healthy" for v in checks.values())
        span.set_attribute("overall_health", "healthy" if all_healthy else "degraded")

        return checks, 200 if all_healthy else 503
```

## Docker Deployment

```dockerfile
# Dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Create traces directory
RUN mkdir -p /var/log/traces

# Environment variables
ENV SERVICE_NAME=prod-agent
ENV ENVIRONMENT=production
ENV PRELA_EXPORTER=file
ENV PRELA_TRACE_DIR=/var/log/traces
ENV PRELA_SAMPLE_RATE=0.05

CMD ["python", "app.py"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  agent:
    build: .
    environment:
      - SERVICE_NAME=prod-agent
      - ENVIRONMENT=production
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - PRELA_TRACE_DIR=/var/log/traces
      - PRELA_SAMPLE_RATE=0.05
    volumes:
      - ./traces:/var/log/traces
    restart: unless-stopped
```

## Kubernetes Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prela-agent
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: agent
        image: prela-agent:latest
        env:
        - name: SERVICE_NAME
          value: "prod-agent"
        - name: ENVIRONMENT
          value: "production"
        - name: PRELA_EXPORTER
          value: "file"
        - name: PRELA_TRACE_DIR
          value: "/var/log/traces"
        - name: PRELA_SAMPLE_RATE
          value: "0.05"
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: api-keys
              key: anthropic-key
        volumeMounts:
        - name: traces
          mountPath: /var/log/traces
      volumes:
      - name: traces
        persistentVolumeClaim:
          claimName: traces-pvc
```

## Monitoring and Alerting

```python
import prela
from prometheus_client import Counter, Histogram

# Prometheus metrics
trace_counter = Counter('prela_traces_total', 'Total traces created')
trace_duration = Histogram('prela_trace_duration_seconds', 'Trace duration')

class MonitoredTracer:
    """Tracer wrapper with monitoring."""

    def __init__(self, tracer):
        self.tracer = tracer

    def span(self, name, span_type=None):
        trace_counter.inc()
        return self.tracer.span(name, span_type)

tracer = MonitoredTracer(prela.init(service_name="prod-agent"))
```

## Cost Management

```python
import prela

# Cost-aware sampling
class CostAwareSampler:
    """Sample based on estimated cost."""

    def __init__(self, budget_per_hour=100):
        self.budget_per_hour = budget_per_hour
        self.cost_per_trace = 0.01  # Estimate
        self.max_traces_per_hour = budget_per_hour / self.cost_per_trace

    def should_sample(self, trace_id):
        # Implement rate limiting based on budget
        # For simplicity, using probability
        rate = min(1.0, self.max_traces_per_hour / (3600 / 1))  # Per second
        return prela.ProbabilitySampler(rate).should_sample(trace_id)

tracer = prela.init(
    service_name="prod-agent",
    sampler=CostAwareSampler(budget_per_hour=100)
)
```

## Next Steps

- See [Context Propagation](../concepts/context.md)
- Learn about [Sampling](../concepts/sampling.md)
- Explore [Exporters](../concepts/exporters.md)
