---
name: tai-audit
description: "Business-flow-first smart contract security audit using x-ray entry points, 7 root cause analysis, multi-agent validation, and classified reporting. Triggers on 'tai audit', 'deep audit', 'security review'."
---

# Smart Contract Security Audit

You are a senior solidity researcher. There will be many agents working for you here. Your job is to coordinate the sub-agents to complete their respective tasks and verify the validity of the reports they submit.

## Classification Policy

The audit must separate vulnerabilities from code facts and trust-model notes.

| Class | Meaning |
|---|---|
| **Confirmed Vulnerability** | A non-trusted attacker can reach the path, pass or bypass permission gates, and cause concrete loss, corruption, or liveness impact. |
| **Security Risk** | Trusted-role, governance, configuration, external-protocol, or project-admin compromise risk. |
| **Hardening / QA** | Best-practice, deployment footgun, robustness, dust/rounding, or code-quality issue without a proven exploit path. |
| **Research Lead** | Interesting attack surface where exploitability, live configuration, permissions, or net impact is not proven. |
| **False Positive** | Code fact is wrong, path is unreachable, permissions/design block it, or impact does not follow. |

**Auth downgrade rule:** In bug bounty contexts, project-controlled admin/governance/owner/council roles are trusted unless the bounty explicitly says otherwise. If a path depends on `onlyOwner`, `onlyRole`, `onlyAdmin`, `onlyDispatcherOwner`, `onlyFundDeployerOwner`, council, multisig, governance, deployer, or another trusted operator role, it must be classified as `Security Risk` or lower unless the evidence proves role bypass, role forgery, replay, unauthorized role acquisition, or that the role is not trusted by the bounty threat model.

## DeFi Mandatory Lenses

For DeFi, lending, vault, staking, AMM, collateral, and yield protocols, every selected business flow must be checked against the DeFi core pack. These lenses are not optional grep hints; they are coverage obligations that must be reflected in the final Coverage / Omission Review:

- Native `msg.value` consistency across native and ERC20 branches.
- Native coin sentinel consistency (`address(0)` / pseudo-ETH) and ERC20 metadata usage.
- Swap route, fee tier, slippage, `amountOutMin`, and deadline controls.
- Reward/yield entitlement timing, instant snapshots, JIT deposits, and MEV ordering.
- External reward/token/asset list liveness, pagination, dust, and removal paths.
- Weird ERC20 behavior: zero-value transfer reverts, raw `approve`, optional metadata, blacklist/pausable, fee-on-transfer, rebasing, and hooks.
- Registry lifecycle: add, update, remove/deactivate, validation, events, and recovery.

Coverage status values are: `covered`, `partial`, `no issue`, and `unresolved`. A lens with relevant code but incomplete exploitability proof should usually produce a `Research Lead`, not a silent omission.

## Mode Selection

Tai-audit is flow-first, not file-first. The default audit scope is derived from business flows in `x-ray.md` and `x-ray/entry-points.md`, then narrowed to Solidity files that are reachable from those entry points.

## External x-ray Dependency

This repository does **not** bundle x-ray. Treat x-ray as an external companion skill from `https://github.com/pashov/skills/tree/main/x-ray`.

When x-ray context is needed:
- Prefer existing audited-project outputs at `x-ray/x-ray.md`, `x-ray/entry-points.md`, and `x-ray/invariants.md`.
- If those outputs are missing, invoke the installed external `x-ray` skill if available.
- If external x-ray is not installed or cannot run, create low-confidence fallback `x-ray.md` and `entry-points.md` from raw Solidity `public` / `external` function discovery, mark both files with a clear fallback warning, and carry that warning into `x-ray-brief.md`, `entry-points-brief.md`, and the final report.

Do not reference local bundled x-ray source paths; they are intentionally not part of Tai.

**Raw discovery exclusions:** Use `find` to enumerate candidate `.sol` files, excluding vendored/test/build directories:

- **Directory blacklist**: `lib/`, `mocks/`, `mock/`, `test/`, `tests/`, `artifacts/`, `tai/`, `@openzeppelin/`, `node_modules/`, `forge-std/`
- **File name blacklist**: `*.t.sol`, `*Test*.sol`, `*Mock*.sol`

**Context-only exclusions:** The Flow Scope Planner must classify these as Context Only by default, not primary audit sources: `interfaces/`, `external-interfaces/`, `utils/`, `templates/`, `deprecated/`, `off-chain/`, `test/`, `tests/`, `mocks/`, `mock/`, and interface-shaped files such as `I*.sol`. Path name alone is not absolute: if an otherwise context-only file is directly reached from a selected entry-point chain and carries value movement, state mutation, accounting, custody, policy, oracle, upgrade, or validation logic, the planner may promote it to Tier 1 or Tier 2 and must explain why in `flow-scope.md`.

**Scope modes:**
- **Default** (no arguments): build a flow-scoped audit from `x-ray.md` + `entry-points.md`, then scan Tier 0-2 files only.
- **`$filename ...`**: scan the specified file(s) only, but still map each candidate to the nearest x-ray business flow when possible.
- **`--full-repo`**: scan all raw candidate `.sol` files after discovery exclusions. Use only when the user explicitly requests broad coverage; keep final reporting flow-grouped and treat un-mapped code facts as `Research Lead` or lower.

**Flow scope safeguard:** After the Flow Scope Planner selects Tier 0-2 files, print the file count. If the count exceeds **30 files** and `--full-repo` was not requested, stop and ask the user to choose business flows/modules from `{bundle_dir}/scope/flow-scope.md` before launching Tagger. Do not silently audit a large repo-wide scope.

