# Core API

The core API provides the fundamental building blocks for tracing AI agent applications.

## prela.init()

::: prela.init
    options:
      show_source: false
      show_root_heading: true

## Tracer

::: prela.core.tracer.Tracer
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - span
        - export_span
        - set_global
        - get_global

## Span

::: prela.core.span.Span
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - end
        - set_attribute
        - add_event
        - to_dict
        - from_dict

## SpanEvent

::: prela.core.span.SpanEvent
    options:
      show_source: false
      show_root_heading: true

## SpanType

::: prela.core.span.SpanType
    options:
      show_source: false
      show_root_heading: true

## SpanStatus

::: prela.core.span.SpanStatus
    options:
      show_source: false
      show_root_heading: true

## Context Management

::: prela.core.context.get_current_context
    options:
      show_source: false

::: prela.core.context.get_current_span
    options:
      show_source: false

::: prela.core.context.new_trace_context
    options:
      show_source: false

::: prela.core.context.copy_context_to_thread
    options:
      show_source: false

::: prela.core.context.get_current_trace_id
    options:
      show_source: false

::: prela.core.context.set_context
    options:
      show_source: false

::: prela.core.context.reset_context
    options:
      show_source: false

## TraceContext

::: prela.core.context.TraceContext
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - push_span
        - pop_span
        - current_span

## Sampling

::: prela.core.sampler.BaseSampler
    options:
      show_source: false
      show_root_heading: true

::: prela.core.sampler.AlwaysOnSampler
    options:
      show_source: false
      show_root_heading: true

::: prela.core.sampler.AlwaysOffSampler
    options:
      show_source: false
      show_root_heading: true

::: prela.core.sampler.ProbabilitySampler
    options:
      show_source: false
      show_root_heading: true

::: prela.core.sampler.RateLimitingSampler
    options:
      show_source: false
      show_root_heading: true

## Clock Utilities

::: prela.core.clock.now
    options:
      show_source: false

::: prela.core.clock.monotonic_ns
    options:
      show_source: false

::: prela.core.clock.duration_ms
    options:
      show_source: false

::: prela.core.clock.format_timestamp
    options:
      show_source: false

::: prela.core.clock.parse_timestamp
    options:
      show_source: false
