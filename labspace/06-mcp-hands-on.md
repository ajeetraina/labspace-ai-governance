# MCP Hands-On — Enabling MCP for your sandboxes

Section 05 framed **Pillar 2 — MCP Tool Governance** as roadmap. This section gets your hands on the part that's already shipping: the `sbx mcp` subcommand for registering MCP servers your sandboxed agents can call.

There are two ways to enable it. Pick the one that fits you:

- **☁️ MCP Gateway Cloud** — Docker's hosted control plane (`connect.docker.com`). Brokers per-server OAuth on your Docker identity. Recommended.
- **💻 Local MCP Gateway** — the open-source `docker/mcp-gateway` running on your own machine. Good for offline labs.

**Time:** ~15 minutes
**Prerequisites:** Sections 00 and 01, plus `sbx login`.

## Step 1 — Install the nightly `sbx`

MCP features land in the nightly first. On macOS:

```bash no-run-button
brew install docker/tap/sbx@nightly
```

If stable is already installed, switch the symlink:

```bash no-run-button
brew unlink sbx 2>/dev/null; brew link --overwrite sbx@nightly
```

On Linux or Windows, grab the latest pre-release asset from the [releases page](https://github.com/docker/sbx-releases/releases) (`DockerSandboxes-linux.tar.gz`, the `.deb`/`.rpm` packages, or `DockerSandboxes.msi`). Don't download "Source code" — that repo only ships release assets.

```bash no-run-button
sbx version
```

## Step 2 — `sbx mcp` is hidden until you enable it

The command exists but stays hidden until one environment variable is set:

```
SBX_MCP_URL is not set; MCP is not enabled
```

`SBX_MCP_URL` is the gate. It both unlocks the `mcp` subtree in `sbx --help` and tells `sbx` which control plane to talk to. The daemon reads it **on startup**, so after setting it you stop the daemon (it auto-restarts on your next `sbx` call).

## Step 3 — Choose your path

Click a button to pick how you'll enable MCP. The instructions below update to match.

::variableSetButton[☁️ MCP Gateway Cloud (recommended)]{variables="mcpMode=cloud"}
::variableSetButton[💻 Local MCP Gateway]{variables="mcpMode=local"}

:::conditionalDisplay{variable="mcpMode" hasNoValue}

> [!NOTE]
> Pick one of the two buttons above to reveal its steps.

:::

<!-- ───────────────────────── CLOUD PATH ───────────────────────── -->

:::conditionalDisplay{variable="mcpMode" requiredValue="cloud"}

### ☁️ MCP Gateway Cloud

Log in, then point `sbx` at the hosted control plane and restart the daemon:

```bash no-run-button
sbx login
export SBX_MCP_URL=https://connect.docker.com
sbx daemon stop
sbx mcp --help
```

> `connect.docker.com` is publicly reachable — no Tailscale or VPN needed — but you **must** be logged in. The control plane brokers OAuth against your Docker identity and stores credentials centrally, not as plaintext env vars.

#### Add MCP servers

Register servers once; the registrations persist across sessions. Each remote server kicks off a browser OAuth flow tied to your Docker identity:

```bash no-run-button
sbx mcp add notion --url https://mcp.notion.com/mcp
sbx mcp add linear --url https://mcp.linear.app/mcp
sbx mcp add stripe --url https://mcp.stripe.com
```

Need several at once? Register a **bundle** — a JSON document listing multiple servers. Bundle adds are idempotent (re-running updates each server to match the latest document):

```bash no-run-button
sbx mcp bundle add core \
  --url https://gist.githubusercontent.com/slimslenderslacks/87547c8fa827b01a3b2cafa1586f10d7/raw/mcp-servers.json
```

Manage what's registered:

```bash no-run-button
sbx mcp ls                 # registered servers
sbx mcp bundle ls          # registered bundles
sbx mcp inspect notion     # full details (URL, type, OAuth info)
```

#### Use them in a sandbox

Pre-connect servers when you launch an agent (Claude and opencode are supported today):

```bash no-run-button
sbx run claude --name my-session --mcp notion --mcp linear
```

Or launch with none pre-connected — the agent can still discover and add servers at runtime via `mcp-find` and `mcp-add`:

```bash no-run-button
sbx run claude --name my-session
```

:::

<!-- ───────────────────────── LOCAL PATH ───────────────────────── -->

:::conditionalDisplay{variable="mcpMode" requiredValue="local"}

### 💻 Local MCP Gateway

The open-source [`docker/mcp-gateway`](https://github.com/docker/mcp-gateway) proxies MCP traffic to backing servers over stdio/SSE/streaming. Pull the lab's prebuilt Compose file and start it:

```bash no-run-button
mkdir -p ~/workdemo/mcp-gateway-lab && cd ~/workdemo/mcp-gateway-lab
curl -fsSL https://raw.githubusercontent.com/ajeetraina/labspace-ai-governance/main/labspace/assets/mcp-gateway-compose.yaml -o compose.yaml
docker compose up -d
```

It runs `docker/mcp-gateway` with the DuckDuckGo server enabled and exposes the SSE transport on port 8811. Point `sbx` at it:

```bash no-run-button
export SBX_MCP_URL=http://localhost:8811
sbx daemon stop
sbx mcp --help
```

#### Register a local server

Local stdio servers run as Docker containers on your machine. Register one:

```bash no-run-button
sbx mcp add local-ddg --command docker --args "run,-i,--rm,--init,mcp/duckduckgo"
sbx mcp ls
sbx mcp inspect local-ddg
```

> [!WARNING]
> Local stdio servers run on the **host**, not in the sandbox — they have your full user permissions (filesystem, network, secrets). The local gateway is the **data plane**: it can't broker hosted OAuth the way the cloud control plane does, so `sbx mcp add --url https://...` against an OAuth server won't complete the OAuth flow here. Use local mode for offline development and trusted servers.

:::

## A few rules baked into the binary

These will save you debugging time when registering servers:

- **`--url` must be https** — plain http fails with `issuer URL must use https scheme` (`sbx` runs OAuth discovery against it).
- **`--args` is comma-separated**, not space-separated: `--args "run,-i,--rm,mcp/postgres"` is one value.
- **`--command` is an executable**, not a shell string — use `--command docker --args "run,..."`, not `--command "docker run ..."`.

## Step 4 — Clean up

```bash no-run-button
sbx mcp rm local-ddg notion linear stripe 2>/dev/null; sbx mcp ls
```

## How this connects to Pillar 2

Everything you just did is the **developer side** of MCP Tool Governance — registering servers from your CLI. The governance side (org admins approving catalogs, restricting tool sets, injecting per-request secrets) sits in front of the same `sbx mcp` machinery, gated by the control plane that `SBX_MCP_URL` points at.

In other words: today you control what's registered; tomorrow your org admin controls what's *registerable*.
