# What's Next

You just proved **Pillar 1 — Sandbox Policies** end-to-end. Here's a preview of Pillars 2 and 3.

> ⚠️ **Preview content.** The commands and screenshots below illustrate the model. Specific subcommands and Admin Console UI may vary by sbx version. Run `sbx --help` and `sbx <subcommand> --help` for the exact surface on your installed version.

## Pillar 2 — MCP Tool Governance

MCP (Model Context Protocol) servers give agents access to tools — GitHub, Notion, your internal APIs, custom servers your team builds. Each tool can be a new attack surface.

Docker AI Governance lets org admins define:

- **Which MCP servers** are approved for agents in `$$org$$`
- **Which tools** within each server are usable
- **Which catalogs** developers can pull from (curated Hub catalog vs. open public sources)
- **Credential management** — how secrets are injected per request, never persisted on the agent

When configured, an agent attempting to call an unapproved tool gets the same kind of policy-denied error you saw with the network proxy in Section 03.

This is the **MCP Gateway** layer in the Docker AI Governance architecture. It sits between agent and tool, evaluating every call against the same policy engine that enforces sandbox network rules.

## Pillar 3 — Audit and Visibility

Every policy decision — allow or deny, network or filesystem or MCP — generates a structured audit event.

Conceptually:

```json
{
  "timestamp": "2026-06-01T01:35:22Z",
  "user": "ajeetraina777",
  "org": "$$org$$",
  "sandbox_id": "sbx_abc123",
  "rule_type": "network",
  "rule_name": "deny exfiltration",
  "decision": "deny",
  "resource": "paste.ee:443",
  "agent": "shell"
}
```

These events stream to your existing SIEM (Splunk, Datadog, Elastic, Sentinel) for retention, alerting, and compliance reporting.

To explore the audit surface on your install:

```bash terminal-id=main
sbx audit --help
```

Then try whatever subcommands are listed. Common ones:

```bash terminal-id=main
sbx audit ls
```

The `paste.ee` and `example.com` denials from Section 03 should appear as events if audit is wired in.

## The complete three-pillar picture

| Pillar | What it controls | Where it's enforced | Section in this lab |
| --- | --- | --- | --- |
| 1. Sandbox policies | Network, filesystem, resource limits | Network proxy, mount layer | **Section 03 (validated)** |
| 2. MCP tool governance | Which tools agents can call | MCP Gateway | Preview above |
| 3. Audit + visibility | Every policy decision logged | Audit event stream → SIEM | Preview above |

All three share **one policy engine** and **one source of truth** (the Admin Console).

## Where to go from here

- **Product page:** [docker.com/products/ai-governance](https://www.docker.com/products/ai-governance/)
- **Docker docs:** Check [docs.docker.com](https://docs.docker.com) for the latest AI governance documentation
- **The accompanying deck** covers the policy framework and supporting architecture in more depth

## Quick recap

You proved:

- Policies defined once in the Admin Console flow automatically to every developer's `sbx`
- Three rules — two allows and one deny — enforce a real security model
- The default-deny posture catches anything you didn't explicitly approve
- Developers can't override the policies locally — the CISO retains control

That's the working version of "AI governance" you can defend to a security team.
