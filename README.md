# Docker AI Governance Labspace

A hands-on lab that proves how Docker AI Governance policies flow from one Admin Console toggle to every developer's `sbx` sandbox, with empirical tests for both network and filesystem enforcement.

**Define once. Enforce everywhere.**

## What this lab proves

- Policies set in `app.docker.com/admin/orgs/<your-org>` flow automatically to any developer logged in with org credentials
- Network rules are enforced by an in-proxy `403` at request time
- Filesystem rules are enforced at sandbox creation time - denied mounts cause `sbx run` to fail before the agent ever runs
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

- **`sbx` (Docker Sandboxes)** installed and available on `$PATH` - Docker Desktop is not required
- **Admin access** to a Docker Hub organization with AI Governance enabled
- **A logged-in Docker CLI** (`docker login` with your org credentials)

If you don't have an organization yet, you can still walk through Sections 00-02 conceptually - the demo sections (03, 04) need org-level admin access to add policy rules.

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