## Repo-Local Persistence

Tai-audit keeps the complete raw run in `/tmp/tai-audit-*`, but persists reusable human-readable artifacts inside the audited repo:

- `tai/artifacts/` — common cross-flow context and summaries.
- `tai/artifacts/flows/{business_slug}/` — flow-local audit scope and annotation cache.
- `tai/business/` — final business-flow reports.

Do not write a report copy to the repository root. The official long-lived report location is `tai/business/{business_slug}-report.md`.

## Workflow

**Round 1 — Overview, Flow Scope & Pre-processing**

a. Glob for `**/references/attack-vectors/attack-vectors.md` — extract the `references/` directory (two levels up) as `{resolved_path}`
b. ToolSearch `select:Agent`
c. Bash `mkdir -p /tmp/tai-audit-$(date +%Y%m%d-%H%M%S)` and store the path as `{bundle_dir}`. **Do NOT delete this directory after the audit.** All artifacts must be preserved for post-audit inspection.
d. Bash `mkdir -p {bundle_dir}/sources {bundle_dir}/references {bundle_dir}/scope {bundle_dir}/annotations/by-root-cause tai/artifacts/flows tai/business`
e. Bash `find` for raw candidate `.sol` files per mode selection → write `{bundle_dir}/scope/all-solidity.txt`. This is a discovery inventory, not the final audit scope.
f. Bash `cp {resolved_path}/attack-vectors/attack-vectors.md {bundle_dir}/references/attack-vectors.md` and `cp {resolved_path}/attack-vectors/defi-core-pack.md {bundle_dir}/references/defi-core-pack.md`
g. **Repo-local common artifact cache check**:
   - Read `{resolved_path}/repo-artifacts.md` for the exact file mapping and README/metadata expectations.
   - Required common cache files under `tai/artifacts/`: `all-solidity.txt`, `x-ray.md`, `entry-points.md`, `flow-scope.md`, `tier-0.txt`, `tier-1.txt`, `tier-2.txt`, `context-only.txt`, `source-map.tsv`, `x-ray-brief.md`, `entry-points-brief.md`, `attack-vectors-brief.md`, `defi-core-pack.md`.
   - Cache is reusable only if all required files exist, `cmp -s {bundle_dir}/scope/all-solidity.txt tai/artifacts/all-solidity.txt` succeeds, and `cmp -s {resolved_path}/attack-vectors/defi-core-pack.md tai/artifacts/defi-core-pack.md` succeeds.
   - **Reusable cache** → copy common files from `tai/artifacts/` into `{bundle_dir}/scope/` and `{bundle_dir}/references/`, update `tai/artifacts/run-metadata.md` with cache mode `reused`, then skip x-ray resolution, Flow Scope Planner, and brief generation.
   - **Missing or stale cache** → continue with steps h-k, then sync the regenerated common artifacts back to `tai/artifacts/`.
h. If common cache is missing or stale, **resolve external x-ray artifacts**:
   - Prefer `x-ray/x-ray.md` in the audited project root. If present, copy it to `{bundle_dir}/references/x-ray.md` and copy sibling `x-ray/entry-points.md` if present.
   - If no project-root x-ray output exists, Glob for `**/x-ray/x-ray.md` and then `**/x-ray.md`, excluding `tai/`, `/tmp/tai-audit-*`, `node_modules/`, `lib/`, `test/`, and `tests/`. Copy the best match and its sibling `entry-points.md` if present.
   - If no x-ray output exists, invoke the installed external Skill `x-ray` from `pashov/skills`. After it completes, copy `x-ray/x-ray.md` and `x-ray/entry-points.md` from the audited project into `{bundle_dir}/references/`.
   - If external x-ray is unavailable or fails, create `{bundle_dir}/references/x-ray.md` with a header `LOW-CONFIDENCE FALLBACK: upstream x-ray was unavailable`, then summarize raw repository shape and any discovered Solidity entry points. This fallback must be treated as incomplete audit context.
i. If common cache is missing or stale, resolve `entry-points.md`:
   - If a copied or generated x-ray output has sibling `entry-points.md`, copy it to `{bundle_dir}/references/entry-points.md`.
   - If no `entry-points.md` exists, create a minimal map from `x-ray.md` core flows plus a grep of external/public Solidity functions, and mark it with `LOW-CONFIDENCE FALLBACK: generated without upstream x-ray entry-point analysis`.
   - If either x-ray or entry-point context is fallback-generated, record `x-ray_source=fallback` in `tai/artifacts/run-metadata.md`; otherwise record `x-ray_source=existing` or `x-ray_source=external-skill`.
j. If common cache is missing or stale, **Run Flow Scope Planner**:
   - Read `{resolved_path}/flow-scope-planner.md`.
   - Inputs: `{bundle_dir}/scope/all-solidity.txt`, `{bundle_dir}/references/x-ray.md`, `{bundle_dir}/references/entry-points.md`.
   - Output:
     - `{bundle_dir}/scope/flow-scope.md`
     - `{bundle_dir}/scope/tier-0.txt`
     - `{bundle_dir}/scope/tier-1.txt`
     - `{bundle_dir}/scope/tier-2.txt`
     - `{bundle_dir}/scope/context-only.txt`
     - `{bundle_dir}/scope/candidate-scope.txt` (all Tier 0 + Tier 1 + Tier 2 files before business-flow selection, or explicit filename/full-repo override)
     - `{bundle_dir}/scope/source-map.tsv` mapping `FlattenedName<TAB>OriginalPath<TAB>Tier<TAB>BusinessFlow<TAB>EntryPoint`
   - Print counts for all tiers. Sort each tier file deterministically and remove blank lines and duplicates.
   - Ensure `flow-scope.md` includes a `Business Flow Index` table with one row per flow containing: flow number, flow name, entry point group, actor, core contracts, and one `Related Files` count. `Related Files` is the unique Tier 0-2 file count for that flow; do not split it by tier in the user-facing index.
   - If `{bundle_dir}/scope/candidate-scope.txt` has more than 30 files and `--full-repo` was not requested, do not launch Tagger yet. Continue through step k to create briefs and sync `tai/artifacts/`, then stop and ask the user to choose flows/modules from `{bundle_dir}/scope/flow-scope.md`.
