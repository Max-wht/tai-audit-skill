# Root Cause Catalog

These seven root causes form a cover (not a partition) of the smart contract vulnerability universe $U_C$. Each root cause maps to one or more code-analysis annotation sets — the Researcher uses these to locate suspicious code via the annotation index files in `{bundle_dir}/annotations/by-root-cause/`.

See `tag-ontology.md` for the full tag-to-Grep-pattern reference.

---

## 1. R_auth — Authorization & Identity Binding Failure

**What fails**: "Who can do this" is bound incorrectly.

**Code-Analysis Tag Sets**: AUTH
**Annotation Index**: `auth.txt`

**OWASP**: SC01 Access Control Vulnerabilities
**SCWE Families**: SCSVS-AUTH; SCWE-016, SCWE-017, SCWE-018, SCWE-101

**Key Patterns**:
- Missing `onlyOwner` / role check on privileged functions
- `tx.origin` used for authentication
- Unprotected initializer functions
- Single-point admin without timelock or multisig
- Meta-transaction caller reconstruction failure (ERC2771)
- Role escalation / role management failure

**Research Grep Keywords**: `tx.origin`, `onlyOwner`, `onlyRole`, `hasRole`, `_msgSender()`, `initialize`, `transferOwnership`, `renounceOwnership`

---

## 2. R_logic — Business Logic & Invariant Modeling Failure

**What fails**: Code runs exactly as written, but the rules themselves are exploitable.

**Code-Analysis Tag Sets**: STATE + VALUE + ENV
**Annotation Indexes**: `state.txt`, `value.txt`, `env.txt`

**OWASP**: SC02 Business Logic Vulnerabilities
**SCWE Families**: SCSVS-DEFI; SCWE-116, SCWE-125, SCWE-101

**Key Patterns**:
- Incorrect reward / fee distribution formulas
- Instant-balance or instant-volume reward/yield snapshots that can be JIT-deposited into
- Missing supply cap or economic bound
- Missing health factor / solvency check
- Missing registry removal/deactivation path causing stale entries to affect core flows
- Path-dependent state machine with exploitable transitions
- Governance action construction flaws
- Economic invariant not enforced at protocol level

**Research Grep Keywords**: `reward`, `yield`, `distribute`, `fee`, `cap`, `maxSupply`, `health`, `solvent`, `collateral`, `liquidate`, `redeem`, `borrow`, `volume`, `snapshot`, `checkpoint`, `registry`, `register`, `unregister`, `governance`, `proposal`, `quorum`

---

## 3. R_order — Timing, Reentrancy & Transaction Ordering Failure

**What fails**: "When / in what order things happen" is underestimated.

**Code-Analysis Tag Sets**: FLOW + STATE + ENV
**Annotation Indexes**: `flow.txt`, `state.txt`, `env.txt`

**OWASP**: SC08 Reentrancy Attacks (+ MEV overlaps with SC03, SC02)
**SCWE Families**: SCWE-046, SCWE-052, SCWE-037, SCWE-137, SCWE-142, SCWE-134

**Key Patterns**:
- Classic reentrancy (state write after external call)
- Read-only reentrancy (stale view state used after callback)
- Cross-function reentrancy
- Transaction order dependency / front-running
- Sandwich attack surfaces (AMM, liquidation, auction)
- MEV — validator-ordering-sensitive operations
- JIT deposit/withdraw around reward, yield, interest, or fee distribution
- Missing deadline or stale transaction protections on swaps and user exits

**Research Grep Keywords**: `nonReentrant`, `.call{`, `.call(`, `delegatecall`, `block.timestamp`, `block.number`, `deadline`, `snapshot`, `checkpoint`, `MEV`, `deposit`, `withdraw`, `msg.sender` ordering, state writes after external calls

---

## 4. R_arith — Arithmetic, Accounting & Resource Boundary Failure

**What fails**: "The math is wrong" or "resource boundaries are modeled incorrectly."

**Code-Analysis Tag Sets**: VALUE
**Annotation Index**: `value.txt`

**OWASP**: SC07 Arithmetic Errors, SC09 Integer Overflow and Underflow
**SCWE Families**: SCWE-047, SCWE-124, SCWE-059, SCWE-109, SCWE-126, SCWE-058

**Key Patterns**:
- Precision loss / rounding error in financial math
- Share inflation attacks (ERC4626 first-depositor)
- LP token accounting bias
- Native amount / `msg.value` mismatch causing incorrect accounting
- Hardcoded fee tier or route constants that misprice swaps or yield conversion
- Hardcoded user-exit slippage or route constants that can block withdrawals/redemptions during market stress
- Integer overflow/underflow (especially in `unchecked` blocks)
- Gas griefing / unbounded resource consumption
- Queue growth with no bound

**Research Grep Keywords**: `unchecked`, `/ ` (division in assignment), `decimals`, `precision`, `supply`, `balance`, `shares`, `totalAssets`, `convertToShares`, `convertToAssets`, `msg.value`, `percentMul`, `pricePerShare`, `UNISWAP_FEE`, `fee`, `amount`, `minOut`, `slippage`, `withdraw`, `redeem`

