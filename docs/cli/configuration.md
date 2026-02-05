# CLI Configuration

Configure the Prela CLI using configuration files and environment variables.

## Configuration File

Create `.prela.yaml` in your project root:

```yaml
# .prela.yaml
service_name: my-agent
trace_directory: ./traces
exporter: file
sample_rate: 1.0
auto_instrument: true
debug: false

# File exporter options
file_exporter:
  max_file_size_mb: 100
  rotate: true

# Console exporter options
console_exporter:
  verbosity: normal
  color: true
  show_timestamps: true
```

## Environment Variables

Override config with environment variables:

```bash
export PRELA_SERVICE_NAME=my-agent
export PRELA_TRACE_DIR=./traces
export PRELA_EXPORTER=file
export PRELA_SAMPLE_RATE=1.0
export PRELA_AUTO_INSTRUMENT=true
export PRELA_DEBUG=false
```

## Precedence

1. CLI options (highest priority)
2. Environment variables
3. Configuration file
4. Defaults (lowest priority)

## Example Configurations

### Development

```yaml
# .prela.dev.yaml
service_name: dev-agent
exporter: console
sample_rate: 1.0
console_exporter:
  verbosity: verbose
  color: true
debug: true
```

### Production

```yaml
# .prela.prod.yaml
service_name: prod-agent
trace_directory: /var/log/traces
exporter: file
sample_rate: 0.1
file_exporter:
  max_file_size_mb: 500
  rotate: true
auto_instrument: true
debug: false
```

### Testing

```yaml
# .prela.test.yaml
service_name: test-agent
exporter: console
sample_rate: 1.0
console_exporter:
  verbosity: minimal
```

## Loading Custom Config

```bash
# Use specific config file
PRELA_CONFIG=.prela.prod.yaml prela list
```

## Next Steps

- See [Commands](commands.md)
- Learn about [Exporters](../concepts/exporters.md)
