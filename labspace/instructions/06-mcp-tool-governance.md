# Section 06 — Pillar 2: MCP Tool Governance

> 🎯 **Goal.** Configure Docker MCP Toolkit + Gateway so agents can only call approved MCP tools. Watch an unapproved server be blocked by default and an approved one go through.
>
> 👥 **Audience.** Developers, security leads.
> ⏱ **~10 minutes.**
> 💻 **Hands-on** (parts of the org-level catalog are screenshot-led, like Lab 4).

> ⚠️ **Validate before running.** MCP Toolkit and Gateway are in active development. Re-check the exact CLI / Docker Desktop UI flow against your installed version before running live. Public docs: <https://docs.docker.com/ai/mcp-catalog-and-toolkit/>

## Why MCP needs its own governance layer

MCP (Model Context Protocol) is how agents pull in *tools* — Notion access, GitHub APIs, database connections, internal services, file readers. The ecosystem is exploding. Anyone can publish an MCP server.

That creates two distinct risks:

1. **Tool sprawl.** A developer installs a useful-looking MCP server they found in a tweet. It now has access to their machine's credentials and runs whatever its author wants. No one in the org reviewed it.
2. **Tool abuse.** A legitimate MCP server has a tool the agent shouldn't use in some contexts (e.g. a "delete repository" tool in a GitHub MCP server).

Pillar 2 addresses both. Per the public docker.com page: *"Admins control which MCP servers and tools are available organization-wide. Unapproved servers are blocked by default and every MCP call flows through the same policy engine."*

## Step 1 — See your current MCP setup

Docker MCP Toolkit ships with Docker Desktop. Open Docker Desktop → MCP Toolkit (or use the CLI):

```bash
docker mcp ls
docker mcp catalog ls
```

You'll see the current catalog (the set of MCP servers available to enable) and the active set (the ones turned on for this developer).

## Step 2 — Try to add an unsanctioned server

Suppose a teammate sends you a "really useful" MCP server URL they found online. Try to enable it directly:

```bash
docker mcp enable some-random-mcp-server
```

> 📌 With org governance enabled, this is rejected because the server isn't in the approved org catalog. Without org governance, the local enable succeeds — but that's exactly the problem org-level governance solves.

## Step 3 — Walkthrough: the org catalog

> 📸 **Screenshot.** `assets/screenshots/05-mcp-catalog-admin.png`

In the Admin Console, the MCP catalog page lists every server admins have approved. Each row has:

- Server name and image reference
- Allowed tools within that server (admins can allow the server but disable specific tools)
- Scope: who in the org can enable it
- Status: active / disabled

The catalog is distributed via the developer's Docker login — same auth flow as Pillar 1.

## Step 4 — Hands-on: enable an approved server

For the lab, pick a server that ships with Docker MCP Catalog — for example, a filesystem reader or a GitHub MCP server:

```bash
docker mcp enable github
```

List active servers:

```bash
docker mcp ls
```

You should see `github` as active.

## Step 5 — Watch the gateway in action

Every MCP call flows through the Docker MCP Gateway. Start a sandbox with an agent and an enabled MCP server:

```bash
sbx run --agent docker-agent --workspace ./my-project --mcp github
```

Inside the sandbox, the agent can call GitHub tools. If you ask it to call a tool that *isn't* in the allowed set (e.g. delete-repository when the admin only allowed read-only tools), the gateway denies and logs the attempt.

Watch the gateway log on your host:

```bash
docker mcp logs --follow
```

You should see entries for each tool invocation — request, decision, latency. The denied calls show a clear reason.

## Step 6 — A real-world scenario for Bosch

Imagine the agent in a Mobility codebase needs a Notion MCP server to read the team's design docs. The org admin's job:

1. Approve the Notion MCP server in the catalog.
2. Allow only the read-page and search tools — *not* write or delete.
3. Scope to the Mobility team (other teams don't see it).
4. Audit (Lab 6) shows every Notion call made by every agent.

That's the entire flow:

```
Org catalog → Allowed server → Allowed tools → Scope by team → Audit every call
```

## Step 7 — How this connects to Pillar 1

MCP Tool Governance and Sandbox Policies aren't independent. An MCP server needs network access to reach Notion's API, which means the Sandbox Policy (network access rules) has to allow `api.notion.com`. Approving the tool *and* allowing the network is two policies on the same agent — both enforced.

→ **Defined once, enforced everywhere** is the same model across both pillars.

---

→ Next: **[Section 07 — Pillar 3: Audit & Visibility](07-audit-visibility.md)**
