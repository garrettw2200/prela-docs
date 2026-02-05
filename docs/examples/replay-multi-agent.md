# Replay with Multi-Agent Frameworks

This guide demonstrates how to capture and replay traces from multi-agent frameworks: CrewAI, AutoGen, LangGraph, and Swarm.

## Overview

All multi-agent frameworks support replay capture when `capture_for_replay=True`:

- **CrewAI** - Captures system prompt, tools, agent memory, tasks
- **AutoGen** - Captures system messages, function maps, chat history
- **LangGraph** - Captures graph config, node list, input state
- **Swarm** - Captures instructions, functions, context variables

**Replay enables:**
- Test multi-agent workflows with different models
- Compare agent performance across LLM providers
- Detect regressions in agent behavior
- Optimize agent prompts and configurations

## CrewAI Replay

### Capture

```python
import prela
from crewai import Agent, Task, Crew

# Enable replay capture
tracer = prela.init(
    service_name="crewai-demo",
    exporter="file",
    file_path="crew_trace.jsonl",
    capture_for_replay=True,  # Enable capture
)

# Define agents
researcher = Agent(
    name="Researcher",
    role="AI Research Specialist",
    goal="Research latest AI trends",
    backstory="PhD in AI with 10 years experience",
    tools=[web_search_tool, scraper_tool],
    allow_delegation=False,
)

writer = Agent(
    name="Writer",
    role="Technical Writer",
    goal="Write clear technical content",
    backstory="10 years writing about AI",
    tools=[grammar_checker_tool],
    allow_delegation=False,
)

# Define tasks
research_task = Task(
    description="Research the latest AI agent trends and frameworks",
    agent=researcher,
)

write_task = Task(
    description="Write a comprehensive article about AI agents",
    agent=writer,
)

# Create and execute crew
crew = Crew(
    agents=[researcher, writer],
    tasks=[research_task, write_task],
    verbose=True,
)

result = crew.kickoff()
print(result)
```

**Captured Data:**
- **System Prompt**: `"Crew: {crew_name}"`
- **Available Tools**: All tools across all agents with agent attribution
- **Agent Memory**: Complete agent definitions (name, role, goal, backstory, model)
- **Tasks**: Task descriptions and assignments
- **Config**: Framework, execution_id, num_agents, num_tasks, process type

### Replay

```python
from prela.replay import ReplayEngine, TraceLoader

# Load trace
trace = TraceLoader.from_file("crew_trace.jsonl")

# Replay with different model
engine = ReplayEngine(trace)
result = engine.replay_with_modifications(
    model="gpt-4o",  # Try different model
    temperature=0.5,
)

print(f"Original model: {trace.spans[0].attributes.get('llm.model')}")
print(f"Replayed with: gpt-4o")
print(f"Output similarity: {result.output_similarity:.2%}")
```

### Compare CrewAI Configurations

```python
from prela.replay import ReplayEngine, TraceLoader

trace = TraceLoader.from_file("crew_trace.jsonl")
engine = ReplayEngine(trace)

# Test 1: Original model
result1 = engine.replay_with_modifications(model="gpt-4")

# Test 2: Faster model
result2 = engine.replay_with_modifications(model="gpt-3.5-turbo")

# Test 3: Different provider
result3 = engine.replay_with_modifications(model="claude-sonnet-4")

# Compare
comparison12 = engine.compare_replay(result1, result2)
comparison13 = engine.compare_replay(result1, result3)

print(f"GPT-4 vs GPT-3.5: {comparison12.output_similarity:.2%}")
print(f"GPT-4 vs Claude: {comparison13.output_similarity:.2%}")
```

---

## AutoGen Replay

### Capture

```python
import prela
from autogen import ConversableAgent

# Enable replay capture
tracer = prela.init(
    service_name="autogen-demo",
    exporter="file",
    file_path="autogen_trace.jsonl",
    capture_for_replay=True,
)

# Define agents
user_proxy = ConversableAgent(
    name="UserProxy",
    system_message="A human user providing requirements",
    code_execution_config={"work_dir": "workspace", "use_docker": False},
    llm_config=False,
    human_input_mode="NEVER",
)

coder = ConversableAgent(
    name="Coder",
    system_message="Expert Python programmer writing clean code",
    llm_config={"model": "gpt-4", "temperature": 0.1},
)

critic = ConversableAgent(
    name="Critic",
    system_message="Code reviewer providing improvement suggestions",
    llm_config={"model": "gpt-4", "temperature": 0.3},
)

# Initiate conversation
user_proxy.initiate_chat(
    coder,
    message="Write a Python function to calculate Fibonacci numbers with memoization"
)
```

