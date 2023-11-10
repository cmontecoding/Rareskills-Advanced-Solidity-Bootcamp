// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {StakingToken} from "../../src/Ecosystem1/StakingToken.sol";

contract StakingTokenTest is Test {
    StakingToken token;
    address admin;
    address user1;
    address user2;

    function setUp() public {
        admin = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        token = new StakingToken(admin);
    }

    function testCanMint() public {
        token.mint(10);
    }

    function testCannotMint() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(10);
    }

}
