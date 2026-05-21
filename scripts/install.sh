#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [--target claude|codex|all] [--with-xray]

Options:
  --target      Install target. Default: claude.
  --with-xray   Install or update upstream pashov/skills x-ray.
  -h, --help    Show this help.

By default this installs only tai-audit and does not modify an existing x-ray.

Environment:
  CLAUDE_SKILLS_DIR   Default: $HOME/.claude/skills
  CODEX_SKILLS_DIR    Default: $HOME/.codex/skills
  X_RAY_REF           Upstream branch, tag, or commit. Default: main
EOF
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="claude"
with_xray=0
xray_ref="${X_RAY_REF:-main}"
xray_repo="https://github.com/pashov/skills.git"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      [[ $# -ge 2 ]] || { echo "--target requires a value" >&2; exit 2; }
      target="$2"
      shift 2
      ;;
    --target=*)
      target="${1#--target=}"
      shift
      ;;
    --with-xray)
      with_xray=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$target" in
  claude|codex|all) ;;
  *)
    echo "Invalid --target: $target" >&2
    usage >&2
    exit 2
    ;;
esac

sync_dir() {
  local source_dir="$1"
  local target_dir="$2"
  local label="$3"

  [[ -f "$source_dir/SKILL.md" ]] || {
    echo "Missing SKILL.md in $source_dir" >&2
    exit 1
  }

  mkdir -p "$target_dir"
  rsync -a --delete --exclude '.DS_Store' "$source_dir/" "$target_dir/"
  diff -qr "$source_dir" "$target_dir"
  echo "Updated $label -> $target_dir"
}

clone_xray() {
  local tmp_dir="$1"

  if git clone --depth 1 --branch "$xray_ref" "$xray_repo" "$tmp_dir" >/dev/null 2>&1; then
    return 0
  fi

  git clone --filter=blob:none --no-checkout "$xray_repo" "$tmp_dir" >/dev/null
  (
    cd "$tmp_dir"
    git fetch --depth 1 origin "$xray_ref" >/dev/null
    git checkout --detach FETCH_HEAD >/dev/null
  )
}

install_xray() {
  local skills_dir="$1"
  local platform="$2"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  clone_xray "$tmp_dir"

  [[ -f "$tmp_dir/x-ray/SKILL.md" ]] || {
    echo "Upstream x-ray skill not found in pashov/skills@$xray_ref" >&2
    rm -rf "$tmp_dir"
    exit 1
  }

  mkdir -p "$skills_dir/x-ray"
  rsync -a --delete --exclude '.DS_Store' "$tmp_dir/x-ray/" "$skills_dir/x-ray/"
  {
    echo "# Upstream x-ray installation"
    echo
    echo "Source: https://github.com/pashov/skills/tree/$xray_ref/x-ray"
    echo "Requested ref: $xray_ref"
    echo "Installed commit: $(cd "$tmp_dir" && git rev-parse HEAD)"
    echo "Installed at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    if [[ -f "$skills_dir/x-ray"/VERSION ]]; then
      echo "Upstream VERSION: $(tr -d '\n' < "$skills_dir/x-ray"/VERSION)"
    fi
  } > "$skills_dir/x-ray/UPSTREAM.md"

  rm -rf "$tmp_dir"
  echo "Updated upstream x-ray for $platform -> $skills_dir/x-ray"
}

report_xray_status() {
  local skills_dir="$1"
  local platform="$2"

  if [[ "$with_xray" -eq 1 ]]; then
    return 0
  fi

  if [[ -f "$skills_dir/x-ray/SKILL.md" ]]; then
    echo "Existing x-ray detected for $platform; not modified. Use --with-xray to update it."
  else
    echo "No x-ray skill detected for $platform. Tai can use existing project x-ray outputs or fallback context; use --with-xray to install upstream x-ray."
  fi
}

install_for() {
  local platform="$1"
  local skills_dir

  case "$platform" in
    claude)
      skills_dir="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
      ;;
    codex)
      skills_dir="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
      ;;
    *)
      echo "Unsupported platform: $platform" >&2
      exit 2
      ;;
  esac

  mkdir -p "$skills_dir"
  sync_dir "$repo_root/skills/tai-audit" "$skills_dir/tai-audit" "$platform tai-audit"

  if [[ "$with_xray" -eq 1 ]]; then
    install_xray "$skills_dir" "$platform"
  fi

  report_xray_status "$skills_dir" "$platform"
}

if [[ "$target" == "all" ]]; then
  install_for claude
  install_for codex
else
  install_for "$target"
fi

echo "Install complete."
