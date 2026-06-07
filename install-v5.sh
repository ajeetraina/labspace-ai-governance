#!/usr/bin/env bash
# Install script for labspace-ai-governance v5
#
# Drops in the v5 labspace structure: sections 00-08, the MCP hands-on
# content, the observability kit (live dashboard for sbx + MCP events),
# and the supporting assets.
#
# Run this from the root of a labspace-ai-governance clone, or from inside
# the extracted tarball. It will:
#   1. Back up any existing labspace/ directory
#   2. Drop in the v5 content from this bundle
#   3. Optionally refresh root-level compose files
#
# Usage:
#   bash install-v5.sh           # interactive
#   bash install-v5.sh --force   # skip prompts, overwrite root files

set -e

REPO_ROOT="$(pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="labspace.backup-${TIMESTAMP}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE=1 ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
  esac
done

if [ ! -f "${SCRIPT_DIR}/labspace/labspace.yaml" ]; then
  echo "ERROR: ${SCRIPT_DIR}/labspace/labspace.yaml not found."
  echo "Run this script from the directory where you extracted the v5 tarball."
  exit 1
fi

# If the script lives in the same directory as the target, the v5 content
# is already in place — nothing to copy. Bail out cleanly so users running
# this in a dev clone don't see a confusing cp error.
if [ "${SCRIPT_DIR}" = "${REPO_ROOT}" ]; then
  echo "==> labspace-ai-governance v5"
  echo "    The script is running from the same directory as your repo,"
  echo "    which means the v5 content is already in place. Nothing to install."
  echo
  echo "    To install v5 into a different directory, run:"
  echo "      cd /path/to/target && bash ${SCRIPT_DIR}/install-v5.sh"
  echo
  echo "    To rebuild the labspace stack:"
  echo "      bash start-labspace.sh"
  echo
  echo "    To try the observability dashboard:"
  echo "      cd labspace/kits/observability && docker compose up -d --build"
  exit 0
fi

confirm() {
  local prompt="$1"
  if [ "$FORCE" = "1" ]; then return 0; fi
  read -r -p "$prompt [y/N] " ans
  case "$ans" in y|Y|yes|Yes) return 0 ;; *) return 1 ;; esac
}

echo "==> labspace-ai-governance v5 installer"
echo "    Target: ${REPO_ROOT}"
echo

# 1. Back up existing labspace/ if present
if [ -d "${REPO_ROOT}/labspace" ] && [ "${REPO_ROOT}" != "${SCRIPT_DIR}" ]; then
  echo "==> Backing up existing labspace/ to ${BACKUP_DIR}/"
  mv "${REPO_ROOT}/labspace" "${REPO_ROOT}/${BACKUP_DIR}"
fi

# 2. Copy v5 labspace/ in
echo "==> Installing labspace/ content"
mkdir -p "${REPO_ROOT}/labspace"
# Use cp -R so kits/ and assets/ come along with the markdown files
cp -R "${SCRIPT_DIR}/labspace/." "${REPO_ROOT}/labspace/"

# 3. Root-level files: compose stack + start script
ROOT_FILES=(compose.yaml compose.override.yaml start-labspace.sh)
NEEDS_ROOT_INSTALL=0
for f in "${ROOT_FILES[@]}"; do
  if [ ! -f "${REPO_ROOT}/${f}" ] && [ -f "${SCRIPT_DIR}/${f}" ]; then
    NEEDS_ROOT_INSTALL=1
    break
  fi
done

if [ "$NEEDS_ROOT_INSTALL" = "1" ]; then
  if confirm "==> Install missing root files (compose.yaml, start-labspace.sh, etc.)?"; then
    for f in "${ROOT_FILES[@]}"; do
      if [ -f "${SCRIPT_DIR}/${f}" ] && [ ! -f "${REPO_ROOT}/${f}" ]; then
        cp "${SCRIPT_DIR}/${f}" "${REPO_ROOT}/${f}"
        echo "    Installed ${f}"
      fi
    done
    [ -f "${REPO_ROOT}/start-labspace.sh" ] && chmod +x "${REPO_ROOT}/start-labspace.sh"
  fi
fi

# 4. Make kit scripts executable
find "${REPO_ROOT}/labspace/kits" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo
echo "==> Done."
[ -d "${REPO_ROOT}/${BACKUP_DIR}" ] && echo "    Old labspace backed up at: ${BACKUP_DIR}/"
echo "    v5 installed at: labspace/"
echo
echo "What's new in v5:"
echo "  - Section 06: MCP Hands-On (sbx mcp registration, 4 modes, local gateway variant)"
echo "  - Section 08: Observability (jq one-liners + live dashboard kit)"
echo "  - labspace/kits/observability/: Go backend + HTML UI for live sbx + MCP events"
echo "  - labspace/assets/mcp-gateway-compose.yaml: reusable local gateway recipe"
echo "  - whalecollab as default org (replaces customer name presets)"
echo "  - Admin URL pattern corrected to app.docker.com/accounts/<org>"
echo
echo "Next steps:"
echo "  1. Review:                ls labspace/"
echo "  2. Test the labspace UI:  bash start-labspace.sh   # then visit http://localhost:3030"
echo "  3. Try the dashboard:     cd labspace/kits/observability && docker compose up -d --build"
echo "  4. Commit:                git add -A && git commit -m 'Install labspace v5'"
echo
[ -d "${REPO_ROOT}/${BACKUP_DIR}" ] && \
  echo "To revert:   rm -rf labspace && mv ${BACKUP_DIR} labspace"
