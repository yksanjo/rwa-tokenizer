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

        // Setup roles
        vm.startPrank(issuer);
        token.grantRole(AGENT_ROLE, agent);
        token.grantRole(VERIFIER_ROLE, verifier);
        vm.stopPrank();
    }

    function test_Initialization() public {
        assertEq(token.name(), "US Treasury Bond Fund");
        assertEq(token.symbol(), "USTB");
        assertEq(token.assetName(), "US Treasury Bond Fund Series 1");
        assertEq(token.assetType(), "Treasury");
        assertEq(token.hasRole(ISSUER_ROLE, issuer), true);
    }

    function test_WhitelistInvestor() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));
        assertEq(token.isWhitelisted(investor), true);
    }

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

    function test_NAVUpdate() public {
        vm.prank(agent);
        token.updateNAV(1_000_000 * 10**8); // $1M NAV

        assertEq(token.nav(), 1_000_000 * 10**8);
    }

    function test_AssetLifecycle() public {
        vm.startPrank(issuer);
        token.activateAsset();
        token.matureAsset();
        token.redeemAsset();
        vm.stopPrank();
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

    function test_ManagementFee() public {
        // First mint some shares
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        vm.stopPrank();

        // Set fee and update NAV
        vm.prank(issuer);
        token.setManagementFee(150); // 1.5%

        vm.prank(agent);
        token.updateNAV(1_000_000 * 10**8);

        assertEq(token.managementFee(), 150);
        assertGt(token.accruedFees(), 0);
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

    function test_SharePrice() public {
        vm.prank(verifier);
        token.whitelistAddress(investor, bytes32(0));

        vm.startPrank(issuer);
        token.activateAsset();
        token.mint(investor, 1000 ether);
        vm.stopPrank();

        vm.prank(agent);
        token.updateNAV(1_100_000 * 10**8); // $1.1M NAV

        uint256 sharePrice = token.getSharePrice();
        // NAV = 1,100,000 (8 decimals), shares = 1000e18
        // sharePrice = (1,100,000 * 10^8 * 10^18) / (1000 * 10^18) = 1,100 * 10^8
        assertEq(sharePrice, 1100 * 10**8);
    }
}