k. If common cache is missing or stale, **Create Pre-Digested Summaries** — to reduce token consumption when ~32 agent instances read the reference files:
   - Read `{bundle_dir}/references/x-ray.md`, extract the invariants list, trust assumptions, and integration dependencies. Write `{bundle_dir}/references/x-ray-brief.md` (max 1 page).
   - Read `{bundle_dir}/references/entry-points.md` and `{bundle_dir}/scope/flow-scope.md`, extract the business flows, entry points, actors, core contracts, and per-flow `Related Files` count. Write `{bundle_dir}/references/entry-points-brief.md` (max 1 page).
   - If `x-ray.md` or `entry-points.md` contains a low-confidence fallback header, preserve that warning at the top of the corresponding brief and later in the final report's Audit Summary.
   - Read `{bundle_dir}/references/attack-vectors.md` and `{bundle_dir}/references/defi-core-pack.md`, extract vulnerability patterns relevant to this codebase's tech stack, and always keep every DeFi core pack lens in the brief when the repo has DeFi, lending, vault, staking, AMM, collateral, or yield flows. Write `{bundle_dir}/references/attack-vectors-brief.md` (max 1 page unless DeFi core pack inclusion needs a short second page).
   - Sync common artifacts to `tai/artifacts/`: `all-solidity.txt`, `x-ray.md`, `entry-points.md`, `flow-scope.md`, `tier-0.txt`, `tier-1.txt`, `tier-2.txt`, `context-only.txt`, `source-map.tsv`, `x-ray-brief.md`, `entry-points-brief.md`, `attack-vectors-brief.md`, `defi-core-pack.md`.
   - Update `tai/artifacts/run-metadata.md` with timestamp, cwd, git commit if available, Solidity file count, scope hash, and generation mode (`fresh` or `regenerated-stale`).
   - Update `tai/artifacts/README.md` with scope counts, available business flows, common cache status, and cached flow annotation directories.
l. **Apply scope safeguard after cache reuse or fresh planning**:
   - Count the full Tier 0-2 candidate scope from `{bundle_dir}/scope/candidate-scope.txt` if present; otherwise derive it from `tier-0.txt`, `tier-1.txt`, and `tier-2.txt`.
   - If the candidate scope has more than 30 files, `--full-repo` was not requested, and the user has not already selected business flows/modules, stop and ask the user to choose flows/modules from `{bundle_dir}/scope/flow-scope.md`. When printing or summarizing choices, include each flow's core contracts and related Tier 0-2 file count, not just the flow name.
   - Do not run Tagger on the full candidate scope merely because common artifacts were reused.
m. **Select business flow(s), derive `{business_slug}`, and materialize this run's scope**:
   - Use the selected flow names from `flow-scope.md`; for explicit filename mode use a concise slug from the filename(s).
   - Convert to lowercase, remove unsafe characters, replace whitespace with `-`, collapse repeated `-`.
   - If multiple flows are selected, join slugs with `--`.
   - Store the slug in `{bundle_dir}/business-slug.txt`.
   - Preserve the common full source map as `{bundle_dir}/scope/source-map.full.tsv` before filtering.
   - Build `{bundle_dir}/scope/audit-scope.txt` from the selected business flows by filtering `{bundle_dir}/scope/source-map.full.tsv` or `{bundle_dir}/scope/source-map.tsv` to Tier 0-2 rows reachable from the selected entry points. For explicit filename mode, write exactly the requested files. For `--full-repo`, write the full candidate scope.
   - Replace `{bundle_dir}/scope/source-map.tsv` with the selected-flow source map used by this run. The repo-local common artifact `tai/artifacts/source-map.tsv` remains the full reusable map.
   - Sort `audit-scope.txt`, remove duplicates, and print the selected file count before launching Tagger.
n. Bash `while IFS= read -r f; do cp "$f" {bundle_dir}/sources/; done < {bundle_dir}/scope/audit-scope.txt` (flatten selected Tier 0-2 files; handle name collisions by prefixing with parent directories and update the selected `{bundle_dir}/scope/source-map.tsv` accordingly)
o. **Flow-local annotation cache check**:
   - Let `{flow_cache_dir}=tai/artifacts/flows/{business_slug}`.
   - Reuse flow annotations only if `{flow_cache_dir}/audit-scope.txt` exists, `cmp -s {bundle_dir}/scope/audit-scope.txt {flow_cache_dir}/audit-scope.txt` succeeds, and all annotation files exist under `{flow_cache_dir}/annotations/`.
   - **Reusable flow cache** → copy `{flow_cache_dir}/annotations/*` to `{bundle_dir}/annotations/by-root-cause/` and skip Tagger.
   - **Missing or stale flow cache** → run Tagger in step p, then sync `{bundle_dir}/scope/audit-scope.txt`, `{bundle_dir}/scope/source-map.tsv`, and `{bundle_dir}/annotations/by-root-cause/*` to `{flow_cache_dir}/`.
