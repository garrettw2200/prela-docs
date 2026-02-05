# Installation

Install Prela using pip, the Python package manager.

---

## Requirements

- **Python**: 3.9 or higher
- **pip**: Latest version recommended

---

## Install via pip

```bash
pip install prela
```

This installs the core Prela SDK with zero dependencies.

---

## Optional Dependencies

Install with optional integrations:

### OpenAI

```bash
pip install prela[openai]
```

Includes: `openai>=1.0.0`

### Anthropic

```bash
pip install prela[anthropic]
```

Includes: `anthropic>=0.40.0`

### LangChain

```bash
pip install prela[langchain]
```

Includes: `langchain>=0.1.0`

### LlamaIndex

```bash
pip install prela[llamaindex]
```

Includes: `llama-index>=0.9.0`

### CrewAI

```bash
pip install prela[crewai]
```

Includes: `crewai>=0.30.0`

### AutoGen

```bash
pip install prela[autogen]
```

Includes: `autogen>=0.2.0`

### LangGraph

```bash
pip install prela[langgraph]
```

Includes: `langgraph>=0.0.20`

### Swarm

```bash
pip install prela[swarm]
```

Includes: `openai-swarm`

### All Integrations

```bash
pip install prela[all]
```

Includes all optional dependencies.

### Development

```bash
pip install prela[dev]
```

Includes testing and development tools:

- `pytest>=7.4.0`
- `pytest-asyncio>=0.21.0`
- `pytest-cov>=4.1.0`
- `black>=23.7.0`
- `ruff>=0.0.285`
- `mypy>=1.5.0`

---

## Verify Installation

Check that Prela is installed correctly:

```bash
python -c "import prela; print(prela.__version__)"
```

Expected output:

```
0.1.0
```

---

## Upgrade

Upgrade to the latest version:

```bash
pip install --upgrade prela
```

---

## Uninstall

Remove Prela:

```bash
pip uninstall prela
```

---

## Development Installation

For contributors, install from source:

```bash
# Clone SDK repository
git clone https://github.com/garrettw2200/prela-sdk.git
cd prela-sdk

# Install in editable mode with dev dependencies
pip install -e ".[dev,all]"

# Run tests
pytest
```

---

## Next Steps

- [Quick Start](quickstart.md) - Create your first trace
- [Configuration](configuration.md) - Configure Prela
