# Setup

Welcome to the Docker AI Governance lab.

Before you start, set the **organization** you'll be using throughout. Most commands and links in later sections substitute `$$org$$` for whatever you set here.

::variableDefinition[org]{prompt="Which Docker Hub organization will you use?"}

If you're not sure, try one of these presets:

::variableSetButton[Docker DevRel]{variables="org=dockerdevrel"}
::variableSetButton[Bosch (demo)]{variables="org=bosch"}
::variableSetButton[Acme (sample)]{variables="org=acme"}

You can change this any time.

## What you need

- **Docker Desktop** with `sbx` (Docker Sandboxes) installed
- **Admin access** to a Docker Hub organization so you can configure AI governance policies
- **A terminal** in the right-hand panel — most commands are click-to-run

## Quick check

Verify sbx is installed:

```bash terminal-id=main
sbx version
```

Verify you're logged in to Docker:

```bash terminal-id=main
docker login
```

If you're a member of multiple organizations, make sure the org you set above (`$$org$$`) matches one where you have admin rights — otherwise you won't be able to set policies in Section 03.

When you're ready, move to Section 01.
