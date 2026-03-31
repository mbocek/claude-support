#!/usr/bin/env bash
set -euo pipefail

REPO="mbocek/claude-support"
BRANCH="main"
API_URL="https://api.github.com/repos/${REPO}/contents/.claude?ref=${BRANCH}"

download_dir() {
  local api_url="$1"
  local base_dir="$2"

  local response
  response=$(curl -fsSL "$api_url")

  echo "$response" | jq -c '.[]' | while read -r item; do
    local type name path download_url
    type=$(echo "$item" | jq -r '.type')
    name=$(echo "$item" | jq -r '.name')
    path=$(echo "$item" | jq -r '.path')
    download_url=$(echo "$item" | jq -r '.download_url')

    local local_path="${base_dir}/${name}"

    if [ "$type" = "dir" ]; then
      mkdir -p "$local_path"
      download_dir "https://api.github.com/repos/${REPO}/contents/${path}?ref=${BRANCH}" "$local_path"
    else
      echo "Downloading ${path}"
      curl -fsSL "$download_url" -o "$local_path"
    fi
  done
}

mkdir -p .claude
download_dir "$API_URL" ".claude"

echo "Done. .claude directory installed into $(pwd)/.claude"
