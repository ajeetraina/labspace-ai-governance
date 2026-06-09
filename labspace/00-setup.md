# Setup

Welcome to the Docker AI Governance lab.

Before you start, set the **organization** you'll be using throughout. Most commands and links in later sections substitute `$$org$$` for whatever you set here.

::variableDefinition[org]{prompt="Which Docker Hub organization will you use?" default="whalecollab"}

Click below to apply the default for this lab, or type your own org name into the field above.

::variableSetButton[Use whalecollab]{variables="org=whalecollab"}

You can change this any time.

## What you need

- **Docker Desktop** with `sbx` (Docker Sandboxes) installed
- **Admin access** to a Docker Hub organization so you can configure AI governance policies
- **A terminal** in the right-hand panel — most commands are click-to-run

## Quick check

Verify sbx is installed:

```bash no-run-button
sbx version
```

Verify you're logged in to Docker:

```bash no-run-button
docker login
```

If you're a member of multiple organizations, make sure the org you set above (`$$org$$`) matches one where you have admin rights — otherwise you won't be able to set policies in Section 03.

When you're ready, move to Section 01.