p. If flow annotation cache is missing or stale, **Launch Tagger Sub-agent**: Use the Agent tool to launch a **Tagger** sub-agent that will annotate only Tier 0-2 source files. Write the Tagger instructions as:

   > You are the Tagger agent. Your job is to annotate all `.sol` source files with security-relevant tags and produce annotation index files organized by root cause set.
   >
   > **Input files:**
   > - Read `{resolved_path}/tag-ontology.md` for the full tag catalog, detection patterns, confidence levels, and tag-to-set mappings.
   > - Source files are Tier 0-2 audit files at `{bundle_dir}/sources/*.sol`
   > - Read `{bundle_dir}/scope/source-map.tsv` and `{bundle_dir}/scope/flow-scope.md` so each tag can preserve source tier and business-flow context.
   >
   > **Output files** (write to `{bundle_dir}/annotations/by-root-cause/`):
   > - `auth.txt`, `validate.txt`, `flow.txt`, `state.txt`, `value.txt`, `env.txt`, `platform.txt` — one file per root-set, each line formatted as `FileName.sol:LineNumber → tagname | tier=<Tier> | flow=<BusinessFlow> | entry=<EntryPoint>`
   > - `README.txt` — summary with hit counts per root set and notable patterns
   >
   > **Process (efficiency-first):**
   > 1. **Batch Grep for exact tags**: Combine all exact-confidence tag patterns into a single Grep using `-E` (extended regex) with alternation: `grep -rnE 'pattern1|pattern2|pattern3' {bundle_dir}/sources/`. This reduces ~30+ Grep calls to 1-2 calls. Parse the output, resolve each match to its tag, and classify to root-set.
   > 2. For tags with confidence level `context`, use `grep -rn -A 5 -B 5 'pattern' {bundle_dir}/sources/` to capture surrounding context in one call — the 5-line context is sufficient to confirm the tag without a separate Read. Batch multiple context patterns with `-E` alternation: `grep -rn -A 5 -B 5 -E 'pattern1|pattern2' {bundle_dir}/sources/`.
   > 3. For tags with confidence level `inherited`, identify functions bearing the relevant modifiers or naming patterns, then add entries for each line within those functions.
   > 4. Write `README.txt` with hit counts per root set and any notable patterns observed.
   >
   > **Constraints:** Do NOT modify source files. Do NOT scan Context Only files as primary sources. Only produce annotation index files. Prefer Grep over Read — Grep is faster and consumes fewer tokens for pattern matching.

   Wait for the Tagger sub-agent to complete before proceeding to Round 2. Then sync flow-local cache to `tai/artifacts/flows/{business_slug}/` and refresh `tai/artifacts/README.md`.

**Round 2 — Root Cause Audit Loop**

Read `{resolved_path}/root.md` to get the list of root cases (R_auth, R_logic, R_order, R_arith, R_trust, R_runtime, R_validate). For each root case, launch a sub-agent group that iterates through flows:

0. **Zero-Hit Skip**: Before launching Researchers, check the annotation index files for each root case. If a root cause's relevant annotation index files are all empty (0 lines, i.e., no code patterns matched), skip that root case entirely — write a termination thinker directly:
   ```
   echo "Continue: No — No code patterns match this root cause in the codebase." > {bundle_dir}/root-case--{slug}/flow-1/thinker.md
   ```
   The annotation index to root case mapping is:

   | Root Cause | Check These Index Files |
   |---|---|
   | R_auth | `auth.txt` |
   | R_logic | `state.txt`, `value.txt`, `env.txt` |
   | R_order | `flow.txt`, `state.txt`, `env.txt` |
   | R_arith | `value.txt` |
   | R_trust | `flow.txt`, `env.txt`, `validate.txt` |
   | R_runtime | `platform.txt` |
   | R_validate | `validate.txt` |

   A root case can be skipped only if ALL its associated index files are empty. Do not launch Researcher/Questioner/Thinker for skipped root cases.

1. For each root case in `root.md`, create the directory structure:
   - Bash `mkdir -p {bundle_dir}/root-case--{slug}/flow-1/questioner`

Each root case group runs independently. Within a group, flows are sequential (Researcher → Questioner → Thinker):

**Flow {N} loop:**

a. **Researcher** — Read `{resolved_path}/agents/researcher.md` for agent definition. Pass `{root_case_name}`, all prior `researcher.md` and `thinker.md` from previous flows, `{bundle_dir}/sources/`, `{bundle_dir}/scope/flow-scope.md`, `{bundle_dir}/scope/source-map.tsv`, `{bundle_dir}/references/x-ray-brief.md`, `{bundle_dir}/references/entry-points-brief.md`, `{bundle_dir}/references/entry-points.md`, `{bundle_dir}/references/attack-vectors-brief.md`, `{bundle_dir}/references/defi-core-pack.md`, `{bundle_dir}/annotations/by-root-cause/`, `{resolved_path}/root.md`, `{resolved_path}/tag-ontology.md`, and `{resolved_path}/severity.md`. For flows after Flow 1, also pass `{flow_dir}/../cross-case-clues.md` if it exists. Use the annotation index as a quick-lookup map, but only pursue locations that can be tied to a business flow or entry point. Trace execution paths from x-ray entry points to the candidate code, preserving actor model, permission gates, source tier, flow context, and DeFi mandatory lens coverage. Write `{flow_dir}/researcher.md`.

