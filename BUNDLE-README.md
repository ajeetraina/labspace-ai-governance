# labspace-ai-governance — v5 bundle

Self-contained tarball of the Docker AI Governance labspace. Extract anywhere and run.

## What's in v5

| Path | What |
|---|---|
| `install-v5.sh` | Idempotent installer. Backs up any existing `labspace/`, drops in v5 content, optionally adds root compose files. |
| `compose.yaml` + `compose.override.yaml` | Labspace UI stack (markdown renderer on `:3030` + ttyd terminal on `:8085`). |
| `start-labspace.sh` | Brings the stack up. |
| `labspace/00-setup.md` | Pick your Docker org. Default: `whalecollab`. |
| `labspace/01-introduction.md` | Why AI Governance — three pillars framing. |
| `labspace/02-the-policy-model.md` | How org policies reach developers; local vs remote. |
| `labspace/03-network-demo.md` | Network enforcement demo. Three rules, three `curl`s, three outcomes. Includes MITM proxy explanation. |
| `labspace/04-filesystem-demo.md` | Filesystem enforcement demo. Mount-time policy checks. |
| `labspace/06-mcp-hands-on.md` | `sbx mcp` registration with four modes + local gateway variant. |
| `labspace/08-observability.md` | Audit log + live dashboard. Honest about prompts / tool-call / user-attribution gaps. |
| `labspace/05-whats-next.md` | Closing — roadmap framing for Pillar 3 SIEM/audit features. |
| `labspace/assets/mcp-gateway-compose.yaml` | Reusable Compose recipe for a local `docker/mcp-gateway` with `--verbose=true`. |
| `labspace/kits/observability/` | Go backend + single-page HTML UI that tails sbx daemon log + MCP gateway containers and streams events live to `http://localhost:8090`. |

## Quick start

```bash
tar -xzf labspace-ai-governance-v5.tar.gz
cd labspace-ai-governance-v5
bash install-v5.sh                # into the current directory
bash start-labspace.sh            # then visit http://localhost:3030
```

To run the observability dashboard:

```bash
cd labspace/kits/observability
docker compose --profile with-gateway up -d --build
open http://localhost:8090
```

## Prerequisites

- Docker Desktop with the `sbx` CLI installed (nightly recommended for full MCP feature surface)
- A Docker Hub organisation with a Docker Business subscription (for the AI Governance feature)
- Admin access to that org (to set the policies the lab tests against)

## Org-specific configuration

The lab uses `whalecollab` as the default org (set in `labspace/00-setup.md`). To use a different org, either:

- Click a different org name on the Setup page once the labspace UI is running, or
- Edit `labspace/00-setup.md` and change `default="whalecollab"` to your org

The Admin Console URL pattern is `https://app.docker.com/accounts/<org>` — the lab uses `$$org$$` substitution so you don't need to edit URLs.

## Reverting

`install-v5.sh` backs up any existing `labspace/` to `labspace.backup-<timestamp>/`. To roll back:

```bash
rm -rf labspace
mv labspace.backup-<timestamp> labspace
```
