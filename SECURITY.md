# Security Policy

## Status

This repository is a **reference implementation** and has **not** been
audited by a third party. Do not deploy it to manage real assets.

## Reporting a vulnerability

If you discover a vulnerability in this codebase, please report it
privately rather than opening a public issue.

- **Email:** yoshi@soundraw.co.jp
- **Subject line:** `[rwa-tokenizer] Security report`
- Please include:
  - A description of the issue and its impact
  - Steps to reproduce, or a proof-of-concept where applicable
  - The commit hash you reviewed
  - Your name and how you'd like to be credited (optional)

We will acknowledge receipt within 72 hours and aim to provide an initial
assessment within 7 days. We do not currently offer a paid bounty, but
verified reports will be credited in the changelog and (with your consent)
in any post-audit security advisory.

## Disclosure timeline

- **Day 0** — Report received.
- **Day ≤ 3** — Acknowledgement sent.
- **Day ≤ 7** — Initial triage and severity assessment.
- **Day ≤ 30** — Patch developed and tested (timeline varies with
  severity).
- **Coordinated disclosure** — Public advisory and patch release once a
  fix is available, on a timeline agreed with the reporter.

For issues affecting deployed mainnet contracts (none exist for this
repository at the time of writing), we will pursue coordinated disclosure
with affected counterparties before publishing technical details.

## Scope

In scope:

- `contracts/src/RWAToken.sol` and any contract added to `contracts/src/`.
- Deployment scripts in `scripts/` to the extent they affect on-chain
  state.
- Configuration that exposes private keys, RPC credentials, or other
  secrets.

Out of scope:

- The example `frontend/` (no real funds are at risk).
- DeepSeek or other AI tooling used to generate code.
- Issues that require physical access to a developer machine.

## Known limitations

The contract has documented limitations in `AUDIT_BRIEF.md`. Reports
that restate those limitations (e.g., "the NAV oracle is a single
EOA") are not eligible for credit; we are aware. Reports of *new*
issues, or of bugs in the implementation of intentional design
choices, are welcome.
