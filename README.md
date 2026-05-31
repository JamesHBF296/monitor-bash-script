# Monitor Bash Scripts

## Overview
`monitor-bash-scripts` is a lightweight Bash‑based monitoring suite designed to run on Linux hosts.  It periodically checks the health of critical services, gathers basic system metrics (CPU load, memory, disk usage), and sends alerts via **Telegram** and **AWS SNS**.  All configuration is driven by a `config.env` source script, making the tool easy to drop into existing servers.

---

## Features
- **Service health checks** – verifies that a configurable list of services (e.g. `nginx`, `dockerd`, `sshd`) are active; attempts to start them up to three times before raising an alert.
- **System metrics** – collects CPU utilisation, load average, memory usage and disk utilisation.
- **Multi‑channel alerts** – sends a message to a Telegram bot and publishes to an AWS SNS topic.
- **Centralised logging** – writes timestamped entries to `/var/log/<module>_log.log` for each module.
- **Modular design** – each concern lives in its own Bash module (`metrics.sh`, `services.sh`, `alert.sh`).

---

## Prerequisites
| Tool | Reason |
|------|--------|
| `bash` (≥ 4) | Core interpreter |
| `curl` | Telegram API calls |
| `jq` | JSON handling for SNS responses |
| `awscli` | Publish to SNS |
| `mpstat` (from `sysstat` package) | Accurate CPU utilisation |
| `systemctl` | Service status & control |
| `sudo` | Required for writing to `/var/log` and starting services |

Make sure these utilities are installed and available in `$PATH`.

---

## Installation
```bash
# Give execution permission to all scripts
chmod +x *.sh module/*.sh
```

---

## Configuration
1. **Create a `config.env` file**.  It should define the following variables:
   ```dotenv
   # Telegram settings
   BOT_TOKEN="<your-telegram-bot-token>"
   CHAT_ID="<your-telegram-chat-id>"

   # AWS SNS settings
   TOPIC_ARN="arn:aws:sns:<region>:<account-id>:<topic-name>"
   AWS_REGION="<aws-region>"
   ```
2. **Source the configuration** – `main.sh` loads `config.env`.
3. **Edit the service list** – modify the `SERVICES` array in `main.sh` to include any additional daemons you want to monitor.

---

## Usage
```bash
# Run the monitoring script (you may want to add this to cron or a systemd service)
./main.sh
```
The script will:
1. Source `config.env` and the module scripts.
2. Run `check_service` with the defined services.
3. Run `check_metrics` to collect system information.
4. Send an alert if any service fails to start or if metric collection encounters an error.

---

## Module Overview
| Module | Purpose |
|--------|---------|
| `metrics.sh` | Gathers CPU, load‑average, memory and disk statistics, formats a JSON payload and forwards it to `alert`.
| `services.sh` | Accepts a list of service names, checks each with `systemctl`, attempts to start non‑running services (up to 3 retries), logs results, and aggregates any failures for alerting.
| `alert.sh` | Provides three helper functions:
- `log` – writes a timestamped entry to `/var/log/<module>_log.log`.
- `telegram` – posts a plain‑text message to a Telegram bot.
- `sns_alert` – publishes the same message to an AWS SNS topic.
- `alert` – convenience wrapper that calls both `telegram` and `sns_alert`.
| `main.sh` | Orchestrates the workflow by sourcing the config and the three modules, defining the service array, and invoking the checks.

---

## Logging
All log files are stored under `/var/log/` and are named after the module that generated them, e.g.:
- `/var/log/services_log.log`
- `/var/log/alert_log.log`

The `log` function automatically creates the file (with `sudo`) if it does not exist.

---

## Alerts
The system will send alerts in two ways:
1. **Telegram** – immediate notification to the configured chat.
2. **AWS SNS** – useful for downstream processing (Lambda, email, SMS, etc.).

Both channels are invoked by the `alert` wrapper, so you only need to call `alert "Your message"` from any module.

