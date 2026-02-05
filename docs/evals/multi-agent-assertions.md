# Multi-Agent Assertions

Prela provides specialized assertion types for testing multi-agent system behaviors. These assertions work across all supported multi-agent frameworks: CrewAI, AutoGen, LangGraph, and Swarm.

## Overview

Multi-agent assertions validate behaviors like:

- Agent participation and invocation
- Task completion and delegation
- Agent-to-agent handoffs
- Conversation flow and turn management
- Circular delegation detection

All assertions operate on trace data captured during multi-agent execution, providing systematic testing without framework-specific code.

## Available Assertions

### AgentUsedAssertion

Verifies that a specific agent was invoked during execution with a minimum number of invocations.

**Parameters:**
- `agent_name` (str): Name of the agent to check
- `min_invocations` (int): Minimum expected invocations (default: 1)

**Works with:** CrewAI, AutoGen, LangGraph, Swarm

**Example:**
```python
from prela.evals.assertions import AgentUsedAssertion

assertion = AgentUsedAssertion(agent_name="Researcher", min_invocations=1)
```

**Use cases:**
- Verify an agent participated in the workflow
- Ensure critical agents were invoked
- Validate agent usage in multi-agent scenarios

---

### TaskCompletedAssertion

Verifies that a specific task completed successfully, optionally matching task description.

**Parameters:**
- `task_description` (str): Task description to match (partial match)
- `exact_match` (bool): Whether to require exact description match (default: False)

**Works with:** CrewAI, AutoGen

**Example:**
```python
from prela.evals.assertions import TaskCompletedAssertion

assertion = TaskCompletedAssertion(
    task_description="Research AI trends",
    exact_match=False
)
```

**Use cases:**
- Verify task execution in CrewAI workflows
- Ensure critical tasks completed
- Validate task orchestration

---

### DelegationOccurredAssertion

Verifies agent-to-agent delegation occurred in task-based multi-agent systems.

**Parameters:**
- `from_agent` (str | None): Delegating agent name (None = any)
- `to_agent` (str | None): Receiving agent name (None = any)

**Works with:** CrewAI

**Example:**
```python
from prela.evals.assertions import DelegationOccurredAssertion

# Specific delegation
assertion = DelegationOccurredAssertion(
    from_agent="Manager",
    to_agent="Researcher"
)

# Any delegation to Researcher
assertion = DelegationOccurredAssertion(
    from_agent=None,
    to_agent="Researcher"
)
```

**Use cases:**
- Verify delegation flow in CrewAI
- Ensure managers delegate to workers
- Validate task assignment patterns

---

### HandoffOccurredAssertion

Verifies agent handoffs occurred in handoff-based multi-agent systems (Swarm).

**Parameters:**
- `from_agent` (str | None): Initial agent name (None = any)
- `to_agent` (str | None): Final agent name (None = any)

**Works with:** Swarm

**Example:**
```python
from prela.evals.assertions import HandoffOccurredAssertion

# Specific handoff
assertion = HandoffOccurredAssertion(
    from_agent="Triage",
    to_agent="Billing"
)

# Any handoff to Billing
assertion = HandoffOccurredAssertion(
    from_agent=None,
    to_agent="Billing"
)
```

**Use cases:**
- Verify handoff routing in Swarm
- Ensure agents transfer control correctly
- Validate agent switching logic

---

### AgentCollaborationAssertion

Verifies that a minimum number of unique agents participated in the execution.

**Parameters:**
- `min_agents` (int): Minimum expected unique agents

**Works with:** CrewAI, AutoGen, LangGraph, Swarm

**Example:**
```python
from prela.evals.assertions import AgentCollaborationAssertion

assertion = AgentCollaborationAssertion(min_agents=3)
```

**Use cases:**
- Verify multi-agent collaboration
- Ensure minimum agent participation
- Validate team-based workflows

---

### ConversationTurnsAssertion

Verifies that a conversation had a specific number of turns (message exchanges).

**Parameters:**
- `min_turns` (int | None): Minimum expected turns (default: None)
- `max_turns` (int | None): Maximum expected turns (default: None)

**Works with:** AutoGen

**Example:**
```python
from prela.evals.assertions import ConversationTurnsAssertion

# Exact range
assertion = ConversationTurnsAssertion(min_turns=3, max_turns=10)

# At least N turns
assertion = ConversationTurnsAssertion(min_turns=5, max_turns=None)
```

**Use cases:**
- Verify conversation length in AutoGen
- Ensure conversations don't exceed limits
- Validate termination conditions

---

### NoCircularDelegationAssertion

Detects circular delegation loops using depth-first search (DFS) on the delegation graph.

**Parameters:**
- None

**Works with:** CrewAI, AutoGen, LangGraph, Swarm

**Example:**
```python
from prela.evals.assertions import NoCircularDelegationAssertion

assertion = NoCircularDelegationAssertion()
```

