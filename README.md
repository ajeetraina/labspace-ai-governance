# Labspace for Docker AI Governance

An interactive hands-on lab covering the three pillars of **Docker AI Governance** — Sandbox Policies, MCP Tool Governance, and Audit & Visibility — built on the same `ttyd + Mac terminal` Labspace pattern as [`labspace-sbx`](https://github.com/ajeetraina/labspace-sbx).

The labspace UI runs in your browser at `http://localhost:3030`:

- **Left panel** → Lab instructions (this content)
- **Right panel** → Your Mac terminal with `sbx` and `docker mcp` ready to use

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) 4.45+
- [ttyd](https://github.com/tsl0922/ttyd) — `brew install ttyd`
- [sbx](https://github.com/docker/sbx-releases) — `brew install docker/tap/sbx`

`start-labspace.sh` checks all three on launch and tells you what to install if anything is missing.

## Quick start

```bash
git clone https://github.com/ajeetraina/labspace-ai-governance
cd labspace-ai-governance
bash start-labspace.sh
```

Open <http://localhost:3030>.

When you're done:

```bash
bash disable-run.sh   # or just Ctrl-C in the start-labspace.sh window
```

## What you'll learn

- **Why AI coding agents inherit your permissions** — and what that means for SSH keys, cloud credentials, internal repos, and any URL on the internet.
- **Pillar 1 — Sandbox Policies.** Network and filesystem allow/deny rules with `sbx policy`. Local rules, org rules, precedence, and propagation via the auth flow.
- **The Blast Radius Test.** Run the same attack patterns against an unconstrained agent vs an agent in a policy-bounded sandbox. Side-by-side, on your own machine.
- **Pillar 2 — MCP Tool Governance.** Approved MCP catalogs, per-tool allowlists within an approved server, and what happens when an agent tries to call a denied tool.
- **Pillar 3 — Audit & Visibility.** Structured events for every policy evaluation, SIEM-shape JSON, and how this lands with your CISO.
- **Bosch-style mapping** for four enterprise verticals (Mobility, iBike, Manufacturing, R&D) — concrete network/filesystem/MCP policy fragments per unit.

## Sections

| # | Section | Pillar |
|---|---------|--------|
| 00 | Setup — enter your Docker org | — |
| 01 | Introduction — the three pillars | — |
| 02 | Horror Stories — agent with no boundaries | — |
| 03 | Sandbox Policies (local) | 1 |
| 04 | Blast Radius Test | 1 |
| 05 | Org Governance walkthrough | 1 |
| 06 | MCP Tool Governance | 2 |
| 07 | Audit & Visibility | 3 |
| 08 | Bosch scenarios — per-vertical mapping | All |
| 99 | Validation checklist (facilitators only) | — |

## Personalising — your Docker org

Section 00 asks for your Docker org name (default `acme-corp`). The labspace stores it in `project/setup/.env` and substitutes it through Sections 05, 07, and 08 — so policy examples reference *your* internal domains instead of generic placeholders.

For the Bosch BU-level session: type `bosch` at the prompt and the labs read naturally to that audience.

## Repo layout

```
labspace-ai-governance/
├── labspace/
│   ├── labspace.yaml          # Section ordering and metadata
│   ├── content/               # Lab markdown (00–08, 99)
│   └── assets/screenshots/    # Admin Console screenshots
├── project/                   # Supporting files and helper scripts
│   ├── horror-story-agent/    # inventory.sh — what an agent could touch
│   ├── policies/              # Sample sbx policy templates
│   ├── mcp-governance/        # MCP Toolkit reference
│   ├── audit/                 # view-events.sh + sample-events.jsonl
│   └── setup/                 # setup-org.sh, render-org.sh
├── start-labspace.sh          # ttyd + compose launcher (host-side)
├── disable-run.sh             # Stop everything
├── blast-radius.sh            # Guided Blast Radius scenario runner
├── compose.yaml
└── compose.override.yaml
```

## Validation before running with a customer

Read `labspace/content/99-validation-checklist.md` before facilitating with Bosch or any external audience. The content was authored against public Docker docs and may need to be re-checked against your installed `sbx` version — especially the audit CLI (`sbx audit ls / export`) which is the part I'm least sure about.

## License

Apache-2.0 (matches the parent template).
