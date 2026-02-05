# CLI Commands

Prela provides a command-line interface for managing traces and running evaluations.

## Installation

The CLI is included with Prela:

```bash
pip install prela
prela --help
```

## Global Options

```bash
prela --version          # Show version
prela --help             # Show help
prela COMMAND --help     # Command-specific help
```

## Commands

### init

Initialize Prela in a new project.

```bash
prela init [--service-name NAME] [--exporter TYPE]
```

**Options:**
- `--service-name`: Service name (default: directory name)
- `--exporter`: Exporter type (console, file)

**Example:**
```bash
prela init --service-name my-agent --exporter file
```

### list

List available traces.

```bash
prela list [--directory DIR] [--service NAME] [--date DATE] [--limit N]
```

**Options:**
- `--directory`: Traces directory (default: ./traces)
- `--service`: Filter by service name
- `--date`: Filter by date (YYYY-MM-DD)
- `--limit`: Max results (default: 20)

**Example:**
```bash
prela list --service my-agent --date 2025-01-26
```

### show

Display a specific trace.

```bash
prela show TRACE_ID [--directory DIR] [--format FORMAT]
```

**Options:**
- `--directory`: Traces directory
- `--format`: Output format (json, tree, default: tree)

**Example:**
```bash
prela show 550e8400-e29b-41d4-a716-446655440000
prela show 550e8400-e29b-41d4-a716-446655440000 --format json
```

### search

Search traces by attributes.

```bash
prela search [--directory DIR] [--service NAME] [--status STATUS] [--type TYPE] [--date DATE] [--limit N]
```

**Options:**
- `--directory`: Traces directory
- `--service`: Service name
- `--status`: Span status (success, error, pending)
- `--type`: Span type (agent, llm, tool, etc.)
- `--date`: Date (YYYY-MM-DD)
- `--limit`: Max results (default: 20)

**Example:**
```bash
prela search --service my-agent --status error --type llm
```

### eval run

Run evaluation suite.

```bash
prela eval run SUITE_FILE --agent AGENT_FILE [OPTIONS]
```

**Options:**
- `--agent`: Path to agent module
- `--format`: Output format (console, json, junit, default: console)
- `--output`: Output file path
- `--parallel`: Enable parallel execution
- `--workers N`: Number of parallel workers (default: 4)
- `--trace`: Enable tracing
- `--exporter`: Trace exporter (console, file)

**Example:**
```bash
prela eval run tests.yaml --agent agent.py
prela eval run tests.yaml --agent agent.py --parallel --workers 8
prela eval run tests.yaml --agent agent.py --format junit --output results.xml
```

### export

Export traces to different formats.

```bash
prela export [--directory DIR] [--output FILE] [--format FORMAT] [--service NAME] [--date DATE]
```

**Options:**
- `--directory`: Traces directory
- `--output`: Output file
- `--format`: Format (json, jsonl, csv)
- `--service`: Filter by service
- `--date`: Filter by date

**Example:**
```bash
prela export --service my-agent --date 2025-01-26 --output export.json
```

### replay

Replay captured traces with modifications for testing and debugging.

```bash
prela replay TRACE_FILE [OPTIONS]
```

**Options:**
- `--model`: Override model (e.g., gpt-4o, claude-sonnet-4)
- `--temperature`: Override temperature
- `--max-tokens`: Override max tokens
- `--compare`: Compare with original execution
- `--stream`: Enable streaming output
- `--enable-tools`: Enable tool re-execution
- `--enable-retrieval`: Enable retrieval re-execution
- `--format`: Output format (json, tree, default: tree)

**Examples:**

Basic replay with different model:
```bash
prela replay trace.json --model gpt-4o
```

Replay with comparison:
```bash
prela replay trace.json --model claude-sonnet-4 --compare
```

Replay with streaming:
```bash
prela replay trace.json --model gpt-4o --stream
```

Replay with tool execution:
```bash
prela replay trace.json --enable-tools --compare
```

**See also:**
- [Replay Concepts](../concepts/replay.md)
- [Replay Examples](../examples/replay.md)

## Configuration File

Create `.prela.yaml` for defaults:

```yaml
# .prela.yaml
service_name: my-agent
trace_directory: ./traces
exporter: file
sample_rate: 1.0
```

CLI options override config file.

## Next Steps

- See [Configuration](configuration.md)
- Learn about [Exporters](../concepts/exporters.md)
