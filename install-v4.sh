#!/usr/bin/env bash
# Cleanup + install script for labspace-ai-governance v4
#
# Run this from the root of your labspace-ai-governance repo.
# It will:
#   1. Back up the existing labspace/ directory
#   2. Remove the old content
#   3. Drop in the lean v4 structure
#
# Usage:
#   bash install-v4.sh

set -e

REPO_ROOT="$(pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="labspace.backup-${TIMESTAMP}"

if [ ! -d "labspace" ]; then
  echo "ERROR: no labspace/ directory found in $REPO_ROOT"
  echo "Run this script from the root of your labspace-ai-governance repo."
  exit 1
fi

echo "==> Backing up existing labspace/ to ${BACKUP_DIR}/"
mv labspace "${BACKUP_DIR}"

echo "==> Creating fresh labspace/ directory"
mkdir -p labspace

echo "==> Copying v4 content into labspace/"
# Assumes this script lives alongside the v4 labspace/ directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cp "${SCRIPT_DIR}/labspace/"*.md labspace/
cp "${SCRIPT_DIR}/labspace/labspace.yaml" labspace/

echo ""
echo "==> Done."
echo "    Old content backed up at: ${BACKUP_DIR}/"
echo "    New v4 content installed at: labspace/"
echo ""
echo "Next steps:"
echo "  1. Review the new files:    ls labspace/"
echo "  2. Test locally:            bash start-labspace.sh"
echo "  3. Commit:                  git add -A && git commit -m 'Lean v4 — validated enforcement demo'"
echo "  4. If anything's wrong:     rm -rf labspace && mv ${BACKUP_DIR} labspace"
