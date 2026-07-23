#!/usr/bin/env bash
set -euo pipefail

REPO="mbocek/claude-support"
BRANCH="main"
TARBALL_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

# Distributed subtrees — replaced wholesale on install so upstream deletions propagate
# to existing installs. User-owned paths (e.g. .claude/agent-memory/<agent>/) are never touched.
DISTRIBUTED=(
  ".claude/agents"
  ".claude/commands"
  ".claude/templates"
  ".claude/agent-memory/_shared"
)

for tool in curl tar; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Error: '$tool' is required but not installed." >&2; exit 1; }
done

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "Downloading ${REPO}@${BRANCH}..."
curl -fsSL "$TARBALL_URL" | tar -xz -C "$tmpdir"

# The tarball extracts to a single top-level directory (e.g. claude-support-main/).
src=$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -1)
if [ -z "$src" ] || [ ! -d "$src/.claude" ]; then
  echo "Error: .claude directory not found in the downloaded archive." >&2
  exit 1
fi

for path in "${DISTRIBUTED[@]}"; do
  rm -rf "$path"
  mkdir -p "$(dirname "$path")"
  if [ -d "$src/$path" ]; then
    cp -R "$src/$path" "$path"
    echo "Installed $path"
  fi
done

echo "Done. .claude directory installed into $(pwd)/.claude"
