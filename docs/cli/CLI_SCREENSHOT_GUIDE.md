# Prela CLI Screenshot Guide

**Purpose:** Visual demonstration guide for CLI features (FAQs, marketing, documentation)

**Status:** Ready for screenshots

---

## 📸 Screenshot Checklist

Use this guide to capture professional screenshots of Prela CLI in action.

### Terminal Setup for Screenshots

```bash
# Recommended terminal settings for clean screenshots:
# - Font: SF Mono, Menlo, or Monaco (14-16pt)
# - Theme: Dark theme with good contrast
# - Window size: 100 columns x 30 rows (standard)
# - Clear terminal before each screenshot: clear or cmd+K
```

---

## 1. Getting Started

### Screenshot 1.1: Installation
```bash
# Show installation process
pip install prela

# Expected output:
# Collecting prela
# Downloading prela-0.1.0-py3-none-any.whl
# Installing collected packages: prela
# Successfully installed prela-0.1.0
```

### Screenshot 1.2: Version Check
```bash
prela --version

# Expected output:
# Prela CLI v0.1.0
```

### Screenshot 1.3: Help Overview
```bash
prela --help

# Expected output:
# Prela - AI Agent Observability Platform CLI
#
# Usage: prela [OPTIONS] COMMAND [ARGS]...
#
# Commands:
#   list      List recent traces
#   show      Show detailed trace information
#   search    Search traces by keyword
#   replay    Replay a trace with modifications
#   explore   Launch interactive trace explorer
#   last      Show most recent trace
#   errors    Show failed traces
#   tail      Follow new traces in real-time
#   eval      Run evaluation suites
```

---

## 2. Basic Commands

### Screenshot 2.1: List Traces (Empty State)
```bash
# First run with no traces yet
prela list

# Expected output:
# No traces found in ./traces
#
# To start tracing:
#   1. Import prela in your code: import prela
#   2. Initialize: prela.init(service_name="my-app", exporter="file")
#   3. Run your AI agent
#   4. Traces will appear here!
```

### Screenshot 2.2: List Traces (With Data)
```bash
# After running some scenarios
prela list

# Expected output (formatted table):
#                             Recent Traces (17 of 17)
# ┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━━┳━━━━━━━┳━━━━━━━━━━━━━━┓
# ┃ Trace ID         ┃ Root Span     ┃ Duration ┃ Status  ┃ Spans ┃ Time         ┃
# ┡━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━━━╇━━━━━━━╇━━━━━━━━━━━━━━┩
# │ aa538cdd-d1d5-4b │ reasoning_fl… │   10.99s │ success │     7 │ 2026-01-30   │
# │ 427ef3a7-58a3-4a │ rapid_reques… │    9.03s │ success │     6 │ 2026-01-30   │
# │ 56cee896-936f-46 │ reasoning_fl… │    8.12s │ error   │     4 │ 2026-01-30   │
# └──────────────────┴───────────────┴──────────┴─────────┴───────┴──────────────┘
```

### Screenshot 2.3: List with Filters
```bash
# Show filtering capabilities
prela list --limit 5

# Expected output:
#                             Recent Traces (5 of 17)
# [Same table format, but only 5 rows]
```

```bash
# Time-based filtering
prela list --since 1h

# Expected output:
#                       Recent Traces (Last Hour: 12 of 17)
# [Table with traces from last hour only]
```

---

## 3. Show Trace Details

### Screenshot 3.1: Compact Tree View
```bash
# Clean hierarchical view
prela show aa538cdd-d1d5-4b --compact

# Expected output:
# Trace: aa538cdd-d1d5-4b1a-a5c6-2895041bd236
#
# reasoning_flow (agent) success 10.99s
# ├── step_1_analyze (custom) success 3.97s
# │   └── anthropic.messages.create (llm) success 3.97s
# ├── step_2_solve (custom) success 2.35s
# │   └── anthropic.messages.create (llm) success 2.35s
# └── step_3_verify (custom) success 4.67s
#     └── anthropic.messages.create (llm) success 4.67s
#
# 💡 Tip: Run without --compact to see full span details
```

### Screenshot 3.2: Full Trace Details
```bash
# Show detailed span information
prela show aa538cdd-d1d5-4b

# Expected output:
# Trace: aa538cdd-d1d5-4b1a-a5c6-2895041bd236
# Started: 2026-01-30 03:15:42
# Duration: 10.99s
# Status: SUCCESS
#
# reasoning_flow (agent) success 10.99s
# ├── step_1_analyze (custom) success 3.97s
# │   └── anthropic.messages.create (llm) success 3.97s
# ├── step_2_solve (custom) success 2.35s
# │   └── anthropic.messages.create (llm) success 2.35s
# └── step_3_verify (custom) success 4.67s
#     └── anthropic.messages.create (llm) success 4.67s
#
# Span Details:
#
# reasoning_flow
#   Span ID: root-span-123
#   Type: agent
#   Status: success
#   Duration: 10.99s
#   Attributes:
#     task: mathematical_reasoning
#     service.name: test-multi-step
#
# step_1_analyze
#   Span ID: span-456
#   Type: custom
#   Status: success
#   Duration: 3.97s
#   Parent: reasoning_flow
#   Attributes:
#     result: To calculate 15 * 23, we can break it down...
#
# [... more span details ...]
```

