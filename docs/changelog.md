# Changelog

All notable changes to Prela will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **Repository Split**: SDK moved to separate repository at [github.com/garrettw2200/prela-sdk](https://github.com/garrettw2200/prela-sdk)
- **PyPI Publication**: SDK now available on PyPI at [pypi.org/project/prela](https://pypi.org/project/prela/)
- **Installation**: Primary installation method is now `pip install prela`

### Added
- **Production Validation** (Phase 6):
  - 21/21 core features validated with real API calls
  - 6 production test scenarios with complete validation evidence
  - Performance validation: SDK overhead <5%, CLI response <1s
  - Documentation validation: All scenarios documented with expected outputs
  - Test scenarios copied to examples directory with comprehensive README
- Comprehensive documentation site
- Production deployment examples
- Multi-environment configuration guides

## [0.2.0] - 2025-01-26

### Added
- **Evaluation Framework**: Complete testing framework for AI agents
  - EvalCase and EvalSuite for test definition
  - 10 assertion types (structural, tool, semantic)
  - EvalRunner with sequential and parallel execution
  - Three reporters: Console, JSON, JUnit
  - YAML/JSON test suite support
  - CI/CD integration guides
- **CLI Tool**: Command-line interface for trace management
  - `prela init` - Initialize new projects
  - `prela list` - List available traces
  - `prela show` - Display specific traces
  - `prela search` - Search traces by attributes
  - `prela eval run` - Run evaluation suites
  - `prela export` - Export traces to different formats
- **Enhanced FileExporter**:
  - Tree-based directory structure (by service/date)
  - Trace search and filtering
  - File rotation by size
  - Improved organization
- **Enhanced ConsoleExporter**:
  - Three verbosity levels (minimal, normal, verbose)
  - Colored output with rich library support
  - Tree visualization for nested spans
  - Configurable formatting

### Changed
- ConsoleExporter API: Changed `quiet` parameter to `verbosity`
- FileExporter API: Changed from single file to directory-based organization

### Fixed
- Context propagation in thread pools
- Timing precision in latency assertions

## [0.1.0] - 2025-01-20

### Added
- **Core Tracing**: Complete span and context system
  - Span class with immutability after end()
  - SpanType enum (AGENT, LLM, TOOL, RETRIEVAL, EMBEDDING, CUSTOM)
  - SpanStatus enum (PENDING, SUCCESS, ERROR)
  - SpanEvent for timestamped occurrences
  - High-resolution clock utilities
  - Thread-safe and async-safe context propagation
- **Tracer**: Main orchestration class
  - Context manager interface for spans
  - Automatic parent-child linking
  - Global tracer management
  - Service name injection
- **Sampling**: Four sampling strategies
  - AlwaysOnSampler (development)
  - AlwaysOffSampler (disable tracing)
  - ProbabilitySampler (probabilistic sampling)
  - RateLimitingSampler (token bucket rate limiting)
- **Exporters**: Base export system
  - BaseExporter abstract class
  - BatchExporter with retry logic
  - ConsoleExporter for development
  - FileExporter for production (JSONL format)
  - Exponential backoff retry
- **Auto-Instrumentation**: Automatic SDK tracing
  - OpenAI SDK support (chat, completions, embeddings)
  - Anthropic SDK support (messages, streaming, tools)
  - LangChain integration (chains, agents, tools)
  - Auto-discovery and registration
- **Public API**: Simple initialization
  - `prela.init()` - One-line setup
  - `prela.get_tracer()` - Access global tracer
  - `prela.auto_instrument()` - Manual instrumentation
  - Environment variable support

### Features
- **OpenAI Instrumentation**:
  - Sync and async chat completions
  - Streaming responses
  - Function/tool calling
  - Embeddings API
  - Legacy completions
  - Token usage tracking
  - Error capturing
- **Anthropic Instrumentation**:
  - Sync and async messages
  - Streaming responses
  - Tool use detection
  - Extended thinking capture
  - Token usage tracking
  - Error capturing
- **LangChain Instrumentation**:
  - Chain executions (LLMChain, SequentialChain)
  - Agent workflows
  - Tool invocations
  - Retriever queries
  - Callback-based integration

### Performance
- `__slots__` for memory efficiency
- Lazy serialization
- Minimal overhead (<100μs per span)
- Thread-safe by design
- Async-compatible

### Testing
- 573 comprehensive tests
- 95%+ code coverage
- Unit, integration, and edge case tests
- Thread safety validation
- Async support validation

## [0.0.1] - 2025-01-15

### Added
- Initial project structure
- Basic span implementation (prototype)
- Proof of concept

---

## Version History

- **0.2.0**: Evaluation framework, CLI tool, enhanced exporters
- **0.1.0**: Core tracing, auto-instrumentation, public API
- **0.0.1**: Initial prototype

## Migration Guides

### Migrating from 0.1.0 to 0.2.0

#### ConsoleExporter Changes

```python
# Old (0.1.0)
ConsoleExporter(quiet=False)

# New (0.2.0)
ConsoleExporter(verbosity="normal")  # or "minimal", "verbose"
```

#### FileExporter Changes

```python
# Old (0.1.0)
FileExporter(file_path="traces.jsonl")

# New (0.2.0)
FileExporter(directory="./traces")  # Organized by service/date
```

## Deprecation Notices

None currently.

## Security

For security vulnerabilities, please email security@prela.dev instead of using the issue tracker.

## Links

- [Documentation](https://docs.prela.dev)
- [GitHub Repository](https://github.com/garrettw2200/prela-sdk)
- [PyPI Package](https://pypi.org/project/prela/)
- [GitHub Discussions](https://github.com/garrettw2200/prela-sdk/discussions)
- [Discord Community](https://discord.gg/bCMfHnZD)

[Unreleased]: https://github.com/garrettw2200/prela-sdk/compare/v0.1.0...HEAD
[0.2.0]: https://github.com/garrettw2200/prela-sdk/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/garrettw2200/prela-sdk/releases/tag/v0.1.0
[0.0.1]: https://github.com/garrettw2200/prela-sdk/releases/tag/v0.0.1
