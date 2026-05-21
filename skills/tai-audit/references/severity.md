# Severity and Classification Rubric

Researchers and Questioners must separate **what was observed** from **what is exploitable**. A code fact, grep hit, trusted-role power, or hardening gap is not automatically a vulnerability.

Tai-audit is business-flow first. A candidate must be reachable from a concrete entry point in `entry-points.md` before it can be treated as a vulnerability. Isolated code facts in interfaces, utilities, templates, deprecated code, off-chain helpers, tests, mocks, or un-mapped libraries are not findings by themselves.

## Finding Classes

| Class | Definition | Severity Ceiling |
|---|---|---|
| **Confirmed Vulnerability** | A non-trusted attacker can reach the path, pass or bypass permission gates, and cause concrete loss, corruption, or liveness impact. | Critical |
| **Security Risk** | A real risk under trusted-role compromise, governance/admin action, deployment misconfiguration, external protocol compromise, or explicit trust assumption. | Medium |
| **Hardening / QA** | Best-practice gap, code-quality issue, deployment footgun, dust/rounding edge, or low-impact robustness improvement without a proven exploit path. | Low / Informational |
| **Research Lead** | Interesting code fact or attack surface where exploitability, live configuration, permissions, or net impact is not proven. | Medium |
| **False Positive** | Code fact is wrong, path is unreachable, permissions/design intentionally block it, or impact claim does not follow. | N/A |

## Flow and Entry Point Gate

To classify a candidate as `Confirmed Vulnerability`, all of the following must be true:

- It maps to a business flow and entry point from x-ray's `entry-points.md`.
- The actor can reach that entry point without relying on a trusted project role, or a role bypass/forgery/replay/unauthorized acquisition is proven.
- The path is traced from the entry point through permission gates to the affected code.
- The impact is concrete: net profit, deterministic loss, state corruption, or meaningful liveness failure.

If the candidate cannot be mapped to an entry point, classify it as `Research Lead`, `Hardening / QA`, or `False Positive`. If the candidate exists only in a Context Only file, it cannot be standalone; it needs a Tier 0-2 call chain before severity can exceed Low/Informational.

## Severity Levels

| Severity | Use Only When |
|---|---|
| **Critical** | A non-trusted attacker can directly steal or permanently lock most/all funds, mint unbacked value, or make the protocol insolvent with no privileged role. |
| **High** | A non-trusted attacker can cause material fund loss or critical invariant violation with realistic capital/timing/preconditions. |
| **Medium** | A non-trusted attacker can cause bounded loss, meaningful liveness failure, or single-user/protocol functionality impairment; OR a serious Security Risk depends on trusted-role or external-governance compromise. |
| **Low** | Hardening, QA, spec mismatch, configuration footgun, dust/rounding edge, or trusted-role risk with no direct non-trusted attacker path. |
| **Informational** | Documentation, monitoring, operational, or best-practice note with negligible direct impact. |

## Medium+ Evidence Requirements

Any Medium, High, or Critical item must answer:

- Who triggers it: ordinary user, asset manager, fund owner, protocol admin, governance, deployer, external protocol, or unknown?
- Which business flow and entry point reaches it?
- Which permission gates are passed or bypassed?
- What is the concrete net loss, net profit, state corruption, or liveness impact?
- What live/config dependency is required, and was it verified?

If these answers are incomplete, downgrade the item to `Research Lead`, `Hardening / QA`, or Low severity.

## External Dependency and Speculation Downgrade Rule

If the harmful behavior requires a future external protocol upgrade, an unverified out-of-scope implementation, an unsupported token/configuration, or a speculative non-reverting failure mode that is not true in the current reachable deployment, do **not** classify it as `Confirmed Vulnerability`.

- Use `Research Lead` when the concern is plausible but not proven in current code/configuration.
- Use `Security Risk` when the concern depends on a trusted role, governance, admin registry, or external protocol compromise.
- Use `Confirmed Vulnerability` only when the current code path and current reachable configuration prove the failure mode and concrete impact.

Dynamic external lists are different from pure future speculation. If current code already consumes an external or admin-configured list of reward, asset, hook, or strategy tokens, the absence of zero-amount guards, failure isolation, pagination, skip logic, or removal paths is a current-code risk. Classify it by reachability and actor model rather than discarding it solely because the specific bad token is not currently observed.

Permissionless exit liveness also deserves explicit impact framing. A hardcoded slippage, fixed pool/route, or missing deadline in a user withdrawal/redemption path may be Medium+ when realistic market movement can prevent solvent users from exiting. Treat it as QA only when the user has another permissionless exit, can set their own bounds, or the blocked path is non-core.

## Auth and Trusted-Role Downgrade Rule

Bug bounty threat models normally treat project-controlled roles as trusted unless the bounty explicitly says otherwise. If the harmful path depends on `onlyOwner`, `onlyRole`, `onlyAdmin`, `onlyDispatcherOwner`, `onlyFundDeployerOwner`, council, multisig, governance, deployer, or another project/operator role:

- Do **not** classify it as High/Critical or as a `Confirmed Vulnerability` by default.
- Classify it as `Security Risk` if the consequence is meaningful under role compromise or misconfiguration.
- Classify it as `Hardening / QA` if it is only centralization, no timelock, zero-address validation, deployment configuration, or process hardening.
- Escalate to `Confirmed Vulnerability` only if the evidence proves a non-trusted attacker can bypass the role gate, incorrectly obtain the role, replay/forge authorization, or the role is not trusted by the stated bounty threat model.

## Usage

When evidence is incomplete, downgrade the class or severity. Do not default upward. Researchers may propose severity, but Questioners and the coordinator must re-rate after checking actor model, permissions, reachability, and impact.
