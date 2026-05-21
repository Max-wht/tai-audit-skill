# Repo-Local Artifacts

Tai-audit keeps raw per-run evidence in `/tmp/tai-audit-*` and persists only reusable context plus human-readable reports in the audited repository.

## Directories

- `tai/artifacts/` — common artifacts reused across business flows.
- `tai/artifacts/flows/{business_slug}/` — flow-local audit scope and annotation cache.
- `tai/business/` — final reports grouped by business flow.

Do not copy flattened source files into `tai/artifacts/` by default.

## Common Artifacts

`tai/artifacts/` should contain:

- `README.md`
- `run-metadata.md`
- `all-solidity.txt`
- `x-ray.md`
- `entry-points.md`
- `flow-scope.md`
- `tier-0.txt`
- `tier-1.txt`
- `tier-2.txt`
- `context-only.txt`
- `source-map.tsv`
- `x-ray-brief.md`
- `entry-points-brief.md`
- `attack-vectors-brief.md`
- `defi-core-pack.md`

Common cache is reusable only when required files exist, the current raw Solidity inventory matches `tai/artifacts/all-solidity.txt`, and the installed skill's `defi-core-pack.md` matches `tai/artifacts/defi-core-pack.md`.

When reusing common cache, copy files back into the raw bundle as:

- `all-solidity.txt`, `flow-scope.md`, `tier-0.txt`, `tier-1.txt`, `tier-2.txt`, `context-only.txt`, `source-map.tsv` -> `{bundle_dir}/scope/`
- `x-ray.md`, `entry-points.md`, `x-ray-brief.md`, `entry-points-brief.md`, `attack-vectors-brief.md`, `defi-core-pack.md` -> `{bundle_dir}/references/`

The common cache intentionally does not store a final `audit-scope.txt`. Each run must materialize `audit-scope.txt` only after the user-selected business flow(s) are known. If a full Tier 0-2 candidate list is needed, rebuild it from `tier-0.txt`, `tier-1.txt`, and `tier-2.txt` or use the fresh-run `candidate-scope.txt`.

## Flow Artifacts

`tai/artifacts/flows/{business_slug}/` should contain:

- `audit-scope.txt`
- `source-map.tsv`
- `annotations/README.txt`
- `annotations/auth.txt`
- `annotations/validate.txt`
- `annotations/flow.txt`
- `annotations/state.txt`
- `annotations/value.txt`
- `annotations/env.txt`
- `annotations/platform.txt`

Flow annotation cache is reusable only when the current `audit-scope.txt` matches the cached `audit-scope.txt` and every annotation file exists.

## Report Artifacts

`tai/business/` should contain:

- `README.md`
- `{business_slug}-report.md`

For multi-flow runs, join slugs with `--`, for example `investment-buy-shares--redemption-redeem-shares-report.md`.

Never write or overwrite a root-level report copy.

## Metadata Expectations

`tai/artifacts/run-metadata.md` should record:

- Timestamp
- Working directory
- Git commit, or `unknown` if not in a git repo
- Solidity file count
- Scope hash from `all-solidity.txt`
- Cache mode: `fresh`, `reused`, or `regenerated-stale`

`tai/artifacts/README.md` should summarize:

- Common cache status
- Scope counts for Tier 0, Tier 1, Tier 2, and Context Only
- Available business flows
- Cached flow annotation directories

`tai/business/README.md` should summarize:

- Business flow
- Report path
- Run timestamp
- Audited file count
- Counts for Confirmed Vulnerability, Security Risk, Hardening / QA, Research Lead, and False Positive
