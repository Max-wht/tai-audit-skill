# DeFi Core Pack

This pack is always included for DeFi, lending, vault, staking, AMM, yield, bridge-liquidity, and collateral protocols. Do not drop these patterns during attack-vector brief generation even when the full `attack-vectors.md` is compressed.

## Mandatory Lens Checklist

Every selected business flow must be reviewed against these lenses and assigned one status in the final coverage review: `covered`, `partial`, `no issue`, or `unresolved`.

| Lens | What To Check | Common Evidence |
|---|---|---|
| Native value consistency | `payable` entry points require `msg.value == expectedAmount`; ERC20 branches reject nonzero `msg.value`; excess native value is refunded or reverted. | `payable`, `msg.value`, `_amount`, ETH deposit branches |
| Native sentinel and metadata | Native coin sentinel (`address(0)` or `0xEeee...`) is never passed to ERC20 metadata or transfer interfaces; sentinel convention is consistent across parent and child contracts. | `address(0)`, `ETH`, `IERC20Detailed.decimals()`, `symbol()`, `balanceOf()` |
| Swap route and execution bounds | Swap routes, fee tiers, pools, `amountOutMin`, slippage, and deadline are user-specified or governance-configurable where market conditions can change. Permissionless exits need user-controlled tolerance or a robust alternate exit. | `UNISWAP_FEE`, `fee`, `path`, `pool`, `minOut`, `slippage`, `deadline`, `withdraw`, `redeem` |
| Reward entitlement timing | Yield/reward distribution is not based on a manipulable instant balance, volume, or supply snapshot; same-block deposit/distribution/withdraw and MEV ordering are considered. | `distributeYield`, `reward`, `yield`, `balanceOf`, `totalSupply`, `volume`, `snapshot`, `checkpoint` |
| External reward list liveness | Loops over external reward/token/asset registries have bounds, pagination, removal, and failure isolation; dust cannot force costly or reverting work forever. | `extraRewardsLength`, `rewardToken`, `assets.length`, `_count`, `_offset`, `registerAsset`, `unregister` |
| Weird ERC20 behavior | Zero-value transfers, raw `approve`, non-standard return values, blacklist/pausable tokens, optional metadata, fee-on-transfer, rebasing, and hooks do not block core flows. | `transfer(0)`, `safeTransfer`, `TransferHelper.safeTransfer`, `approve`, `safeApprove`, `IERC20Detailed`, `balanceOf`, `yieldAmount`, `treasuryAmount` |
| Registry lifecycle | Admin/config registries have add, update, remove, validation, eventing, and recovery paths; stale or null entries cannot permanently block core loops. | mappings, arrays, `register`, `set`, `remove`, `_assetsCount`, `getAddress` |

## Must-Include Patterns

### Native Value Sent to Wrong Branch
- **D:** A payable function accepts ERC20-style deposits or actions but does not require `msg.value == 0` on non-native branches, or accepts native deposits without requiring `msg.value == amount`. Native funds can be stranded or over-forwarded.
- **FP:** Entry point explicitly checks `msg.value == 0` for ERC20 branches and `msg.value == expectedAmount` for native branches, or refunds excess before any external call.

### Native Sentinel Used as ERC20 Metadata
- **D:** `address(0)` or an ETH pseudo-address is interpreted as native coin but later passed to `IERC20`, `IERC20Metadata`, `IERC20Detailed`, `decimals()`, `symbol()`, `balanceOf()`, `transfer()`, or `approve()`.
- **FP:** Native coin branch exits before ERC20 calls, uses hardcoded native decimals only for display/math, or wraps to WETH before ERC20 operations.

### Hardcoded Swap Route or Fee Tier
- **D:** Protocol-internal swaps use hardcoded fee tier, path, pool, slippage, or no deadline. Market liquidity shifts can make the route unavailable, highly lossy, or sandwichable.
- **FP:** Route and fee tier are configurable with events and validation, user supplies final `minOut`/deadline, or swaps go through a vetted aggregator with output checks.

### Permissionless Exit Slippage/Liveness Freeze
- **D:** Permissionless withdrawal, redemption, or exit swaps use hardcoded slippage, fixed route/pool, or no deadline, and the user cannot choose tolerance. Market stress can make exits revert even when the user's position is solvent and assets exist.
- **FP:** User supplies `minOut` and `deadline`, governance can adjust bounds before execution without blocking users, or an alternate permissionless exit avoids the hardcoded swap.

### Reward Snapshot JIT
- **D:** Rewards/yield are allocated from instantaneous balances, supplies, borrowing volumes, or asset lists at distribution time. A user can deposit or rebalance just before distribution, capture outsized rewards, and exit immediately.
- **FP:** Rewards are time-weighted, snapshot from a previous block/epoch, checkpointed before balance changes, or subject to a minimum holding period/cooldown.

### External Reward List Gas or Revert DoS
- **D:** Core reward/yield processing iterates over a list controlled by an external protocol or admin registry. Any token dust, blacklisted recipient, zero-transfer revert, or long list can block the whole function.
- **FP:** Pagination is mandatory, failed transfers are isolated, list length is bounded by protocol config, zero amounts are skipped, and obsolete entries can be removed.

### Zero-Amount Transfer Revert
- **D:** A transfer or treasury/yield split may call token transfer with `amount == 0`. Common code shape: `amount = token.balanceOf(address(this))`, `treasuryAmount = amount.percentMul(fee)`, then `safeTransfer(..., treasuryAmount)` or `safeTransfer(..., amount)` without `if (amount > 0)`. Some tokens revert on zero-value transfers, blocking the whole distribution or claim path.
- **FP:** Every transfer is guarded by `if (amount > 0)`, or supported tokens are verified to accept zero transfers and the token list cannot include arbitrary external reward tokens.

### Raw Approve or Unsafe Allowance Lifecycle
- **D:** The protocol calls raw `approve()` or repeatedly changes nonzero allowance to nonzero allowance for arbitrary or stablecoin-like tokens. USDT-style approvals can fail or return false.
- **FP:** Uses SafeERC20 with zero-first allowance reset where needed, or supported token set excludes such behavior with explicit validation.

### Registry Add Without Remove
- **D:** An asset/reward registry supports adding entries but has no removal or deactivation path. Stale, null, dusted, or malicious entries can permanently increase gas cost or cause recurring reverts.
- **FP:** Registry supports removal/deactivation, iteration can skip bad entries, and batch ranges let operators avoid known-bad entries without losing distribution correctness.

## Precision Rule

A candidate that depends only on a future external protocol upgrade, unverified off-scope behavior, or a currently false integration assumption must not be classified as `Confirmed Vulnerability`. Keep it as `Research Lead` unless the current code and current reachable configuration prove the harmful behavior.

## External Dynamic List Current-Risk Rule

Do not dismiss a candidate as pure future speculation when the current code integrates a dynamic external list or registry that can supply arbitrary reward, asset, or hook-enabled tokens. The current-code risk is the missing guard, failure isolation, pagination, skip, or removal path around that dynamic list. Classify by reachability and actor model:

- Permissionless or core keeper path with concrete liveness loss can be `Confirmed Vulnerability`.
- Admin/external-governance controlled list impact is usually `Security Risk`.
- Missing live configuration proof should become `Research Lead`, not `False Positive`.
