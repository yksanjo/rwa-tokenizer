# RWA Tokenizer

A reference implementation of an ERC-3643-style tokenized Real-World Asset
contract, with on-chain compliance, time-prorated management fees, and a
Pending → Active → Matured → Redeemed asset lifecycle.

This repository is a **technical reference**, intended for institutions
evaluating tokenization architectures and for engineering teams that want a
clean starting point before adding production-grade compliance, oracle, and
distribution infrastructure.

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.22-blue)](https://soliditylang.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Status

| Item | Status |
|---|---|
| Reference implementation | Complete |
| Unit tests (Foundry) | Complete |
| Fuzz tests | **Not yet** |
| Third-party security audit | **Not yet** — see `AUDIT_BRIEF.md` |
| Production deployment | **Not yet** |
| Legal structuring (issuer entity, offering memorandum, transfer agent agreement) | Out of scope |

**Do not deploy this contract to manage real assets without a full audit and
the surrounding legal/operational stack.** See `AUDIT_BRIEF.md` for the
scoping note we would hand to an auditor.

## Scope

The `RWAToken` contract implements:

- **Compliance enforcement** — whitelist / blacklist with role-separated
  verification (VERIFIER) and enforcement (AGENT). Every transfer, mint, and
  burn passes through the compliance check.
- **Role-based access control** — `ISSUER_ROLE`, `AGENT_ROLE`,
  `VERIFIER_ROLE`, plus `DEFAULT_ADMIN_ROLE` for upgrades.
- **NAV tracking** — single-oracle NAV updates with timestamp, denominated in
  USD with 8 decimals.
- **Management fee accrual** — time-prorated continuous accrual, capped at
  500 bps (5%) per annum. Reduces NAV in share-price calculations rather
  than transferring out, mirroring the standard fund-administrator pattern.
- **Asset lifecycle** — Pending → Active → Matured → Redeemed, with fee
  accrual settled on maturity.
- **Emergency pause** — circuit breaker held by AGENT_ROLE.
- **UUPS upgradeability** — admin-gated implementation upgrades with event
  emission.

## Out of scope

The following are deliberately **not** part of this contract. Each is a
known limitation that institutional deployments should address externally:

- **Full ERC-3643 modular compliance.** The whitelist/blacklist is a
  simplified compliance surface. A production deployment needs an Identity
  Registry, a Claim Issuer Registry, and pluggable Compliance modules
  (transfer restrictions by jurisdiction, holding limits, lock-ups).
- **Production-grade NAV oracle.** This contract trusts a single
  `AGENT_ROLE` address. Production should source NAV from Chainlink, a
  fund-administrator-signed multi-sig, or a NAV oracle with attestation.
- **Dividend / coupon distribution.** Distribution belongs in a separate
  contract (Merkle distributor or per-share pull-claim). Embedding it in
  the token contract is an anti-pattern — see Centrifuge, Tokeny, and the
  ERC-3643 reference architecture.
- **Forced transfers / recovery.** Required by most security-token
  jurisdictions (court order, lost-key recovery). Add via a Recovery
  module before mainnet.
- **Transfer agent and registrar integration.** Off-chain investor records
  and corporate actions are out of scope.

## Smart Contract API

### Roles

| Role | Capabilities |
|---|---|
| `ISSUER_ROLE` | Mint, burn, set management fee, advance asset lifecycle. |
| `AGENT_ROLE` | Update NAV, pause/unpause, blacklist accounts. |
| `VERIFIER_ROLE` | Whitelist accounts (post-KYC). |
| `DEFAULT_ADMIN_ROLE` | Authorize implementation upgrades; grant/revoke roles. |

### Key functions

```solidity
// Compliance
function whitelistAddress(address account, bytes32 claim)   // VERIFIER
function blacklistAddress(address account)                  // AGENT

// Issuance
function mint(address to, uint256 amount)                   // ISSUER
function burn(address from, uint256 amount)                 // ISSUER (forced redemption)

// NAV & fees
function updateNAV(uint256 _nav)                            // AGENT
function setManagementFee(uint256 _feeBps)                  // ISSUER (≤ 500 bps)
function previewAccruedFees() view returns (uint256)

// Lifecycle
function activateAsset()                                    // ISSUER
function matureAsset()                                      // ISSUER
function redeemAsset()                                      // ISSUER

// Views
function getSharePrice() view returns (uint256)             // USD, 8 decimals
function getPortfolioValue(address investor) view returns (uint256)
```

### Decimal convention

| Value | Decimals |
|---|---|
| `nav`, `accruedFees`, `getSharePrice()`, `getPortfolioValue()` | 8 (USD; 1.00 USD = `1e8`) |
| `totalShares`, `balanceOf` | 18 (ERC-20 wei) |
| `managementFee` | basis points (`100` = 1%) per annum |

## Build and test

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Build
cd contracts
forge build

# Test
forge test -vv
```

The test suite covers initialization, compliance enforcement, lifecycle
transitions, time-prorated fee accrual (including a 365-daily-update
regression for the v0 fee-compounding bug), share-price math, and pause.

## Deployment

Deployment scripts are illustrative — they target Sepolia and the testnets
listed in `.env.example`. **Mainnet deployment is intentionally not wired
up in this repo.** Mainnet deployment of a security-token contract should
go through:

1. Third-party audit + remediation
2. Issuer-entity ownership of the proxy admin key (multi-sig or HSM)
3. Compliance modules wired before activation
4. Operational runbook for pause, NAV updates, and recovery

See `SECURITY.md` for the disclosure policy.

## Repository layout

```
contracts/        Solidity sources + Foundry config
  src/            RWAToken.sol
  test/           RWAToken.t.sol
frontend/         Reference Next.js dashboard (illustrative only)
scripts/          Deployment + iteration helpers
SECURITY.md       Disclosure policy
AUDIT_BRIEF.md    Threat model, known limitations, audit scope
```

## License

MIT. See `LICENSE`.

## Disclosures

This implementation was developed with assistance from AI coding tools
(Claude, DeepSeek). All code has been reviewed by a human author; no
portion of this repository should be construed as audited or production-
ready until an independent security audit is complete (see
`AUDIT_BRIEF.md`).
