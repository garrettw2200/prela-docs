# Drift Detection - Quick Start Guide

This guide shows you how to use Prela's drift detection API to monitor agent behavior anomalies.

## Prerequisites

- Prela API Gateway running
- ClickHouse with agent baselines table
- Active agents with trace data (minimum 7 days recommended)

---

## Step 1: Calculate Baselines

First, establish baseline metrics for your agents:

```bash
# Calculate baselines for all agents in a project
curl -X POST "http://localhost:8000/api/v1/drift/projects/my-project/baselines/calculate"

# Response:
{
  "baselines_calculated": 5
}
```

**What it does:** Analyzes last 7 days of agent behavior and stores statistical baselines (mean, stddev, percentiles) for 16 metrics.

**Schedule:** Run this daily via cron to keep baselines up-to-date.

---

## Step 2: Check for Drift

Monitor for anomalies in agent behavior:

```bash
# Check all agents
curl "http://localhost:8000/api/v1/drift/projects/my-project/drift/check"

# Check specific agent
curl "http://localhost:8000/api/v1/drift/projects/my-project/drift/check?agent_name=researcher"

# Adjust sensitivity (1.0 = more alerts, 4.0 = fewer alerts)
curl "http://localhost:8000/api/v1/drift/projects/my-project/drift/check?sensitivity=2.0"

# Check last 12 hours only
curl "http://localhost:8000/api/v1/drift/projects/my-project/drift/check?lookback_hours=12"
```

**Response (when drift detected):**
```json
{
  "alerts": [
    {
      "agent_name": "researcher",
      "service_name": "my-service",
      "anomalies": [
        {
          "metric_name": "duration",
          "current_value": 12847.3,
          "baseline_mean": 5243.2,
          "change_percent": 145.0,
          "severity": "high",
          "direction": "increased",
          "unit": "ms",
          "sample_size": 87
        }
      ],
      "root_causes": [
        {
          "type": "model_change",
          "description": "Model changed: gpt-4, gpt-4o",
          "confidence": 0.9
        }
      ],
      "detected_at": "2026-01-30T14:23:45"
    }
  ],
  "count": 1
}
```

---

## Step 3: View Historical Baselines

```bash
# List all baselines for a project
curl "http://localhost:8000/api/v1/drift/projects/my-project/baselines"

# Filter by agent
curl "http://localhost:8000/api/v1/drift/projects/my-project/baselines?agent_name=researcher"

# Limit results
curl "http://localhost:8000/api/v1/drift/projects/my-project/baselines?limit=20"
```

---

## Understanding Alerts

### Severity Levels

| Severity | Z-Score | Meaning | Action |
|----------|---------|---------|--------|
| **Critical** | > 4σ | Extreme deviation | Immediate investigation |
| **High** | 3-4σ | Significant deviation | Investigate soon |
| **Medium** | 2-3σ | Notable deviation | Monitor closely |
| **Low** | 1-2σ | Minor deviation | Track trend |

### Metrics Monitored

1. **Duration** - How long agents take to complete tasks
2. **Token Usage** - LLM token consumption per execution
3. **Tool Calls** - Frequency of tool invocations
4. **Success Rate** - Percentage of successful completions
5. **Cost** - USD spent per execution

### Root Cause Types

1. **model_change** - Agent switched LLM models (confidence: 0.9)
2. **input_complexity_increase** - Input size/complexity grew (confidence: 0.8)
3. **error_rate_increase** - More failures detected (confidence: 0.95)

---

## Example Scenarios

### Scenario 1: Performance Regression

**Problem:** Agent suddenly takes 2x longer to respond

**Detection:**
```bash
curl "http://localhost:8000/api/v1/drift/projects/prod/drift/check?agent_name=qa_agent"
```

**Alert:**
```json
{
  "metric_name": "duration",
  "current_value": 10234.5,
  "baseline_mean": 5123.7,
  "change_percent": 99.7,
  "severity": "high",
  "direction": "increased"
}
```

**Root Cause:** "Input complexity increased by 85.3%"

**Action:** Investigate input data sources, consider prompt optimization

---

### Scenario 2: Cost Spike

**Problem:** Daily costs increased from $50 to $200

