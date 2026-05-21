#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill_dir="$repo_root/skills/tai-audit"
failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "missing file: ${path#$repo_root/}"
}

require_file "$skill_dir/SKILL.md"
require_file "$skill_dir/VERSION"
require_file "$skill_dir/agents/openai.yaml"
require_file "$skill_dir/references/root.md"
require_file "$skill_dir/references/severity.md"
require_file "$skill_dir/references/tag-ontology.md"
require_file "$skill_dir/references/flow-scope-planner.md"
require_file "$skill_dir/references/repo-artifacts.md"
require_file "$skill_dir/references/agents/researcher.md"
require_file "$skill_dir/references/agents/questioner.md"
require_file "$skill_dir/references/agents/thinker.md"
require_file "$skill_dir/references/attack-vectors/attack-vectors.md"
require_file "$skill_dir/references/attack-vectors/defi-core-pack.md"
require_file "$repo_root/README.md"
require_file "$repo_root/LICENSE"
require_file "$repo_root/CONTRIBUTING.md"
require_file "$repo_root/SECURITY.md"

head -n 1 "$skill_dir/SKILL.md" | grep -qx -- '---' || fail "SKILL.md frontmatter must start with ---"
grep -q '^name: tai-audit$' "$skill_dir/SKILL.md" || fail "SKILL.md missing name: tai-audit"
grep -q '^description:' "$skill_dir/SKILL.md" || fail "SKILL.md missing description"

[[ ! -d "$repo_root/x-ray" ]] || fail "vendored x-ray/ directory must not exist"
if find "$repo_root" -maxdepth 1 -type f -print | awk -F/ '$NF == "Readme.md" { found=1 } END { exit found ? 0 : 1 }'; then
  fail "use README.md, not Readme.md"
fi

if find "$repo_root" -path "$repo_root/.git" -prune -o -type f -empty -print | grep -q .; then
  find "$repo_root" -path "$repo_root/.git" -prune -o -type f -empty -print >&2
  fail "empty files are not allowed"
fi

if rg -n 'x-ray/scripts|repo_root/x-ray|sync_skill .*x-ray|\.\./x-ray|x-ray/VERSION|x-ray/references' \
  "$repo_root/skills" "$repo_root/scripts" "$repo_root/docs" \
  --glob '!scripts/check.sh' >/tmp/tai-skill-local-xray-refs.txt; then
  cat /tmp/tai-skill-local-xray-refs.txt >&2
  fail "local vendored x-ray references remain"
fi
rm -f /tmp/tai-skill-local-xray-refs.txt

grep -q 'https://github.com/pashov/skills/tree/main/x-ray' "$repo_root/README.md" || fail "README must link upstream x-ray"
grep -q 'If you already have x-ray installed' "$repo_root/README.md" || fail "README must explain existing x-ray installs"
grep -q 'MIT License' "$repo_root/LICENSE" || fail "LICENSE must be MIT"
grep -q 'Zero-Amount Transfer Revert' "$skill_dir/references/attack-vectors/defi-core-pack.md" || fail "DeFi core pack missing zero-transfer pattern"
grep -q 'Permissionless Exit Slippage/Liveness Freeze' "$skill_dir/references/attack-vectors/defi-core-pack.md" || fail "DeFi core pack missing permissionless exit liveness pattern"
grep -q 'External Dynamic List Current-Risk Rule' "$skill_dir/references/attack-vectors/defi-core-pack.md" || fail "DeFi core pack missing external dynamic list rule"

bash -n "$repo_root/scripts/install.sh"
bash -n "$repo_root/scripts/update-claude.sh"
bash -n "$repo_root/scripts/check.sh"

if [[ "$failures" -ne 0 ]]; then
  echo "$failures check(s) failed." >&2
  exit 1
fi

echo "All checks passed."
