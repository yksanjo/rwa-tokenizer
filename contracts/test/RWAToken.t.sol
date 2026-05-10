// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/RWAToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RWATokenTest is Test {
    RWAToken public token;
    RWAToken public implementation;
    ERC1967Proxy public proxy;

    address public issuer = address(0x1);
    address public agent = address(0x2);
    address public verifier = address(0x3);
    address public investor = address(0x4);
    address public investor2 = address(0x5);

    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    function setUp() public {
        implementation = new RWAToken();
        proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(
                RWAToken.initialize.selector,
                "US Treasury Bond Fund",
                "USTB",
                "US Treasury Bond Fund Series 1",
                "Treasury",
                issuer
            )
        );
        token = RWAToken(address(proxy));

        vm.startPrank(issuer);
        token.grantRole(AGENT_ROLE, agent);
        token.grantRole(VERIFIER_ROLE, verifier);
        vm.stopPrank();
    }

    // --- Initialization ---
    function test_Initialization() public {
        assertEq(token.name(), "US Treasury Bond Fund");
        assertEq(token.symbol(), "USTB");
        assertEq(token.assetName(), "US Treasury Bond Fund Series 1");
        assertEq(token.assetType(), "Treasury");
        assertEq(token.hasRole(ISSUER_ROLE, issuer), true);
    }

    function test_RevertInitializeWithZeroIssuer() public {
        RWAToken impl = new RWAToken();
        vm.expectRevert();
        new ERC1967Proxy(
            address(impl),
            abi.encodeWithSelector(
                RWAToken.initialize.selector,
                "x", "X", "asset", "Treasury", address(0)
            )
        );
    }

    // --- Compliance ---
    function test_WhitelistInvestor() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));
        assertEq(token.isWhitelisted(investor), true);
    }

    function test_RevertWhitelistBlacklisted() public {
        vm.prank(agent);
        token.blacklistAddress(investor);
        vm.prank(verifier);
        vm.expectRevert("Account is blacklisted");
        token.whitelistAddress(investor, bytes32(0));
    }

    // --- Minting ---
    function test_MintTokens() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        vm.stopPrank();

        assertEq(token.balanceOf(investor), 1000 ether);
        assertEq(token.totalShares(), 1000 ether);
    }

    function test_RevertMintToNonWhitelisted() public {
        vm.startPrank(issuer);
        token.activateAsset();
        vm.expectRevert("Recipient not whitelisted");
        token.mint(investor, 1000 ether);
        vm.stopPrank();
    }

    function test_RevertMintZeroAmount() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));
        vm.startPrank(issuer);
        token.activateAsset();
        vm.expectRevert("Amount must be > 0");
        token.mint(investor, 0);
        vm.stopPrank();
    }

    // --- Transfers ---
    function test_TransferWithCompliance() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));
        vm.prank(verifier);
        token.whitelistAddress(investor2, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        vm.stopPrank();

        vm.prank(investor);
        token.transfer(investor2, 500 ether);

        assertEq(token.balanceOf(investor), 500 ether);
        assertEq(token.balanceOf(investor2), 500 ether);
    }

    function test_BlacklistPreventsTransfer() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));
        vm.prank(verifier);
        token.whitelistAddress(investor2, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        vm.stopPrank();

        vm.prank(agent);
        token.blacklistAddress(investor);

        vm.prank(investor);
        vm.expectRevert("Sender not whitelisted");
        token.transfer(investor2, 100 ether);
    }

    function test_PausePreventsTransfers() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        vm.stopPrank();

        vm.prank(agent);
        token.pause();

        vm.prank(investor);
        vm.expectRevert();
        token.transfer(investor2, 100 ether);
    }

    // --- NAV ---
    function test_NAVUpdate() public {
        vm.prank(issuer);
        token.activateAsset();
        vm.prank(agent);
        token.updateNAV(1_000_000 * 10**8); // $1M NAV
        assertEq(token.nav(), 1_000_000 * 10**8);
    }

    function test_RevertNAVZero() public {
        vm.prank(issuer);
        token.activateAsset();
        vm.prank(agent);
        vm.expectRevert("NAV must be > 0");
        token.updateNAV(0);
    }

    // --- Asset Lifecycle ---
    function test_AssetLifecycle() public {
        vm.startPrank(issuer);
        token.activateAsset();
        token.matureAsset();
        token.redeemAsset();
        vm.stopPrank();
        assertEq(uint(token.assetState()), uint(RWAToken.AssetState.Redeemed));
    }

    // --- Management Fee: time-prorated accrual ---
    function test_ManagementFee_NoTimeNoFees() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        token.setManagementFee(150); // 1.5% per annum
        vm.stopPrank();

        vm.prank(agent);
        token.updateNAV(1_000_000 * 10**8);

        // No time has elapsed beyond the same-block updates → no fees accrued.
        assertEq(token.accruedFees(), 0);
        assertEq(token.managementFee(), 150);
    }

    function test_ManagementFee_OneYearAccrual() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        token.setManagementFee(150); // 1.5% per annum
        vm.stopPrank();

        vm.prank(agent);
        token.updateNAV(1_000_000 * 10**8); // $1M

        // Advance exactly one year.
        vm.warp(block.timestamp + 365 days);

        // Trigger accrual via another NAV update.
        vm.prank(agent);
        token.updateNAV(1_000_000 * 10**8);

        // Expected: 1.5% of $1M = $15,000 = 15_000 * 1e8
        uint256 expected = (1_000_000 * 10**8 * 150) / 10000;
        assertEq(token.accruedFees(), expected);
    }

    function test_ManagementFee_HalfYearAccrual() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        token.setManagementFee(200); // 2% per annum
        vm.stopPrank();

        vm.prank(agent);
        token.updateNAV(1_000_000 * 10**8);

        // Advance half a year.
        vm.warp(block.timestamp + (365 days / 2));

        vm.prank(agent);
        token.updateNAV(1_000_000 * 10**8);

        // Expected: half of 2% = 1% of $1M = $10,000
        uint256 expected = (1_000_000 * 10**8 * 200 * (365 days / 2))
            / (10000 * 365 days);
        assertEq(token.accruedFees(), expected);
    }

    function test_ManagementFee_NoCompoundingOnDailyOracle() public {
        // Regression: v0 charged the full annual fee on every updateNAV().
        // Confirm that 365 daily NAV pushes yield ~1× annual fee, not 365×.
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        token.setManagementFee(100); // 1% per annum
        vm.stopPrank();

        vm.prank(agent);
        token.updateNAV(1_000_000 * 10**8);

        for (uint256 i = 0; i < 365; i++) {
            vm.warp(block.timestamp + 1 days);
            vm.prank(agent);
            token.updateNAV(1_000_000 * 10**8);
        }

        // Expected: ~1% of $1M = $10,000. Tolerate rounding ≤ 365 wei-USD.
        uint256 expected = (1_000_000 * 10**8 * 100) / 10000;
        assertApproxEqAbs(token.accruedFees(), expected, 365);
    }

    function test_RevertFeeAboveCap() public {
        vm.prank(issuer);
        vm.expectRevert("Fee exceeds 5% cap");
        token.setManagementFee(501);
    }

    function test_PreviewAccruedFees() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));
        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        token.setManagementFee(100);
        vm.stopPrank();

        vm.prank(agent);
        token.updateNAV(1_000_000 * 10**8);

        vm.warp(block.timestamp + 365 days);

        uint256 preview = token.previewAccruedFees();
        uint256 expected = (1_000_000 * 10**8 * 100) / 10000;
        assertEq(preview, expected);
        // Real accruedFees is still 0 until a state-changing call.
        assertEq(token.accruedFees(), 0);
    }

    // --- Share Price ---
    function test_SharePrice() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        vm.stopPrank();

        vm.prank(agent);
        token.updateNAV(1_100_000 * 10**8); // $1.1M NAV

        // NAV = 1,100,000 * 1e8, shares = 1000 * 1e18
        // sharePrice = (1,100,000 * 1e8 * 1e18) / (1000 * 1e18) = 1,100 * 1e8
        assertEq(token.getSharePrice(), 1100 * 10**8);
    }

    function test_PortfolioValue() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        vm.stopPrank();

        vm.prank(agent);
        token.updateNAV(1_000_000 * 10**8);

        // Single holder owns 100% → portfolio value = NAV (less fees, which is 0)
        assertEq(token.getPortfolioValue(investor), 1_000_000 * 10**8);
    }
}
