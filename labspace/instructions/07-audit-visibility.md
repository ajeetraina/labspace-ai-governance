# Section 07 — Pillar 3: Audit & Visibility

> 🎯 **Goal.** See the structured events Docker AI Governance emits for every policy evaluation. Understand the schema. Pipe them through a simple local viewer that simulates a SIEM. This is the pillar that lets your CISO sign off.
>
> 👥 **Audience.** Security, compliance, audit, platform.
> ⏱ **~10 minutes.**

## Why audit is the pillar that unlocks the others

Sandboxes contain blast radius. MCP governance prevents tool sprawl. But neither answers the CISO's question:

> *"Show me, with evidence, every AI agent action in our org last week. Who ran it, what did it try to do, what was allowed, what was denied, when."*

Without that trail, "we have AI governance" is a claim. With it, it's compliance.

Per the public source: *"Every policy evaluation generates a structured event with user identity, timestamp, session context, and triggering rule. Export to your existing SIEM and compliance systems. Get full traceability, zero blind spots."*

## Step 1 — Generate some events

We want a mix of allowed and denied events. From inside a sandbox:

```bash
sbx shell

# Allowed — in default allowlist
curl -s https://api.anthropic.com/v1/models > /dev/null
curl -s https://github.com > /dev/null

# Denied — not in allowlist
curl -s https://paste.ee 2>&1 | head -3
curl -s https://hooks.slack.com 2>&1 | head -3

# Filesystem — try to mount something denied
exit
```

## Step 2 — Look at the raw events

The sandbox emits structured events for every policy evaluation. Read them locally:

```bash
sbx audit ls --since 5m
```

> ⚠️ **CLI surface to validate.** The exact `sbx audit` subcommand and flags are still firming up. If the command differs in your installed sbx version, swap it in here. Expected behaviour: list the structured events emitted in a given window. Fallback for the lab: write events to a local file with `sbx audit export --output ./events.jsonl`.

Each event is one JSON object per line (JSONL):

```json
{
  "event_id": "evt_01J9X3...",
  "timestamp": "2026-06-10T09:14:22.481Z",
  "user": {
    "id": "user_4f2a",
    "email": "ajeet@bosch-example.com",
    "org": "bosch"
  },
  "session": {
    "id": "sbx_8c7b9",
    "agent": "docker-agent",
    "workspace": "/home/ajeet/projects/mobility-firmware"
  },
  "policy": {
    "rule_name": "default-ai-providers",
    "rule_origin": "remote",
    "rule_type": "network"
  },
  "request": {
    "kind": "network",
    "target": "api.anthropic.com",
    "port": 443
  },
  "decision": "allow",
  "reason": "matched allow rule default-ai-providers"
}
```

For a denied event:

```json
{
  "event_id": "evt_01J9X4...",
  "timestamp": "2026-06-10T09:14:38.102Z",
  "user": {"id": "user_4f2a", "email": "ajeet@bosch-example.com", "org": "bosch"},
  "session": {"id": "sbx_8c7b9", "agent": "docker-agent", "workspace": "/home/ajeet/projects/mobility-firmware"},
  "policy": {"rule_name": "org-deny-exfiltration", "rule_origin": "remote", "rule_type": "network"},
  "request": {"kind": "network", "target": "paste.ee", "port": 443},
  "decision": "deny",
  "reason": "matched deny rule org-deny-exfiltration"
}
```

> 📌 **Every field on this object answers a CISO question.** Who (user). When (timestamp). Where (workspace, session). What (request). Why (rule_name, reason). Decision (allow/deny).

## Step 3 — Use the fake SIEM viewer

The labspace includes a small `jq`-based viewer that simulates what a SIEM would do with this stream. Pipe events into it:

```bash
sbx audit export --output ./events.jsonl
cat ./events.jsonl | bash ./project/audit/view-events.sh
```

The viewer aggregates by decision, by user, by rule, and lists top denied targets — exactly the kinds of dashboards your SIEM (Splunk, Datadog, Sentinel, Elastic) would build.

Example output:

```text
=== Audit summary (last 5 minutes) ===

Total events:        47
  allowed:           39 (83%)
  denied:             8 (17%)

By user:
  ajeet@bosch-example.com       47

By rule:
  default-ai-providers            (allow)    21
  default-package-mgrs            (allow)    12
  default-source                  (allow)     6
  org-deny-exfiltration           (deny)      5
  org-deny-unsanctioned-llm       (deny)      3

Top denied targets:
  paste.ee                                    3
  hooks.slack.com                             2
  api.unknown-llm.example                     2
  discord.com                                 1

Anomaly check:
  ⚠ user ajeet@bosch-example.com triggered 5+ denies
    on org-deny-exfiltration in <5min — investigate.
```

## Step 4 — Pipe to a real SIEM

For real environments, you'd forward `events.jsonl` (or the event stream) to your SIEM. The output format is plain JSON per line, which every SIEM ingests natively. Common patterns:

- **Splunk:** universal forwarder → HEC, indexed as JSON.
- **Datadog:** Logs Agent watches the file path, parses JSON.
- **Elastic:** Filebeat reads JSONL, posts to Logstash / Elasticsearch.
- **Microsoft Sentinel:** Log Analytics Agent or Logstash output.
- **OpenTelemetry:** structured events map cleanly onto OTel attributes.

## Step 5 — Compliance angles to know

Several regulatory frameworks now require audit trails for autonomous systems. The structured event format above maps to:

- **SOC 2 CC7.2** — system monitoring of unauthorised actions.
- **ISO 27001 A.12.4** — event logging.
- **EU AI Act** — record-keeping for high-risk AI systems.
- **NIST AI RMF** — measure and manage actions, decisions, and outcomes.

You don't need to memorise the mapping — but when the CISO asks "can we evidence agent behaviour for SOC 2", the answer is "yes, here's the JSON stream feeding the SIEM."

## Step 6 — One more thing: the rule origin matters

Notice that every event has `policy.rule_origin: local` or `remote`. When auditing, this matters:

- `remote` (org-defined) — same rule across every developer. Predictable.
- `local` (developer-defined) — could vary. Worth flagging in dashboards.

A good SIEM dashboard surfaces:

- Denied events grouped by rule (which org policies are working hardest)
- Allowed events to *unusual* domains (which delegated local rules are being added)
- Per-user volume (anomaly detection)

---

→ Next: **[Section 08 — Bosch Scenarios](08-bosch-scenarios.md)**