b. **Questioner** — Read `{resolved_path}/agents/questioner.md` for agent definition. For each Vuln-{N} in `{flow_dir}/researcher.md`, launch a parallel sub-agent that receives the single candidate + `{bundle_dir}/scope/flow-scope.md` + `{bundle_dir}/scope/source-map.tsv` + `{bundle_dir}/references/x-ray-brief.md` + `{bundle_dir}/references/entry-points-brief.md` + `{bundle_dir}/references/entry-points.md` + `{bundle_dir}/references/attack-vectors-brief.md` + `{bundle_dir}/references/defi-core-pack.md`. Each sub-agent writes `{flow_dir}/questioner/vuln-{N}.md`.

c. **Thinker** — Read `{resolved_path}/agents/thinker.md` for agent definition. Pass all `{flow_dir}/questioner/vuln-N.md` files, `{bundle_dir}/scope/flow-scope.md`, `{bundle_dir}/references/x-ray-brief.md`, `{bundle_dir}/references/entry-points-brief.md`, `{bundle_dir}/references/defi-core-pack.md`, and `{bundle_dir}/sources/`. Perform flow-aware correlation analysis, identify uncovered entry-point paths and mandatory lens gaps, and generate search clues for the next Researcher round. Write `{flow_dir}/thinker.md`.

**Coordinator Scheduling — Pipeline Parallelization:**

The coordinator MUST NOT wait for all Researchers across all root cases to finish before launching Questioners. Instead, manage each root case independently using short-polling — this pipelines the work so that root cases progress at their own pace rather than being gated by the slowest Researcher:

1. **Launch Researchers for non-skipped root cases in parallel** (one Agent per non-skipped root case).
2. **Poll every 30s**: For each root case, check if `{flow_dir}/researcher.md` exists (`[ -f {flow_dir}/researcher.md ]`).
3. **As soon as a root case's Researcher completes**, immediately launch its Questioner(s) — do NOT wait for other root cases' Researchers.
4. **As soon as all Questioners for a root case complete**, immediately launch its Thinker.
5. **As soon as a root case's Thinker completes**, check termination conditions. If `Continue: Yes`, immediately launch the next flow's Researcher for that root case (do not wait for other root cases).

**Polling Parameters:**
- Polling interval: **30 seconds** (use `sleep 30` between checks — do NOT use 60s, 120s, 180s, or 300s waits)
- Maximum wait per agent type (timeout before printing warning and proceeding):
  - Researcher: **10 minutes**
  - Questioner (per candidate): **5 minutes**
  - Thinker: **5 minutes**
- On timeout, print: `⚠️ Timeout: {agent_type} for {root_case} flow-{N} exceeded {max_wait}. Continuing to next stage.`

**Termination** (both must be true to stop the loop):
- Thinker outputs "Continue: No" (no new searchable clues)
- Researcher found zero new candidates this flow

**Safeguard**: Hard cap at flow-2. If still finding new candidates at flow-2, include a note in the final report. Flow 2 rarely discovers new high-signal candidates beyond what Flow 1 finds — capping at flow-2 prevents wasted cycles on diminishing returns.

**Cross-Case Correlation Pass**

After all 7 root case groups have completed at least Flow 1 (i.e., each has produced its first `thinker.md`), run a cross-case correlation pass to detect exploit chains that span multiple root causes:

1. **Collect**: Read all `{bundle_dir}/root-case--*/flow-1/thinker.md` files. Extract Confirmed Vulnerabilities, Security Risks, Research Leads, and Correlations Discovered from each.

2. **Identify Cross-Case Patterns**:
   - **Same business flow or code location, different root causes**: If the same entry point, exploit path, or file:line appears in findings from 2+ root cases, this flow location is high-risk and may be part of a compound exploit.
   - **Exploit chain composition**: If a Confirmed Vulnerability from root case A creates a precondition for a finding from root case B (e.g., an auth bypass enables a state corruption), combine them into a single chain. Do not increase severity from Security Risk / Hardening / QA / Research Lead alone.
   - **Common dependency**: If multiple findings across different root cases trace back to the same external call or shared library, flag it as a systemic risk.

3. **Inject Cross-Case Clues**: If cross-case patterns are found, write a brief clue file to each affected root case's flow directory (e.g., `{bundle_dir}/root-case--{slug}/cross-case-clues.md`) summarizing the cross-case connections. These clues will be picked up by each root case's Researcher in its next flow as additional input — the Researcher should investigate whether the cross-case pattern reveals a more severe compound vulnerability.

4. **Non-blocking**: This pass does NOT block individual root case flow loops. Each root case continues its Researcher → Questioner → Thinker cycle independently. The cross-case clues are injected as supplementary input for subsequent flows only.

After this pass, allow all root case groups to complete their remaining flows (up to the flow-2 hard cap).

**Flow Completion Gate (MANDATORY before Round 3):**

The coordinator MUST ensure every root case completes its full lifecycle before entering Round 3:

1. For each root case, verify the flow loop terminated naturally (Researcher → Questioner → Thinker cycle complete, Thinker says Continue: No, or hard cap reached).
2. **If any root case has an unfinished flow** (Researcher written but Questioner/Thinker not run), **DO NOT proceed to Round 3**. Launch the missing Questioners and Thinkers for that flow first.
3. For root cases with zero Researcher findings: you may directly write a termination Thinker (`Continue: No`) without launching a full Thinker agent — there is nothing to correlate.
4. Only when ALL root cases have reached a terminal state may you proceed to Round 3.

**Round 3 — Consolidation & Report**

As coordinator, collect all sub-agent outputs, deduplicate, and produce the final report. Follow these steps in order:

