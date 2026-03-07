# Prompt Management

Prela provides versioned prompt templates with variable substitution, version history, and stage-based promotion. Manage prompts as first-class artifacts alongside your traces and evaluations.

---

## Quick Start

```python
from prela.prompts import PromptTemplate, PromptRegistry

# Create a prompt template
template = PromptTemplate(
    name="classify",
    template="Classify this text: {{text}}\nCategories: {{categories}}",
    model="claude-sonnet-4-20250514",
    tags=["classification", "production"],
)

# Render with variables
prompt = template.render(
    text="I love this product!",
    categories="positive, negative, neutral",
)
# => "Classify this text: I love this product!\nCategories: positive, negative, neutral"
```

---

## PromptTemplate

A versioned prompt template with `{{variable}}` syntax.

```python
from prela.prompts import PromptTemplate

template = PromptTemplate(
    name="summarize",
    template="Summarize the following in {{style}} style:\n\n{{content}}",
    model="claude-sonnet-4-20250514",
    tags=["summarization"],
    change_note="Initial version",
)

# Inspect variables
print(template.variables)  # ["style", "content"]

# Render
result = template.render(style="concise", content="Long article text...")
```

**Fields:**

| Field | Type | Default | Description |
|---|---|---|---|
| `name` | `str` | Required | Unique prompt name |
| `template` | `str` | Required | Template text with `{{variable}}` placeholders |
| `version` | `int` | `1` | Version number |
| `model` | `str` | `None` | Recommended model for this prompt |
| `tags` | `list[str]` | `[]` | Tags for organization |
| `metadata` | `dict` | `{}` | Arbitrary metadata |
| `change_note` | `str` | `""` | Description of what changed in this version |

Rendering raises `ValueError` if any required variables are missing.

---

## Versioning

Create new versions of a template while preserving history:

```python
# Start with v1
v1 = PromptTemplate(
    name="greet",
    template="Hello {{name}}!",
    change_note="Initial greeting",
)

# Create v2 with updated template
v2 = v1.new_version(
    template="Hi {{name}}, welcome to {{service}}!",
    change_note="Added service name, more casual tone",
)

print(v2.version)   # 2
print(v2.variables)  # ["name", "service"]
```

The `new_version()` method returns a new `PromptTemplate` with an incremented version number. The original template is unchanged.

---

## PromptRegistry

Manage multiple prompts with version tracking and stage promotion:

```python
from prela.prompts import PromptTemplate, PromptRegistry

registry = PromptRegistry()

# Register prompts
registry.register(PromptTemplate(
    name="greet",
    template="Hello {{name}}!",
))
registry.register(PromptTemplate(
    name="greet",
    template="Hi {{name}}, how can I help?",
    version=2,
    change_note="More conversational",
))

# Get latest version
latest = registry.get("greet")  # version 2

# Get specific version
v1 = registry.get("greet", version=1)

# View version history
for tmpl in registry.history("greet"):
    print(f"v{tmpl.version}: {tmpl.change_note}")
```

### Stage Promotion

Promote specific versions to deployment stages:

```python
# Promote v1 to production (safe, tested version)
registry.promote("greet", version=1, stage="production")

# Promote v2 to staging for testing
registry.promote("greet", version=2, stage="staging")

# Retrieve by stage
prod_prompt = registry.get("greet", stage="production")  # v1
staging_prompt = registry.get("greet", stage="staging")   # v2
```

Supported stages: `production`, `staging`, `canary` (or any custom string).

### Listing and Filtering

```python
# List all prompts (latest versions)
all_prompts = registry.list()

# Filter by tag
classification_prompts = registry.list(tag="classification")

# Check if a prompt exists
if "greet" in registry:
    print("Found!")

# Count total versions
print(len(registry))  # Total version count across all prompts
```

### Export and Import

Persist prompts or sync across environments:

```python
# Export all prompts to JSON-serializable format
data = registry.export_all()

# Import into another registry
new_registry = PromptRegistry()
count = new_registry.import_all(data)
print(f"Imported {count} prompt versions")
```

---

## Backend API

The Prela dashboard provides prompt management through the REST API:

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/v1/prompts/projects/{project_id}/prompts` | Create a prompt (v1) |
| `GET` | `/api/v1/prompts/projects/{project_id}/prompts` | List all prompts |
| `GET` | `/api/v1/prompts/projects/{project_id}/prompts/{name}` | Get latest version |
| `PUT` | `/api/v1/prompts/projects/{project_id}/prompts/{name}` | Create a new version |
| `DELETE` | `/api/v1/prompts/projects/{project_id}/prompts/{name}` | Delete a prompt |
| `GET` | `/api/v1/prompts/projects/{project_id}/prompts/{name}/history` | Get version history |
| `POST` | `/api/v1/prompts/projects/{project_id}/prompts/{name}/promote` | Promote to a stage |

### Example: Create and Promote

```bash
# Create a prompt
curl -X POST https://api.prela.dev/api/v1/prompts/projects/my-project/prompts \
  -H "Authorization: Bearer $PRELA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "classify",
    "template": "Classify: {{text}}\nCategories: {{categories}}",
    "model": "claude-sonnet-4-20250514",
    "tags": ["classification"]
  }'

# Create v2
curl -X PUT https://api.prela.dev/api/v1/prompts/projects/my-project/prompts/classify \
  -H "Authorization: Bearer $PRELA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "template": "You are a classifier. Classify: {{text}}\nUse categories: {{categories}}",
    "change_note": "Added system context"
  }'

# Promote v1 to production
curl -X POST https://api.prela.dev/api/v1/prompts/projects/my-project/prompts/classify/promote \
  -H "Authorization: Bearer $PRELA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"version": 1, "stage": "production"}'
```