**Detection:**
```bash
curl "http://localhost:8000/api/v1/drift/projects/prod/drift/check?sensitivity=1.5"
```

**Alert:**
```json
{
  "metric_name": "cost",
  "current_value": 0.082,
  "baseline_mean": 0.021,
  "change_percent": 290.5,
  "severity": "critical"
}
```

**Root Cause:** "Model changed: gpt-4o-mini, gpt-4"

**Action:** Verify model selection logic, consider reverting to cheaper model

---

### Scenario 3: Success Rate Drop

**Problem:** Agent failing 15% more requests

**Detection:**
```bash
curl "http://localhost:8000/api/v1/drift/projects/prod/drift/check?lookback_hours=6"
```

**Alert:**
```json
{
  "metric_name": "success_rate",
  "current_value": 0.832,
  "baseline_mean": 0.982,
  "change_percent": -15.3,
  "severity": "high",
  "direction": "decreased"
}
```

**Root Cause:** "Error rate increased (success rate dropped 15.3%)"

**Action:** Check external API health, review error logs

---

## Automation Examples

### Daily Baseline Update (Cron)

```bash
# /etc/cron.d/prela-baselines
0 2 * * * curl -X POST "http://api.prela.internal/api/v1/drift/projects/prod/baselines/calculate"
```

### Alerting Script

```python
import requests
import smtplib
from email.mime.text import MIMEText

def check_drift():
    response = requests.get(
        "http://api.prela.internal/api/v1/drift/projects/prod/drift/check",
        params={"sensitivity": 2.0}
    )
    data = response.json()

    if data["count"] > 0:
        send_alert_email(data["alerts"])

def send_alert_email(alerts):
    msg = MIMEText(f"Detected {len(alerts)} drift alerts:\n\n{alerts}")
    msg["Subject"] = "Prela Drift Alert"
    msg["To"] = "ops@company.com"

    smtp = smtplib.SMTP("localhost")
    smtp.send_message(msg)
    smtp.quit()

if __name__ == "__main__":
    check_drift()
```

### Slack Integration

```python
import requests

def send_slack_alert(alerts):
    webhook_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

    for alert in alerts:
        severity_emoji = {
            "critical": "🔴",
            "high": "🟠",
            "medium": "🟡",
            "low": "🔵"
        }

        message = {
            "text": f"{severity_emoji.get(alert['anomalies'][0]['severity'])} Drift Alert: {alert['agent_name']}",
            "blocks": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": f"*Agent:* {alert['agent_name']}\n*Anomalies:* {len(alert['anomalies'])}"
                    }
                }
            ]
        }

        requests.post(webhook_url, json=message)
```

---

## Configuration Recommendations

| Environment | Window Days | Sensitivity | Lookback Hours | Schedule |
|-------------|-------------|-------------|----------------|----------|
| **Development** | 3 | 3.0 | 6 | Manual |
| **Staging** | 7 | 2.5 | 12 | Daily 2am |
| **Production** | 7 | 2.0 | 24 | Every 6 hours |
| **High-Traffic** | 14 | 2.0 | 6 | Hourly |

---

## Troubleshooting

### No Baselines Found

**Symptom:** `"message": "No baseline found for agent"`

**Cause:** Agent hasn't run enough times in the window period

**Solution:**
1. Check agent has >10 executions in last 7 days
2. Verify agent name is correct (case-sensitive)
3. Run baseline calculation manually

### Insufficient Data

**Symptom:** `"baselines_calculated": 0, "message": "Insufficient data"`

**Cause:** Not enough historical traces

**Solution:**
1. Reduce window_days: `?window_days=3`
2. Wait for more agent executions
3. Check ClickHouse for span data

### Too Many Alerts

**Symptom:** Receiving alerts constantly

**Cause:** Sensitivity too low

**Solution:**
1. Increase sensitivity: `?sensitivity=3.0`
2. Adjust lookback hours: `?lookback_hours=48`
3. Review root causes to filter noise

---

## Next Steps

1. **Frontend Integration:** Build React dashboard showing drift alerts
2. **Notification System:** Set up email/Slack alerts
3. **Alert Rules:** Configure which anomalies trigger notifications
4. **Historical Analysis:** Track how baselines evolve over time

For questions or feedback, visit: https://github.com/anthropics/prela