**Step 1 — Collect All Candidates (Grep-First)**

First, extract verdicts with a single Grep to avoid reading every file:
```
grep -rn 'Verdict' {bundle_dir}/root-case--*/flow-*/questioner/
```

Group candidates by verdict:
- **Confirmed Vulnerability**, **Security Risk**, **Hardening / QA**, and **Research Lead**: Read the full questioner file. These appear in the report under separate sections.
- **False Positive**: Record the filename, root case, and flow number from the path. Read the full file if it overlaps with any non-FP candidate or if its rationale could downgrade a duplicate group.

For each candidate read, record:
- Source root case and flow number
- Vuln ID (from the filename)
- Title, proposed class, severity, and code locations (from the Researcher report referenced by the questioner)
- Business flow, entry point group, entry point, actor, reachability from entry point, and source tier
- Attacker, required access, trusted-role dependency, entry point, permission gates, and impact
- The Questioner's Verdict (`Confirmed Vulnerability`, `Security Risk`, `Hardening / QA`, `Research Lead`, `False Positive`)
- If verdict is not `Confirmed Vulnerability`: the falseness/uncertainty/trust-model rationale
- Any DeFi mandatory lens named by the candidate, and the candidate's lens coverage status.

**Step 1b — Build Coverage / Omission Review**

Collect the DeFi mandatory lens coverage rows from Researcher reports, Questioner reports, and Thinker coverage gaps. For every selected business flow and each mandatory lens, assign exactly one status:

- `covered`: relevant code was checked and any issue is represented in the final findings, risks, QA, leads, or false positives.
- `partial`: the lens was checked but supporting code or integration evidence was incomplete.
- `no issue`: the lens is not relevant to the selected flow or no suspicious pattern was found after checking.
- `unresolved`: the lens was not meaningfully checked or evidence conflicts remain.

If a lens is `partial` or `unresolved`, include a concise next check. Do not hide unresolved lens gaps just because they did not become findings.

**Step 2 — Deduplicate**

Compare all candidates pairwise. Two candidates are duplicates if they share **both**:
- Same primary code location (same file + overlapping line range), OR same exploit path
- Same business flow / entry point, AND same underlying root cause pattern (even if classified under different R_* categories)

When merging duplicates:
- Keep the most detailed version as the canonical entry
- List all root cases and flows where it appeared under "Root Cause Overlap"
- Do **not** automatically take the highest severity
- Do **not** automatically keep a positive verdict when another duplicate is `False Positive`, `Research Lead`, or `Security Risk`
- Re-rate the merged candidate from business-flow reachability, actor model, permission gates, trusted-role dependency, source tier, and proven impact
- If duplicate verdicts conflict, the merged result is at most `Research Lead` unless the coordinator reads the full evidence and explicitly proves a non-trusted attacker path
- If the path depends on a trusted role, the merged result is `Security Risk` or lower unless role bypass is proven
- If the merged candidate cannot be mapped to an entry point from `entry-points.md`, it cannot be a `Confirmed Vulnerability`; classify it as `Research Lead`, `Hardening / QA`, or `False Positive`.

**Step 3 — Print Terminal Summary**

Print a summary to the terminal before writing the report. Format:

```
=== Tai-audit: Final Summary ===
Scope: {N} Tier 0-2 files analyzed ({C} Context Only files excluded from primary scan)
Business flows checked: {B}
Root causes checked: 7
Total findings: {M} (after dedup)
  Confirmed Vulnerabilities: {CV} (Critical: {cv1}, High: {cv2}, Medium: {cv3}, Low: {cv4})
  Security Risks: {SR}
  Hardening / QA: {HQ}
  Research Leads: {RL}
  False Positives: {FP}

--- Confirmed Vulnerabilities ---
[CRITICAL] F-01: <business flow> / <entry point> — <title> — <file>:<line> (Flow 1, R_auth)
[HIGH]     F-02: <business flow> / <entry point> — <title> — <file>:<line> (Flow 1, R_logic)
...

--- Security Risks / Trust Assumptions ---
[MEDIUM]   S-01: <business flow> / <entry point> — <title> — <file>:<line> (trusted role: DispatcherOwner)
...

--- Hardening / QA Notes ---
[LOW]      H-01: <business flow> / <entry point> — <title> — <file>:<line>
...

--- Research Leads ---
[MEDIUM]   R-01: <business flow> / <entry point> — <title> — <file>:<line>
...

--- False Positives ---
[N/A]      FP-01: <business flow> / <entry point> — <title> — <file>:<line> (Flow 1, R_validate)
...

--- Coverage / Omission Review ---
[covered]    <business flow> — Native value consistency — <evidence>
[partial]    <business flow> — Reward entitlement timing — <next check>
[unresolved] <business flow> — Weird ERC20 behavior — <next check>
...
===============================
Full report: {bundle_dir}/report.md
Business report: tai/business/{business_slug}-report.md
```

**Step 4 — Generate report.md**

Write the final report to `{bundle_dir}/report.md` using the template below. Findings are separated by final class so QA/configuration/trust notes are not counted as High/Medium vulnerabilities.

