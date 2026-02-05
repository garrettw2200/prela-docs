# Running Evaluations

This guide covers how to execute evaluation suites, configure runners, and analyze results.

## Basic Execution

```python
from prela.evals import EvalSuite, EvalRunner

# Load suite
suite = EvalSuite.from_yaml("tests.yaml")

# Define agent
def my_agent(input_data):
    query = input_data.get("query", "")
    return f"Response to: {query}"

# Run
runner = EvalRunner(suite, my_agent)
result = runner.run()

# View results
print(result.summary())
```

## Sequential Execution

Default mode runs tests one at a time:

```python
runner = EvalRunner(suite, my_agent, parallel=False)
result = runner.run()
```

**Advantages:**
- Predictable order
- Easier debugging
- Lower resource usage

## Parallel Execution

Run tests concurrently for speed:

```python
runner = EvalRunner(
    suite=suite,
    agent_fn=my_agent,
    parallel=True,
    max_workers=4  # Number of parallel workers
)
result = runner.run()
```

**Advantages:**
- Faster execution
- Better resource utilization
- Scales with CPU cores

**Considerations:**
- Tests must be independent
- Higher memory usage
- Non-deterministic order

## With Tracer Integration

Capture execution traces:

```python
import prela

# Initialize tracer
tracer = prela.init(service_name="eval", exporter="console")

# Run with tracing
runner = EvalRunner(suite, my_agent, tracer=tracer)
result = runner.run()

# Each test execution captured as span
```

## Progress Callbacks

Monitor progress in real-time:

```python
def on_case_complete(case_result):
    status = "✓" if case_result.passed else "✗"
    print(f"{status} {case_result.case_name} ({case_result.duration_ms:.0f}ms)")

runner = EvalRunner(
    suite, my_agent,
    on_case_complete=on_case_complete
)
result = runner.run()
```

## Results

### EvalRunResult

```python
result = runner.run()

print(f"Total: {result.total}")
print(f"Passed: {result.passed}")
print(f"Failed: {result.failed}")
print(f"Pass Rate: {result.pass_rate:.1%}")
print(f"Duration: {result.duration_ms:.0f}ms")

# Individual cases
for case_result in result.case_results:
    print(f"{case_result.case_name}: {case_result.passed}")
```

### Summary Output

```python
print(result.summary())
# Evaluation Suite: My Tests
# Total Cases: 10
# Passed: 8 (80.0%)
# Failed: 2 (20.0%)
#
# Case Results:
#   ✓ test_1 (123ms)
#   ✓ test_2 (456ms)
#   ✗ test_3 (789ms)
#     - Assertion failed: Expected to contain 'result'
```

## Reporting

### Console Reporter

```python
from prela.evals.reporters import ConsoleReporter

# Minimal output
ConsoleReporter(verbosity="minimal").report(result)

# Normal output (default)
ConsoleReporter(verbosity="normal").report(result)

# Verbose output
ConsoleReporter(verbosity="verbose").report(result)
```

### JSON Reporter

```python
from prela.evals.reporters import JSONReporter

JSONReporter("results.json").report(result)

# Pretty print
JSONReporter("results.json", indent=2).report(result)
```

### JUnit Reporter

```python
from prela.evals.reporters import JUnitReporter

JUnitReporter("junit.xml").report(result)
```

### Multiple Reporters

```python
reporters = [
    ConsoleReporter(verbosity="normal"),
    JSONReporter("results.json"),
    JUnitReporter("junit.xml")
]

for reporter in reporters:
    reporter.report(result)
```

## CLI Usage

```bash
# Basic run
prela eval run tests.yaml --agent agent.py

# With specific format
prela eval run tests.yaml --agent agent.py --format junit --output results.xml

# Parallel execution
prela eval run tests.yaml --agent agent.py --parallel --workers 8

# With tracer
prela eval run tests.yaml --agent agent.py --trace --exporter console
```

## Best Practices

### 1. Use Parallel for Large Suites

```python
# Small suite (<10 tests): sequential
runner = EvalRunner(suite, agent, parallel=False)

# Large suite (>50 tests): parallel
runner = EvalRunner(suite, agent, parallel=True, max_workers=8)
```

### 2. Monitor Progress

```python
def progress(case_result):
    print(f"[{datetime.now()}] Completed: {case_result.case_name}")

runner = EvalRunner(suite, agent, on_case_complete=progress)
```

### 3. Save Results

```python
result = runner.run()

# Save for analysis
JSONReporter("results/eval_{datetime.now().isoformat()}.json").report(result)
```

### 4. Handle Failures

```python
result = runner.run()

if result.failed > 0:
    print(f"⚠️ {result.failed} test(s) failed")

    for case_result in result.case_results:
        if not case_result.passed:
            print(f"\nFailed: {case_result.case_name}")
            for assertion_result in case_result.assertion_results:
                if not assertion_result.passed:
                    print(f"  - {assertion_result.message}")
```

## Next Steps

- See [CI Integration](ci-integration.md) for automation
- Learn [Writing Tests](writing-tests.md)
- Explore [Assertions](assertions.md)
