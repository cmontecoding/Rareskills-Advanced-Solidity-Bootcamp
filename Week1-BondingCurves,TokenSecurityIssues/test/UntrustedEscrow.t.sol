// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {UntrustedEscrow} from "../src/UntrustedEscrow.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract UntrustedEscrowTest is Test {
    UntrustedEscrow untrusted;
    address admin;
    address user1;
    address user2;
    DummyERC20 token;

    function setUp() public {
        /// @dev warp forward so that block timestamp is not 0
        vm.warp(block.timestamp + 1000);

        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        untrusted = new UntrustedEscrow();
        token = new DummyERC20("Test", "TEST");
        token.mint(user1, 10);
    }

    function testInitialize() public {
        untrusted.initialize(user1, user2, IERC20(address(token)));

        assertEq(untrusted.buyer(), user1);
        assertEq(untrusted.seller(), user2);
        assertEq(address(untrusted.token()), address(token));
    }

    function testDeposit() public {
        untrusted.initialize(user1, user2, IERC20(address(token)));

        vm.startPrank(user1);
        token.approve(address(untrusted), 10);
        untrusted.deposit(10);
        vm.stopPrank();

        assertEq(token.balanceOf(address(untrusted)), 10);
        assertEq(untrusted.depositTime(), block.timestamp);
        assertEq(untrusted.deposited(), true);
    }

    function testWithdraw() public {
        untrusted.initialize(user1, user2, IERC20(address(token)));

        vm.startPrank(user1);
        token.approve(address(untrusted), 10);
        untrusted.deposit(10);
        vm.stopPrank();

        vm.warp(block.timestamp + 3 days);
        vm.startPrank(user2);
        untrusted.withdraw();
        vm.stopPrank();

        assertEq(token.balanceOf(address(untrusted)), 0);
        assertEq(token.balanceOf(user2), 10);
    }

    function testWithdrawTooSoon() public {
        untrusted.initialize(user1, user2, IERC20(address(token)));

        vm.startPrank(user1);
        token.approve(address(untrusted), 10);
        untrusted.deposit(10);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);
        vm.startPrank(user2);
        vm.expectRevert("Withdrawal time has not arrived yet");
        untrusted.withdraw();
    }
}

contract DummyERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
