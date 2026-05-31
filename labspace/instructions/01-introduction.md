# Section 01 — Introduction: The Three Pillars

> 📖 **Read this first.** Sets context for everything that follows.
> ⏱ **~5 minutes.**

## How this labspace works

When you launch this labspace with `bash start-labspace.sh`, two things start on your Mac:

1. **ttyd** binds to your host shell (zsh) and exposes it on port 8085.
2. **The labspace UI** renders these lab pages on the left panel of `http://localhost:3030`, with the ttyd terminal embedded on the right.

**Right panel = your actual host shell**, with `sbx` and `docker mcp` already on `$PATH`. Every command in this labspace runs there. No need for a separate terminal window.

Why this matters: `sbx` needs hypervisor access (`/dev/kvm` on Linux, the host hypervisor on Mac/Win) to launch microVMs. That's why we don't try to run it inside a code-server container — ttyd bridges the browser directly to the host shell where sbx already works.


## Why we need AI governance

In the last 18 months, AI coding agents have moved from autocomplete to autonomy. Claude Code, Codex, Copilot, Cursor, Gemini, Droid, OpenCode, Docker Agent — they read files, write code, run tests, install packages, hit external APIs, and call MCP tools. Most of them run **directly on the developer's laptop, with the developer's permissions**.

That means by default:

- The agent can read every SSH key, every `.env` file, every `~/.aws/credentials` it can find.
- The agent can `git push` to any repo the developer has access to.
- The agent can call any URL on the public internet.
- The agent can install any package from any registry.
- If the agent gets a prompt-injection payload from a webpage, README, or scraped doc, it executes the injected instruction with **your** identity and **your** filesystem.

In short — **agents inherit your permissions**. Great productivity. Zero boundaries. Total mayhem when something goes wrong.

This labspace is about putting boundaries back in place — at three different layers — without slowing down the developer.

## The three pillars

Docker AI Governance is one tagline, three pillars:

### 1. Sandbox Policies — Network and filesystem control. Enforced, not advised.

Define allow and deny rules for domains, IPs, and CIDRs. Set filesystem mount rules with read-only or read-write scope. Enforcement happens at the proxy and mount level, not at the agent's discretion.

Docs: <https://docs.docker.com/ai/sandboxes/security/governance/>

### 2. MCP Tool Governance — Control which tools agents can use. Org-wide, by default.

Admins control which MCP servers and tools are available organization-wide. Unapproved servers are blocked by default and every MCP call flows through the same policy engine.

Docs: <https://docs.docker.com/ai/mcp-catalog-and-toolkit/>

### 3. Audit + Visibility — The proof CISOs need to confidently approve AI.

Every policy evaluation generates a structured event with user identity, timestamp, session context, and triggering rule. Export to your existing SIEM and compliance systems. Full traceability, zero blind spots.

Source: <https://www.docker.com/products/ai-governance/>

## The "defined once, enforced everywhere" model

```
┌─────────────────────────────────────────────────────────┐
│  Docker Admin Console (app.docker.com/admin)            │
│  AI Governance settings                                  │
│  ├─ Network access rules                                 │
│  ├─ Filesystem access rules                              │
│  └─ MCP tool catalog + access                            │
└──────────────────────┬──────────────────────────────────┘
                       │
                       │  Propagated through the auth flow
                       │  developers already use (Docker login)
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Developer's machine (host)                              │
│  ├─ sbx daemon — pulls org policies                      │
│  ├─ Sandbox microVM — enforces network + filesystem      │
│  ├─ MCP Gateway — enforces tool allowlist                │
│  └─ Structured events — exported to SIEM                 │
└─────────────────────────────────────────────────────────┘
```

**Two halves of the same system:**

- The **Admin Console** is where policies are *defined* (admins, once, org-wide).
- The **`sbx` CLI** (on the host) is where policies are *enforced* (every developer's machine, every agent run).

## Where are we headed?

| § | Section | Pillar |
|---|---------|--------|
| 02 | Horror Stories — agent without boundaries | — |
| 03 | Sandbox Policies (local) | 1 |
| 04 | Blast Radius Test | 1 |
| 05 | Org Governance walkthrough | 1 |
| 06 | MCP Tool Governance | 2 |
| 07 | Audit & Visibility | 3 |
| 08 | Bosch scenarios | All |

→ Next: **[Section 02 — Horror Stories](02-horror-stories.md)**
