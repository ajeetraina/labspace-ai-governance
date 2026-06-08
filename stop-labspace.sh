#!/usr/bin/env bash
# stop-labspace.sh - Shut down the labspace stack started by start-labspace.sh
#
# Idempotent: safe to run when nothing is up.
#
# Usage:
#   bash stop-labspace.sh              # stop containers + kill ttyd
#   bash stop-labspace.sh --volumes    # also remove named volumes
#   bash stop-labspace.sh --images     # also remove the locally-built
#                                      # labspace-observability:latest image
#   bash stop-labspace.sh --all        # volumes + images
#   bash stop-labspace.sh -h / --help

set -e

TTYD_PORT=8085
COMPOSE_FILE="compose.override.yaml"

# ── Color helpers ──────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}WARN:${NC} $*"; }
error() { echo -e "${RED}ERROR:${NC} $*"; exit 1; }

# ── Flag parsing ───────────────────────────────────────────────
REMOVE_VOLUMES=0
REMOVE_IMAGES=0
for arg in "$@"; do
  case "$arg" in
    --volumes|-v) REMOVE_VOLUMES=1 ;;
    --images|-i)  REMOVE_IMAGES=1 ;;
    --all|-a)     REMOVE_VOLUMES=1; REMOVE_IMAGES=1 ;;
    -h|--help)
      sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) warn "Unknown flag: $arg (use -h for help)" ;;
  esac
done

# ── 1. Locate the compose base file (same logic as start-labspace.sh) ──
if [ -f "docker-compose.yml" ]; then
  BASE_COMPOSE="docker-compose.yml"
elif [ -f "compose.yaml" ]; then
  BASE_COMPOSE="compose.yaml"
elif [ -f "compose.yml" ]; then
  BASE_COMPOSE="compose.yml"
else
  BASE_COMPOSE=""
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  warn "$COMPOSE_FILE not found. Skipping docker compose down."
  COMPOSE_AVAILABLE=0
else
  COMPOSE_AVAILABLE=1
fi

# ── 2. Bring down the compose stack ────────────────────────────
if [ "$COMPOSE_AVAILABLE" = "1" ]; then
  DOWN_FLAGS=""
  [ "$REMOVE_VOLUMES" = "1" ] && DOWN_FLAGS="--volumes"
  [ "$REMOVE_IMAGES" = "1" ]  && DOWN_FLAGS="$DOWN_FLAGS --rmi local"

  # CONTENT_PATH only matters for `up`, but compose warns if unset on `down`
  # too. Default it to PWD so the warning doesn't clutter output.
  export CONTENT_PATH="${CONTENT_PATH:-$(pwd)}"

  if [ -n "$BASE_COMPOSE" ]; then
    info "Stopping labspace stack (local compose: $BASE_COMPOSE)..."
    docker compose -f "$BASE_COMPOSE" -f "$COMPOSE_FILE" down $DOWN_FLAGS 2>&1 \
      | grep -v "level=warning" || true
  else
    info "Stopping labspace stack (OCI reference)..."
    docker compose -f oci://dockersamples/labspace -f "$COMPOSE_FILE" down $DOWN_FLAGS 2>&1 \
      | grep -v "level=warning" || true
  fi
fi

# ── 3. Kill ttyd on its port ───────────────────────────────────
if lsof -ti tcp:$TTYD_PORT &>/dev/null; then
  info "Killing ttyd on port $TTYD_PORT..."
  lsof -ti tcp:$TTYD_PORT | xargs kill -9 2>/dev/null || true
else
  info "No ttyd running on port $TTYD_PORT."
fi

# ── 4. Optional: clean the observability image even if compose missed it ──
if [ "$REMOVE_IMAGES" = "1" ]; then
  if docker image inspect labspace-observability:latest &>/dev/null; then
    info "Removing image labspace-observability:latest..."
    docker rmi -f labspace-observability:latest >/dev/null 2>&1 || true
  fi
fi

# ── 5. Summary ─────────────────────────────────────────────────
echo ""
echo "==========================================="
echo "  Labspace stopped."
[ "$REMOVE_VOLUMES" = "1" ] && echo "  Volumes removed."
[ "$REMOVE_IMAGES" = "1" ]  && echo "  Local observability image removed."
echo ""
echo "  To start again:  bash start-labspace.sh"
echo "==========================================="
