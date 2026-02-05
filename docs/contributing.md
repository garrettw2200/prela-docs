# Contributing to Prela

Thank you for your interest in contributing to Prela! This guide will help you get started.

## Development Setup

### Prerequisites

- Python 3.9+
- Git
- pip and virtualenv

### Clone the Repository

```bash
git clone https://github.com/garrettw2200/prela-sdk.git
cd prela-sdk
```

### Setup Development Environment

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -e ".[dev,all]"
```

### Run Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=prela --cov-report=html

# Run specific test file
pytest tests/test_span.py

# Run specific test
pytest tests/test_span.py::test_span_creation
```

## Code Quality

### Formatting

We use `black` for code formatting:

```bash
# Format all files
black prela tests

# Check formatting
black --check prela tests
```

### Linting

We use `ruff` for linting:

```bash
# Lint code
ruff check prela tests

# Auto-fix issues
ruff check --fix prela tests
```

### Type Checking

We use `mypy` for type checking:

```bash
# Type check
mypy prela
```

## Making Changes

### Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### Commit Guidelines

Use conventional commit messages:

```
feat: add support for custom exporters
fix: resolve context propagation in thread pools
docs: update installation guide
test: add tests for span serialization
refactor: simplify sampler interface
```

### Write Tests

All new features and bug fixes should include tests:

```python
# tests/test_your_feature.py
import pytest
from prela import Span, SpanType

def test_your_feature():
    """Test description."""
    span = Span(name="test", span_type=SpanType.CUSTOM)
    # Test assertions
    assert span.name == "test"
```

### Update Documentation

Update relevant documentation:

- API docstrings
- Usage examples
- README updates
- Migration guides (if breaking changes)

## Pull Request Process

### Before Submitting

1. Run all tests: `pytest`
2. Check coverage: `pytest --cov=prela`
3. Format code: `black prela tests`
4. Lint code: `ruff check prela tests`
5. Type check: `mypy prela`
6. Update CHANGELOG.md

### Submitting PR

1. Push your branch to GitHub
2. Create a pull request
3. Fill out the PR template
4. Link related issues
5. Request review

### PR Checklist

- [ ] Tests pass
- [ ] Code coverage maintained/improved
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Commit messages follow conventions
- [ ] Code formatted with black
- [ ] No linting errors
- [ ] Type hints added

## Development Guidelines

### Code Style

- Use type hints for all functions
- Write docstrings in Google style
- Keep functions focused and small
- Prefer composition over inheritance

### Testing

- Aim for 100% test coverage
- Test edge cases
- Test error handling
- Use descriptive test names

### Documentation

- Document all public APIs
- Include usage examples
- Keep docs up to date
- Use clear, concise language

## Project Structure

```
prela-sdk/
├── prela/              # Source code
│   ├── core/           # Core tracing
│   ├── exporters/      # Export backends
│   ├── instrumentation/  # Auto-instrumentation
│   ├── evals/          # Evaluation framework
│   └── contrib/        # CLI and extras
├── tests/              # Test suite
├── examples/           # Example scripts
├── docs/               # Documentation
└── .github/            # GitHub workflows
```

## Release Process

Maintainers will handle releases. Process:

1. Update version in `_version.py`
2. Update CHANGELOG.md
3. Create git tag
4. Build package: `python -m build`
5. Publish to PyPI: `twine upload dist/*`

## Getting Help

- 💬 [Discord Community](https://discord.gg/bCMfHnZD)
- 🐛 [GitHub Issues](https://github.com/garrettw2200/prela-sdk/issues)
- 💡 [GitHub Discussions](https://github.com/garrettw2200/prela-sdk/discussions)

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Personal or political attacks
- Publishing others' private information

### Enforcement

Violations may result in temporary or permanent ban from project participation.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be recognized in:

- CONTRIBUTORS.md
- Release notes
- Documentation credits

## Thank You!

Your contributions make Prela better for everyone. Thank you for being part of our community!
