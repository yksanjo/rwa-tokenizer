// RWA Token ABI (minimal for frontend interactions)
export const RWA_TOKEN_ABI = [
  // Read
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function balanceOf(address) view returns (uint256)",
  "function totalSupply() view returns (uint256)",
  "function nav() view returns (uint256)",
  "function totalShares() view returns (uint256)",
  "function managementFee() view returns (uint256)",
  "function accruedFees() view returns (uint256)",
  "function getSharePrice() view returns (uint256)",
  "function getPortfolioValue(address) view returns (uint256)",
  "function isWhitelisted(address) view returns (bool)",
  "function isBlacklisted(address) view returns (bool)",
  "function assetName() view returns (string)",
  "function assetType() view returns (string)",
  
  // Write
  "function mint(address to, uint256 amount)",
  "function burn(address from, uint256 amount)",
  "function updateNAV(uint256 _nav)",
  "function whitelistAddress(address account, bytes32 claim)",
  "function blacklistAddress(address account)",
  "function pause()",
  "function unpause()",
  "function activateAsset()",
  "function matureAsset()",
  "function redeemAsset()",
  "function setManagementFee(uint256 _fee)",
  
  // Events
  "event NAVUpdated(uint256 newNav, uint256 timestamp)",
  "event Whitelisted(address indexed account)",
  "event Blacklisted(address indexed account)",
  "event Transfer(address indexed from, address indexed to, uint256 value)",
] as const;

// Contract addresses by chain
export const CONTRACT_ADDRESSES: Record<number, `0x${string}`> = {
  // Sepolia testnet
  11155111: "0x...", // Deploy your contract and add address here
  // Add other chains as needed
};

export function getContractAddress(chainId: number): `0x${string}` {
  return CONTRACT_ADDRESSES[chainId] || "0x...";
}