**Use cases:**
- Prevent infinite delegation loops
- Ensure proper termination
- Validate delegation graph structure

**Algorithm:**
- Builds delegation graph from trace events
- Performs DFS to detect cycles
- Returns list of detected cycles (agent names)

---

## Complete Example

Here's a complete test case using multiple multi-agent assertions:

```python
from prela.evals import EvalCase, EvalInput, EvalRunner, EvalSuite
from prela.evals.assertions import (
    AgentCollaborationAssertion,
    AgentUsedAssertion,
    DelegationOccurredAssertion,
    NoCircularDelegationAssertion,
    TaskCompletedAssertion,
)

# Define test case
test_case = EvalCase(
    id="test_research_workflow",
    name="Research workflow with delegation",
    input=EvalInput(query="Research AI agent trends and write summary"),
    assertions=[
        # Verify all agents participated
        AgentUsedAssertion(agent_name="Manager", min_invocations=1),
        AgentUsedAssertion(agent_name="Researcher", min_invocations=1),
        AgentUsedAssertion(agent_name="Writer", min_invocations=1),

        # Verify task completion
        TaskCompletedAssertion(task_description="Research AI trends"),
        TaskCompletedAssertion(task_description="Write summary"),

        # Verify delegation flow
        DelegationOccurredAssertion(
            from_agent="Manager",
            to_agent="Researcher"
        ),
        DelegationOccurredAssertion(
            from_agent="Manager",
            to_agent="Writer"
        ),

        # Verify collaboration
        AgentCollaborationAssertion(min_agents=3),

        # Ensure no circular delegation
        NoCircularDelegationAssertion(),
    ]
)

# Create suite
suite = EvalSuite(name="Multi-Agent Tests", cases=[test_case])

# Define agent function
def my_crew_workflow(input_data):
    # Your CrewAI implementation
    # ...
    return result

# Run evaluation
runner = EvalRunner(suite, my_crew_workflow)
result = runner.run()

# View results
print(result.summary())
```

**Output:**
```
Evaluation Suite: Multi-Agent Tests
Total Cases: 1
Passed: 1 (100.0%)
Case Results:
  ✓ Research workflow with delegation (2.5s)
    ✓ PASS [agent_used] Agent 'Manager' invoked 1 times
    ✓ PASS [agent_used] Agent 'Researcher' invoked 1 times
    ✓ PASS [agent_used] Agent 'Writer' invoked 1 times
    ✓ PASS [task_completed] Task 'Research AI trends' completed
    ✓ PASS [task_completed] Task 'Write summary' completed
    ✓ PASS [delegation_occurred] Delegation from Manager to Researcher
    ✓ PASS [delegation_occurred] Delegation from Manager to Writer
    ✓ PASS [agent_collaboration] Found 3 agents
    ✓ PASS [no_circular_delegation] No circular delegation detected
```

## Framework-Specific Examples

### CrewAI Example

```python
from prela.evals import EvalCase, EvalInput
from prela.evals.assertions import (
    AgentUsedAssertion,
    DelegationOccurredAssertion,
    TaskCompletedAssertion,
)

crewai_case = EvalCase(
    id="test_crewai_delegation",
    name="CrewAI task delegation",
    input=EvalInput(query="Complete research task"),
    assertions=[
        AgentUsedAssertion(agent_name="Researcher", min_invocations=1),
        TaskCompletedAssertion(task_description="Research"),
        DelegationOccurredAssertion(
            from_agent="Manager",
            to_agent="Researcher"
        ),
    ]
)
```

### AutoGen Example

```python
from prela.evals import EvalCase, EvalInput
from prela.evals.assertions import (
    AgentUsedAssertion,
    ConversationTurnsAssertion,
    AgentCollaborationAssertion,
)

autogen_case = EvalCase(
    id="test_autogen_conversation",
    name="AutoGen multi-turn conversation",
    input=EvalInput(query="Discuss project requirements"),
    assertions=[
        AgentUsedAssertion(agent_name="UserProxy", min_invocations=1),
        AgentUsedAssertion(agent_name="Assistant", min_invocations=1),
        ConversationTurnsAssertion(min_turns=3, max_turns=10),
        AgentCollaborationAssertion(min_agents=2),
    ]
)
```

### LangGraph Example

```python
from prela.evals import EvalCase, EvalInput
from prela.evals.assertions import (
    AgentUsedAssertion,
    AgentCollaborationAssertion,
)

langgraph_case = EvalCase(
    id="test_langgraph_workflow",
    name="LangGraph stateful workflow",
    input=EvalInput(query="Process data through graph"),
    assertions=[
        AgentUsedAssertion(agent_name="analyze", min_invocations=1),
        AgentUsedAssertion(agent_name="respond", min_invocations=1),
        AgentCollaborationAssertion(min_agents=2),
    ]
)
```