---

## 5. R_trust — External Dependency & Trust Boundary Failure

**What fails**: The contract trusts something outside its boundary that can be manipulated.

**Code-Analysis Tag Sets**: FLOW + ENV + VALIDATE
**Annotation Indexes**: `flow.txt`, `env.txt`, `validate.txt`

**OWASP**: SC03 Price Oracle Manipulation, SC06 Unchecked External Calls
**SCWE Families**: SCSVS-ORACLE, SCSVS-COMM, SCSVS-BRIDGE; SCWE-028, SCWE-048, SCWE-042, SCWE-104, SCWE-110, SCWE-112, SCWE-113, SCWE-086

**Key Patterns**:
- Price oracle manipulation (spot price, low-liquidity TWAP)
- Stale oracle data without staleness check
- Malicious / non-standard ERC20 token (fee-on-transfer, rebase, callback)
- Weird ERC20 behavior (zero-transfer revert, raw approve failure, optional metadata, blacklist/pausable)
- Unchecked external call return values
- External reward/token lists that can grow, revert, or include arbitrary tokens
- Zero-amount reward/yield transfers of externally supplied tokens without `amount > 0` guards
- Bridge message / proof validation gaps
- Block variable used as randomness source
- Cross-chain message nonce / chainId / domain validation

**Research Grep Keywords**: `oracle`, `getPrice`, `latestAnswer`, `latestRoundData`, `twap`, `spot`, `.call{`, `.transfer(`, `approve`, `safeApprove`, `blockhash`, `prevrandao`, `extcodesize`, `IERC20`, `IERC20Detailed`, `safeTransfer`, `safeTransferFrom`, `TransferHelper.safeTransfer`, `rewardToken`, `extraRewardsLength`, `yieldAmount`, `treasuryAmount`, `percentMul`, `poolInfo`, `Uniswap`, `Curve`

---

## 6. R_runtime — Language, Compiler, EVM & Upgrade Semantics Failure

**What fails**: The platform/compiler/proxy layer doesn't preserve developer intent.

**Code-Analysis Tag Sets**: PLATFORM
**Annotation Index**: `platform.txt`

**OWASP**: SC10 Proxy & Upgradeability Vulnerabilities
**SCWE Families**: SCWE-099, SCWE-098, SCWE-118, SCWE-035, SCWE-039, SCWE-061, SCWE-089, SCWE-144, SCWE-150

**Key Patterns**:
- Proxy storage collision (implementation vs. proxy layout mismatch)
- Unprotected upgrade function / re-initialization
- Function selector clash between proxy and implementation
- Solidity compiler known bugs (version-specific)
- Vyper `_abi_decode` / version-specific semantics
- Inline assembly memory/storage corruption
- `delegatecall` to untrusted / unverified code
- Selfdestruct / deprecated opcode misuse

**Research Grep Keywords**: `delegatecall`, `assembly`, `_upgradeTo`, `upgradeTo`, `_authorizeUpgrade`, `initialize`, `UUPS`, `TransparentUpgradeable`, `pragma solidity`, `selfdestruct`, `onlyProxy`, `onlyNotInitialized`

---

## 7. R_validate — Input, Encoding, Signature & Message Validation Failure

**What fails**: Untrusted data is accepted as valid without sufficient verification.

**Code-Analysis Tag Sets**: VALIDATE
**Annotation Index**: `validate.txt`

**OWASP**: SC05 Lack of Input Validation
**SCWE Families**: SCWE-090, SCWE-141, SCWE-143, SCWE-122, SCWE-154, SCWE-105, SCWE-055, SCWE-147, SCWE-131

**Key Patterns**:
- Missing zero-address validation on critical addresses
- Native coin sentinel confusion (`address(0)` vs pseudo-ETH address) and ERC20 metadata calls on native assets
- Missing `msg.value` checks on payable functions with ERC20 and native branches
- Missing calldata/returndata length check
- Signature replay (missing nonce, domain separator, deadline)
- `abi.encodePacked` hash collision on dynamic types
- Missing slippage / deadline on swap/liquidity operations
- Cross-chain message payload validation gaps
- `abi.decode` without bounds / type validation

**Research Grep Keywords**: `address(0)`, `0xEeeee`, `ETH`, `payable`, `msg.value`, `abi.decode`, `abi.encodePacked`, `keccak256`, `nonce`, `deadline`, `minOut`, `minAmount`, `slippage`, `domainSeparator`, `_hashTypedDataV4`, `ecrecover`, `ECDSA`, `decimals()`, `symbol()`, `approve`

---

## A_flash — Flash Loan Amplifier

**Not a root cause.** Flash loans amplify existing weaknesses in R_auth, R_logic, R_arith, and R_trust by providing massive temporary capital. Any finding in those root causes that touches economic constraints or governance should be evaluated under flash loan amplification.

**OWASP**: SC04 Flash Loan–Facilitated Attacks

**When to flag**: A vulnerability in R_logic (e.g., missing supply cap), R_arith (e.g., rounding bias), or R_trust (e.g., spot oracle) that could be exploited with large temporary capital.
