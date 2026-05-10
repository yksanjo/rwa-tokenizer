// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title RWAToken
 * @notice Tokenized Real World Asset with compliance and NAV tracking
 * @dev ERC-3643 inspired security token with identity verification
 */
contract RWAToken is 
    ERC20Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    // --- Roles ---
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    // --- Asset State ---
    enum AssetState { Pending, Active, Matured, Redeemed }
    AssetState public assetState;

    string public assetName;
    string public assetType; // "Treasury", "Bond", "RealEstate", "PrivateCredit"
    uint256 public nav; // Current NAV in USD (8 decimals)
    uint256 public navTimestamp;
    uint256 public totalShares;
    uint256 public managementFee; // Basis points (100 = 1%)
    uint256 public accruedFees;

    // --- Identity & Compliance ---
    mapping(address => bytes32) public identityClaims;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isBlacklisted;

    // --- Events ---
    event NAVUpdated(uint256 newNav, uint256 timestamp);
    event Whitelisted(address indexed account);
    event Blacklisted(address indexed account);
    event FeesAccrued(uint256 amount);
    event AssetStateChanged(AssetState newState);
    event DividendsDistributed(uint256 amount, uint256 perShare);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _assetName,
        string memory _assetType,
        address _issuer
    ) external initializer {
        __ERC20_init(_name, _symbol);
        __AccessControl_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _issuer);
        _grantRole(ISSUER_ROLE, _issuer);

        assetName = _assetName;
        assetType = _assetType;
        assetState = AssetState.Pending;
    }

    // --- Compliance ---
    modifier onlyWhitelisted(address account) {
        require(isWhitelisted[account], "Account not whitelisted");
        require(!isBlacklisted[account], "Account blacklisted");
        _;
    }

    function whitelistAddress(address account, bytes32 claim) 
        external 
        onlyRole(VERIFIER_ROLE) 
    {
        require(!isBlacklisted[account], "Account is blacklisted");
        identityClaims[account] = claim;
        isWhitelisted[account] = true;
        emit Whitelisted(account);
    }

    function blacklistAddress(address account) 
        external 
        onlyRole(AGENT_ROLE) 
    {
        isBlacklisted[account] = true;
        isWhitelisted[account] = false;
        emit Blacklisted(account);
    }

    // --- Token Operations ---
    function mint(address to, uint256 amount) 
        external 
        onlyRole(ISSUER_ROLE) 
        whenNotPaused 
    {
        require(assetState == AssetState.Active, "Asset not active");
        require(isWhitelisted[to], "Recipient not whitelisted");
        _mint(to, amount);
        totalShares += amount;
    }

    function burn(address from, uint256 amount) 
        external 
        onlyRole(ISSUER_ROLE) 
        whenNotPaused 
    {
        _burn(from, amount);
        totalShares -= amount;
    }

    function _update(address from, address to, uint256 value)
        internal
        override
        whenNotPaused
    {
        if (from != address(0) && to != address(0)) {
            require(isWhitelisted[from], "Sender not whitelisted");
            require(isWhitelisted[to], "Recipient not whitelisted");
            require(!isBlacklisted[from], "Sender blacklisted");
            require(!isBlacklisted[to], "Recipient blacklisted");
        }
        super._update(from, to, value);
    }

    // --- NAV & Fees ---
    function updateNAV(uint256 _nav) external onlyRole(AGENT_ROLE) {
        require(_nav > 0, "NAV must be > 0");
        nav = _nav;
        navTimestamp = block.timestamp;
        _accrueFees();
        emit NAVUpdated(_nav, block.timestamp);
    }

    function _accrueFees() internal {
        if (managementFee > 0 && totalShares > 0) {
            uint256 feeAmount = (nav * managementFee) / 10000;
            accruedFees += feeAmount;
            emit FeesAccrued(feeAmount);
        }
    }

    function setManagementFee(uint256 _fee) external onlyRole(ISSUER_ROLE) {
        require(_fee <= 500, "Fee too high"); // Max 5%
        managementFee = _fee;
    }

    // --- Asset Lifecycle ---
    function activateAsset() external onlyRole(ISSUER_ROLE) {
        require(assetState == AssetState.Pending, "Wrong state");
        assetState = AssetState.Active;
        emit AssetStateChanged(AssetState.Active);
    }

    function matureAsset() external onlyRole(ISSUER_ROLE) {
        require(assetState == AssetState.Active, "Wrong state");
        assetState = AssetState.Matured;
        emit AssetStateChanged(AssetState.Matured);
    }

    function redeemAsset() external onlyRole(ISSUER_ROLE) {
        require(assetState == AssetState.Matured, "Wrong state");
        assetState = AssetState.Redeemed;
        emit AssetStateChanged(AssetState.Redeemed);
    }

    // --- Dividends ---
    function distributeDividends() 
        external 
        payable 
        onlyRole(ISSUER_ROLE) 
    {
        require(totalShares > 0, "No shares");
        uint256 perShare = msg.value / totalShares;
        emit DividendsDistributed(msg.value, perShare);
    }

    // --- Pause ---
    function pause() external onlyRole(AGENT_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(AGENT_ROLE) {
        _unpause();
    }

    // --- UUPS ---
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    // --- View Functions ---
    // Returns share price in USD with 8 decimals
    function getSharePrice() external view returns (uint256) {
        if (totalShares == 0) return 0;
        return ((nav - accruedFees) * 1e18) / totalShares;
    }

    // Returns portfolio value in USD with 8 decimals
    function getPortfolioValue(address investor) external view returns (uint256) {
        if (totalShares == 0) return 0;
        return (balanceOf(investor) * (nav - accruedFees)) / totalShares;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
