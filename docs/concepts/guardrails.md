# Guardrails

Guardrails intercept LLM requests and responses to enforce safety policies in real time. They run synchronously in the request pipeline and can **block**, **redact**, or **log** content before it reaches the LLM or before responses reach the user.

---

## Quick Start

```python
import prela
from prela.guardrails import GuardrailRunner, PIIGuard, InjectionGuard

# Create a guardrail pipeline
runner = GuardrailRunner()
runner.add(PIIGuard(action="redact"))
runner.add(InjectionGuard())

# Initialize Prela with guardrails enabled
prela.init(service_name="my-agent", guardrails=runner)

# All LLM calls now pass through guardrails automatically
from anthropic import Anthropic
client = Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    messages=[{"role": "user", "content": "Hello!"}],
)
```

When guardrails are passed to `prela.init()`, they are automatically applied to all instrumented LLM calls (OpenAI and Anthropic). Input is checked before the LLM call, and output is checked after.

---

## How It Works

Guards execute in the order they are added to the `GuardrailRunner`. The pipeline follows these rules:

1. **ALLOW** -- Content passes through unchanged. Next guard runs.
2. **BLOCK** -- Execution stops immediately. A `GuardrailBlocked` exception is raised (or logged, depending on configuration).
3. **MODIFY** -- Content is replaced with the modified version. Subsequent guards see the modified content.
4. **LOG** -- Content passes through, but a warning is logged.

If a guard raises an exception, it defaults to **ALLOW** to avoid blocking legitimate requests.

---

## Built-in Guards

| Guard | Description | Default Action | Phases |
|---|---|---|---|
| `PIIGuard` | Detects emails, phone numbers, SSNs, credit cards, API keys | `block` | Input + Output |
| `InjectionGuard` | Detects prompt injection patterns (instruction overrides, jailbreaks, role confusion) | `block` | Input only |
| `ContentFilterGuard` | Block or require custom regex patterns | `block` | Input + Output |
| `MaxTokenGuard` | Limit input/output token count (estimated) | `block` input / `log` output | Input + Output |
| `CustomGuard` | Wrap any callable as a guard | User-defined | User-defined |

---

## PIIGuard

Detects personally identifiable information: emails, phone numbers, SSNs, credit card numbers, and API keys (AWS, Stripe, GitHub, OpenAI, Slack, Google).

```python
from prela.guardrails import PIIGuard

# Block any PII
guard = PIIGuard(action="block")

# Or redact PII automatically (replaces with [EMAIL_REDACTED], [SSN_REDACTED], etc.)
guard = PIIGuard(action="redact")

# Allow specific PII types
guard = PIIGuard(action="redact", allow_emails=True, allow_phones=True)

# Only check output (not input)
guard = PIIGuard(action="block", check_input=False, check_output=True)
```

**Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `action` | `str` | `"block"` | `"block"` to stop the request, `"redact"` to replace PII |
| `check_input` | `bool` | `True` | Check input content |
| `check_output` | `bool` | `True` | Check output content |
| `allow_emails` | `bool` | `False` | Skip email detection |
| `allow_phones` | `bool` | `False` | Skip phone detection |

---

## InjectionGuard

Detects prompt injection attempts across 5 pattern categories:

- **Instruction overrides** (critical) -- "ignore previous instructions", "override system prompt"
- **Jailbreak attempts** (high) -- DAN mode, developer mode, "act without restrictions"
- **Role confusion** (high) -- injected system/assistant role markers
- **Encoded injection** (medium) -- base64 decode, eval/exec calls
- **Delimiter injection** (medium) -- closing prompt tags, end markers

```python
from prela.guardrails import InjectionGuard

# Default: block medium severity and above
guard = InjectionGuard()

# Only block critical and high severity patterns
guard = InjectionGuard(min_severity="high")
```

**Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `min_severity` | `str` | `"medium"` | Minimum severity to block: `"low"`, `"medium"`, `"high"`, `"critical"` |

!!! note
    `InjectionGuard` only checks input (before the LLM call). It does not check output.

---

## ContentFilterGuard

Block content matching forbidden patterns, or require content matching specific patterns.

```python
from prela.guardrails import ContentFilterGuard

guard = ContentFilterGuard(
    blocked_patterns=[r"\b(password|secret|token)\b"],
    required_patterns=[r"\bJSON\b"],
    case_sensitive=False,
)
```

**Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `blocked_patterns` | `list[str]` | `None` | Regex patterns that block if matched |
| `required_patterns` | `list[str]` | `None` | Regex patterns that block if NOT matched |
| `case_sensitive` | `bool` | `False` | Whether patterns are case-sensitive |
| `check_input` | `bool` | `True` | Check input content |
| `check_output` | `bool` | `True` | Check output content |

---

## MaxTokenGuard

Limit input and output token counts using a character-based estimate (~1 token per 4 characters).

```python
from prela.guardrails import MaxTokenGuard

guard = MaxTokenGuard(max_input_tokens=4000, max_output_tokens=2000)
```

- **Input**: Blocks if estimated tokens exceed `max_input_tokens`.
- **Output**: Logs a warning (does not block) if estimated tokens exceed `max_output_tokens`.

**Parameters:**

| Parameter | Type | Default | Description |
|---|---|---|---|
| `max_input_tokens` | `int` | `None` | Maximum input token estimate |
| `max_output_tokens` | `int` | `None` | Maximum output token estimate |

---

## Custom Guards

### Using CustomGuard

Wrap any callable as a guard:

```python
from prela.guardrails import CustomGuard, GuardrailResult, GuardrailAction

def check_language(content: str, **kwargs) -> GuardrailResult:
    if "confidential" in content.lower():
        return GuardrailResult(
            action=GuardrailAction.BLOCK,
            guard_name="language_check",
            message="Confidential content detected",
        )
    return GuardrailResult(
        action=GuardrailAction.ALLOW,
        guard_name="language_check",
    )

guard = CustomGuard("language_check", input_fn=check_language)
```

### Extending BaseGuard

For more control, subclass `BaseGuard`:

```python
from prela.guardrails import BaseGuard, GuardrailAction, GuardrailResult

class DomainGuard(BaseGuard):
    @property
    def name(self) -> str:
        return "domain_check"

    def check_input(self, content: str, **kwargs) -> GuardrailResult:
        if "forbidden_domain.com" in content:
            return GuardrailResult(
                action=GuardrailAction.BLOCK,
                guard_name=self.name,
                message="Forbidden domain referenced",
            )
        return GuardrailResult(
            action=GuardrailAction.ALLOW,
            guard_name=self.name,
        )
```

---

## GuardrailRunner Configuration

```python
from prela.guardrails import GuardrailRunner, PIIGuard, InjectionGuard

# Default: raise GuardrailBlocked on block
runner = GuardrailRunner(on_block="raise")

# Or log and continue (don't raise exceptions)
runner = GuardrailRunner(on_block="log")

# Add a callback for any non-ALLOW result
def on_violation(result):
    print(f"Violation: {result.guard_name} - {result.message}")

runner = GuardrailRunner(on_violation=on_violation)

# Chain guards
runner.add(PIIGuard(action="redact")).add(InjectionGuard())
```

---

## Standalone Usage

You can use guardrails without `prela.init()` for manual checking:

```python
from prela.guardrails import GuardrailRunner, PIIGuard

runner = GuardrailRunner()
runner.add(PIIGuard(action="block"))

# Check input manually
results = runner.run_input("My email is john@example.com")
for r in results:
    if r.blocked:
        print(f"Blocked: {r.message}")

# Check output manually
results = runner.run_output(llm_response_text)
```

---

## Tracing Integration

When guardrails are integrated via `prela.init()`, results are automatically recorded on spans:

- `guardrails.input.count` -- Number of guards that ran on input
- `guardrails.input.blocked` -- Whether input was blocked
- `guardrails.input.blocked_by` -- Name of the guard that blocked
- `guardrails.input.modified` -- Whether input was modified
- `guardrails.output.count` / `guardrails.output.blocked` / etc. -- Same for output

Blocked events are also recorded as span events with the guard name and message.

---

## Backend API

The Prela dashboard provides guardrail configuration management and violation history:

- `POST /api/v1/guardrails/projects/{project_id}/configs` -- Create/update guard configuration
- `GET /api/v1/guardrails/projects/{project_id}/configs` -- List guard configurations
- `GET /api/v1/guardrails/projects/{project_id}/violations` -- Query violation history
- `POST /api/v1/guardrails/projects/{project_id}/violations` -- Report a violation

Violation history is stored in ClickHouse with 90-day retention.
