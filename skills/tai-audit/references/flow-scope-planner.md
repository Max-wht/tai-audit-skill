# Flow Scope Planner

The planner turns x-ray business context into a narrow audit scope. Its job is to prevent repo-wide grep noise by selecting files reachable from meaningful entry points.

## Inputs

- `{bundle_dir}/scope/all-solidity.txt` — raw Solidity inventory.
- `{bundle_dir}/references/x-ray.md` — protocol overview, threat model, invariants, hotspots.
- `{bundle_dir}/references/entry-points.md` — business flows, entry points, actors, call chains.

## Output Files

Write these files under `{bundle_dir}/scope/`:

- `flow-scope.md` — human-readable scope plan grouped by business flow.
- `tier-0.txt` — files that define user, manager, protocol, or admin entry points.
- `tier-1.txt` — files directly called by Tier 0 for value movement, state mutation, share/accounting math, policy checks, or custody.
- `tier-2.txt` — oracle, adapter, external-position, policy, queue, upgrade, and admin dependencies that are relevant to the selected flows.
- `context-only.txt` — interfaces, external interfaces, simple utilities, templates, deprecated code, off-chain helpers, tests, mocks, and interface-shaped files.
- `candidate-scope.txt` — all Tier 0 + Tier 1 + Tier 2 files before the user selects a business flow. This is the safeguard input, not necessarily the Tagger input.
- `source-map.tsv` — `FlattenedName<TAB>OriginalPath<TAB>Tier<TAB>BusinessFlow<TAB>EntryPoint`.

`flow-scope.md` must include a human-selectable flow index. The user must be able to choose a flow from the summary table without opening every flow section, so the index must show core contracts and one related-file count. `Related Files` means the unique Tier 0-2 files reachable from that flow; do not split this count by tier in the user-facing index.

## Classification Rules

Classify each Solidity file into exactly one primary tier:

| Tier | Meaning |
|---|---|
| Tier 0 | Defines a business entry point from `entry-points.md`, such as deposit, redeem, borrow, liquidate, manager execution, migration, fee settlement, queue action, or admin upgrade/setup. |
| Tier 1 | Directly participates in a Tier 0 call chain and mutates value, state, accounting, balances, shares, collateral, debt, queues, permissions, or policy decisions. |
| Tier 2 | Security-relevant dependency used by a selected flow: oracle, adapter, parser, external-position library, policy, registry, upgrade beacon, initializer, callback handler, or external protocol boundary. |
| Context Only | Interface, external-interface, simple utility, template, deprecated, off-chain, test/mock, vendored dependency, or `I*.sol` file. These are not scanned by Tagger by default. |

Context Only files are not ignored forever. A Researcher may read them later when a Tier 0-2 call chain references them, but they must not generate standalone candidates. A file under a normally context-only path may be promoted to Tier 1 or Tier 2 when a selected entry-point chain directly reaches it and it carries value movement, state mutation, accounting, custody, policy, oracle, upgrade, or validation logic.

## Selection Process

1. Parse `entry-points.md` first. Treat `Protocol Flow Paths` and permissioned entry point sections as the source of truth for business flows.
2. Parse `x-ray.md` for core flow, key attack surfaces, file hotspots, trust assumptions, and integration dependencies.
3. Map each entry point to its defining file from `all-solidity.txt`.
4. Add directly called value/state/accounting dependencies from the call chain as Tier 1.
5. Add relevant oracle/adapter/policy/external-position/upgrade/admin dependencies as Tier 2 only when tied to a selected business flow or x-ray hotspot.
6. Put all simple interfaces, passive utilities, templates, deprecated, off-chain, tests, mocks, and unreferenced libraries into Context Only.
7. If a file could be Tier 2 or Context Only, choose Context Only unless the flow map or x-ray hotspot gives a concrete reason to inspect it. If promoted despite a context-only path, explain the concrete reachable logic in `flow-scope.md`.
8. Write `candidate-scope.txt` from Tier 0 + Tier 1 + Tier 2. Sort each tier file deterministically, remove blank lines, and remove duplicate paths.
9. For every business flow, compute one unique related-file count from `source-map.tsv`: the unique Tier 0 + Tier 1 + Tier 2 files reachable from that flow. Do not show tier-split counts in the flow index.
10. Do not write the final flow-specific `audit-scope.txt` here. The coordinator materializes it after business-flow selection, so repo-local common cache can be reused across different flows.

## `flow-scope.md` Template

```markdown
# Flow Scope

## Scope Summary

| Tier | Files | Rule |
|---|---:|---|
| Tier 0 | {n} | Entry point contracts |
| Tier 1 | {n} | Direct value/state/accounting dependencies |
| Tier 2 | {n} | Security-relevant dependencies |
| Context Only | {n} | Interfaces/utils/templates/deprecated/off-chain/tests/mocks |

## Business Flow Index

| # | Flow | Entry Point Group | Actor | Core Contracts | Related Files |
|---:|---|---|---|---|---:|
| 1 | {Business Flow Name} | {Permissionless / Role-Gated / Admin-Only / Initialization} | {actor} | `CoreA`, `CoreB` | {tier0+tier1+tier2 unique count} |

## Business Flows

### {Business Flow Name}

| Field | Value |
|---|---|
| Actor | {user / manager / owner / admin / external protocol} |
| Entry Point Group | {Permissionless / Role-Gated / Admin-Only / Initialization} |
| Entry Points | `{Contract.function()}`, ... |
| Call Chain | `A()` -> `B()` -> `C()` |
| Core Contracts | `...` |
| Related Files | {unique Tier 0-2 file count} |
| Tier 0 Files | `...` |
| Tier 1 Files | `...` |
| Tier 2 Files | `...` |
| Context Only Dependencies | `...` |
| Reason Selected | {value movement / share accounting / policy gate / oracle / upgrade / x-ray hotspot} |

## Excluded Primary Scan Surface

| File/Pattern | Reason |
|---|---|
| `interfaces/` | ABI only; read as context if referenced |
| `utils/` | Helper library by default; promote only if selected call chain reaches value/state/security logic |
```

## Hard Gates

- If Tier 0-2 contains more than 30 files and the user did not request full-repo mode, stop after writing the scope files and ask the user to choose flows/modules.
- Never promote a Context Only grep hit to `Confirmed Vulnerability` unless a Tier 0-2 entry point reaches it and the exploitability gate is satisfied.
- Admin/setup/upgrade flows may be selected for trust-risk review, but project-controlled roles remain trusted by default in bug bounty mode.