---

## 4. Search Functionality

### Screenshot 4.1: Search by Keyword
```bash
# Search across all traces
prela search "reasoning_flow"

# Expected output:
# Found 3 traces matching 'reasoning_flow'
#
#                                 Search Results
# ┏━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━┳━━━━━━━━┓
# ┃ Trace ID         ┃ Root Span           ┃ Matching Spans ┃ Status ┃
# ┡━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━╇━━━━━━━━┩
# │ aa538cdd-d1d5-4b │ reasoning_flow      │              1 │ success│
# │ 56cee896-936f-46 │ reasoning_flow      │              1 │ error  │
# │ 8f2a1b34-c9d7-4e │ reasoning_flow      │              1 │ success│
# └──────────────────┴─────────────────────┴────────────────┴────────┘
```

### Screenshot 4.2: Search by Model Name
```bash
# Find traces using specific model
prela search "claude-sonnet-4"

# Expected output:
# Found 12 traces matching 'claude-sonnet-4'
#
# [Search results table showing all Claude Sonnet traces]
```

### Screenshot 4.3: Search for Errors
```bash
# Quick error search
prela search "error"

# Expected output:
# Found 5 traces matching 'error'
#
# [Search results table with error traces highlighted]
```

---

## 5. Convenience Shortcuts

### Screenshot 5.1: Most Recent Trace
```bash
# One command to see latest execution
prela last --compact

# Expected output:
# Showing most recent trace (aa538cdd-d1d5-4b...)
#
# reasoning_flow (agent) success 10.99s
# ├── step_1_analyze (custom) success 3.97s
# │   └── anthropic.messages.create (llm) success 3.97s
# ├── step_2_solve (custom) success 2.35s
# │   └── anthropic.messages.create (llm) success 2.35s
# └── step_3_verify (custom) success 4.67s
#     └── anthropic.messages.create (llm) success 4.67s
#
# 💡 Tip: Run without --compact to see full span details
```

### Screenshot 5.2: Failed Traces
```bash
# Instant error filtering
prela errors

# Expected output:
#                             Failed Traces (3 errors)
# ┏━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━┳━━━━━━━━━━━━┓
# ┃ Trace ID       ┃ Root Span           ┃ Duration ┃ Spans ┃ Time       ┃
# ┡━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━╇━━━━━━━━━━━┩
# │ 56cee896-936f  │ reasoning_flow      │    8.12s │     4 │ 2026-01-30 │
# │ 615cecb0-2fe4  │ rapid_requests      │    2.15s │     3 │ 2026-01-30 │
# │ ae9ced4a-1c2f  │ eval.case.test      │    0.45s │     2 │ 2026-01-30 │
# └────────────────┴─────────────────────┴──────────┴───────┴────────────┘
#
# 💡 Tip: Use 'prela show <trace-id>' to inspect a specific error
```

### Screenshot 5.3: Real-Time Monitoring
```bash
# Follow new traces as they arrive
prela tail --compact --interval 1

# Expected output:
# Following traces in ./traces (polling every 1s)
# Press Ctrl+C to stop
#
# [New traces appear automatically as they're created]
#
# 2026-01-30 03:25:15  reasoning_flow (10.99s) ✓
# 2026-01-30 03:25:28  rapid_requests (9.03s) ✓
# 2026-01-30 03:25:42  eval.case.test (0.33s) ✗
```

---

## 6. Interactive Features

### Screenshot 6.1: Interactive List Selection
```bash
# Numbered trace selection
prela list --interactive

# Expected output:
#                    Recent Traces (5 of 17) - Select by number
# ┏━━━━━━┳━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━━┳━━━━━━━┳━━━━━━━━━━━━┓
# ┃    # ┃ Trace ID       ┃ Root Span  ┃ Duration ┃ Status  ┃ Spans ┃ Time       ┃
# ┡━━━━━━╇━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━━━╇━━━━━━━╇━━━━━━━━━━━━┩
# │    1 │ aa538cdd-d1d5  │ reasoning… │   10.99s │ success │     7 │ 2026-01-30 │
# │    2 │ 427ef3a7-58a3  │ rapid_req… │    9.03s │ success │     6 │ 2026-01-30 │
# │    3 │ 56cee896-936f  │ reasoning… │    8.12s │  error  │     4 │ 2026-01-30 │
# │    4 │ 615cecb0-2fe4  │ rapid_req… │    2.15s │  error  │     3 │ 2026-01-30 │
# │    5 │ ae9ced4a-1c2f  │ eval.case  │    0.33s │  error  │     2 │ 2026-01-30 │
# └──────┴────────────────┴────────────┴──────────┴─────────┴───────┴────────────┘
#
# Select trace (1-5), or 'q' to quit [q]: _
```