**Captured Data:**
- **System Messages**: Each agent's system prompt
- **Function Map**: Available functions with names and descriptions
- **Chat History**: Complete message sequence
- **Config**: Framework, conversation_id, initiator, recipient, max_turns

### Replay

```python
from prela.replay import ReplayEngine, TraceLoader

trace = TraceLoader.from_file("autogen_trace.jsonl")
engine = ReplayEngine(trace)

# Replay conversation with different temperature
result = engine.replay_with_modifications(
    model="gpt-4",
    temperature=0.0,  # More deterministic
)

print("Replayed conversation with temperature=0.0")
print(f"Turn count: {len([s for s in result.spans if 'message' in s.name])}")
```

### Test Conversation Consistency

```python
from prela.replay import ReplayEngine, TraceLoader

trace = TraceLoader.from_file("autogen_trace.jsonl")
engine = ReplayEngine(trace)

# Replay 5 times with same settings
results = []
for i in range(5):
    result = engine.replay_with_modifications(
        model="gpt-4",
        temperature=0.0,  # Should be deterministic
    )
    results.append(result)

# Check consistency
similarities = []
for i in range(1, len(results)):
    comparison = engine.compare_replay(results[0], results[i])
    similarities.append(comparison.output_similarity)

avg_similarity = sum(similarities) / len(similarities)
print(f"Average consistency: {avg_similarity:.2%}")
print(f"Expected: >95% for temperature=0.0")
```

---

## LangGraph Replay

### Capture

```python
import prela
from langgraph.graph import StateGraph

# Enable replay capture
tracer = prela.init(
    service_name="langgraph-demo",
    exporter="file",
    file_path="langgraph_trace.jsonl",
    capture_for_replay=True,
)

# Define state schema
graph = StateGraph(state_schema={
    "messages": list,
    "analyzed": bool,
    "sentiment": str,
    "response": str,
})

# Define nodes
def analyze_node(state):
    messages = state["messages"]
    text = " ".join(messages)
    sentiment = "positive" if "good" in text.lower() else "neutral"
    return {**state, "analyzed": True, "sentiment": sentiment}

def respond_node(state):
    sentiment = state.get("sentiment", "neutral")
    response = "Glad to hear!" if sentiment == "positive" else "Thank you"
    return {**state, "response": response}

# Build graph
graph.add_node("analyze", analyze_node)
graph.add_node("respond", respond_node)
graph.set_entry_point("analyze")
graph.add_edge("analyze", "respond")
graph.set_finish_point("respond")

# Compile and execute
compiled = graph.compile()
result = compiled.invoke({"messages": ["This is good!"], "analyzed": False})
print(result)
```

**Captured Data:**
- **Graph Config**: Framework, graph_id, nodes list
- **Input State**: Complete input state (dict or truncated string)
- **Node Changes**: Keys modified by each node

### Replay

```python
from prela.replay import ReplayEngine, TraceLoader

trace = TraceLoader.from_file("langgraph_trace.jsonl")
engine = ReplayEngine(trace)

# Replay with different input state
result = engine.replay_with_modifications(
    # Note: LangGraph replay uses captured state
    # Modifications apply to LLM calls within nodes (if any)
    model="gpt-4o",
)

print("Replayed LangGraph execution")
print(f"Nodes executed: {len([s for s in result.spans if 'node' in s.name])}")
print(f"State changes captured: {sum(1 for s in result.spans if 'changed_keys' in s.attributes)}")
```

### Compare Graph Execution