### Swarm Example

```python
from prela.evals import EvalCase, EvalInput
from prela.evals.assertions import (
    AgentUsedAssertion,
    HandoffOccurredAssertion,
)

swarm_case = EvalCase(
    id="test_swarm_handoff",
    name="Swarm agent handoff",
    input=EvalInput(query="Handle customer inquiry"),
    assertions=[
        AgentUsedAssertion(agent_name="Triage", min_invocations=1),
        AgentUsedAssertion(agent_name="Billing", min_invocations=1),
        HandoffOccurredAssertion(
            from_agent="Triage",
            to_agent="Billing"
        ),
    ]
)
```

## Convenience Functions

All assertions have convenience factory functions for cleaner syntax:

```python
from prela.evals.assertions import (
    agent_used,
    task_completed,
    delegation_occurred,
    handoff_occurred,
    agent_collaboration,
    conversation_turns,
    no_circular_delegation,
)

# Cleaner syntax
assertions = [
    agent_used("Manager", min_invocations=1),
    task_completed("Research AI trends"),
    delegation_occurred(from_agent="Manager", to_agent="Researcher"),
    handoff_occurred(from_agent="Triage", to_agent="Billing"),
    agent_collaboration(min_agents=3),
    conversation_turns(min_turns=3, max_turns=10),
    no_circular_delegation(),
]
```

## Best Practices

### 1. Test Critical Flows

Always verify that critical agents and tasks execute:

```python
assertions = [
    agent_used("CriticalAgent", min_invocations=1),
    task_completed("Critical task description"),
]
```

### 2. Validate Collaboration

Ensure minimum agent participation in team workflows:

```python
assertions = [
    agent_collaboration(min_agents=3),  # At least 3 agents must participate
]
```

### 3. Prevent Infinite Loops

Always include circular delegation detection:

```python
assertions = [
    no_circular_delegation(),  # Catch delegation cycles
]
```

### 4. Framework-Specific Assertions

Use framework-appropriate assertions:

- **CrewAI**: Use `DelegationOccurredAssertion` and `TaskCompletedAssertion`
- **AutoGen**: Use `ConversationTurnsAssertion`
- **Swarm**: Use `HandoffOccurredAssertion`
- **LangGraph**: Use `AgentUsedAssertion` for node verification

### 5. Combine Assertions

Test multiple aspects of multi-agent behavior:

```python
assertions = [
    agent_used("Manager", min_invocations=1),          # Verify participation
    delegation_occurred("Manager", "Worker"),          # Verify delegation
    agent_collaboration(min_agents=2),                  # Verify collaboration
    no_circular_delegation(),                           # Verify no loops
]
```

## Troubleshooting

### Assertion Failing: Agent Not Found

**Problem**: `AgentUsedAssertion` fails with "Agent 'X' not found"

**Solution**: Verify agent name matches exactly:
```python
# Check trace data for actual agent names
# Agent names must match framework's naming convention
```

### Assertion Failing: No Delegation Detected

**Problem**: `DelegationOccurredAssertion` fails even though delegation occurred

**Solution**: Verify framework emits delegation events:
```python
# CrewAI: Delegation tracked via task assignments
# Swarm: Handoffs tracked via agent switching
# Check that framework instrumentation is enabled
```

### Assertion Failing: Circular Delegation False Positive

**Problem**: `NoCircularDelegationAssertion` detects cycles when none exist

**Solution**: Review delegation graph structure:
```python
# Check trace events for delegation patterns
# Ensure agents don't delegate back to themselves
```

## Integration with Evaluation Framework

Multi-agent assertions integrate seamlessly with Prela's evaluation framework:

```python
from prela.evals import EvalRunner, EvalSuite
from prela.evals.reporters import ConsoleReporter, JUnitReporter

# Create suite with multi-agent assertions
suite = EvalSuite(name="Multi-Agent Tests", cases=[...])

# Run with tracer integration
runner = EvalRunner(suite, my_agent_function, tracer=tracer)
result = runner.run()

# Report results
ConsoleReporter(verbose=True).report(result)
JUnitReporter("results/junit.xml").report(result)
```

## Next Steps

- [Writing Tests](writing-tests.md) - Learn how to create comprehensive test cases
- [Running Evaluations](running.md) - Execute evaluation suites with parallel support
- [CI Integration](ci-integration.md) - Integrate with GitHub Actions, GitLab CI, etc.
- [CrewAI Integration](../integrations/crewai.md) - CrewAI-specific instrumentation details
- [AutoGen Integration](../integrations/autogen.md) - AutoGen-specific instrumentation details
- [LangGraph Integration](../integrations/langgraph.md) - LangGraph-specific instrumentation details
- [Swarm Integration](../integrations/swarm.md) - Swarm-specific instrumentation details