### Screenshot 6.2: Interactive TUI (Full Screen)
```bash
# Launch full-screen interactive explorer
prela explore

# Expected: Full-screen TUI with:
# - Header: "Prela Trace Explorer | k/j: Navigate | Enter: Select | Esc: Back | q: Quit"
# - Main area: DataTable with trace list
# - Footer: Keyboard shortcuts help
#
# [Note: This requires an actual terminal screenshot of the Textual TUI]
```

---

## 7. Replay Engine

### Screenshot 7.1: Basic Replay
```bash
# Replay exact execution
prela replay test_traces/replay_test.jsonl

# Expected output:
# Loading trace from test_traces/replay_test.jsonl...
# ✓ Loaded trace f6358584-48eb-40c8-8c5e-49010950c9f2 with 1 spans
#
# Executing replay...
# ✓ Exact replay completed
#
# Replay Results:
#   Trace ID: f6358584-48eb-40c8-8c5e-49010950c9f2
#   Total Spans: 1
#   Duration: 1957.3ms
#   Tokens: 34
#   Cost: $0.0002
#   Success: ✓
#
# Final Output:
#   2 + 2 equals 4.
```

### Screenshot 7.2: Replay with Model Override
```bash
# Change model and compare results
prela replay test_traces/replay_test.jsonl --model claude-opus-4 --compare

# Expected output:
# Loading trace from test_traces/replay_test.jsonl...
# ✓ Loaded trace f6358584-48eb-40c8-8c5e-49010950c9f2 with 1 spans
#
# Executing replay...
# ✓ Modified replay completed (1 spans modified)
#
# Comparing with original execution...
# sentence-transformers not available. Using fallback similarity metrics.
#
# Replay Comparison Summary
# ==================================================
# Total Spans: 1
# Identical: 0 (0.0%)
# Changed: 1 (100.0%)
#
# Cost: $0.0002 → $0.0008 (+$0.0006)
# Tokens: 34 → 42 (+8)
#
# Key Differences:
#   • anthropic.messages.create (model)
#   • anthropic.messages.create (output)
#
# Output Comparison:
#   Original: "2 + 2 equals 4."
#   Modified: "The sum of 2 and 2 is 4."
#   Similarity: 0.82 (semantic match)
```

### Screenshot 7.3: Streaming Replay
```bash
# Watch replay output in real-time
prela replay test_traces/replay_test.jsonl --stream

# Expected output:
# Loading trace from test_traces/replay_test.jsonl...
# ✓ Loaded trace f6358584-48eb-40c8-8c5e-49010950c9f2 with 1 spans
#
# Executing replay...
# Streaming enabled - showing real-time output:
#
# 2 + 2 equals 4.
#
# ✓ Exact replay completed
```

---

## 8. Evaluation Framework

### Screenshot 8.1: Run Eval Suite (Python)
```bash
# Show evaluation results
cd test_scenarios
python 06_evaluation.py

# Expected output:
# ============================================================
# TEST SCENARIO 6: Evaluation Framework
# ============================================================
#
# ✓ Prela initialized with file exporter
# ✓ Traces will be saved to: ./test_traces
#
# → Defining test cases...
#   ✓ Created 3 test cases
#   ✓ Created eval suite: Math Agent Tests
#
# → Running evaluation...
#
# ============================================================
# Evaluation Suite: Math Agent Tests
# Started: 2026-01-30T03:41:54
# Completed: 2026-01-30T03:41:54
# Duration: 0.33s
#
# Total Cases: 3
# Passed: 2 (66.7%)
# Failed: 1
# ============================================================
#
# Detailed Results:
#   ✓ Simple Addition (152.3ms)
#   ✓ Multiplication (189.7ms)
#   ✗ Explain Reasoning (98.1ms)
#     ✗ Semantic similarity below threshold (0.65 < 0.70)
```

---

## 9. Workflow Comparisons (For Marketing)

### Screenshot 9.1: Before Prela (4 Steps)
```bash
# Traditional workflow without convenience commands
prela list
# [scan timestamps manually...]
# [copy trace ID...]
prela show aa538cdd-d1d5-4b1a-a5c6-2895041bd236

# Caption: "Old way: 4 steps, manual scanning, copy/paste"
```

