# DeepSeek Prompt: Generate RWA Token Contract

## Context
You are generating a Solidity smart contract for tokenizing real-world assets (RWAs). The contract should follow industry standards and include compliance features.

## Requirements

Generate an ERC-3643 (T-REX) compliant security token contract with:

1. **Token Features:**
   - ERC-3643 standard (security token with identity verification)
   - Mint/burn with permissioned roles
   - Transfer restrictions based on identity
   - Pausable functionality

2. **Compliance:**
   - On-chain identity verification (Claim topics)
   - Whitelist/blacklist management
   - Transfer validation before execution
   - Granular permission levels (ISSUER, AGENT, VERIFIER)

3. **RWA Specific:**
   - NAV (Net Asset Value) tracking with oracle updates
   - Fee accrual mechanism (management fee)
   - Dividend distribution capability
   - Asset lifecycle management (issued, active, matured, redeemed)

4. **Security:**
   - OpenZeppelin-based access control
   - Reentrancy protection
   - Emergency pause mechanism
   - Upgradeable via UUPS proxy

## Output Format

Provide:
1. Complete Solidity contract code
2. NatSpec documentation
3. Deployment script (Hardhat/Foundry)
4. Test file with key scenarios

## Chain
Ethereum (compatible with L2s: Arbitrum, Optimism, Polygon)

## Additional Notes
- Use Solidity ^0.8.20
- Follow OpenZeppelin v5 conventions
- Include events for all state changes
- Gas optimized where possible
