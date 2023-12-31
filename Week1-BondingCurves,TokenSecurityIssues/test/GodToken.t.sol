// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {GodToken} from "../src/GodToken.sol";

contract GodTokenTest is Test {
    GodToken god;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        god = new GodToken(1000);
        god.transfer(user1, 100);
        god.transfer(user2, 100);

        ///@dev make sure initializations are correct
        assertEq(god.totalSupply(), 1000);
        assertEq(god.balanceOf(admin), 800);
        assertEq(god.balanceOf(user1), 100);
        assertEq(god.balanceOf(user2), 100);
    }

    /// @notice Test that the owner can transfer tokens between addresses
    function testGodTransfer() public {
        god.godTransfer(user1, user2, 10);
        assertEq(god.balanceOf(user1), 90);
        assertEq(god.balanceOf(user2), 110);
    }

    /// @notice Test that non-owners cannot transfer tokens between addresses
    function testGodTransferFail() public {
        vm.prank(user1);
        vm.expectRevert();
        god.godTransfer(user1, user2, 10);
    }

    function testOwnable2StepTransfer() public {
        god.transferOwnership(user1);

        /// @dev user1 should be pending owner
        assertEq(god.pendingOwner(), user1);
        assertEq(god.owner(), admin);

        vm.prank(user1);
        god.acceptOwnership();
        assertEq(god.owner(), user1);
        assertEq(god.pendingOwner(), address(0));
    }

}
