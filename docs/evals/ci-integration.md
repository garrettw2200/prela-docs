# CI/CD Integration

Integrate Prela evaluations into your continuous integration pipeline for automated testing.

## GitHub Actions

```yaml
name: Run Evaluations

on: [push, pull_request]

jobs:
  evaluate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-python@v4
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          pip install prela anthropic openai
          pip install -r requirements.txt

      - name: Run evaluations
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          prela eval run tests/eval_suite.yaml \
            --agent src/agent.py \
            --format junit \
            --output results/junit.xml

      - name: Publish test results
        uses: EnricoMi/publish-unit-test-result-action@v2
        if: always()
        with:
          files: results/junit.xml

      - name: Upload results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: eval-results
          path: results/
```

## GitLab CI

```yaml
test:
  image: python:3.10
  stage: test

  before_script:
    - pip install prela anthropic openai

  script:
    - prela eval run tests/eval_suite.yaml --agent src/agent.py --format junit --output junit.xml

  artifacts:
    when: always
    reports:
      junit: junit.xml
    paths:
      - junit.xml

  variables:
    ANTHROPIC_API_KEY: $ANTHROPIC_API_KEY
    OPENAI_API_KEY: $OPENAI_API_KEY
```

## CircleCI

```yaml
version: 2.1

jobs:
  evaluate:
    docker:
      - image: cimg/python:3.10

    steps:
      - checkout

      - run:
          name: Install dependencies
          command: pip install prela anthropic openai

      - run:
          name: Run evaluations
          command: |
            prela eval run tests/eval_suite.yaml \
              --agent src/agent.py \
              --format junit \
              --output results/junit.xml

      - store_test_results:
          path: results/

      - store_artifacts:
          path: results/

workflows:
  test:
    jobs:
      - evaluate
```

## Jenkins

```groovy
pipeline {
    agent any

    stages {
        stage('Setup') {
            steps {
                sh 'pip install prela anthropic openai'
            }
        }

        stage('Evaluate') {
            steps {
                sh '''
                    prela eval run tests/eval_suite.yaml \
                      --agent src/agent.py \
                      --format junit \
                      --output results/junit.xml
                '''
            }
        }
    }

    post {
        always {
            junit 'results/junit.xml'
            archiveArtifacts artifacts: 'results/**', allowEmptyArchive: true
        }
    }
}
```

## Azure Pipelines

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: UsePythonVersion@0
    inputs:
      versionSpec: '3.10'

  - script: |
      pip install prela anthropic openai
    displayName: 'Install dependencies'

  - script: |
      prela eval run tests/eval_suite.yaml \
        --agent src/agent.py \
        --format junit \
        --output $(Build.ArtifactStagingDirectory)/junit.xml
    displayName: 'Run evaluations'
    env:
      ANTHROPIC_API_KEY: $(ANTHROPIC_API_KEY)
      OPENAI_API_KEY: $(OPENAI_API_KEY)

  - task: PublishTestResults@2
    inputs:
      testResultsFiles: '$(Build.ArtifactStagingDirectory)/junit.xml'
      failTaskOnFailedTests: true

  - task: PublishBuildArtifacts@1
    inputs:
      pathToPublish: '$(Build.ArtifactStagingDirectory)'
      artifactName: 'eval-results'
```

## Best Practices

### 1. Use Secrets for API Keys

```yaml
# GitHub Actions
env:
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

# GitLab CI
variables:
  ANTHROPIC_API_KEY: $ANTHROPIC_API_KEY

# CircleCI (in Project Settings)
```

### 2. Fail CI on Test Failures

```python
# In agent code or CI script
result = runner.run()
if result.pass_rate < 1.0:
    sys.exit(1)  # Non-zero exit code fails CI
```

### 3. Store Results as Artifacts

```yaml
# GitHub Actions
- uses: actions/upload-artifact@v3
  with:
    name: eval-results
    path: results/
```

### 4. Run on Pull Requests

```yaml
on:
  pull_request:
    branches: [main, develop]
```

### 5. Cache Dependencies

```yaml
- uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
```

## Example Python Script

```python
# run_evals.py
import sys
from prela.evals import EvalSuite, EvalRunner
from prela.evals.reporters import JUnitReporter, ConsoleReporter

def my_agent(input_data):
    # Your agent implementation
    pass

def main():
    # Load suite
    suite = EvalSuite.from_yaml("tests/eval_suite.yaml")

    # Run evaluations
    runner = EvalRunner(suite, my_agent, parallel=True)
    result = runner.run()

    # Report results
    ConsoleReporter(verbosity="verbose").report(result)
    JUnitReporter("results/junit.xml").report(result)

    # Exit with appropriate code
    if result.pass_rate < 1.0:
        print(f"❌ {result.failed} test(s) failed")
        sys.exit(1)
    else:
        print(f"✅ All {result.total} tests passed")
        sys.exit(0)

if __name__ == "__main__":
    main()
```

Use in CI:

```bash
python run_evals.py
```

## Next Steps

- See [Running Evaluations](running.md)
- Learn [Writing Tests](writing-tests.md)
- Explore [GitHub Actions Examples](https://github.com/prela/prela/tree/main/.github/workflows)
