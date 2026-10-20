#!/usr/bin/env bash
set -euo pipefail

# Installs the agent/command set into ./.claude of the current directory.
#
#   ./install.sh
#   curl -fsSL https://raw.githubusercontent.com/mbocek/claude-support/main/install.sh | bash

REPO="mbocek/claude-support"
BRANCH="main"
TARBALL_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"
TARGET_DIR=".claude"

# Replaced wholesale so upstream deletions propagate; agent-memory/ is user-owned and never touched.
SUBTREES=("agents" "commands" "templates")

# Prefer a local checkout next to this script; otherwise download the tarball so `curl | bash` works.
SRC_ROOT=""
_src="${BASH_SOURCE[0]:-}"
if [ -n "$_src" ] && [ -f "$_src" ]; then
  _dir="$(cd "$(dirname "$_src")" && pwd)"
  [ -d "$_dir/agents" ] && SRC_ROOT="$_dir"
fi

if [ -z "$SRC_ROOT" ]; then
  for tool in curl tar; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Error: '$tool' is required to download the source." >&2; exit 1; }
  done
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT
  echo "Downloading ${REPO}@${BRANCH}..."
  curl -fsSL "$TARBALL_URL" | tar -xz -C "$tmpdir"
  SRC_ROOT=$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -1)
  if [ -z "$SRC_ROOT" ] || [ ! -d "$SRC_ROOT/agents" ]; then
    echo "Error: agents/ not found in the downloaded archive." >&2
    exit 1
  fi
fi

for sub in "${SUBTREES[@]}"; do
  rm -rf "${TARGET_DIR:?}/$sub"
  mkdir -p "$TARGET_DIR/$sub"
  cp "$SRC_ROOT/$sub"/*.md "$TARGET_DIR/$sub/"
done

echo "Installed into $(pwd)/$TARGET_DIR"
