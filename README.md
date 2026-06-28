# Docker AI Governance Labspace

A hands-on lab that proves how Docker AI Governance policies flow from one Admin Console toggle to every developer's `sbx` sandbox, with empirical tests for both network and filesystem enforcement.

**Define once. Enforce everywhere.**

## What this lab proves

- Policies set in `app.docker.com/admin/orgs/<your-org>` flow automatically to any developer logged in with org credentials
- Network rules are enforced by an in-proxy `403` at request time
- Filesystem rules are enforced at sandbox creation time - denied mounts cause `sbx run` to fail before the agent ever runs
- The default-deny posture catches anything not covered by an allow rule
- Developers cannot override `ORIGIN: remote` policies locally
- MCP servers register through `sbx mcp` behind the **Docker MCP Gateway**, so sandboxed agents reach tools through one governed control plane
- Policies can be authored two ways - the Hub Admin Console UI or the **Docker AI Governance API** - both writing to the same source of truth

By the end you have a defensible enforcement story you can walk a security team through.

## Two ways to set up policies

This labspace supports two methods for authoring and applying AI Governance policies - both write to the same source of truth, so you can pick whichever fits your workflow:

1. **AI Governance API** - Drive the control plane programmatically over HTTP. Author, update, and apply policies via API calls (see Section 11). Ideal for automation, CI/CD, and infrastructure-as-code workflows.
2. **Manual Setup** - Use the Hub Admin Console UI at `app.docker.com/admin/orgs/<your-org>` to toggle and author policy rules by hand. Ideal for getting started and for teams who prefer a visual workflow.

## Quick start

### Launch the labspace directly

```bash
docker labspace launch ajeetraina777/labspace-ai-governance
```

> **Note on the terminal:** This lab teaches `sbx`, which must run on your
> **host** (not inside a container). The IDE terminal is therefore served by
> the **Labspace Compose provider** (`workspace.provider.type: labspace` in
> `compose.override.yaml`) — the provider handles the terminal for you, so
> there's nothing extra to install. This provider is rolling out with the
> Labspace tooling — if `docker labspace launch` errors on
> `provider.type: labspace`, your build doesn't ship it yet.

#### Troubleshooting the launch

**`Docker socket mount denied ... image is not in the allowed list`**
(`mikesir87/docker-socket-proxy`) — Docker Desktop's **Enhanced Container
Isolation (ECI)** is blocking the socket proxy the Labspace framework uses.
This is common on company-managed Docker installs, where ECI is enforced by
admin policy. Fix it one of two ways:

- **Allow-list the image (preferred on managed machines):** add
  `mikesir87/docker-socket-proxy` to the ECI Docker-socket image list in
  `admin-settings.json` (under
  `enhancedContainerIsolation.dockerSocketMount.imageList`). This is set by
  a Docker Desktop admin and survives policy syncs. There is no GUI field for
  this list — it lives in `admin-settings.json` only.
- **Disable ECI:** Docker Desktop → **Settings → General** → uncheck
  **Use Enhanced Container Isolation**. Quick, but may be locked or reverted
  by your org's policy.

The allow-list block in `admin-settings.json` looks like this (merge the
`images` entry into any existing `enhancedContainerIsolation` block rather
than overwriting the file):

```json
{
  "configurationFileVersion": 2,
  "enhancedContainerIsolation": {
    "value": true,
    "dockerSocketMount": {
      "imageList": {
        "images": ["docker.io/mikesir87/docker-socket-proxy:*"]
      }
    }
  }
}
```

`admin-settings.json` lives at `C:\ProgramData\DockerDesktop\admin-settings.json`
(Windows), `/Library/Application Support/com.docker.docker/admin-settings.json`
(macOS), or `/usr/share/docker-desktop/admin-settings.json` (Linux). It is read
**only at Docker Desktop startup**, so fully quit and relaunch after editing.

> **Caveat for company-managed laptops:** on a managed Docker Desktop,
> `admin-settings.json` is usually **pushed centrally** via the org's Settings
> Management, so local edits get overwritten on the next sync (and you may not
> have write access to the file at all). In that case the allow-list must be
> added by whoever administers Docker Desktop for your org — through
> **Admin Console → Docker Desktop → Settings Management**, which distributes
> the `admin-settings.json` to all managed devices. That's the durable,
> fleet-wide fix; disabling ECI locally only works if org policy permits it.

**`failed to connect to the docker API at ... dockerDesktopLinuxEngine ...
The system cannot find the file specified`** — Docker Desktop's Linux engine
isn't running. Start Docker Desktop (and on Windows, ensure it's in
**Linux containers** mode, not Windows containers), then confirm with
`docker version` showing a **Server** section before retrying.

### Running it locally

```bash
git clone https://github.com/ajeetraina/labspace-ai-governance
cd labspace-ai-governance

# Option A — checks prerequisites, then brings up the stack
bash start-labspace.sh

# Option B — content-dev mode (auto-syncs your edits)
CONTENT_PATH=$PWD docker compose up --watch
```

Then visit [http://localhost:3030](http://localhost:3030) in your browser.

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
| 02 | The Policy Model | 5 min | Conceptual: two policy-authoring paths (Hub Admin Console + Governance API) and how org → developer policy flow works |
| 03 | Network Enforcement Demo | 10 min | Three `curl` commands, three outcomes (allow / deny / default-deny) |
| 04 | Filesystem Enforcement Demo | 10 min | Three `sbx run` attempts, same three outcomes |
| 07 | Product Catalog | 15 min | Turn an autonomous coding agent loose on a real Node.js app, contained by your policies |
| 06 | MCP Hands-On | 15 min | Register MCP servers with `sbx mcp` behind the Docker MCP Gateway (remote OAuth, docker.io image, local stdio) |
| 08 | Observability | 10 min | Inspect the audit trail and the live sbx/MCP dashboard |
| 09 | Monitoring Policies | 10 min | Watch policy decisions as they happen |
| 10 | Audit Logging | 10 min | Trace every allow/deny back to a rule |
| 11 | Governance API | 15 min | Drive the same control plane programmatically over HTTP |
| 05 | What's Next | 5 min | Preview of audit trails and MCP Tool Governance |

Total walkthrough: ~110 minutes.

