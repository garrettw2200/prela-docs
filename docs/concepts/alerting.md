# Alerting

Prela's alerting system monitors your agent metrics and sends notifications when thresholds are crossed. Alerts are evaluated continuously in the background and can notify via **Slack**, **Email**, or **PagerDuty**.

---

## Supported Metrics

| Metric | Description | Example Use Case |
|---|---|---|
| `error_rate` | Percentage of spans with error status | Alert when error rate exceeds 5% |
| `latency_p95` | 95th percentile latency (ms) for LLM spans | Alert when P95 exceeds 3000ms |
| `latency_mean` | Average latency (ms) for LLM spans | Alert when mean latency spikes |
| `cost_per_trace` | Average cost per trace (USD) | Alert when costs exceed budget |
| `success_rate` | Percentage of successful spans | Alert when success drops below 95% |
| `token_usage` | Total tokens consumed | Alert on unusual token consumption |

---

## Creating an Alert Rule

Alert rules are managed via the REST API:

```bash
curl -X POST https://api.prela.dev/api/v1/alerts/projects/{project_id}/rules \
  -H "Authorization: Bearer $PRELA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "High Latency Alert",
    "metric_type": "latency_p95",
    "condition": "gt",
    "threshold": 3000,
    "evaluation_window_minutes": 60,
    "severity": "high",
    "notify_slack": true,
    "slack_webhook_url": "https://hooks.slack.com/services/...",
    "cooldown_minutes": 30
  }'
```

Or use the Prela dashboard at **Alerts** in the navigation.

---

## Alert Rule Configuration

| Field | Type | Default | Description |
|---|---|---|---|
| `name` | `str` | Required | Human-readable alert name |
| `description` | `str` | `None` | Optional description |
| `enabled` | `bool` | `true` | Whether this rule is active |
| `metric_type` | `str` | Required | One of the 6 supported metrics |
| `condition` | `str` | Required | `gt`, `lt`, `gte`, or `lte` |
| `threshold` | `float` | Required | Numeric threshold value |
| `evaluation_window_minutes` | `int` | `60` | Time window to evaluate (5-1440 min) |
| `agent_name` | `str` | `None` | Filter to a specific agent |
| `severity` | `str` | `"medium"` | `low`, `medium`, `high`, `critical` |
| `cooldown_minutes` | `int` | `30` | Minimum time between notifications (5-1440 min) |

---

## Notification Channels

### Slack

Send alerts to a Slack channel via webhook URL.

```json
{
  "notify_slack": true,
  "slack_webhook_url": "https://hooks.slack.com/services/T00/B00/xxx"
}
```

Slack messages include severity-colored headers, metric details, and a link to the dashboard.

### Email

Send alerts to one or more email addresses. Requires SMTP configuration on the backend.

```json
{
  "notify_email": true,
  "email_addresses": ["ops@company.com", "lead@company.com"]
}
```

### PagerDuty

Trigger PagerDuty incidents using the Events API v2.

```json
{
  "notify_pagerduty": true,
  "pagerduty_routing_key": "your-routing-key"
}
```

Alert severity is mapped to PagerDuty severity: critical -> critical, high -> error, medium -> warning, low -> info.

---

## How Evaluation Works

1. The alert evaluation loop runs as a background task in the API Gateway (configurable interval, default 5 minutes).
2. For each enabled rule, the system queries ClickHouse for the metric value over the evaluation window.
3. If the condition is met (e.g., `latency_p95 > 3000`), notifications are dispatched to all configured channels.
4. **Cooldown deduplication** prevents repeated notifications -- after an alert fires, it won't fire again until the cooldown period expires.

---

## API Reference

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/v1/alerts/projects/{project_id}/rules` | Create an alert rule |
| `GET` | `/api/v1/alerts/projects/{project_id}/rules` | List alert rules |
| `GET` | `/api/v1/alerts/projects/{project_id}/rules/{rule_id}` | Get a specific rule |
| `PUT` | `/api/v1/alerts/projects/{project_id}/rules/{rule_id}` | Update a rule |
| `DELETE` | `/api/v1/alerts/projects/{project_id}/rules/{rule_id}` | Delete a rule |
| `GET` | `/api/v1/alerts/projects/{project_id}/triggered` | Get triggered alert history |

---

## Example: Slack Alert for Error Rate

```bash
curl -X POST https://api.prela.dev/api/v1/alerts/projects/my-project/rules \
  -H "Authorization: Bearer $PRELA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Error Rate Spike",
    "metric_type": "error_rate",
    "condition": "gt",
    "threshold": 0.05,
    "evaluation_window_minutes": 30,
    "severity": "critical",
    "notify_slack": true,
    "slack_webhook_url": "https://hooks.slack.com/services/T00/B00/xxx",
    "cooldown_minutes": 60
  }'
```

This creates an alert that fires when the error rate exceeds 5% over a 30-minute window, sends a Slack notification, and won't fire again for at least 60 minutes.
