# Tag Ontology for Code Line-Level Annotation

This reference defines the tag system used in Phase 1 (Code Annotation Tagging). Agents use this to run Grep-based detection and produce the `annotations/by-root-cause/` index files.

## The Seven Root-Cause Sets (Code-Analysis View)

These seven sets classify **what every executable code line does** in terms of security responsibility. Lines can belong to multiple sets.

| Set | Semantic Question | Typical Content |
|---|---|---|
| **AUTH** | Who is allowed to do this? | Caller checks, role checks, upgrade auth, pause/unpause, `tx.origin` |
| **VALIDATE** | Are inputs/signatures/bytes valid? | Zero-address checks, length checks, `abi.decode`, EIP-712, replay protection, `encodePacked` |
| **FLOW** | Does control leave the contract safely? | Low-level calls, `delegatecall`, value transfers, callback surfaces, return handling |
| **STATE** | Are state transitions sequenced correctly? | Balance/supply writes, invariant assertions, stale reads, effect ordering |
| **VALUE** | Do numeric/economic invariants hold? | Rounding, share math, slippage bounds, overflow paths, caps |
| **ENV** | Are env/ordering assumptions safe? | Timestamp branches, `blockhash`/`prevrandao`, unbounded loops, deadline checks |
| **PLATFORM** | Does the platform preserve intent? | Inline assembly, proxy storage, compiler version, upgrade mechanics, known bugs |

## Tag Detection Patterns

Below are the tags detectable via Grep in Solidity source code. Each tag has a confidence level:
- **exact**: Single-line Grep hit is definitive (e.g., `tx.origin`)
- **context**: Must read surrounding 5 lines to confirm (e.g., division in value-sensitive context)
- **inherited**: Inferred from function name or modifier (e.g., `onlyOwner` → entire function body inherits AUTH)

### AUTH Tags

| Tag | Grep Pattern | Confidence |
|---|---|---|
| `sem.auth.role_check` | `require\s*\(.*msg\.sender.*==`, `onlyOwner`, `onlyRole`, `hasRole`, `_checkOwner` | exact |
| `risk.auth.tx_origin` | `tx\.origin` | exact |
| `sem.auth.privileged_operation` | `onlyOwner`, `_upgradeTo`, `pause\s*\(`, `unpause\s*\(`, `mint\s*\(`, `_authorizeUpgrade`, `transferOwnership` | exact |
| `ctx.auth.meta_tx` | `_msgSender\s*\(`, `ERC2771Context`, `isTrustedForwarder` | exact |
| `guard.auth.timelock` | `block\.timestamp.*>=`, `timelock`, `ETA` | context |

### VALIDATE Tags

| Tag | Grep Pattern | Confidence |
|---|---|---|
| `guard.input.zero_address` | `address\s*\(\s*0\s*\)`, `!= address\(0\)`, `== address\(0\)` | exact |
| `sem.input.payable_value` | `payable`, `msg\.value` | exact |
| `risk.native.sentinel_metadata` | `address\s*\(\s*0\s*\)`, `0xEeeee`, `ETH`, `IERC20Detailed`, `decimals\s*\(`, `symbol\s*\(` | context |
| `guard.input.length_check` | `\.length`, `require\s*\(.*\.length` | context |
| `sem.abi.decode_user_bytes` | `abi\.decode\s*\(` | exact |
| `risk.hash.encode_packed_dynamic` | `abi\.encodePacked\s*\(`, `keccak256\s*\(.*encodePacked` | context |
| `guard.sig.replay_protection` | `nonce`, `domainSeparator`, `DOMAIN_SEPARATOR`, `_hashTypedDataV4`, `EIP712` | exact |

### FLOW Tags

| Tag | Grep Pattern | Confidence |
|---|---|---|
| `sem.call.low_level` | `\.call\s*\{`, `\.call\s*\(`, `address\(.*\)\.call` | exact |
| `sem.call.delegatecall` | `delegatecall` | exact |
| `sem.call.value_transfer` | `\.call\s*\{value:`, `\.transfer\s*\(`, `\.send\s*\(` | exact |
| `flow.user_input_to_call_target` | `.*\.call\s*\{.*\}`, `.*\.call\s*\(` (where target is a parameter) | context |
| `risk.call.unchecked_return` | `\.call\s*\{` without preceding `bool` or without subsequent `require` | context |
| `risk.token.zero_amount_transfer` | `transfer\s*\(`, `safeTransfer\s*\(`, `TransferHelper\.safeTransfer`, `yieldAmount`, `treasuryAmount`, `percentMul` | context |
| `risk.token.raw_approve` | `\.approve\s*\(`, `approve\s*\(` | context |
| `guard.flow.nonreentrant` | `nonReentrant`, `@nonreentrant`, `_notEntered`, `ReentrancyGuard` | exact |

### STATE Tags

| Tag | Grep Pattern | Confidence |
|---|---|---|
| `sem.state.balance_write` | `balance[s]?\[`, `supply`, `totalSupply`, `debt\[`, `allowance\[`, `shares\[`, `=.*\+`, `=.*\-` (in context of state variable assignment) | context |
| `guard.state.invariant_check` | `assert\s*\(`, `require\s*\(.*<=`, `require\s*\(.*>=`, `require\s*\(.*==` | context |
| `risk.registry.lifecycle_gap` | `register`, `add`, `set`, `remove`, `delete`, `deactivate`, `_assetsCount`, `mapping\s*\(` | context |
| `risk.flow.state_write_after_call` | (requires reading sequence — not purely grep-detectable at single-line level) | inherited |

