# Instrumentation API

Auto-instrumentation for popular LLM SDKs and frameworks.

## Base Instrumentor

::: prela.instrumentation.base.Instrumentor
    options:
      show_source: false
      show_root_heading: true
      members:
        - instrument
        - uninstrument
        - is_instrumented

## Auto-Instrumentation

::: prela.instrumentation.auto.auto_instrument
    options:
      show_source: false
      show_root_heading: true

## OpenAI Instrumentor

::: prela.instrumentation.openai.OpenAIInstrumentor
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - instrument
        - uninstrument
        - is_instrumented

## Anthropic Instrumentor

::: prela.instrumentation.anthropic.AnthropicInstrumentor
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - instrument
        - uninstrument
        - is_instrumented

## LangChain Instrumentor

::: prela.instrumentation.langchain.LangChainInstrumentor
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - instrument
        - uninstrument
        - is_instrumented

### PrelaCallbackHandler

::: prela.instrumentation.langchain.PrelaCallbackHandler
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - on_llm_start
        - on_llm_end
        - on_llm_error
        - on_chain_start
        - on_chain_end
        - on_chain_error
        - on_tool_start
        - on_tool_end
        - on_tool_error
        - on_retriever_start
        - on_retriever_end
        - on_retriever_error

## LlamaIndex Instrumentor

::: prela.instrumentation.llamaindex.LlamaIndexInstrumentor
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - instrument
        - uninstrument
        - is_instrumented

### PrelaHandler

::: prela.instrumentation.llamaindex.PrelaHandler
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - on_event_start
        - on_event_end

## N8N Webhook Handler

::: prela.instrumentation.n8n.webhook.N8nWebhookHandler
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - start
        - start_background
        - stop

## N8N Code Node Context

::: prela.instrumentation.n8n.code_node.PrelaN8nContext
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - __enter__
        - __exit__
        - log_llm_call
        - log_tool_call
        - log_retrieval

## N8N Models

### N8nWorkflowExecution

::: prela.instrumentation.n8n.models.N8nWorkflowExecution
    options:
      show_source: false
      show_root_heading: true

### N8nNodeExecution

::: prela.instrumentation.n8n.models.N8nNodeExecution
    options:
      show_source: false
      show_root_heading: true

### N8nAINodeExecution

::: prela.instrumentation.n8n.models.N8nAINodeExecution
    options:
      show_source: false
      show_root_heading: true
