// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title RWAToken
 * @notice Reference implementation of a tokenized Real-World Asset with
 *         compliance enforcement, time-prorated management fees, and a
 *         pending/active/matured/redeemed asset lifecycle.
 *
 * @dev   This is a v1 reference implementation. Known limitations (see
 *        AUDIT_BRIEF.md):
 *         - Compliance is a single whitelist/blacklist, not full ERC-3643
 *           Identity Registry + Claim Issuer Registry + modular Compliance.
 *         - NAV is updated by a single AGENT_ROLE address. Production
 *           deployments should source NAV from a Chainlink price feed or
 *           multi-sig oracle.
 *         - Dividend / coupon distribution is OUT OF SCOPE. Issuers should
 *           deploy a separate distributor contract (Merkle distributor or
 *           per-share pull-claim) — keeping distribution out of the token
 *           contract is the institutional pattern (see Centrifuge, Tokeny).
 *         - This contract has not been audited.
 *
 * @dev   Decimal scaling:
 *         - `nav` and `accruedFees`: USD value, 8 decimals (1.00 USD = 1e8)
 *         - `totalShares` and `balanceOf`: ERC-20 wei, 18 decimals
 *         - `getSharePrice()` returns USD per whole token, 8 decimals
 *         - `getPortfolioValue()` returns USD value held, 8 decimals
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

    // --- Constants ---
    uint256 public constant MAX_MANAGEMENT_FEE_BPS = 500; // 5% per annum
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    // --- Asset State ---
    enum AssetState { Pending, Active, Matured, Redeemed }
    AssetState public assetState;

    string public assetName;
    string public assetType; // "Treasury", "Bond", "RealEstate", "PrivateCredit"

    // NAV in USD with 8 decimals
    uint256 public nav;
    uint256 public navTimestamp;
    uint256 public totalShares;

    // Management fee in basis points, charged per annum, accrued continuously
    uint256 public managementFee;
    uint256 public accruedFees;
    uint256 public lastFeeAccrual;

    // --- Identity & Compliance ---
    mapping(address => bytes32) public identityClaims;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isBlacklisted;

    // --- Events ---
    event NAVUpdated(uint256 newNav, uint256 timestamp);
    event Whitelisted(address indexed account);
    event Blacklisted(address indexed account);
    event FeesAccrued(uint256 amount, uint256 fromTimestamp, uint256 toTimestamp);
    event ManagementFeeSet(uint256 oldFeeBps, uint256 newFeeBps);
    event AssetStateChanged(AssetState newState);
    event ForcedRedemption(address indexed from, uint256 amount, string reason);
    event UpgradeAuthorized(address indexed newImplementation);

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
        require(_issuer != address(0), "Issuer cannot be zero address");
        require(bytes(_name).length > 0, "Name required");
        require(bytes(_symbol).length > 0, "Symbol required");
        require(bytes(_assetName).length > 0, "Asset name required");
        require(bytes(_assetType).length > 0, "Asset type required");

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
    function whitelistAddress(address account, bytes32 claim)
        external
        onlyRole(VERIFIER_ROLE)
    {
        require(account != address(0), "Account cannot be zero");
        require(!isBlacklisted[account], "Account is blacklisted");
        identityClaims[account] = claim;
        isWhitelisted[account] = true;
        emit Whitelisted(account);
    }

    function blacklistAddress(address account)
        external
        onlyRole(AGENT_ROLE)
    {
        require(account != address(0), "Account cannot be zero");
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
        require(amount > 0, "Amount must be > 0");
        _accrueFees();
        _mint(to, amount);
        totalShares += amount;
    }

    function burn(address from, uint256 amount)
        external
        onlyRole(ISSUER_ROLE)
        whenNotPaused
    {
        require(amount > 0, "Amount must be > 0");
        _accrueFees();
        _burn(from, amount);
        totalShares -= amount;
        emit ForcedRedemption(from, amount, "Issuer burn");
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
        // Accrue at the OLD nav for the elapsed period before updating.
        _accrueFees();
        nav = _nav;
        navTimestamp = block.timestamp;
        emit NAVUpdated(_nav, block.timestamp);
    }

    /// @notice Accrue management fees continuously over elapsed time at the
    ///         current NAV. Idempotent within a single block. Only accrues
    ///         while the asset is Active.
    function _accrueFees() internal {
        uint256 from = lastFeeAccrual;
        lastFeeAccrual = block.timestamp;

        if (assetState != AssetState.Active) return;
        if (managementFee == 0 || totalShares == 0 || nav == 0) return;
        if (from == 0 || block.timestamp <= from) return;

        uint256 elapsed = block.timestamp - from;
        uint256 feeAmount = (nav * managementFee * elapsed)
            / (BPS_DENOMINATOR * SECONDS_PER_YEAR);
        if (feeAmount == 0) return;
        accruedFees += feeAmount;
        emit FeesAccrued(feeAmount, from, block.timestamp);
    }

    function setManagementFee(uint256 _feeBps) external onlyRole(ISSUER_ROLE) {
        require(_feeBps <= MAX_MANAGEMENT_FEE_BPS, "Fee exceeds 5% cap");
        // Accrue at the OLD fee rate before changing.
        _accrueFees();
        uint256 oldFee = managementFee;
        managementFee = _feeBps;
        emit ManagementFeeSet(oldFee, _feeBps);
    }

    /// @notice Preview the fee that would accrue if `_accrueFees()` were
    ///         called now. View function for transparency.
    function previewAccruedFees() external view returns (uint256) {
        if (assetState != AssetState.Active) return accruedFees;
        if (managementFee == 0 || totalShares == 0 || nav == 0) return accruedFees;
        uint256 from = lastFeeAccrual;
        if (from == 0 || block.timestamp <= from) return accruedFees;
        uint256 elapsed = block.timestamp - from;
        uint256 pending = (nav * managementFee * elapsed)
            / (BPS_DENOMINATOR * SECONDS_PER_YEAR);
        return accruedFees + pending;
    }

    // --- Asset Lifecycle ---
    function activateAsset() external onlyRole(ISSUER_ROLE) {
        require(assetState == AssetState.Pending, "Wrong state");
        assetState = AssetState.Active;
        // Begin fee accrual timer from activation, not deployment.
        lastFeeAccrual = block.timestamp;
        emit AssetStateChanged(AssetState.Active);
    }

    function matureAsset() external onlyRole(ISSUER_ROLE) {
        require(assetState == AssetState.Active, "Wrong state");
        _accrueFees(); // settle fees up to maturity
        assetState = AssetState.Matured;
        emit AssetStateChanged(AssetState.Matured);
    }

    function redeemAsset() external onlyRole(ISSUER_ROLE) {
        require(assetState == AssetState.Matured, "Wrong state");
        assetState = AssetState.Redeemed;
        emit AssetStateChanged(AssetState.Redeemed);
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
    {
        require(newImplementation != address(0), "Implementation cannot be zero");
        emit UpgradeAuthorized(newImplementation);
    }

    // --- View Functions ---
    /// @notice Returns share price in USD with 8 decimals.
    function getSharePrice() external view returns (uint256) {
        if (totalShares == 0) return 0;
        uint256 netNav = nav > accruedFees ? nav - accruedFees : 0;
        return (netNav * 1e18) / totalShares;
    }

    /// @notice Returns portfolio value for `investor` in USD with 8 decimals.
    function getPortfolioValue(address investor) external view returns (uint256) {
        if (totalShares == 0) return 0;
        uint256 netNav = nav > accruedFees ? nav - accruedFees : 0;
        return (balanceOf(investor) * netNav) / totalShares;
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
