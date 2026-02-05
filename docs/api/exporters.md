# Exporters API

Exporters send trace data to various backends for storage and analysis.

## Base Exporter

::: prela.exporters.base.BaseExporter
    options:
      show_source: false
      show_root_heading: true
      members:
        - export
        - shutdown

## BatchExporter

::: prela.exporters.base.BatchExporter
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - export
        - shutdown
        - _do_export

## ExportResult

::: prela.exporters.base.ExportResult
    options:
      show_source: false
      show_root_heading: true

## Console Exporter

::: prela.exporters.console.ConsoleExporter
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - export

## File Exporter

::: prela.exporters.file.FileExporter
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - export
        - shutdown
        - list_traces
        - get_trace
        - search_traces
        - cleanup_old_traces
