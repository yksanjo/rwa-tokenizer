# Audit Brief — RWAToken v1

**Status:** unaudited reference implementation.
**Target auditors (suggested):** Trail of Bits, OpenZeppelin, Halborn,
Spearbit, ChainSecurity.

This document is the scoping note we would hand to an audit firm. It is
also the document we would hand to an institution evaluating this codebase
so that the limitations are visible up-front rather than discovered during
diligence.

---

## 1. Codebase under review

- `contracts/src/RWAToken.sol` — single contract, ~250 lines of Solidity
- `contracts/test/RWAToken.t.sol` — Foundry test suite
- OpenZeppelin upgradeable contracts (v5.x) — assumed audited; out of
  scope except for incorrect usage by `RWAToken`.

The frontend, deploy scripts, and AI-generation scripts are **not** part
of an audit scope.

## 2. Trust model

### Roles and their assumed trustworthiness

| Role | Holder (assumed) | Trust assumption |
|---|---|---|
| `DEFAULT_ADMIN_ROLE` | Issuer multi-sig (HSM) | Fully trusted. Controls upgrades and role grants. |
| `ISSUER_ROLE` | Issuer entity | Fully trusted. Authorized to mint, burn (forced redemption), set fees, advance lifecycle. |
| `AGENT_ROLE` | Fund administrator | Trusted to provide accurate NAV updates and to pause in emergencies. |
| `VERIFIER_ROLE` | KYC provider | Trusted to whitelist only post-KYC accounts. |
| Token holders | Various | Untrusted. Must pass compliance checks. |

### Off-chain assumptions

- KYC is performed off-chain; on-chain whitelist is the trust anchor.
- NAV is computed by a fund administrator off-chain and pushed on-chain.
  This contract assumes a single trusted pusher.
- Management fees are settled off-chain via NAV deduction (the contract
  does not move fee funds). Issuer realizes fees through residual value
  on redemption / via separate distribution.

## 3. Threat model — questions for the auditor

### Compliance / access control

1. Can a non-whitelisted address ever receive or send tokens through any
   path (mint, burn, transfer, transferFrom, permit if added)?
2. Does the `_update` override correctly cover all token movement paths
   under OpenZeppelin v5?
3. Can a blacklisted address be re-whitelisted via any path? (Intended:
   no — see `whitelistAddress` revert.)
4. Can role-grant be exploited to escalate from `ISSUER_ROLE` to
   `DEFAULT_ADMIN_ROLE`?

### Fee accounting

5. Is the time-prorated fee accrual monotonic and free of double-counting
   across `mint`, `burn`, `updateNAV`, `setManagementFee`, and
   `matureAsset`?
6. Is there any sequence of NAV updates and fee-rate changes that yields
   an incorrect total accrual?
7. Can `accruedFees` overflow or exceed `nav` under realistic inputs
   (NAV ≤ `type(uint128).max`, time ≤ 100 years, fee ≤ 500 bps)?
8. Is `previewAccruedFees()` consistent with the state change that
   `_accrueFees()` produces?

### Share price / portfolio value

9. Are `getSharePrice()` and `getPortfolioValue()` free of rounding bias
   that could be exploited via small-balance mint/burn?
10. Is the `netNav = nav > accruedFees ? nav - accruedFees : 0` clamp
    safe? Are there preconditions where fees should never exceed NAV?

### Upgradeability

11. Is the storage layout safe against future upgrades? Are state
    variables ordered such that new versions can append without
    collision?
12. Does `_authorizeUpgrade` correctly restrict to `DEFAULT_ADMIN_ROLE`?
13. Are there any uninitialized storage slots that a malicious
    implementation could exploit?

### Lifecycle

14. Are the lifecycle transitions one-way and irreversible? Can an
    asset return from Matured to Active?
15. After `redeemAsset`, can any function still mutate state in a way
    that affects investor claims?

### Pause and emergency

16. Does `_update`'s `whenNotPaused` modifier cover every transfer path,
    including ERC-20 hooks like `permit` if added?
17. Are admin functions (NAV updates, fee changes) intentionally
    callable while paused? (Currently yes — desired for emergency NAV
    corrections.)

## 4. Known limitations (intentional, not bugs)

These are explicit design choices, not findings:

- **L1: Single-EOA NAV oracle.** `AGENT_ROLE` is trusted to push NAV
  without on-chain validation. Production deployments must replace this
  with a Chainlink feed, multi-sig signer set, or attestation oracle.
- **L2: Simplified compliance.** Single whitelist/blacklist rather than
  ERC-3643 modular Compliance, Identity Registry, and Claim Issuer
  Registry. Production deployments must extend this.
- **L3: No on-chain dividend distribution.** Distribution is intended
  to be handled by a separate distributor contract.
- **L4: No on-chain recovery mechanism.** Lost-key recovery, court-
  ordered forced transfers, and corporate actions are out of scope.
- **L5: No transfer agent integration.** Off-chain investor registry,
  K-1 reporting, etc. are out of scope.
- **L6: Fees never leave the contract.** `accruedFees` reduces NAV in
  share-price calculations. Issuer realizes fees through residual
  value, not on-chain transfer. Acceptable for an institutional setup
  where the issuer is also the residual claim holder.
- **L7: No transfer hooks for compliance modules.** Production
  ERC-3643 wires per-transfer hooks to modular Compliance.

## 5. Test coverage

Foundry unit tests cover:

- Initialization and zero-address guards
- Whitelist / blacklist enforcement on transfer, mint, burn
- Mint / burn revert paths
- Asset lifecycle transitions
- NAV update authorization
- Fee accrual: zero-time, half-year, full-year, and a 365×daily
  regression test for the v0 fee-compounding bug
- Fee rate cap (500 bps)
- `previewAccruedFees` consistency
- Share price and portfolio value math
- Pause enforcement

**Fuzz tests:** not yet implemented. Recommended pre-audit additions:

- `fuzz_FeeAccrual(uint256 nav, uint256 feeBps, uint256 timeElapsed)`
- `fuzz_TransferRespectsCompliance(...)`
- `invariant_AccruedFeesLeqNav()`
- `invariant_TotalSharesEqualsSumBalances()`

## 6. External dependencies

- `@openzeppelin/contracts-upgradeable` ^5.x — assumed audited
- Solidity ^0.8.22 — relies on built-in overflow checks

## 7. Suggested audit scope and effort

- ~250 LoC of in-scope Solidity
- Storage-layout review for upgrade safety
- Threat model walk-through (sections 3.1–3.6 above)
- Fuzz / invariant test suite review (once added)

Rough sizing for a small-firm engagement: 1–2 auditor-weeks.

## 8. Out of scope for audit

- Frontend (`frontend/`)
- Deploy scripts (`scripts/`)
- AI generation scripts (`scripts/deepseek-generate.sh` etc.)
- `prompts/` directory
- `outreach/` directory
- The OpenZeppelin upgradeable base contracts themselves

---

*Document version 1. Update with each scope change.*
