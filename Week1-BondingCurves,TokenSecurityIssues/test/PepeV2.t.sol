// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {PepeV2} from "../src/PepeV2.sol";

contract PepeV2Test is Test {
    PepeV2 pepe;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        pepe = new PepeV2(1000);
        pepe.transfer(user1, 100);
        pepe.transfer(user2, 100);

        ///@dev make sure initializations are correct
        assertEq(pepe.totalSupply(), 1000);
        assertEq(pepe.balanceOf(admin), 800);
        assertEq(pepe.balanceOf(user1), 100);
        assertEq(pepe.balanceOf(user2), 100);
    }

    /// @notice Test that the blacklisted address cannot send tokens
    function testBlacklistSender() public {
        pepe.blacklist(user1, true);
        vm.expectRevert("Blacklisted");
        vm.prank(user1);
        pepe.transfer(user2, 10);
    }

    /// @notice Test that the blacklisted address cannot receive tokens
    function testBlacklistReceiver() public {
        pepe.blacklist(user2, true);
        vm.expectRevert("Blacklisted");
        vm.prank(user1);
        pepe.transfer(user2, 10);
    }
}
