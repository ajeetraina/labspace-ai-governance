#!/bin/bash
# start-labspace.sh - Launch the sbx Labspace locally (content-dev mode)
#
# The IDE terminal is served by the Labspace Compose provider
# (workspace.provider.type: labspace in compose.override.yaml), which starts
# a host-side ttyd on :8085 automatically. This script no longer starts ttyd
# by hand — it only checks prerequisites and brings up the compose stack.
#
# To launch the *published* labspace instead, use:
#   docker labspace launch ajeetraina777/labspace-ai-governance
#
# Prerequisites (automatically checked on startup):
#
#   macOS:
#     brew install ttyd
#     brew install docker/tap/sbx
#
#   Linux:
#     sudo apt install ttyd
#     curl -fsSL https://get.docker.com | sudo REPO_ONLY=1 sh
#     sudo apt-get install docker-sbx
#     sudo usermod -aG kvm $USER && newgrp kvm
#
#   If any prerequisite is missing, this script will tell you
#   exactly what to install and exit cleanly.

set -e

COMPOSE_FILE="compose.override.yaml"

# ── Color helpers ──────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}WARN:${NC} $*"; }
error() { echo -e "${RED}ERROR:${NC} $*"; exit 1; }

# ── 1. Check ttyd (the labspace provider runs host ttyd on :8085) ──
if ! command -v ttyd &>/dev/null; then
  echo ""
  echo -e "${RED}ERROR: ttyd not found.${NC}"
  echo ""
  echo "  The labspace provider serves the IDE terminal with host ttyd."
  echo "  Install it with:"
  echo "    brew install ttyd          # macOS"
  echo "    sudo apt install ttyd      # Ubuntu/Debian"
  echo ""
  echo "  Then re-run: bash start-labspace.sh"
  exit 1
fi

# ── 2. Check sbx ───────────────────────────────────────────────
if ! command -v sbx &>/dev/null; then
  echo ""
  echo -e "${RED}ERROR: sbx not found.${NC}"
  echo ""
  echo "  Install it with:"
  echo "    brew install docker/tap/sbx          # macOS"
  echo "    sudo apt install docker-sandbox       # Ubuntu (if available)"
  echo ""
  echo "  Or check: https://docs.docker.com/go/sbx/"
  echo ""
  echo "  Then re-run: bash start-labspace.sh"
  exit 1
fi

# ── 3. Ensure sbx is responsive ────────────────────────────────
if ! sbx ls &>/dev/null; then
  error "sbx is installed but not responding. Make sure Docker is running, then try 'sbx ls'."
fi
info "sbx ready: $(sbx version 2>/dev/null)"

# ── 4. Set CONTENT_PATH (fixes 'empty section between colons') ──
export CONTENT_PATH="${CONTENT_PATH:-$(pwd)}"
info "CONTENT_PATH set to: $CONTENT_PATH"

# ── 5. Validate compose.override.yaml exists ───────────────────
if [ ! -f "$COMPOSE_FILE" ]; then
  error "$COMPOSE_FILE not found. Are you running from the repo root?"
fi

# ── 6. Start Labspace (use local base compose if present, ───────
#       otherwise fall back to the OCI reference). The workspace
#       provider starts host ttyd on :8085 for the IDE tab. ──────
if [ -f "docker-compose.yml" ]; then
  BASE_COMPOSE="docker-compose.yml"
elif [ -f "compose.yaml" ]; then
  BASE_COMPOSE="compose.yaml"
elif [ -f "compose.yml" ]; then
  BASE_COMPOSE="compose.yml"
else
  BASE_COMPOSE=""
fi

if [ -n "$BASE_COMPOSE" ]; then
  info "Starting Labspace (local compose: $BASE_COMPOSE)..."
  docker compose -f "$BASE_COMPOSE" up --watch &
else
  info "Starting Labspace (OCI reference)..."
  docker compose -f oci://dockersamples/labspace -f "$COMPOSE_FILE" up --watch &
fi
COMPOSE_PID=$!

echo ""
echo "==========================================="
echo "  Labspace ready at http://localhost:3030"
echo "  Observability dashboard: http://localhost:8090"
echo "    (also the 'Observability' tab + Section 08)"
echo "  IDE terminal (provider):  http://localhost:8085"
echo "  Run: sbx ls, sbx version, sbx run ..."
echo "==========================================="
echo ""
echo "Press Ctrl+C to stop"

# ── 7. Cleanup on exit ─────────────────────────────────────────
cleanup() {
  echo ""
  info "Stopping..."
  if [ -n "$BASE_COMPOSE" ]; then
    docker compose -f "$BASE_COMPOSE" down 2>/dev/null || true
  else
    docker compose -f oci://dockersamples/labspace -f "$COMPOSE_FILE" down 2>/dev/null || true
  fi
}
trap cleanup EXIT
wait $COMPOSE_PID