```python
from prela.replay import ReplayEngine, TraceLoader

trace = TraceLoader.from_file("langgraph_trace.jsonl")
engine = ReplayEngine(trace)

# Replay 3 times (should be identical for deterministic graphs)
results = []
for i in range(3):
    result = engine.replay_with_modifications()
    results.append(result)

# Verify determinism
for i in range(1, len(results)):
    comparison = engine.compare_replay(results[0], results[i])
    print(f"Run {i+1} similarity: {comparison.output_similarity:.2%}")
```

---

## Swarm Replay

### Capture

```python
import prela
from swarm import Swarm, Agent

# Enable replay capture
tracer = prela.init(
    service_name="swarm-demo",
    exporter="file",
    file_path="swarm_trace.jsonl",
    capture_for_replay=True,
)

# Define agents with handoff functions
def transfer_to_billing():
    """Transfer to billing specialist."""
    return billing_agent

def transfer_to_technical():
    """Transfer to technical support."""
    return technical_agent

triage_agent = Agent(
    name="Triage",
    instructions="Route customers to right specialist",
    functions=[transfer_to_billing, transfer_to_technical],
)

billing_agent = Agent(
    name="Billing",
    instructions="Help with payment and subscription questions",
)

technical_agent = Agent(
    name="Technical",
    instructions="Help with technical issues and bugs",
)

# Execute with Swarm
client = Swarm()
response = client.run(
    agent=triage_agent,
    messages=[{"role": "user", "content": "I want to cancel my subscription"}],
    context_variables={"user_id": "user-123", "tier": "premium"},
)

print(f"Final agent: {response.agent.name}")
print(f"Handoffs: {response.context_variables.get('handoff_count', 0)}")
```

**Captured Data:**
- **Instructions**: Agent's system instructions
- **Functions**: Agent's available functions with names and docstrings
- **Context Variables**: Keys only (not values for privacy)
- **Config**: Framework, execution_id, initial_agent, final_agent

### Replay

```python
from prela.replay import ReplayEngine, TraceLoader

trace = TraceLoader.from_file("swarm_trace.jsonl")
engine = ReplayEngine(trace)

# Replay with different model
result = engine.replay_with_modifications(
    model="gpt-4o",
    temperature=0.3,
)

print("Replayed Swarm execution")
print(f"Agents used: {len([s for s in result.spans if 'agent' in s.attributes])}")
print(f"Handoffs: {sum(1 for s in result.spans if 'handoff' in s.name)}")
```

### Test Agent Handoff Consistency

```python
from prela.replay import ReplayEngine, TraceLoader

trace = TraceLoader.from_file("swarm_trace.jsonl")
engine = ReplayEngine(trace)

# Replay multiple times
handoff_counts = []
for i in range(10):
    result = engine.replay_with_modifications(
        model="gpt-4",
        temperature=0.0,  # Deterministic
    )

    handoffs = sum(1 for s in result.spans if 'handoff' in s.name)
    handoff_counts.append(handoffs)

# Check consistency
print(f"Handoff counts: {handoff_counts}")
print(f"Consistent: {len(set(handoff_counts)) == 1}")
```

---

## Cross-Framework Comparison

### Compare Approaches to Same Task

```python
from prela.replay import ReplayEngine, TraceLoader

# Load traces from different frameworks solving same task
crewai_trace = TraceLoader.from_file("crew_research_trace.jsonl")
autogen_trace = TraceLoader.from_file("autogen_research_trace.jsonl")
langgraph_trace = TraceLoader.from_file("langgraph_research_trace.jsonl")
swarm_trace = TraceLoader.from_file("swarm_research_trace.jsonl")

# Replay all with same model
model = "gpt-4o"
temperature = 0.7

crewai_result = ReplayEngine(crewai_trace).replay_with_modifications(
    model=model, temperature=temperature
)
autogen_result = ReplayEngine(autogen_trace).replay_with_modifications(
    model=model, temperature=temperature
)
langgraph_result = ReplayEngine(langgraph_trace).replay_with_modifications(
    model=model, temperature=temperature
)
swarm_result = ReplayEngine(swarm_trace).replay_with_modifications(
    model=model, temperature=temperature
)

# Compare metrics
results = {
    "CrewAI": crewai_result,
    "AutoGen": autogen_result,
    "LangGraph": langgraph_result,
    "Swarm": swarm_result,
}

for framework, result in results.items():
    duration = sum(s.duration_ms for s in result.spans)
    tokens = sum(s.attributes.get("llm.total_tokens", 0) for s in result.spans)
    print(f"{framework:12} - Duration: {duration:6.0f}ms, Tokens: {tokens:5}")
```

