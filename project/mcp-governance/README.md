# MCP Tool Governance — examples

> ⚠️ **Validate before running.** The Docker MCP CLI surface is still firming up. Re-check exact commands against `docker mcp --help` on your installed version.

## Listing the current catalog and active servers

```bash
docker mcp catalog ls         # All servers in the catalog (org-visible)
docker mcp ls                 # Servers currently enabled on this machine
```

## Enabling an approved server

```bash
docker mcp enable github
docker mcp ls
```

## Trying to enable an unsanctioned server (org governance on)

```bash
docker mcp enable some-random-server
# Expected: rejected — server not in approved org catalog
```

## Restricting tools within an approved server

This is an admin-side configuration in the Admin Console. The developer sees the result: when the agent calls a non-allowed tool, the gateway denies and logs.

Example: GitHub MCP server is approved org-wide, but only read tools are allowed.

```bash
# In the sandbox:
# Agent calls github.get-issue → allowed
# Agent calls github.delete-repository → denied at gateway
```

The corresponding audit events live in `examples/audit/sample-events.jsonl`. Look for events with `request.kind: "mcp"` — both an `allow` (get-issue) and a `deny` (delete-repository) are included.

## Watching the gateway logs

```bash
docker mcp logs --follow
```

Each MCP call shows up here: server, tool, decision, latency, requesting session.

## A note on org catalog vs developer catalog

Two layers:

1. **Org catalog** (Admin Console): the universe of servers approved for use anywhere in the org.
2. **Developer's enabled set** (local): which of the org-approved servers this developer has turned on for their machine.

A developer can only enable servers from the org catalog. They can't add a brand-new server unless an admin approves it first.

## Tool sprawl — the failure mode this prevents

Without governance:

```bash
# Developer reads a blog post recommending a "useful" MCP server.
# Pastes the install command from the blog into their terminal.
# The server now has access to their credentials and runs whatever its author wants.
# Nobody else in the org reviews it. It works → it spreads.
```

With governance:

```bash
# Same developer tries the same paste.
# Local enable rejected by docker mcp because the server isn't in the org catalog.
# Developer files an "approve this server" ticket. Security reviews it. Catalog updated.
# Now everyone benefits — and the audit trail captures who's using it.
```