### Screenshot 9.2: After Prela (1 Step)
```bash
# Modern workflow with convenience shortcuts
prela last

# Caption: "New way: 1 command, instant results"
```

### Screenshot 9.3: Error Debugging - Before
```bash
# Traditional error finding
prela list
# [scan visually for red 'error' status...]
# [copy each error trace ID...]
prela show 56cee896-936f-4612-8a42-3f1e2d5c7b89
prela show 615cecb0-2fe4-4e91-b2c3-8a7d9e1f4c2b
# [repeat for each error...]

# Caption: "Finding errors: Manual scanning and multiple commands"
```

### Screenshot 9.4: Error Debugging - After
```bash
# Modern error debugging
prela errors

# Caption: "Finding errors: One command, instant results"
```

---

## 10. Integration Examples (For Docs)

### Screenshot 10.1: Simple Python Integration
```python
# show_simple_integration.py
import prela
from anthropic import Anthropic

# One line to enable tracing
prela.init(service_name="my-app", exporter="file")

# All Claude calls automatically traced!
client = Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=1024,
    messages=[{"role": "user", "content": "What is 2+2?"}]
)

print(f"✓ Response: {response.content[0].text}")
print("✓ Trace captured automatically!")
print("✓ Run 'prela list' to view")
```

### Screenshot 10.2: Multi-Step Agent Integration
```python
# show_multistep_integration.py
import prela
from anthropic import Anthropic

tracer = prela.init(service_name="reasoning-agent", exporter="file")
client = Anthropic()

# Create hierarchical trace structure
with tracer.span("reasoning_flow", span_type=prela.SpanType.AGENT):

    with tracer.span("analyze", span_type=prela.SpanType.CUSTOM):
        response1 = client.messages.create(...)  # Automatically traced

    with tracer.span("solve", span_type=prela.SpanType.CUSTOM):
        response2 = client.messages.create(...)  # Automatically traced

    with tracer.span("verify", span_type=prela.SpanType.CUSTOM):
        response3 = client.messages.create(...)  # Automatically traced

print("✓ Multi-step trace captured with hierarchy!")
print("✓ Run 'prela show <trace-id>' to see the tree")
```

---

## 📋 Screenshot Capture Instructions

### Recommended Order:
1. **Getting Started** (Screenshots 1.1-1.3) - Show installation and help
2. **Basic Usage** (Screenshots 2.1-2.2) - Empty state → populated list
3. **Core Features** (Screenshots 3.1-5.3) - Show, search, shortcuts
4. **Interactive** (Screenshots 6.1-6.2) - Interactive selection and TUI
5. **Advanced** (Screenshots 7.1-8.1) - Replay and evaluation
6. **Comparisons** (Screenshots 9.1-9.4) - Before/after workflows

### Terminal Setup:
```bash
# Clean, professional screenshots
export PS1="$ "  # Simple prompt
clear            # Clear screen before each screenshot

# Optimal window size
# Width: 100 columns (fits on most screens)
# Height: 30 rows (shows full tables)
```

### Pro Tips:
1. **Add delays for streaming**: Use `sleep 1` to show incremental output
2. **Highlight key outputs**: Circle or annotate important parts in post
3. **Show full commands**: Include the `prela` command in each screenshot
4. **Consistent styling**: Use same terminal theme throughout
5. **Add captions**: Brief text below each screenshot explaining what it shows

---

## 🎨 Marketing Captions

### For Hero Section:
```
"See inside your AI agents"
→ Screenshot: prela show --compact with clean tree structure

"Debug errors in seconds, not hours"
→ Screenshot: prela errors with 3 error traces highlighted

"One line of code. Complete observability."
→ Screenshot: Python code showing prela.init() + automatic tracing
```

### For Features Section:
```
"Beautiful CLI, not just functional"
→ Screenshot: prela list with formatted table

"Interactive exploration when you need it"
→ Screenshot: prela explore TUI full screen

"Replay any execution with different models"
→ Screenshot: prela replay --model --compare showing side-by-side
```

### For Docs FAQ:
```
Q: "How do I find my most recent trace?"
A: Run `prela last`
→ Screenshot: prela last --compact output

Q: "How do I debug failed executions?"
A: Run `prela errors`
→ Screenshot: prela errors table with helpful tip

Q: "Can I monitor traces in real-time?"
A: Run `prela tail`
→ Screenshot: prela tail --compact showing live updates
```

---

## ✅ Ready for Screenshots!

This guide provides clear, reproducible examples for all major CLI features. Each command shows expected output formatted exactly as it appears in the terminal.

**Next steps:**
1. Set up clean terminal environment
2. Run test scenarios to populate traces
3. Capture screenshots following the recommended order
4. Add captions and annotations for marketing materials
5. Use in docs, README, website, and Product Hunt launch

**Estimated time:** 30-45 minutes for all screenshots
