# Evaluations API

Framework for testing and evaluating AI agent behavior.

## Test Case Definition

### EvalInput

::: prela.evals.case.EvalInput
    options:
      show_source: false
      show_root_heading: true

### EvalExpected

::: prela.evals.case.EvalExpected
    options:
      show_source: false
      show_root_heading: true

### EvalCase

::: prela.evals.case.EvalCase
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - to_dict
        - from_dict

## Test Suite

### EvalSuite

::: prela.evals.suite.EvalSuite
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - add_case
        - filter_by_tags
        - to_yaml
        - from_yaml
        - to_json
        - from_json

## Test Execution

### EvalRunner

::: prela.evals.runner.EvalRunner
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - run
        - run_case

### CaseResult

::: prela.evals.runner.CaseResult
    options:
      show_source: false
      show_root_heading: true

### EvalRunResult

::: prela.evals.runner.EvalRunResult
    options:
      show_source: false
      show_root_heading: true
      members:
        - summary

### create_assertion

::: prela.evals.runner.create_assertion
    options:
      show_source: false

## Assertions

### Base Assertion

::: prela.evals.assertions.base.BaseAssertion
    options:
      show_source: false
      show_root_heading: true
      members:
        - evaluate
        - from_config

::: prela.evals.assertions.base.AssertionResult
    options:
      show_source: false
      show_root_heading: true

### Structural Assertions

::: prela.evals.assertions.structural.ContainsAssertion
    options:
      show_source: false
      show_root_heading: true

::: prela.evals.assertions.structural.NotContainsAssertion
    options:
      show_source: false
      show_root_heading: true

::: prela.evals.assertions.structural.RegexAssertion
    options:
      show_source: false
      show_root_heading: true

::: prela.evals.assertions.structural.LengthAssertion
    options:
      show_source: false
      show_root_heading: true

::: prela.evals.assertions.structural.JSONValidAssertion
    options:
      show_source: false
      show_root_heading: true

### Tool Assertions

::: prela.evals.assertions.tool.ToolCalledAssertion
    options:
      show_source: false
      show_root_heading: true

::: prela.evals.assertions.tool.ToolArgsAssertion
    options:
      show_source: false
      show_root_heading: true

::: prela.evals.assertions.tool.ToolSequenceAssertion
    options:
      show_source: false
      show_root_heading: true

### Semantic Assertions

::: prela.evals.assertions.semantic.SemanticSimilarityAssertion
    options:
      show_source: false
      show_root_heading: true

## Reporters

### ConsoleReporter

::: prela.evals.reporters.console.ConsoleReporter
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - report

### JSONReporter

::: prela.evals.reporters.json.JSONReporter
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - report

### JUnitReporter

::: prela.evals.reporters.junit.JUnitReporter
    options:
      show_source: false
      show_root_heading: true
      members:
        - __init__
        - report