### VALUE Tags

| Tag | Grep Pattern | Confidence |
|---|---|---|
| `risk.math.unchecked` | `unchecked\s*\{` | exact |
| `risk.math.rounding_value_sensitive` | `/\s` (division in assignment context) | context |
| `guard.value.slippage_bound` | `minOut`, `minAmount`, `minimumAmount`, `slippage`, `deadline`, `amountOutMin`, `amountInMax` | exact |
| `risk.swap.hardcoded_route_fee` | `UNISWAP_FEE`, `fee`, `path`, `pool`, `route`, `swapExact`, `Curve`, `Uniswap` | context |
| `risk.swap.permissionless_exit_liveness` | `withdraw`, `redeem`, `slippage`, `minOut`, `deadline`, `Curve`, `Uniswap` | context |
| `risk.reward.instant_snapshot` | `reward`, `yield`, `distribute`, `balanceOf`, `totalSupply`, `volume`, `snapshot`, `checkpoint` | context |
| `sem.value.external_balance_read` | `balanceOf\s*\(`, `getBorrowingAssetAndVolumes`, `totalSupply\s*\(` | context |

### ENV Tags

| Tag | Grep Pattern | Confidence |
|---|---|---|
| `risk.env.timestamp_sensitive` | `block\.timestamp` | exact |
| `risk.env.chain_randomness` | `blockhash`, `prevrandao`, `block\.difficulty` | exact |
| `risk.env.unbounded_loop` | `for\s*\(.*\.length` | exact |
| `risk.env.external_dynamic_list` | `extraRewardsLength`, `rewardToken`, `assets\.length`, `_count`, `_offset`, `for\s*\(.*length` | context |
| `risk.env.tod_sensitive` | `block\.number`, `block\.timestamp.*price`, `block\.timestamp.*rate` | context |

### PLATFORM Tags

| Tag | Grep Pattern | Confidence |
|---|---|---|
| `ctx.platform.inline_assembly` | `assembly\s*\{` | exact |
| `ctx.storage.proxy_layout_sensitive` | `_upgradeTo`, `_authorizeUpgrade`, `UUPS`, `TransparentUpgradeable`, `BeaconProxy`, `onlyProxy` | exact |
| `ctx.compiler.version_risky` | `pragma solidity` (check version against known-bug list) | exact |

## Tag-to-Set Mapping

| Tag Prefix | Primary Set | May Also Imply |
|---|---|---|
| `sem.auth.*`, `risk.auth.*`, `guard.auth.*`, `ctx.auth.*` | **AUTH** | — |
| `guard.input.*`, `sem.input.*`, `sem.abi.*`, `risk.hash.*`, `risk.native.*`, `guard.sig.*` | **VALIDATE** | AUTH, VALUE |
| `sem.call.*`, `risk.call.*`, `risk.token.*`, `guard.flow.*`, `flow.*` | **FLOW** | STATE, VALUE, PLATFORM |
| `sem.state.*`, `guard.state.*`, `risk.state.*`, `risk.registry.*` | **STATE** | VALUE, FLOW |
| `risk.math.*`, `risk.swap.*`, `risk.reward.*`, `sem.value.*`, `guard.value.*` | **VALUE** | STATE, ENV |
| `risk.env.*` | **ENV** | FLOW, STATE, AUTH |
| `ctx.compiler.*`, `ctx.storage.*`, `ctx.platform.*` | **PLATFORM** | STATE |

## Cross-Mapping: Audit Root Causes ↔ Code-Analysis Tag Sets

This mapping tells the Researcher which annotation index files to consult for each audit root cause.

| Audit Root Cause | Primary Tag Set(s) | Search These Annotation Files |
|---|---|---|
| **R_auth** — 授权失效 | AUTH | `auth.txt` |
| **R_validate** — 验证失效 | VALIDATE | `validate.txt` |
| **R_order** — 时序/重入/排序 | FLOW + STATE + ENV | `flow.txt`, `state.txt`, `env.txt` |
| **R_arith** — 数值/记账 | VALUE | `value.txt` |
| **R_trust** — 外部依赖 | FLOW + ENV + VALIDATE | `flow.txt`, `env.txt`, `validate.txt` |
| **R_logic** — 业务逻辑 | STATE + VALUE + ENV | `state.txt`, `value.txt`, `env.txt` |
| **R_runtime** — 平台语义 | PLATFORM | `platform.txt` |
| **A_flash** — 闪电贷放大 | (amplifies R_auth, R_logic, R_arith, R_trust) | Check above files for economic/governance surfaces |

## Annotation Output Format

Phase 1 produces 7 index files under `{bundle_dir}/annotations/by-root-cause/`:

```
annotations/by-root-cause/
  auth.txt
  validate.txt
  flow.txt
  state.txt
  value.txt
  env.txt
  platform.txt
```

Each file uses the format:
```
FileName.sol:LineNumber → tagname
```

Example:
```
LendingPool.sol:42 → sem.auth.role_check
LendingPool.sol:127 → sem.call.value_transfer
LendingPool.sol:130 → risk.flow.state_write_after_call
Router.sol:89 → guard.value.slippage_bound
```

The annotation step is run **after x-ray** so that x-ray's source analysis and entry point classification can inform context-dependent tags (confidence level `context` or `inherited`).