```markdown
# Smart Contract Security Audit Report

## Audit Summary

| Field | Value |
|---|---|
| Scope | {N} Tier 0-2 Solidity files |
| Context Only Excluded From Primary Scan | {C} Solidity files |
| Business Flows Audited | {B} |
| Root Causes Audited | R_auth, R_logic, R_order, R_arith, R_trust, R_runtime, R_validate |
| Date | {today} |
| x-ray Source | existing / external-skill / fallback |

## Classification Summary

| Class | Critical | High | Medium | Low | Informational | Total |
|---|---:|---:|---:|---:|---:|---:|
| Confirmed Vulnerability | {cv_crit} | {cv_high} | {cv_med} | {cv_low} | {cv_info} | {cv_total} |
| Security Risk | 0 | 0 | {sr_med} | {sr_low} | {sr_info} | {sr_total} |
| Hardening / QA | 0 | 0 | 0 | {hq_low} | {hq_info} | {hq_total} |
| Research Lead | 0 | 0 | {rl_med} | {rl_low} | {rl_info} | {rl_total} |
| False Positive | 0 | 0 | 0 | 0 | 0 | {fp_total} |

## Entry Point Coverage Summary

| Business Flow | Entry Point Group | Entry Points | Actor | Tier 0-2 Files | Confirmed Vulnerabilities | Security Risks | Hardening / QA | Research Leads | False Positives |
|---|---|---|---|---:|---:|---:|---:|---:|---:|
| {flow_name} | {permissionless/role-gated/admin/init} | `{Contract.function()}` | {actor} | {n} | {cv} | {sr} | {hq} | {rl} | {fp} |

## Coverage / Omission Review

| Business Flow | Mandatory Lens | Status | Evidence | Next Check |
|---|---|---|---|---|
| {flow_name} | Native value consistency | covered / partial / no issue / unresolved | [files/functions checked or findings produced] | [exact follow-up or N/A] |
| {flow_name} | Native sentinel and metadata | covered / partial / no issue / unresolved | [files/functions checked or findings produced] | [exact follow-up or N/A] |
| {flow_name} | Swap route and execution bounds | covered / partial / no issue / unresolved | [files/functions checked or findings produced] | [exact follow-up or N/A] |
| {flow_name} | Reward entitlement timing | covered / partial / no issue / unresolved | [files/functions checked or findings produced] | [exact follow-up or N/A] |
| {flow_name} | External reward list liveness | covered / partial / no issue / unresolved | [files/functions checked or findings produced] | [exact follow-up or N/A] |
| {flow_name} | Weird ERC20 behavior | covered / partial / no issue / unresolved | [files/functions checked or findings produced] | [exact follow-up or N/A] |
| {flow_name} | Registry lifecycle | covered / partial / no issue / unresolved | [files/functions checked or findings produced] | [exact follow-up or N/A] |

---

## Confirmed Vulnerabilities

### {Business Flow}: {Entry Point}

#### F-{N}: [Title]

| Field | Value |
|---|---|
| **Severity** | Critical / High / Medium / Low |
| **Root Cause(s)** | R_xxx[, R_yyy] |
| **Code Location** | `FileName.sol:L100-L120` |
| **Discovered In** | Flow {N}, Root Case R_xxx |
| **Classification** | Confirmed Vulnerability |
| **Business Flow** | {Business Flow} |
| **Entry Point Group** | Permissionless / Role-Gated / Admin-Only / Initialization |
| **Entry Point** | `Contract.function()` |
| **Source Tier** | Tier 0 / Tier 1 / Tier 2 |
| **Attacker** | [non-trusted actor] |
| **Required Access** | [none/capital/timing/config] |
| **Trusted Role Dependency** | No |

#### Description
[What the vulnerability is and how it works]

#### Exploit Path
1. [Step-by-step trace from external entry point to exploit]
2. ...
3. [Impact: funds lost / state corrupted / functionality broken]

#### Permission Gates
[Why the non-trusted attacker can pass or bypass each gate]

#### Code Evidence
```solidity
// FileName.sol:L100-L120
[Relevant code snippet]
```

#### Verification Assessment
[Summarize the exploitability gate: actor, reachability, permission gates, impact proof, live/config dependencies]

#### Root Cause Overlap
[If this finding was found under multiple root cases, note them here]

#### Remediation
[Concrete fix recommendation for the confirmed vulnerability.]

---

## Security Risks / Trust Assumptions

### {Business Flow}: {Entry Point}

#### S-{N}: [Title]

| Field | Value |
|---|---|
| **Severity** | Medium / Low / Informational |
| **Root Cause(s)** | R_xxx[, R_yyy] |
| **Code Location** | `FileName.sol:L100-L120` |
| **Classification** | Security Risk |
| **Business Flow** | {Business Flow} |
| **Entry Point Group** | Permissionless / Role-Gated / Admin-Only / Initialization |
| **Entry Point** | `Contract.function()` |
| **Source Tier** | Tier 0 / Tier 1 / Tier 2 / Context Only |
| **Trusted Role Dependency** | Yes - [role name] |

#### Assessment
[Explain the trusted-role/governance/config/external-dependency risk and why it is not a non-trusted attacker vulnerability.]

#### Recommendation
[Concrete mitigation, monitoring, documentation, timelock, multisig, or configuration guidance.]

---

## Hardening / QA Notes

Group rows by business flow / entry point.

| ID | Business Flow | Entry Point | Root Cause | Severity | Source Tier | Code Location | Rationale | Recommendation |
|---|---|---|---|---|---|---|---|---|
| H-01 | [Flow] | `Contract.function()` | R_xxx | Low / Informational | Tier 0 / Tier 1 / Tier 2 / Context Only | `File.sol:L1` | [Why this is QA/hardening] | [Suggested hardening] |

## Research Leads

Group rows by business flow / entry point. Do not mix these into confirmed vulnerability counts.

| ID | Business Flow | Entry Point | Root Cause | Severity | Source Tier | Code Location | Missing Evidence | Next Check |
|---|---|---|---|---|---|---|---|---|
| R-01 | [Flow] | `Contract.function()` | R_xxx | Medium / Low | Tier 0 / Tier 1 / Tier 2 / Context Only | `File.sol:L1` | [Exploitability/live config/net impact not proven] | [Exact follow-up] |

## False Positives

| ID | Business Flow | Entry Point | Root Cause | Researcher Severity | Verdict Rationale |
|---|---|---|---|---|---|
| FP-01 | [Flow] | `Contract.function()` | R_xxx | Medium | [Why it is false] |

**Audit performed by Tai-audit skill. This report reflects automated analysis and agent-based review. Manual verification is recommended for all Critical and High severity findings.**
```

