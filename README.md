# Docker AI Governance Labspace

A hands-on lab that proves how Docker AI Governance policies flow from one Admin Console toggle to every developer's `sbx` sandbox, with empirical tests for both network and filesystem enforcement.

**Define once. Enforce everywhere.**

## What this lab proves

- Policies set in `app.docker.com/admin/orgs/<your-org>` flow automatically to any developer logged in with org credentials
- Network rules are enforced by an in-proxy `403` at request time
- Filesystem rules are enforced at sandbox creation time — denied mounts cause `sbx run` to fail before the agent ever runs
- The default-deny posture catches anything not covered by an allow rule
- Developers cannot override `ORIGIN: remote` policies locally

By the end you have a defensible enforcement story you can walk a security team through.

## Quick start

```bash
git clone https://github.com/ajeetraina/labspace-ai-governance
cd labspace-ai-governance
bash start-labspace.sh
```

Then visit [http://localhost3030](http://localhost:3030) in your browser.

## Prerequisites

- **Docker Desktop** with `sbx` (Docker Sandboxes) available on `$PATH`
- **Admin access** to a Docker Hub organization with AI Governance enabled
- **A logged-in Docker CLI** (`docker login` with your org credentials)

If you don't have an organization yet, you can still walk through Sections 00-02 conceptually — the demo sections (03, 04) need org-level admin access to add policy rules.

## Lab structure

| # | Section | Time | What you do |
| --- | --- | --- | --- |
| 00 | Setup | 2 min | Pick your org and verify sbx is installed |
| 01 | Why AI Governance | 3 min | Horror stories, three pillars framing |
| 02 | The Policy Model | 5 min | Conceptual: how org → developer policy flow works |
| 03 | Network Enforcement Demo | 10 min | Three `curl` commands, three outcomes (allow / deny / default-deny) |
| 04 | Filesystem Enforcement Demo | 10 min | Three `sbx run` attempts, same three outcomes |
| 05 | What's Next | 5 min | Preview of audit trails and MCP Tool Governance |

Total walkthrough: ~35 minutes.

## The three pillars

Docker AI Governance gives you three layers of control:

1. **Sandbox Policies** — Network and filesystem rules enforced at the proxy and mount layer. *Validated in Sections 03 and 04.*
2. **MCP Tool Governance** — Which MCP servers and tools agents can call. *Previewed in Section 05.*
3. **Audit + Visibility** — Every policy decision generates a structured event for your SIEM. *Previewed in Section 05.*

This lab focuses on Pillar 1 because that's what you can empirically prove enforces in 20 minutes. Pillars 2 and 3 are framed honestly as roadmap/preview content.

## What was empirically validated

Every command in Sections 03 and 04 was tested end-to-end on the `dockerdevrel` org. Key findings baked into the lab:

- **Network rules:** in-proxy interception, returns HTTP 403 to denied destinations. `allow AI services` + `allow Docker services` + `deny exfiltration` is the minimum viable demo configuration.
- **`allow all IPs` (`0.0.0.0/0`) is a trap.** It defeats every deny rule. Section 03 explicitly removes it.
- **Filesystem rules:** mount-time enforcement, not runtime. `sbx run` checks every mount path against policy before starting the sandbox; denied paths cause sandbox creation to fail with `403 mount policy denied`.
- **macOS path canonicalisation:** `/tmp` resolves to `/private/tmp` in policy evaluation. Important if you write rules targeting `/tmp/...`.
- **Sandbox name collisions:** sbx auto-names sandboxes by `<agent>-<workdir>`. Re-running from the same workdir fails. The lab uses three distinct workdirs in Section 04 to avoid this.

The audit subcommand (`sbx audit`) is not yet available on the sbx CLI. Section 05 points to the local daemon log as the inspection surface today and marks the structured audit CLI as roadmap.


## Architecture

Built on the `labspace-sbx` template. The labspace itself runs in a Docker Compose stack:

- **Left panel** — labspace UI renders the markdown sections with variable substitution (`$$org$$`) and click-to-run code blocks
- **Right panel** — `ttyd` exposes your host zsh on port 8085, so click-to-run commands execute on your real machine where `sbx` is installed and your Docker credentials live

Click-to-run code blocks use `terminal-id=main` to target the right-panel terminal.

## File layout

```
labspace-ai-governance/
├── README.md                    # this file
├── labspace/
│   ├── labspace.yaml            # section registry
│   ├── 00-setup.md              # org variable + presets
│   ├── 01-introduction.md       # why + three pillars
│   ├── 02-the-policy-model.md   # conceptual
│   ├── 03-network-demo.md       # validated
│   ├── 04-filesystem-demo.md    # validated
│   └── 05-whats-next.md         # roadmap / preview
├── start-labspace.sh            # bring up the Compose stack
├── compose.yaml
├── compose.override.yaml
└── kits/                        # ancillary content kits (optional)
```

## Feedback

Issues, corrections, or enhancements welcome at the repo. The validation note in Section 04 calls out areas where the sbx behaviour may evolve — PRs that update the lab against a newer sbx version are particularly helpful.