**Output:**
```
CrewAI       - Duration: 8250ms, Tokens: 2150
AutoGen      - Duration: 6800ms, Tokens: 1950
LangGraph    - Duration: 5400ms, Tokens: 1800
Swarm        - Duration: 7200ms, Tokens: 2050
```

---

## Multi-Agent Regression Testing

### Detect Agent Behavior Changes

```python
from prela.replay import ReplayEngine, TraceLoader

def test_agent_regression(baseline_trace_path: str, current_trace_path: str):
    """Compare baseline vs current agent behavior."""

    baseline = TraceLoader.from_file(baseline_trace_path)
    current = TraceLoader.from_file(current_trace_path)

    # Replay both with same settings
    engine = ReplayEngine(baseline)
    baseline_result = engine.replay_with_modifications(
        model="gpt-4",
        temperature=0.0,
    )

    engine = ReplayEngine(current)
    current_result = engine.replay_with_modifications(
        model="gpt-4",
        temperature=0.0,
    )

    # Compare
    comparison = engine.compare_replay(baseline_result, current_result)

    print(f"Output similarity: {comparison.output_similarity:.2%}")
    print(f"Span count: {comparison.span_count_match}")
    print(f"Status match: {comparison.all_status_match}")

    # Alert if significant change
    if comparison.output_similarity < 0.9:
        print("⚠️  Warning: Significant behavior change detected")
        return False

    print("✓ No regression detected")
    return True

# Run regression test
test_agent_regression(
    baseline_trace_path="baseline_v1.0_crew.jsonl",
    current_trace_path="current_v1.1_crew.jsonl",
)
```

---

## Best Practices

### 1. Capture with Production Settings

```python
# Capture traces with realistic configurations
tracer = prela.init(
    capture_for_replay=True,
    sample_rate=0.1,  # Sample 10% to avoid overhead
)
```

### 2. Use Deterministic Settings for Testing

```python
# Replay with temperature=0 for consistency tests
result = engine.replay_with_modifications(
    model="gpt-4",
    temperature=0.0,  # Deterministic
)
```

### 3. Test Multiple Models

```python
models = ["gpt-4", "gpt-3.5-turbo", "claude-sonnet-4"]
results = {}

for model in models:
    result = engine.replay_with_modifications(model=model)
    results[model] = result

# Compare performance
for model, result in results.items():
    duration = sum(s.duration_ms for s in result.spans)
    print(f"{model}: {duration:.0f}ms")
```

### 4. Version Control Traces

```bash
# Store baseline traces for regression testing
git add traces/baseline_v1.0_*.jsonl
git commit -m "Add baseline traces for v1.0"
```

### 5. Automate Regression Tests

```python
import pytest
from prela.replay import ReplayEngine, TraceLoader

@pytest.mark.parametrize("framework", ["crewai", "autogen", "langgraph", "swarm"])
def test_multi_agent_regression(framework):
    """Test for regressions in multi-agent behavior."""
    baseline = TraceLoader.from_file(f"baselines/{framework}_baseline.jsonl")

    engine = ReplayEngine(baseline)
    result = engine.replay_with_modifications(
        model="gpt-4",
        temperature=0.0,
    )

    # Compare with baseline
    comparison = engine.compare_replay(baseline, result)

    assert comparison.output_similarity >= 0.95, \
        f"{framework} regression: similarity {comparison.output_similarity:.2%}"
```

---

## Next Steps

- [Replay Advanced Features](../concepts/replay-advanced.md) - API retry, semantic fallback, tool re-execution
- [Replay with Tools](replay-with-tools.md) - Tool re-execution examples
- [CrewAI Integration](../integrations/crewai.md) - CrewAI instrumentation details
- [AutoGen Integration](../integrations/autogen.md) - AutoGen instrumentation details
- [LangGraph Integration](../integrations/langgraph.md) - LangGraph instrumentation details
- [Swarm Integration](../integrations/swarm.md) - Swarm instrumentation details