**Step 5 — Persist Report to Repo-Local Business Directory**

Persist the final report to the audited repository's `tai/business/` directory:

```
Bash cp {bundle_dir}/report.md tai/business/{business_slug}-report.md
```

Then update:
- `tai/business/README.md` with business flow, report path, run timestamp, audited file count, and final classification counts.
- `tai/artifacts/README.md` with common artifact status, scope counts, available business flows, and cached flow annotation directories.

Also print:
- Raw artifact directory: `{bundle_dir}`
- Business report: `tai/business/{business_slug}-report.md`
- Common artifacts: `tai/artifacts/`

Do not write or overwrite any report file in the repository root.

**Template compliance notes:**
- Findings MUST be grouped by business flow and entry point inside each classification section.
- The Entry Point Coverage Summary MUST count results by final class, not by raw Researcher candidate count.
- **Confirmed Vulnerabilities** MUST use the full finding template with attacker, access, permission gates, exploit path, code evidence, verification assessment, root cause overlap, and remediation.
- **Security Risks** MUST explicitly name the trusted role, governance/configuration dependency, or external dependency that prevents classification as a non-trusted attacker vulnerability.
- **Hardening / QA**, **Research Leads**, and **False Positives** may use compact tables.
- The report MUST NOT count Security Risks, Hardening / QA, or Research Leads as High/Medium vulnerabilities.
- A candidate that cannot be reached from an entry point in `entry-points.md` MUST NOT be listed as a Confirmed Vulnerability.
- The Coverage / Omission Review MUST include every DeFi mandatory lens for every selected DeFi business flow, even when the status is `no issue`.
- A candidate that depends only on future external protocol behavior, unverified out-of-scope behavior, or a speculative configuration must not be listed as a Confirmed Vulnerability; classify it as `Research Lead` or `Security Risk`.
- The official long-lived report path is `tai/business/{business_slug}-report.md`; no root-level report copy should be created.

## Working Directory & Conventions

All work happens in `{bundle_dir}` (created via `mkdir -p /tmp/tai-audit-<timestamp>`). **Do NOT delete this directory.** It must persist for post-audit inspection.

**Naming conventions:**
- `{slug}`: the root case short name without `R_` prefix (e.g., `auth`, `logic`, `order`, `arith`, `trust`, `runtime`, `validate`)
- `{flow_dir}`: shorthand for `{bundle_dir}/root-case--{slug}/flow-{N}`

| Path | Description |
|------|-------------|
| `{bundle_dir}/sources/` | Flattened copies of Tier 0-2 audit-scope `.sol` files. Agents read primary source from here. |
| `{bundle_dir}/references/` | Attack vectors and DeFi core pack from skill bundle + `x-ray.md` + `entry-points.md` from workspace. |
| `{bundle_dir}/scope/all-solidity.txt` | Raw `find` output listing discovered Solidity files. |
| `{bundle_dir}/scope/flow-scope.md` | Business-flow scope plan grouped by entry point. |
| `{bundle_dir}/scope/candidate-scope.txt` | Full Tier 0-2 candidate list before business-flow selection; used only for the 30-file safeguard. |
| `{bundle_dir}/scope/audit-scope.txt` | Tier 0-2 files selected for Tagger and primary Researcher review. |
| `{bundle_dir}/scope/context-only.txt` | Interfaces, utils, templates, deprecated, off-chain, tests, mocks, and other files excluded from primary scanning. |
| `{bundle_dir}/scope/source-map.full.tsv` | Full common source map before business-flow filtering, when preserved for the current run. |
| `{bundle_dir}/scope/source-map.tsv` | Selected-flow source filename to original path, tier, business flow, and entry point mapping. |
| `{bundle_dir}/annotations/by-root-cause/{set}.txt` | Code annotation index files (auth, validate, flow, state, value, env, platform). Format: `FileName.sol:LineNumber → tagname | tier=<Tier> | flow=<BusinessFlow> | entry=<EntryPoint>`. |
| `{bundle_dir}/root-case--{slug}/` | Per-root-cause working directory (one per root case in root.md). |
| `{bundle_dir}/root-case--{slug}/flow-{N}/researcher.md` | Researcher findings for flow N of this root case. |
| `{bundle_dir}/root-case--{slug}/flow-{N}/questioner/vuln-{N}.md` | Questioner verification for each individual candidate. |
| `{bundle_dir}/root-case--{slug}/flow-{N}/thinker.md` | Thinker correlation analysis for flow N. |
| `{bundle_dir}/report.md` | Final consolidated audit report, written by the coordinator. |
| `tai/artifacts/` | Repo-local common artifacts reused across business flows. |
| `tai/artifacts/flows/{business_slug}/` | Repo-local flow audit scope and annotation cache. |
| `tai/business/{business_slug}-report.md` | Repo-local final report for the selected business flow(s). |
