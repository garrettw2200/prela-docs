# Prela

**AI Agent Observability Platform**

Prela is an open-source observability platform designed specifically for AI agents. Monitor, debug, and optimize your autonomous AI systems with comprehensive tracing, metrics, and analytics.

## Features

- **Agent Tracing**: Track every decision, tool call, and action your AI agents take
- **Performance Metrics**: Monitor latency, token usage, and success rates
- **Error Detection**: Catch and diagnose agent failures before they impact users
- **Multi-Framework Support**: Works with LangChain, OpenAI, Anthropic, and custom agents
- **Real-time Dashboard**: Visualize agent behavior and performance in real-time
- **API & SDK**: Easy integration with Python and TypeScript

## Quick Start

### Install the SDK

```bash
pip install prela
```

### Basic Usage

```python
import prela

# Initialize with console output
prela.init(service_name="my-agent", exporter="console")

# Your AI agent code here - automatically traced!
from openai import OpenAI
client = OpenAI()
response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

## Repositories

Prela is organized into multiple repositories:

- **[prela-sdk](https://github.com/garrettw2200/prela-sdk)** - Python SDK ([PyPI](https://pypi.org/project/prela/)) - ✅ **NOW AVAILABLE**
- **prela-backend** - Cloud services (Private) - Coming soon
- **prela-frontend** - Dashboard (Private) - Coming soon
- **prela-n8n-node** - N8N integration (Public) - Coming soon

## Repository Structure

```
prela/
├── sdk/                    # Python SDK → Moved to separate repo
├── backend/                # Cloud services
├── frontend/               # React dashboard
├── docs/                   # Documentation
└── internal/               # Internal planning docs (not on GitHub)
```

## Development

### Prerequisites

- Python 3.9+
- Node.js 18+
- Docker & Docker Compose

### Setup

```bash
# Install SDK from PyPI
pip install prela[all]

# Or for SDK development, clone the separate repository
git clone https://github.com/garrettw2200/prela-sdk.git
cd prela-sdk
pip install -e ".[dev,all]"

# Start backend services (from monorepo)
cd backend
make dev

# Start frontend (from monorepo)
cd frontend
npm install
npm run dev
```

### Running Tests

```bash
# SDK tests (from separate repository)
git clone https://github.com/garrettw2200/prela-sdk.git
cd prela-sdk
pytest

# Backend tests (from monorepo)
cd backend
make test

# Frontend tests (from monorepo)
cd frontend
npm test
```

## Documentation

Full documentation is available at [https://prela.readthedocs.io](https://prela.readthedocs.io)

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

- **SDK**: Apache 2.0 License
- **Backend & Frontend**: Proprietary (Cloud services)

## Support

- SDK Issues: [https://github.com/garrettw2200/prela-sdk/issues](https://github.com/garrettw2200/prela-sdk/issues)
- SDK Discussions: [https://github.com/garrettw2200/prela-sdk/discussions](https://github.com/garrettw2200/prela-sdk/discussions)
- Documentation: [https://docs.prela.dev](https://docs.prela.dev)
- Discord: [https://discord.gg/bCMfHnZD](https://discord.gg/bCMfHnZD)

---

Built with love by the Prela team
