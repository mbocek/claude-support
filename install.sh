#!/usr/bin/env bash
set -euo pipefail

# Installs the generic agent/command set for a target assistant.
#
#   ./install.sh [claude|opencode|both]        (default: claude)
#   ./install.sh --target opencode
#   curl -fsSL https://raw.githubusercontent.com/mbocek/claude-support/main/install.sh | bash -s -- opencode
#
# The canonical source lives in src/ with a tool-neutral frontmatter and two
# tokens ({{GUIDE}}, {{CFG}}). This script renders that source into the layout
# the chosen assistant expects:
#
#   claude   -> .claude/{agents,commands,templates,agent-memory/_shared}   guide=CLAUDE.md
#   opencode -> .opencode/{agents,commands,templates,agent-memory/_shared} guide=AGENTS.md
#
# For opencode the agent/command frontmatter is rewritten (name/model/effort
# dropped, mode + permission derived from the neutral `tools`/`memory` fields).

REPO="mbocek/claude-support"
BRANCH="main"
TARBALL_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

# Distributed subtrees — replaced wholesale on install so upstream deletions
# propagate. User-owned per-agent memory dirs (agent-memory/<agent>/) are never
# touched.
SUBTREES=("agents" "commands" "templates" "agent-memory/_shared")

usage() {
  cat >&2 <<EOF
Usage: install.sh [claude|opencode|both]

  claude    render into ./.claude   (guide file: CLAUDE.md)   [default]
  opencode  render into ./.opencode (guide file: AGENTS.md)
  both      render both trees
EOF
}

# --- parse target -----------------------------------------------------------
TARGET="claude"
case "${1:-}" in
  "") ;;
  --target) TARGET="${2:-}"; shift ;;
  --target=*) TARGET="${1#--target=}" ;;
  -h|--help) usage; exit 0 ;;
  *) TARGET="$1" ;;
esac
case "$TARGET" in
  claude|opencode|both) ;;
  *) echo "Error: unknown target '$TARGET'." >&2; usage; exit 1 ;;
esac

for tool in awk sed; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Error: '$tool' is required but not installed." >&2; exit 1; }
done

# --- resolve the source root ------------------------------------------------
# Prefer a local checkout (src/ next to this script); otherwise download the
# tarball so `curl | bash` keeps working.
SRC_ROOT=""
_src="${BASH_SOURCE[0]:-}"
if [ -n "$_src" ] && [ -f "$_src" ]; then
  _dir="$(cd "$(dirname "$_src")" && pwd)"
  [ -d "$_dir/src/agents" ] && SRC_ROOT="$_dir/src"
fi

tmpdir=""
if [ -z "$SRC_ROOT" ]; then
  for tool in curl tar; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Error: '$tool' is required to download the source." >&2; exit 1; }
  done
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT
  echo "Downloading ${REPO}@${BRANCH}..."
  curl -fsSL "$TARBALL_URL" | tar -xz -C "$tmpdir"
  extracted=$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -1)
  if [ -z "$extracted" ] || [ ! -d "$extracted/src/agents" ]; then
    echo "Error: src/ not found in the downloaded archive." >&2
    exit 1
  fi
  SRC_ROOT="$extracted/src"
fi

# --- opencode frontmatter rewriter ------------------------------------------
# Reads a canonical agent/command markdown file and emits opencode frontmatter.
# The body is passed through untouched (token substitution happens afterwards).
read -r -d '' AWK_FM <<'AWK' || true
BEGIN { fm = 0; indesc = 0; ndesc = 0; hasmemory = 0 }

NR == 1 && $0 == "---" { fm = 1; print "---"; next }

fm == 1 {
  if ($0 == "---") {
    for (i = 0; i < ndesc; i++) print desc[i]
    if (kind == "agent") {
      print "mode: subagent"
      if (color != "") print "color: " color
      has_edit = (tools ~ /Write/ || tools ~ /Edit/ || hasmemory)
      has_bash = (tools ~ /Bash/)
      has_web  = (tools ~ /WebFetch/)
      if (!has_edit || !has_bash || !has_web) {
        print "permission:"
        if (!has_edit) print "  edit: deny"
        if (!has_bash) print "  bash: deny"
        if (!has_web)  print "  webfetch: deny"
      }
    } else if (kind == "command") {
      print "agent: build"
    }
    print "---"
    fm = 2
    next
  }
  if ($0 ~ /^[A-Za-z][A-Za-z0-9_-]*:/) {
    indesc = 0
    key = $0; sub(/:.*/, "", key)
    val = $0; sub(/^[^:]*:[ \t]*/, "", val)
    if (key == "description") { indesc = 1; desc[ndesc++] = $0 }
    else if (key == "tools")  { tools = val }
    else if (key == "color")  { color = val }
    else if (key == "memory") { hasmemory = 1 }
    # name, model, effort, allowed-tools, argument-hint -> dropped
    next
  }
  if (indesc == 1) { desc[ndesc++] = $0 }
  next
}

fm == 2 { print }
AWK

# render_file <src> <agent|command|passthrough> <guide> <cfg>
render_file() {
  local src="$1" kind="$2" guide="$3" cfg="$4"
  if [ "$kind" = "opencode-agent" ]; then
    awk -v kind="agent" "$AWK_FM" "$src" | sed -e "s#{{GUIDE}}#${guide}#g" -e "s#{{CFG}}#${cfg}#g"
  elif [ "$kind" = "opencode-command" ]; then
    awk -v kind="command" "$AWK_FM" "$src" | sed -e "s#{{GUIDE}}#${guide}#g" -e "s#{{CFG}}#${cfg}#g"
  else
    # passthrough: canonical frontmatter is already the claude format
    sed -e "s#{{GUIDE}}#${guide}#g" -e "s#{{CFG}}#${cfg}#g" "$src"
  fi
}

render_target() {
  local target="$1"
  local base guide cfg
  case "$target" in
    claude)   base=".claude";   guide="CLAUDE.md"; cfg=".claude" ;;
    opencode) base=".opencode"; guide="AGENTS.md"; cfg=".opencode" ;;
  esac

  for sub in "${SUBTREES[@]}"; do
    rm -rf "${base:?}/$sub"
    mkdir -p "$base/$sub"
  done

  local agent_kind cmd_kind
  if [ "$target" = "opencode" ]; then
    agent_kind="opencode-agent"; cmd_kind="opencode-command"
  else
    agent_kind="passthrough"; cmd_kind="passthrough"
  fi

  for f in "$SRC_ROOT"/agents/*.md; do
    render_file "$f" "$agent_kind" "$guide" "$cfg" > "$base/agents/$(basename "$f")"
  done
  for f in "$SRC_ROOT"/commands/*.md; do
    render_file "$f" "$cmd_kind" "$guide" "$cfg" > "$base/commands/$(basename "$f")"
  done
  for f in "$SRC_ROOT"/templates/*.md; do
    render_file "$f" "passthrough" "$guide" "$cfg" > "$base/templates/$(basename "$f")"
  done
  render_file "$SRC_ROOT/memory/protocol.md" "passthrough" "$guide" "$cfg" \
    > "$base/agent-memory/_shared/protocol.md"

  echo "Rendered '$target' into $(pwd)/$base"
}

if [ "$TARGET" = "both" ]; then
  render_target claude
  render_target opencode
else
  render_target "$TARGET"
fi

echo "Done."
